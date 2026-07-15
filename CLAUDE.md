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

**v0.306 (on the `single-profile` fork) — removed the stat-weight edit box's remaining 0-10 clamp
and "importance scale" framing.** v0.305's edit box still enforced a 0-10 range and still said
"0 = ignore, 10 = highest importance," so it was reported as still showing "the 1-10 system" rather
than the actual value. There is no scale any more: the box shows and accepts exactly the number
`Scoring.lua`'s `ComputeScore` multiplies the derived stat by, with no minimum, maximum, or
rating-language on top (`Weights.WEIGHT_MIN`/`WEIGHT_MAX` removed; `SetWeightValue` no longer
clamps). Full detail in `bugs/known-bugs.md` #33.

**v0.305 (same fork) — replaced the stat-weight +/- buttons with direct-entry edit boxes.** Each stat
row is a label and one editable text box; type a value, press Enter (or click away) to save. Invalid
(non-numeric) typed text reverts to the real saved value rather than sticking. "Restore Defaults"
persists unchanged. Full detail in `bugs/known-bugs.md` #32.

**v0.304 (same fork) — removed the multi-profile system entirely.** There is now exactly one
hand-adjustable weight set per character, restorable to spec defaults via "Restore Defaults." Since
weights don't auto-update on a respec or talent change (and never did — see `ROADMAP.md`'s new
0.35), the addon tells the player this once at boot in chat. Full detail in `bugs/known-bugs.md` #31.

All three changes happened on the `single-profile` git branch, forked from `main` right after v0.303
was committed there. v0.303 (still on `main` and carried into this branch) was bug #30's real fix:
shift+left-click an equipped item in the character window to print its score to chat, replacing
`/lgs score` for everyday use (`/lgs score` still works as a debug-bench fallback). See
`bugs/known-bugs.md` #30 for why shift+left-click was used instead of the originally-requested
shift+right-click.

Next step: resume `TEST_PLAN.md` at T1 to re-confirm all of v0.302-v0.306's changes, then continue
through T16-T35, which were never reached. Testers email completed checklists to
`wegatherinthesun@gmail.com` per `TEST_PLAN.md`'s own Quick start.

How to handle a completed test report is a standing rule — see `CONVENTIONS.md`'s Hard process
rules.

After finishing any step: update `PROGRESS.md` (and `bugs/known-bugs.md` if relevant) before
considering the task done — see `CONVENTIONS.md`'s Mandatory maintenance rules.
