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

Skills it touches aim to follow Anthropic's published
[agent-skills best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
([overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) ·
[Claude Code skills](https://code.claude.com/docs/en/skills)) — and the tooling
exists to *prove* it rather than assume it.

## ✨ What's inside

| Layer | Tool | What it proves | Cost / cadence |
|---|---|---|---|
| 🧹 **Static** | [`check-skill`](bin/check-skill) | The skill is *well-formed* — 21 checks: frontmatter, naming, trigger language, tree-wide secret & security-smell scans, sidecar hygiene | Free · every edit |
| ⚡ **Behavioral** | [`behavioral-check`](reference/behavioral-check.md) | The documented commands *actually run* against the real system today | ~0 tokens · on touch |
| 🎯 **Empirical trigger** | [`trigger-accuracy`](reference/trigger-accuracy.md) | The skill *really fires* on its positive prompts and declines its negatives (observed, not self-predicted) | Sub-agents · milestone |
| ⚖️ **Value-add** | [`value-add-test`](reference/value-add-test.md) | The skill *beats the cold model* in a blind head-to-head | LLM-judged · pre-promotion |
| 🔄 **Autoresearch** | [`improving-skills`](skills/improving-skills/SKILL.md) | Iterative modify → score → keep-or-revert loop that tightens an existing SKILL.md | Heavy · on demand |
| ⚓ **Goal anchoring** | [`goal-new-skill`](commands/goal-new-skill.md) · [`goal-improve-skill`](commands/goal-improve-skill.md) | Skill work is driven by a measurable end state, not vibes | Free · per skill |

The harness is self-tested (10 pathological fixtures + 26 pytest tests) and CI
enforces zero FAILs *and* zero WARNs on the shipped skills, on every push and PR.

## 🚀 Install

Inside Claude Code, on any machine:

```
/plugin marketplace add mjenkinsx9/mjenkins-toolbox
/plugin install skill-kit@mjenkins-toolbox
```

Update later with `/plugin update skill-kit`.

Because a plugin's `bin/` joins the Bash `PATH`, every helper is callable by
bare name (`check-skill`, `score-skill`, `behavioral-check`, …) in any repo —
no layout assumed. Run artifacts land in `.skill-kit/runs/` in the consuming
project (gitignore it).

## 🧭 Usage

```bash
# Lint a skill directory (or a SKILL.md directly) — exit 0 iff zero FAILs:
check-skill .claude/skills/my-skill

# Do the skill's documented commands still run against the real system?
behavioral-check .claude/skills/my-skill --dry-run

# Blind value-add baseline (preflight + tally; generation is agent-driven):
value-add-test .claude/skills/my-skill
```

```
/skill-kit:goal-new-skill summarizing-prs             # interview → goal.md for a not-yet-written skill
/skill-kit:goal-improve-skill .claude/skills/my-skill # measurable target for an improvement run
/skill-kit:improving-skills .claude/skills/my-skill/SKILL.md
```

The improving-skills loop scores each candidate against a fixed composite —
**mechanical floor** (`check-skill` must pass every kept iteration), **trigger
accuracy** (positive + negative fixture prompts), **instruction quality**
(LLM-as-judge against the skill's own `tests.md` scenarios), and **token
efficiency** (rewards shrinking, never penalizes a smaller body) — then runs
the value-add baseline once on the final candidate, because a maxed composite
proves a skill is *tight*, not that it beats just asking the model. See
[scoring.md](skills/improving-skills/references/scoring.md) and
[loop.md](skills/improving-skills/references/loop.md).

> **Note:** the `goal-*` commands assume a `/goal` command in your environment —
> it is not part of this plugin or stock Claude Code. Without one, the generated
> `goal.md` still works as a manual acceptance checklist.

## 📁 Layout

```
.claude-plugin/plugin.json   plugin manifest
bin/                         deterministic helpers, auto-added to PATH
  check-skill                21-check static harness
  score-skill · token-count  mechanical scorers for the improvement loop
  behavioral-check           live tests.md command runner
  trigger-accuracy           empirical trigger measurement helpers
  value-add-test             blind head-to-head scaffolding + tally
commands/                    /skill-kit:goal-new-skill · /skill-kit:goal-improve-skill
skills/improving-skills/     the autoresearch loop (/skill-kit:improving-skills)
reference/                   protocols the loop runs at milestones
tests/                       self-tests for the harness itself (fixtures + pytest)
```

## 🧪 Testing the tests

The harness itself is under test — because a linter you can't trust is worse
than no linter:

```bash
bash tests/run-self-tests.sh    # 10 fixture skills with known verdicts
python -m pytest tests -q       # 26 tests for the Python eval scripts
```

## 🔁 Relationship to skill-testing

The [skill-testing](https://github.com/mjenkinsx9/skill-testing) dev-bench is
where the methodology is developed; this plugin is its distributable packaging.
The shared tooling is co-developed as documented file pairs — see
[SYNC.md](SYNC.md) for the pairing table and the pre-release drift check, and
[MIGRATION.md](MIGRATION.md) for the extraction history.

## 💻 Requirements

Scripts are `bash` + a handful of POSIX tools + Python, and run identically on
Linux, macOS, and Windows (Git Bash or WSL — the harness tries `python3` /
`python` / `py -3` and skips the silent MS-Store shim). `pip install pyyaml`
is the only Python dependency. All scripts use forward-slash paths and LF line
endings (enforced via `.gitattributes`).

## 📄 License

[MIT](LICENSE) © 2026 Mike Jenkins
