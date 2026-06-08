# Loop mechanics

The modify → verify → keep-or-revert cycle. Loaded only when running an
improving-skills session.

## Iteration

The fixtures (`test-prompts.md`, `tests.md`) are copied into `.skill-kit/runs/<run-id>/` at
run start and **frozen** there for the whole loop — every iteration scores
against the same fixtures so the composite is comparable across iterations. Don't
edit the source fixtures mid-run; if they need to change, that's a new run.

Repeat until a stopping condition fires:

1. **Read state.** Read the current `.skill-kit/runs/<run-id>/skill/SKILL.md` and the
   most recent rows of `results.tsv` to know what's been tried.
2. **Propose ONE change.** Pick a single improvement based on `program.md`
   goals. Examples of valid focused changes:
   - Tighten the `description` to better match firing/non-firing prompts
   - Replace a verbose paragraph with a 2-bullet summary
   - Promote a frequently-needed reference into the body (and remove the
     link) or vice versa
   - Remove a redundant section
   - Replace abstract language with a concrete example
   - Add a missing "When to use" sentence
3. **Apply the edit** to `.skill-kit/runs/<run-id>/skill/SKILL.md` using Edit. Do NOT
   touch any other file.
4. **Score the candidate.** The mechanical helper does what it can; the
   agent fills in the LLM-dependent parts:
   - Run
     `score-skill .skill-kit/runs/<run-id>/skill/SKILL.md .skill-kit/runs/<run-id>/skill-baseline/SKILL.md`.
     It emits:
     ```
     harness=PASS|FAIL tokens=<int> efficiency=<float|NA> trigger=AGENT quality=AGENT composite=AGENT
     ```
     Both LLM-judged parts below run in **fresh sub-agents with clean
     context — never inline.** The orchestrator has already read the skill,
     so judging in-context would contaminate the score (same isolation rule
     as `${CLAUDE_PLUGIN_ROOT}/reference/value-add-test.md`). Use the exact prompts in `eval.json`
     (`trigger_prompt`, `quality_judge.prompt`) so scoring is reproducible.
   - **trigger:** depends on `eval.json` `trigger_mode`. **`simulated`** (default,
     cheap): for every row in `test-prompts.md`, dispatch the `trigger_prompt`
     (substituting the candidate `description` and the row's prompt) to a fresh
     sub-agent; it replies yes/no. **`empirical`**: run `${CLAUDE_PLUGIN_ROOT}/reference/trigger-accuracy.md`,
     which spawns real sub-agents and OBSERVES the actual `Skill` call instead of
     predicting it. Either way compute `trigger` as correct / total (positives that
     fire + negatives that decline) — the same accuracy formula, so the composite is
     unchanged.
   - **quality:** for each scenario in `.skill-kit/runs/<run-id>/skill/tests.md`, run the
     skill on the scenario's `Input`, then hand a fresh judge sub-agent the
     `quality_judge.prompt` (skill instructions + `Expected behavior` +
     output). It returns a single 0–10 (mean of the value-add rubric's five
     dimensions). Average over scenarios, divide by 10 → `quality`. If
     tests.md is missing or has < 3 scenarios, stop the loop and ask the user
     to populate it first.
   - Compute `composite = 0.4·trigger + 0.4·quality + 0.2·efficiency`
     (efficiency defaults to 1.0 when `NA`). If `harness=FAIL`, set
     `composite = -inf`.
5. **Decide.**
   - If `harness=FAIL` → revert (`git -C .skill-kit/runs/<run-id>/skill checkout SKILL.md`).
     Record the attempt in `results.tsv` with `kept=no`.
   - If `score > best_score_so_far` → keep. Commit on the scratch branch
     with message `iter <N>: <one-line description of edit>`. Update
     `best_score`. Record with `kept=yes`.
   - Otherwise → revert. Record with `kept=no`.

## Stopping conditions

Stop when ANY of these holds. The numeric thresholds are heuristics that live in
`eval.json` (`stopping`, `weights`) and are tunable per run — see the
`_comment` fields there for the rationale behind each default.

- **Iteration cap reached.** Default 20 (`stopping.max_iterations`).
- **Stuck.** No score improvement in the last `stopping.no_improvement_for`
  iterations (default 5 — enough tries to escape a local max).
- **Floor hit.** Composite has been ≥ `stopping.score_ceiling` (default 0.95)
  for two consecutive iterations (further marginal gains aren't worth the loop
  time; the composite is effectively exhausted).
- **User interrupt.** The user types Ctrl-C or asks to stop.

Once stopped, run two loop-end milestones on the final candidate — **never
per-iteration**, neither part of the per-iteration composite:
- The **value-add check** (SKILL.md Step 5).
- The **empirical trigger-accuracy** harness (`${CLAUDE_PLUGIN_ROOT}/reference/trigger-accuracy.md`), even when
  the loop scored trigger in `simulated` mode. Record both as
  `Trigger (simulated / empirical)` so a gap between *predicted* and *observed* firing
  is visible before promotion.

## results.tsv format

Append one row per iteration, tab-separated:

```
iter	score	trigger	quality	tokens	harness	kept	edit_summary
0	0.612	0.70	0.55	840	PASS	-	baseline
1	0.638	0.75	0.55	820	PASS	yes	tightened description triggers
2	0.601	0.70	0.55	820	PASS	no	rewrote steps as table
```

Iteration 0 is always the unmodified baseline.

## Recovery

If the loop crashes mid-iteration, `results.tsv` is the source of truth.
Read the last row; if `kept=yes`, the file on disk reflects that iteration.
If `kept=no`, run a `git -C .skill-kit/runs/<run-id>/skill checkout SKILL.md` to
ensure the file matches the last kept iteration.
