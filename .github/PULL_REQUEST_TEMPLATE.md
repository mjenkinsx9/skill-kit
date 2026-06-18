## Summary

<!-- What does this PR change, and why? -->

## Checklist

- [ ] `bash bin/check-skill skills/improving-skills` → 0 FAIL and 0 WARN
- [ ] If `bin/` or `tests/` changed: `bash tests/run-self-tests.sh` and
      `python -m pytest tests -q` pass, with a fixture/test pinning the
      behavior change
- [ ] Synced files changed? `DB=../skill-testing bash tools/check-sync.sh` is
      green (or `SYNC.md` updated + baseline regenerated for an intentional new
      divergence)
- [ ] If this should reach users: version bumped in lockstep across all five
      manifests (see `AGENTS.md`)
- [ ] Docs (README / SYNC.md / AGENTS.md / docs/) updated if behavior changed
