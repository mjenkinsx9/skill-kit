# skill-kit

The skill-building workflow from the [skill-testing](https://github.com/mjenkinsx9/skill-testing)
dev-bench, packaged as a distributable Claude Code plugin. Author, evaluate,
security-review, and autonomously improve Claude Agent Skills in any project.

## What's inside

| Path | Purpose |
|---|---|
| `bin/check-skill` | Static best-practices harness — validates a skill dir / SKILL.md. On PATH, callable bare. |
| `bin/score-skill`, `bin/token-count` | Mechanical scorers for the improvement loop. |
| `bin/value-add-test`, `bin/trigger-accuracy` | Loop-end milestone tooling (does the skill beat the cold model; does it actually fire). |
| `skills/improving-skills/` | The autoresearch loop (modify → score → keep-or-revert), invoked as `/skill-kit:improving-skills`. |
| `commands/goal-new-skill.md` | `/skill-kit:goal-new-skill <name>` — interviews you and anchors a `goal.md` for a not-yet-authored skill at `.claude/skills/<name>/`. |
| `commands/goal-improve-skill.md` | `/skill-kit:goal-improve-skill <skill-dir>` — anchors a measurable target for an improving-skills run. |
| `reference/` | The value-add and trigger-accuracy protocols the loop runs at the end. |

Because a plugin's `bin/` is auto-added to the Bash `PATH`, the skill calls its
helpers by bare name (`check-skill`, `score-skill`, …) and pre-authorizes them
with `allowed-tools: Bash(check-skill *)` — no repo layout assumed, so it works
wherever the plugin is installed. Run artifacts land in `${CLAUDE_PROJECT_DIR}/.skill-kit/runs/`.

### Planned (not yet shipped)

- `agents/` — security-reviewer, value-add-evaluator, skill-importer (to be authored from real practice, per the repo's prime rule — not from imagination).

See [MIGRATION.md](MIGRATION.md) for status and remaining work.

## Distribution

This repo is the `mjenkins-toolbox` marketplace (defined in
`/.claude-plugin/marketplace.json`). The `./plugins/skill-kit` relative source
resolves whether the marketplace is added locally or cloned from GitHub.

### Install in any project

```bash
/plugin marketplace add mjenkinsx9/mjenkins-toolbox   # registers the mjenkins-toolbox catalog
/plugin install skill-kit@mjenkins-toolbox
```

### Dogfood it locally (in this repo)

```bash
/plugin marketplace add ./        # add this repo as a local marketplace
/plugin install skill-kit@mjenkins-toolbox
/reload-plugins
```

### Enable across all your projects

Add to `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "mjenkins-toolbox": {
      "source": { "source": "github", "repo": "mjenkinsx9/mjenkins-toolbox" }
    }
  },
  "enabledPlugins": {
    "skill-kit@mjenkins-toolbox": true
  }
}
```

## Namespacing

Everything from a plugin is namespaced by the plugin name: the skill becomes
`/skill-kit:improving-skills`, future commands become `/skill-kit:goal-new-skill`, etc.
