# CLAUDE.md — Leveling Gears

Living project memory, kept deliberately small. Detail lives in the files below — read whichever
one the current task actually needs, not all of them, every time.

## Read when relevant

| File | Read it when... |
|---|---|
| [`README.md`](README.md) | you need the one-paragraph pitch, install steps, or slash-command list |
| [`ROADMAP.md`](ROADMAP.md) | proposing or starting the next step, or asked "what's next" |
| [`PROGRESS.md`](PROGRESS.md) | you need history: what's built, why a past decision was made, or before writing a new progress entry |
| [`CONVENTIONS.md`](CONVENTIONS.md) | before writing or editing any code — coding rules, WoW/Lua sandbox limits, process rules, versioning ladder, technical reference notes |
| [`DESIGN.md`](DESIGN.md) | touching `Conversions.lua`/`Priorities.lua`/`Scoring.lua`/`Weights.lua` — the scoring engine's architecture and every judgment call behind it |
| [`DATA_PIPELINE.md`](DATA_PIPELINE.md) | working on the 0.41–0.44 data pipeline steps — exact source URLs, license status, file structure, and parser design |
| [`bugs/known-bugs.md`](bugs/known-bugs.md) | investigating, fixing, or recording a bug |
| [`TESTERS.md`](TESTERS.md) | onboarding a tester, or asked how testing/defect-reporting works on this project |
| [`TEST_PLAN.md`](TEST_PLAN.md) | before AND after every commit — what changed, what's at risk, and the full regression checklist; keep it current |

Never build past the current step before first receiving beta testing feedback from the previous one — see
`CONVENTIONS.md`'s "Hard process rules for Claude Code."

## Current step

**v0.301 — first Testing Phase 1 bugfix.** The author's own on-disk debug log surfaced a real bug
(#27, `bugs/known-bugs.md`) that the v0.3 static conflict audit couldn't have caught: `DetectSpec`
was crashing on every call since v0.25, so gear-outline coloring and spec-aware default weights had
likely never worked. Patched defensively. **Still not confirmed live.** Next step: work through
`TEST_PLAN.md`'s full regression checklist before anything else gets pushed — its first item is
confirming this exact fix (do defaults now seed spec-aware instead of a flat 5?). `TESTERS.md` has
the process for anyone else running that checklist. Full detail in `PROGRESS.md`'s Current status
section.

After finishing any step: update `PROGRESS.md` (and `bugs/known-bugs.md` if relevant) before
considering the task done — see `CONVENTIONS.md`'s Mandatory maintenance rules.
