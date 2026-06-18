#!/usr/bin/env bash
# check-sync.sh - automated drift checker for the skill-testing dev-bench pairs.
#
# For every tracked dev-bench<->plugin pair (see SYNC.md), this diffs the two
# files and compares that diff, byte-for-byte, against a committed golden
# baseline in tools/sync-baseline/<slug>.diff. A golden baseline is the exact,
# reviewed set of intentional adaptations: if the live diff matches, the only
# difference between the two copies is the divergence SYNC.md already documents.
# Any deviation means the dev-bench moved (port it) or the plugin moved
# (document the new divergence and refresh the baseline) — either way, drift.
#
# It also asserts the five manifests share one version, the four rich manifests
# share the cross-harness metadata fields, and gemini-extension.json matches
# name+version.
#
# Usage:
#   DB=../skill-testing bash tools/check-sync.sh   # from the plugin repo root
#
# DB must point at a skill-testing checkout (default ../skill-testing). Exit 0
# means no undocumented drift; exit 1 lists every offending pair/field.
#
# To refresh a baseline after a reviewed, documented divergence:
#   diff "$DB/<ref>" "<tgt>" > tools/sync-baseline/<slug>.diff

set -u

DB="${DB:-../skill-testing}"
script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
baseline_dir="$script_dir/sync-baseline"

if [[ ! -d "$DB" ]]; then
    echo "error: dev-bench checkout not found at DB=$DB" >&2
    echo "usage: DB=../skill-testing bash tools/check-sync.sh" >&2
    exit 2
fi

# Tracked pairs as "ref|tgt|slug":
#   ref  - path under the dev-bench ($DB)
#   tgt  - path under the plugin repo root
#   slug - baseline file name (tools/sync-baseline/<slug>.diff)
pairs=(
  "eval/check-skill.sh|bin/check-skill|check-skill"
  "eval/value-add-test.sh|bin/value-add-test|value-add-test"
  "eval/value-add-test.md|reference/value-add-test.md|value-add-test-md"
  "eval/trigger-accuracy.py|bin/trigger-accuracy|trigger-accuracy"
  "eval/trigger-accuracy.md|reference/trigger-accuracy.md|trigger-accuracy-md"
  "eval/behavioral-check.py|bin/behavioral-check|behavioral-check"
  "eval/behavioral-check.md|reference/behavioral-check.md|behavioral-check-md"
  ".claude/skills/improving-skills/scripts/score-skill.sh|bin/score-skill|score-skill"
  ".claude/skills/improving-skills/scripts/token-count.sh|bin/token-count|token-count"
  ".claude/commands/goal-improve-skill.md|commands/goal-improve-skill.md|goal-improve-skill"
  ".claude/commands/goal-new-skill.md|commands/goal-new-skill.md|goal-new-skill"
  "eval/tests/run-self-tests.sh|tests/run-self-tests.sh|tests-run-self-tests"
  "eval/tests/test_eval_scripts.py|tests/test_eval_scripts.py|tests-test-eval-scripts"
  "LICENSE|LICENSE|license"
)

failed=0

for entry in "${pairs[@]}"; do
    ref="${entry%%|*}"
    rest="${entry#*|}"
    tgt="${rest%%|*}"
    slug="${rest#*|}"
    ref_path="$DB/$ref"
    tgt_path="$repo_root/$tgt"
    baseline="$baseline_dir/$slug.diff"

    if [[ ! -f "$ref_path" ]]; then
        echo "DRIFT $slug: dev-bench file missing: $ref" >&2
        failed=1
        continue
    fi
    if [[ ! -f "$tgt_path" ]]; then
        echo "DRIFT $slug: plugin file missing: $tgt" >&2
        failed=1
        continue
    fi
    if [[ ! -f "$baseline" ]]; then
        echo "DRIFT $slug: no golden baseline at tools/sync-baseline/$slug.diff" >&2
        failed=1
        continue
    fi

    # diff exits 1 when files differ; that is expected for diverged pairs. We
    # care only whether the diff TEXT matches the reviewed baseline. Compare via
    # process substitution so the runtime form matches the documented refresh
    # command (`diff ref tgt > baseline.diff`) byte-for-byte, trailing newline
    # included — no create-vs-check normalization skew.
    if ! diff -q "$baseline" <(diff "$ref_path" "$tgt_path") >/dev/null 2>&1; then
        echo "DRIFT $slug: $ref <-> $tgt diverges from its documented baseline" >&2
        echo "  refresh after review: diff \"\$DB/$ref\" \"$tgt\" > tools/sync-baseline/$slug.diff" >&2
        failed=1
    fi
done

# Fixtures must stay byte-identical across the split (SYNC.md: "fixtures
# byte-identical"). Any difference here — other than caches — is drift.
fx_diff="$(diff -r "$DB/eval/tests/fixtures" "$repo_root/tests/fixtures" 2>&1 \
    | grep -v '__pycache__' || true)"
if [[ -n "$fx_diff" ]]; then
    echo "DRIFT fixtures: eval/tests/fixtures <-> tests/fixtures differ:" >&2
    echo "$fx_diff" >&2
    failed=1
fi

# Manifest metadata sync. The five manifests must share one version; the four
# rich manifests must additionally share the cross-harness metadata; the Gemini
# extension (reduced shape) need only match name+version.
manifest_check="$(
python3 - "$repo_root" <<'PY'
import json, sys
root = sys.argv[1]
rich = [
    ".claude-plugin/plugin.json",
    ".plugin/plugin.json",
    ".codex-plugin/plugin.json",
    ".cursor-plugin/plugin.json",
]
gemini = "gemini-extension.json"
ref_path = rich[0]
data = {}
for m in rich + [gemini]:
    with open(f"{root}/{m}", encoding="utf-8") as fh:
        data[m] = json.load(fh)
ref = data[ref_path]
failed = False

# All five share version.
for m, d in data.items():
    if d.get("version") != ref.get("version"):
        print(f"MISMATCH {m}: version={d.get('version')!r} != {ref.get('version')!r}")
        failed = True

# Four rich manifests share the cross-harness metadata fields.
for field in ("name", "description", "author", "homepage", "repository", "license"):
    for m in rich:
        if data[m].get(field) != ref.get(field):
            print(f"MISMATCH {m}: {field}={data[m].get(field)!r} != {ref.get(field)!r}")
            failed = True

# Gemini must match name (version already checked above).
if data[gemini].get("name") != ref.get("name"):
    print(f"MISMATCH {gemini}: name={data[gemini].get('name')!r} != {ref.get('name')!r}")
    failed = True

sys.exit(1 if failed else 0)
PY
)"
manifest_rc=$?
if (( manifest_rc != 0 )); then
    echo "DRIFT manifests:" >&2
    echo "$manifest_check" >&2
    failed=1
fi

if (( failed )); then
    echo "check-sync: undocumented drift detected (see above)" >&2
    exit 1
fi

echo "check-sync: OK — every tracked pair matches its documented baseline."
exit 0
