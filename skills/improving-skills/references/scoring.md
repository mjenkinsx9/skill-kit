# Scoring

How `score-skill` composes the iteration score, and how to read
`results.tsv`.

## Contents

- [Composite](#composite)
- [Components](#components)
- [Reading results.tsv](#reading-resultstsv)
- [What the composite does NOT measure](#what-the-composite-does-not-measure)

## Composite

```
score = 0.4·trigger + 0.4·quality + 0.2·efficiency        (if harness=PASS)
score = -inf                                              (if harness=FAIL)
```

`harness=FAIL` immediately disqualifies the iteration, so the loop will
always revert it regardless of the other components. This is the
"best-practices floor": no candidate is allowed to degrade structural
quality, even if it gains on triggers or tokens.

## Components

### trigger (0–1)

For each row in `test-prompts.md` (positive + negative), dispatch `eval.json`'s
`trigger_prompt` to a **fresh sub-agent with clean context** (never inline — the
orchestrator knows the skill and would contaminate the judgment): "Given ONLY
this skill description … would you invoke this skill for the prompt …? Reply
`yes`/`no`."

Score = (correct positives + correct negatives) / total prompts.

Positive prompts the candidate fires on count as correct; negative prompts
it declines to fire on count as correct. Both directions matter — a
description that fires on everything is just as bad as one that fires on
nothing.

**Simulated vs empirical.** The above is the **simulated** scorer: a sub-agent
*predicts* whether it would fire. That is cheap enough to run every iteration, but
it is the model judging its own behavior. Setting `eval.json` `trigger_mode:
empirical` swaps in `${CLAUDE_PLUGIN_ROOT}/reference/trigger-accuracy.md`, which spawns real sub-agents on the
fixtures and *observes* the actual `Skill` call (accuracy = `(tp+tn)/total`, the same
formula — so the composite is unchanged). Empirical is expensive, so even when the
loop runs simulated, it measures empirical **once at loop end** and records both; a
wide simulated-minus-empirical gap means the description reads better than it fires.

### quality (0–1)

LLM-as-judge against the **target skill's `tests.md`** scenarios, each judge in
a **fresh sub-agent with clean context**. For each scenario in
`.skill-kit/runs/<run-id>/skill/tests.md`:

1. Have Claude execute the candidate skill on the scenario's `Input`.
2. Hand a fresh judge sub-agent `eval.json`'s `quality_judge.prompt` (the
   candidate SKILL.md + the scenario's `Expected behavior` + the actual output).
   It rates the value-add rubric's five dimensions — rigor, evidence,
   actionability, risk-awareness, signal-to-noise — and returns their mean as a
   single 0–10. This replaces the old ad-hoc "adhere to purpose" prompt; the
   shared rubric keeps quality scoring consistent with the value-add test.
3. Average over scenarios, divide by 10.

`tests.md` is the source of truth for quality — its scenarios already enumerate
golden / edge / error behavior. Reusing them keeps fixtures consolidated and
forces the run to grapple with edge and error cases, not just the happy path.

If `tests.md` is missing or has fewer than 3 scenarios, surface that to the
user before starting the loop and ask them to populate it. Don't synthesize
scenarios — the whole point of tests.md is that it captures real runs, not
imagined ones.

This catches regressions where a candidate "wins" trigger accuracy by
broadening the description, but the body no longer instructs Claude well on
the actual scenarios the skill must handle.

### efficiency (0–1)

```
efficiency = min(1.0, baseline_tokens / candidate_tokens)
```

`baseline_tokens` is the iteration-0 word count × 1.3. The min(1.0) clamp
means making the skill larger does NOT help the score — it only rewards
reduction. The 0.2 weight keeps token-shrinking from dominating.

## Reading results.tsv

```
iter  score  trigger  quality  tokens  harness  kept  edit_summary
0     0.612  0.70     0.55     840     PASS     -     baseline
1     0.638  0.75     0.55     820     PASS     yes   tightened description triggers
2     0.601  0.70     0.55     820     PASS     no    rewrote steps as table
3     -inf  -        -        650     FAIL     no    accidentally first-person
4     0.671  0.80     0.55     780     PASS     yes   added negative-trigger language
```

- **score column**: the composite, or `-inf` for harness failures.
- **trigger / quality / tokens**: raw values, useful for diagnosing why a
  candidate was rejected.
- **kept**: `yes` means committed on the scratch branch; `no` means
  reverted; `-` for baseline.
- **edit_summary**: free text the agent wrote when proposing the edit.

A healthy run shows the score climbing in fits and starts, with most
iterations either improving or reverted. A flat results.tsv means the loop
isn't finding improvements — usually because the test prompts are too
loose or the program.md goals are too vague.

## What the composite does NOT measure

The composite tells you a skill is *well-formed, on-target, and tight*. It does
**not** tell you the skill *beats just asking the model*. A skill can sit at
composite ~0.97 — trigger and quality near 1.0 — and still **lose a blind
head-to-head to the cold model**, because the composite rewards producing the
skill's prescribed format and has no way to see that the format is *burying* the
skill's value (process scaffolding crowding out the substance).

So a maxed composite means *this metric is exhausted*, not *this skill is good*.
When the loop plateaus near the ceiling, do not conclude the skill is done — run
the **value-add test** (`${CLAUDE_PLUGIN_ROOT}/reference/value-add-test.md`): the skill's real output vs a
no-skill baseline on representative seeds, blind-judged. If the skill loses or
ties, the next improvement lives *outside* the composite (usually: lead with
substance, demote the process machinery), not in another iteration of the loop.

The loop now runs this check automatically once at the end for generative
targets (SKILL.md Step 5) and records the verdict in `results.tsv` — so a run
can't quietly conclude on a maxed composite without it.
