# Gemini CLI — port status: **documented gap, no manifest shipped**

skill-kit does **not** ship a Gemini CLI extension. This page explains why, and
what a faithful port would actually require, so nobody mistakes the absence of a
manifest for an oversight.

## Why the other manifests don't transfer

Claude Code, Codex, Cursor, and Factory Droid all share the same packaging
model: a small JSON manifest plus auto-discovered `skills/<name>/SKILL.md`
directories and markdown `commands/`. skill-kit's portable core — the
`improving-skills` SKILL.md, the `goal-*` markdown commands, and the `bin/`
helpers that those workflows shell out to (`check-skill`, `score-skill`,
`behavioral-check`, …) — drops straight into that model. Adding a manifest that
points at the existing `skills/` and `commands/` directories is genuinely all
those harnesses need.

Gemini CLI uses a different model. An extension is described by a
[`gemini-extension.json`](https://geminicli.com/docs/extensions/reference/)
manifest whose primary surface is **MCP servers**, with custom commands authored
as **TOML** files under `commands/`. There is no `SKILL.md` primitive and no
mechanism that adds a plugin's `bin/` directory to the shell `PATH`. So the three
things that make skill-kit useful do not have a one-to-one mapping:

| skill-kit component | Gemini equivalent | Gap |
|---|---|---|
| `skills/improving-skills/SKILL.md` (model-invoked workflow) | none | No skills primitive — would have to be re-expressed as a custom command or MCP prompt |
| `commands/goal-*.md` (markdown slash commands) | `commands/*.toml` | Format mismatch — markdown bodies must be rewritten as TOML command definitions |
| `bin/*` helpers, auto-added to `PATH` | MCP server tools | No PATH injection — each helper must be wrapped and exposed as an MCP tool |

## What a faithful port would require

This is real work, not a manifest drop, which is why it is documented rather than
faked:

1. **An MCP server wrapping `bin/`.** Author a small server (the repo is
   bash + Python today, so a thin Node/Python MCP server) exposing
   `check-skill`, `score-skill`, `token-count`, `behavioral-check`,
   `trigger-accuracy`, and `value-add-test` as MCP tools, then declare it under
   `mcpServers` in `gemini-extension.json` using `${extensionPath}` for
   portability.
2. **TOML command conversion.** Re-author `commands/goal-new-skill.md` and
   `commands/goal-improve-skill.md` as `commands/*.toml`. The interview logic
   survives; the wrapper format changes.
3. **The autoresearch loop.** `improving-skills` is an agent-driven loop, not a
   single tool call. With no skills primitive it would need to live as a custom
   command that orchestrates the MCP tools above — the largest single piece of
   the port.

Until that MCP wrapper exists, a `gemini-extension.json` pointing at the current
directories would not function, so none is shipped.

## References

- Gemini CLI extensions reference: https://geminicli.com/docs/extensions/reference/
