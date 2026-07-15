# CONVENTIONS.md — Leveling Gears

Standing rules: coding conventions, the WoW/Lua sandbox constraints, process rules for how to work
on this project, the versioning ladder, and technical reference notes verified against this
specific client. Read this before writing or editing any code. See `PROGRESS.md` for history and
`ROADMAP.md` for what's being built next.

---

## Project owner

- Has some coding experience (Python, basic Lua, HTML/JS), not professional.
- Builds and tests in small increments. STOP after each version step and wait for beta-testing
  results before continuing.

## Hard process rules for Claude Code

1. **One step at a time.** Build only the current version step (see `ROADMAP.md`). Then stop,
   describe how to beta-test it, and wait for feedback before continuing.
2. **Update `PROGRESS.md` and the bug log** after each step: version completed, files changed,
   decisions, open bugs, and validation results.
3. **No invented APIs.** Use only real Classic-client Lua APIs. If unsure an API exists on the
   TBC Anniversary client, say so and propose a safe alternative.
4. **No placeholder secrets, no API keys, no external services in the addon.** The in-game addon is
   fully offline. (The offline *build pipeline* may download public databases — that's separate.)
5. **Data is baked offline, not faked.** Until the real baked database exists, any feature needing
   item/quest/loot data runs on a tiny hand-made sample table OR shows "Coming soon." Never fake a
   full database inline.
6. Keep code in small, clearly named files. Comment generously — the project owner is not a
   professional developer and reads the code directly.
7. **A completed test report from the project owner is authoritative and actionable, not just
   informational** (this is different from a report from any other tester, which may need judgment
   about whether/how to act on it). On receiving one: treat confirmed-working items as real
   confirmation (reflect in `bugs/known-bugs.md`/`PROGRESS.md` where relevant); investigate and
   fix/mitigate real bugs immediately, not just file them for later — if a root cause can't be
   confirmed by static review, add targeted debug logging and ask for specific evidence in the
   retest rather than guessing at a fix; file genuine new feature ideas in `ROADMAP.md` at the next
   free version slot (see the versioning ladder) but do **not** build them until every
   currently-shipped feature is confirmed working, unless directed otherwise; update `TEST_PLAN.md`
   so the next pass knows what to re-confirm and where to resume.

## Mandatory maintenance rules (apply to every change)
- After every code change, verify the addon still parses and update the TOC version if the shipped addon version changed.
- Before considering any UI change complete, verify that every settings section remains visibly separated on the page and does not overlap another section; check this during each edit and include the result in the progress notes.
- Treat WoW-style presentation as a default requirement, not a follow-up question: every change should use standard WoW UI conventions, standard Lua style, and a visually polished appearance that feels native to the game and consistent with the rest of the default Blizzard UI.
- When editing UI, favor Blizzard-style spacing, hierarchy, labels, textures, and button behavior over custom or improvised visuals; the addon should look like it belongs in WoW rather than like a generic app window.
- Keep `PROGRESS.md` current after every change with what was built, why it changed, the current version, and the next step.
- Keep the Lua code annotated as part of the work; every major helper, UI section, and saved-data path should have comments explaining purpose and WoW-specific behavior.
- Keep the bug ledger current after every fix or regression with a summary, root cause, attempted fixes, resolution status, validation, and follow-up.
- Every bug must be recorded as either Open, Solved, or Mitigated, with discovery time and resolution time when applicable.
- The bug file must be a working list, not a dated archive; use a stable filename such as `bugs/known-bugs.md` and update it continuously as the project evolves.
- Every change should include a short note in the bug ledger if it affects startup, addon loading, slash commands, UI initialization, SavedVariables, or version metadata.
- Follow WoW addon conventions at every step: use Classic-compatible APIs, keep the settings UI on a single window, store data in SavedVariables, register slash commands and events safely, avoid fragile UI patterns that can break initialization, and keep the visual language aligned with the existing Blizzard UI.
- Never leave a change unrecorded just because it is small; log it in `PROGRESS.md` and the bug ledger before moving on.
- Keep `TEST_PLAN.md` current **every commit**: update "Recent changes to focus on" to describe what changed and why it matters for testing, and add/update/remove regression-checklist rows so the checklist never drifts from what actually exists. See `TEST_PLAN.md`'s own "For whoever maintains this project" section at the bottom for the exact process. Keep tester-facing content (the Quick start, the checklist itself) simple — testers should not need to read `TESTERS.md` or anything else to complete and submit it.

## Branding

The addon always says "gears," never "gear." Window title: **Leveling Gears**. Version string in
smaller text directly under the title. Icon (designed later): a small gear meshing with a big gear.
Buttons use the branding: **"Select Gears"**, **"View Gears"**.

## Versioning ladder (follow exactly)

- **0.1** — first runnable skeleton. 0.11, 0.12… = small additions while the addon is "just a
  window and buttons."
- **0.2, 0.3…** — milestones (settings, scoring engine, data schema, etc.). Sub-decimals = their
  sub-features.
- **Thousandths-decimal rule (added after 0.24):** once a milestone's two-decimal sub-features (0.21,
  0.22, 0.23, 0.24…) are exhausted by ordinary bugfixes and small corrections rather than new
  sub-features, extend to a third decimal digit instead of rolling the second digit over — e.g. after
  0.24, further fixes are 0.241, 0.242, 0.243… This keeps a long tail of small maintenance fixes from
  visually implying a milestone has been reached when it hasn't. Only introduce a new two-decimal
  sub-feature (0.25, 0.26…) for an actual new sub-feature of the current milestone, not for fixes to
  existing ones.
- **0.3 redefinition (2026-07-14):** 0.3 was originally reserved for the data-schema/database
  milestone. The v0.25/0.26 scoring engine plus the v0.261 nine-file reorganization turned out to be
  substantial enough — and risky enough to a 9-file load-order change touching every feature — that
  0.3 was reclaimed as **"stable, reorganized baseline entering Testing Phase 1"**: every existing
  feature gets tested end to end (see `TEST_PLAN.md`) before anything new is built on top. This
  bumped every milestone from the data-schema step onward by one tick so numbers stay unique — see
  `ROADMAP.md` for the renumbered list (data-schema is now 0.4, not 0.3). **0.3x is now this
  stabilization/testing milestone's sub-decimal space** (bugfixes found during Testing Phase 1 use
  the thousandths rule as usual: 0.301, 0.302…; a genuine new sub-feature of this milestone would be
  0.31 — but 0.31 was also the old data-pipeline download step, now renumbered to 0.41, so check
  `ROADMAP.md` before assuming a two-decimal number is free). **0.31-0.36 are now taken** (Testing
  Phase 1 follow-up features found in the v0.301 test report — see `ROADMAP.md`'s "Testing Phase 1
  follow-ups" section; 0.33 shipped as bug #30's fix in v0.303, 0.34 was dropped as moot when the
  v0.304 fork removed profiles entirely, 0.35 — auto-updating default weights on respec/talent change
  — was filed fresh in that same fork, and 0.31 was reclaimed on 2026-07-14 as the consolidated
  release version for the whole `single-profile` fork's work — see below — bumping the old "minimap
  drag-to-reposition" item to 0.36); the next free two-decimal number in this milestone is **0.37**.
- **0.31 consolidation (2026-07-14):** the `single-profile` fork's iterative bugfix-style versions
  (v0.304 through v0.308 — single-profile removal, direct-entry stat editing, then two passes at
  fixing `Priorities.lua`'s default weights) were squashed into one consolidated two-decimal release,
  **0.31**, once merged back into `main`. The individual v0.304-v0.308 numbers remain in
  `PROGRESS.md`'s Progress log and `bugs/known-bugs.md` #31-#35 as the accurate historical record of
  how 0.31 was built — they are not retroactively renamed — but the shipped, tested version going
  forward is 0.31. **Patches to 0.31 follow the existing thousandths rule**: the next one is 0.311,
  not 0.301 (0.301 already exists — it's the earlier, unrelated bug #27 crash fix from the 0.3
  baseline milestone, well before this fork existed).
- **Version A** — first feature-complete **alpha** (no decimal). A.1, A.2 = alpha fixes.
- **Version B** — **beta**.
- **1.0** — first shipped release. **1.01** = bug patches. **1.1** = one new feature.
  After ten features (1.10), roll to **2.0**.

## Settings architecture note

- General settings should stay global to the addon and be scoped to the addon itself, not to any one character. Examples: window position, minimap button visibility, default addon behavior toggles, and future default sort/filter choices.
- Character-specific settings should be stored per character and not shared across alts. This includes stat weights and any other character-specific override values.
- **v0.304 (single-profile fork):** exactly one weight set per character — no named/created/switched
  profiles. A player can hand-adjust any weight or restore the whole set to the character's detected
  spec/mode default; there is nothing else to manage. The earlier multi-profile design (profiles
  keyed by id, an "active profile" pointer, create/switch/name UI) was a real source of bugs
  (`bugs/known-bugs.md` #28) for flexibility this addon's design never actually needed.
- The implementation uses a simple structure: `LevelingGearsDB.general` for universal settings and `LevelingGearsDB.characters[characterKey].weights` for the character's own stat weights.

---

## World of Warcraft Addon Development Rules (These are non-negotiable)
- General Philosophy: This project targets World of Warcraft addons, not generic Lua. Never introduce patterns common in desktop Lua or game engines that are unsupported by WoW. Always prioritize:

- Blizzard coding style
- Blizzard API conventions
- WoW addon best practices
- Readability over cleverness
- Minimal dependencies
- Long-term maintainability

## Lua Version Rules

- Assume the addon is running under the Lua version shipped with the target WoW client.
- Always verify that every language feature exists in that version.
- Never use newer Lua features unless confirmed supported.
- Examples to check:

  - bitwise operators
  - goto
  - utf8 library
  - table.move
  - table.pack
  - table.unpack
  - string.pack
  - __pairs
  - __ipairs
- If uncertain, verify against the correct WoW API version.

## WoW Environment Rules: Remember WoW is sandboxed.
- Everything must work inside WoW's addon sandbox.
- Never use:

  - io.*
  - os.execute
  - package.*
  - require()
  - loadfile()
  - dofile()
  - file access
  - sockets
  - external libraries

## Blizzard UI Style: Whenever possible, build UI the way Blizzard does.

### Preferred Widgets & Templates
- Prefer:
  - CreateFrame
  - UIPanelButtonTemplate
  - UIPanelScrollFrameTemplate
  - GameFontHighlight
  - GameFontNormal
  - GameFontDisable
  - GameTooltip
  - BackdropTemplateMixin
- Templates over custom implementations.
- Avoid reinventing Blizzard widgets.

### Naming Style
- Prefer names Blizzard would likely use.
- Functions should describe exactly one responsibility.

- Examples:
  - CreateOptionsPanel()
  - UpdateEquipmentDisplay()
  - RefreshProfileList()
  - OnClick()
  - OnEvent()
  - Initialize()

- Avoid names like:
  - MegaRefreshEverything()
  - DoMagic()
  - Temp()
  - Thing()
  - Handler2()

### UI Layout
Whenever possible, follow Blizzard's own layout conventions.

- Use consistent spacing throughout the interface.
- Prefer common Blizzard spacing values such as 4, 8, 12, 16, and 24 pixels.
- Keep alignment and padding consistent across related controls.
- Avoid arbitrary positioning values unless there is a specific reason.

A player should feel like the interface belongs inside World of Warcraft.

### Blizzard UI Templates
Always check whether Blizzard already provides a suitable template before creating a custom control.

Prefer built-in templates such as:
- UIPanelButtonTemplate
- OptionsCheckButtonTemplate
- UIDropDownMenu
- InputBoxTemplate
- UIPanelCloseButton

Only build custom controls when Blizzard does not already provide an appropriate solution.

### Minimap Buttons
Follow Blizzard's standard interaction patterns whenever possible.

The default behavior should be:
- Left-click: Open or close the addon's main window.
- Right-click: Open an optional context menu or secondary options.

Tooltips should use Blizzard formatting and clearly explain available interactions.

### Slash Commands
Keep slash commands simple and easy to remember.

Examples:
- /addon
- /addon help
- /addon debug

Avoid creating excessive or redundant commands. Every command should serve a clear purpose.

### Blizzard Look and Feel
Before introducing a new feature or UI element, ask: would Blizzard likely implement this feature in this way? If the answer is no, reconsider the design.

Whenever possible:
- Follow Blizzard interaction patterns.
- Match Blizzard naming conventions.
- Use Blizzard visual styles.
- Prefer Blizzard widgets and templates over custom implementations.

The addon should feel like a natural extension of the default UI rather than a separate application.

## Code Quality & Maintainability

### Local Variables
Everything should be local unless intentionally global. Every global should be intentional.

Check for:
- unused locals
- unused globals
- shadowed variables
- duplicate declarations
- globals created accidentally

### Function Ordering
Before finishing: verify every local function used before definition. Never rely on globals accidentally.

### Dependency Graph
Whenever functions are added, removed, renamed, or moved, review the dependency graph before considering the task complete.

Verify that:
- Every function reference is still valid.
- Local functions are not called before they are defined unless they have been explicitly forward declared.
- There are no accidental circular dependencies.
- Changes to one function have not broken other functions that depend on it.
- Every function still has a clear and intentional responsibility.

Never assume that moving code is harmless simply because it compiles.

### Variable Lifetime
Verify that every variable exists within the correct scope.

Check for:
- Variables that should be local but were accidentally made global.
- Variables captured by closures unintentionally.
- Variables referenced inside event callbacks after they have gone out of scope.
- Variables shared between frame scripts that should instead be local.

Avoid accidentally creating or relying on global variables.

### Comments
Comments should explain why the code exists, not simply repeat what the code already says.

Avoid comments like:
```
-- increment i
i = i + 1
```

Instead, explain the reasoning behind the code:
```
-- Keep the UI synchronized after profile changes.
```

Good comments explain design decisions, assumptions, edge cases, or Blizzard-specific behavior.

### Error Handling
Do not allow errors to fail silently.

When appropriate:
- Use pcall() to safely isolate non-critical operations.
- Use assert() for conditions that should never fail.
- Return early when invalid data is detected.
- Log unexpected failures whenever possible.

Never suppress errors without a clear reason.

## Runtime Behavior & Performance

### Event Handling
- Use event-driven design.
- Avoid polling.
- Register only events actually needed.
- Always unregister events that are temporary.
- Avoid duplicate event registrations.

### SavedVariables
- Never store transient state.

- Store only:
  - settings
  - profiles
  - positions
  - preferences
- Avoid storing cached data unless performance requires it.
- Initialize SavedVariables safely.
  - AddonDB = AddonDB or {}
  - AddonDB.settings = AddonDB.settings or {}
- Never assume tables exist.

### Frame Creation
- Frames should be created once. Never recreate frames repeatedly.
- Prefer:
  - CreateFrame(...)
  - Store references and reuse them
  - Hide instead of destroying.

### Performance
World of Warcraft addons run continuously during gameplay. Avoid unnecessary work.

In particular:
- Do not repeatedly call CreateFrame() for objects that can be reused.
- Avoid repeated calls to expensive APIs such as GetItemStats() when the results can be cached.
- Avoid allocating new tables every update when existing tables can be reused.
- Avoid unnecessary string concatenation inside frequently executed code.

Cache data whenever doing so improves performance without sacrificing correctness.

### Garbage Collection
Reduce unnecessary memory allocations.

Whenever practical:
- Reuse tables instead of constantly creating new ones.
- Reuse frame objects rather than recreating them.
- Avoid creating new closures every refresh when one can be reused.
- Minimize temporary objects inside frequently executed functions.

Efficient memory usage improves performance and reduces garbage collection pauses.

## API & Expansion Safety

### WoW API Validation
Every Blizzard API call should be verified rather than assumed.

Confirm that:
- The API function exists for the target expansion.
- The function name is spelled correctly.
- The arguments are correct and in the proper order.
- The expected return values are being handled correctly.
- The function has not been renamed, deprecated, or replaced in the target client.

Never invent Blizzard API names or guess how an API works.

### Expansion Compatibility
Always know which version of World of Warcraft the addon targets.

Examples include:
- Classic Era
- Hardcore
- Season of Discovery
- Cataclysm Classic
- Retail

Many Blizzard APIs differ between expansions. Never mix APIs from different game versions without explicitly supporting both.

## Static Analysis Checklist

Before considering any task complete, perform a full validation pass over the affected files.

Verify that:
- Lua syntax is valid.
- The addon loads without errors.
- Every if, for, while, repeat, function, and table has the correct closing end or delimiter.
- There are no duplicate local variables.
- There are no accidental global variables.
- Every referenced function exists.
- Every referenced variable exists.
- No local function is called before it has been defined unless it has been explicitly forward declared.
- There are no invalid forward references.
- There is no unreachable or dead code.
- There are no unused variables or unused functions unless intentionally retained.
- There are no unintentionally shadowed local variables.
- Events are not registered more than once unless intentionally required.
- Frame names remain unique.
- Slash commands remain unique.
- SavedVariables are initialized safely before use.
- Every Blizzard API call exists and is valid for the target expansion.
- API arguments and return values are handled correctly.
- The code is compatible with the target Lua version.
- The code is compatible with the target World of Warcraft expansion.
- Blizzard templates are used whenever appropriate.
- Naming follows Blizzard conventions.
- UI layout follows Blizzard spacing and style conventions.
- Comments remain accurate and no obsolete comments are left behind.
- Completed work does not leave forgotten TODO markers.
- Tooltips accurately describe current behavior.
- Minimap functionality still behaves correctly.
- Slash commands continue to function correctly.
- Character stat weights still save, load, and restore-to-defaults correctly.
- Settings continue to save and load correctly.
- The change has not introduced unnecessary allocations or performance regressions.
- No unsupported desktop Lua features or libraries have been introduced, including io, os, package, require(), loadfile(), or any other APIs unavailable within the World of Warcraft addon sandbox.

After every non-trivial edit, stop treating the task as complete and perform a full-project validation pass. Re-read the entire file (or affected files) as if reviewing someone else's code. Check for broken references, ordering issues, stale comments, inconsistent naming, API misuse, style regressions, and logic affected by the change. Do not assume that code untouched by the edit is still correct simply because it was not modified.

---

## Technical notes

- Client: TBC Classic Anniversary. Lua 5.1 subset; Blizzard strips most of `io`/`os`. No file or
  network access from the addon itself.
- Item stats: read at runtime. Numeric stats come from **`GetItemStats(itemLink)`** (returns a
  table of ITEM_MOD_* values) — NOT from GetItemInfo, which gives name/quality/ilvl/equipLoc but
  no stats. Caching still gates both: `GetItemInfo` is ASYNC — uncached items return nil on first
  call; use a request queue keyed on the `GET_ITEM_INFO_RECEIVED` event and fill scores in as items
  arrive. VERIFY that GetItemStats surfaces "Equip:" values (+healing, +spell damage, mp5) as
  ITEM_MOD_* entries; if any are missing there, fall back to a hidden-tooltip scan for those lines
  and record the finding here.
- Armor (added 0.248, bug #23): `GetItemStats` does NOT expose a plain item's base armor value —
  base armor is intrinsic to material/item level/slot, not a modifier stat. `ITEM_MOD_ARMOR_SHORT`
  (added to `itemStatAliases` as `ARMOR`) can only ever pick up BONUS armor modifiers (e.g. a shield's
  "of the Bear"-style suffix). Unverified on this client; if it never contributes to any item's score
  in play, fall back to a hidden-tooltip scan of the "Armor" line, same policy as above.
- Class/usability filtering: our baked DB carries classMask, so class checks are a table lookup for
  DB items. `GetItemInfo` gives equipLoc/subtype/minLevel. A hidden-tooltip scan of the "Classes:"
  line is the FALLBACK only, for items not in our DB or missing a mask.
- **Scoring engine (added 0.25):** `Conversions.lua`/`Priorities.lua`/`Scoring.lua` implement a
  three-layer scorer — see `DESIGN.md` for the full rationale and every judgment call made. In
  short: primaries are never weighted directly (they're converted to derived stats first, which is
  what prevents double-counting); rating-to-percent conversions are read live via
  `GetCombatRating`/`GetCombatRatingBonus` against the NAMED `CR_*` globals (never hardcoded
  numeric indices, since those differ across client/expansion builds); the one hardcoded table is
  Attack Power per point of Strength/Agility per class/form, verified for TBC (Shaman is 1 AP/Str,
  not 2). `Armor Penetration Rating` was not itemized until patch 3.0.2 (after TBC's own content
  patches), so `CR_ARMOR_PENETRATION` may not exist or may never be populated on this client —
  guarded the same way as every other rating, contributing 0 if absent.
- Slash: `/levelinggears` + `/lgs` primary; `/lg` was deliberately removed (see `bugs/known-bugs.md`
  #5) — do not reintroduce it as a top-level command.
- SavedVariables: settings account-wide with per-character overrides; per-character selected
  upgrades, weights, and alt profession data.
- **How WoW addon persistence actually works (no "save" step exists):** an addon never explicitly
  writes its SavedVariables to disk. Every value change should just mutate the global table declared
  in `## SavedVariables:` immediately (this addon already does that everywhere — every setter writes
  straight into `LevelingGearsDB`). The *client itself* serializes that table to
  `WTF/Account/<ACCOUNT>/SavedVariables/LevelingGears.lua` at the normal save points: `/reload`,
  camping to character select, "Log Out," or "Exit Game." Force-quitting the process (task-killing
  it, a crash, unplugging power) skips all of those and loses anything since the last save point —
  this is the single most common cause of "my settings didn't stick" reports, and is not a bug an
  addon can work around. Because of this, addons conventionally do NOT ship a manual "Save"/"Apply"
  button — there's nothing for it to do that isn't already happening. The addon's "Save Settings"
  footer button does NOT call `ReloadUI()` (an earlier version did, briefly — see
  `bugs/known-bugs.md` #18 — but there was nothing left to persist, so it just produced a jarring
  no-op reload); it only re-syncs the display and prints a confirmation, purely for reassurance.
- Also note: a `.toc` metadata change (e.g. adding a `## SavedVariables` line, changing dependencies)
  is only read when the client fully starts up — `/reload` does not re-parse the `.toc`. Test any
  `.toc` change with a full exit-and-relaunch, not just `/reload`.
- Libraries: Ace3 (AceDB, AceConfig, AceGUI) + LibDBIcon acceptable if they cut boilerplate;
  plain frames also fine for early versions (and are what's actually in use today — see
  `PROGRESS.md`'s decision log). Choose per step and record it in `PROGRESS.md`.
- Pipeline: Python (installed) + optional SQLite (ships with macOS). Never a DB server.
- Provide exact in-game test steps each stop ("/reload, type /levelinggears, expect X").
