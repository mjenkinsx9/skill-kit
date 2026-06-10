# Promotion Checklist — improving-skills

**Skill**: improving-skills (live tool skill; `disable-model-invocation: true`)
**Location**: `skills/improving-skills/`

## Pre-promotion verification

- [x] `check-skill skills/improving-skills` → 0 FAIL
- [x] `tests.md` present with scenarios + `Last verified:` date
- [x] Sidecars (`references/loop.md`, `references/scoring.md`, `value-add` references, `templates/`) referenced one level deep; helper scripts live in the plugin `bin/` (`check-skill`, `score-skill`, `token-count`)
- [x] No secrets; `allowed-tools` scoped intentionally
- [x] Name is gerund form, matches folder
- [x] **Value-add verdict**: N/A (non-generative) — this is a meta-tool that runs the
      modify→score→keep-or-revert loop; "beats cold model on rigor" is the wrong frame
      (see `${CLAUDE_PLUGIN_ROOT}/reference/value-add-test.md` → applicability limits)

## Notes

This skill ships inside the `skill-kit` plugin rather than being promoted from
`staging/`. The checklist exists so the harness's Check 15 has a value-add
verdict to read and to document why the value-add test does not apply here.
