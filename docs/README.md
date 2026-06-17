# skill-kit documentation

Start here: the [Overview](01-overview.md) explains what skill-kit is and what's
inside the evaluation stack.

## Getting started

| Doc | Description |
|---|---|
| [01 · Overview](01-overview.md) | What skill-kit is, the core idea, the "what's inside" evaluation stack, requirements, and license |
| [02 · Installation](02-installation.md) | Install via the marketplace, the `bin/`-on-`PATH` convention, run artifacts, and requirements |
| [03 · Usage](03-usage.md) | The `bin/` commands, slash commands, the improving-skills scoring loop, and reference protocols |

## Using it

| Doc | Description |
|---|---|
| [03 · Usage](03-usage.md) | Lint / behavioral / value-add / trigger commands, `/skill-kit:` slash commands, and the scoring composite |
| [04 · Multi-harness support](04-harnesses.md) | Per-harness status, manifests, and install/load notes (Claude Code, Copilot CLI, Codex, Cursor, Gemini) |

## Reference

| Doc | Description |
|---|---|
| [05 · Repository layout](05-layout.md) | Map of manifests, `bin/` helpers, `commands/`, `skills/`, `reference/`, and `tests/` |
| [06 · Testing the tests](06-testing.md) | Running the self-test suite + pytest, and the relationship to the skill-testing dev-bench |
| [Gemini CLI port notes](gemini.md) | Exactly what ports to Gemini CLI (skills layer) and what doesn't (TOML commands, no `bin/` on `PATH`) |
| [behavioral-check protocol](../reference/behavioral-check.md) | Live `tests.md` command runner protocol the loop runs at milestones |
| [trigger-accuracy protocol](../reference/trigger-accuracy.md) | Empirical trigger measurement protocol (Claude agent IDs or Pi/Codex transcripts) |
| [value-add-test protocol](../reference/value-add-test.md) | Blind head-to-head value-add baseline protocol |
| [improving-skills · scoring.md](../skills/improving-skills/references/scoring.md) | The fixed composite each loop candidate is scored against |
| [improving-skills · loop.md](../skills/improving-skills/references/loop.md) | The modify → score → keep-or-revert loop mechanics |

## Project & meta

| Doc | Description |
|---|---|
| [AGENTS.md](../AGENTS.md) | Guidance for agents/humans working in the repo, test commands, and the release / version-bump guide |
| [SYNC.md](../SYNC.md) | The dev-bench ↔ plugin file-pairing table and the pre-release drift check |
| [MIGRATION.md](../MIGRATION.md) | Extraction history from the skill-testing dev-bench and design-decision record |

---

Back to the project README: [../README.md](../README.md)
