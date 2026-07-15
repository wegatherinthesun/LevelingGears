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

**Version: v0.382.** No test report has come in since the first real v0.301 pass, so this section
covers everything changed across v0.301 → v0.382 in one go — that's a lot, but almost none of it has
had any live confirmation yet. That first pass found bug #27's fix largely working (T1/T3/T7 showed
clean loads and successful gear scoring — a big improvement) but stopped at T15/T16 after hitting
three more real issues, and after reporting the profile system and the stat-weight controls as
sources of "lots of errors" / "too complicated." **Testing should resume from T1** to re-confirm
everything still works after all of this, then continue on to T16-T35, which were never reached:

1. **`Priorities.lua`'s default weights are now analytically derived from real TBC combat formulas
   (v0.308, following v0.307's real-but-still-approximate research pass).** Every spec's seeded
   weights come from verified formulas (14 Attack Power = 1 DPS, crit/haste multiplier math,
   per-class mechanical corrections like Warrior rage-generation normalization) instead of a guess or
   an invented rank-to-number scale — see `DESIGN.md`'s Layer 3 section. **T20 below is rewritten**
   with specific per-role expectations to actually test this, not just "not a flat 5."
2. **Stat weight boxes show the exact value with no scale (v0.305/v0.306).** No more +/- buttons, no
   0-10 clamp, no "0 = ignore, 10 = highest importance" framing — the box shows and accepts the
   literal number the scoring engine multiplies the stat by. **T22-T23 below test this.**
3. **Profile system removed (v0.304).** The "Profiles" section is gone from the settings window —
   no more profile picker, no "Create new profile." **T15-T18 below test the new single-weight-set
   model** instead of profile creation/switching.
4. **Bug #29 (still open): window position restores consistently but not to the exact dragged
   spot.** Root cause still unconfirmed — v0.311 added scale diagnostics (`GetScale`/
   `GetEffectiveScale`) on top of the existing point/x/y logging, in case a UI-scale mismatch between
   sessions turns out to be the cause. **T11 this round should include the full `/lgs debug dump`**
   covering both a drag and a reopen — this is the single most valuable piece of data this round,
   since nothing more can be fixed here without it.
5. **Bug #30 (solved): `/lgs score` reported as "too complicated."** Shift-click an equipped item in
   the character window to print its score to chat, no slash command needed. Built as
   **shift+left-click** (not the literally-requested shift+right-click — see bug #30 in
   `bugs/resolved-bugs.md`). **T8 below tests this as the primary workflow**; `/lgs score` still works
   as a debug-bench fallback.
6. **New chat notice on first load:** since weights no longer auto-update on a respec or talent
   change (that's `ROADMAP.md`'s 0.35, not built yet), the addon tells you this once at boot — look
   for it and confirm the wording makes sense.
7. **New roadmap items, not built yet:** minimap drag-to-reposition (renumbered from 0.31 to 0.36,
   since 0.31 is now this whole consolidated version — see `ROADMAP.md`), custom art (0.32),
   auto-updating defaults on respec (0.35), and an in-UI explanation for why primary stats aren't
   weightable (0.37). None of these are testable yet — don't look for them.
8. **Bug #36 (solved): equipped-gear evaluation could fire dozens of times per second (v0.313).**
   Found via real debug-log data (a burst of 61 identical "Gear evaluation" lines in the same second)
   that opening bags, visiting a vendor, or trading could each trigger many undebounced
   `UNIT_INVENTORY_CHANGED` events, each one running a full 17-slot re-evaluation. Fixed by routing
   the event handler and the `CharacterFrame` `OnShow` hook through the same 0.2s debounce
   (`ScheduleGearEvaluation`) already used for the weight-adjustment path. **T32 below now asks you to
   open/close bags and visit a vendor a few times with `/lgs debug` on, then dump the log** and confirm
   you don't see repeated back-to-back "Gear evaluation" lines within the same second.
9. **New: manual "Spec:" dropdown, plus two rounds of a real auto-detection fix (bug #37, v0.38 →
   v0.381).** A live report (an Enhancement Shaman scored as Elemental) led to a "Spec" settings
   section with a "Spec:" dropdown ("Auto-detect" + your class's 3 real specs) that overrides the
   auto-detected guess, plus a status line showing what's actually being used to score gear right
   now. A second report immediately after (same character, all 44 points in Enhancement, still
   detected as Restoration) proved the first fix's theory (a talent-tab tie resolving to tab order)
   wasn't the whole story, so `DetectSpec`'s entire point-reading method was replaced — it no longer
   trusts `GetTalentTabInfo`'s own point count at all, instead summing each individual talent's rank
   directly. **New T20b below tests this directly; T20 itself now has a note about using the
   dropdown if a spec still looks wrong.**
10. **New: helper text explaining why primary stats aren't weightable (roadmap item 0.37, shipped
    v0.382).** The stat-weights section has always shown only derived stats (Attack Power, Spell
    Power, etc.) — Strength/Agility/Intellect/Stamina/Spirit were never listed, with nothing in the
    UI explaining why. A new line of small helper text under the existing color-guide text now says
    so. **T13 below (scrolling/layout) should pay extra attention to this section** — the new line
    shifted the stat-group starting offset in code (a reasoned estimate, not a measured value).

Bug #27 itself (from v0.301) is not fully closed — T20 (spec-aware default seeding across multiple
classes) still hasn't actually been run. That's still this round's highest-value test, alongside T11
and the new T20b above.

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
- Expected: Reads **v0.382**.
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
- Expected: Prints the ring buffer (up to 500 entries, bumped from 50 in v0.312) to chat.
- Result:
- Notes:

**T8 — Shift+left-click an equipped item to score it (bug #30's real fix)**
- Instruction: Open the character window (paperdoll) so your equipped gear is visible, then
  shift+left-click one of your equipped items. Try several different slots/items (e.g. a weapon, a
  caster cloth item, a trinket).
- Repeat: 3x (3 different items)
- Expected: Prints a derived-stat breakdown and a final score to chat, scored against your own
  character weights (same weights that drive the gear-outline colors). A plain left-click on the same
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
  table rather than your own character weights (so the numbers may differ slightly from T8 above —
  that difference is expected, not a bug; see `DESIGN.md`).
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
  against the minimap"), **then actually reopen the window at least once** (close it and reopen via
  `/lgs`, or `/reload`, or a full relaunch) before pulling the debug dump — a dump taken right after
  the drag but before a reopen doesn't capture the comparison this bug needs.
- Repeat: 2x (one `/reload`, one full restart)
- Expected: Window reopens in the *exact* dragged position both times, not just a similar area.
  Please include `/lgs debug dump` covering both the drag (`SaveWindowPosition` line) AND the
  reopen (`ApplySavedPosition` line) — real dumps already checked (three separate reads, most recently
  at 123 total log entries) show 45 clean save/apply pairs across three different anchor points
  (`CENTER`, `TOPLEFT`, `LEFT`) with **zero drift in any of them** and scale values identical
  (`1.0000`) every time — UI-scale mismatch is ruled out as the cause, and in-session close/reopen
  round-trips all look clean. The one thing none of this data has confirmed yet is an actual
  `/reload` or full client relaunch in between the drag and the reopen (every clean cycle captured so
  far was an in-session close/reopen) — that's the one piece still missing. If a real reload/relaunch
  also round-trips clean, this bug can likely be closed outright.
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
  Defaults" button against the stat groups below it — unconfirmed since v0.26, see bug #25/#26; and
  the new 0.382 primary-stats helper-text line above "Restore Defaults," whose added height is a
  reasoned estimate, not a measured in-game value).
- Result:
- Notes:

**T14 — Close button**
- Instruction: Click the X close button.
- Repeat: 1x
- Expected: Window closes.
- Result:
- Notes:

### Single weight set per character (v0.304 — replaces the old "Profiles section")

**T15 — No profile picker exists anymore**
- Instruction: Open the settings window and look at the area between "General settings" and "Stat
  weights."
- Repeat: 1x
- Expected: No "Profiles" section, no profile picker button, no "Create new profile." The stat
  weights section starts directly below general settings.
- Result:
- Notes:

**T16 — Weights are set once per character, no naming/creation needed**
- Instruction: Adjust a few stat weights by hand.
- Repeat: 1x
- Expected: Values change and stick — there's nothing to name or create, just the one weight set for
  this character.
- Result:
- Notes:

**T17 — Restore Defaults still works**
- Instruction: Hand-adjust a couple of weights, then click "Restore Defaults."
- Repeat: 2x
- Expected: Every weight resets to the character's spec-aware default (not a flat 5 — see T20), and
  the chat confirmation names the detected spec.
- Result:
- Notes:

**T18 — Weights are per-character**
- Instruction: Log into a different character (alt), adjust a weight there, then log back to the
  first character.
- Repeat: 1x
- Expected: Each character keeps its own weights — the alt's adjustment does not affect the first
  character's values, and vice versa.
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
- Instruction: On at least 3 characters covering different roles — e.g. one clearly melee
  (Warrior/Rogue), one caster (Mage/Warlock), one healer (Priest/Druid/Paladin) — either check the
  weights on first-ever load, or click "Restore Defaults."
- Repeat: 3x (3 different characters/specs minimum — more is better if you have alts available)
- Expected: Seeded weights match that spec's real, cited stat priority (see `Priorities.lua`), not
  just "not a flat 5" — e.g. a Fury Warrior should seed Hit and Expertise as its two highest values
  with Haste near zero (a real TBC rage-mechanic quirk, not a mistake); a Restoration Shaman should
  seed MP5 *above* Healing Power (a genuinely surprising real ratio from its cited source — this is
  correct, not a bug); a Warlock should seed Hit clearly above Spell Power. If a seeded set of values
  looks backwards or nonsensical for that spec, that's worth reporting in detail (which stats, which
  spec) rather than just "weights looked wrong." **If the wrong spec is detected (e.g. this exact
  report — an Enhancement Shaman seeded with Elemental's Spell-Power-first weights), that's bug #37's
  territory** — use the new "Spec:" dropdown (T20b below) to force the correct spec rather than
  reporting it as a dead end; but please still note which class/spec/talent-point distribution
  triggered the wrong auto-detect, since that's exactly the evidence needed to confirm bug #37's
  tie-break theory.
- Result:
- Notes:

**T20b — Manual spec-override dropdown (bug #37, new in v0.38, auto-detect rewritten in v0.381)**
- Instruction: Open the new "Spec" section (between "General settings" and "Stat weights"). Note
  what the "Currently scoring as:" status line says, then open the "Spec:" dropdown and select a
  different one of your class's 3 specs.
- Repeat: 2x (pick two different specs, and once try "Auto-detect" to switch back)
- Expected: The dropdown lists exactly your class's 3 real specs plus "Auto-detect." Selecting a
  spec immediately updates the status line (ending in `[manually set]`), re-seeds every stat weight
  to that spec's real defaults, and re-colors your equipped gear's outlines to match. Selecting
  "Auto-detect" goes back to talent-point detection (status line ending in `[assumed - ...]` or no
  bracketed tag at all if a real spec was read). The new "Spec" section should not visually overlap
  "Stat weights" below it.
- Result:
- Notes:

**T21 — Core stats group contents**
- Instruction: Expand "Core stats" and read the stat names.
- Repeat: 1x
- Expected: Shows Spell Power, Healing, Attack Power, Ranged Attack Power, Health, Mana — **not**
  Strength/Agility/Stamina/Intellect/Spirit (removed in v0.25).
- Result:
- Notes:

**T22 — Direct weight entry (v0.305 — replaces the old +/- buttons, bug #32)**
- Instruction: Click into a stat's edit box, clear it, type a new value (e.g. "8.5"), then press
  Enter.
- Repeat: 3x (3 different stats)
- Expected: The box keeps showing exactly what you typed (formatted cleanly, e.g. "8.5" not
  "8.500000001"), and the gear-outline colors update shortly after (per the existing 0.2s debounce).
- Result:
- Notes:

**T22b — No more 0-10 ceiling (v0.306, bug #33)**
- Instruction: Type a value clearly outside the old 0-10 range into a stat's box — try both "25" and
  "-3" — pressing Enter after each.
- Repeat: 2x (one above 10, one below 0)
- Expected: Both values are accepted and stick exactly as typed (not clamped back to 10 or 0). The
  helper text above the stat groups should also no longer say "0 = ignore, 10 = highest importance."
- Result:
- Notes:

**T23 — Invalid entry reverts instead of sticking**
- Instruction: Click into a stat's edit box, clear it, type something non-numeric (e.g. "abc"), then
  click elsewhere in the window to move focus away.
- Repeat: 2x
- Expected: The box reverts to the last real saved value (not left showing "abc" or blank) — the
  invalid entry should never look like it was accepted.
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
- Expected: Every displayed value re-syncs and a chat confirmation appears. Nothing should visibly
  "jump" (there's nothing to reload).
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

**T32 — Outlines update on equipment change (bug #36 — debounce fix, v0.313)**
- Instruction: Unequip an item, then re-equip it (or equip a different one). Then, with `/lgs debug`
  enabled, open/close your bags a few times and visit a vendor (buy or just open the vendor window),
  then run `/lgs debug dump`.
- Repeat: 2x for the equip change; 1x for the bag/vendor + dump check
- Expected: Outlines update to reflect the new gear both times. In the dumped log, "Gear evaluation"
  lines should appear at most about once per 0.2s — not dozens of identical lines stamped the same
  second (that was bug #36, now routed through the existing debounce).
- Result:
- Notes:

**T33 — Outlines update on respec/level-up**
- Instruction: If feasible this session, respec or level up.
- Repeat: 1x each (skip whichever isn't feasible)
- Expected: Outlines re-evaluate afterward. Weights themselves do **not** auto-update to the new
  spec's defaults yet (that's `ROADMAP.md`'s 0.35, not built) — "Restore Defaults" or a hand-adjust is
  still required if the respec changes what the weights should be. Confirm the boot-time chat message
  about this still matches actual behavior.
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
- Instruction: Set a distinctive combination of weights, minimap toggle, window position, and debug
  mode. Fully exit and relaunch the client (not `/reload`).
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
3. If a past bug's fix is touched again, cross-reference its number from `bugs/known-bugs.md` (if
   still open) or `bugs/resolved-bugs.md` (if already solved/mitigated).
4. Keep test case IDs (T1, T2, …) stable once assigned — renumbering breaks cross-references in old
   test reports. Append new cases at the end of their section instead of renumbering.
5. Collect completed reports from the `wegatherinthesun@gmail.com` inbox as they arrive; there's no
   automated intake.
