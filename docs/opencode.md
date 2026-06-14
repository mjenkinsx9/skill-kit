# OpenCode — port status: **documented gap, no plugin shipped**

skill-kit does **not** ship an OpenCode plugin. This page explains why, and what
a faithful port would require.

## Why the JSON manifests don't transfer

Every other supported harness loads a declarative JSON manifest and
auto-discovers `skills/<name>/SKILL.md` plus markdown `commands/`. skill-kit's
portable core slots into that model, so those ports are a manifest pointing at
the existing directories.

OpenCode is not declarative. Per the
[plugins docs](https://opencode.ai/docs/plugins/), a plugin is a
**JavaScript/TypeScript module** that exports one or more plugin functions; each
receives a context object (`project`, `directory`, `worktree`, `client`, and
Bun's `$` shell helper) and returns a hooks object. There is **no JSON
manifest** and **no `SKILL.md` primitive**. Plugins are loaded from
`.opencode/plugins/` (or `~/.config/opencode/plugins/`), or as npm packages
listed under `plugin` in `opencode.json`. The closest analogue to a skill is a
**custom tool** registered with the `tool()` helper (description + Zod arg schema
+ an `execute()` function).

None of skill-kit's three layers maps to that:

| skill-kit component | OpenCode equivalent | Gap |
|---|---|---|
| `skills/improving-skills/SKILL.md` | none (no skills primitive) | Workflow must be reimplemented as a custom tool / hooks |
| `commands/goal-*.md` | none (no markdown commands) | Interview logic must be re-authored in TS |
| `bin/*` helpers on `PATH` | `tool()` with `execute()` | Each helper must be wrapped as a TS tool shelling out via Bun `$` |

## What a faithful port would require

1. **A TS plugin module** under `.opencode/plugins/` (or published as an npm
   package) that registers custom tools wrapping the `bin/` helpers
   (`check-skill`, `score-skill`, `behavioral-check`, …), shelling out via the
   provided Bun `$` helper and declaring Zod schemas for their arguments.
2. **Re-authoring the workflows.** `improving-skills` and the `goal-*` commands
   have no declarative target here; their logic would move into the TS module as
   tools or hook handlers — a genuine reimplementation, not a re-point.

Because that is a rewrite rather than repackaging, no OpenCode plugin is shipped;
the gap is documented instead of faked.

## References

- OpenCode plugins docs: https://opencode.ai/docs/plugins/
