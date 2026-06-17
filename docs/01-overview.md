# Overview — what skill-kit is

**skill-kit** is the skill-testing workshop, packaged as a Claude Code plugin:
author, evaluate, security-review, and autonomously improve Claude Agent Skills —
in any project, with evidence, not vibes.

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

## What's inside

| Layer | Tool | What it proves | Cost / cadence |
|---|---|---|---|
| 🧹 **Static** | [`check-skill`](../bin/check-skill) | The skill is *well-formed* — 21 checks: frontmatter, naming, trigger language, tree-wide secret & security-smell scans, sidecar hygiene | Free · every edit |
| ⚡ **Behavioral** | [`behavioral-check`](../reference/behavioral-check.md) | The documented commands *actually run* against the real system today | ~0 tokens · on touch |
| 🎯 **Empirical trigger** | [`trigger-accuracy`](../reference/trigger-accuracy.md) | The skill *really fires* on its positive prompts and declines its negatives (observed, not self-predicted; Claude agent IDs or Pi/Codex transcript paths) | Agent sessions · milestone |
| ⚖️ **Value-add** | [`value-add-test`](../reference/value-add-test.md) | The skill *beats the cold model* in a blind head-to-head | LLM-judged · pre-promotion |
| 🔄 **Autoresearch** | [`improving-skills`](../skills/improving-skills/SKILL.md) | Iterative modify → score → keep-or-revert loop that tightens an existing SKILL.md | Heavy · on demand |
| ⚓ **Goal anchoring** | [`goal-new-skill`](../commands/goal-new-skill.md) · [`goal-improve-skill`](../commands/goal-improve-skill.md) | Skill work is driven by a measurable end state, not vibes | Free · per skill |

The harness is self-tested (10 pathological fixtures + 34 pytest tests) and CI
enforces zero FAILs *and* zero WARNs on the shipped skills, on every push and PR.

## Requirements

Scripts are `bash` + a handful of POSIX tools + Python, and run identically on
Linux, macOS, and Windows (Git Bash or WSL — the harness tries `python3` /
`python` / `py -3` and skips the silent MS-Store shim). `pip install pyyaml`
is the only Python dependency. All scripts use forward-slash paths and LF line
endings (enforced via `.gitattributes`).

## License

[MIT](../LICENSE) © 2026 Mike Jenkins

---

Back to the documentation index: [README.md](README.md)
