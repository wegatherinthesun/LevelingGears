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

**v0.31 — consolidated release: single weight set per character, direct-entry stat editing,
analytically-derived defaults.** This squashes the `single-profile` fork (built and iterated
internally as v0.304-v0.308, now merged back into `main` and deleted) into one shipped version:

- **One weight set per character**, no profiles — create/switch/name-profile UI removed entirely
  (`bugs/known-bugs.md` #31).
- **Direct-entry stat editing** — each stat is a label plus an edit box showing and accepting the
  exact value the scoring engine uses, replacing the old +/- buttons and (after one follow-up fix)
  the leftover 0-10 clamp/"importance scale" framing (`bugs/known-bugs.md` #32/#33).
- **`Priorities.lua`'s default weights are now analytically derived** from real, verified TBC combat
  formulas (14 Attack Power = 1 DPS, crit/haste multiplier math, per-class mechanical corrections
  like Warrior rage-generation normalization and caster crit-multiplier talents) instead of either
  hand-authored guesses or an invented rank-to-number scale — see `DESIGN.md`'s Layer 3 section and
  `bugs/known-bugs.md` #34/#35 for the two-step correction that got here.

The individual v0.304-v0.308 numbers stay in `PROGRESS.md`'s Progress log and the bug ledger as the
accurate build history — they are not retroactively renamed — but 0.31 is the version going forward.
**Patches to 0.31 follow the usual thousandths rule: 0.311, 0.312…**, per `CONVENTIONS.md`'s
versioning ladder.

v0.303 (also on `main`) was bug #30's real fix: shift+left-click an equipped item in the character
window to print its score to chat, replacing `/lgs score` for everyday use (`/lgs score` still works
as a debug-bench fallback). See `bugs/known-bugs.md` #30 for why shift+left-click was used instead of
the originally-requested shift+right-click.

Next step: resume `TEST_PLAN.md` at T1 to re-confirm everything through 0.31, then continue through
T16-T35, which were never reached. Testers email completed checklists to
`wegatherinthesun@gmail.com` per `TEST_PLAN.md`'s own Quick start.

How to handle a completed test report is a standing rule — see `CONVENTIONS.md`'s Hard process
rules.

After finishing any step: update `PROGRESS.md` (and `bugs/known-bugs.md` if relevant) before
considering the task done — see `CONVENTIONS.md`'s Mandatory maintenance rules.
