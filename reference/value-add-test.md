# Value-add test

**The question the static harness and the autoresearch composite cannot answer:
does running the skill actually beat just asking the model with no skill at
all?** `check-skill.sh` tells you a skill is *well-formed*; the improving-skills
composite (`0.4·trigger + 0.4·quality + 0.2·efficiency`) tells you it's
*on-target and tight*. Neither tells you it *earns its complexity*. A skill can
score ~0.97 on the composite and still lose a blind head-to-head to the cold
model — its scaffolding burying the rigor that was supposed to be its value.
This test catches that.

> **This is a milestone / pre-promotion check, not a per-edit check.** It spawns
> several sub-agents per run (see Cost). Run it before first promotion, and again
> after any change to the skill's **output format or process scaffolding** —
> those are exactly the changes that flip the result.

## When this test applies

- **Run it** — generative / judgment / advisory skills whose value is *quality of
  reasoning or output*: idea generation, review, research, summarization,
  planning. "Does it think better than cold Claude?" is the right question.
- **Wrong frame — adapt or skip:**
  - *Deterministic / mechanical skills* (run a script, enforce a format, count
    things): the value is consistency/correctness, already covered by
    `check-skill.sh` + `tests.md`. Cold Claude may score higher on free-form prose
    while missing the determinism that is the whole point. Skip, or replace the
    rubric with a pass/fail correctness check.
  - *Safety / refusal / policy skills*: the value is reliable constraint
    adherence. Judging on rigor/actionability would *reward* a cold answer that is
    "more helpful" precisely by violating the constraint. Judge on
    policy-adherence instead, or skip and lean on `tests.md` error/edge scenarios.
  - *Format-compliance skills*: the format **is** the value; "beats cold model" is
    meaningless. Skip.
  - Rule of thumb: **value = "thinks better" → run it; value = "does the same
    thing every time" or "refuses correctly" → wrong instrument, record N/A and
    move on.**
- *No natural cold baseline* (skill wraps a tool/script with no "just ask the
  model" equivalent): record `N/A — no cold baseline`.

## Protocol

### 1. Pick seeds
Reuse the skill's `test-prompts.md` **positive** prompts verbatim — they are the
canonical "representative inputs the skill should fire on" (same fixture-reuse
rationale `scoring.md` gives for `tests.md`). Default **N = 3**, sampled across
the list (first / middle / last), scaling to 5 for a high-stakes promotion.
Negatives are out of scope — a head-to-head on a prompt the skill shouldn't fire
on is meaningless. `value-add-test <skill-dir>` does this selection for
you and assigns the A/B order below.

### 2. Generate both arms — in fresh sub-agents
For each seed, produce two outputs, **each in its own fresh sub-agent with clean
context** (never inline — the orchestrator has already read the skill and would
contaminate the baseline):

- **Skill arm:** sub-agent reads the skill and runs it on the seed, producing the
  skill's real deliverable (format and all).
- **Cold arm (baseline):** sub-agent is given *only the raw user seed* and told to
  answer with its own expertise. It must **not** read the skill, its sidecars, or
  any skill-derived instructions.

Correct cold prompt: `"<seed>" — answer with your best work; do not read any
skill files.`
Contaminated (do NOT do this): pasting the skill's framework, output template, or
"act as a council of…" framing into the cold prompt. The baseline is *plain
Claude on the task a user would actually type.*

### 3. Judge blind
Per seed, **2 independent judge sub-agents** (fresh context each). Give each judge
only: the two outputs labeled **A** and **B** (per the randomized order from the
script), the rubric, and the task. The judge is **not** told which arm is the
skill, **never** sees `SKILL.md`, and its prompt is scrubbed of process-language
tells. (If the skill's *own output* contains "Council Report" / "Gate Status" /
role names, those stay — that is the real output being judged. Just don't add
tells in the framing.) Randomize A/B per seed so "skill" is sometimes A, sometimes
B; map A/B back to skill/cold **only after** all scores are collected.

**Rubric — 5 dimensions, 0–10 each, equal weight (max 50/arm/judge):**
1. **Rigor** — depth and correctness of reasoning.
2. **Evidence** — concrete, sourced (or honestly-flagged) proof, not assertion.
3. **Actionability** — a clear, falsifiable next step the user can act on.
4. **Risk-awareness** — surfaces the real legal/adoption/competition/economic risks.
5. **Signal-to-noise** — insight per line; scaffolding/filler/repetition counts against.

### 3b. Flag non-discriminating seeds and high variance
Before trusting the aggregate, surface two patterns the mean hides — they change what the verdict
*means*, not the number, so record each as one line in the summary:
- **Non-discriminating seeds** — a seed where the skill and cold arms land within ~2/50 of each
  other: the skill adds nothing *there*, even if it wins elsewhere. A PASS carried by one of three
  seeds is weaker than the aggregate implies. (This is the per-seed analog of an assertion that
  passes whether or not the skill ran — it isn't measuring the skill's value.)
- **High variance** — a wide spread between the two judges on a seed, or across seeds, signals
  flakiness: ambiguous output, a borderline prompt, or genuine judge disagreement. Don't over-read
  a lone high-variance seed; let the per-seed win tally and the CONCERN band (below) absorb it.

### 4. Tally and interpret
`lift = skill_aggregate − cold_aggregate` (mean total across judges × seeds),
plus a per-seed win tally. `value-add-test --tally <results.tsv>` computes
this. The verdict is **"majority + margin," not a single number** — at small N a
lone anomalous seed shouldn't flip a clear majority.

- **PASS** — skill wins the aggregate by a clear margin (≳1.5/50) **and** wins ≥ a
  majority of seeds.
- **CONCERN** — within ~1.5/50 of cold, or wins the aggregate but splits seeds.
  Record, investigate, do not auto-block.
- **FAIL** — cold beats the skill on the aggregate beyond the margin. This is the
  "the skill loses to just-ask-Claude" signal: the skill is well-formed but its
  value isn't reaching the user (usually format/scaffolding burying substance, or
  no real edge over the base model).

## What a FAIL / CONCERN means (and the fairness note)

The skill is judged on its **real deliverable, format included**, against a
free-form cold answer. That asymmetry is **fair and is the point** — the user
lives with the skill's actual output. If its prescribed format buries the
substance (e.g. process metadata, repeated status labels, role-by-role
scaffolding crowding out the ideas), that is a genuine defect this test exists to
surface — *not* an artifact to "fix" by letting the skill answer free-form. The
usual remedy for a FAIL is to make the skill **lead with the substance** and
demote its process machinery, then re-run.

## Enforcement

Required-to-run-and-record before promoting a generative/judgment skill. Record
the verdict (`PASS / CONCERN / FAIL`, date, lift, seeds) in the skill's
PROMOTION-CHECKLIST. A CONCERN or FAIL must be **acknowledged** — with a fix or a
written justification — never silently ignored. It is *not* a hard
promotion-blocking gate: it is stochastic and expensive, and in this repo only
the deterministic `check-skill.sh` hard-blocks.

## Cost & edge cases

- **Cost:** N seeds × (1 skill gen + 1 cold gen + 2 judges) = `4N` sub-agents at
  defaults (12 at N=3), several of which (the skill arm especially) may themselves
  be expensive. Milestone check, never per-edit, never inside the improving-skills
  inner loop.
- **Judge variance at small N:** mitigated by ≥2 judges, the per-seed win tally,
  and the CONCERN band. Don't over-read a single seed.
- **Contamination is the main validity threat:** keep A/B randomization in the
  script (not the agent); run every arm and every judge in a fresh sub-agent;
  scrub tells from judge prompts; map A/B→skill/cold only after scoring.

## Artifact

Record to `runs/value-add-<id>/results.tsv` (per-seed/per-judge rows:
`seed<TAB>judge<TAB>skill_total<TAB>cold_total`) plus a one-paragraph summary.
`runs/` is gitignored — the verdict is a recorded diagnostic, not a committed
gate file.
