#!/usr/bin/env wolframscript
(* nb2wb_extract.wls <input.nb> <out.json>
   Extracts every cell of a Mathematica .nb IN ORDER as faithful input text,
   using the front end's own "InputText" linearisation (preserves comments,
   special chars, and the author's intended statement structure).
   Output: JSON list of <|"kind"->"code"|"md", "style"->..., "text"->...|>.
   A separate normalizer (wl_normalize.py) then makes code cells bridge-safe.
   This avoids the lossy "Package export + blank-line split" path, which broke
   cell boundaries and multi-line statements. *)

args = $ScriptCommandLine;
If[Length[args] < 3, Print["usage: nb2wb_extract.wls <input.nb> <out.json>"]; Exit[1]];
inFile = args[[2]]; outFile = args[[3]];

nb = Import[inFile];
If[Head[nb] =!= Notebook, Print["ERROR: not a Notebook: ", inFile]; Exit[1]];

(* cells in document order, with their style *)
cells = Cases[nb, Cell[c_, sty_String, ___] :> {sty, c}, Infinity];
codeStyles = {"Input", "Code"};

(* NOTE on line wrapping: the FE's "InputText" linearisation IGNORES PageWidth
   (tried as a Cell option, an ExportPacket option, and a wrapping-Notebook option —
   all still wrap a wide cell). A single soft-wrapped expression such as
     MMVbar[...] := (-1)^(...) MMV[...]   (one RowBox, " " = implicit Times)
   therefore exports with a HARD newline at the display-wrap point, AND a
   continuation INDENT after it:  "(-1)^(...)\n   MMV[...]".  Since the RHS up to the
   wrap is already complete, that newline would SPLIT the SetDelayed and silently drop
   the MMV factor. We do NOT try to prevent the wrap here (the FE won't cooperate, and
   re-linearising via MakeExpression+ToString would drop comments); instead the
   normaliser (wl_normalize.py) collapses these wraps using the tell-tale signal that
   FE wraps carry a continuation indent whereas genuine statement breaks export at
   column 0. KEEP comments intact in this faithful export; the normaliser is what makes
   the result bridge-safe. *)
inputText[boxes_, style_] := Module[{r},
  r = FrontEndExecute[FrontEnd`ExportPacket[Cell[boxes, style], "InputText"]];
  If[ListQ[r], First[r], ToString[r]]];

recs = UsingFrontEnd@Table[
   Module[{sty = cells[[i, 1]], c = cells[[i, 2]], txt},
    If[MemberQ[codeStyles, sty],
     txt = inputText[c, "Input"];
     <|"kind" -> "code", "style" -> sty, "text" -> txt|>,
     (* prose / heading cell: take plain text *)
     txt = Quiet@Check[inputText[c, sty], ToString[c, InputForm]];
     <|"kind" -> "md", "style" -> sty, "text" -> txt|>]],
   {i, Length[cells]}];

Export[outFile, recs, "JSON"];
Print["extracted ", Length[recs], " cells -> ", outFile];
