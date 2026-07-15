# CLAUDE.md — Leveling Gears

Living project memory, kept deliberately small. Detail lives in the files below — read whichever
one the current task actually needs, not all of them, every time.

## Read when relevant

| File | Read it when... |
|---|---|
| [`README.md`](README.md) | you need the one-paragraph pitch, install steps, or slash-command list |
| [`ROADMAP.md`](ROADMAP.md) | proposing or starting the next step, or asked "what's next" |
| [`PROGRESS.md`](PROGRESS.md) | you need history: what's built, why a past decision was made, or before writing a new progress entry |
| [`CHANGELOG.md`](CHANGELOG.md) | you need a concise, version-by-version summary of what changed (starts at v0.383 — see `PROGRESS.md`/git log for anything earlier) |
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

**Current version: v0.383 — closed all 4 bugs found in the first real T1-T22 test pass; the sole
next step is another live test round.** Per direct instruction, each was built and individually
retested with no version bump in between (see `queue.md` for the working list this cycle drew from),
then batched into this one real version:
- **Bug #38 (Solved):** direct-entry stat weights looked like they rejected typed values — actually,
  clicking "Save Settings" directly (no Enter first) let `RefreshWeightLabels` overwrite the
  still-uncommitted edit. Fixed by clearing focus on every weight input first.
- **Bug #29 (Solved):** window position finally restores to the exact dragged spot. Found by
  comparing against how other addons handle this (per direct instruction) instead of guessing a
  third time: `AceGUI-3.0`'s Window widget saves two independent absolute screen coordinates
  (`GetLeft()`/`GetTop()`) instead of a single point/relativePoint/offset triple. Confirmed working
  live.
- **Bug #39 (Solved):** scoring an item with no clean numeric stats (a totem) looked broken — both
  `/lgs score` and shift-click now tell the player why instead of a misleading message or silence.
- **Bug #40 (Solved):** the "Spec:" control was a custom button with a permanently reserved gap;
  replaced entirely with Blizzard's native `UIDropDownMenuTemplate` (confirmed safe on this client
  via a real installed addon, `Omen.lua`, using it the same way with no library/version gating).

See `bugs/resolved-bugs.md` #29, #38, #39, #40 for full investigation detail, and `CHANGELOG.md`
(new this version — a concise, version-by-version summary going forward) for the short version.

This is a **bug-fix → test → ship cycle** the author asked to set up and repeat until the addon is
ready for `ROADMAP.md`'s `0.4` (freeze the item/quest schema, start the real database). Builds on
0.31 (single weight set per character, direct-entry stat editing, analytically-derived `Priorities.
lua` defaults — see `PROGRESS.md`'s Current status and `bugs/resolved-bugs.md` #31-#35), 0.311-0.313
(research gaps closed, debug log ring buffer bumped, a gear-evaluation debounce gap fixed — see
`bugs/resolved-bugs.md` #36), and 0.38 (the versioning-ladder slots 0.31-0.38 are documented in
`CONVENTIONS.md`; the next free two-decimal slot is 0.39). 0.381-0.383 are thousandths bugfix
patches on 0.38, not new sub-features.

**`bugs/known-bugs.md` now has zero open bugs.**

**Next step: another real `TEST_PLAN.md` T1-T35 pass against v0.383 — not more code.** The v0.382
pass got through T1-T22 and found the 4 bugs above; testing should resume from T22b through T35, plus
specifically retest T11/T22/T8b/T20b to confirm each fix actually holds (see `TEST_PLAN.md`'s "Recent
changes" section for exactly what to check on each).

**Exit criterion for this cycle:** once a full T1-T35 pass comes back with no unresolved Blocker/
Critical/Major findings (`TESTERS.md`'s severity scale), move to `ROADMAP.md`'s `0.4` — not before.
Until then, whatever the pass finds becomes the next cycle's patch list: fix with real evidence (add
diagnostic logging first if the cause isn't obvious, or compare against how another installed addon
solves the same problem, same as this cycle's bugs), re-validate, and — per direct instruction — do
NOT re-version or do a full doc pass after every individual fix; batch it all into one version bump
once a meaningful round of testing is done, the same way this version was assembled.

Testers (including the author, for their own runs) email completed checklists to
`wegatherinthesun@gmail.com` per `TEST_PLAN.md`'s own Quick start — or report results directly if
that's more practical.

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
