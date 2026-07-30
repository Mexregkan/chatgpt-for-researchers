(* sync-wb-nb.wls — canonical .wb -> .nb sync.
   Usage (run from anywhere; set defaultWb/defaultNb below or pass paths as trailing args):
     wolframscript -file sync-wb-nb.wls verify     "<snippet>"
     wolframscript -file sync-wb-nb.wls stability  "<snippet>"
     wolframscript -file sync-wb-nb.wls replace    "<wbSnippet>" ["<nbOldSnippet>"]
     wolframscript -file sync-wb-nb.wls insert     "<wbSnippet>" "<nbAnchorSnippet>"
     wolframscript -file sync-wb-nb.wls regenerate [<wbPath> <nbPath>]
     ... [optional trailing args: <wbPath> <nbPath>]

   Snippet modes (verify/stability/replace/insert) propagate ONE edited cell, preserving the
   rest of a hand-crafted .nb (outputs, manual tweaks). Snippets MUST be single tokens
   (symbol names like "myFunction"): in box structures, "myFunc[x_" never matches because
   myFunc, [, x_ are separate strings.

   regenerate rebuilds the WHOLE .nb from the .wb so it opens in Mathematica looking normal
   (syntax-coloured BoxData Input cells; markdown -> Title/Section/Subsection/Text styles;
   in-code comments lifted into adjacent Text cells). Use it for a fresh / fully-rewritten
   .nb. It OVERWRITES the .nb, so do not use it to patch one cell of a hand-crafted notebook.

   Exit code 0 = success/PASS, 1 = failure (snippet write modes restore from backup). *)

(* ── Project defaults ──────────────────────────────────────────────────────
   Set these to your file pair so you can call the script without trailing
   args. Leave as "" to require explicit paths every time.              *)
defaultWb = "";   (* e.g. "/abs/path/to/project/numerics/mynotebook.wb" *)
defaultNb = "";   (* e.g. "/abs/path/to/project/numerics/mynotebook.nb" *)
(* ────────────────────────────────────────────────────────────────────────── *)

args = Rest[$ScriptCommandLine];
die[msg_] := (Print["FAIL: ", msg]; Exit[1]);
If[Length[args] < 1, die["need <mode> ..."]];
mode = args[[1]];
str[b_] := ToString[b, InputForm, PageWidth -> Infinity];

resolvePaths[] := Module[{paths = Select[args, StringContainsQ[#, "/"] &]},
   {If[Length[paths] >= 1, paths[[1]],
     If[defaultWb =!= "", defaultWb,
      die["no .wb path — pass as trailing arg or set defaultWb at the top of the script"]]],
    If[Length[paths] >= 2, paths[[2]],
     If[defaultNb =!= "", defaultNb,
      die["no .nb path — pass as trailing arg or set defaultNb at the top of the script"]]]}];

(* ============================ regenerate mode ============================ *)
(* Why a separate engine: snippet modes use MakeBoxes (canonical, but reassociates Times in
   product-numerator fractions and drops comments). regenerate uses the FRONT-END parser,
   which preserves the literal expression and the source line breaks (no reassociation hazard
   on a whole-file rewrite) and yields the FE's native multi-line BoxData that colours
   exactly like typed input. Both drop (* *) comments, so we lift them into Text cells. *)

hstyle[1] = "Title"; hstyle[2] = "Section"; hstyle[3] = "Subsection"; hstyle[4] = "Subsubsection";

stripMd[t_] := StringReplace[t, {
   RegularExpression["\\*\\*(.+?)\\*\\*"] -> "$1",      (* bold *)
   RegularExpression["`([^`]+)`"] -> "$1",             (* inline code *)
   RegularExpression["\\[([^\\]]+)\\]\\([^)]+\\)"] -> "$1"}];  (* [text](link) *)

(* code text -> the FE's BoxData (syntax-colourable); $Failed if it will not parse *)
parseCodeFE[code_] := Module[{r},
   r = UsingFrontEnd@FrontEndExecute[FrontEnd`UndocumentedTestFEParserPacket[code, True]];
   If[MatchQ[r, {_BoxData, ___}], r[[1]], $Failed]];

(* markdown .wb cell -> list of {style, text}: header lines become Title/Section/..., the
   rest becomes Text; markdown markup stripped *)
mdSpecs[v_] := Module[{lines = StringSplit[v, "\n"], out = {}, prose = {}, flush},
   flush[] := (With[{t = StringTrim[StringRiffle[prose, "\n"]]},
       If[t =!= "", AppendTo[out, {"Text", stripMd[t]}]]]; prose = {});
   Do[If[StringMatchQ[line, RegularExpression["#{1,4}\\s+.*"]],
      flush[];
      With[{h = StringCases[line, RegularExpression["^#{1,4}"]][[1]]},
       AppendTo[out, {hstyle[StringLength[h]], StringTrim[stripMd[StringDrop[line, StringLength[h]]]]}]],
      AppendTo[prose, line]], {line, lines}];
   flush[]; out];

(* code .wb cell -> {Text comments} (if any) then {code} with comments stripped *)
codeSpecs[v_] := Module[{comments, code, out = {}, ct},
   comments = StringCases[v, RegularExpression["(?s)\\(\\*(.*?)\\*\\)"] -> "$1"];
   code = StringReplace[v, RegularExpression["(?s)\\(\\*.*?\\*\\)"] -> ""];
   code = StringTrim[StringReplace[code, RegularExpression["\n{3,}"] -> "\n\n"]];
   If[comments =!= {},
    ct = StringRiffle[
       Select[StringTrim /@ (StringReplace[#, RegularExpression["\\s+"] -> " "] & /@ comments), # =!= "" &], "  "];
    If[ct =!= "", AppendTo[out, {"Text", ct}]]];
   If[code =!= "", AppendTo[out, {"code", code}]];
   out];

regenerate[wbfile_, nbfile_] := Module[{wb, specs, cells, nb2, nIn, nCode, raw, nbBoxes, chk, checker},
   wb = Quiet[Import[wbfile, "RawJSON"]];
   If[Head[wb] =!= Association, die["cannot read .wb " <> wbfile]];
   (* Guard: a split-statement hazard in the .wb (e.g. a definition RHS broken across a
      top-level newline) would be faithfully propagated into the .nb as a corrupting
      BoxData[{stmt1,"\n",stmt2}] split — this is how the MMVbar bug got into the .nb.
      If the paired nb-to-wolfbook skill is present (it lives next to this script under
      ../nb-to-wolfbook/), run its hazard checker and warn loudly before overwriting.
      Path is derived from this script's own location, so it is portable; if the checker
      is absent (e.g. a global-only sync-wb-nb install), this guard silently no-ops. *)
   checker = Quiet@Check[
      FileNameJoin[{DirectoryName[ExpandFileName[$ScriptCommandLine[[1]]]],
                    "..", "nb-to-wolfbook", "wl_normalize.py"}], ""];
   If[StringQ[checker] && checker =!= "" && FileExistsQ[checker],
    chk = RunProcess[{"python3", checker, "--check", wbfile}];
    If[AssociationQ[chk] && chk["ExitCode"] =!= 0,
     Print["\n*** WARNING: split-statement hazard(s) in the .wb ***"];
     Print[chk["StandardOutput"]];
     Print["The regenerated .nb will INHERIT these (BoxData split). Fix the .wb first:"];
     Print["  python3 ", checker, " --wb \"", wbfile, "\"   (then re-check). Proceeding.\n"]]];
   specs = Flatten[
     Function[c, If[c["kind"] === 1, mdSpecs[c["value"]], codeSpecs[c["value"]]]] /@ wb["cells"], 1];
   cells = Function[spec, Module[{bd},
       If[spec[[1]] === "code",
        bd = parseCodeFE[spec[[2]]];
        If[bd === $Failed, die["front-end parse failed for a code cell:\n" <> spec[[2]]]];
        Cell[bd, "Input", ExpressionUUID -> CreateUUID[]],
        Cell[spec[[2]], spec[[1]], ExpressionUUID -> CreateUUID[]]]]] /@ specs;
   (* write to the EXACT absolute path (relative paths silently land in wolframscript's own
      cwd — the classic "I regenerated it but the file didn't change" bug) *)
   Export[nbfile, Notebook[cells, StyleDefinitions -> "Default.nb"], "NB"];
   (* verify the file actually changed and is well-formed *)
   nb2 = Quiet[Import[nbfile]];
   If[Head[nb2] =!= Notebook, die["written file is not a Notebook (path? permissions?): " <> nbfile]];
   raw = Import[nbfile, "Text"];
   If[! StringContainsQ[raw, "BoxData"], die["written file has no BoxData cells: " <> nbfile]];
   nIn = Count[nb2, Cell[_BoxData, "Input", ___], Infinity];
   nCode = Count[specs, {"code", _}];
   If[nIn =!= nCode, die["BoxData cells " <> ToString[nIn] <> " != code cells " <> ToString[nCode]]];
   (* faithfulness: every stored code cell must re-parse to valid code (no $Failed). The FE
      parser is deterministic and the .nb Export/Import roundtrip is lossless, so this rules
      out a corrupt/garbled write. (We do not compare held expressions directly: Import
      normalises the FE's multi-line list-form BoxData into a single RowBox, which is the
      same code but a different held shape.) *)
   nbBoxes = Cases[nb2, Cell[bd_BoxData, "Input", ___] :> bd, Infinity];
   If[! AllTrue[nbBoxes,
       Module[{e = Quiet@ToExpression[First[#], StandardForm, HoldComplete]},
         FreeQ[e, $Failed] && e =!= HoldComplete[Null]] &],
    die["a stored code cell does not re-parse to valid code"]];
   Print["PASS: regenerated ", nbfile];
   Print["  cells: ", Length[cells], "  (", nIn, " coloured code, ", Length[cells] - nIn, " heading/text)"];
   Print["  styles: ", Union[Cases[nb2, Cell[_, s_String, ___] :> s, Infinity]]];
   Print["  NOTE: if it is open in Mathematica, close WITHOUT saving and reopen (File > Revert)"];
   Print["        -- a saved stale copy would overwrite this regenerated file."];
   Exit[0]];

If[mode === "regenerate",
  Module[{p = resolvePaths[]}, regenerate[p[[1]], p[[2]]]]];

(* ===================== snippet modes (one-cell sync) ===================== *)
If[Length[args] < 2, die["need <mode> <snippet> [...]"]];
snip1 = args[[2]];
snip2 = If[Length[args] >= 3 && ! StringContainsQ[args[[3]], "/"], args[[3]], snip1];
{wbfile, nbfile} = resolvePaths[];

wb = Quiet[Import[wbfile, "RawJSON"]];
If[Head[wb] =!= Association, die["cannot read .wb " <> wbfile]];
wbMatches = Select[wb["cells"], #["kind"] === 2 && StringContainsQ[#["value"], snip1] &];
If[Length[wbMatches] =!= 1,
  die["wb cells matching '" <> snip1 <> "': " <> ToString[Length[wbMatches]] <> " (need 1)"]];
code = wbMatches[[1]]["value"];

(* stability: code -> boxes -> code must be the identity on the parsed expression *)
e1 = ToExpression[code, StandardForm, HoldComplete];
boxes = ToExpression[code, StandardForm,
   Function[e, MakeBoxes[e, StandardForm], HoldAllComplete]];
e2 = ToExpression[boxes, StandardForm, HoldComplete];
stableQ = (e1 === e2);
If[mode === "stability",
  If[stableQ, Print["PASS: stable"]; Exit[0],
   die["NOT box-round-trip stable; rewrite the source (e.g. product-numerator fraction a*b/c -> assign numerator to a local; see SKILL.md)"]]];
If[! stableQ,
  die["wb code is not box-round-trip stable; run stability mode and fix the source first"]];

nb = Import[nbfile];
If[Head[nb] =!= Notebook, die["cannot read .nb " <> nbfile]];
nCells = Count[nb, _Cell, Infinity];
allPos = Position[nb, Cell[BoxData[_], "Input", ___]];
findPos[snip_] := Select[allPos, StringContainsQ[str[Extract[nb, #][[1, 1]]], snip] &];

If[mode === "verify",
  pos = findPos[snip1];
  If[Length[pos] =!= 1, die["nb cells matching '" <> snip1 <> "': " <> ToString[Length[pos]]]];
  exprNb = ToExpression[Extract[nb, pos[[1]]][[1, 1]], StandardForm, HoldComplete];
  If[exprNb === e1, Print["PASS: nb cell === wb cell"]; Exit[0],
   die["nb cell differs from wb cell"]]];

(* write modes: back up first *)
backup = "/tmp/sync-wb-nb-backup-" <> ToString[AbsoluteTime[] // Round] <> ".nb";
CopyFile[nbfile, backup];
Print["backup: ", backup];
newCell = Cell[BoxData[boxes], "Input", ExpressionUUID -> CreateUUID[]];

newnb = Which[
  mode === "replace",
  pos = findPos[snip2];
  If[Length[pos] =!= 1, die["nb target cells matching '" <> snip2 <> "': " <> ToString[Length[pos]] <> " (need 1)"]];
  ReplacePart[nb, pos[[1]] -> newCell],
  mode === "insert",
  pos = findPos[snip2];
  If[Length[pos] =!= 1, die["nb anchor cells matching '" <> snip2 <> "': " <> ToString[Length[pos]] <> " (need 1)"]];
  anchor = Extract[nb, pos[[1]]];
  nb /. (c : Cell[___, ExpressionUUID -> (anchor /. Cell[___, ExpressionUUID -> u_, ___] :> u), ___]) :> Sequence[c, newCell],
  True, die["unknown mode " <> mode]];

expected = nCells + If[mode === "insert", 1, 0];
If[Count[newnb, _Cell, Infinity] =!= expected,
  die["cell count wrong after " <> mode <> "; nothing written"]];
Export[nbfile, newnb];

(* verify the write *)
nb2 = Import[nbfile];
pos2 = Select[Position[nb2, Cell[BoxData[_], "Input", ___]],
   StringContainsQ[str[Extract[nb2, #][[1, 1]]], snip1] &];
ok = Length[pos2] >= 1 &&
   AnyTrue[pos2, ToExpression[Extract[nb2, #][[1, 1]], StandardForm, HoldComplete] === e1 &] &&
   Head[nb2] === Notebook;
If[ok, Print["PASS: ", mode, " verified (cells: ", Count[nb2, _Cell, Infinity], ")"]; Exit[0],
  CopyFile[backup, nbfile, OverwriteTarget -> True];
  die["post-write verification failed; .nb RESTORED from backup"]];
