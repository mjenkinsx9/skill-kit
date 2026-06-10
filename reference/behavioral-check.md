# Behavioral test (live)

`check-skill` proves a skill is *well-formed*; `value-add-test` and
`trigger-accuracy` probe its *description*. **None of them run the skill's
actual tooling.** For a tool-wrapping / script-backed skill, the question that
matters most is the one none of those answer:

> Does the documented command actually reach the system and return sane output **today**?

`behavioral-check` answers it by executing the skill's own `tests.md`
scenarios live and reporting what really happened.

It is the cheap, *real* counterpart to the heavy improving-skills composite
(`/skill-kit:improving-skills`): that loop fans out hundreds of agents and is
deliberately locked to read-only / no-prod so it never touches live
infrastructure — so it can grade *answer quality* but can never confirm the
*integration works*. This does, in a handful of seconds and ~0 tokens.

## What it does (deterministic) vs. what you do (judgment)

Like `value-add-test` and `trigger-accuracy`, the split is deliberate:

- **The script** extracts the runnable commands from `tests.md` (both fenced
  ` ```bash ` blocks and inline `` `python …` `` spans — plus a leading `VAR=value` env prefix,
  applied via the subprocess env — are supported), runs each
  one in a chosen working directory, and reports its **exit code, an output
  preview, and automatic sanity flags** (`TIMEOUT`, `TRACEBACK`, `EMPTY-STDOUT`).
- **You / the orchestrator** compare each command's real output against the
  scenario's **`Expected`/`Result`** prose to decide PASS/FAIL. The script never
  judges semantics — `data_reduction: 0` is valid JSON; only a human/agent knows
  it's wrong.

## Usage

```bash
behavioral-check <skill-dir>                       # run from the current dir
behavioral-check <skill-dir> --cwd <checkout>      # run commands from <checkout>
behavioral-check <skill-dir> --dry-run             # list commands, run nothing
behavioral-check <skill-dir> --json > result.json  # structured output too
```

Accepts a skill directory (it finds `tests.md`) or a direct path to a `tests.md`.

### Working directory & credentials

The commands in `tests.md` are written relative to a repo root (e.g.
`python scripts/pure-check.py status`) and usually need credentials from a
git-ignored `.env`. So **run the harness from — or point `--cwd` at — the
checkout where the skill's `scripts/` and `.env` actually live.** A common gotcha:
a git **worktree** does not carry the gitignored `.env`, so validate worktree
skills with `--cwd <main-checkout>`.

## Applicability

Built for **script-/tool-backed skills** whose `tests.md` scenarios are runnable
commands (the `*-check.py` wrappers, CLI skills, anything with a deterministic
invocation). Skills whose value is a generated artifact, a voice/rewrite, or an
orchestration side-effect have no runnable `tests.md` commands — this harness will
report "no runnable commands found"; verify those with `value-add-test` /
`check-skill` instead.

## Interpretation

- **`RAN`** — the command executed to completion. Read the preview and compare to
  `Expected`. A **non-zero exit is not a failure** when the scenario is an error
  case (e.g. an unknown-target refusal *should* exit non-zero).
- **`ERR`** — the command **timed out** or printed a **traceback**: a genuine
  behavioral break. The harness exits non-zero so automation can catch it.
- Harness exit: `0` all commands completed · `1` a timeout/traceback occurred ·
  `2` no `tests.md` / no runnable commands / usage error.

The `summary:` line totals commands run, timeouts, tracebacks, and non-zero exits.

## Safety

This **executes commands taken verbatim from `tests.md`** in a shell. Only point
it at skills whose `tests.md` you trust; well-authored skills keep their test
scenarios read-only by author contract (they query and report, never mutate).
Use `--dry-run` first to see exactly what will run. The harness adds nothing of
its own — it runs only what the skill documents.

## Why a Python script

Same spirit as the rest of the plugin's `bin/` helpers: trivial to read and
modify, pure stdlib, no dependencies. Markdown command-extraction is cleaner in
Python than shell, and it runs the same on Windows and POSIX.
