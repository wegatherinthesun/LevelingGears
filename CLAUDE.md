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
| [`bugs/known-bugs.md`](bugs/known-bugs.md) | investigating or recording a bug — still-open bugs only |
| [`bugs/resolved-bugs.md`](bugs/resolved-bugs.md) | recording a fix once a bug is Solved/Mitigated, or — especially — when troubleshooting a difficult bug: the same root cause (a stale forward-declaration, an undebounced event, a client API returning an unexpected shape) has recurred before, and a past entry's investigation technique is often the fastest way in |
| [`TEST_PLAN.md`](TEST_PLAN.md) | before AND after every commit — what changed, what's at risk, and the full regression checklist; keep it current. Also the file testers fill in and email back (see its Quick start) |
| [`TESTERS.md`](TESTERS.md) | optional extra context for testers — not required reading, don't over-invest here |

Never build past the current step before first receiving beta testing feedback from the previous one — see
`CONVENTIONS.md`'s "Hard process rules for Claude Code."

## Current step

**Current version: v0.382 — every currently-known code fix is in; the sole next step is a real live
test pass.** This closes out a short cycle prompted by a live report (playing an Enhancement Shaman,
the addon recommended Spell Power instead of Attack Power): v0.38 added a "Spec:" override dropdown
plus a first, incomplete tie-break fix to `Scoring.DetectSpec`; v0.381 replaced `DetectSpec`'s entire
point-reading method after a second report (44 points in Enhancement, still detected as Restoration)
disproved the tie-break theory — it now sums each talent's own `currentRank` via `GetNumTalents`/
`GetTalentInfo` instead of trusting `GetTalentTabInfo`'s aggregate at all, confirmed as a real pattern
via two other addons on this client (`ShamanPower.lua`, `PallyPower.lua`). v0.382 bundled in roadmap
item 0.37 (a helper-text line explaining why primary stats aren't weightable) since bug #29 — the
only other open item — has no further code fix possible without live evidence. See
`bugs/resolved-bugs.md` #37 (and its second update) for the full spec-detection investigation.

This is a **bug-fix → test → ship cycle** the author asked to set up and repeat until the addon is
ready for `ROADMAP.md`'s `0.4` (freeze the item/quest schema, start the real database). Builds on
0.31 (single weight set per character, direct-entry stat editing, analytically-derived `Priorities.
lua` defaults — see `PROGRESS.md`'s Current status and `bugs/resolved-bugs.md` #31-#35), 0.311-0.313
(research gaps closed, debug log ring buffer bumped, a gear-evaluation debounce gap fixed — see
`bugs/resolved-bugs.md` #36), and 0.38 (the versioning-ladder slots 0.31-0.38 are documented in
`CONVENTIONS.md`; the next free two-decimal slot is 0.39). 0.381/0.382 are thousandths bugfix
patches on 0.38, not new sub-features — see `ROADMAP.md`'s "Testing Phase 1 follow-ups" section,
which now reads every item (0.31-0.38) as Built.

**Next step: a real `TEST_PLAN.md` T1-T35 pass against v0.382 — not more code.** Everything from
v0.301 onward is implemented and statically validated but has had no live confirmation since the
very first (partial) test report. Two things matter most this round:
- **Bug #29** (window position): drag the window, do an actual `/reload` or full relaunch (not just
  close/reopen), then pull `/lgs debug dump` — the one piece of evidence that can close this outright.
- **Bug #37** (spec detection, v0.381's rewrite): with debug mode on, confirm a `DetectSpec:` log line
  now reports the correct per-tab point counts for a real character (e.g. `tab2=44` for an Enhancement
  Shaman fully specced into that tree), and that the "Spec:" dropdown/status line work as expected —
  also check the new "Spec" section doesn't overlap "Stat weights" below it (a reasoned height
  estimate, not a measured value; the 0.382 primary-stats helper text added there too).

**Exit criterion for this cycle:** once a T1-T35 pass comes back with no unresolved Blocker/Critical/
Major findings (`TESTERS.md`'s severity scale) and bug #29 is closed or reclassified with real
evidence, move to `ROADMAP.md`'s `0.4` — not before. Until then, whatever the pass finds becomes the
next cycle's patch list: fix with real evidence (add diagnostic logging first if the cause isn't
obvious, same as bugs #29/#36/#37), re-validate, commit, push, and re-test.

Nothing further should be built or "fixed" blindly until this test pass happens. Testers (including
the author, for their own runs) email completed checklists to `wegatherinthesun@gmail.com` per
`TEST_PLAN.md`'s own Quick start — or report results directly if that's more practical.

How to handle a completed test report is a standing rule — see `CONVENTIONS.md`'s Hard process
rules.

**When troubleshooting a difficult or hard-to-pin-down bug, check `bugs/resolved-bugs.md` before
guessing at a fix.** This project's history repeats root causes more often than it invents new
ones — a stale forward-declaration, a client API returning an unexpected type/shape, an
undebounced event handler, a client-specific slot/API quirk — and a past entry often already
contains the exact investigation technique (most notably: reading the on-disk debug log directly
rather than reasoning from code alone) that cracked a similar-looking problem before.

After finishing any step: update `PROGRESS.md` and the bug ledger before considering the task
done — `bugs/known-bugs.md` while a bug is still open, moved to `bugs/resolved-bugs.md` (same bug
number) the moment it's Solved or Mitigated with nothing further to do — see `CONVENTIONS.md`'s
Mandatory maintenance rules.
