# Syncing with the skill-testing dev-bench

The shared eval tooling is co-developed in the
[skill-testing](https://github.com/mjenkinsx9/skill-testing) dev-bench and
ported here. The two repos evolve independently, but the dev-bench is where
harness changes are usually born — so **before each plugin release, diff every
pair below** and port what's missing. Drift is not hypothetical: one week after
the repo split, the dev-bench harness was 144 lines ahead (resynced 2026-06-10).

## File pairs

| dev-bench (skill-testing) | plugin (skill-kit) | intentional adaptations in the plugin copy |
|---|---|---|
| `eval/check-skill.sh` | `bin/check-skill` | header comment filename/usage only (2 lines) |
| `eval/value-add-test.sh` | `bin/value-add-test` | doc refs resolve from `${SKILL_KIT_ROOT}`/`${CLAUDE_PLUGIN_ROOT}`/`dirname "$0"/..`; `run_dir` → `${CLAUDE_PROJECT_DIR:-.}/.skill-kit/runs/`; **plus a dual-format seed parser — accepts canonical `y \| prompt` rows (the test-prompts template format, and the only format `trigger-accuracy` reads) in addition to the legacy "Positive"-heading format, canonical winning when both are present. Dev-bench parses legacy only and trails — see "Plugin leads" below** |
| `eval/value-add-test.md` | `reference/value-add-test.md` | bare command names; Artifact section uses `.skill-kit/runs/` |
| `eval/trigger-accuracy.py` | `bin/trigger-accuracy` | **intentional feature-superset (multi-harness)** — beyond the docstring doc-pointer, the plugin adds the `run-probes` + `score-transcripts` subcommands, Pi/Codex/OpenAI tool-call shape detection (`_iter_content_tool_blocks`, `_iter_chat_tool_calls`, `_coerce_args`), `_text_signal_fired`/`--text-signal`, the `_score_with_resolver`/`score_transcripts` refactor, an empty-transcript guard, and extra transcript path keys. Dev-bench is Claude-only and **trails** — see "Plugin leads" below |
| `eval/trigger-accuracy.md` | `reference/trigger-accuracy.md` | bare command names; `<skill-dir>` generalization; **documents the plugin-only `run-probes`/`score-transcripts` subcommands and `--text-signal`**; diagnostic-only description advice (constructive guidance in `docs/07-authoring.md`); `references/scoring.md` pointer |
| `eval/behavioral-check.py` | `bin/behavioral-check` | docstring doc-pointer + usage line |
| `eval/behavioral-check.md` | `reference/behavioral-check.md` | bare command names; plugin terms (`/skill-kit:improving-skills`, no `eval/`/`staging/`) |
| `eval/tests/` | `tests/` | `HARNESS`/`FIXTURES`/repo-root paths; explicit `SourceFileLoader` for extensionless bin scripts; fixtures byte-identical |
| `.claude/skills/improving-skills/` | `skills/improving-skills/` | `/skill-kit:`-namespaced invocations; `.skill-kit/runs/` scratch dir; bare helper names; `${CLAUDE_PLUGIN_ROOT}/reference/…` pointers |
| `.claude/skills/improving-skills/scripts/score-skill.sh` | `bin/score-skill` | locates the harness as a `bin/` sibling; **plus a `cand_tokens > 0` divide-by-zero guard on the baseline comparison. Dev-bench lacks the guard and trails — see "Plugin leads" below** |
| `.claude/skills/improving-skills/scripts/token-count.sh` | `bin/token-count` | none beyond the name |
| `.claude/commands/goal-*.md` | `commands/goal-*.md` | `/skill-kit:`-namespacing; anchors at `.claude/skills/<name>/` (dev-bench uses `staging/`); `.skill-kit/runs/`; bare `check-skill`; **plus the inlined "never from imagination" doctrine line (in `goal-new-skill.md`) and a plugin-only note in both files that `/goal` is not part of this plugin or stock Claude Code — if absent, the written `goal.md` is the manual acceptance checklist** |
| `LICENSE` | `LICENSE` | none — currently byte-identical (both carry the same holder); kept in the drift check so a future divergence is caught |

Not ported (dev-bench-only): `eval/README.md`, `.claude/commands/prime.md`,
`examples/`, `staging/`, `WRITING-DESCRIPTIONS.md`, `check-skills.yml`'s
multi-dir sweeps. New dev-bench eval tools default to "port it" (see
`behavioral-check`) unless they encode dev-bench repo layout.

Plugin-only, no dev-bench source: `bin/improving-skills`, `bin/goal-improve-skill`,
and `bin/goal-new-skill` are PATH shims that print the skill/command file to load
(so the workflow is discoverable from a plugin `bin/`) — there is nothing to diff
them against upstream.

Scope decision (deliberately not shipped): the dev-bench also carries the
`automating-browsers` and `generating-ai-ideas` skills. Those are dev-bench-only
and are **not** shipped here — they sit off skill-kit's product surface
(author / evaluate / improve-skills). Only `improving-skills` crosses the split.

## Pairs where the plugin leads the dev-bench (back-port pending)

These plugin copies are intentional **supersets** — a re-sync must **NOT** revert
them to the smaller dev-bench versions. Until the dev-bench catches up, these
features live only here, and the direction of flow for them is **plugin →
dev-bench** (the reverse of the default):

- `bin/trigger-accuracy` — `run-probes`, `score-transcripts`, Pi/Codex/OpenAI
  tool-call detection, `--text-signal`, empty-transcript guard
- `bin/value-add-test` — canonical `y | prompt` seed parser (template format)
- `bin/score-skill` — `cand_tokens > 0` divide-by-zero guard

## Pre-release drift check

**Pinned dev-bench ref: `ac28303`** — the `skill-testing` commit the baselines
and the table below are pinned to. CI (`.github/workflows/drift-check.yml`)
diffs against this exact ref; bump it here whenever you re-sync.

The authoritative, automated check is `tools/check-sync.sh` (golden-diff per
pair + manifest-metadata assertions); CI runs it on every PR. The loop below is
the equivalent **manual** convenience — it covers all tracked pairs, so a
maintainer running it verbatim diffs every one:

```bash
DB=../skill-testing PK=.
for pair in \
  "eval/check-skill.sh:$PK/bin/check-skill" \
  "eval/value-add-test.sh:$PK/bin/value-add-test" \
  "eval/value-add-test.md:$PK/reference/value-add-test.md" \
  "eval/trigger-accuracy.py:$PK/bin/trigger-accuracy" \
  "eval/trigger-accuracy.md:$PK/reference/trigger-accuracy.md" \
  "eval/behavioral-check.py:$PK/bin/behavioral-check" \
  "eval/behavioral-check.md:$PK/reference/behavioral-check.md" \
  ".claude/skills/improving-skills/scripts/score-skill.sh:$PK/bin/score-skill" \
  ".claude/skills/improving-skills/scripts/token-count.sh:$PK/bin/token-count" \
  ".claude/commands/goal-improve-skill.md:$PK/commands/goal-improve-skill.md" \
  ".claude/commands/goal-new-skill.md:$PK/commands/goal-new-skill.md"
do
  echo "== ${pair%%:*}"; diff "$DB/${pair%%:*}" "${pair#*:}"
done
```

Every hunk in the output must be one of the documented adaptations above.
Anything else is drift — port it (or document a new intentional divergence here,
and refresh the matching `tools/sync-baseline/<slug>.diff`). Then run the gates
locally before tagging:

```bash
DB=../skill-testing bash tools/check-sync.sh  # exit 0 = no undocumented drift
bash bin/check-skill skills/improving-skills  # 0 FAIL, 0 WARN
bash tests/run-self-tests.sh
python -m pytest tests -q
```
