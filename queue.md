# queue.md — working queue from TEST_RESULTS_Helio_v0382.md

Pulled from the T1-T22 results (testing stopped at T22). One thing at a time: pick the top item,
change just that, test just that, no version bump until told to do one.

## Done this cycle (shipped as v0.383)

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

## Still pending (carry into the next test round)

4. **T18 — Alt's weights showed stale/wrong values until "Restore Defaults" was clicked.** Not yet
   investigated — per the original note, don't change anything until this is narrowed down further
   with more testing in different ways.

5. **T21 — Primary-stat explanation text: confirm it's actually showing.** The v0.382 helper text
   exists in code but was reported as missing — still needs a check for whether it's rendering,
   visible, or was just not noticed. Not yet investigated.

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

- T1/T2: confirmed clean load and correct version string (0.382).
- T4-T7, T9-T10, T12-T17, T19, T20, T20b: passed as expected.
