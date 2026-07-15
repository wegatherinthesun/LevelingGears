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

**Version: v0.383.** See `CHANGELOG.md` for the concise summary. The v0.382 pass (`TEST_RESULTS_
Helio_v0382.md`) was the first real test run this project has had since the original partial T1-T15
pass at v0.301 — it got through T1-T22 and found 4 real bugs, all fixed and individually retested
this version:

1. **Bug #29 (closed): window position now uses two absolute screen coordinates instead of a single
   point/offset anchor** (the same technique other addons on this client use), replacing the old
   approach that always logged as correct but never actually landed exactly right. **Retest T11** —
   should now restore to the exact dragged spot across a real `/reload`/relaunch, not just "close."
2. **Bug #38 (closed): direct stat-weight entry now commits before "Save Settings" reads it back.**
   Typing a value and clicking Save directly (no Enter first) used to silently revert the box.
   **Retest T22, T22b, T23** — these were never reached last round since T22 blocked further testing.
3. **Bug #39 (closed): scoring an item with no clean numeric stats (e.g. a totem) now explains why**
   instead of a misleading "try again" message or, for shift-click, no response at all. **Retest
   T8b** specifically on a totem or similar no-stats item.
4. **Bug #40 (closed): the "Spec:" control is now a real Blizzard dropdown**, not a custom button
   with a permanent empty gap below it. **Retest T20b.**

**Testing should resume from T22b** (T1-T22 already passed last round, no need to redo those) through
T35, plus the 4 specific retests called out above. Bug #27's own T20 (spec-aware default seeding
across multiple classes/specs) was confirmed working last round — no need to repeat unless a new
class/spec combination is available to check.

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
- Expected: Reads **v0.383**.
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
- Expected: Prints the ring buffer (up to 2000 entries, bumped from 500) to chat.
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

**T10 — Minimap button opens the window**
- Instruction: Left-click the minimap button, then right-click it.
- Repeat: 2x (both buttons)
- Expected: Both open/close the window. *(Known, accepted: no separate right-click menu exists yet
  — identical behavior is correct, not a bug.)*
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
  visually overlapping.
- Repeat: 1x
- Expected: Smooth scroll, nothing clipped, no section overlaps another (including the "Restore
  Defaults" button against the stat groups below it — unconfirmed since v0.26, see bug #25/#26; the
  0.382 primary-stats helper-text line above it; and the "Spec" section's real dropdown, whose sizing
  changed again in the v0.383 rewrite — all reasoned estimates, not measured in-game values).
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

**T20b — Manual spec-override dropdown (bug #37, v0.38 → v0.381; now a real dropdown, bug #40 in v0.383)**
- Instruction: Open the "Spec" section (between "General settings" and "Stat weights"). Note what the
  "Currently scoring as:" status line says, then click the "Spec:" dropdown and select a different one
  of your class's 3 specs.
- Repeat: 2x (pick two different specs, and once try "Auto-detect" to switch back)
- Expected: This is now a real Blizzard dropdown widget (previously a custom button) — confirm it
  looks and opens like a standard WoW dropdown, with no permanent empty gap below it whether open or
  closed. The dropdown lists exactly your class's 3 real specs plus "Auto-detect." Selecting a spec
  immediately updates the status line (ending in `[manually set]`), re-seeds every stat weight to that
  spec's real defaults, and re-colors your equipped gear's outlines to match. Selecting "Auto-detect"
  goes back to talent-point detection (status line ending in `[assumed - ...]` or no bracketed tag at
  all if a real spec was read).
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
