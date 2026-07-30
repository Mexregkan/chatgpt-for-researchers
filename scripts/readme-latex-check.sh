#!/usr/bin/env bash
# readme-latex-check.sh
#
# Scan README.md (or another file) for LaTeX commands that GitHub/MathJax
# does not support, and suggest fixes.
#
# Usage: ./scripts/readme-latex-check.sh [file]
#        Default file: README.md
#
# GitHub renders math blocks using MathJax with a strict allowlist.
# Many standard LaTeX commands silently fail to render.

set -euo pipefail

FILE="${1:-README.md}"

if [[ ! -f "$FILE" ]]; then
    echo "File not found: $FILE"
    exit 1
fi

echo "=== GitHub README LaTeX compatibility check: $FILE ==="
echo ""

ISSUES=0

check() {
    local pattern="$1"
    local message="$2"
    local fix="$3"
    local matches
    matches=$(grep -n "$pattern" "$FILE" 2>/dev/null || true)
    if [[ -n "$matches" ]]; then
        echo "ISSUE: $message"
        echo "  Fix: $fix"
        echo "  Found at:"
        echo "$matches" | sed 's/^/    /'
        echo ""
        ISSUES=$((ISSUES + 1))
    fi
}

# Commands blocked by GitHub's MathJax allowlist
check '\\operatorname'   '\operatorname{} is not supported'       'Use \mathrm{} instead'
check '\\bm{'            '\bm{} (bold math) is not supported'     'Use \mathbf{} instead'
check '\\mathscr{'       '\mathscr{} is not supported'            'Use \mathcal{} instead'
check '\\mathbb{1}'      '\mathbb{1} may not render'              'Use \mathbf{1} or \mathbb{1} with caution'
check '\\boldsymbol{'    '\boldsymbol{} may not render'           'Use \mathbf{} instead'
check '\\hspace{'        '\hspace{} not supported in math mode'   'Remove or use \, \; \quad instead'
check '\\vspace{'        '\vspace{} not supported in math mode'   'Remove spacing command'
check '\\text{.*\\.'     '\text{} with nested LaTeX may fail'     'Keep \text{} content as plain text'
check '\\underbrace{'    '\underbrace{} may not render on GitHub' 'Remove or restructure expression'
check '\\overbrace{'     '\overbrace{} may not render on GitHub'  'Remove or restructure expression'

# Inline math style check
check '^\$[^`]'  'Inline math $...$ at line start may not render on GitHub' \
    'Use $`...`$ syntax for inline math: $`\xi(s)`$'

# Display math style check
check '^\$\$'    'Display math $$...$$ may render inconsistently' \
    'Use fenced math block: ```math ... ``` instead'

# Check for missing closing backtick in inline math
# (simplified — just flags bare $ usage not in code blocks)

echo "---"
if [[ $ISSUES -eq 0 ]]; then
    echo "No known issues found. (Note: this check is not exhaustive — verify in browser.)"
else
    echo "Found $ISSUES potential issue(s). Fix them and verify in browser before publishing."
fi
echo ""
echo "Tips:"
echo "  Inline math:  \$\`\\xi(s)\`\$"
echo "  Display math: \`\`\`math block \`\`\`"
echo "  Always check rendered output at github.com — tools can miss things."
