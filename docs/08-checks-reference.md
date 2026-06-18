# The 21 checks

`check-skill` is a fast, deterministic **static** linter — frontmatter, naming,
line counts, security, secrets, `tests.md` presence. Run it on every edit:

```bash
check-skill .claude/skills/<name>          # or a direct path to SKILL.md
```

It accepts either a skill directory or a direct path to `SKILL.md`. Exit code is 0
only when zero FAILs are recorded.

The checks encode the published Anthropic rules from the
[best-practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices),
[overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview),
and [Claude Code skills](https://code.claude.com/docs/en/skills) docs. Each finding
is labeled:

- **PASS** — check satisfied
- **WARN** — strong recommendation violated; doesn't block (a prompt to look, not a
  verdict)
- **FAIL** — hard rule violated; non-zero exit code

## The checks

| # | Check | Level |
|---|---|---|
| 1 | Frontmatter parses as YAML between `---` markers | FAIL |
| 2 | `name` present, ≤64 chars, `^[a-z0-9-]+$`, no "anthropic"/"claude"/XML | FAIL |
| 3 | `name` matches folder name (when invoked on a directory) | FAIL |
| 4 | `name` uses gerund form (`processing-pdfs`) | WARN |
| 5 | `description` present, ≤1024 chars, no XML | FAIL |
| 6 | `description` in third person (no "I can…", "You can…") | FAIL |
| 7 | `description` includes genuine trigger phrasing — one of "use when"/"use whenever"/"use this skill when"/"use for"/"when the user"/"when working"/"when asked"/"trigger(s) when" (case-insensitive). A bare mid-sentence "when" or a "for \<task noun\>" clause is deliberately NOT enough. | WARN |
| 7b | `description` trigger clause (the text after whichever phrase Check 7 matched) enumerates ≥2 concrete conditions (not a single generic one). WARNs when no clause is extractable, and when Check 7 itself warned. | WARN |
| 8 | `description` substantive length (≥40 chars) | WARN |
| 9 | Body ≤500 lines (split into supporting files past that) | WARN |
| 10 | No Windows-style backslash paths (drive-letter `C:\…` or UNC `\\host\share`) in `SKILL.md` or reference `.md` files (same walk/exclusions as Check 16 — `scripts/`, `templates/`, `assets/`, `goals/` and governance files other than `SKILL.md` are skipped; scripts may legitimately carry Windows paths). A line tagged `allowlist windows-path` is exempt. Findings reported as `path:line`. | FAIL |
| 11 | References one level deep from `SKILL.md` | WARN |
| 12 | Security smells (`curl … \| sh`, `rm -rf`, base64 decode, outbound POSTs) across the whole skill tree — every `.md` plus every script file (`*.py *.sh *.bash *.js *.ts *.rb *.pl *.ps1`), including `scripts/`, `references/`, and `templates/`. Findings reported as `path:line`. | WARN |
| 13 | No leaked secrets (`sk-…`, `ghp_…`, `AKIA…`) anywhere in the skill tree — same `.md`+script scan set as Check 12, with no exclusions (a leaked key is never legitimate). A line tagged `allowlist secret` is exempt, in every file. Findings reported as `path:line`. | FAIL |
| 14 | `tests.md` sidecar with `Last verified:` date and ≥3 scenarios (FAIL if missing, WARN if `Last verified` > 90 days old). The staleness date is read from the `Last verified:` line itself; structural `##` headings (Contents, Notes, Setup, Prerequisites, Preamble, Background) don't count as scenarios. | FAIL/WARN |
| 15 | `PROMOTION-CHECKLIST.md` present with a `Value-add verdict:` line — only for skills under a `.claude/skills/` path (bare-`SKILL.md` paths are exempt). | WARN |
| 16 | All reference `.md` files (sibling to `SKILL.md` or in `references/`) are ≤200 lines. Walks the skill dir tree; excludes `SKILL.md`, `tests.md`, `test-prompts.md`, `PROMOTION-CHECKLIST.md`, `goal.md`, and the `scripts/`/`templates/`/`assets/`/`goals/` subdirs. On WARN: split into smaller topic-focused files or move into a `references/` subdir. | WARN |
| 17 | Reference `.md` files over 100 lines open with a table of contents (an H1–H3 heading whose text contains "contents"). Same walk/exclusions as Check 16. Encodes Anthropic's "structure longer reference files with a table of contents" so the model sees the full scope even from a partial read. | WARN |
| 18 | No reference docs loose beside `SKILL.md` — any top-level `.md` that isn't a governance file (`SKILL.md`, `tests.md`, `test-prompts.md`, `PROMOTION-CHECKLIST.md`, `goal.md`, `README.md`) should move into a `references/` subdir. Fires as soon as a skill carries reference content besides `SKILL.md`. | WARN |
| 19 | No scripts loose beside `SKILL.md` — top-level executable files (`*.py`, `*.sh`, `*.bash`, `*.js`, `*.ts`, `*.rb`, `*.pl`, `*.ps1`) belong in a `scripts/` subdir (executed, not loaded). | WARN |
| 20 | Every reference file is linked from `SKILL.md` (its basename appears there) — the reverse of Check 11, catching orphans the model would never load. Same file set/exclusions as Check 16. Remedy: link it from `SKILL.md`, or remove it. | WARN |
| 21 | Staging/live drift — only relevant in a dev-bench layout where a `staging/<name>` twin exists in the same repo; every file present in both copies is compared with `diff -q`. In a plain consumer repo with no such twin it PASSes with "no staging twin". | WARN |

## Escape hatches

Two FAIL checks have a per-line escape hatch for skills that *legitimately* need the
flagged content — a security-review or secrets-handling skill that must show
realistic key shapes, or a skill documenting a Windows CLI. The marker suppresses
the finding for that line only; a real accidental leak or portability bug won't
carry it.

### Check 13 — secrets

Tag a line with an `allowlist secret` marker to exempt it:

```
AKIAIOSFODNN7EXAMPLE <!-- pragma: allowlist secret -->
```

The marker works in **every** scanned file (`references/`, `scripts/`, … — not just
`SKILL.md`). Only use it on deliberate examples.

### Check 10 — Windows paths

Tag the line with an `allowlist windows-path` marker:

```
C:\Users\... <!-- allowlist windows-path -->
```

Use it on a skill that genuinely documents Windows paths (e.g. a skill about a
Windows CLI). A genuine portability bug won't carry the marker.

## Interpreting WARN

A WARN is a prompt to look — not a verdict. Security smells (Check 12) in particular
are patterns that *might* be malicious or *might* be a legitimate example; the human
reviewer decides. Only FAILs change the exit code.

> **Note:** `docs/` files are not skill directories, so they never affect a
> `check-skill` verdict — the harness only walks the skill tree under the path you
> give it.

## Beyond the static linter

`check-skill` proves a skill is *well-formed*; it never runs the skill and can't
prove it's worth invoking. Three deeper checks cover what it can't — the live
[behavioral-check](../reference/behavioral-check.md), the empirical
[trigger-accuracy](../reference/trigger-accuracy.md) test, and the blind
[value-add-test](../reference/value-add-test.md). See the
[Overview](01-overview.md#whats-inside) for how they layer.

---

Back to the documentation index: [README.md](README.md)
