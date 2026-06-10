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
| `eval/value-add-test.sh` | `bin/value-add-test` | doc refs → `${CLAUDE_PLUGIN_ROOT}/reference/…`; `run_dir` → `${CLAUDE_PROJECT_DIR:-.}/.skill-kit/runs/` |
| `eval/value-add-test.md` | `reference/value-add-test.md` | bare command names; Artifact section uses `.skill-kit/runs/` |
| `eval/trigger-accuracy.py` | `bin/trigger-accuracy` | docstring doc-pointer only |
| `eval/trigger-accuracy.md` | `reference/trigger-accuracy.md` | bare command names; `<skill-dir>` generalization; inline description advice (no `WRITING-DESCRIPTIONS.md` here); `references/scoring.md` pointer |
| `eval/behavioral-check.py` | `bin/behavioral-check` | docstring doc-pointer + usage line |
| `eval/behavioral-check.md` | `reference/behavioral-check.md` | bare command names; plugin terms (`/skill-kit:improving-skills`, no `eval/`/`staging/`) |
| `eval/tests/` | `tests/` | `HARNESS`/`FIXTURES`/repo-root paths; explicit `SourceFileLoader` for extensionless bin scripts; fixtures byte-identical |
| `.claude/skills/improving-skills/` | `skills/improving-skills/` | `/skill-kit:`-namespaced invocations; `.skill-kit/runs/` scratch dir; bare helper names; `${CLAUDE_PLUGIN_ROOT}/reference/…` pointers |
| `.claude/skills/improving-skills/scripts/score-skill.sh` | `bin/score-skill` | locates the harness as a `bin/` sibling |
| `.claude/skills/improving-skills/scripts/token-count.sh` | `bin/token-count` | none beyond the name |
| `.claude/commands/goal-*.md` | `commands/goal-*.md` | namespacing; anchors at `.claude/skills/<name>/`; `.skill-kit/runs/` |
| `LICENSE` | `LICENSE` | copyright holder |

Not ported (dev-bench-only): `eval/README.md`, `.claude/commands/prime.md`,
`examples/`, `staging/`, `WRITING-DESCRIPTIONS.md`, `check-skills.yml`'s
multi-dir sweeps. New dev-bench eval tools default to "port it" (see
`behavioral-check`) unless they encode dev-bench repo layout.

## Pre-release drift check

From the plugin repo root, with the dev-bench checked out as a sibling:

```bash
DB=../skill-testing PK=.
for pair in \
  "eval/check-skill.sh:$PK/bin/check-skill" \
  "eval/value-add-test.sh:$PK/bin/value-add-test" \
  "eval/value-add-test.md:$PK/reference/value-add-test.md" \
  "eval/trigger-accuracy.py:$PK/bin/trigger-accuracy" \
  "eval/trigger-accuracy.md:$PK/reference/trigger-accuracy.md" \
  "eval/behavioral-check.py:$PK/bin/behavioral-check" \
  "eval/behavioral-check.md:$PK/reference/behavioral-check.md"
do
  echo "== ${pair%%:*}"; diff "$DB/${pair%%:*}" "${pair#*:}"
done
```

Every hunk in the output must be one of the documented adaptations above.
Anything else is drift — port it (or document a new intentional divergence
here). Then run the gates locally before tagging:

```bash
bash bin/check-skill skills/improving-skills  # 0 FAIL, 0 WARN
bash tests/run-self-tests.sh
python -m pytest tests -q
```
