---
name: improving-skills
description: Iteratively improves an agent skill's SKILL.md by mutating it, scoring against a fixed composite (trigger accuracy, instruction quality, token efficiency, best-practices compliance), and keeping only changes that raise the score. Use when the user asks to tighten, shrink, or improve a SKILL.md while preserving its intended behavior.
disable-model-invocation: true
allowed-tools: Read Edit Write Bash(check-skill *) Bash(score-skill *) Bash(token-count *) Bash(git *) Bash(mkdir *) Bash(cp *)
---

# Improving Skills

Adapts the autoresearch loop (modify → verify → keep-or-revert) for one
purpose only: improving SKILL.md files. The target is always a single
SKILL.md; no prompts, no agents, no generic code optimization.

## When to use

The user wants to autonomously improve a specific SKILL.md — phrasings like
"tighten this skill", "shrink the skill body without losing capability",
"make this skill trigger more reliably", "run autoresearch on the X skill".

Always invoked manually via `/skill-kit:improving-skills`. The skill has
`disable-model-invocation: true` so it never auto-fires.

## Steps

1. **Set up the run.** Take the target SKILL.md path from the user. Copy
   the entire skill directory to `.skill-kit/runs/<run-id>/skill/` (run-id is a short
   timestamp like `2026-05-13-1542`). Initialize a scratch git branch for
   the run.
2. **Read configuration.** Copy templates from this skill's `templates/`
   into `.skill-kit/runs/<run-id>/` if not already present:
   - `program.md` — goals and constraints. If `<skill-dir>/goal.md` exists
     (drafted via `/skill-kit:goal-improve-skill`), seed `program.md` from it
     instead of starting from the blank template.
   - `eval.json` — scoring config (paths, weights, iteration cap)
   - `test-prompts.md` — positive + negative trigger fixtures (drives the
     trigger-accuracy dimension)
   Verify the target ships a `tests.md` sidecar with ≥3 scenarios — the
   quality dimension scores candidates against those scenarios. If
   `test-prompts.md` or `tests.md` is missing/empty, stop and ask the
   user to populate it before starting the loop.
3. **Score the baseline.** Run
   `score-skill .skill-kit/runs/<run-id>/skill/SKILL.md`
   and record the composite as iteration 0 in `.skill-kit/runs/<run-id>/results.tsv`.
4. **Run the loop.** See [loop.md](references/loop.md) for the iteration mechanics
   and stopping conditions.
5. **Value-add check.** When the loop stops, run the value-add test
   (`${CLAUDE_PLUGIN_ROOT}/reference/value-add-test.md`) **once** on the
   final kept candidate — the composite proves the skill is well-formed, not
   that it beats just asking the model. Skip only if the target is *not* a
   generative/judgment skill (deterministic / safety / format-compliance); then
   record `Value-add verdict: N/A (non-generative)`. Record the verdict
   (`PASS / CONCERN / FAIL`, lift, seeds) in `.skill-kit/runs/<run-id>/results.tsv` and the
   report. A **FAIL** means the composite gains never reached the user (usually
   scaffolding burying substance) — recommend the substance-first remedy and do
   **not** call the skill done. This runs once at loop end, never per-iteration
   (it spawns ~4N sub-agents). See [scoring.md](references/scoring.md) → "What the composite
   does NOT measure".
6. **Report.** Summarize: starting score, best score, number of iterations,
   what changed in the winning candidate, and the value-add verdict. Point the
   user at `.skill-kit/runs/<run-id>/skill/SKILL.md` and the `results.tsv` audit log.

## Constraints

- One focused change per iteration. Resist the urge to refactor multiple
  things at once.
- Never modify frontmatter field names (`name`, `description`) — only their
  values. Renaming `description` to `desc` would break discovery.
- Never drop below the harness floor: every kept iteration must pass
  `check-skill` cleanly (zero FAILs).
- Preserve the skill's intended behavior. If `test-prompts.md` says a
  prompt should fire, the candidate must keep it firing.

## Output format

After the loop stops, emit:

```
## Improving-skills run <run-id>

- Target: <path>
- Iterations: <n>
- Baseline score: <score>
- Best score:     <score> (iteration <k>)
- Token reduction: <baseline_tokens> → <best_tokens> (<percent>%)
- Trigger (simulated / empirical): <sim> / <emp>
- Value-add verdict: <PASS|CONCERN|FAIL, lift, seeds | N/A (non-generative)>

## What changed

<2-4 bullets describing the surviving edits>

## Audit log

.skill-kit/runs/<run-id>/results.tsv
.skill-kit/runs/<run-id>/skill/SKILL.md
```

## Details

- Loop mechanics, retry behavior, stopping conditions: [loop.md](references/loop.md)
- Scoring composite and how to interpret results.tsv: [scoring.md](references/scoring.md)
- Empirical trigger measurement (real firing vs simulated prediction):
  `${CLAUDE_PLUGIN_ROOT}/reference/trigger-accuracy.md`
