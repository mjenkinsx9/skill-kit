# Testing the tests

The harness itself is under test — because a linter you can't trust is worse
than no linter:

```bash
bash tests/run-self-tests.sh    # 10 fixture skills with known verdicts
python -m pytest tests -q       # 34 tests for the Python eval scripts
```

## Relationship to skill-testing

The [skill-testing](https://github.com/mjenkinsx9/skill-testing) dev-bench is
where the methodology is developed; this plugin is its distributable packaging.
The shared tooling is co-developed as documented file pairs — see
[SYNC.md](../SYNC.md) for the pairing table and the pre-release drift check, and
[MIGRATION.md](../MIGRATION.md) for the extraction history.

---

Back to the documentation index: [README.md](README.md)
