# TEST_PLAN.md — Leveling Gears

## Quick start

1. Save this file somewhere you'll find it again.
2. Open it in any plain text editor (Notepad, TextEdit, etc. — nothing special needed).
3. Fill in **Tester info** just below.
4. Go through the checklist one test at a time: do what it says, then write your result and any
   notes right under it. Do this for every test, even the ones that just work — a blank line looks
   the same as "forgot to test this."
5. Fill in **Summary** at the very end.
6. Rename the file to `TEST_RESULTS_<yourname>_v<version>.md` (e.g. `TEST_RESULTS_pat_v0301.md`).
7. Email the renamed file as an attachment to **wegatherinthesun@gmail.com**, subject line
   `Leveling Gears test report - v<version> - <yourname>`.

That's really it. Everything past this point is the actual checklist, plus optional extra context —
you don't need to read any of it first, just start at Tester info below.

Two optional one-time settings in-game make your results more useful if anything goes wrong (skip
these and it still mostly works, just harder to diagnose):
- Type `/console scriptErrors 1` once, so any error pops up on screen instead of hiding silently.
- Type `/lgs debug` once, so the addon keeps its own error log you can copy from if needed.

---

## Tester info

- Name:
- Date:
- Addon version under test:
- Character(s) used (name, class, spec, level):

---

## Recent changes to focus on (as of this commit)

**Version: v0.303.** No test report has come in since the first real v0.301 pass, so this
section covers everything changed across v0.301 → v0.303 in one go. That first pass found bug #27's
fix largely working (T1/T3/T7 showed clean loads and successful gear scoring — a big improvement)
but stopped at T15/T16 after hitting three more real issues. v0.302 fixed/mitigated those three;
v0.303 then replaced v0.302's bug #30 mitigation with the actual requested fix. **Testing
should resume from T1** to re-confirm everything still works after all of this, then continue on to
T16-T35, which were never reached last time:

1. **Bug #28 (solved): profile picker button read as a "restore defaults" action.** Added a
   "Profile:" label to the left of the button — re-check T15 with this in mind.
2. **Bug #29 (open, mitigated): window position restores consistently but not to the exact dragged
   spot.** No confirmed root cause yet — added debug logging (`/lgs debug` level 1) to both save and
   restore, plus a defensive pixel-rounding fix. **T11 this round should include the
   `/lgs debug dump` output** covering both a drag and a reopen, so there's real data to compare
   instead of a visual impression.
3. **Bug #30 (solved): `/lgs score` reported as "too complicated."** The previous round's
   usage-message mitigation was rejected outright in favor of the real fix: shift-click
   an equipped item in the character window to print its score to chat, no slash command needed.
   Built as **shift+left-click** (not the literally-requested shift+right-click — see bug #30 in
   `bugs/known-bugs.md` for the verified Blizzard-click-behavior reasoning). **T8 below now tests
   this as the primary workflow**; `/lgs score` still works as a debug-bench fallback.
4. **New roadmap items, not built yet:** minimap drag-to-reposition + custom art, and a real
   profile-naming dialog were filed in `ROADMAP.md`'s "Testing Phase 1 follow-ups" (0.31, 0.32, 0.34)
   from feedback in the same report. None of these are testable yet — don't look for them.

Bug #27 itself (from v0.301) is not fully closed — T20 (spec-aware default seeding across multiple
classes) still hasn't actually been run. That's still this round's highest-value test.

---

## Phase 1 — Full regression checklist

Every case needs a result before submitting. Where a case says to check across multiple classes/
specs, that's because the scoring engine's defaults are authored per class/spec/mode
(`Priorities.lua`) — single-character testing can't validate that coverage.

Repeat counts are deliberately modest — enough to catch an intermittent issue without turning
testing into a grind. If you have time to do more on any case, more is always welcome.

### Load & version

**T1 — Addon loads cleanly**
- Instruction: Fully exit and relaunch the client (not `/reload`), then log into a test character.
- Repeat: 2x (once via full restart, once via `/reload` afterward)
- Expected: No Lua errors on either load. Confirms the 9-file load order and the
  `## SavedVariables` TOC directive both still work.
- Result:
- Notes:

**T2 — Version string is correct**
- Instruction: Open the settings window and read the version line under the title.
- Repeat: 1x
- Expected: Reads **v0.303**.
- Result:
- Notes:

**T3 — Debug log is clean on login**
- Instruction: `/lgs debug` then `/lgs debug dump` shortly after logging in, before touching
  anything else.
- Repeat: 1x
- Expected: No unexpected errors in the ring buffer.
- Result:
- Notes:

### Slash commands & minimap

**T4 — Primary slash commands toggle the window**
- Instruction: Type `/levelinggears`, then `/lgs`.
- Repeat: 2x each (open then close, for both commands)
- Expected: Each command opens the window if closed, closes it if open.
- Result:
- Notes:

**T5 — Removed alias stays removed**
- Instruction: Type `/lg`.
- Repeat: 1x
- Expected: Nothing happens (deliberately removed — silence is correct, not a bug).
- Result:
- Notes:

**T6 — Debug mode toggle**
- Instruction: Type `/lgs debug`.
- Repeat: 2x (once to enable, once to disable)
- Expected: A chat confirmation each time, matching the new state.
- Result:
- Notes:

**T7 — Debug dump**
- Instruction: Type `/lgs debug dump`.
- Repeat: 1x
- Expected: Prints the ring buffer (up to 50 entries) to chat.
- Result:
- Notes:

**T8 — Shift+left-click an equipped item to score it (bug #30's real fix)**
- Instruction: Open the character window (paperdoll) so your equipped gear is visible, then
  shift+left-click one of your equipped items. Try several different slots/items (e.g. a weapon, a
  caster cloth item, a trinket).
- Repeat: 3x (3 different items)
- Expected: Prints a derived-stat breakdown and a final score to chat, scored against your own
  profile weights (same weights that drive the gear-outline colors). A plain left-click on the same
  item still picks it up as normal (don't confirm the drag, just check the cursor picks it up), and a
  plain shift-click (no click type held down beyond Shift) still inserts the item link into an open
  chat edit box as it always has — neither of those should be affected by this change.
- Result:
- Notes:

**T8b — `/lgs score` still works as a fallback**
- Instruction: Type `/lgs score ` (with the trailing space, don't press Enter yet), then shift-click
  an equipped or bagged item — this inserts the item link right into that same line — then press
  Enter.
- Repeat: 1x
- Expected: Prints a derived-stat breakdown and a final score, scored against the raw `Priorities.lua`
  table rather than your own profile weights (so the numbers may differ slightly from T8 above — that
  difference is expected, not a bug; see `DESIGN.md`).
- Result:
- Notes:

**T9 — Minimap button visibility**
- Instruction: Toggle the "Show minimap button" checkbox off, then on.
- Repeat: 2x (both directions)
- Expected: The minimap button hides/shows immediately and the state survives reopening the window.
- Result:
- Notes:

**T10 — Minimap button opens the window**
- Instruction: Left-click the minimap button, then right-click it.
- Repeat: 2x (both buttons)
- Expected: Both open/close the window. *(Known, accepted: no separate right-click menu exists yet
  — identical behavior is correct, not a bug.)*
- Result:
- Notes:

### Window behavior

**T11 — Window position persists (bug #29 — reported imprecise last round)**
- Instruction: Drag the window to a spot you can describe precisely (e.g. "top-left corner flush
  against the minimap"), then `/reload`. Repeat once more but fully exit and relaunch the client
  instead of `/reload`.
- Repeat: 2x (one `/reload`, one full restart)
- Expected: Window reopens in the *exact* dragged position both times, not just a similar area.
  Please include `/lgs debug dump` covering both the drag and the reopen — new logging this round
  prints the exact saved/restored coordinates, which is the hard evidence needed to actually
  pin down last round's "close but not exact" report.
- Result:
- Notes:

**T12 — Escape closes the window**
- Instruction: Open the window, press Escape.
- Repeat: 2x
- Expected: Window closes both times.
- Result:
- Notes:

**T13 — Scrolling and layout**
- Instruction: Scroll the settings area top to bottom. Look for clipped content or any two sections
  visually overlapping.
- Repeat: 1x
- Expected: Smooth scroll, nothing clipped, no section overlaps another (including the "Restore
  Defaults" button against the stat groups below it — unconfirmed since v0.26, see bug #25/#26).
- Result:
- Notes:

**T14 — Close button**
- Instruction: Click the X close button.
- Repeat: 1x
- Expected: Window closes.
- Result:
- Notes:

### Profiles section

**T15 — Profile dropdown contents (bug #28 — fixed this round)**
- Instruction: Look at the profile section, then open the profile dropdown.
- Repeat: 1x
- Expected: A "Profile:" label now sits to the left of the button (new this round, so it no longer
  reads like a "restore defaults" action). Opening it lists "Default," any profiles you've created,
  and "Create new profile."
- Result:
- Notes:

**T16 — Creating a profile**
- Instruction: Click "Create new profile" twice in a row (creating two).
- Repeat: 2x
- Expected: Each new profile seeds with spec-aware default weights (not a flat 5 — see T20) and
  switches to it immediately; names increment sensibly.
- Result:
- Notes:

**T17 — Switching profiles**
- Instruction: Switch between two existing profiles a couple of times.
- Repeat: 2x
- Expected: Every visible weight label updates to match the newly-selected profile each time.
- Result:
- Notes:

**T18 — Profiles are per-character**
- Instruction: Log into a different character (alt) and open the settings window.
- Repeat: 1x
- Expected: The alt does not see the first character's profiles.
- Result:
- Notes:

### Stat weights section

**T19 — Group expand/collapse**
- Instruction: Click the `+`/`-` on Core stats, Other stats, and Resistances.
- Repeat: 1x each (3 total)
- Expected: Each group expands/collapses independently.
- Result:
- Notes:

**T20 — Spec-aware default seeding (bug #27 — highest priority this round)**
- Instruction: Create a fresh profile (or use Restore Defaults) on at least 3 characters covering
  different roles — e.g. one clearly melee (Warrior/Rogue), one caster (Mage/Warlock), one healer
  (Priest/Druid/Paladin).
- Repeat: 3x (3 different characters/specs minimum — more is better if you have alts available)
- Expected: Seeded weights look role-appropriate (e.g. the melee character seeds high Attack Power,
  the caster seeds high Spell Power, not a flat 5 across every stat on any of them).
- Result:
- Notes:

**T21 — Core stats group contents**
- Instruction: Expand "Core stats" and read the stat names.
- Repeat: 1x
- Expected: Shows Spell Power, Healing, Attack Power, Ranged Attack Power, Health, Mana — **not**
  Strength/Agility/Stamina/Intellect/Spirit (removed in v0.25).
- Result:
- Notes:

**T22 — Fine `+`/`-` stepping**
- Instruction: Click a stat's `+` button, then its `-` button.
- Repeat: 3x each direction
- Expected: Each click moves the value by exactly 0.05, every time.
- Result:
- Notes:

**T23 — Shift-click coarse stepping**
- Instruction: Shift-click a stat's `+` button, then its `-` button.
- Repeat: 3x each direction
- Expected: Each click moves the value by exactly 1, every time.
- Result:
- Notes:

**T24 — Clamping at the ends of the range**
- Instruction: Reduce a stat to 0 and keep clicking `-`; raise a stat to 10 and keep clicking `+`.
- Repeat: 1x each end
- Expected: Value stops at 0 (never negative) and at 10 (never above), respectively.
- Result:
- Notes:

**T25 — Display formatting**
- Instruction: Land on a few different fractional values (e.g. 9.5, 9.55, a whole number) and read
  the displayed text.
- Repeat: 3x (3 different values)
- Expected: No floating-point artifacts (e.g. never "9.550000001"), no unnecessary trailing zero
  (e.g. "9.50" should read "9.5"), whole numbers show no decimal at all.
- Result:
- Notes:

**T26 — Restore Defaults**
- Instruction: Hand-adjust a few weights, then click "Restore Defaults."
- Repeat: 3x
- Expected: Every stat resets to the detected spec/mode default every time, with a chat confirmation
  naming the detected class/spec.
- Result:
- Notes:

**T27 — Low-level fallback spec**
- Instruction: If you have a character under level 10 (no talent points spent), check its seeded
  defaults.
- Repeat: 1x (skip if no low-level character is available)
- Expected: Still gets a sensible assumed default per class, not an error or a flat 5.
- Result:
- Notes:

### Save Settings footer

**T28 — Save Settings button**
- Instruction: Click "Save Settings."
- Repeat: 2x
- Expected: Every displayed value re-syncs and a chat confirmation names the active profile. Nothing
  should visibly "jump" (there's nothing to reload).
- Result:
- Notes:

### Equipped-gear outline coloring

**T29 — Outlines appear**
- Instruction: Open the character panel (`C`).
- Repeat: 2x (close and reopen once)
- Expected: A colored outline appears on each equipped item's slot button both times.
- Result:
- Notes:

**T30 — Color scale**
- Instruction: Compare outline colors across your equipped items.
- Repeat: 1x
- Expected: Colors span red→violet, relative to this character's own gear average (not an absolute
  or dungeon-standard scale).
- Result:
- Notes:

**T31 — Outlines update on weight change**
- Instruction: Change 3 different stat weights (one at a time) while the character panel is open.
- Repeat: 3x
- Expected: Outline colors update within about 0.2s of each change.
- Result:
- Notes:

**T32 — Outlines update on equipment change**
- Instruction: Unequip an item, then re-equip it (or equip a different one).
- Repeat: 2x
- Expected: Outlines update to reflect the new gear both times.
- Result:
- Notes:

**T33 — Outlines update on respec/level-up**
- Instruction: If feasible this session, respec or level up.
- Repeat: 1x each (skip whichever isn't feasible)
- Expected: Outlines re-evaluate afterward (defaults may also change if spec detection changes).
- Result:
- Notes:

**T34 — Correct slot coverage**
- Instruction: Check which slots are outlined.
- Repeat: 1x
- Expected: Exactly 17 slots evaluated. Shirt, Ammo, and Tabard are **not** outlined (removed
  deliberately). The ranged/relic slot is outlined for classes that use it (Paladin Libram, Druid
  Idol, Shaman Totem, or an actual ranged weapon).
- Result:
- Notes:

### Persistence

**T35 — Full persistence across a real restart**
- Instruction: Set a distinctive combination of weights, profile, minimap toggle, window position,
  and debug mode. Fully exit and relaunch the client (not `/reload`).
- Repeat: 1x
- Expected: Every one of those survives. This is the real persistence test — `/reload` alone has
  produced false confidence before (see bug #13).
- Result:
- Notes:

---

## Known, accepted behavior (not a bug — don't report these)

- Minimap button's left-click and right-click do the same thing (open/close). No distinct
  right-click context menu exists yet.
- Roadmap features not yet built (tooltip hook, recommendation window, sorting/filters, alt
  professions, data pipeline) are absent by design — see `ROADMAP.md` for what's intentionally not
  built yet at this stage.

---

## Summary (fill in after finishing)

- Total test cases: 35 — Passed: ___ Failed: ___ Partial: ___ Skipped: ___
- Anything that failed, in plain language, and how bad it seemed:
- Overall impression / anything not covered by a specific test case above:

Done? Rename the file and email it per the Quick start at the top. Thank you!

---

## For whoever maintains this project (not testers — nothing below applies to you)

This file is a **reusable template**: the same checklist format every round, with "Recent changes
to focus on" and individual test cases updated as the addon changes.

Before calling a commit done:
1. Update **"Recent changes to focus on"** above to describe what this commit changed and why it
   matters for testing — replace the previous entry, don't just append (git history already
   preserves the old ones; `PROGRESS.md` is the permanent log).
2. If a feature was added, changed, or removed, add/update/remove its test case so the checklist
   never drifts from what actually exists. Keep the same per-case format (Instruction/Repeat/
   Expected/Result/Notes) so the template stays consistent release to release.
3. If a past bug's fix is touched again, cross-reference its number from `bugs/known-bugs.md`.
4. Keep test case IDs (T1, T2, …) stable once assigned — renumbering breaks cross-references in old
   test reports. Append new cases at the end of their section instead of renumbering.
5. Collect completed reports from the `wegatherinthesun@gmail.com` inbox as they arrive; there's no
   automated intake.
