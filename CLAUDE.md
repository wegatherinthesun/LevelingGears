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

**v0.303 — bug #30's real fix: shift+left-click an equipped item to score it.** v0.302's mitigation
for bug #30 (a clearer `/lgs score` usage message) was rejected as too complicated; the requested fix
was a direct one: shift-click an equipped item in the character window to print its score to chat,
no slash command needed. Verified Blizzard's real click behavior via FrameXML before implementing
anything: right-click unconditionally fires
`UseInventoryItem` regardless of modifiers (would risk an unwanted trinket-proc etc. on shift+right-
click), so this shipped as **shift+left-click** instead — side-effect-free, and reuses the same
gesture Blizzard already uses for "insert item link in chat." `GearEvaluation.lua` now hooks each
equipped slot button once via `HookScript` (additive, doesn't replace Blizzard's own handler);
`/lgs score` still works as the debug-bench fallback. This also pulled forward and closed
`ROADMAP.md`'s previously-gated 0.33 item — see that file for the consequence for the future 0.6
"suggest gear" gesture (shift+left-click is no longer available for it). Bugs #28/#29 from v0.302
remain as they were (see `bugs/known-bugs.md`). Next step: resume `TEST_PLAN.md` at T1 to re-confirm
this and last round's fixes, then continue through T16-T35, which were never reached. Testers email
completed checklists to `wegatherinthesun@gmail.com` per `TEST_PLAN.md`'s own Quick start. Full
detail in `PROGRESS.md`'s Current status section.

How to handle a completed test report is a standing rule — see `CONVENTIONS.md`'s Hard process
rules.

After finishing any step: update `PROGRESS.md` (and `bugs/known-bugs.md` if relevant) before
considering the task done — see `CONVENTIONS.md`'s Mandatory maintenance rules.
