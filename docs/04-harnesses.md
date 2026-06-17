# Multi-harness support

The Agent Skills (`SKILL.md` files) are the portable core, so skill-kit ships
sibling manifests that point the same `skills/` and `commands/` directories at
several agent CLIs. No content is moved or duplicated — each manifest just
re-points the existing tree.

| Harness | Status | Manifest | Install / load | Docs |
|---|---|---|---|---|
| **Claude Code** | ✅ ported · validated (`claude plugin validate . --strict`) | `.claude-plugin/plugin.json` | `/plugin marketplace add mjenkinsx9/mjenkins-toolbox` then `/plugin install skill-kit@mjenkins-toolbox` | [docs](https://code.claude.com/docs/en/plugins-reference) |
| **GitHub Copilot CLI** | ✅ ported (skills + commands) | `.plugin/plugin.json` | install the plugin per Copilot CLI; `.plugin/plugin.json` is first in its manifest search path | [docs](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference) |
| **OpenAI Codex** | ✅ ported · install-validated with Codex CLI | `.codex-plugin/plugin.json` | install via Codex plugins / `.agents/plugins/marketplace.json` catalog | [docs](https://developers.openai.com/codex/plugins/build) |
| **Cursor** | ✅ ported (manifest conforms to schema; not locally validated) | `.cursor-plugin/plugin.json` | install via Cursor plugins | [docs](https://cursor.com/docs/reference/plugins) |
| **Gemini CLI** | ✅ ported — skills layer (commands/`bin/` have caveats) | `gemini-extension.json` | install the extension; `skills/` is auto-discovered | [gemini.md](gemini.md) |

**Copilot CLI** would read `.claude-plugin/plugin.json` as a fallback in its
manifest search order (`.plugin/plugin.json` → `plugin.json` →
`.github/plugin/plugin.json` → `.claude-plugin/plugin.json`), but Copilot
defaults `skills` to `skills/` while `commands` has *no* default — so the
fallback alone would expose the skill but not the `goal-*` commands. To ship the
full port, skill-kit adds a `.plugin/plugin.json` (first in that search order,
ignored by every other harness) that declares both `skills` and `commands`.

**Codex** and **Cursor** get a thin sibling manifest with metadata kept in sync with
`.claude-plugin/plugin.json`, pointing at the unchanged `skills/` (and, for
Cursor, `commands/`). Only Claude Code has a validator available in this repo's
toolchain, so those are conformance ports, not validator-verified.

**Gemini CLI** auto-discovers a `skills/<name>/SKILL.md` directory, so its
`gemini-extension.json` carries just the synced metadata and the
`improving-skills` skill ports directly — with caveats: Gemini commands are TOML
(the markdown `goal-*` commands don't auto-port) and it doesn't add `bin/` to
`PATH`. See [gemini.md](gemini.md).

---

Back to the documentation index: [README.md](README.md)
