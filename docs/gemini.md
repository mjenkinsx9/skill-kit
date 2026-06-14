# Gemini CLI — port status: **ported (skills layer), with caveats**

skill-kit ships a Gemini CLI extension: [`gemini-extension.json`](../gemini-extension.json)
at the repo root. This page records exactly what ports and what doesn't.

## What ports

Per the [Gemini CLI extensions reference](https://geminicli.com/docs/extensions/reference/),
an extension can **bundle agent skills**:

> "Bundle agent skills to provide specialized workflows. Place skill
> definitions in a `skills/` directory. For example, `skills/security-audit/SKILL.md`
> exposes a `security-audit` skill."

That is the same `skills/<name>/SKILL.md` layout skill-kit already uses, and it
is **auto-discovered** — no manifest field points at it. So the portable core,
`skills/improving-skills/SKILL.md`, loads in Gemini CLI exactly as it does in
Claude Code. The manifest only needs the identifying fields:

```json
{ "name": "skill-kit", "version": "0.2.0", "description": "…" }
```

`name` and `version` are the required fields; `description` is for display.
Metadata is kept in sync with `.claude-plugin/plugin.json`.

## What does NOT port automatically

Two layers don't transfer one-to-one, which is why this is "ported with
caveats" rather than a clean drop-in:

1. **Slash commands are TOML, not markdown.** Gemini reads custom commands from
   `commands/*.toml` ("Provide custom commands by placing TOML files in a
   `commands/` subdirectory"). skill-kit's `commands/goal-new-skill.md` and
   `commands/goal-improve-skill.md` are markdown, so they are **not** picked up
   as Gemini commands. The interview logic would need re-authoring as TOML to
   expose `/goal-new-skill` etc. in Gemini. The skills layer does not depend on
   these commands, so the core still works without them.
2. **`bin/` is not auto-added to `PATH`.** Claude Code puts a plugin's `bin/` on
   the shell `PATH`, which is why `check-skill`, `score-skill`, etc. are callable
   by bare name. Gemini has no equivalent injection, so the SKILL.md's documented
   commands resolve only if the helpers are reachable some other way (e.g. the
   user puts `bin/` on `PATH`, or invokes them by repo-relative path). This is a
   shared caveat across every non-Claude-Code harness here, not unique to Gemini.

## Optional future work

To make the command and helper layers first-class in Gemini, convert the
`goal-*` commands to TOML and/or wrap the `bin/` helpers behind an MCP server
declared under `mcpServers` in `gemini-extension.json` (using `${extensionPath}`
for portability). Neither is required for the skills layer to function.

## References

- Gemini CLI extensions reference: https://geminicli.com/docs/extensions/reference/
