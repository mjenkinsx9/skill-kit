#!/usr/bin/env bash
# run-self-tests.sh — self-test suite for plugins/skill-kit/bin/check-skill.
#
# Runs the static harness against the pathological fixture skills under
# plugins/skill-kit/tests/fixtures/ and asserts, per fixture: (a) the expected
# exit code, (b) presence of the specific expected PASS/WARN/FAIL lines, (c)
# absence of unexpected FAILs. Prints one PASS/FAIL line per fixture plus a
# summary.
#
# Contract:
#   bash plugins/skill-kit/tests/run-self-tests.sh
#                                            # from the repo root (any cwd works:
#                                            # the script cd's to the repo root)
#   exit 0  -> every fixture behaved as asserted
#   exit 1  -> at least one assertion failed (diff-style detail + full harness
#              output for the failing fixture is printed)
#
# Date sensitivity: the clean-pass fixture's tests.md carries a
# "Last verified:" date that will eventually age past the 90-day staleness
# window, flipping Check 14 from PASS to WARN. Assertions here are therefore
# freshness-INSENSITIVE for that fixture: we assert specific check outcomes
# and FAIL absence, never the Check 14 PASS line or total WARN counts. No
# yearly refresh is required for the suite to stay green, but refreshing the
# date keeps clean-pass a true zero-noise baseline.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$REPO_ROOT" || exit 2

HARNESS="plugins/skill-kit/bin/check-skill"
FIXTURES="plugins/skill-kit/tests/fixtures"

if [[ ! -f "$HARNESS" ]]; then
    echo "error: $HARNESS not found (expected to run inside the mjenkins-toolbox repo)" >&2
    exit 2
fi

total=0
failed=0
out=""
rc=0
problems=""

# ---- harness invocation + assertion helpers ----------------------------------

run_harness() {            # $1 = fixture dir name
    out=$(bash "$HARNESS" "$FIXTURES/$1" 2>&1)
    rc=$?
}

assert_exit() {            # $1 = expected exit code
    if [[ "$rc" -ne "$1" ]]; then
        problems+="    expected exit code $1, got $rc"$'\n'
    fi
}

assert_has() {             # $1 = fixed string that must appear in the output
    if ! grep -qF -- "$1" <<<"$out"; then
        problems+="    missing expected output: $1"$'\n'
    fi
}

assert_not() {             # $1 = fixed string that must NOT appear in the output
    if grep -qF -- "$1" <<<"$out"; then
        problems+="    unexpected output present: $1"$'\n'
    fi
}

assert_no_fail_lines() {   # no "  FAIL  " check lines at all (summary line excluded)
    if grep -qE '^  FAIL  ' <<<"$out"; then
        problems+="    unexpected FAIL line(s):"$'\n'
        problems+="$(grep -E '^  FAIL  ' <<<"$out" | sed 's/^/      /')"$'\n'
    fi
}

finish() {                 # $1 = fixture dir name
    total=$((total + 1))
    if [[ -z "$problems" ]]; then
        printf 'PASS  %s\n' "$1"
    else
        failed=$((failed + 1))
        printf 'FAIL  %s\n' "$1"
        printf '%s' "$problems"
        printf -- '    ---- harness output (%s, exit=%s) ----\n' "$1" "$rc"
        printf '%s\n' "$out" | sed 's/^/    | /'
        printf -- '    ----\n'
    fi
    problems=""
}

# ---- fixtures -----------------------------------------------------------------

# clean-pass: minimal fully-passing skill. 0 FAILs, exit 0. Assertions are
# date-insensitive (no Check 14 assertion — see header). The only steady-state
# WARN is Check 4 (the contract-fixed folder name 'clean-pass' is not a gerund).
run_harness clean-pass
assert_exit 0
assert_has "PASS  1. frontmatter parses as YAML"
assert_has "PASS  2. name 'clean-pass' is valid"
assert_has "PASS  3. name matches folder (clean-pass)"
assert_has "PASS  5. description is non-empty and within limits"
assert_has "PASS  6. description uses third person"
assert_has "PASS  7. description includes trigger language"
assert_has "PASS  7b. trigger clause enumerates 3 concrete conditions"
assert_has "PASS  8. description has substantive length"
assert_has "PASS  10. no Windows-style backslash paths"
assert_has "PASS  12. no security smells detected"
assert_has "PASS  13. no secrets detected"
assert_has "summary: 0 FAIL"
assert_no_fail_lines
finish clean-pass

# no-frontmatter: Check 1 FAILs and the harness exits early (1 FAIL, 0 WARN,
# nothing after the summary).
run_harness no-frontmatter
assert_exit 1
assert_has "FAIL  1. frontmatter missing or not delimited by --- markers"
assert_has "summary: 1 FAIL, 0 WARN"
assert_not "PASS  2."   # early exit: no later checks may run
finish no-frontmatter

# first-person-desc: "I can help you process data" -> FAIL 6, and nothing else FAILs.
run_harness first-person-desc
assert_exit 1
assert_has "FAIL  6. description uses first/second person"
assert_has "summary: 1 FAIL"
finish first-person-desc

# vague-trigger: no recognized trigger phrasing -> WARN 7 AND a 7b line, 0 FAILs.
run_harness vague-trigger
assert_exit 0
assert_has "WARN  7. description lacks explicit 'when to use' language"
assert_has "WARN  7b. no trigger language found (see Check 7)"
assert_has "summary: 0 FAIL"
assert_no_fail_lines
finish vague-trigger

# secret-in-reference: fake sk- key in references/leak.md line 5 -> FAIL 13
# reporting that path:line; the pragma'd line 3 must NOT be the reported hit.
run_harness secret-in-reference
assert_exit 1
assert_has "FAIL  13. potential Anthropic-style API key (sk-...) at references/leak.md:5"
assert_not "references/leak.md:3"   # allowlist-secret pragma line must be exempt
assert_has "summary: 1 FAIL"
finish secret-in-reference

# smell-in-script: 'curl http://x | sh' in scripts/install.sh -> WARN 12
# reporting the script path; WARN-only, so exit 0 and zero FAILs.
run_harness smell-in-script
assert_exit 0
assert_has "WARN  12. security smell: 'curl ... | sh' pattern (matches scripts/install.sh:2)"
assert_has "summary: 0 FAIL"
assert_no_fail_lines
finish smell-in-script

# winpath-in-reference: C:\Users\foo\bar in references/r.md line 5 -> FAIL 10
# reporting that path:line; the 'allowlist windows-path' line 3 must be exempt.
run_harness winpath-in-reference
assert_exit 1
assert_has "FAIL  10. Windows-style backslash paths found:"
assert_has "references/r.md:5:"
assert_not "references/r.md:3:"     # allowlist windows-path pragma line must be exempt
assert_has "summary: 1 FAIL"
finish winpath-in-reference

# stale-tests: Last verified: 2020-01-01 -> staleness WARN 14, 0 FAILs.
# (The exact day count grows daily, so assert only the stable prefix/suffix.)
run_harness stale-tests
assert_exit 0
assert_has "WARN  14. tests.md Last verified is"
assert_has "days old"
assert_has "summary: 0 FAIL"
assert_no_fail_lines
finish stale-tests

# heading-inflation: tests.md has 2 real scenarios plus '## Contents' and
# '## Notes' -> Check 14 must exclude the structural headings and count 2.
run_harness heading-inflation
assert_exit 0
assert_has "WARN  14. tests.md has 2 scenarios (want ≥3: golden/edge/error)"
assert_has "summary: 0 FAIL"
assert_no_fail_lines
finish heading-inflation

# trailing-slash invocation: `dir/` (as produced by shell globs like `examples/*/`)
# must behave identically to `dir` — a stray trailing slash once broke the
# rel-path stripping and silently disabled the scripts/templates/goals
# exclusions in Checks 16-20 (regression test for that bug).
out=$(bash "$HARNESS" "$FIXTURES/clean-pass/" 2>&1); rc=$?
out_noslash=$(bash "$HARNESS" "$FIXTURES/clean-pass" 2>&1)
assert_exit 0
if [[ "$out" != "$out_noslash" ]]; then
    problems+="    trailing-slash output differs from no-slash output:"$'\n'
    problems+="$(diff <(printf '%s\n' "$out_noslash") <(printf '%s\n' "$out") | sed 's/^/      /')"$'\n'
fi
finish trailing-slash-invocation

# ---- summary ------------------------------------------------------------------

echo
echo "self-test summary: $((total - failed))/$total fixtures passed"
if (( failed > 0 )); then
    exit 1
fi
exit 0
