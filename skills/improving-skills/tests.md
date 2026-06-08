# Tests for improving-skills

Verification scenarios. These are illustrative until the loop has been
exercised end-to-end against a real skill; refresh `Last verified` and
the "Verified output" sections after the first real run.

Last verified: 2026-05-13

## Golden path: tighten an existing skill

**Input:** `/improving-skills examples/reviewing-pull-requests/SKILL.md`
where the target ships a populated `test-prompts.md`.

**Expected behavior:**
1. Copies the target into `runs/<run-id>/skill/`.
2. Scores baseline; appends iter 0 row to `results.tsv`.
3. Proposes one focused edit per iteration, scores via
   `scripts/score-skill.sh`, keeps improvements / reverts the rest.
4. Stops on iteration cap, no-improvement-for-5, or score ≥ 0.95.
5. Emits a final summary citing baseline score, best score, token delta,
   and the path to `results.tsv`.

**Verified output:** TBD — refresh after first end-to-end run.

## Edge case: missing test-prompts.md

**Input:** `/improving-skills <skill-with-no-test-prompts>`.

**Expected behavior:** Skill detects the missing file and asks the user
to author `test-prompts.md` before continuing rather than running the
loop with zero discrimination data.

**Verified output:** TBD.

## Edge case: every mutation fails the harness

**Input:** A skill where small edits keep tripping the third-person or
description-length FAIL.

**Expected behavior:** Auto-revert each FAIL'd iteration, log them with
`harness=FAIL kept=no` in `results.tsv`, and stop on the
no-improvement-for-5 condition rather than looping indefinitely.

**Verified output:** TBD.

## Error case: target path does not exist

**Input:** `/improving-skills nonexistent/path/SKILL.md`.

**Expected behavior:** Reports the missing file plainly and stops before
creating a run directory. Does not silently fall back to a default.

**Verified output:** TBD.
