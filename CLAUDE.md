# CLAUDE.md — Leveling Gears

This file is the living project spec and memory. Claude Code: read this fully before doing anything.
Keep it updated — after every completed step, record what was built, decisions made, and known bugs.
Never build past the current step without the user explicitly approving the previous one.

## Mandatory maintenance rules (apply to every change)
- After every code change, verify the addon still parses and update the TOC version if the shipped addon version changed.
- Before considering any UI change complete, verify that every settings section remains visibly separated on the page and does not overlap another section; check this during each edit and include the result in the progress notes.
- Treat WoW-style presentation as a default requirement, not a follow-up question: every change should use standard WoW UI conventions, standard Lua style, and a visually polished appearance that feels native to the game and consistent with the user’s existing UI.
- When editing UI, favor Blizzard-style spacing, hierarchy, labels, textures, and button behavior over custom or improvised visuals; the addon should look like it belongs in WoW rather than like a generic app window.
- Keep this file current after every change with what was built, why it changed, the current version, and the next step.
- Keep the Lua code annotated as part of the work; every major helper, UI section, and saved-data path should have comments explaining purpose and WoW-specific behavior.
- Keep the bug ledger current after every fix or regression with a summary, root cause, attempted fixes, resolution status, validation, and follow-up.
- Every bug must be recorded as either Open, Solved, or Mitigated, with discovery time and resolution time when applicable.
- The bug file must be a working list, not a dated archive; use a stable filename such as known-bugs.md and update it continuously as the project evolves.
- Every change should include a short note in the bug ledger if it affects startup, addon loading, slash commands, UI initialization, SavedVariables, or version metadata.
- Follow WoW addon conventions at every step: use Classic-compatible APIs, keep the settings UI on a single window, store data in SavedVariables, register slash commands and events safely, avoid fragile UI patterns that can break initialization, and keep the visual language aligned with the existing Blizzard UI.
- Never leave a change unrecorded just because it is small; log it in this file and the bug ledger before moving on.

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

A user should feel like the interface belongs inside World of Warcraft.

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
- Profile management still works correctly.
- Settings continue to save and load correctly.
- The change has not introduced unnecessary allocations or performance regressions.
- No unsupported desktop Lua features or libraries have been introduced, including io, os, package, require(), loadfile(), or any other APIs unavailable within the World of Warcraft addon sandbox.

After every non-trivial edit, stop treating the task as complete and perform a full-project validation pass. Re-read the entire file (or affected files) as if reviewing someone else's code. Check for broken references, ordering issues, stale comments, inconsistent naming, API misuse, style regressions, and logic affected by the change. Do not assume that code untouched by the edit is still correct simply because it was not modified.

---

## Progress log
- 0.1 completed: created the addon folder and initial files for Leveling Gears, including Core.lua, LevelingGears.toc, and this CLAUDE.md spec file. Built the first runnable skeleton: a centered settings window titled "Leveling Gears" with a version label, close button, and slash-command entry points for /levelinggears, /lgs, and /lg.
- 0.11 completed: added a minimap button that opens and closes the same settings window used by the slash commands. Added a tooltip for the button and verified the Lua file still parses cleanly.
- 0.12 completed: polished the window with drag-and-drop positioning, saved placement, Escape-to-close behavior, and a vertically scrolling content area so the settings page can grow over time.
- 0.2 completed: added a visible, scrollable stat-weight list with per-stat up/down controls, 0–10 values, and per-character saving.
- 0.21 completed: added a profile-aware settings layout with addon-wide settings at the top, profile creation and switching below it, icon selection for profiles, and chat notifications on startup, profile load, and profile switch.
- 0.21 follow-up completed: simplified the profile section into a cleaner layout with a separate divider, a dropdown-based profile selector, and a higher window frame level so the window stays above overlays when open.
- 0.21 maintenance completed: added optional file-based debug logging, wrapped initialization and window callbacks in safe calls, and fixed an addon load blocker caused by an uninitialized profile hint UI object during setup.
- 0.22 completed: limited the addon slash commands to /levelinggears and /lgs, added a launch reminder to tell users how to open settings, and added comments around the remaining helper functions so the main Lua file is more self-documenting.
- UI cleanup completed: the stat-weight section now uses the same structured layout as the other settings sections, with a divider, a title, a short description, and content rows that stay separated so they do not overlap.
- 0.24 completed: added a visible color legend near the top of the settings page, expanded the equipped-gear evaluation to cover offhand and extra inventory slots where possible, and tightened the slash-command open path so /levelinggears and /lgs reliably open the settings window.
- Load-blocker fix confirmed: the addon initialization issue is resolved and documented as fixed.
- Profile-icon issue confirmed: the earlier icon-related UI problem has been fixed and documented as resolved.
- Metadata maintenance completed: the TOC version was brought into alignment with the current implementation so the addon reports version 0.22 consistently.
- Documentation pass completed: the Lua file now has more direct comments around the debug helpers, profile state, UI construction, and minimap/slash-command entry points so the code is easier to maintain.
- Bug: earlier profile UI revisions exposed icon options too early and caused layout overlap. The issue was documented and the UI was simplified to keep profile selection compact and avoid overlap.
- Bug: the addon hit a runtime initialization error when the profile hint text object was missing. The issue was fixed by creating the missing font string during setup and validating the file with luac.
- Bug: debug logging was added as an opt-in, file-gated feature so it remains silent unless the user explicitly enables it.
- 0.241 completed (maintenance pass): fixed a sandbox violation (file-based debug logging used `io.open`, which does not exist in the WoW addon environment) by replacing it with a SavedVariables-backed ring buffer plus chat output, gated by `/lgs debug` and readable via the new `/lgs debug dump`. Fixed five real call-order/scoping bugs: `PrintChat` and `ApplySavedPosition` were referenced before their `local` declarations existed (resolved as nil globals at runtime); `RefreshProfileList`, `SetActiveProfile`, and `CreateProfile` call each other and needed explicit forward declarations; `UpdateEquippedGearEvaluation` was an unintentional global, now a forward-declared local; the real minimap button frame was being created into a *second, shadowing* `local minimapButton` instead of the module-level one, so the "Show minimap button" checkbox never controlled it. Also discovered and fixed a critical persistence bug: the TOC file never declared `## SavedVariables: LevelingGearsDB`, so despite all the SavedVariables code, nothing had ever actually persisted between sessions. Removed dead code left over from the earlier profile-icon feature (`selectedProfileIcon` referenced a global that was never defined). Renamed three genuinely-unused `self` callback parameters to `_`. Updated `.luacheckrc` with the addon's real WoW API surface so luacheck stops flagging legitimate globals as errors; `luacheck` and `luac -p` both run clean now (one intentional "loop executed at most once" notice remains in `GetActiveProfile`, which is deliberate first-match logic, not a bug).
- 0.242 completed (bugfix): user reported no colored outlines around equipped gear. Root cause (per bug #15): the paperdoll slot buttons (`CharacterHeadSlot`, etc.) this addon outlines aren't guaranteed to exist at login on this client — it loads the Character panel UI on demand, evidenced by the installed `GearScoreTBCClassic` addon deferring all of its own paperdoll work to `CharacterFrame`'s `OnShow`. Added the same `CharacterFrame:HookScript("OnShow", ...)` trigger so the outline evaluation re-runs once the panel is actually open and its slot buttons exist. Also added a debug-log line reporting slot-buttons-found vs. items-scored so this is diagnosable via `/lgs debug` + `/lgs debug dump` if it recurs. Not yet confirmed in-game.
- 0.243 completed (bugfix, confirmed via real evidence): user reported settings not persisting and still no colored outlines. Read the user's actual on-disk SavedVariables file (`WTF/Account/ANDROIDEYES/SavedVariables/LevelingGears.lua`) directly and found: (1) settings persistence is in fact already working — the file contains real, non-default per-character stat weights and window position for "Xanga - Dreamscythe" — the likely earlier confusion was that a `.toc` metadata change (like adding `## SavedVariables`) only takes effect on a full client restart, not a `/reload`; and (2) the addon's own debug log (captured automatically by `SafeCall` regardless of whether debug mode was toggled on) had captured 50 repeats of `Core.lua:607: Invalid inventory slot in GetInventorySlotInfo` — the real root cause of the missing borders (see bug #16). `RelicSlot` isn't a real inventory slot in TBC (relics share the ranged-weapon slot until Wrath), so `GetInventorySlotInfo("RelicSlot")` threw a hard Lua error that silently aborted `UpdateEquippedGearEvaluation` before it ever reached the outline-coloring code, for every class, every time. Removed the `RelicSlot` entry and wrapped the per-slot `GetInventorySlotInfo` call in `pcall` so one bad slot name can never again kill the whole evaluation. Not yet confirmed in-game that borders now render (fix is evidence-based from the debug log, but this session cannot run the client).
- User confirmed colors now work as expected after 0.243.
- 0.244 completed (bug #17): user still reported settings not retaining and asked for a static Apply/Save button below the scroll area, plus asked how WoW addons conventionally save settings. Re-audited every settings-writing function (`SetWeight`, `SetMinimapButtonVisible`, `SaveWindowPosition`, `SetActiveProfile`, `CreateProfile`, `SetDebugEnabled`) and confirmed none of them buffer state — all write directly into `LevelingGearsDB` the instant they're called, and the 0.243 evidence already proved disk persistence itself works. Concluded the most likely explanation is the client being closed in a way that skips WoW's normal SavedVariables-flush points (`/reload`, Log Out, Exit Game) — e.g. a force-quit or crash — which is not something an addon can work around. Added a static "Save Settings" button in a fixed footer (anchored to the window frame, not the scroll child, so it never scrolls away) that calls `ReloadUI()`, giving a visible on-demand confirmation that a save-and-reload cycle happened — the same pattern Blizzard's own addon-list panel uses for its "Reload UI" button. Documented the actual SavedVariables persistence model in Technical notes so this isn't mistaken for a bug again. Shrank the scroll area's bottom margin (16px → 44px) to make room for the new footer and its divider.
- 0.245 completed (bugs #18, #19): user reported the Save Settings button "is just reloading the UI and the settings aren't being updated at all," and asked to drop the Shirt/Ammo/Tabard slots plus clarify relic handling by class. Found two real, compounding issues: (1) `SetWeight` never triggered `UpdateEquippedGearEvaluation`, so changing a stat weight never live-updated the equipped-gear outline colors — the only visible feedback loop the user had; (2) the 0.244 button's `ReloadUI()` call had nothing new to persist (data was already live-saved), so it just produced a jarring, seemingly-pointless full UI reload. Fixed `SetWeight` to refresh the gear evaluation immediately, and removed `ReloadUI()` from the button entirely — it now only prints an honest confirmation of the current profile, since there is nothing left to save. Removed `ShirtSlot`, `AmmoSlot`, and `TabardSlot` from the equipped-gear evaluation (17 slots now). Verified via web search (Wowpedia) rather than assumption that TBC has no separate relic slot — Librams (Paladin), Idols (Druid), and Totems (Shaman) all share the ranged-weapon slot, which the addon already evaluates via `RangedSlot`; no per-class logic was needed, and this is now recorded in a code comment.
- 0.246 completed (bugs #20, #21): user reported the +/- buttons were visually reversed (wanted `-` on the left) and that clicking them sometimes jumped the value by 1, 3, or 5 instead of 1; also re-questioned whether `LevelingGearsDB` is declared correctly at load time. Confirmed the declaration is exactly correct (`LevelingGearsDB = LevelingGearsDB or {}`, matching the TOC's `## SavedVariables: LevelingGearsDB` case-for-case) and, via two separate on-disk SavedVariables reads taken minutes apart, confirmed weight values were genuinely changing and saving correctly throughout the user's test session — the persistence mechanism itself is sound; logged as bug #21 (open) pending a precise repro of what specifically appears lost. Swapped the `+`/`-` button anchors. Root-caused the multi-jump report to this session's own 0.245 fix: making `SetWeight` run the full (17-slot) gear evaluation synchronously on every click was expensive enough that rapid clicking could queue up and burst-fire, exactly as shown by the debug log (two "Gear evaluation" entries logged in the same second). Fixed by debouncing the evaluation behind a `C_Timer.After(0.2, ...)` guard so a burst of clicks collapses into one evaluation instead of one per click.
- 0.247 completed (bug #22): user reported the jump-by-4-or-5 was happening on the very *first* click on a stat, not just from rapid repeat clicks, and separately still reported settings not surviving a reload. Found the real root cause of both: `RefreshWeightLabels` (and `RefreshProfileList`/`RefreshGeneralSettingsUI`) only ever ran once, during the addon's initial load — never again when the user later reopened the settings window. Every stat row starts with a hardcoded placeholder label of `"5"`; if a window reopen never re-synced that label against the true saved value (e.g. 9 or 10, per this character's actual saved weights), the *first* click on that stat would compute `trueValue + delta` and display it, looking like a jump of exactly the gap between 5 and the true value — matching the reported 4s and 5s precisely. This also fully explains the "settings don't survive reload" reports: the window can display a stale number until first touched, which reads exactly like data loss even though the saved data was correct the whole time (as repeatedly confirmed on disk). Fixed by forward-declaring `RefreshWeightLabels` (joining the existing `RefreshProfileList`/`SetActiveProfile`/`CreateProfile` forward-declaration block) and calling `RefreshGeneralSettingsUI()`, `RefreshProfileList()`, and `RefreshWeightLabels()` from the window's `OnShow` handler every time it opens, plus from the Save Settings button's click handler for concrete visible proof. The window can no longer show a stale value for longer than it takes to reopen it.
- **User confirmed bugs #20, #21, #22 all fixed.**
- 0.248 completed (bug #23): user asked for Armor to also be checked. Added `ARMOR`/"Armor" to `statDefinitions` and to the "Other stats" group (alongside Defense/Dodge/Parry/Block/Block Value/Resilience), and added `ARMOR = { "ITEM_MOD_ARMOR_SHORT" }` to `itemStatAliases`, matching the existing naming convention exactly. Recorded an honest caveat: a plain piece's base armor value isn't exposed by `GetItemStats` at all (it's intrinsic to material/ilvl/slot, not a modifier stat) — this token can only ever pick up BONUS armor modifiers (e.g. a shield's "of the Bear" suffix). Unverified on this client; documented the tooltip-scan fallback per the project's existing policy for uncertain `GetItemStats` coverage if it never contributes in practice.

## Settings architecture note
- General settings should stay global to the addon and be scoped to the addon itself, not to any one character. Examples: window position, minimap button visibility, default addon behavior toggles, and future default sort/filter choices.
- Character-specific settings should be stored per character and not shared across alts. This includes the active profile selection and any character-specific override values.
- Profile-based settings should be stored inside each character's state and should eventually support spec-aware variants. Each profile can later carry fields such as name, role, spec, and profile-specific weights.
- The initial implementation now uses a simple structure: LevelingGearsDB.general for universal settings and LevelingGearsDB.characters[characterKey].profiles for profile-specific data. This keeps the model flexible for spec filtering later without forcing a rewrite.

## What this project is

**Leveling Gears** is a World of Warcraft addon for **TBC Classic Anniversary** (Lua 5.1 subset,
Classic-family client APIs — NOT retail APIs). It helps a leveling player find upgrades for their
equipped gear and tells them exactly where to get them: which quest (and chain steps), which mob or
boss, which dungeon, which profession recipe. Selected upgrades appear on the item's tooltip with a
"next step" and optional TomTom waypoint.

**Branding rule:** the addon always says "gears," never "gear." Window title: **Leveling Gears**.
Version string in smaller text directly under the title. Icon (designed later): a small gear meshing
with a big gear. Buttons use the branding: **"Select Gears"**, **"View Gears"**.

## The user (project owner)

- Has some coding experience (Python, basic Lua, HTML/JS), not professional. Explain non-obvious
  concepts briefly when introducing them. Do not assume familiarity with WoW addon internals.
- Works on an old Mac. Prefer solutions with zero or minimal tooling. Never require compiling
  anything from source. The offline data pipeline is written in Python (already installed) and, if
  a database engine is wanted, SQLite (ships with macOS) — never a database server.
- Builds and tests in small increments. STOP after each version step and wait for their results
  before continuing.

## Hard process rules for Claude Code

1. **One step at a time.** Build only the current version step (see roadmap). Then stop, tell the
   user how to test it, and wait.
2. **Update this file and the bug log** after each step: version completed, files changed, decisions, open bugs, and validation results.
3. **No invented APIs.** Use only real Classic-client Lua APIs. If unsure an API exists on the
   TBC Anniversary client, say so and propose a safe alternative.
4. **No placeholder secrets, no API keys, no external services in the addon.** The in-game addon is
   fully offline. (The offline *build pipeline* may download public databases — that's separate.)
5. **Data is baked offline, not faked.** Until the real baked database exists, any feature needing
   item/quest/loot data runs on a tiny hand-made sample table OR shows "Coming soon." Never fake a
   full database inline.
6. Keep code in small, clearly named files. Comment generously — the user reads the code.

## Versioning ladder (defined by the user — follow exactly)

- **0.1** — first runnable skeleton. 0.11, 0.12… = small additions while the addon is "just a
  window and buttons."
- **0.2, 0.3…** — milestones (settings, scoring engine, data schema, etc.). Sub-decimals = their
  sub-features. **0.3 is reserved specifically for the data-schema/database milestone** (freezing the
  table shapes + hand-made sample, per the Roadmap below) — nothing before that milestone lands may
  use a 0.3x version number, no matter how many bugfix/maintenance passes happen first.
- **Thousandths-decimal rule (added after 0.24):** once a milestone's two-decimal sub-features (0.21,
  0.22, 0.23, 0.24…) are exhausted by ordinary bugfixes and small corrections rather than new
  sub-features, extend to a third decimal digit instead of rolling the second digit over — e.g. after
  0.24, further fixes are 0.241, 0.242, 0.243… This keeps a long tail of small maintenance fixes from
  visually implying a milestone (like 0.3, the database) has been reached when it hasn't. Only
  introduce a new two-decimal sub-feature (0.25, 0.26…) for an actual new sub-feature of the current
  milestone, not for fixes to existing ones.
- **Version A** — first feature-complete **alpha** (no decimal). A.1, A.2 = alpha fixes.
- **Version B** — **beta**.
- **1.0** — first shipped release. **1.01** = bug patches. **1.1** = one new feature.
  After ten features (1.10), roll to **2.0**.

---

## DATA: the shape now vs. the shape we need (read before the roadmap)

This addon lives or dies on its data. Two source shapes exist and must be inverted into ours.

**How the source data is shaped now:**
- cmangos tbc-db (SQL): organized by *creature* — `creature_loot_template` rows say "creature X
  drops item Y at Z%." World drops and shared tables hide behind `reference_loot_template` (a
  negative `mincountOrRef` is a pointer into it — must be resolved). Also holds quests
  (`quest_template`, incl. reward items) and profession/recipe data. Creature level lives in
  `creature_template` (MinLevel/MaxLevel). GPLv3.
- Questie source Lua tables (`Database/*.lua` — the SOURCE files, NOT the shipped compiled blobs):
  organized by *quest* — quest → reward items, prequests (`preQuestSingle` = need any one,
  `preQuestGroup` = need all), `nextQuestInChain`, plus coordinates via the NPC/object DBs. Has
  hand-applied corrections cmangos lacks. Check its LICENSE before redistributing derived data.

**How WE need it shaped** (organized by what the hover query asks — "upgrades for THIS slot"):

    Items[itemId]   = { name, slot, subtype, armorType, reqLevel, classMask }
                      -- NOTE: gear STATS are NOT stored here. Read them from the client at
                      -- runtime via GetItemStats (see technical notes; item must be cached —
                      -- GetItemInfo async rules apply). The client already knows every item's
                      -- stats; baking them would duplicate and desync.
    Sources[itemId] = {                      -- LIGHT summaries only, no coordinates
                        { kind="drop",   npcId=, dropRate=, obtainLevel= },
                        { kind="quest",  questId=, chainId=, choiceGroup=, obtainLevel= },
                        { kind="craft",  prof=, recipeId=, recipeSource=, obtainLevel= },
                        { kind="vendor", npcId=, cost=, obtainLevel= },
                        { kind="boe",    obtainLevel= },   -- exists on AH; watch/price via AH
                      }
    Quests[questId] = { pickup={zone,x,y,npc}, turnin={...}, chainId, requiredLevel, faction }
    Chains[chainId] = { steps = { {questId}, {questId}, ... } }   -- ordered
    Recipes[recipeId] = { prof, skill, reagents={ {itemId,n}, ... }, taughtBy=, recipeDropRate= }
    BySlot[slot]    = { itemId, itemId, ... }   -- the fast door the hover query walks

Key rules baked into this shape: **store each fact once, reference by ID everywhere else**
(BySlot holds IDs, not copies). **reqLevel** (can I equip it) is separate from **obtainLevel**
(can I realistically get it) — leveling needs both. **Heavy detail (coords, chain steps, reagents)
lives off the hot path** in Quests/Chains/Recipes and is only touched on click, never on hover.
If coordinates are baked into Quests at build time, TomTom works with NO runtime Questie dependency.

---

## Roadmap (each bullet is a stop-and-test gate)

### Foundation
- **0.1 — Skeleton.** Addon loads on TBC Anniversary. `/levelinggears` and `/lgs` (also try `/lg`
  as a bonus alias, but primary commands must not depend on it) open **THE settings window** —
  the only settings screen this addon will ever have — titled "Leveling Gears" with the version
  string under the title and an X close button. At 0.1 it's an empty shell; its contents get filled
  in by later steps. Nothing else yet. (The only other frame that will ever exist is the 0.5
  recommendation window, which is not settings.)
- **0.11 — Minimap button** (LibDBIcon or hand-rolled) opens/closes **the same one window**. The
  slash commands and the minimap button are two doors into the identical settings window — never
  two different screens.
- **0.12 — Window polish.** Draggable, remembers position (SavedVariables), Escape closes,
  vertical scrolling (its contents will grow long).

### The stat-weight settings (EARLY — this fills the one window and is its main content)
- **0.2 — The stat-weight list.** This is the primary content of THE single settings window (the
  same one 0.1 opens from slash/minimap) — fully visible and user-facing, NOT a hidden engine.
  The window's body is a **vertically scrolling list** of every TBC gear stat, built from the known
  fixed set (primary stats, spell power/healing, all the ratings, mp5, attack power, resistances,
  etc. — a finite, knowable list, not discovered dynamically). Each stat is a row the user sees and
  edits directly: the stat's name, its current value, and **up/down arrows** on a **0–10 scale** —
  **0 = ignore entirely, 1 = lowest importance, 10 = most important.** Default: **every stat
  equal.** The 0–10 is what the user sees and controls; internally map it to whatever real
  multiplier the scorer needs (the math is hidden, the sliders are not). Per-character, saved.
  Every OTHER setting the addon ever gains (minimap toggle, suggestion count, source checkboxes,
  spec dropdown, TomTom row, etc.) also lives on THIS one scrolling page — there is no second
  settings screen anywhere in the app.
- **0.21 — The scorer.** A function behind the page: score(item) = sum over the item's numeric
  stats of (statValue × that stat's weight). It reads the exact values shown on the 0.2 page.
  It has no results window YET (that's the recommendation window later), so at this step prove it
  with a print/debug against a couple of hand-typed fake items — but the WEIGHTS driving it are
  already fully visible and editable on the 0.2 page. Nothing about the weights is background.
- **Proc/effect stats — LATER, OPTIONAL track.** "Chance on hit," "increases healing by up to N,"
  and use-effects are TEXT, not clean numeric stats; the client won't hand them over as
  multipliable numbers. v1 policy: **weight only clean numeric stats; ignore procs/use-effects in
  scoring** (item still appears, its normal stats still count). Assigning values to named effects
  would need a SECOND scraped database (e.g., an effect→value table) — spec this as an explicit
  future option only if the user wants it. Do NOT build it into early versions.

### Data pipeline (build the schema early; fill it in stages)
- **0.23 — Equipped-gear weakness evaluation.** Using the visible 0.2 weights, evaluate each
  equipped piece of gear against the character's current gear average. Show a thin colored outline
  around the item's slot button so the player can see at a glance which pieces are below average,
  at average, or above average for the current build. The color scale is relative to the largest
  gap in the current gear set, with green marking parity, red/orange/yellow marking weaker-than-
  average pieces, and cyan/blue/violet marking stronger-than-average pieces. This is a no-database
  step and is intentionally aimed at identifying improvement opportunities rather than producing a
  traditional "gear score".
- **0.3 — Freeze the schema + hand-made sample.** Implement the exact table shapes above as real
  Lua files. Populate with a ~12-item HAND-MADE sample spanning every source kind (drop, quest,
  chain, craft, vendor, boe) so all later UI can be built and tested with zero pipeline. This is
  the contract every other module codes against.
- **0.31 — Download the sources.** Guide the user to obtain: cmangos tbc-db (GitHub ZIP) and
  Questie source Lua (GitHub ZIP — the Database/ source files). Record exact locations on disk.
- **0.32 — Parser: quests first (easy source).** Python script reads Questie's source Lua (crib its
  `setupTests.lua` stubs to load the tables) → emit Items/Sources/Quests/Chains for quest rewards
  in OUR schema. Prove the parse→normalize→emit loop on the tidy source before the hard one.
- **0.33 — Parser: loot + recipes (hard source).** Extend the Python pipeline to read cmangos SQL
  (via direct text parsing OR load into SQLite), resolving `reference_loot_template` indirection,
  joining `creature_template` for obtainLevel, emitting drop/craft/vendor sources. This is the
  genuinely hard part — expect iteration.
- **0.34 — Bake coordinates + merge.** Join quests → start/turn-in NPC → spawn coords so Quests
  carries waypoints inline (removes runtime Questie dependency). Merge all sources into one baked
  DB, build the BySlot index. Make the whole pipeline a repeatable script, versioned per game
  phase, so it can be re-run when data updates.
- **Licensing:** cmangos is GPLv3; check Questie's license. Re-derived facts into our own schema +
  credit sources; be prepared to license the addon compatibly. Using cmangos for loot avoids
  AtlasLoot's GPL entirely.

### The product (UI against sample data, then real data once 0.3x lands)
- **0.4 — Tooltip hook.** Hovering an EQUIPPED item adds a small Leveling Gears section for that
  slot. TECHNICAL REALITY: Blizzard's GameTooltip cannot host clickable buttons — tooltips aren't
  mouse-interactive and vanish when the cursor leaves the item. So implement as: informational
  lines appended INTO the tooltip (selected upgrade + where to get it), and the clickable actions
  ("Select Gears" / "next step") on a small separate clickable flyout frame anchored beside the
  tooltip, or triggered by a modifier key (e.g., "Alt+click to Select Gears") — propose the
  approach, let the user pick, record it here. No upgrade chosen for that slot → the Select Gears
  action. One chosen → show it + where to get it + the next-step action.
- **0.5 — Recommendation window.** Opens from "Select Gears," scoped to the hovered slot (gloves →
  glove upgrades). Layout top→bottom: header (name + icon + version), character summary (name,
  level, color-rated gearscore), then suggested items: each row = icon + name (native quality
  color), % upgrade, source summary, group-content marker. Hovering a row shows the NATIVE item
  tooltip (Blizzard renders stats free) PLUS our appended lines (source, drop %, quest/chain
  position, profession, mob/boss, dungeon, quest-giver location). Clicking selects it for the slot.
  Scores via the 0.21 engine; data from the sample table until the pipeline is done.
- **0.6 — Next-step engine.** Selected upgrade shows current next step and iterates it: quest
  chains advance to the first uncompleted quest (completed quests excluded everywhere); crafted
  items show reagents and open the profession window; recipe-is-a-drop shows the recipe's own drop
  source + rate (show the rate, player decides). TomTom present → button sets a waypoint (mob area,
  boss's dungeon, quest pickup, vendor, or AH for BoE). TomTom absent → button reads "Install
  TomTom for waypoints" and coords/zone still show as text. BoE: button also prints a clickable
  item link LOCALLY into the player's own chat frame (no self-whisper — client forbids it) so their
  pricing addon can act on it.
- **0.7 — Sorting & filters.** Sorts: **Best upgrade %** (default, top 3 by default, count
  configurable), **Most accessible** (composite of mob level vs player, elite/group, chain length —
  imperfect OK, list scrolls to less accessible), **Highest stats**, **By particular stat**.
  Source-type checkboxes, ALL ON by default (quest, dungeon, world/mob, craft, vendor, BoE/AH).
  Faction = HARD filter. Race = NOT filtered (show it, player judges the trip). Group-required
  content is explicitly marked so no one gets waypointed to an unsoloable dungeon blind.
- **0.8 — Equipped-gear glow.** Thin, clean, non-invasive colored outline showing upgrade need,
  computed RELATIVE to the character's OWN average item quality (a quest-gear player is judged
  against themselves, never dungeon standards).
- **0.9 — Alt professions & crafter fallback.** Checkbox: consider alts' professions (needs the alt
  to have logged in once with the addon; per-character data unioned in a global SavedVariable —
  "known alts only"). Toggle: if no one you have can craft it, still show reagents + offer a
  pre-written trade-chat message to find a crafter. Both default on, both disableable.

### Later
- **Spec guesser / chooser (later version).** Reads talent point distribution (e.g., 21/5/33),
  matches a table of popular builds (hand-made, user-expanded). Its ONLY job is to **move the
  visible 0–10 sliders on the 0.2 page automatically** to a preset — the user watches them move and
  can still grab any slider by hand afterward. It never hides or replaces the weight page; it's a
  convenience layer on top of it, not a separate scoring path. Dropdown to override the guess; must
  allow off-meta specs (Dreamstate Resto Druid, Shockadin, etc.). A wrong guess just means the user
  adjusts the same always-visible sliders themselves.
- **Proc/effect valuation (optional).** See the proc note under 0.2 — only if the user commits to
  the second scraped database.
- **A / B / 1.0** — per the versioning ladder, gated by the user.

---

## The color system (used addon-wide, unanimously)

ROYGBIV, one consistent meaning everywhere:
**Red = urgent/worst → Orange → Yellow → Green = solid/good → Blue → Indigo/Violet = exceptional.**
Gearscore is never a number — it is a colored outline/rating on this scale. Glows use it. Item
NAMES keep Blizzard's native quality colors (a different, familiar system — do not mix the two).

## Settings inventory (ALL on the ONE scrolling settings window; build each when its step arrives)

There is exactly ONE settings window in this addon. Slash commands and the minimap button both open
it, and every setting below lives on that single vertically-scrolling page — no second settings
screen exists anywhere. (The 0.5 recommendation window is a separate frame, but it is NOT settings —
it is the per-slot upgrade picker opened from "Select Gears." Those are the only two frames.)

- Per-stat weights, 0–10, up/down arrows — the main content of the window, visible and directly
  editable from early (0.2); later spec automation just moves these sliders
- Minimap button on/off
- Suggestion count (default 3)
- Sort mode default
- Source-type checkboxes (all on by default)
- Alt professions toggle; crafter-search fallback toggle
- Spec override dropdown (later; adjusts the weights)
- TomTom integration (auto-detected; row explains if missing)

**Static footer (0.244, revised 0.245):** a "Save Settings" button lives in a fixed footer below the
scroll area (anchored to the window frame itself, not the scroll child, so it never scrolls out of
view — the same structural exception as the title/version/close button at the top). Every setting
already writes into `LevelingGearsDB` the instant it changes; WoW addons have no separate manual
"save" step, and the client itself flushes SavedVariables to disk on `/reload`, logout, or exit (see
Technical notes). **0.245 removed the `ReloadUI()` call** the button originally made (0.244): since
there was nothing left to persist, forcing a full UI reload only produced a jarring "nothing appears
to have happened" experience (bug #18). The button now just prints an honest chat confirmation of the
current profile — there is nothing to reload because there is nothing unsaved.

## Technical notes

- Client: TBC Classic Anniversary. Lua 5.1 subset; Blizzard strips most of `io`/`os`. No file or
  network access from the addon itself.
- Item stats: read at runtime. Numeric stats come from **`GetItemStats(itemLink)`** (returns a
  table of ITEM_MOD_* values) — NOT from GetItemInfo, which gives name/quality/ilvl/equipLoc but
  no stats. Caching still gates both: `GetItemInfo` is ASYNC — uncached items return nil on first
  call; use a request queue keyed on the `GET_ITEM_INFO_RECEIVED` event and fill scores in as items
  arrive. VERIFY at 0.21 on the Anniversary client that GetItemStats surfaces "Equip:" values
  (+healing, +spell damage, mp5) as ITEM_MOD_* entries; if any are missing there, fall back to a
  hidden-tooltip scan for those lines and record the finding in this file.
- Armor (added 0.248, bug #23): `GetItemStats` does NOT expose a plain item's base armor value —
  base armor is intrinsic to material/item level/slot, not a modifier stat. `ITEM_MOD_ARMOR_SHORT`
  (added to `itemStatAliases` as `ARMOR`) can only ever pick up BONUS armor modifiers (e.g. a shield's
  "of the Bear"-style suffix). Unverified on this client; if it never contributes to any item's score
  in play, fall back to a hidden-tooltip scan of the "Armor" line, same policy as above.
- Class/usability filtering: our baked DB carries classMask, so class checks are a table lookup for
  DB items. `GetItemInfo` gives equipLoc/subtype/minLevel. A hidden-tooltip scan of the "Classes:"
  line is the FALLBACK only, for items not in our DB or missing a mask.
- Slash: `/levelinggears` + `/lgs` primary; `/lg` best-effort alias only.
- SavedVariables: settings account-wide with per-character overrides; per-character selected
  upgrades, weights, and alt profession data.
- **How WoW addon persistence actually works (no "save" step exists):** an addon never explicitly
  writes its SavedVariables to disk. Every value change should just mutate the global table declared
  in `## SavedVariables:` immediately (this addon already does that everywhere — `SetWeight`,
  `SetMinimapButtonVisible`, `SaveWindowPosition`, etc. all write straight into `LevelingGearsDB`).
  The *client itself* serializes that table to
  `WTF/Account/<ACCOUNT>/SavedVariables/LevelingGears.lua` at the normal save points: `/reload`,
  camping to character select, "Log Out," or "Exit Game." Force-quitting the process (task-killing
  it, a crash, unplugging power) skips all of those and loses anything since the last save point —
  this is the single most common cause of "my settings didn't stick" reports, and is not a bug an
  addon can work around. Because of this, addons conventionally do NOT ship a manual "Save"/"Apply"
  button — there's nothing for it to do that isn't already happening. The one thing an addon CAN
  expose is a button that calls `ReloadUI()`, which forces an on-demand save-and-reload cycle; this
  addon's 0.244 "Save Settings" footer button does exactly that, purely for visible reassurance.
- Also note: a `.toc` metadata change (e.g. adding a `## SavedVariables` line, changing dependencies)
  is only read when the client fully starts up — `/reload` does not re-parse the `.toc`. Test any
  `.toc` change with a full exit-and-relaunch, not just `/reload`.
- Libraries: Ace3 (AceDB, AceConfig, AceGUI) + LibDBIcon acceptable if they cut boilerplate;
  plain frames also fine for 0.1. Choose per step and record it here.
- Pipeline: Python (installed) + optional SQLite (ships with macOS). Never a DB server.
- Provide exact in-game test steps each stop ("/reload, type /levelinggears, expect X").

## Decision log

- **2026-07-12** — Project moved to `~/Projects/LevelingGears` (git-initialized), symlinked into
  `.../_anniversary_/Interface/AddOns/LevelingGears` on the external drive for live in-game testing.
- **2026-07-12** — Confirmed `## Interface: 20505` is correct for this TBC Anniversary client by
  grepping installed addons' own TBC-specific TOC files (DBM-Core_TBC.toc, GearScoreTBCClassic_TBC.toc,
  both ship `## Interface: 20505` for this exact client build `wow_anniversary 2.5.6.68575`) rather
  than guessing.
- **2026-07-12** — 0.1 built with **plain frames, no Ace3** (per Technical notes: "plain frames also
  fine for 0.1"). Single file `Core.lua`. Verified `BackdropTemplateMixin and "BackdropTemplate" or
  nil` idiom and the `UIPanelCloseButton` template are both real/in-use on this client by grepping
  other installed addons (Attune, Auctionator) before using them — not invented.
- **2026-07-12** — Local dev tooling installed (Homebrew `lua` 5.5 + `luarocks` + `luacheck` via
  `~/.luarocks`, run against a side-by-side `lua@5.4` since luacheck 1.2.0 doesn't run on 5.5). This
  is purely a local linter for catching typos before reloading the UI — the addon itself has zero
  dependency on it and ships pure Lua 5.1-compatible source.

## Current status

- **Current step: 0.248 — built, ready to commit.** Files: `LevelingGears.toc`, `Core.lua`.
  0.241–0.243 fixed the `io.*` sandbox violation, forward-reference bugs, the missing
  `## SavedVariables` TOC directive, and the `RelicSlot` crash killing the gear-outline colors (**user
  confirmed colors work**). 0.244–0.245 iterated on the Save Settings button and fixed `SetWeight` to
  live-refresh gear outlines, and dropped Shirt/Ammo/Tabard from evaluation. 0.246 fixed the `+`/`-`
  button order and debounced the gear evaluation against rapid clicking. 0.247 found and fixed the
  actual root cause behind both remaining reports (bug #22): the settings window only synced its
  displayed labels from `LevelingGearsDB` once, at initial load, never again on reopen — **user
  confirmed bugs #20, #21, and #22 all fixed.** 0.248 added Armor as a weightable stat (bug #23), with
  an honest caveat recorded that `GetItemStats` only exposes bonus/suffix armor, not a piece's base
  armor value. **User is ready to commit and push** — see the Decision log for the commit/push plan.
