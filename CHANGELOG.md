# CHANGELOG.md — Leveling Gears

A concise, version-by-version summary of what changed and why it matters to a player or tester.
This file starts at **v0.383** — everything before that point has full detail in `PROGRESS.md`'s
Progress log and the git history, and can be reassembled into earlier changelog entries later if
that's ever useful; it isn't backfilled here now.

For the full investigation behind any fix below (root cause, evidence, validation), see
`bugs/resolved-bugs.md` by bug number. For the day-to-day build narrative, see `PROGRESS.md`.

---

## v0.384 (2026-07-15)

A second round of fixes, this time addressed one queued item at a time from live testing
(`TEST_RESULTS_Helio_0383.md`) with no version bump in between, then batched together here.

- **Added:** base armor value now factors into item scoring (a small, fixed, non-adjustable nudge —
  real stats still dominate), read via a hidden-tooltip scan since `GetItemStats` never itemizes a
  plain item's base armor. Mainly matters for very early gear, which often has no other clean
  numeric stats to compare by. (Bug #43)
- **Changed:** the minimap button's right-click no longer duplicates left-click's open/close — it's
  now press-and-hold-and-drag to reposition the button around the minimap, with the new position
  saved across reloads. This was `ROADMAP.md`'s planned 0.36 item. (Bug #44)
- **Added:** a per-category debug-log toggle (`/lgs debug window` disables just the window-position
  log channel, independent of the main `/lgs debug` switch). (Bug #45)
- **Added:** a helper-text note explaining why a caster's "Haste Rating" box isn't labeled "Spell
  Haste" — TBC never itemized them separately; the single stat was already being scored correctly
  per class. (Bug #46)
- **Fixed:** a Lua error thrown by the new per-category debug toggle the moment a window-position log
  line fired, caught via a routine debug-log pull before it reached a tester. (Bug #42)
- **Fixed:** "Core stats" overlapping "Restore Defaults" and the note above it — a regression this
  version's own Haste note caused. The layout no longer relies on a hand-guessed pixel offset for
  this (a recurring source of bugs since v0.26); it's now anchored to the button's real position.
  (Bug #41)
- Removed the `/lg`-alias test case from `TEST_PLAN.md` (confirmed permanently fine, no longer worth
  a retest slot every round).
- Bug ledger: zero open bugs remain in `bugs/known-bugs.md` as of this version.

## v0.383 (2026-07-15)

A full round of fixes from live testing (`TEST_RESULTS_Helio_v0382.md`), addressed one at a time and
retested individually before this batch was versioned together.

- **Fixed:** typing a new stat weight and clicking "Save Settings" directly (without pressing Enter
  first) discarded the edit instead of saving it. (Bug #38)
- **Fixed:** window position now saves and restores using two independent absolute screen
  coordinates instead of a single point/offset anchor — the same technique other addons on this
  client use (AceGUI's Window widget). This closes the long-standing "restores close, but not to the
  exact spot" bug. (Bug #29)
- **Fixed:** scoring an item with no clean numeric stats (e.g. a totem) now shows a clear message
  explaining why, instead of a misleading "try again" prompt or — for shift-click — no response at
  all. (Bug #39)
- **Changed:** the "Spec:" selector in the settings window is now a real Blizzard dropdown instead
  of a custom button with a hand-rolled menu, which used to leave a permanent empty gap below it.
  (Bug #40)
- **Changed:** the debug log's ring buffer capacity increased from 500 to 2000 entries, to
  comfortably hold a full test pass's worth of logging without wrapping.
- Bug ledger: zero open bugs remain in `bugs/known-bugs.md` as of this version.
