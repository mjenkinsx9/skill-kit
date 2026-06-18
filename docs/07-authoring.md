# Authoring skills

This is the methodology behind a skill that survives the harness — ported from the
skill-testing dev-bench and adapted for plugin users. It is harness-neutral: it
describes how to build a skill, not how to install one (see
[Multi-harness support](04-harnesses.md) for that). Where it names a check, see
[The 21 checks](08-checks-reference.md) for the exact rule and escape hatch.

## Building skills (the most important rule)

**Never write a skill from imagination. Skills come from doing real work first.**

The process:

1. **Pick one task.** Not "handle operations" — one specific task with one clear
   outcome. Optionally run `/skill-kit:goal-new-skill <gerund-form-name>` to
   interview yourself into a measurable end state and persist it as a `goal.md`
   sidecar.
2. **Do it live.** Walk through it in a real session. Correct mistakes, add missed
   steps, confirm what works. You're doing the work, not writing instructions.
3. **Do it again.** Run the same task 2–3 more times with different inputs. Catch
   edge cases — empty results, missing data, weird formats. This is where the skill
   gets real.
4. **Codify it.** After 2–3 successful runs, write `SKILL.md` + `tests.md` from
   experience, not theory. Add only the sidecars you actually need (`references/`,
   `scripts/`).
5. **Test as a skill.** Run the same scenarios through the skill instead of
   manually. Same quality? Good. Something off? Fix it and update the skill.
6. **Let it fail.** Use it for a week. When it breaks, don't just fix the output —
   fix the skill so that failure can't happen again.
7. **Stop touching it.** When it just works, move on.

```
Do it manually (2-3x) → Codify into SKILL.md → Test → Fail/fix/update → Stable → Move on
```

**The trap:** writing a detailed `SKILL.md` on day one from your head. It will be
wrong in ways you can't predict until you've run the workflow for real.

## Scope: when one task is really several

Step 1 says "pick one task," but "one task" is about a single coherent flow, not a
single rubric item. Split into separate skills when **either** holds:

- **Distinct trigger audiences.** The phrasings that should fire it fall into
  unrelated buckets a single description can't sharpen around without going generic
  (and tripping Check 7b). One audience → one skill.
- **Independent sub-procedures with separate outputs.** The steps branch into parts
  that don't share state and each emit their own deliverable. If you could run half
  the skill and hand off a complete artifact, that half is its own skill.

A skill covering many rubric *areas* over one input is still one task. A
`reviewing-pull-requests` skill checks correctness, tests, security, and style —
four areas — but it's one task: one diff in, one prioritized comment list out, one
trigger ("review this PR"). Don't split that. Do split "review my PR and also deploy
it" — two audiences, two outputs.

## Anti-patterns

- **Autoresearching a brand-new skill.** `improving-skills` polishes an existing
  `SKILL.md` against `test-prompts.md` and `tests.md`. It is not a substitute for
  doing the work manually 2–3 times first.
- **Writing `SKILL.md` as documentation.** Skills are instructions to the model
  ("Read X. Apply Y. Emit Z."), not exposition about what the skill is. If a section
  starts with "This skill helps…", rewrite it imperatively.
- **Broadening the description "just in case."** Trades trigger precision for recall
  and silently degrades discrimination. Sharpen the trigger language instead of
  widening it.
- **Inlining executable logic as prose.** If the instructions describe a
  deterministic procedure ("loop through files, count matches, sort by…"), it
  belongs in `scripts/` as code the skill executes, not as instructions the model
  re-derives each invocation. Reserve `SKILL.md` prose for decisions scripts can't
  make.

## Supporting files / progressive disclosure

Keep `SKILL.md` focused on overview + navigation. Move detail into sibling files in
the skill directory — the model loads them only when needed (progressive
disclosure).

```
my-skill/
├── SKILL.md              # Overview and instructions (required, keep ≤500 lines)
├── tests.md              # ≥3 verification scenarios (quality scoring) — required
├── test-prompts.md       # Positive/negative trigger fixtures — only for autoresearch
├── scripts/              # Utility scripts — executed, not loaded
├── templates/            # Skill-local templates (e.g. program.md scaffolds)
└── references/           # Detailed docs loaded on demand — for multi-topic skills
    ├── reference.md
    ├── examples.md
    └── ...
```

**Reference docs go in `references/`; scripts go in `scripts/`.** As soon as a skill
carries reference content besides `SKILL.md`, put it in a `references/` subdir —
don't leave `reference.md`/`examples.md`/etc. loose at the skill root (matches the
official [skill structure docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)).
`check-skill` Check 18 WARNs on any non-governance `.md` beside `SKILL.md`, and
Check 19 WARNs on any loose script (`*.py`/`*.sh`/… belongs in `scripts/`). Only
`SKILL.md` and the required sidecars (`tests.md`, `test-prompts.md`, `goal.md`) stay
at the root.

**Line budgets** (tied to Checks 9, 16, 17):

- `SKILL.md` body ≤ ~500 lines — split detail into supporting files past that
  (Check 9).
- Each reference file ≤ ~200 lines — if one grows past that, split it into multiple
  topic-focused files within `references/` (Check 16).
- Any reference file over 100 lines opens with a `## Contents` table of contents, so
  the model sees the full scope even from a partial read (Check 17).

**Which sidecars to keep vs strip.** `tests.md` is always required. The rest earn
their place or get deleted:

- `references/` files — keep only when the detail would push the `SKILL.md` body
  toward the ~500-line budget, or is genuinely needed on demand rather than every
  run. Otherwise inline it.
- `test-prompts.md` — only if you plan to autoresearch-improve the skill.
- `scripts/` — only if the skill executes deterministic logic (see the inlining
  anti-pattern).

Worked contrast: a `reviewing-pull-requests` skill ships a single
`references/reference.md` (a multi-section rubric that would bloat the body) and no
`examples.md`; a simple self-explanatory skill ships neither — just `SKILL.md` +
`tests.md`. When in doubt, strip — an unused sidecar is just maintenance surface.

**The orphan rule (Check 20).** Reference every supporting file from `SKILL.md` so
the model knows it exists and what it contains. Keep references one level deep (no
`a → b → c` chains). A bundled file that `SKILL.md` never links is an orphan — the
model won't load it; Check 20 flags it so you either link it or move it out of the
skill (working/meta docs like a campaign tracker don't belong in the live skill).

## Writing the description

The `description:` in a skill's frontmatter is the **primary trigger mechanism** —
the only thing, alongside the name, the model sees when deciding whether to consult
a skill. The body is loaded *after* that decision, so a perfectly-written body
behind a weak description never runs. This is the constructive companion to Checks
7, 7b, and 8.

What a description must carry:

- **What it does AND when to use it**, in one place — all the "when to use"
  information lives here, never only in the body.
- **Imperative, third person.** "Reviews a diff and… Use when the user asks to…" —
  not "I can review" or "You can use this to" (Check 6 FAILs first/second person).
- **User intent, not implementation.** Describe what the user is trying to achieve,
  not the mechanics of how the skill works.

**Enumerate ≥2 concrete conditions — then generalize, don't list.** Name at least
two concrete trigger conditions (Check 7b): "Use when the user asks to review a PR,
audit a diff, or check changes before merging" beats "Use when you have code to look
at". But generalize to intent *categories*; do not enumerate an ever-expanding list
of exact queries. The description is injected into *every* prompt and competes with
every other skill — a query-by-query list bloats it and overfits. When triggering
misses, widen the *category* of intent, not the count of examples.

**Pushy ≠ broad** (the one tension to get right). Two pieces of guidance look like
they conflict; they don't, because they act on different axes:

- **Be a little pushy** (tone) to combat *under*-triggering. State plainly when the
  skill *should* fire, including phrasings where the user never names the skill or
  file type.
- **Stay sharp** (boundary) to combat *over*-triggering. Keep the scope's edges
  concrete so the skill declines near-misses.

A description can — and should — be both. The failure modes are timid-and-narrow
("may be useful if you happen to have a PDF") and pushy-but-vague ("use this
whenever you have anything to work with"). Aim for **pushy and sharp**.

Constraints:

- ≤1024 chars (hard limit, Check 5; over-limit is truncated). Aim for ~100–200
  words.
- ≥40 chars of substance (Check 8) — a one-liner is too vague to drive discovery.
- No angle brackets / XML (Check 5).

| | Example |
|---|---|
| ✗ timid + narrow | `Builds a dashboard for internal data.` |
| ✗ pushy + vague | `Use this whenever the user has any data or numbers to deal with.` |
| ✓ pushy + sharp | `Builds a fast dashboard from internal metrics. Use when the user asks to visualize company data, build a metrics dashboard, or chart internal numbers — even if they don't say "dashboard".` |

For the **negatives** that prove a description is sharp, the valuable cases are
*near-misses* — queries that share keywords but need something else. For a PDF
skill, "extract the fields from this API JSON response" is a good negative (shares
"extract", not the PDF context); "write a fibonacci function" is a useless negative
because nothing about it tempts the skill.

## Mechanical checks

Every new or modified skill must clear the harness:

```bash
check-skill .claude/skills/<name>          # or a direct path to SKILL.md
```

Run it after every `SKILL.md` edit and before shipping. Zero FAILs required; WARNs
are prompts to look. The full check list, levels, and escape hatches are in
[The 21 checks](08-checks-reference.md).

---

Back to the documentation index: [README.md](README.md)
