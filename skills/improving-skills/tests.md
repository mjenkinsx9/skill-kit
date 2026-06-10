# Tests for improving-skills

Verification scenarios, exercised end-to-end on 2026-06-10 against a toy
`writing-commit-messages` skill in a throwaway non-dev-bench project, under a
simulated plugin install (plugin `bin/` on PATH, `CLAUDE_PLUGIN_ROOT` and
`CLAUDE_PROJECT_DIR` set — the same environment a real `/plugin install`
provides). Scoring sub-agents ran on a small model; loop-end value-add was
N/A (format-compliance target) and empirical trigger-accuracy was not
measurable (the target skill was not in the session's live registry — its
documented prerequisite). Re-verify after a true marketplace install.

Last verified: 2026-06-10

## Golden path: tighten an existing skill

**Input:** `/skill-kit:improving-skills .claude/skills/<name>/SKILL.md`
where the target ships a populated `test-prompts.md`.

**Expected behavior:**
1. Copies the target into `.skill-kit/runs/<run-id>/skill/`.
2. Scores baseline; appends iter 0 row to `results.tsv`.
3. Proposes one focused edit per iteration, scores via
   `score-skill`, keeps improvements / reverts the rest.
4. Stops on iteration cap, no-improvement-for-5, or score ≥ 0.95.
5. Emits a final summary citing baseline score, best score, token delta,
   and the path to `results.tsv`.

**Verified output (run 2026-06-10-1700, cap=3):** baseline composite 0.920
(trigger 6/6, quality 0.80, 242 tokens). Iter 1 (quality-targeted body
addition) scored 0.913 — quality rose to 0.83 but tokens grew, composite
dropped → reverted, exactly as the keep-or-revert rule demands. Iter 2
(deliberate first-person description) → `harness=FAIL`, composite −inf,
auto-reverted via the scratch-branch checkout. Iter 3 (removed a verbose
Background section, 242→166 tokens, −31%) scored 0.933 → kept, committed
on the scratch branch. Loop stopped at the cap; final `results.tsv` rows
matched the documented format byte-for-byte. One protocol note: small-model
judges sometimes returned prose instead of the mandated single integer —
the mean was extractable, but enforce the reply format in judge prompts.

## Edge case: missing test-prompts.md

**Input:** `/skill-kit:improving-skills <skill-with-no-test-prompts>`.

**Expected behavior:** Skill detects the missing file and asks the user
to author `test-prompts.md` before continuing rather than running the
loop with zero discrimination data.

**Verified output (2026-06-10):** the Step-2 precondition check found no
`test-prompts.md` in the target dir; the loop stopped before any scoring
and asked for the fixture. No run directory was created.

## Edge case: every mutation fails the harness

**Input:** A skill where small edits keep tripping the third-person or
description-length FAIL.

**Expected behavior:** Auto-revert each FAIL'd iteration, log them with
`harness=FAIL kept=no` in `results.tsv`, and stop on the
no-improvement-for-5 condition rather than looping indefinitely.

**Verified output (2026-06-10, partial):** the single-FAIL path is verified —
run 2026-06-10-1700 iter 2 (first-person description) produced
`harness=FAIL` from `score-skill`, composite −inf, an automatic
`git checkout SKILL.md` revert, and a `-inf … FAIL no` row in
`results.tsv`. The repeated-FAIL stop (no-improvement-for-5) was not
reached because the run's cap of 3 fired first; re-verify on a longer run.

## Error case: target path does not exist

**Input:** `/skill-kit:improving-skills nonexistent/path/SKILL.md`.

**Expected behavior:** Reports the missing file plainly and stops before
creating a run directory. Does not silently fall back to a default.

**Verified output (2026-06-10):** the missing target was reported at Step 1
and the run aborted; `.skill-kit/runs/` contained no new run directory
afterward.
