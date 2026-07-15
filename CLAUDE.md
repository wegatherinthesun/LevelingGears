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

**v0.308 (on the `single-profile` fork) — replaced `Priorities.lua`'s anchor-scale weights with
values analytically derived from known TBC combat formulas.** v0.307's fix was called out as still a
shortcut: a real priority ORDER doesn't specify a magnitude, and inventing one (10/8/6/3/0) wasn't
"doing the math right." Confirmed real numeric per-point stat weights require either simulation
(`wowsims/tbc` has a genuine one, but it's gear/build-dependent and running it means real
infrastructure work) or analytical derivation from known mechanics — chose the latter, with the
requester's confirmation. Every weight now comes from verified formulas (14 AP = 1 DPS, crit/haste
multiplier math, Hit/Expertise's "a miss is zero damage" effect) plus real per-class mechanical
corrections (Warrior rage-generation normalization, caster crit-multiplier talents, HoT/DoT
crit-immunity), using the two real published numeric tables found (Warlock's Spell Power
Equivalency, Resto Shaman's Heal/Haste/MP5/Crit/Int/Stam ratios) directly rather than approximating
them. Also caught and corrected a conceptual error: guide priority orders blend true marginal value
with itemization-scarcity advice ("you'll get plenty of this stat anyway") — only the former belongs
in a per-item scoring weight, so the primary reference stat (AP/RAP/SP/HEAL) is never suppressed by
that reasoning. Added a `ROADMAP.md` "Past 1.0" entry to revisit whether real simulator-farmed data
is worth the infrastructure cost later. Full detail in `bugs/known-bugs.md` #35.

**v0.307 (same fork, earlier step)** — the intermediate, still-shortcut fix described above; see
`bugs/known-bugs.md` #34 for that history.

**v0.304-0.306 (same fork, earlier steps)** — removed the multi-profile system (one weight set per
character now), replaced the stat-weight +/- buttons with direct-entry edit boxes, then removed that
edit box's leftover 0-10 clamp/framing. See `bugs/known-bugs.md` #31/#32/#33.

All of this happened on the `single-profile` git branch, forked from `main` right after v0.303 was
committed there. v0.303 (still on `main` and carried into this branch) was bug #30's real fix:
shift+left-click an equipped item in the character window to print its score to chat, replacing
`/lgs score` for everyday use (`/lgs score` still works as a debug-bench fallback). See
`bugs/known-bugs.md` #30 for why shift+left-click was used instead of the originally-requested
shift+right-click.

Next step: resume `TEST_PLAN.md` at T1 to re-confirm all of v0.302-v0.308's changes, then continue
through T16-T35, which were never reached. Testers email completed checklists to
`wegatherinthesun@gmail.com` per `TEST_PLAN.md`'s own Quick start.

How to handle a completed test report is a standing rule — see `CONVENTIONS.md`'s Hard process
rules.

After finishing any step: update `PROGRESS.md` (and `bugs/known-bugs.md` if relevant) before
considering the task done — see `CONVENTIONS.md`'s Mandatory maintenance rules.
