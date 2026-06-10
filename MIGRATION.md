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

- [x] **Real-world portability test** — *run 2026-06-10 in a throwaway
      non-dev-bench project under a simulated install* (plugin `bin/` on PATH,
      `${CLAUDE_PLUGIN_ROOT}` + `${CLAUDE_PROJECT_DIR}` set). Verified: bare-name
      resolution for all six helpers, `score-skill`'s sibling-harness lookup,
      `.skill-kit/runs/` placement, Check 21 degrading to "no staging twin", and
      a full improving-skills loop (results in
      `skills/improving-skills/tests.md`). **Found and fixed a real portability
      bug:** `value-add-test` only parsed the legacy numbered-list fixture
      format, while the plugin's template (and `trigger-accuracy`) use canonical
      `y | prompt` rows — consumers following the template hit a hard error.
      Both twins now accept both formats, canonical preferred.
- [ ] **True marketplace-install smoke test.** The simulated environment covers
      the mechanics, but a real `/plugin marketplace add` + `/plugin install`
      in an interactive session is the last-mile check (namespaced `/skill-kit:`
      invocation, registry-installed triggering for the empirical
      trigger-accuracy harness).
- [x] **De-duplicate protocol assets** — *resolved by the repo split.*
      `value-add-test.{md,sh}` and `trigger-accuracy.{md,py}` now live in two
      independent repos: `eval/` is canonical in the skill-testing dev-bench, and
      `bin/` + `reference/` are canonical in this plugin. They are no longer two
      copies in one tree to collapse — each repo owns its own, and they evolve on
      their own cadence. ~~The methodology is stable, so drift risk is low.~~
      **Correction (2026-06-10):** drift risk was NOT low — one week after the
      split the dev-bench harness was 144 lines ahead (hardening, self-tests,
      new checks). Resynced in full; [SYNC.md](SYNC.md) now tracks every file
      pair and its intentional adaptations, with a pre-release drift check.
- [x] **2026-06-10 resync from the dev-bench.** Ported: hardened `check-skill`
      (mktemp scratch file, real Check 7 trigger lint, tree-wide Checks 10/12/13,
      Check 14b/14c fixes, new Check 21), value-add tally small-sample caveat,
      the `references/` + TOC restructure of `improving-skills` (now 0 FAIL /
      0 WARN under its own harness), the new `behavioral-check` live harness,
      the harness self-test suite + CI workflow (`tests/`,
      `.github/workflows/harness.yml`), and the MIT license. Plugin-only fixes
      in the same pass: `value-add-test` run dir → `.skill-kit/runs/`, dangling
      `writing-descriptions.md` pointer inlined.

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
