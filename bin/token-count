#!/usr/bin/env bash
# token-count.sh - cheap token approximation for a text file.
#
# Returns word count * 1.3 (rounded). Model-agnostic and sufficient for
# relative comparisons across iterations of the same skill. Not a substitute
# for a tokenizer when you need an absolute number.
#
# Usage:
#   token-count.sh <file>

set -u

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <file>" >&2
    exit 2
fi

if [[ ! -f "$1" ]]; then
    echo "error: file not found: $1" >&2
    exit 2
fi

words=$(wc -w <"$1" | tr -d ' ')
awk "BEGIN { printf \"%d\n\", $words * 1.3 + 0.5 }"
