# Usage

## The `bin/` commands

Every helper is callable by bare name once the plugin's `bin/` is on `PATH`
(see [Installation](02-installation.md)).

```bash
# Lint a skill directory (or a SKILL.md directly) — exit 0 iff zero FAILs:
check-skill .claude/skills/my-skill

# Do the skill's documented commands still run against the real system?
behavioral-check .claude/skills/my-skill --dry-run

# Blind value-add baseline (preflight + tally; generation is agent-driven):
value-add-test .claude/skills/my-skill

# PATH shims for agent workflows/commands (print the exact protocol to load):
goal-new-skill goal.md
goal-improve-skill goal.md
improving-skills .claude/skills/my-skill/SKILL.md

# Empirical trigger smoke test with fresh Pi/Codex probe sessions:
trigger-accuracy run-probes .claude/skills/my-skill --runner pi --runs 1 --balanced --max-prompts 2
trigger-accuracy run-probes .claude/skills/my-skill --runner codex --runs 1 --balanced --max-prompts 2 --text-signal
```

## Slash commands

```
/skill-kit:goal-new-skill summarizing-prs             # interview → goal.md for a not-yet-written skill
/skill-kit:goal-improve-skill .claude/skills/my-skill # measurable target for an improvement run
/skill-kit:improving-skills .claude/skills/my-skill/SKILL.md
```

## The improving-skills loop

The improving-skills loop scores each candidate against a fixed composite —
**mechanical floor** (`check-skill` must pass every kept iteration), **trigger
accuracy** (positive + negative fixture prompts), **instruction quality**
(LLM-as-judge against the skill's own `tests.md` scenarios), and **token
efficiency** (rewards shrinking, never penalizes a smaller body) — then runs
the value-add baseline once on the final candidate, because a maxed composite
proves a skill is *tight*, not that it beats just asking the model. See
[scoring.md](../skills/improving-skills/references/scoring.md) and
[loop.md](../skills/improving-skills/references/loop.md).

> **Note:** the `goal-*` commands assume a `/goal` command in your environment —
> it is not part of this plugin or stock Claude Code. Without one, the generated
> `goal.md` still works as a manual acceptance checklist.

## Reference protocols

The protocols the loop runs at milestones are documented in `reference/`:

- [`behavioral-check.md`](../reference/behavioral-check.md) — live `tests.md`
  command runner
- [`trigger-accuracy.md`](../reference/trigger-accuracy.md) — empirical trigger
  measurement (Claude agent IDs or Pi/Codex transcripts)
- [`value-add-test.md`](../reference/value-add-test.md) — blind head-to-head
  value-add baseline

---

Back to the documentation index: [README.md](README.md)
