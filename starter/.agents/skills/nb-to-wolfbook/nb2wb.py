#!/usr/bin/env python3
"""nb2wb.py <input.nb> [output.wb]

Faithful, bridge-safe .nb -> .wb converter.

Pipeline:
  1. nb2wb_extract.wls (wolframscript) reads the .nb and emits every cell, in
     order, as faithful InputText via the front end (preserves comments, special
     characters, and the author's statement structure).
  2. Code cells are passed through wl_normalize.normalize, which puts each
     statement on a single physical line (collapsing only intra-statement
     newlines). This removes the two failure modes that corrupt cells when an
     evaluator splits on newlines:
       - "Incomplete expression" on a single statement wrapped over many lines;
       - newline-as-implicit-Times turning `a:=...; \n b:=...` into Times[...] or
         dropping a trailing factor (`(-1)^k \n MMV[...]`).
     The FE's InputText export ignores PageWidth and wraps wide cells with a
     continuation INDENT after the newline; normalize() uses that indent as the
     signal to collapse the wrap (a line ending in a complete value like `)` fools a
     pure end-of-line-operator heuristic — that gap is what produced the MMVbar bug).
  3. Runs wl_normalize.find_split_hazards on every code cell and warns about any
     residual definition-split (belt-and-braces; should be empty after normalize).
  4. Writes a VS Code Notebook .wb (JSON, indent=1).

Run:  python3 nb2wb.py "<file.nb>"
"""
import json, os, subprocess, sys
from importlib.machinery import SourceFileLoader

HERE = os.path.dirname(os.path.abspath(__file__))
norm = SourceFileLoader("wl_normalize", os.path.join(HERE, "wl_normalize.py")).load_module()

MD_STYLES = {  # .nb cell style -> markdown heading prefix
    "Title": "# ", "Section": "## ", "Subsection": "### ",
    "Subsubsection": "#### ", "Text": "", "Item": "- ", "ItemNumbered": "- ",
}

def extract(nb_path):
    out_json = nb_path + ".cells.json"
    wls = os.path.join(HERE, "nb2wb_extract.wls")
    subprocess.run(["wolframscript", "-file", wls, os.path.abspath(nb_path),
                    os.path.abspath(out_json)], check=True)
    recs = json.load(open(out_json))
    os.remove(out_json)
    return recs

def to_wb_cell(rec):
    text = rec.get("text", "")
    if rec.get("kind") == "code":
        value = norm.normalize(text)
        return {"kind": 2, "languageId": "wolfram", "value": value,
                "metadata": {}, "outputs": []}
    style = rec.get("style", "Text")
    prefix = MD_STYLES.get(style, "")
    value = prefix + text.strip()
    return {"kind": 1, "languageId": "markdown", "value": value,
            "metadata": {}, "outputs": []}

def main():
    if len(sys.argv) < 2:
        print("usage: nb2wb.py <input.nb> [output.wb]"); sys.exit(1)
    nb_path = sys.argv[1]
    wb_path = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(nb_path)[0] + ".wb"
    recs = extract(nb_path)
    cells = [to_wb_cell(r) for r in recs]
    nb = {"cells": cells,
          "metadata": {"kernelspec": {"displayName": "Wolfram Language",
                                       "language": "wolfram", "name": "wolfram"}}}
    with open(wb_path, "w", encoding="utf-8") as f:
        f.write(json.dumps(nb, indent=1, ensure_ascii=False))
    ncode = sum(1 for c in cells if c["kind"] == 2)
    # belt-and-braces: report any residual statement-split hazard
    haz = []
    for c in cells:
        if c["kind"] == 2:
            haz += norm.find_split_hazards(c["value"])
    suffix = "bridge-safe" if not haz else f"WARNING: {len(haz)} split hazard(s) — run --check"
    print(f"Converted: {os.path.basename(nb_path)} -> {os.path.basename(wb_path)} "
          f"({ncode} code cells, {len(cells)-ncode} markdown cells, {suffix})")
    for a, b in haz[:10]:
        print(f"  HAZARD: ...{a[-50:]!r}  +SPLIT+  {b[:50]!r}...")

if __name__ == "__main__":
    main()
