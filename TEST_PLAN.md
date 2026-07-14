# TEST_PLAN.md — Leveling Gears

Living test plan. **Updated every commit** — not a historical record (that's `PROGRESS.md`'s job).
If you're testing, read `TESTERS.md` once first, then come here for what to actually test today.

## How this file is kept current (for whoever is committing)

Before calling a commit done:
1. Update **"Recent changes to focus on"** below to describe what this commit changed and why it
   matters for testing — replace the previous entry, don't just append (git history already
   preserves the old ones; `PROGRESS.md` is the permanent log).
2. If a feature was added, changed, or removed, add/update/remove its row in the **regression
   checklist** so the checklist never drifts from what actually exists.
3. If a past bug's fix is touched again, cross-reference its number from `bugs/known-bugs.md`.

---

## Recent changes to focus on (as of this commit)

**Version: v0.3.** Three things landed together, none of them changing intended behavior on paper,
which is exactly why they need real verification rather than being assumed safe:

1. **The v0.261 nine-file reorganization** (`Core.lua` split into `Debug.lua`/`Settings.lua`/
   `Weights.lua`/`GearEvaluation.lua`/`UI.lua`/`Core.lua`, alongside the existing `Conversions.lua`/
   `Priorities.lua`/`Scoring.lua`) changed *how* every feature is wired together (cross-file calls
   through the shared `LG` namespace instead of same-file locals) without intending to change *what*
   any feature does. A load-order or wiring mistake here would most likely show up as either a Lua
   error on load, or a feature that silently no-ops. **Test everything, not just what seems related.**
2. **A documentation/version reorganization** (`CLAUDE.md` split into `PROGRESS.md`/`ROADMAP.md`/
   `CONVENTIONS.md`/`DATA_PIPELINE.md`, version bumped 0.261→0.3, roadmap milestones 0.3-0.9
   renumbered to 0.4-0.91). Zero code risk, but worth confirming the addon's own displayed version
   string (window title bar) actually reads **v0.3**.
3. **A static conflict audit** was run before this commit (cross-file reference check, `luac -p` +
   `luacheck` on all 9 files, cross-doc link validation) — all clean. That audit is static analysis
   only; it cannot substitute for actually running the client. Nothing below should be skipped on
   the assumption "the audit already covered it."

---

## Phase 1 — Full regression checklist

Every row needs a pass before pushing. Check across **more than one class/spec** where noted — the
scoring engine's defaults are authored per class/spec/mode (`Priorities.lua`), so single-character
testing can't validate that coverage.

### Load & version
- [ ] Addon loads with zero Lua errors on a full client restart (not just `/reload`) — confirms the
  9-file load order and the `## SavedVariables` TOC directive both still work.
- [ ] Window title bar reads **v0.3**.
- [ ] `/lgs debug dump` right after login shows no unexpected errors in the ring buffer.

### Slash commands & minimap
- [ ] `/levelinggears` opens/closes the settings window.
- [ ] `/lgs` opens/closes the same window.
- [ ] `/lg` does **not** work (deliberately removed — not a bug if it's silent).
- [ ] `/lgs debug` toggles debug mode with a chat confirmation each way.
- [ ] `/lgs debug dump` prints the ring buffer (up to 50 entries) to chat.
- [ ] `/lgs score <item link>` (shift-click an item after typing the command) prints a derived-stat
  breakdown and a final score. Try an item with a mix of stat types (e.g. a weapon with a proc, a
  cloth item with spell power) and sanity-check the printed numbers look plausible.
- [ ] Minimap button visible by default; "Show minimap button" checkbox hides/shows it and persists.
- [ ] Minimap button opens/closes the window on click. *(Known, accepted: left- and right-click do
  the same thing — no separate right-click context menu exists yet. Not a bug.)*

### Window behavior
- [ ] Window is draggable; position persists across `/reload` and a full restart.
- [ ] Escape key closes the window.
- [ ] Scroll area scrolls smoothly; nothing is clipped.
- [ ] No two settings sections visually overlap at the default window size.
- [ ] Close button (X) closes the window.

### General settings section
- [ ] "Show minimap button" checkbox reflects the true saved state every time the window is
  reopened (not just at first load).

### Profiles section
- [ ] Profile dropdown lists "Default" plus any created profiles, and "Create new profile."
- [ ] Creating a new profile seeds it with spec-aware default weights (not a flat 5) and switches
  to it immediately.
- [ ] Switching profiles updates every visible weight label to that profile's saved values.
- [ ] Profiles are per-character — an alt does not see another character's profiles.

### Stat weights section
- [ ] All three groups (Core stats, Other stats, Resistances) expand/collapse independently via
  their `+`/`-` header buttons.
- [ ] "Core stats" shows Spell Power, Healing, Attack Power, Ranged Attack Power, Health, Mana —
  **not** Strength/Agility/Stamina/Intellect/Spirit (removed in v0.25; see `DESIGN.md`).
- [ ] Clicking a stat row's `+`/`-` moves the value by exactly 0.05.
- [ ] Shift-clicking `+`/`-` moves the value by exactly 1.
- [ ] Values clamp correctly at 0 (minimum) and 10 (maximum) — can't go negative or above 10.
- [ ] Displayed values never show floating-point artifacts (e.g. "9.550000001") and never an
  unnecessary trailing zero (e.g. "9.50" should read "9.5"; a whole number shows with no decimal).
- [ ] **Restore Defaults** button resets every stat in the active profile back to the detected
  spec/mode default and prints a confirmation naming the detected class/spec.
- [ ] Restore Defaults button does not visually overlap the stat groups below it (unconfirmed since
  v0.26 — see `bugs/known-bugs.md` #25/#26 — this is the first real check of that layout).
- [ ] Test Restore Defaults + spec-aware seeding on **at least 3 different classes/specs** (e.g. a
  melee spec, a caster spec, and a healer spec) and confirm the seeded defaults look sane for each
  (e.g. a melee spec seeds high Attack Power, not high Spell Power).
- [ ] A character under level 10 (no talent points spent) still gets sensible seeded defaults (the
  "assumed spec" fallback per class in `Priorities.LOW_LEVEL_DEFAULT_SPEC`).

### Save Settings footer
- [ ] Clicking "Save Settings" re-syncs every displayed value and prints a confirmation naming the
  active profile. Nothing should visibly "jump" when clicked (there's nothing to reload).

### Equipped-gear outline coloring
- [ ] Opening the character panel (`C`) shows a colored outline on each equipped item's slot button.
- [ ] Colors span the documented red→violet scale, relative to this character's own gear average.
- [ ] Outlines update immediately (within ~0.2s) after changing a stat weight.
- [ ] Outlines update after equipping/unequipping an item.
- [ ] Outlines update after a respec or level-up.
- [ ] Exactly 17 slots are evaluated — confirm Shirt, Ammo, and Tabard are **not** outlined (removed
  deliberately), and that the ranged/relic slot is outlined for classes that use it (Paladin Libram,
  Druid Idol, Shaman Totem, or a ranged weapon).

### Persistence
- [ ] All of the above (weights, profiles, minimap toggle, window position, debug mode) survive a
  full client exit and relaunch, not just `/reload` — this is the real persistence test; `/reload`
  alone has produced false confidence before (see `bugs/known-bugs.md` #13).

---

## Known, accepted behavior (not a bug — don't report these)

- Minimap button's left-click and right-click do the same thing (open/close). No distinct
  right-click context menu exists yet.
- Roadmap features not yet built (tooltip hook, recommendation window, sorting/filters, alt
  professions, data pipeline) are absent by design — see `ROADMAP.md` for what's intentionally not
  built yet at this stage.
