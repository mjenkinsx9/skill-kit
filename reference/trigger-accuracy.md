# Trigger-accuracy test (empirical)

**The question the static harness and the improving-skills composite cannot answer: does the
description *actually* fire the skill on the prompts it should, and decline on the ones it
shouldn't — in this real environment?** `check-skill.sh` lints the description's *shape* (Checks
7/7b/8). The improving-skills loop scores triggering by **simulation** — it asks a fresh sub-agent
*"given only this description, would you invoke this skill?"*, which is the model **predicting its
own behavior**. This test instead **observes the real decision**: it gives a sub-agent the raw user
prompt and watches whether the `Skill` tool actually fires.

> **Milestone / pre-promotion check, not per-edit.** It spawns one sub-agent per prompt-run
> (`N_prompts × runs`, e.g. 20×3 = 60). Run it once at the end of an improving-skills loop, before
> promoting a skill whose triggering matters, or on demand to debug a skill that mis-fires.

## What it measures — and what it can't

- **Installed-mode, real competition.** The sub-agent inherits this session's *entire* live skill
  registry — the repo's skills **plus every global plugin/user skill**. So the number answers *"does
  this skill fire and win against everything else you have loaded?"* Collisions are **signal**: if a
  positive is stolen by another skill, that is a real triggering problem, and the harness names the
  thief in `other_skill_fired`.
- **No isolation is available** (established by spike, 2026-06-01): sub-agents inherit the parent
  registry, so a worktree can't isolate skills; and `claude -p` only hides *project* skills while
  global plugins still load. Measuring a description "in a vacuum" isn't achievable here, and isn't
  the question worth asking in a crowded skill environment anyway.
- **Fidelity caveat:** triggering is measured in a **sub-agent** context, which is close to but not
  identical to a top-level user turn. Treat the number as a strong empirical signal, not a
  guarantee of the exact main-session rate. It is still far better than self-prediction.

## Prerequisites

- The skill is **discoverable** — it lives in `<skill-dir>/` (this build live-loads new
  skill dirs mid-session). To measure a skill from `staging/` or `examples/`, copy it in first.
- The skill ships a `test-prompts.md` in the canonical `y | prompt` / `n | prompt` format (≥1
  positive and ≥1 negative). The numbered-list legacy format is unsupported.

## Procedure (orchestrator-driven)

The spawn loop is Claude-driven; `trigger-accuracy` does the deterministic parsing,
detection, and aggregation.

### 1. No-op the skill body (so target fires are cheap)
Triggering is decided from the **name + description before the body loads**, so replacing the body
does not bias the decision — but it stops a fired skill from running its real (expensive) procedure.
Back up the real file, then write a probe body that keeps the frontmatter **unchanged**:

```
---
name: <name>
description: <the exact description under test — DO NOT change>
---

# <name>

Trigger probe: when this skill is invoked, reply with exactly `TRIGGER-PROBE-FIRED`
and do nothing else.
```

`cp <skill-dir>/SKILL.md /tmp/<name>.SKILL.bak` first; restore it in step 5.

### 2. Parse the fixtures
```bash
trigger-accuracy parse-prompts <skill-dir>/test-prompts.md
```
Emits `[{prompt, should_fire}]`. Exits 2 on empty / legacy-format input.

### 3. Spawn one sub-agent per prompt-run
For each prompt, spawn `runs` (default 3) Agent sub-agents (parallelize them). Each sub-agent's
prompt is the **raw fixture prompt** plus this neutral cap note (it must not hint which skill to
use):

> `[Trigger-probe harness: respond to the request above as you normally would. You do NOT need to
> complete it — once you've taken your first concrete step (e.g. invoking a skill or your first tool
> call), you may stop.]`

Record each sub-agent's returned `agentId`. Build `runs.json`:
```json
[{"prompt": "...", "should_fire": true, "agent_ids": ["abf781...", "..."]}]
```

### 4. Score
```bash
trigger-accuracy score runs.json --skill <name> \
  --skill-md <skill-dir>/SKILL.md
```
`score` resolves each `agentId` to its transcript
(`~/.claude/projects/*/*/subagents/agent-<id>.jsonl`), detects whether the target `Skill` fired
(or a `Read` of its `SKILL.md`), tallies per-prompt fire-rate vs the 0.5 threshold, and emits the
JSON contract (below) on stdout plus a human summary on stderr.

### 5. Restore and interpret
Restore the real SKILL.md from the backup. Read the verdict: `aggregate.trigger` (accuracy) is the
headline; `recall` low with populated `other_skill_fired` entries means a **competitor is stealing
positives**; `precision` low means the description is **over-firing on negatives** (sharpen it — keep the
scope's edges concrete so it declines near-misses: prompts that share keywords but need
something else).

## Output contract

```json
{
  "skill": "reviewing-pull-requests", "mechanism": "in-session-installed",
  "threshold": 0.5, "cli_version_tested": "2.1.159",
  "prompts": [{"query": "...", "should_fire": true, "fired_count": 3, "runs": 3,
               "rate": 1.0, "pass": true, "errors": 0, "other_skill_fired": null}],
  "aggregate": {"n": 20, "positives": 10, "negatives": 10, "inconclusive": 0,
                "tp": 9, "fp": 1, "tn": 9, "fn": 1,
                "precision": 0.9, "recall": 0.9, "accuracy": 0.9, "trigger": 0.9}
}
```

`aggregate.trigger` **= accuracy = (tp+tn)/n**, identical to the simulated trigger formula in
`${CLAUDE_PLUGIN_ROOT}/skills/improving-skills/references/scoring.md`, so it is a drop-in for that loop's composite.

## Cost, positioning, and caveats

- **Cost:** `N_prompts × runs` sub-agents. The no-op body keeps *target* fires cheap; a fired
  *competitor* still executes (rarer), so keep `runs` low (1 for a smoke test, 3 for a real
  measurement) and treat this as a milestone, never a per-edit gate.
- **Schema pinned to `claude` v2.1.159.** Detection keys on `tool_use` blocks with
  `name == "Skill"` and `input.skill`. If a CLI upgrade renames those, detection fails *safe*
  (counts as "did not fire") — re-run the validation in this repo's history after upgrading.
- **Errors, non-fires, and inconclusive:** a missing transcript counts as an `error` (excluded
  from the rate denominator), never as a silent non-fire. A run that completes without firing the
  target is a real non-fire. A prompt where **every** run errors (0 valid runs) is reported
  `inconclusive` — excluded from `n` and the score entirely, never counted as a correct decline,
  so a broken run (stale `agentId`s, a changed transcript layout) can't inflate the number. A
  nonzero `aggregate.inconclusive` means: re-run before trusting the result.
- Always restore the backed-up SKILL.md, even if the run is interrupted — the no-op body must not
  be left in place.
