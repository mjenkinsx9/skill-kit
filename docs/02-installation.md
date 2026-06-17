# Installation

Inside Claude Code, on any machine:

```
/plugin marketplace add mjenkinsx9/mjenkins-toolbox
/plugin install skill-kit@mjenkins-toolbox
```

Update later with `/plugin update skill-kit`.

Because a plugin's `bin/` joins the Bash `PATH`, every helper is callable by
bare name (`check-skill`, `score-skill`, `behavioral-check`,
`value-add-test`, `improving-skills`, `goal-new-skill`,
`goal-improve-skill`, …) in any repo — no layout assumed. Run artifacts land in
`.skill-kit/runs/` in the consuming project (gitignore it).

## Requirements

Scripts are `bash` + a handful of POSIX tools + Python, and run identically on
Linux, macOS, and Windows (Git Bash or WSL — the harness tries `python3` /
`python` / `py -3` and skips the silent MS-Store shim). `pip install pyyaml`
is the only Python dependency. All scripts use forward-slash paths and LF line
endings (enforced via `.gitattributes`).

## Other harnesses

skill-kit installs on several agent CLIs beyond Claude Code. The Agent Skills
(`SKILL.md` files) are the portable core, so the same `skills/` and `commands/`
directories are re-pointed via sibling manifests — see
[Multi-harness support](04-harnesses.md) for the full table, per-harness install
instructions, and caveats.

---

Back to the documentation index: [README.md](README.md)
