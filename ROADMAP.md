# skill-kit — Next-Version Roadmap (toward v0.3.0)

Built from a cross-repo alignment review of skill-kit against the `skill-testing` dev-bench, then an adversarial re-review of that analysis (48 critiques, 0 refuted; every load-bearing claim re-verified against the live repos). The detailed gap analysis and phased spec were kept as local working notes; this file is the consolidated, self-contained forward plan.

---

## Part A — What the review found (for the record)

The review confirmed the central thesis — a **source-of-truth inversion**: `bin/trigger-accuracy`, `bin/value-add-test`, and `bin/score-skill` are intentional plugin-ahead supersets (driven by the cross-harness mandate) that `SYNC.md` mis-documented as trivial adaptations, which silently broke its own drift check. The adversarial re-review also surfaced these concrete defects in the analysis (all since reconciled in the working notes), recorded here so the rationale isn't lost:

| Defect | Status |
|---|---|
| **H1 evidence grep count wrong** — cited `grep -c 'run-probes\|score-transcripts'`=13; the literal pattern returns **8** (13 needs the `.`-wildcard that also matches `run_probes`/`score_transcripts`). | Corrected in GAP H1. |
| **False "already-aligned" manifest claim** — §6 said all five manifests share name/description/author/homepage/repository/license; `gemini-extension.json` carries only **name/description/version** (intentionally minimal; CI enforces only name+version). | Corrected in GAP §6. |
| **Finding counts not reconstructable** — headline "39 findings / 19 aligned / 5H-6M-28L" came from the raw workflow set (with duplicates + low already-aligneds); the report body enumerates 17 actionable + a summarized aligned surface. | Reconciled: report now states "17 actionable findings; remaining surface verified aligned." |
| **§7 contradiction** — "every change additive, no manifest change, no version bump" vs L1/L2/L7 (which edit a runtime string, bin/ headers, and a manifest and need a patch bump). | Softened to match the plan. |
| **`goal-*.md` command pairs never drift-classified** — a tracked `SYNC.md` pair (row 25) with 23/21 changed lines incl. a doctrine injection and a new "`/goal` is not part of this plugin" line — beyond the documented namespacing adaptations. | Added as a finding + folded into Phase 1. |
| **Drift-LOOP is incomplete by construction** — `SYNC.md`'s pre-release loop iterates only 7 pairs; the table tracks 13. `goal-*.md`, `score-skill`, `token-count` are never diffed even by a maintainer who runs it verbatim. | Added; drives P1 below. |
| Dangling cross-refs ("see L-CI below", "§5/R3"), LICENSE↔README copyright mismatch, M1 div-by-zero overstated (REF clamps `inf→1.0`). | Corrected. |

---

## Part B — The roadmap

Ordered by leverage, not effort. **P0 fixes things that are currently *false or broken*. P1 makes the alignment mechanism *self-enforcing* (the durable fix for the whole inversion). P2 recovers lost capability. P3 hardens the product.**

### P0 — Correctness & staleness (the repo currently ships wrong facts)

| # | Item | Evidence | Action |
|---|---|---|---|
| P0.1 | **AGENTS.md claims no release exists** — but `v0.2.2` is tagged **and** a GitHub release is published (2026-06-17). | `git tag` → `v0.2.2`; `gh release list` → `v0.2.2 — Skill Kit`; AGENTS.md:43-44 "no git tags / GitHub releases yet". | Rewrite AGENTS.md's release section for the *repeatable* case (v0.2.2 done; next is v0.3.0). |
| P0.2 | **"10 fixtures" is wrong** in two user-facing places — there are **9**. | `ls -d tests/fixtures/*/` → 9; README.md:40 + docs/06-testing.md:7 say "10". (pytest "34" is correct.) | `s/10 fixtures/9 fixtures/` (or fix to the actual count) in both files; add the fixture count to the SYNC drift checklist so it can't restale. |
| P0.3 | **tests harness names the wrong repo** (was GAP L1). | `tests/run-self-tests.sh:36` "expected to run inside the **mjenkins-toolbox** repo" (REF says "skill-testing"; correct is "skill-kit"). | `s/the mjenkins-toolbox repo/the skill-kit repo/`. |
| P0.4 | **Copyright holder inconsistent.** | `LICENSE` "Copyright (c) 2026 mjenkinsx9" vs `README.md` footer "© 2026 Mike Jenkins". `SYNC.md` LICENSE-row adaptation is "copyright holder". | Pick one identity; align LICENSE, README, and the manifest `author.name` (`mjenkinsx9`). |
| P0.5 | **Correct the `SYNC.md` adaptation table** for the 4 diverged pairs (the GAP's H1/H2/M1 + the goal-*.md pair). | See GAP H1/H2/M1 + the goal-pairs addendum. | Rewrite the four rows to describe the real divergences; add the "plugin leads / dev-bench trails — back-port pending" note. |

### P1 — Make the alignment mechanism self-enforcing (highest leverage)

> The whole inversion happened because `SYNC.md` is **prose a human must remember to run**. Re-wording it (the original plan) doesn't prevent re-drift. The structural fix is to make the contract executable.

- **P1.1 — Automate the drift check in CI.** Add a `drift-check` job to `harness.yml` that checks out `skill-testing` at a `SYNC.md`-pinned ref, diffs **every** tracked pair, strips the catalogued adaptation hunks, and `exit 1` on any residual. Pin the ref via a new `Pinned dev-bench ref:` line in `SYNC.md`. *This converts `SYNC.md` from documentation into a contract and makes the inversion physically impossible to reintroduce silently.* **This is the single most valuable item in the roadmap.**
- **P1.2 — Extend the drift loop to all 13 tracked pairs.** The current manual loop omits `goal-new-skill.md`, `goal-improve-skill.md`, `score-skill`, `token-count`. Fix the loop (feeds P1.1) so "0 undocumented hunks" is actually achievable.
- **P1.3 — Eliminate the five-manifest lockstep class.** Replace "humans bump 5 manifests" with `bin/sync-manifests` (or a CI `generate + git diff --exit-code`) that renders the 4 secondary manifests' shared metadata from `.claude-plugin/plugin.json`, keeping only harness-specific keys (Codex `interface`, skills/commands paths, Gemini's reduced shape) as overlays. *Minimum*: extend the CI sync check from name+version to also cover description/author/homepage/repository/license (those drift silently today).

### P2 — Recover lost capability + take explicit scope positions

- **P2.1 — `docs/07-authoring.md`** (GAP H3/M2/M4): port the "Building skills" doctrine ("never from imagination," the 2-3×-then-codify loop), the four anti-patterns, the sidecar/progressive-disclosure policy, and condensed description-writing guidance. Re-point dev-bench nouns; the plan's port instruction must also drop the `staging`/promotion bullets (no consumer staging pipeline).
- **P2.2 — Port the Check 1-21 table + allowlist escape-hatch docs** from the dev-bench `eval/README.md`. Today a user who hits a Check 13 secret FAIL has **no doc** telling them `<!-- pragma: allowlist secret -->` exists — it appears only inside test fixtures. Add to `docs/06-testing.md` or a checks reference.
- **P2.3 — `SECURITY.md`** (GAP M3) + **`PULL_REQUEST_TEMPLATE.md`** (GAP M5) + issue templates (GAP L5).
- **P2.4 — Declare product scope explicitly.** The dev-bench ships `automating-browsers` and `generating-ai-ideas`; the plugin ships only `improving-skills` and never says why. **Verdict: exclude both** — `automating-browsers` is Playwright-MCP-coupled and off the "author/evaluate/improve skills" domain; `generating-ai-ideas` is off-scope and would fail the 0-WARN gate (304-line reference needs splitting). Record both as deliberate exclusions in `SYNC.md`'s "Not ported" note so a future sync neither pulls them nor flags them as missing.

### P3 — Harden the product & the release process

- **P3.1 — Static linting in CI** (separate job, don't bloat the harness job): `shellcheck` over the bash tools + `tests/*.sh`, and `ruff` (or `py_compile` + `ruff`) over `bin/trigger-accuracy` (556 ln stdlib) and `bin/behavioral-check`. *A repo whose product is a code-quality harness shipping unlinted code is a credibility gap.* (Note: there is **no** linter config in either repo today — this is net-new, not alignment.)
- **P3.2 — Test the headline cross-harness feature.** `run-probes` (Pi/Codex spawning) has **zero** automated coverage. Add a unit test that monkeypatches `subprocess.run`/a fake `pi`/`codex` on PATH and asserts `_probe_argv` builds the right argv (`pi → ['pi','--mode','json','--no-session','--approve',…]`) and that collected transcripts are scored. Protects the 338-line superset across future syncs.
- **P3.3 — Resolve the Codex commands gap** (upgrade from GAP L2). Codex is advertised "install-validated" but `.codex-plugin/plugin.json` has no `commands` key, so `/skill-kit:goal-*` can't reach Codex users. Verify the Codex plugin schema: if `commands` is honored → add `"commands": "./commands/"` + re-validate; if not → downgrade docs/04 to "skills-only port; commands unavailable on Codex." Split "install validated" from "commands validated" in the status matrix.
- **P3.4 — Fix Pi positioning.** Pi is wired as a **probe runner** (`bin/trigger-accuracy --runner pi`), not an installable harness (no Pi manifest, not in docs/04's table, not in README's install line). The "multi-harness plugin (… / Pi)" framing over-claims it. Reclassify Pi everywhere as "probe-runner target, not an install harness" (today's reality), or add a real Pi manifest + docs row if a Pi extension format exists.
- **P3.5 — Cursor validation runbook.** Cursor is honestly marked "not locally validated" and *does* carry the `commands` key, so the open question is just install + command resolution. Add a short runbook → upgrade docs/04 status to "validated" with a date.
- **P3.6 — Release engineering for v0.3.0.** Add `CHANGELOG.md` (Keep-a-Changelog, back-fill 0.2.2) and a tag-triggered release workflow that runs the gates then `gh release create` from the changelog section, so cutting v0.3.0 is `bump (auto-propagated) → tag → push`.

### Deliberately deferred (with exit conditions)

- **`check-skill --all`** — defer until skill-kit ships >1 skill; CI already loops `for dir in skills/*/` and there is exactly one skill. Spend the effort on P1 instead.
- **`agents/` subagents** — keep deferred (the "no imagination" rule is right), **but** make the revisit trigger observable: today the documented trigger ("the day the value-add script demonstrably leaks context bias") has no detection mechanism and can never fire. Define a concrete signal (e.g. a value-add verdict that flips when re-run in a fresh session, logged to `.skill-kit/runs/`).

---

## Suggested sequencing

1. **v0.2.x patch** — P0 (all correctness/staleness fixes) + P2.3 (SECURITY/PR template, no code risk). Bump patch in lockstep.
2. **v0.3.0 minor** — P1 (drift automation + manifest auto-derive) and P2.1/P2.2/P2.4 (authoring + checks docs + scope), the meaty feature/process work. P1.1 lands first as the keystone.
3. **v0.3.x / v0.4.0** — P3 (linting, probe tests, Codex/Pi/Cursor resolution, release workflow).

P1.1 (CI drift check) is the keystone: once the contract is executable, every later sync and every contributor edit is guarded, and the class of bug this whole exercise diagnosed cannot silently recur.
