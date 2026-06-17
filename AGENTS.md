# AGENTS.md — Skill Kit

Guidance for AI agents (and humans) working in this repo.

## What this is

Skill Kit is a multi-harness plugin (Claude Code / Codex / Cursor / Gemini / Pi) for
authoring, evaluating, security-reviewing, and improving Agent Skills. It ships skills
plus `bin/` tools; there is **no compiled bundle** (no `package.json`), so the plugin
manifests are the only version-bearing files.

## Test / verify

```bash
bash tests/run-self-tests.sh
python -m pytest tests -q
```

`SYNC.md` documents the pre-release drift-check (run the harness probes, diff against
the upstream source).

## Releasing — bump the version, or new code never reaches users

**This is the easy step to forget.** The `mjenkins-toolbox` marketplace references this
plugin by repo tracking `main`, and Claude Code caches the installed plugin **keyed by
the version** in its manifest. So:

> Landing changes on `main` **without bumping the version** means installed plugins keep
> serving the **stale cached version** — `/plugin update` and cache refreshes only pick
> up new code when the version string changes.

When a change should reach users, **bump the version in all five manifests in lockstep**
(they must match — the CI manifest-sync check in `.github/workflows/harness.yml` enforces
it, using `.claude-plugin/plugin.json` as the source of truth):

1. `.claude-plugin/plugin.json`  ← canonical source of truth
2. `.plugin/plugin.json`
3. `.codex-plugin/plugin.json`
4. `.cursor-plugin/plugin.json`
5. `gemini-extension.json`

Then run the tests, commit via PR, merge, and cut the release: `git tag vX.Y.Z` +
`gh release create vX.Y.Z`. (Note: this repo has no git tags / GitHub releases yet — the
first release should be cut at the version already in the manifests.)

Semver (pre-1.0): new features → minor (`0.x.0`); fixes only → patch (`0.x.y`).

## Conventions

- Work ships via PRs against `main`; never push to `main` directly.
- Keep changes focused; follow existing patterns in the file you're editing.
