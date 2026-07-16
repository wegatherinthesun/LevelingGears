# queue.md — working queue

One thing at a time: pick the top item, change just that, test just that, no version bump until told
to do one. Items under "Still open" are not to be built until explicitly told to start them — this
file is just the running list.

## Done — shipped as v0.383

1. ~~**T22 — Direct weight entry doesn't accept typed values.**~~ Fixed as bug #38: "Save Settings"
   clicked directly (no Enter first) was overwriting the uncommitted edit. Confirmed working.
2. ~~**T11 / bug #29 — Window position still doesn't restore to the exact dragged spot.**~~ Fixed by
   switching to the two-absolute-coordinate method other addons use (AceGUI). Confirmed working.
3. ~~**T8b — `/lgs score` doesn't work on a totem.**~~ Fixed as bug #39: both scoring paths now
   explain that an item has no scoreable stats instead of a misleading message or silence. Confirmed
   working.
4. ~~**Spec dropdown had a big reserved gap and wasn't a real dropdown**~~ (reported live, not from
   the original test file). Fixed as bug #40, in two passes: first the gap/overlay/auto-close
   behavior, then a full replacement with Blizzard's native dropdown widget. Confirmed working.

## Done this cycle (shipped as v0.384)

1. ~~**T5 — remove this test case from `TEST_PLAN.md`.**~~ Done: removed from the checklist (T4 is
   now directly followed by T6 — per `TEST_PLAN.md`'s own rule, IDs aren't renumbered).
2. ~~**T7 — stop logging window position saves/restores in the debug ring buffer.**~~ Fixed as bug
   #45: added a per-category debug toggle (`Debug.IsCategoryEnabled`/`SetCategoryEnabled`/
   `ToggleCategory`), wired the `"window"` category onto `UI.lua`'s two `SaveWindowPosition`/
   `ApplySavedPosition` log calls, exposed as **`/lgs debug window`**. Confirmed working live.
3. ~~**T8 — factor armor value into scoring at some level.**~~ Fixed as bug #43: added a
   hidden-tooltip scan (`Scoring.ScanItemArmorValue`) for the "Armor" line (the documented fallback
   from bug #23, since `GetItemStats` never itemizes plain armor), folded into `ComputeScore` as a
   small, fixed, non-user-adjustable nudge (`ARMOR_VALUE_WEIGHT = 0.01`), shown in breakdowns as
   `BASEARMOR`. Real stats still dominate everywhere except low-level gear, where it's now enough to
   stop near-identical items tying at a dead 0 (and, as a side effect, un-hides outlines for items
   that used to score exactly 0). Confirmed no regressions live.
4. ~~**T10 — remove the minimap button's right-click entirely.**~~ Fixed as bug #44 (also
   `ROADMAP.md`'s planned 0.36, now Built): right-click no longer toggles the window (left-click
   only). Repurposed as press-and-hold-and-drag: holding right-click and moving the mouse repositions
   the button around the minimap's edge, saved (`settings.minimapAngle`) across reloads. Confirmed no
   regressions live.
5. ~~**T16 / T20 — Haste vs. Spell Haste explained; Mage `Priorities.lua` audited.**~~ Fixed as bug
   #46 (clarification, not a scoring fix): TBC never itemized a separate Spell Haste stat — a Frost
   Mage's "Haste Rating" box was always being scored correctly as spell haste
   (`Conversions.lua`'s offense-type lookup); added a helper note explaining this. Also audited every
   class/spec table in `Priorities.lua` for the broader "Mage defaults look weird" report — found no
   anomalies (`EXP` already `0` for every pure-caster spec). **Still open:** if a live Frost Mage
   character still shows nonzero Expertise, it's more likely a stale saved weight than a table bug —
   ask the tester whether "Restore Defaults" clears it before investigating further.
6. ~~**Bug #41 — "Core stats" overlapped "Restore Defaults" and the note above it.**~~ A regression
   bug #46's own note caused, reported live and fixed: the stat groups' starting offset had been
   hand-guessed wrong three times now (bug #25's `-134`, 0.37's `-160`, this cycle's `-195`) —
   anchored to `restoreDefaultsButton:GetBottom()` directly instead of guessing a fourth number.
7. ~~**Bug #42 — `Debug.lua` crashed the moment a window-position log line fired.**~~ A regression
   item 2 (bug #45) caused, caught via a routine debug-log pull before it reached a tester:
   `debugCategories` wasn't reliably initialized; made the category functions defensive.

## Still open (carried forward — not to be started without explicit instruction)

- **T13 — trim the excess blank space at the bottom of the settings window.** Attempted once already:
  swapped `scrollChild`'s hardcoded 760px-floor height formula for a real sum of all 3 section
  heights + gaps + a small bottom margin. **Rolled back on direct instruction** — the old, fixed-760
  formula looked better in practice. Back to `math.max(760, generalSection:GetHeight() +
  weightSection:GetHeight() + 40)`. Needs a different approach next time, not the same fix again.
- **T20b — "Auto-detect" stops working once a spec has been manually selected.** Picking a real spec
  from the dropdown works, but switching back to "Auto-detect" afterward doesn't re-engage
  talent-point detection — needs investigation.
- **T23 / T24 — put a real ceiling on stat weights (0-20, round to nearest tenth) with an
  explanatory validation dialog, and reject negative numbers.** Currently accepts any typed number
  with no real bound, including negatives, with no warning (T24: "It does allow me to input a
  negative number"). Expected per the tester: a positive number 0-20, rounding to the nearest tenth,
  and a dialog explaining that when a bad value is rejected — not a silent revert.
- **T24 — remove the old +/- clamp-at-ends test case from `TEST_PLAN.md`.** The +/- buttons no
  longer exist (replaced by direct entry in v0.305); this test case is stale and should fold into
  whatever new test case covers the ceiling/validation item above once that ships.
- **T31 — outline update on weight change.** Tester deferred: "we will come back to this queue to
  specifically test this."
- **T32 — outline update on equip/bag/vendor + debounce dump check (bug #36).** Tester deferred:
  "queue to test this later."
- T14 (close button), T27 (low-level fallback spec), T33 (respec/level-up outline update), T34 (slot
  coverage) — left blank in the last test pass, not confirmed either way. Retest next round.

## Roadmap backlog (explicitly deferred — not touched until you say so)

- Enable sending error reports back to the developer (T3).
- Debug-toggle message should also explain how to disable it once enabled (T3 notes).
- Limit `/lgs debug dump`'s chat output to the last 50 lines, independent of how large the storage
  buffer is (T7).
- Improve `/lgs score` / shift-click score output to be clearer for a player, less raw (T8).
- Remove the `/lgs score` slash command entirely; move this into the item tooltip instead (T8b).
- Explain, in the UI, what values are actually accepted in a weight box (T17).
- Outline coloring should eventually be relative to how much better an available upgrade actually is
  for that slot, not just the character's own current average (T20) — queued for **after** the
  database is built.
- Make the settings window ~40% bigger (T20b).

## Notes (not actionable, just context)

- v0.382 pass: T1/T2 confirmed clean load and correct version string; T4-T7, T9-T10, T12-T17, T19,
  T20, T20b passed as expected; T1-T22 covered, stopped at T22 (bug #38 blocked further testing until
  fixed).
- v0.383 pass (`TEST_RESULTS_Helio_0383.md`): resumed from T22b through T35. Confirmed passing with no
  queue needed: T1, T2, T3, T4, T6, T8b (aside from the note above), T9, T11, T12, T15, T17, T18, T19,
  T20b (dropdown mechanics itself), T21, T22, T22b, T25, T26, T28, T29, T30, T35. T18 and T21 had been
  carried over from the prior cycle as "still pending" and are now confirmed working.
- All items above were addressed one at a time with no version bump in between, per standing
  instruction, then batched into v0.384 together with a full doc/bug-ledger pass.
