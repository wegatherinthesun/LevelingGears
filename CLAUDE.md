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
| [`TEST_PLAN.md`](TEST_PLAN.md) | before AND after every commit — what changed, what's at risk, and the full regression checklist; keep it current. Also the file testers fill in and email back (see its Quick start) |
| [`TESTERS.md`](TESTERS.md) | optional extra context for testers — not required reading, don't over-invest here |

Never build past the current step before first receiving beta testing feedback from the previous one — see
`CONVENTIONS.md`'s "Hard process rules for Claude Code."

## Current step

**Current version: v0.311.** Consolidated release 0.31 (single weight set per character,
direct-entry stat editing, analytically-derived `Priorities.lua` defaults — see `PROGRESS.md`'s
Current status for the full summary and `bugs/known-bugs.md` #31-#35 for how it was built), plus
0.311's follow-up: closed two `Priorities.lua` research gaps and added scale diagnostics to bug #29
(`bugs/known-bugs.md` #29's update note, #34's update note). Patches to 0.31 follow the usual
thousandths rule (0.311, 0.312…), per `CONVENTIONS.md`'s versioning ladder.

**Next step: a real `TEST_PLAN.md` T1-T35 pass against v0.311 — not more code.** Everything from
v0.301 onward is implemented and statically validated but has had no live confirmation since the
very first test report. Only bug #29 (window position drift) is still genuinely open in the bug
ledger; a real on-disk debug log already ruled out the UI-scale-mismatch theory for it and captured
one real drag with no matching reopen yet — the next test pass just needs to reopen the window after
dragging it before pulling `/lgs debug dump` (see `bugs/known-bugs.md` #29's latest update). Nothing
further should be built or "fixed" blindly until a test pass happens. Testers email completed
checklists to `wegatherinthesun@gmail.com` per `TEST_PLAN.md`'s own Quick start.

How to handle a completed test report is a standing rule — see `CONVENTIONS.md`'s Hard process
rules.

After finishing any step: update `PROGRESS.md` (and `bugs/known-bugs.md` if relevant) before
considering the task done — see `CONVENTIONS.md`'s Mandatory maintenance rules.
