# skill-kit — migration status

Tracks the extraction of the skill-building workflow from the
[skill-testing](https://github.com/mjenkinsx9/skill-testing) dev-bench into this
self-contained, distributable plugin, now living in its own `mjenkins-toolbox`
marketplace repo. The plugin is canonical here; skill-testing keeps its own full
dev-bench harness (no shims), so the two repos evolve independently.

## Done

- [x] **Step 1 — harness canonical.** `eval/check-skill.sh` → `bin/check-skill`;
      `eval/check-skill.sh` is now a wrapper delegating to it. Proves the
      `bin/`-on-PATH pattern (bare-callable, `allowed-tools: Bash(check-skill *)`).
- [x] **Step 2 — `improving-skills` ported.** Skill moved to
      `skills/improving-skills/`; `score-skill` + `token-count` promoted to `bin/`
      (locate the harness as a sibling, no repo-root math); loop-end protocols
      (`value-add-test`, `trigger-accuracy`) bundled in `bin/` + `reference/`.
      All coupled paths rewritten:
  - `allowed-tools` → bare `Bash(check-skill *) Bash(score-skill *) Bash(token-count *)`
  - scratch dir `runs/` → `${CLAUDE_PROJECT_DIR}/.skill-kit/runs/`
  - protocol docs → `${CLAUDE_PLUGIN_ROOT}/reference/…`
  - invocation `/improving-skills` → `/skill-kit:improving-skills` (repo docs updated)
  - **Verified:** `check-skill` on the ported skill → 0 FAIL / 0 WARN; `score-skill`
    resolves its sibling harness (`harness=PASS`).
- [x] **`goal-*` commands ported.** Both moved into `commands/`
      (`/skill-kit:goal-new-skill`, `/skill-kit:goal-improve-skill`). Decoupled:
      `goal-new-skill` anchors at `.claude/skills/<name>/` (not `staging/`),
      dropped the stray Windows/PowerShell `mkdir` instruction; both use the bare
      `check-skill` harness and `.skill-kit/runs/` scratch dir. Repo docs +
      skeleton template renamespaced to `/skill-kit:`.

## Remaining

- [ ] **Real-world portability test.** Install the plugin in a throwaway
      *non-skill-testing* project and run `/skill-kit:improving-skills` end to end
      to confirm `${CLAUDE_PLUGIN_ROOT}` / PATH resolution outside this repo. This
      is the next ripe item — it gates the de-dup below.
- [x] **De-duplicate protocol assets** — *resolved by the repo split.*
      `value-add-test.{md,sh}` and `trigger-accuracy.{md,py}` now live in two
      independent repos: `eval/` is canonical in the skill-testing dev-bench, and
      `bin/` + `reference/` are canonical in this plugin. They are no longer two
      copies in one tree to collapse — each repo owns its own, and they evolve on
      their own cadence. The methodology is stable, so drift risk is low.

## Reconsidered: `agents/` — none earns its place yet

The `agents/` line was aspirational. Reconsidered against the repo's #1 rule
(codify from real practice, never imagination) — and **zero agents have ever been
exercised here; the repo is entirely about *skills***. Building speculative agent
files now would *be* the anti-pattern. Per-candidate verdict:

- **`skill-importer` — dropped.** Import (workflow 2) is `cp -r staging → .claude/skills`
  + the harness + a read. There's no judgment to encapsulate; a subagent adds
  indirection over a one-liner. Not an agent. (The risk-bearing part of import is
  security review — see below — not the copy.)
- **`security-reviewer` — deferred, pending real practice.** A read-only review
  subagent is a *plausible* fit for untrusted imported skills, but (a) it overlaps
  the built-in `/security-review` skill and the harness's existing security WARNs,
  and (b) nobody has yet actually reviewed a hostile imported skill here and
  captured the skill-specific checklist that should emerge (`staging/using-keeper-cli`
  touches a secrets manager — a genuine first candidate). Do the review for real
  once or twice, *then* decide subagent vs. a `reference/security-review.md`
  protocol layered on the harness.
- **`value-add-evaluator` — deferred, pending observed need.** Strongest
  rationale: a blind value-add verdict wants a *fresh, uncontaminated* context, and
  the loop's own context has spent N iterations "rooting for" the skill — bias the
  judge should not see. But this is already implemented as `bin/value-add-test` +
  `reference/value-add-test.md`, which the loop runs at the end. Promote it to a
  subagent the day the script-based blind test demonstrably leaks context bias —
  not on the theory that it might.

Net: agents are not a missing capability; they're an optimization that earns its
place only when an exercised workflow demands the isolation/tool-restriction a
subagent provides. None does today.

## Deliberately skipped

- **Promotion-gate hook.** Not needed: skill-kit operates on skills that already
  live in the user's repo (it improves + tests them in place); there's no
  `staging → promote` pipeline in a consumer project. A not-yet-authored skill is
  simply recommended to go where the user's other skills live (`.claude/skills/`).

## `prime` stays dev-bench

`prime` orients on *this repo's* CLAUDE.md / eval/README — nothing to port. It
remains a repo-local command, not part of the plugin.
