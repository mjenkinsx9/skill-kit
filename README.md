<div align="center">

# 🧰 skill-kit

### The skill-testing workshop, packaged as a Claude Code plugin

**Author, evaluate, security-review, and autonomously improve Claude Agent Skills — in any project, with evidence, not vibes.**

[![CI](https://github.com/mjenkinsx9/skill-kit/actions/workflows/harness.yml/badge.svg)](https://github.com/mjenkinsx9/skill-kit/actions/workflows/harness.yml)
![Harness checks](https://img.shields.io/badge/harness_checks-21-blue)
![Bash](https://img.shields.io/badge/bash-3.2%2B-4EAA25?logo=gnubash&logoColor=white)
![Python](https://img.shields.io/badge/python-3.x-3776AB?logo=python&logoColor=white)
![Platform](https://img.shields.io/badge/platform-linux%20%7C%20macos%20%7C%20windows-lightgrey)
![Made for Claude Code](https://img.shields.io/badge/made_for-Claude_Code-d97757)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

</div>

---

The core idea: **a skill is only as good as the evidence behind it.** skill-kit
brings the full evaluation stack from the
[skill-testing](https://github.com/mjenkinsx9/skill-testing) dev-bench to any
project as an installable plugin — a 21-check static harness, a live behavioral
check, empirical trigger measurement, a blind value-add baseline, and an
autoresearch loop that iteratively tightens a `SKILL.md` and keeps only the
changes that score better.

## ✨ What's inside

| Layer | Tool | What it proves |
|---|---|---|
| 🧹 **Static** | `check-skill` | The skill is *well-formed* — 21 checks: frontmatter, naming, trigger language, secret & security-smell scans |
| ⚡ **Behavioral** | `behavioral-check` | The documented commands *actually run* against the real system today |
| 🎯 **Empirical trigger** | `trigger-accuracy` | The skill *really fires* on its positive prompts and declines its negatives |
| ⚖️ **Value-add** | `value-add-test` | The skill *beats the cold model* in a blind head-to-head |
| 🔄 **Autoresearch** | `improving-skills` | Iterative modify → score → keep-or-revert loop that tightens an existing SKILL.md |
| ⚓ **Goal anchoring** | `goal-new-skill` · `goal-improve-skill` | Skill work is driven by a measurable end state, not vibes |

The harness is self-tested (10 pathological fixtures + 34 pytest tests) and CI
enforces zero FAILs *and* zero WARNs on the shipped skills, on every push and PR.

## 🚀 Install

Inside Claude Code, on any machine:

```
/plugin marketplace add mjenkinsx9/mjenkins-toolbox
/plugin install skill-kit@mjenkins-toolbox
```

Update later with `/plugin update skill-kit`. Because a plugin's `bin/` joins the
Bash `PATH`, every helper is callable by bare name in any repo.
skill-kit also installs on Copilot CLI, Codex, Cursor, and Gemini —
see [Multi-harness support](docs/04-harnesses.md).

```bash
# Lint a skill directory (or a SKILL.md directly) — exit 0 iff zero FAILs:
check-skill .claude/skills/my-skill
```

```
/skill-kit:improving-skills .claude/skills/my-skill/SKILL.md
```

## 📚 Documentation

Full guides live in [`docs/`](docs/). Start with the overview, then dive into the
section you need.

| Doc | Description |
|---|---|
| [Overview](docs/01-overview.md) | What skill-kit is, the core idea, and the evaluation stack |
| [Installation](docs/02-installation.md) | Marketplace install, the `bin/`-on-`PATH` convention, requirements |
| [Usage](docs/03-usage.md) | The `bin/` commands, slash commands, and the improving-skills scoring loop |
| [Multi-harness support](docs/04-harnesses.md) | Per-harness status, manifests, and install notes |
| [Repository layout](docs/05-layout.md) | Map of manifests, helpers, commands, skills, and tests |
| [Testing the tests](docs/06-testing.md) | Self-tests + pytest, and the relationship to skill-testing |

Full documentation map: [docs/README.md](docs/README.md)

## 📄 License

[MIT](LICENSE) © 2026 Mike Jenkins
