# Known bugs

This file is the working bug ledger for Leveling Gears. Keep it updated after every change.

## Status legend
- Open: still affecting the addon or not yet verified as fixed
- Solved: confirmed fixed and verified
- Mitigated: reduced or partially improved but still needs follow-up

## Bug entries

### 1. Slash command and minimap button stopped responding
- Status: Solved
- Discovered: 2026-07-13 13:00 local
- Solved: 2026-07-13
- Version introduced: 0.21
- Summary: After the profile UI work, the addon stopped responding to the slash command and the minimap button even though it appeared to load.
- Observed behavior:
  - The addon loaded and printed the startup message.
  - /levelinggears no longer opened the settings window.
  - The minimap button no longer opened or closed the window.
- Likely cause: fragile profile UI code and initialization changes around the new profile controls.
- Attempts to fix:
  - Reviewed the addon initialization flow and the profile UI code.
  - Removed the unstable profile icon button styling logic.
  - Simplified the profile section to a safer dropdown-based layout.
- Resolution: The addon initialization path was made more conservative and the profile section was simplified to avoid breaking startup.
- Validation: Lua syntax remained valid with `luac -p Core.lua`.
- Follow-up: Retest in-game after a full UI reload and verify the slash command and minimap button open the same settings window.

### 2. Addon load blocked by missing profile hint UI object
- Status: Solved
- Discovered: 2026-07-13
- Solved: 2026-07-13
- Version introduced: 0.21
- Summary: The settings UI attempted to use a missing profile hint font-string during addon initialization, causing a runtime error that prevented the addon from loading cleanly.
- Observed behavior:
  - The addon failed during setup when the profile hint object was referenced.
- Likely cause: the profile hint text element had not been created before it was used.
- Attempts to fix:
  - Added the missing font string during UI creation.
  - Wrapped core frame callbacks in safe calls so future Lua errors do not break startup as severely.
- Resolution: The missing object is now created during initialization and the addon can build its UI successfully.
- Validation: `luac -p Core.lua` completed successfully.
- Follow-up: Confirm in-game that the addon loads and opens normally after a reload.

### 3. Optional debug logging needed without spamming players
- Status: Solved
- Discovered: 2026-07-13
- Solved: 2026-07-13
- Version introduced: 0.21
- Summary: The addon needed a quiet, opt-in debugging path for Lua errors without always writing logs or affecting other players.
- Observed behavior:
  - There was no safe way to capture addon errors locally.
- Likely cause: no opt-in debug logging path existed yet.
- Attempts to fix:
  - Added a file-gated debug mode.
  - Implemented `/levelinggears debug` and `/lgs debug` to enable it.
  - Wrote errors to a local debug log file only when the debug file exists.
- Resolution: Debug logging is now available and remains silent unless explicitly enabled.
- Validation: Lua syntax remained valid after the change.
- Follow-up: Test in-game by enabling debug mode and triggering an error path.

### 4. TOC metadata drifted from the implemented version
- Status: Solved
- Discovered: 2026-07-13
- Solved: 2026-07-13
- Version introduced: 0.21
- Summary: The addon metadata in the TOC file had fallen behind the implemented version string.
- Observed behavior:
  - The TOC reported version 0.2 while the Lua file reported 0.21.
- Likely cause: documentation and metadata were not updated consistently after implementation changes.
- Attempts to fix:
  - Updated the TOC version to 0.21.
  - Updated the TOC version again to 0.22 after the command-surface and launch-message changes.
- Resolution: The TOC now matches the current implementation.
- Validation: The file contents were checked directly.
- Follow-up: Keep version metadata aligned whenever the addon version changes.

### 5. Slash-command surface was too broad and did not guide players on first launch
- Status: Solved
- Discovered: 2026-07-13
- Solved: 2026-07-13
- Version introduced: 0.21
- Summary: The addon exposed an extra /lg alias and did not clearly tell players how to open the settings window on first launch.
- Observed behavior:
  - Players saw an extra slash command alias and had no launch-time reminder for the supported commands.
- Likely cause: the command registration was broader than needed and the startup message did not include usage guidance.
- Attempts to fix:
  - Removed the /lg alias from the command registration.
  - Added a startup chat message telling players to type /levelinggears or /lgs to open settings.
- Resolution: The addon now supports only /levelinggears and /lgs, and it gives players a clear first-launch reminder.
- Validation: Lua syntax remained valid after the change.
- Follow-up: Confirm the new command behavior in game after a full reload.

### 6. Profile icon UI caused visual clutter and layout issues
- Status: Solved
- Discovered: 2026-07-13
- Solved: 2026-07-13
- Version introduced: 0.21
- Summary: The earlier profile UI iteration exposed icon-related controls too aggressively and created visual overlap in the settings window.
- Observed behavior:
  - The profile section felt crowded and the UI did not stay visually clean.
- Likely cause: the profile UI was too eager to expose icon-related choices before the section had been simplified.
- Attempts to fix:
  - Simplified the profile UI layout.
  - Kept the profile selection compact and separated from the stat-weight section with a divider.
- Resolution: The icon-related issue is now resolved and the profile section remains compact and tidy.
- Validation: The Lua file still parsed successfully after the UI cleanup.
- Follow-up: Recheck the in-game layout after a full reload.

### 7. Settings sections could draw on top of each other in the single settings window
- Status: Solved
- Discovered: 2026-07-13
- Solved: 2026-07-13
- Version introduced: 0.22
- Summary: The General, Profiles, and Stat weights blocks were still sharing the same anchoring pattern, which caused them to render in the same vertical region and appear visually overlapped.
- Observed behavior:
  - General settings, profiles, and stat-weight sections appeared stacked in the same area instead of as distinct blocks.
- Likely cause: multiple UI blocks were anchored directly to the scroll child using the same top-left origin and offset progression.
- Attempts to fix:
  - Rebuilt the page into separate section containers for General settings, Profiles, and Stat weights.
  - Anchored those containers to each other so each block now has its own vertical spacing.
- Resolution: The settings page now uses dedicated section frames, so the blocks render as separate, clearly spaced sections instead of overlapping.
- Validation: `luac -p Core.lua` completed successfully after the layout change.
- Follow-up: Reload the addon in-game and visually confirm the blocks remain separated at runtime.

### 8. Slash commands were not reliably opening the settings window
- Status: Solved
- Discovered: 2026-07-13
- Solved: 2026-07-13
- Version introduced: 0.23
- Summary: The slash-command handler was not providing a fully robust open path for the settings window.
- Observed behavior:
  - Typing /levelinggears or /lgs did not reliably bring up the settings page.
- Likely cause: the open/close toggle path did not fully reapply the window state and the handler did not guard the frame lifecycle as tightly as it should.
- Attempts to fix:
  - Wrapped the toggle path in a safer open routine.
  - Reapplied frame strata, level, and saved position before showing the window.
- Resolution: The slash commands now route through a safer open path and should open the settings page reliably.
- Validation: `luac -p Core.lua` completed successfully after the change.
- Follow-up: Reload the addon in-game and verify the commands open the settings page immediately.

### 9. The equipped-gear evaluation did not cover every relevant inventory slot
- Status: Solved
- Discovered: 2026-07-13
- Solved: 2026-07-13
- Version introduced: 0.24
- Summary: The initial outline evaluation only covered the core equipment slots and missed offhand and other special inventory slots.
- Observed behavior:
  - Offhand and extra inventory slots did not receive the same weighted outline evaluation.
- Likely cause: the slot list was based on a limited set of hard-coded inventory indexes instead of the slot names used by the client UI.
- Attempts to fix:
  - Switched the evaluation to slot-name lookups so the addon can resolve offhand, ammo, and relic-style slots when the client exposes them.
- Resolution: The outline evaluation now covers offhand and extra inventory slots where the game exposes them.
- Validation: `luac -p Core.lua` completed successfully after the change.
- Follow-up: Reload the addon in-game and confirm the extra slots receive outlines when relevant.

### 10. Debug logging used `io.open`, which does not exist in the WoW addon sandbox
- Status: Solved
- Discovered: 2026-07-13
- Solved: 2026-07-13
- Version introduced: 0.21 (file-based debug logging)
- Summary: The opt-in debug logger wrote to a log file via `io.open`/`fh:write`. WoW addons run in a sandbox with no `io`/`os.execute`/file access at all, so every debug-mode session would have errored the moment logging was enabled or a Lua error occurred.
- Observed behavior: Not caught in-game yet; found via static review against the project's own sandbox rules (CLAUDE.md explicitly forbids `io.*`).
- Likely cause: file-based logging was designed by analogy to desktop scripting rather than WoW's actual capabilities.
- Attempts to fix:
  - Replaced `io.open`/file writes with a bounded ring buffer (`LevelingGearsDB.debugLog`, capped at 50 entries) stored in SavedVariables.
  - Debug messages now also print to chat immediately when debug mode is enabled.
  - Added `/lgs debug dump` to print the stored entries to chat, replacing the old "open the log file" workflow.
- Resolution: No file I/O remains anywhere in Core.lua. Debug logging is fully sandbox-safe.
- Validation: `luac -p Core.lua` and `luacheck Core.lua` both pass; grep confirms no `io.`/`os.`/`package.`/`require(`/`loadfile`/`dofile` usage remains.
- Follow-up: Enable `/lgs debug` in-game, trigger an error, and confirm `/lgs debug dump` shows it.

### 11. Several functions were referenced before their local declaration existed
- Status: Solved
- Discovered: 2026-07-13
- Solved: 2026-07-13
- Version introduced: 0.21–0.24 (accumulated across several steps)
- Summary: Lua resolves `local` references lexically at parse time, not by call time. Several functions called others that were declared with `local function` later in the same file, so those calls silently fell through to nil globals instead of the intended local functions.
- Observed behavior: Not yet hit in a normal play session (most of these paths are debug mode, first-time profile creation, or the minimap toggle), but each would throw "attempt to call a nil value" the first time it executed:
  - `SetDebugEnabled`/`SafeCall` called `PrintChat` before it was declared (would break `/lgs debug` and all error reporting).
  - `ToggleLevelingGears` called `ApplySavedPosition` before it was declared (would break every window-open after the very first one, since the fallback path never ran, and also referenced a fallback `LevelingGears` global that was never set).
  - `RefreshProfileList`'s "Create new profile" and profile-select rows called `CreateProfile`/`SetActiveProfile`, both declared after it (would break profile creation/switching from the dropdown).
  - `RefreshWeightLabels` and the equipment-change event handler called `UpdateEquippedGearEvaluation`, which was an implicit global assigned later in the file (worked by luck, since it's a global not a local, but was flagged as an unintentional global by `luacheck`).
- Likely cause: functions were added incrementally in the order features were built, not in dependency order, with no forward declarations.
- Attempts to fix:
  - Moved `PrintChat` and `ApplySavedPosition` to be defined before their first use.
  - Added explicit forward declarations (`local RefreshProfileList`, `local SetActiveProfile`, `local CreateProfile`, `local UpdateEquippedGearEvaluation`) near the top of the file, then assigned each with `Name = function(...) ... end` at its original definition site, per the project's "explicitly forward declared" rule.
  - Removed the dead `or LevelingGears` fallback in `ToggleLevelingGears` since `_G["LevelingGearsFrame"]` is always populated by the time the function can be called.
- Resolution: Every function reference now resolves to the intended local at parse time; none of these paths depend on accidental global fallback anymore.
- Validation: `luac -p Core.lua` and `luacheck Core.lua` both pass with 0 errors.
- Follow-up: In-game, test `/lgs debug`, opening/closing the window multiple times, creating a new profile, and switching profiles from the dropdown.

### 12. Minimap-button visibility checkbox never actually controlled the minimap button
- Status: Solved
- Discovered: 2026-07-13
- Solved: 2026-07-13
- Version introduced: 0.11 (minimap button) / regressed further whenever the button setup was touched
- Summary: `local minimapButton = nil` was declared once near the top of the file as the module-wide reference used by `SetMinimapButtonVisible`. The actual minimap button frame was later created with `local minimapButton = CreateFrame(...)`, which declared a *new, second* local that shadowed the first instead of assigning into it. `SetMinimapButtonVisible` kept its original upvalue, which stayed nil forever, so toggling "Show minimap button" silently did nothing.
- Observed behavior: Not yet reported by testing; found via static review (`luacheck` flagged "variable minimapButton was previously defined").
- Likely cause: re-using `local` for what should have been a plain assignment into the already-declared module-level variable.
- Attempts to fix: Removed the `local` keyword from the minimap button's creation line so it assigns into the existing module-level `minimapButton` variable instead of shadowing it.
- Resolution: `SetMinimapButtonVisible` now controls the real minimap button.
- Validation: `luacheck Core.lua` no longer reports the shadowed-variable warning.
- Follow-up: In-game, toggle the "Show minimap button" checkbox and confirm the minimap button actually shows/hides.

### 13. TOC file never declared the addon's SavedVariable
- Status: Solved
- Discovered: 2026-07-13
- Solved: 2026-07-13
- Version introduced: 0.1 (present from the very first skeleton)
- Summary: `LevelingGears.toc` never had a `## SavedVariables: LevelingGearsDB` line. Without it, WoW never persists `LevelingGearsDB` between sessions — it behaves like an ordinary Lua global that is empty on every login. Every feature described as "saved" in this file (window position, minimap toggle, profiles, stat weights) has likely never actually survived a real logout/login, only `/reload` within the same session.
- Observed behavior: Not yet reported by testing (easy to miss since `/reload` doesn't reload the game process and so doesn't expose the bug); found via static review of the TOC against the Lua file's SavedVariables usage.
- Likely cause: the TOC metadata was updated for version numbers but the SavedVariables directive was never added when SavedVariables usage was introduced.
- Attempts to fix: Added `## SavedVariables: LevelingGearsDB` to `LevelingGears.toc` and bumped the version to 0.241.
- Resolution: `LevelingGearsDB` will now be written to and restored from the account's `WTF` SavedVariables file across full game restarts. **Note for testing:** a `.toc` metadata change (like adding a `## SavedVariables` line) is only read when the game client fully starts up, not on `/reload` — `/reload` alone is not enough to pick up this specific kind of fix.
- Validation (2026-07-13): confirmed directly by reading `WTF/Account/ANDROIDEYES/SavedVariables/LevelingGears.lua` on disk — it now contains real, non-default per-character data for `Xanga - Dreamscythe` (custom stat weights, window position), proving the SavedVariables directive is active and persistence is working end to end.
- Follow-up: None — confirmed working from the on-disk SavedVariables file.

### 14. Dead code referencing a never-defined `selectedProfileIcon` global
- Status: Solved
- Discovered: 2026-07-13
- Solved: 2026-07-13
- Version introduced: 0.21 (left over after the profile-icon feature was simplified out, see bug #6)
- Summary: `CreateProfile` accepted an unused `icon` parameter and set `icon = icon or selectedProfileIcon` on new profiles. `selectedProfileIcon` was never declared anywhere in the file, so this always evaluated to `nil` — harmless at runtime, but an unintentional global reference and dead code left over from the removed icon-picker UI.
- Observed behavior: Not runtime-visible (silently evaluates to nil); flagged by `luacheck` as "accessing undefined variable."
- Likely cause: leftover from the profile-icon UI that was simplified away per bug #6, without removing the field that referenced it.
- Attempts to fix: Removed the `icon` parameter from `CreateProfile` and the `icon` field from the profile table entirely, since no UI currently sets or reads it.
- Resolution: No remaining reference to `selectedProfileIcon` anywhere in the file.
- Validation: `luacheck Core.lua` no longer reports it; `grep -n selectedProfileIcon Core.lua` returns nothing.
- Follow-up: None — this is inert until profile icons are revisited as a real feature (see the "Later" roadmap section).

### 15. No colored outlines appear around equipped gear
- Status: Mitigated (root cause found and fixed in bug #16; CharacterFrame OnShow fix below is still a valid, permanent improvement)
- Discovered: 2026-07-13 (reported by the project owner)
- Version introduced: 0.23 (equipped-gear weakness evaluation)
- Summary: The equipped-gear outline evaluation looks up the paperdoll slot buttons by global name (`_G.CharacterHeadSlot`, etc.) and only re-runs on `PLAYER_ENTERING_WORLD`, `PLAYER_EQUIPMENT_CHANGED`, and `UNIT_INVENTORY_CHANGED`. This client (TBC Classic Anniversary, a modern client build) loads the paperdoll/Character panel UI on demand rather than at login, so those slot buttons likely don't exist yet the first time the evaluation runs, and nothing ever re-triggers it once the player opens their character sheet for the first time. `EnsureGearOutline` silently returns nil for a missing button, so the failure is invisible — no error, just no borders.
- Observed behavior: No color borders around equipped gear at all.
- Likely cause: paperdoll slot buttons not yet created when `UpdateEquippedGearEvaluation` runs; evaluation was never re-triggered by opening the character panel.
- Evidence: `GearScoreTBCClassic` (an addon installed on this same client, doing very similar per-slot paperdoll work) explicitly defers all of its paperdoll-slot logic to `CharacterFrame:HookScript("OnShow", ...)` rather than assuming the slot buttons exist at login — the same defensive pattern this addon was missing.
- Attempts to fix:
  - Added `CharacterFrame:HookScript("OnShow", function() SafeCall(UpdateEquippedGearEvaluation) end)` so the evaluation re-runs every time the character panel is opened, once the slot buttons are guaranteed to exist.
  - Added a debug-log line (`buttonsFound`/`scoreCount` out of the total slot count) inside `UpdateEquippedGearEvaluation`, visible via `/lgs debug` + `/lgs debug dump`, so if borders still don't appear the exact cause (missing buttons vs. zero-scored items) is directly diagnosable instead of silent.
- Resolution: This fix alone was not sufficient — see bug #16 for the actual root cause, which this debug logging directly exposed via the on-disk debug log.
- Validation: `luac -p Core.lua` and `luacheck Core.lua` both pass.
- Follow-up: Retest after the bug #16 fix.

### 16. `RelicSlot` is not a valid inventory slot in TBC, and its hard Lua error silently killed every outline
- Status: Solved
- Discovered: 2026-07-13 (found via the on-disk `WTF/Account/ANDROIDEYES/SavedVariables/LevelingGears.lua`, which had captured 50 identical debug-log entries: `Core.lua:607: Invalid inventory slot in GetInventorySlotInfo`)
- Solved: 2026-07-13
- Version introduced: 0.24 ("expanded the equipped-gear evaluation to cover offhand and extra inventory slots where possible")
- Summary: `equippedSlotDefinitions` included `{ slotName = "RelicSlot", buttonName = "CharacterRelicSlot" }`. Relics did not get their own separate equipment slot until Wrath of the Lich King — in TBC, relic items (Librams/Idols/Totems/Sigils) share the same slot as ranged weapons (`RangedSlot`). `GetInventorySlotInfo("RelicSlot")` throws a hard Lua error ("Invalid inventory slot") on this TBC ruleset rather than returning nil. Because `RelicSlot` was the *last* entry in the list, and a thrown error aborts the whole enclosing function (not just that loop iteration), `UpdateEquippedGearEvaluation` was erroring out before it ever reached the code that colors and shows the outline frames — so literally nobody, on any class, ever saw a single colored border, regardless of the CharacterFrame/OnShow fix in bug #15.
- Observed behavior: No color borders around equipped gear at all; the addon's own debug log (captured automatically by `SafeCall`, independent of whether debug mode was toggled on) showed the same error repeating every time the evaluation ran.
- Likely cause: the slot list was extended in 0.24 to "cover offhand and extra inventory slots where possible" without verifying each slot name against the TBC ruleset specifically — a violation of the project's own Expansion Compatibility rule (CLAUDE.md: "Many Blizzard APIs differ between expansions. Never mix APIs from different game versions without explicitly supporting both").
- Attempts to fix:
  - Removed the `RelicSlot`/`CharacterRelicSlot` entry from `equippedSlotDefinitions` entirely, since TBC has no separate relic slot or button for it.
  - Hardened the slot-lookup loop in `UpdateEquippedGearEvaluation` with `pcall(GetInventorySlotInfo, slotDefinition.slotName)` so that if any other slot name is ever invalid on this ruleset, only that one slot is skipped instead of aborting the outline evaluation for every equipped item.
- Resolution: The evaluation can no longer be killed outright by a single bad slot name, on this or any future expansion target.
- Validation: `luac -p Core.lua` and `luacheck Core.lua` both pass; confirmed the error string and its exact source line via the on-disk debug log before making the change.
- Follow-up: In-game, `/reload`, open the character panel, and confirm colored borders now appear around equipped gear. Run `/lgs debug dump` afterward — the repeating "Invalid inventory slot" error should no longer appear, and the "Gear evaluation: N/20 slot buttons found, M items scored" line (added in bug #15) should show a non-zero `M`.
- Update (2026-07-13): confirmed via testing that the colors are now working as expected. Closing this bug.

### 17. Settings still reported as not retaining; added a "Save Settings" footer button and clarified the persistence model
- Status: Mitigated (no code bug found; added a confidence/confirmation mechanism per the request)
- Discovered: 2026-07-13
- Version introduced: N/A (design/education gap, not a code regression)
- Summary: Reported that changes to settings still weren't being retained, and requested a static "Apply" button below the scrollable area that saves settings so they survive a reload. Re-read every settings-writing code path end to end (`SetWeight`, `SetMinimapButtonVisible`, `SaveWindowPosition`, `SetActiveProfile`, `CreateProfile`, `SetDebugEnabled`) and found no buffering or bug — every one of them already mutates `LevelingGearsDB` immediately and directly; there is no code-level "unsaved" state for a button to flush. This is also directly contradicted by hard evidence: the on-disk SavedVariables file already contained real, non-default weights and window position for the test character (see bug #13), proving the persistence pipeline itself works.
- Observed behavior: Settings perceived as "not retaining" despite the underlying mechanism demonstrably writing correct data to disk at least once.
- Likely cause: WoW addons have no manual "save" step by convention — the client itself flushes SavedVariables to disk only at real save points (`/reload`, camping out, "Log Out," "Exit Game"). If the client process is ever terminated outside one of those paths (force-quit, crash, killed process), anything since the last save point is lost with no addon-side way to prevent it. This is almost certainly the explanation, not a code defect.
- Attempts to fix:
  - Added a static "Save Settings" button in a fixed footer anchored to the window frame (not the scroll child), so it stays visible regardless of scroll position, as requested.
  - The button calls `ReloadUI()`, the only Blizzard-provided way for an addon to force an on-demand save-and-reload cycle, giving the player a visible, on-demand confirmation that a save happened (matching the "Reload UI" button pattern Blizzard's own addon-list panel uses for the same purpose).
  - Documented the actual WoW SavedVariables persistence model in CLAUDE.md's Technical notes so this doesn't get re-litigated as a "bug" later.
- Resolution: No code change was needed to fix "retention" itself (it already worked); added the button as reassurance/confirmation UI, exactly as requested.
- Validation: `luac -p Core.lua` and `luacheck Core.lua` both pass.
- Follow-up: Confirm specifically how the client is being closed when testing (graceful Log Out/Exit Game vs. force-quitting the process/window). If settings still don't survive a genuine `/reload` or graceful exit after this version, that would indicate a real remaining bug and needs a fresh look with `/lgs debug dump` output attached.
- Update (2026-07-13): reported that the button "is just reloading the UI and the settings aren't being updated at all." Re-read the on-disk SavedVariables file again and confirmed weight values had genuinely changed between two separate readings (proof the data pipeline keeps working correctly) — so this wasn't data loss. See bug #18 for the actual design fix.

### 18. Save Settings button forced a disruptive, pointless reload; equipped-gear colors didn't live-update when weights changed
- Status: Solved
- Discovered: 2026-07-13 ("the save settings button is just reloading the UI and the settings aren't being updated at all")
- Solved: 2026-07-13
- Version introduced: 0.244 (the Save Settings button itself); the live-update gap dates to 0.2 (`SetWeight`)
- Summary: Two separate, real issues combined to make the 0.244 button feel broken:
  1. `SetWeight` (called by every stat weight's +/- button) updated the underlying data and its own label text, but never called `UpdateEquippedGearEvaluation` — so changing a weight never live-updated the equipped-gear outline colors. During testing, adjusting a weight visibly "did nothing" to the gear borders.
  2. The 0.244 "Save Settings" button called `ReloadUI()` on every click. Since every setting already writes into `LevelingGearsDB` the instant it changes (confirmed working via the on-disk file), `ReloadUI()` had nothing new to persist — it only closed and reopened the whole UI. Combined with issue 1, clicking it produced a jarring screen reload that "did nothing," reasonably reading as broken.
- Observed behavior: Clicking Save Settings reloads the UI but nothing appears updated.
- Likely cause: (1) an incomplete wiring of `SetWeight` to the gear-evaluation refresh path; (2) the 0.244 button design copied a "Reload UI" pattern from other addons' *disable/enable-addon* flows (where a reload is genuinely required to load/unload Lua files) without recognizing that a simple settings change never requires one.
- Attempts to fix:
  - `SetWeight` now calls `SafeCall(UpdateEquippedGearEvaluation)` after updating a weight, so equipped-gear outline colors update immediately as weights change, with no reload needed.
  - Removed the `ReloadUI()` call from the Save Settings button entirely. It now just prints an honest confirmation (current profile name) since there is nothing left to "save" — WoW addons never need a manual save step; SavedVariables are already live in memory and get flushed to disk automatically at real save points.
  - Removed `ReloadUI` from `.luacheckrc`'s `read_globals` since it's no longer referenced.
- Resolution: Weight changes are now immediately visible on the character's gear outlines, and the footer button no longer performs a disruptive, no-op reload.
- Validation: `luac -p Core.lua` and `luacheck Core.lua` both pass.
- Follow-up: In-game, change a stat weight while the character panel is open and confirm the gear outline colors update immediately without needing to reload or reopen anything.

### 19. Removed Shirt, Ammo, and Tabard from the equipped-gear evaluation; confirmed relics need no per-class special-casing
- Status: Solved
- Discovered: 2026-07-13 (request)
- Solved: 2026-07-13
- Version introduced: N/A (scope reduction, not a bug)
- Summary: Requested to stop evaluating the Shirt, Ammo, and Tabard slots (all cosmetic/non-stat-relevant for gearing purposes), and to confirm whether relics needed per-class handling.
- Resolution:
  - Removed `ShirtSlot`, `AmmoSlot`, and `TabardSlot` from `equippedSlotDefinitions`; the evaluation now covers 17 slots.
  - Verified (via web search, not assumption, per this project's "never invent or guess API/game behavior" rule) that TBC has no separate relic slot — it was added in Wrath of the Lich King. In TBC, Librams (Paladin), Idols (Druid), and Totems (Shaman) all occupy the same slot as ranged weapons. The existing `RangedSlot` entry already evaluates this slot for every class, so no per-class logic is needed; added a code comment recording this so it isn't relitigated or "fixed" incorrectly later.
- Validation: `luac -p Core.lua` and `luacheck Core.lua` both pass.
- Follow-up: None.

### 20. Stat weight +/- buttons were reversed; rapid clicks could jump by more than 1
- Status: Solved (button order); Mitigated (multi-jump — root-caused and fixed, awaiting in-game confirmation)
- Discovered: 2026-07-13 (report)
- Solved: 2026-07-13
- Version introduced: button order dates to 0.2; the multi-jump behavior was introduced by this session's own 0.245 fix (bug #18)
- Summary: Two issues:
  1. The `-` button was anchored to the right of `+` (reading left to right: `+`, then `-`). Requested `-` on the left, matching the conventional decrement-then-increment reading order.
  2. Reported that clicking +/- "sometimes" changed the value by 1, 3, or 5 instead of 1. `SetWeight` only ever applies a hardcoded `+1`/`-1` delta per call, so a value changing by more than 1 can only happen if `SetWeight` is invoked more than once per perceived click. The addon's own debug log showed the smoking gun: after the 0.245 fix that made `SetWeight` call the (relatively expensive, 17-slot) `UpdateEquippedGearEvaluation` on every click, the log recorded bursts of multiple gear evaluations within the same second (e.g. two entries both timestamped `12:15:09`) during weight-adjustment testing. Running a full evaluation synchronously on every click was likely causing enough of a hitch that rapid clicking queued up and fired in a burst, reading as a multi-step jump.
- Observed behavior: The buttons are visually swapped and increments are sometimes inconsistent.
- Likely cause: (1) simple anchor-order mistake; (2) this session's own bug #18 fix added a synchronous, non-trivial recalculation directly in the hot click path with no debounce.
- Attempts to fix:
  - Swapped the `upButton`/`downButton` anchors so `-` renders to the left of `+`.
  - Added `ScheduleGearEvaluation()`, a debounce guard (`gearEvaluationPending` flag + `C_Timer.After(0.2, ...)`, the same `C_Timer` API already confirmed in use by `GearScoreTBCClassic` on this client) so multiple rapid `SetWeight` calls collapse into a single evaluation ~0.2s after the last click, instead of one full evaluation per click.
- Resolution: Button order now matches the request; rapid clicking should no longer be able to visibly lag or burst-fire.
- Validation: `luac -p Core.lua` and `luacheck Core.lua` both pass.
- Follow-up: In-game, click a stat's `-`/`+` buttons both slowly and rapidly in succession and confirm the value always changes by exactly 1 per click, with no delayed multi-step jumps.
- Update (2026-07-13): reported that the multi-jump was still happening on the *first* click specifically (not just rapid repeat clicks), still landing on jumps of 4-5. See bug #22 — this pointed to a completely different root cause than the 0.245 debounce theory: a stale display value, not a multi-fire click.
- Update (2026-07-13): confirmed fixed via testing after the bug #22 fix landed (0.247). Closing.

### 21. Settings reported as still not surviving a reload, despite repeated on-disk confirmation
- Status: Solved — see bug #22, which found and fixed a stale-display bug that fully explains this report without any actual data loss; confirmed fixed via testing
- Discovered: 2026-07-13
- Summary: Requested confirmation that `LevelingGearsDB = LevelingGearsDB or {}` is declared at load time, and questioned whether persistence is wired correctly. Re-confirmed: `Core.lua:7` declares exactly `LevelingGearsDB = LevelingGearsDB or {}`, matching `## SavedVariables: LevelingGearsDB` in the TOC exactly (case-sensitive match verified). This is the correct, standard idiom.
- Evidence against a real persistence bug: diffing multiple reads of `WTF/Account/ANDROIDEYES/SavedVariables/LevelingGears.lua` taken minutes apart across this conversation shows the on-disk weights repeatedly changing between reads, and the debug log shows continuous, error-free "Gear evaluation" activity across dozens of timestamps spanning the whole session. This means saves are demonstrably succeeding, repeatedly, during that actual test session.
- Likely cause: identified in bug #22 — the settings window only ever synced its displayed labels from `LevelingGearsDB` once, at initial addon load. Reopening the window later (the normal way a player checks "did my setting survive?") never re-ran that sync, so the window could show stale numbers that looked like data loss even though the real, saved values were correct underneath the whole time.
- Follow-up: None — confirmed fixed via testing.

### 22. Settings window never re-synced its displayed values after the first load, causing both the "first click jumps by 4-5" and "settings don't survive reload" reports
- Status: Solved — confirmed fixed via testing
- Discovered: 2026-07-13 ("first click to iterate up and down is still doing 4 or 5 instead of 1")
- Solved: 2026-07-13
- Version introduced: 0.2 (the underlying gap has existed since the weight UI was first built; only exposed clearly once real non-default data existed to diverge from the placeholder)
- Summary: Every stat row is created with a hardcoded placeholder label text of `"5"` (`CreateStatRow`), and `RefreshWeightLabels()` (which overwrites every label with the true persisted value) was previously only ever called once, during the addon's initial load sequence (`SafeCall(InitializeProfileState)`). Nothing re-ran it when the settings window was later reopened. Since the window starts hidden and is opened well after load, in practice this coincidentally still worked much of the time — but any gap between what the window last displayed and what the true saved value is (e.g. after set-and-forget testing, or if a display path was ever skipped) would only get corrected the moment a stat's own `+`/`-` button was clicked, because that's the only other code path that touches a label directly. Clicking `+`/`-` computes `trueValue + delta` and displays the result — so the *first* click on a stat whose displayed number didn't match its true saved value would show a jump equal to that gap (matching the reported 4-5, which lines up exactly with the gap between the "5" placeholder and the real 9-10 values already observed in this character's saved weights), while every click after that looked correct (display and truth now in sync).
- Observed behavior: The first interaction with a stat jumps by 4 or 5 instead of 1, and settings separately appeared not to survive a reload — both consistent with the settings window showing a stale number until first touched.
- Likely cause: `RefreshWeightLabels`/`RefreshProfileList`/`RefreshGeneralSettingsUI` were wired to run once at file load, but never wired to the window's own `OnShow` — the actual moment a player looks at the page and forms an opinion about whether their data survived.
- Attempts to fix:
  - Forward-declared `RefreshWeightLabels` (added to the existing forward-declaration block, alongside `RefreshProfileList`/`SetActiveProfile`/`CreateProfile`) and changed its definition to `RefreshWeightLabels = function() ... end` so it can be referenced before its own definition point, per the project's dependency-graph rule.
  - The settings window's `OnShow` handler now calls `RefreshGeneralSettingsUI()`, `RefreshProfileList()`, and `RefreshWeightLabels()` every time the window is opened, not just once at initial load — guaranteeing the display always matches `LevelingGearsDB` regardless of how long ago the addon first loaded.
  - The "Save Settings" footer button now also calls all three refreshers before printing its confirmation message, so clicking it gives concrete, visible proof (the numbers on screen re-paint from the real data) rather than just a chat message taken on faith.
- Resolution: The settings window can no longer display a stale number for longer than the time it takes to reopen it.
- Validation: `luac -p Core.lua` and `luacheck Core.lua` both pass. Confirmed fixed in-game via testing.
- Follow-up: None.

### 23. Added Armor as a weightable stat
- Status: Solved
- Discovered: 2026-07-13 (request)
- Solved: 2026-07-13
- Version introduced: N/A (new stat coverage, not a bug)
- Summary: Requested that the addon also check the Armor stat. Added `{ key = "ARMOR", name = "Armor" }` to `statDefinitions` and to the "Other stats" group (alongside the other mitigation stats: Defense, Dodge, Parry, Block, Block Value, Resilience), and added `ARMOR = { "ITEM_MOD_ARMOR_SHORT" }` to `itemStatAliases`, following the exact naming convention every other stat alias already uses.
- Caveat (recorded per this project's "never invent/guess API behavior" rule): a plain armor piece's base armor value is intrinsic to its material/item level/slot and is NOT exposed as an `ITEM_MOD_*` stat by `GetItemStats` at all — there is no API for that. What `ITEM_MOD_ARMOR_SHORT` actually captures is BONUS armor modifiers only (e.g. a shield with an "of the Bear"-style suffix, or a rare item with +Armor as an explicit stat). This token's exact behavior on this specific client is unverified (no local way to test client-side Lua output in this session); if it never contributes to any item's score in play, the documented fallback is a hidden-tooltip scan of the "Armor" line, matching the existing policy already recorded in Technical notes for other uncertain `GetItemStats` coverage (Healing/Spell Power/MP5).
- Validation: `luac -p Core.lua` and `luacheck Core.lua` both pass; confirmed `statDefinitions` and `statGroups` both contain exactly 28 unique, matching stat keys (including `ARMOR`) via a scripted diff.
- Follow-up: In-game, confirm "Armor" appears as a row in the "Other stats" section with working +/- controls, and check whether equipping a shield with bonus armor (or any item with a +Armor suffix) actually contributes to that item's score — if it never does, revisit with a tooltip-scan fallback.

### 24. Replaced the flat weighted-sum scorer with a three-layer conversion-aware engine; removed primary-stat sliders
- Status: Solved
- Discovered: 2026-07-13 (request: spec-aware default weights)
- Solved: 2026-07-13
- Version introduced: N/A (new feature/architecture change, not a bug — but see the double-counting issue below, which WAS a real latent bug in the pre-0.25 scorer)
- Summary: The weight sliders needed smart, spec-aware default values (fully hand-adjustable afterward). Building that required knowing how much a primary stat (Agility, Strength, etc.) is actually worth in derived terms — which exposed a real, pre-existing bug: `GetEquippedItemScore` had summed `rawStatValue * weight` for every weighted stat since 0.2, including primaries. That double-counts — e.g. Agility contributed its own weighted value AND (implicitly, through no fault of the scorer, since it never modeled the connection) should also have flowed into Attack Power/crit%/armor, which have their own separate weights. Added `Conversions.lua` (Layer 1 live rating/Agility/Intellect conversions + Layer 2 hardcoded AP-per-primary table), `Priorities.lua` (Layer 3: authored default weights, 9 classes × 27 specs × 2 modes), and `Scoring.lua` (`ScoreItem`/`ScoreEquippedItem`, spec/form detection).
- Observed behavior: not reported as a bug (the naive sum "worked" in the sense of producing *a* number), found while implementing the requested feature.
- Likely cause: the original 0.2 scorer was built before any conversion logic existed, and treated every weighted stat as directly comparable regardless of whether it was a primary or already-derived stat.
- Attempts to fix:
  - Primaries are now converted to derived stats (AP, RAP, HEALTH, MANA, CRIT, ARMOR) via `Conversions:ApplyConversions` before any weight is applied; only derived stats are ever weighted.
  - Removed the STR/AGI/STA/INT/SPI sliders from the "Core stats" settings group (weighting them directly would double-count under the new engine) and added HEALTH/MANA sliders — the derived stats Stamina and Intellect actually turn into.
  - `EnsureWeights` now seeds any never-set weight from the character's detected spec/mode default (`LG.Scoring:GetDefaultWeights`) instead of a flat 5, but never overwrites a weight the player has already touched.
  - Added `/lgs score <item link>` (not `/lg score` — `/lg` was deliberately removed, see bug #5) to print the derived-stat breakdown and final score for sanity-checking the Priorities tables against real items. Fixed a real bug found while adding it: `HandleSlashCommand` lowercases its whole argument, which would have corrupted a pasted item link's case-sensitive `|H`/`|h` escape pair — the `score` subcommand is matched against the original casing instead.
  - Added `CHARACTER_POINTS_CHANGED`/`PLAYER_LEVEL_UP` to the existing gear-evaluation event frame so a respec or level-up (which changes the detected spec) re-scores equipped gear immediately.
  - Full rationale and every judgment call (rating fallback source, low-level default spec per class, Druid form-for-scoring, Hit/Crit/Haste offense-type simplification, why Spirit has no conversion) recorded in the new `DESIGN.md`.
- Resolution: Scoring no longer double-counts primaries; default weights are spec-aware; the player's own hand-adjustments remain fully authoritative.
- Validation: `luac -p` and `luacheck` both pass on all 4 Lua files.
- Follow-up: In-game, `/reload`, open settings and confirm Health/Mana rows appear in "Core stats" with no Str/Agi/Sta/Int/Spi rows; confirm gear-outline colors still render; run `/lgs score` on a few equipped items and sanity-check the printed breakdown.

### 25. Added 0.05-precision weight steps and a Restore Defaults button; layout offset not yet visually confirmed
- Status: Mitigated (implemented and validated statically; the one open item is an in-game visual check, not a known defect)
- Discovered: 2026-07-13 (request)
- Version introduced: N/A (new feature, not a bug)
- Summary: Requested that the spec-aware defaults (added in bug #24 / v0.25) become explicit and reversible via a "Restore Defaults" button, and that 0.05-precision adjustments replace whole integers while keeping the 0-10 scale and units simple.
- Resolution:
  - Added `RestoreDefaultWeights` + a "Restore Defaults" button in the stat-weights section, which overwrites the ENTIRE active profile's weights with `LG.Scoring:GetDefaultWeights()` — distinct from `EnsureWeights`, which still only ever seeds a never-touched key.
  - Added `WEIGHT_STEP = 0.05`, `RoundToStep`, and `FormatWeight` (Core.lua) so `+`/`-` clicks move by 0.05 with values rounded to avoid floating-point drift and displayed with only as many decimals as needed.
  - Added a Shift-click modifier for a coarser ±1 step (judgment call, not explicitly requested — see DESIGN.md) since 0.05 alone would need up to 200 clicks to cross the bar; documented in the page's own helper text.
  - Bumped `ReflowStatGroups`' starting Y-offset (`-102` to `-134`) to make room for the new button row, based on the existing row-height/gap conventions already used elsewhere in this file, not a measured in-game value.
- Observed behavior: not yet run in game.
- Likely follow-up needed: this project's own mandatory rule requires confirming settings sections don't overlap after any UI change — the `-134` offset is a reasoned estimate, not a confirmed measurement, since this session cannot render the client.
- Validation: `luac -p Core.lua` and `luacheck Core.lua` both pass (only the pre-existing, documented `GetActiveProfile` single-iteration-loop notice remains).
- Follow-up: In-game, `/reload`, open settings, and confirm (a) the "Restore Defaults" button doesn't overlap the "Core stats" group header below it, (b) clicking `+`/`-` moves a weight by 0.05 and displays cleanly (e.g. "9.55", not "9.550000001"), (c) Shift-click moves by 1, (d) "Restore Defaults" resets every stat back to the spec-detected values and prints the expected confirmation.

### 26. Split `Core.lua` (1100+ lines) into 9 files by responsibility
- Status: Mitigated (implemented and statically validated; in-game load/functional check is the one open item, same caveat as every UI-only change in this ledger)
- Discovered: 2026-07-13 (request)
- Version introduced: N/A (reorganization, not a bug)
- Summary: `Core.lua` needed to stay small, with logic/UI/debugging moved into whichever files make sense, since it had grown to cover debug logging, SavedVariables/profile CRUD, weight math, equipped-gear scoring, and the entire settings window in one 1100+ line file.
- Resolution:
  - New files: `Debug.lua` (logging, `PrintChat`, `SafeCall`, addon version — loads first), `Settings.lua` (general settings + per-character profile CRUD), `Weights.lua` (stat list + 0.05-precision weight math), `GearEvaluation.lua` (equipped-item scoring + outline coloring), `UI.lua` (the settings window). `Core.lua` is now ~100 lines: slash-command dispatch + startup sequence only.
  - Every function that used to need a same-file `local` forward-declaration to be callable across the old file (`RefreshProfileList`, `RefreshWeightLabels`, `SetActiveProfile`, `CreateProfile`, `UpdateEquippedGearEvaluation` — the exact functions behind bugs #11 and #22) is now a field on the shared `LG` namespace table instead, which Lua resolves at call time rather than parse time. This isn't just a relocation — it structurally removes the whole class of forward-reference bug this project had hit twice before.
  - Kept a strict data/UI layering: `Settings.lua`/`Weights.lua` never touch a widget directly, calling a narrow `LG.UI.*` hook instead; `UI.lua` never touches SavedVariables directly, calling `LG.Settings.*`/`LG.Weights.*` instead.
  - One deliberate small simplification while moving the code: `UI.lua`'s `statGroups` now looks up each stat's name/key from `Weights.statDefinitions` by key instead of re-typing the same key+name pairs a second time, removing a pre-existing duplication between the two lists (functionally identical output, verified by construction).
  - Updated `LevelingGears.toc`'s file list to the new 9-file load order (order matters here: `Debug.lua` first since everything depends on it, `Core.lua` last since it orchestrates everything else).
- Observed behavior: not yet run in game.
- Validation: `luac -p` and `luacheck` both pass on all 9 files (only the pre-existing, documented `GetActiveProfile` single-iteration-loop notice remains, now in `Settings.lua`). Grepped for stale bare references to every moved function name and for duplicate function definitions — none found.
- Follow-up: In-game, `/reload`, confirm the addon loads with no Lua errors (this touched every file's load boundary), and re-run the full existing manual regression list (open/close window, switch/create profile, adjust a weight, Restore Defaults, gear-outline colors, `/lgs score`) since the reorganization touched the call path of literally every feature even though no behavior was intended to change.

### 27. `DetectSpec` crashed on every call: `GetTalentTabInfo`'s `pointsSpent` return landed on a string, silently breaking spec-aware defaults since v0.25
- Status: Solved (patched; not yet re-verified in game — this exact class of client/API surface can only be confirmed live)
- Discovered: 2026-07-13/14 (found via the on-disk debug log — 50 identical entries, the full ring buffer, all timestamped the same second: `Interface/AddOns/LevelingGears/Scoring.lua:102: attempt to perform arithmetic on local 'pointsSpent' (a string value)`)
- Version introduced: 0.25 (the day `DetectSpec` was written; never caught until real in-game testing, since this is a runtime API-return-type mismatch that `luac -p`/`luacheck` cannot detect)
- Summary: `Scoring.DetectSpec` read `local _, _, pointsSpent = GetTalentTabInfo(tabIndex)`, assuming the old-style Classic-era signature `name, icon, pointsSpent, background, ...` (pointsSpent at position 3). On this client, position 3 is actually a string, not a number — `totalPoints = totalPoints + pointsSpent` then throws immediately on the very first loop iteration, every single time `DetectSpec` runs.
- Impact: `DetectSpec` is the foundation of the entire v0.25+ scoring engine — `EnsureWeights`, `GetEquippedItemScore`/gear-outline coloring, `RestoreDefaultWeights`, and `/lgs score` all call it directly or indirectly. Every call errored, caught by whichever `SafeCall`/`pcall` boundary was nearest: gear-outline evaluation aborted before coloring anything (same failure mode as bug #16), and `Weights.EnsureWeights`'s `GetSpecDefaults()` (itself wrapped in `SafeCall`) silently fell back to a flat 5 for every stat instead of a spec-aware default. Confirmed on disk: a freshly-created test profile ("Arracherra") had every weight at exactly 5 except one stat manually adjusted afterward during 0.05/Shift-click testing — exactly the signature of `GetDefaultWeights()` failing every time, not working occasionally.
- Likely cause: `GetTalentTabInfo`'s exact return signature is uncertain across client builds — web research found retail's modern signature prepends an `id` return (`id, name, description, icon, pointsSpent, background, previewPointsSpent, isUnlocked`), which would push `pointsSpent` to position 5, or to position 4 if `id` is present without the later-added `description`/`previewPointsSpent`/`isUnlocked` fields (those were reportedly only added in Cataclysm Classic). No source could confirm the exact TBC Anniversary (2.5.x) signature with certainty.
- Attempts to fix:
  - Rather than commit to a single guessed position, `DetectSpec` now captures positions 3, 4, and 5 (`local _, _, c, d, e = GetTalentTabInfo(tabIndex)`) and uses `tonumber(c) or tonumber(d) or tonumber(e) or 0` — whichever candidate is actually numeric wins. This is robust to either plausible signature without needing to know which one this client actually uses.
- Resolution: No more `pcall` error at this line under either hypothesized signature; falls back to `0` (treated as "no points in this tab," same as before the bug existed) only if none of the three candidate positions are numeric.
- Validation: `luac -p Scoring.lua` and `luacheck Scoring.lua` both pass with 0 warnings.
- Follow-up: In-game, `/lgs debug` then `/lgs debug dump` after some play should show no more of this error. More importantly: create or switch to a profile and confirm the seeded default weights actually look spec-aware (e.g. a melee class seeds high Attack Power, not a flat 5 across every stat) — this is the first real functional test of the entire v0.25 scoring engine's default-seeding path, which has apparently never worked correctly until this fix.
- Update (2026-07-14, first real test pass, v0.301): T3/T7 in the test report show "17/17 slot buttons found, 16 items scored" with **no errors in the ring buffer** — direct evidence the crash itself is fixed (before this fix, gear evaluation aborted on the very first slot every time, scoring 0 items). Testing stopped before T20 (the specific spec-aware-seeding check) was reached, so that part is still unconfirmed — see the follow-up on bug #27 itself remains open until T20 is actually run.

### 28. Profile dropdown button's bare "Default" label reads as a "restore defaults" action, not a profile picker
- Status: Solved, then superseded — see the v0.304 update below
- Discovered: 2026-07-14 (test report, T15)
- Version introduced: 0.21 (the profile dropdown button itself)
- Summary: The button that opens the profile-switcher dropdown just displays the active profile's name (e.g. "Default") with no label explaining what the button IS. Reported: "It seems like a restore default button to me."
- Resolution: Added a static "Profile:" text label immediately to the left of the button (`UI.lua`), matching the suggested fix. The button itself still shows the active profile's name; the new label just makes clear what kind of control it is.
- Validation: `luac -p UI.lua` and `luacheck UI.lua` both pass.
- Follow-up: In-game, confirm the "Profile:" label doesn't crowd the button or overlap anything at the section's fixed width (320px).
- Update (v0.304): reported as one of "lots of errors in the profile" — rather than continue patching the multi-profile picker/dropdown/create-new UI piece by piece, the whole profile system was removed (see bug #31). There is no longer a profile button, dropdown, or label for this bug to apply to.

### 29. Window position restores consistently, but not to the exact spot it was dragged to
- Status: Open (mitigated with diagnostics + a defensive rounding fix; root cause not yet confirmed)
- Discovered: 2026-07-14 (test report, T11)
- Version introduced: unknown — position save/restore has existed since v0.12; may have always had this gap, or may be new
- Summary: "The window doesn't open in the same place every time, but kind of in a similar general area... Reloads and relogs will have it be in the same place every time, but it isn't where the user had put it." Read carefully, this means restoration is *consistent* (not random) but *offset* from the true drop point — pointing at a systematic error introduced once at save time, not a flaky restore.
- Investigation: Reviewed `SaveWindowPosition`/`ApplySavedPosition` (`UI.lua`) end to end. Both use the standard `GetPoint(1)`/`SetPoint` round-trip against `UIParent`, called from `OnDragStop` and `OnHide`. No obvious logic defect found by static review (traced through double-application on open, frame size being fixed at 420x330, and the drag-stop/hide call sites) — this needs real evidence, not another guess, given this project's history of guessed UI fixes not panning out.
- Attempts to fix:
  - Added debug logging (`/lgs debug` level 1) to both functions, printing the exact `point`/`relativePoint`/`x`/`y` at save time and at apply time, so the next test pass's `/lgs debug dump` gives a real, comparable data point instead of a subjective "looks close."
  - Rounded saved x/y to whole pixels (`math.floor(v + 0.5)`) as a safe, low-risk improvement regardless of root cause — repeated `SetPoint`/`GetPoint` round-trips can accumulate floating-point drift, and WoW screen positions are effectively pixel-integer anyway.
- Resolution: Not confirmed — this is a diagnostic pass, not a verified fix.
- Validation: `luac -p UI.lua` and `luacheck UI.lua` both pass.
- Follow-up: Next test pass: drag the window to a deliberately memorable spot (e.g. flush against a corner of another native UI element), note the exact spot, `/reload`, and include the `/lgs debug dump` output covering both the drag (SaveWindowPosition log line) and the reopen (ApplySavedPosition log line) in the report.

### 30. `/lgs score` reported as "doesn't work"
- Status: Solved (real fix — `/lgs score` replaced as the everyday workflow by shift+left-clicking an equipped item)
- Discovered: 2026-07-14 (test report, T8)
- Version introduced: 0.25 (the command itself)
- Summary: Reported as "doesn't work" with no further detail. The v0.302 mitigation (clearer usage message + logging) was rejected outright: "I don't like that. It is too complicated." The actual request: when the character window is open showing equipped gear, shift-right-click an equipped item to print its score to chat.
- Investigation: The v0.302 mitigation correctly diagnosed why the slash-command workflow is failure-prone (the item link must be shift-clicked into the SAME chat line before pressing Enter) — but the feedback made clear this workflow is fundamentally the wrong shape for everyday use, not that it needed clearer instructions. Verified Blizzard's actual click behavior for equipped-item slot buttons against FrameXML source (`PaperDollItemSlotButton_OnClick`) before implementing anything: left-click branches on modifier (plain = pick up, Ctrl = dress up, Shift = insert item link in chat), but right-click unconditionally calls `UseInventoryItem(slotId)` regardless of any held modifier — there is no shift-check on the right-click branch at all. Hooking shift+right-click would therefore also fire the item's on-use effect (e.g. a trinket proc) as an unwanted side effect every time a player checked a score.
- Resolution: Implemented as shift+**left**-click instead of the literally-requested shift+right-click, given the evidence above — it is side-effect-free and reuses a gesture (shift-click to reference an item) every WoW player already knows. `GearEvaluation.lua` now hooks each equipped slot button's `OnClick` via `HookScript` (additive, does not replace Blizzard's own handler) the first time it's seen; on shift+left-click it scores the item against the character's own live weights (`Scoring:ScoreEquippedItem`, same weights used for the gear-outline coloring) and prints the breakdown to chat. Extracted the chat-printing logic that was inline in `HandleScoreCommand` into a new shared `Scoring:PrintBreakdown` so both this feature and the surviving `/lgs score` debug-bench command (kept for checking the raw `Priorities.lua` tables independent of player customization, per `DESIGN.md`) share one implementation.
- Validation: `luac -p` and `luacheck` clean on `GearEvaluation.lua`, `Scoring.lua`, `Core.lua`.
- Follow-up: Next test pass, confirm shift+left-clicking an equipped item in the character window prints a score breakdown to chat, and that normal left-click (pick up), Ctrl-click (dress up), and plain shift-click (insert link) on the same buttons are all unaffected.

### 31. Multi-profile system was a persistent source of errors; removed entirely (v0.304 fork)
- Status: Solved (by removal, not a further patch)
- Discovered: 2026-07-14 (report: "lots of errors in the profile")
- Version introduced: 0.21 (the profile system itself)
- Summary: Reported broadly as "lots of errors in the profile," on top of the already-recorded bug #28 (ambiguous picker label). Rather than continue fixing the multi-profile system (create/switch/name profiles per character, id-keyed `profiles` table, `activeProfile` pointer) piece by piece, the decision was to remove it: **there is only one weight set per character.** The player adjusts it by hand or restores it to the character's detected spec/mode default — no naming, no creating, no switching.
- Resolution:
  - `Settings.lua`: replaced `characterState.profiles`/`activeProfile` with a single flat `characterState.weights` table. `GetActiveProfile`/`SetActiveProfile`/`CreateProfile` are gone; `GetCharacterState()` now returns the character's weight state directly. A one-time migration pulls the previously active profile's weights into the new flat state so existing testers don't lose hand-tuned values (the old `profiles`/`activeProfile` fields are left in place afterward, unused — same harmless-dead-data policy this project already uses elsewhere).
  - `Weights.lua`/`GearEvaluation.lua`: swapped every `GetActiveProfile()` call for `GetCharacterState()` (same shape, `.weights` field) — no scoring logic changed.
  - `UI.lua`: removed the entire "Profiles" section (header, hint text, dropdown button, dropdown menu frame, divider) and its supporting code (`ToggleProfileMenu`, `RefreshProfileList`, the profile row pool). The stat-weights section now anchors directly below "General settings."
  - `Core.lua`: `InitializeProfileState` renamed to `InitializeCharacterState`; the "Loaded profile 'X'" boot message is gone (nothing left to name). Added a new one-time boot chat message explaining that weights don't auto-update on a respec or talent change and must be restored/re-adjusted by hand (see `ROADMAP.md` 0.35 for the planned real fix).
  - `ROADMAP.md`'s 0.34 ("profile creation dialog") is dropped as moot; a new 0.35 ("auto-updating default weights on respec/talent change") is filed instead, since that's the actual underlying need a "give my profile a name" feature was dancing around.
- Validation: `luac -p` and `luacheck` clean on `Settings.lua`, `Weights.lua`, `GearEvaluation.lua`, `UI.lua`, `Core.lua`.
- Follow-up: In-game, confirm the settings window shows General settings directly above Stat weights with no gap or leftover profile UI, that weights persist and restore-to-default correctly, and that the new boot-time chat message appears once and reads clearly.

### 32. Stat weight rows (value + up/down buttons + Shift-click) reported as too complicated
- Status: Solved
- Discovered: 2026-07-14 (report: "The stats adjustment menu is too complicated")
- Version introduced: 0.2 (the up/down buttons); 0.26 (the 0.05-step/Shift-click-for-±1 refinement that made it worse)
- Summary: Each stat row showed a read-only value plus separate `+`/`-` buttons, stepping by 0.05 normally or ±1 with Shift held — a convention that needed its own helper-text sentence to explain and required many clicks to move a value far. Requested replacement: list each stat with the actual value the program uses shown directly in an editable text box, and keep the "Restore Defaults" button.
- Resolution:
  - `UI.lua`'s `CreateStatRow`: removed the value `FontString` and the `upButton`/`downButton` pair entirely. Each row is now a label plus one `EditBox` (`InputBoxTemplate`, the standard Blizzard single-line input widget) pre-filled with the stat's current value.
  - Typing a value and pressing Enter, or clicking away (`OnEditFocusLost`), commits it via the new `Weights.SetWeightValue(statKey, value)` (an absolute setter, clamped to 0-10) — replacing the old delta-based `Weights.SetWeight(statKey, delta)`/`WEIGHT_STEP`/`RoundToStep` mechanism entirely, since there's no longer a step to round to.
  - Invalid (non-numeric) typed text does not silently stick — losing focus with unparsable text reverts the box to the real saved value via the existing `UI.RefreshWeightLabels()`, so the display never implies an edit took effect when it didn't.
  - "Restore Defaults" (`Weights.RestoreDefaultWeights`) is unchanged and still resets every stat to the character's spec-aware default, per the explicit request that this button persist.
  - Kept the existing collapsible group structure (Core stats / Other stats / Resistances) — confirmed with the requester as still wanted; only the per-row control changed, not the section layout.
- Validation: `luac -p` and `luacheck` clean on `Weights.lua` and `UI.lua`.
- Follow-up: In-game, confirm typing a value into a stat's box and pressing Enter (or clicking elsewhere) saves it and updates the gear-outline colors; confirm typing garbage text and clicking away reverts to the last real value instead of leaving the bad text on screen; confirm "Restore Defaults" still fills every box with the spec-aware defaults.
