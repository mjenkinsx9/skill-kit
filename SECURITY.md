# Security Policy

## Supported versions

Only the latest commit on `main` is supported.

## Reporting a vulnerability

Use **GitHub private vulnerability reporting**: *Security tab → Report a
vulnerability* on the skill-kit repository. Please do **not** open a public
issue for anything exploitable.

You'll get an acknowledgment within a few days. No bounty program — but
reporters are credited in the fix commit unless they prefer otherwise.

## What counts as a security bug here

This plugin ships executable `bin/` tools, and one of them
(`bin/check-skill`) is itself a security scanner for agent skills, so its
blind spots are in scope:

- **Harness bypass** — skill content that contains a secret, a security smell
  (`curl | sh`, exfiltration patterns, …), or another flagged pattern but
  evades Checks 10/12/13 (e.g. via encoding, file placement, or pragma abuse).
- **Unintended execution** — a crafted `tests.md` that causes
  `bin/behavioral-check` to extract and run commands outside its documented
  contract, or anything that makes the `bin/` tools execute code they
  shouldn't.
- **CI injection** — skill files crafted so the GitHub Actions workflow
  executes attacker-controlled input.

## Out of scope

- Heuristic imperfection in WARN-level checks (the docs are explicit that
  WARNs are prompts for human review, not verdicts). Non-exploitable false
  negatives are welcome as regular issues — there's an issue template for
  exactly that.
- Vulnerabilities in Claude Code, the Claude API, or third-party tools this
  plugin drives — report those to their vendors (for Anthropic products:
  https://www.anthropic.com/responsible-disclosure-policy).
- Social-engineering scenarios that require the victim to ignore the
  plugin's own documented review workflow (e.g. promoting an unreviewed
  skill without running `bin/check-skill`).
