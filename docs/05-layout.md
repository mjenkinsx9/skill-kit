# Repository layout

```
.claude-plugin/plugin.json   Claude Code manifest
.plugin/plugin.json          GitHub Copilot CLI manifest → ./skills/ + ./commands/
.codex-plugin/plugin.json    OpenAI Codex manifest → ./skills/
.cursor-plugin/plugin.json   Cursor manifest → ./skills/ + ./commands/
gemini-extension.json        Gemini CLI extension (skills/ auto-discovered)
docs/gemini.md               Gemini CLI port notes + caveats
bin/                         deterministic helpers, auto-added to PATH
  check-skill                21-check static harness
  score-skill · token-count  mechanical scorers for the improvement loop
  behavioral-check           live tests.md command runner
  trigger-accuracy           empirical trigger helpers (Claude agent IDs or Pi/Codex transcripts)
  value-add-test             blind head-to-head scaffolding + tally
  goal-new-skill             PATH shim for /skill-kit:goal-new-skill
  goal-improve-skill         PATH shim for /skill-kit:goal-improve-skill
  improving-skills           PATH shim for /skill-kit:improving-skills
commands/                    /skill-kit:goal-new-skill · /skill-kit:goal-improve-skill
skills/improving-skills/     the autoresearch loop (/skill-kit:improving-skills)
reference/                   protocols the loop runs at milestones
tests/                       self-tests for the harness itself (fixtures + pytest)
```

---

Back to the documentation index: [README.md](README.md)
