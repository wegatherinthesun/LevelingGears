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

**On the `data_implementation` branch, unreleased (no version bump yet), on top of v0.385's
baseline.** Two batches worth knowing about:

**Settings window resize, Popout box, bug #48 (Auto-detect fix), bug #49 (weight-ceiling
validation)** — all v0.385, all previously covered here; see `CHANGELOG.md`/`bugs/resolved-bugs.md`
for detail if retesting them specifically.

**New this round — the Suggestions engine and recommendation window:**
1. **Shift+right-click an equipped item now opens the Suggestions window instead of the old score
   popout** — the popout's code is still present but no longer wired to this gesture. **T8
   rewritten** to match.
2. **New: `Suggestions.lua` (the upgrade-recommendation engine) and `SuggestionsUI.lua` (its
   window).** Shows up to 6 real upgrade candidates for the clicked slot — never a downgrade from
   what's equipped, mixing guaranteed category diversity (crafted/BOE/nearby quest) with pure score,
   filtered by level and armor type. **New cases T36-T44** cover this — all brand new, none
   previously tested by anyone but the author. Confirmed working live after fixing several real bugs
   along the way (`bugs/resolved-bugs.md` #50-#55) — T36-T38 are the most important ones to confirm
   independently.
3. **No real in-game trigger exists yet besides shift+right-click and debug commands** — `ROADMAP.md`'s
   0.5 tooltip hook (the originally-planned entry point) isn't built. This is expected, not a bug.

**Testing should cover T8 and T36-T44 first** (all new or changed, none independently confirmed yet),
then resume the regular T1-T35 sweep as time allows.

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
- Expected: Reads **v0.385**.
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

**T6 — Debug mode toggle**
- Instruction: Type `/lgs debug`.
- Repeat: 2x (once to enable, once to disable)
- Expected: A chat confirmation each time, matching the new state.
- Result:
- Notes:

**T7 — Debug dump**
- Instruction: Type `/lgs debug dump`.
- Repeat: 1x
- Expected: Prints the ring buffer (up to 2000 entries, bumped from 500) to chat.
- Result:
- Notes:

**T8 — Shift+right-click an equipped item opens the Suggestions window (moved off the score popout — see the new "Suggestions engine & recommendation window" section below for the window's own content)**
- Instruction: Open the character window (paperdoll) so your equipped gear is visible, then
  shift+right-click one of your equipped items. Try several different slots/items (e.g. a weapon, a
  caster cloth item, a trinket).
- Repeat: 3x (3 different items)
- Expected: Opens the Suggestions window (`SuggestionsUI.lua`) for that slot — see T36+ below for
  what it should contain. This replaced the old score-breakdown popout, which no longer opens from
  this gesture (its code is still present in `UI.lua` but unreferenced). A plain shift+left-click on
  the same item still ONLY inserts the item link into an open chat edit box (Blizzard's native
  behavior). A plain right-click (no Shift) behaves as it always does natively (fires the item's
  on-use effect if it has one) — this is an accepted trade-off of using shift+right-click, not a bug.
- Result:
- Notes:

**T8b — `/lgs score` still works as a fallback (bug #39 — closed, retest on a totem)**
- Instruction: Type `/lgs score ` (with the trailing space, don't press Enter yet), then shift-click
  an equipped or bagged item — this inserts the item link right into that same line — then press
  Enter. **Try this on a totem (or similar item with no clean numeric stats) specifically**, since
  that's what exposed bug #39 last round.
- Repeat: 1x on a normal item, 1x on a totem/no-stats item
- Expected: Normal item prints a derived-stat breakdown and score, scored against the raw
  `Priorities.lua` table rather than your own character weights (numbers may differ slightly from T8
  above — expected, not a bug; see `DESIGN.md`). A totem/no-stats item now prints "This item has no
  stats this addon can score..." instead of the old misleading "may not be cached yet, try again."
- Result:
- Notes:

**T9 — Minimap button visibility**
- Instruction: Toggle the "Show minimap button" checkbox off, then on.
- Repeat: 2x (both directions)
- Expected: The minimap button hides/shows immediately and the state survives reopening the window.
- Result:
- Notes:

**T10 — Minimap button: left-click opens the window, right-click drags to reposition (bug #44, `ROADMAP.md` 0.36)**
- Instruction: Left-click the minimap button. Separately, hold right-click down on the button and
  move the mouse around the minimap, then release.
- Repeat: 2x (left-click twice to open/close; drag twice to two different spots)
- Expected: Left-click still opens/closes the settings window. A plain right-click (no drag) now does
  nothing — this is deliberate, not a bug (see bug #44). Holding right-click and moving the mouse
  drags the button around the minimap's edge in real time; releasing it locks in the new position,
  which should still be there after a `/reload`.
- Result:
- Notes:

### Window behavior

**T11 — Window position persists (bug #29 — closed in v0.383, retest to confirm)**
- Instruction: Drag the window to a spot you can describe precisely (e.g. "top-left corner flush
  against the minimap"), **then actually reopen the window at least once** (close it and reopen via
  `/lgs`, or `/reload`, or a full relaunch).
- Repeat: 2x (one `/reload`, one full restart)
- Expected: Window reopens in the *exact* dragged position both times. v0.383 replaced the save/
  restore method with two independent absolute screen coordinates (the same technique other addons on
  this client use) instead of a single point/offset anchor — note that a saved position from before
  v0.383 won't carry over (the window will open at its default centered position once, since the old
  saved format is no longer read); drag it once to establish a position under the new system before
  judging this test.
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
  visually overlapping. Specifically check "Restore Defaults" against "Core stats" below it (bug #41 —
  a real overlap here was reported and fixed this version, previously unconfirmed since v0.26, see
  bug #25/#26) and the excess blank space previously reported at the bottom of the scroll area
  (reported again, attempted and rolled back this version — still open, expect it to still be there).
- Repeat: 1x
- Expected: Nothing clipped, no section overlaps another. Some blank space below the last stat group
  is still expected for now (open item, not yet fixed).
- Result:
- Notes:

**T14 — Close button**
- Instruction: Click the X close button.
- Repeat: 1x
- Expected: Window closes.
- Result:
- Notes:

**T14b — Window resize by dragging a bottom corner**
- Instruction: Hover the bottom-left or bottom-right corner of the settings window (look for a grip
  texture), then click and drag to resize. Try the top two corners as well.
- Repeat: 2x (one bottom corner each)
- Expected: The window resizes smoothly by dragging either bottom corner. The top two corners do NOT
  resize (deliberate — don't report this as a bug). The new size persists across closing/reopening
  the window and across a `/reload`.
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

**T20b — Manual spec-override dropdown (bug #37, v0.38 → v0.381; real dropdown since bug #40 in v0.383; Auto-detect fixed as bug #48 in v0.385)**
- Instruction: Open the "Spec" section (between "General settings" and "Stat weights"). Note what the
  "Currently scoring as:" status line says, then click the "Spec:" dropdown and select a different one
  of your class's 3 specs. **Then switch it back to "Auto-detect"** — this specific step is bug #48's
  fix (previously a silent no-op).
- Repeat: 2x (pick two different specs, and each time switch back to "Auto-detect" afterward)
- Expected: This is a real Blizzard dropdown widget — confirm it looks and opens like a standard WoW
  dropdown, with no permanent empty gap below it whether open or closed. The dropdown lists exactly
  your class's 3 real specs plus "Auto-detect." Selecting a spec immediately updates the status line
  (ending in `[manually set]`), re-seeds every stat weight to that spec's real defaults, and re-colors
  your equipped gear's outlines to match. Selecting "Auto-detect" goes back to talent-point detection
  (status line ending in `[assumed - ...]` or no bracketed tag at all if a real spec was read) —
  **this must actually take effect**, not silently keep scoring as the previously-selected spec.
- Result:
- Notes:

**T21 — Core stats group contents**
- Instruction: Expand "Core stats" and read the stat names.
- Repeat: 1x
- Expected: Shows Spell Power, Healing, Attack Power, Ranged Attack Power, Health, Mana — **not**
  Strength/Agility/Stamina/Intellect/Spirit (removed in v0.25).
- Result:
- Notes:

**T22 — Direct weight entry (v0.305 — replaces the old +/- buttons, bug #32; commit-on-save fixed as bug #38 in v0.383)**
- Instruction: Click into a stat's edit box, clear it, type a new value (e.g. "8.5"), then press
  Enter. Then, separately, type a different value into another stat's box and click **"Save
  Settings" directly, without pressing Enter or clicking away first** — this exact sequence is what
  exposed bug #38 last round.
- Repeat: 3x (3 different stats via Enter), 2x (via clicking Save Settings directly)
- Expected: Both commit methods work — the box keeps showing exactly what you typed (formatted
  cleanly, e.g. "8.5" not "8.500000001"), and the gear-outline colors update shortly after. Clicking
  "Save Settings" directly after typing (no Enter first) should no longer revert the box to its old
  value.
- Result:
- Notes:

**T22b — Real 0-20 ceiling, rejected values explained with a popup (T23/T24, bug #49 in v0.385)**
- Instruction: Type a value clearly outside the 0-20 range into a stat's box — try both "25" and "-3"
  — pressing Enter after each. Then type a value with more than one decimal place, e.g. "7.23".
- Repeat: 3x ("25", "-3", "7.23")
- Expected: "25" and "-3" are each **rejected** — a popup explains why (out of range) before the box
  reverts to its last real saved value; neither should silently stick or silently revert with no
  explanation. "7.23" IS accepted but rounds to the nearest tenth ("7.2"), not the full typed
  precision. The helper text above the stat groups should mention the 0-20 range.
- Result:
- Notes:

**T23 — Invalid (non-numeric) entry is explained and reverts, not silently accepted**
- Instruction: Click into a stat's edit box, clear it, type something non-numeric (e.g. "abc"), then
  click elsewhere in the window to move focus away.
- Repeat: 2x
- Expected: A popup explains the value isn't a number, then the box reverts to the last real saved
  value (not left showing "abc" or blank) — the invalid entry should never look like it was accepted,
  and the rejection should never be silent.
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

### Suggestions engine & recommendation window (new — `data_implementation` branch, unreleased)

**T36 — Suggestions window shows real upgrade candidates**
- Instruction: Shift+right-click an equipped item (see T8). Try at least 3 different slots, including
  at least one armor slot and one non-armor slot (ring, neck, trinket, or cloak).
- Repeat: 3x (3 different slots)
- Expected: A window opens titled "Suggestions -- <SlotName>", showing an "Equipped score" line and a
  continent name, and up to 6 rows below it — each with an icon, an item name colored by its native
  quality (grey/white/green/blue/purple etc.), an upgrade percentage (or "New" if the slot was empty),
  a source line (e.g. "Drops from a creature", "Quest reward", "Crafted", "Vendor", "Bind on Equip"),
  and a smaller category line underneath. If fewer than 6 real upgrades exist, fewer rows show instead
  of padding with anything fake.
- Result:
- Notes:

**T37 — No-downgrades rule**
- Instruction: Check a slot where your equipped item is already strong (a rare/epic piece, or one
  you've hand-tuned weights around).
- Repeat: 1x
- Expected: No suggested row should ever be an actual downgrade from what's equipped — if your gear
  is already very strong for that slot, the window may show fewer than 6 rows (or "No qualifying
  upgrades found") rather than padding the list with worse items.
- Result:
- Notes:

**T38 — Hovering a row shows the real item tooltip plus our own lines**
- Instruction: With the Suggestions window open, hover your mouse over one of the rows (not click).
- Repeat: 2x (2 different rows)
- Expected: Blizzard's native item tooltip appears (full stats, exactly like hovering the item
  anywhere else), with our own source and category lines appended below it.
- Result:
- Notes:

**T39 — Refresh button**
- Instruction: With the Suggestions window open, click the "Refresh" button.
- Repeat: 1x
- Expected: The window re-queries and repopulates for the same slot — if anything changed (gear,
  weights, location) since it was opened, the list reflects that; otherwise it looks the same.
- Result:
- Notes:

**T40 — Settings button**
- Instruction: With the Suggestions window open, click the "Settings" button.
- Repeat: 1x
- Expected: The main Leveling Gears settings window opens, and the Suggestions window stays open
  (doesn't close itself).
- Result:
- Notes:

**T41 — Empty / still-loading messaging is honest about which one it is**
- Instruction: Check a slot immediately after logging in or reloading (before the background
  pre-fetch has had time to run), and separately check a slot where you're confident nothing better
  exists.
- Repeat: 1x each
- Expected: A slot that's still resolving item data says something like "Still loading item data (N
  item(s) not cached yet) -- checking again shortly..." and the row area auto-refreshes on its own a
  few times without needing Refresh clicked manually. A slot that's been fully checked and genuinely
  has no upgrades says "No qualifying upgrades found for this slot right now." These two messages
  should never look identical (bug #54).
- Result:
- Notes:

**T42 — Window stays put (no drifting or disappearing)**
- Instruction: Open the Suggestions window for several different slots in a row (shift+right-click
  different items one after another).
- Repeat: 3x+
- Expected: The window reappears in the same dead-center screen position every time — it should never
  need to be found somewhere else on screen, and it's not draggable (bug #53 — this is deliberate,
  not a missing feature).
- Result:
- Notes:

**T43 — Debug commands still work**
- Instruction: Type `/lgs suggest handsslot` (or any real slot name), then separately
  `/lgs suggestwindow handsslot`.
- Repeat: 1x each
- Expected: `/lgs suggest` prints a text summary to chat (equipped score, continent, up to 6
  candidates with scores/sources). `/lgs suggestwindow` opens the same window T36 describes.
- Result:
- Notes:

**T44 — Suggestions still show up promptly after a reload**
- Instruction: `/reload`, wait about 30 seconds without touching anything, then shift+right-click an
  equipped item you checked before the reload.
- Repeat: 1x
- Expected: Candidates appear reasonably quickly — the background pre-fetch queue (tied to login,
  continent switches, new equips, spec/level changes) should have already been warming the item cache
  in the background, and previously-found upgrades are remembered per-character across sessions, so
  this shouldn't feel like starting from zero every time.
- Result:
- Notes:

---

## Known, accepted behavior (not a bug — don't report these)

- A plain right-click on the minimap button (no drag) does nothing — this is deliberate now that
  right-click-and-drag repositions the button instead (bug #44, `ROADMAP.md` 0.36).
- A plain right-click (no Shift) on an equipped item slot still fires Blizzard's native
  `UseInventoryItem` (e.g. a trinket's on-use effect), even though Shift+right-click now opens the
  Suggestions window (T8) — accepted so Shift+left-click can stay purely native ("insert item link
  in chat"), per `ROADMAP.md`'s note under "Settings window resize."
- The Suggestions window (T36-T44) is not draggable — deliberate, see T42.
- The Suggestions window has no real in-game trigger yet other than shift+right-click and the debug
  commands — `ROADMAP.md`'s 0.5 tooltip hook (the originally-planned entry point) isn't built yet.
- Some blank space below the last stat group in the settings window is still expected (an attempted
  fix for this was rolled back this version — still an open item, not a new regression).
- Roadmap features not yet built (tooltip hook, sorting/filters, alt professions, AH scanner, data
  curation) are absent by design — see `ROADMAP.md` for what's intentionally not built yet at this
  stage.

---

## Summary (fill in after finishing)

- Total test cases: 44 — Passed: ___ Failed: ___ Partial: ___ Skipped: ___
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
