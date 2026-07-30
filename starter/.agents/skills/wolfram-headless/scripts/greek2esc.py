#!/usr/bin/env python3
"""Convert literal Greek (and a few math) Unicode chars in .wls files to ASCII Wolfram
escapes, so wolframscript can't mojibake them. Usage: greek2esc.py file1.wls [file2.wls ...]
Edits in place. Run BEFORE any heavy wolframscript job. See the wolfram-headless skill."""
import sys, re
ESC = {'ω':r'\[Omega]','α':r'\[Alpha]','Λ':r'\[CapitalLambda]','Δ':r'\[CapitalDelta]',
       'π':r'\[Pi]','ε':r'\[Epsilon]','τ':r'\[Tau]','μ':r'\[Mu]','ξ':r'\[Xi]',
       'β':r'\[Beta]','γ':r'\[Gamma]','δ':r'\[Delta]','θ':r'\[Theta]','σ':r'\[Sigma]',
       'φ':r'\[Phi]','ψ':r'\[Psi]','ρ':r'\[Rho]','λ':r'\[Lambda]','κ':r'\[Kappa]',
       'ζ':r'\[Zeta]','η':r'\[Eta]','Γ':r'\[CapitalGamma]','Ξ':r'\[CapitalXi]',
       'Σ_code':r'\[CapitalSigma]'}
# comment-only math notation -> ASCII (safe; keeps comments parseable)
COMMENT = {'→':'->','⇒':'=>','∈':' in ','−':'-','—':'--','–':'-','≥':'>=','≤':'<=',
           '≠':'!=','¹':'^1','²':'^2','³':'^3','½':'1/2','×':'x','·':'.','…':'...','Σ':'Sum'}
for path in sys.argv[1:]:
    s = open(path, encoding='utf-8').read()
    n = sum(s.count(k) for k in ESC if not k.endswith('_code'))
    for k, v in ESC.items():
        if not k.endswith('_code'):
            s = s.replace(k, v)
    for k, v in COMMENT.items():
        s = s.replace(k, v)
    s = re.sub(r'[^\x00-\x7F]', '?', s)  # strip any stragglers
    open(path, 'w', encoding='utf-8').write(s)
    print(f"{path}: escaped {n} Greek code chars, ASCII-ized comments")
