# PROGRESS.md — Leveling Gears

Chronological build history: current status, dated decisions, and the full per-version progress
log. This file only needs to be read when you need context on what's already been done, why a past
decision was made, or before writing a new entry after finishing a step. `CLAUDE.md` carries only
the current single most important next step — this file has everything behind it.

---

## Current status

- **Current step: 0.303 — bug #30's real fix: shift+left-click an equipped item to score it.**
  v0.302's usage-message mitigation for bug #30 was rejected outright as too complicated; the
  requested fix was direct: when the character window is open showing equipped gear, shift-click an
  equipped item to print its score to chat. Before implementing, verified Blizzard's real click
  behavior for equipped-item slot buttons against
  FrameXML source (`PaperDollItemSlotButton_OnClick`) rather than assuming: right-click unconditionally
  calls `UseInventoryItem(slotId)` regardless of any held modifier (no shift-check on that branch at
  all), so hooking shift+right-click would also risk firing an item's on-use effect (e.g. a trinket
  proc) as an unwanted side effect every time a player checked a score. Left-click already branches on
  Shift for its own existing "insert item link in chat" behavior, so implemented as **shift+left-click**
  instead — side-effect-free, and reuses a gesture every WoW player already knows. This is a deliberate
  evidence-based deviation from the original literal wording (shift+right-click).
  `GearEvaluation.lua` now hooks each equipped slot button's `OnClick` via `HookScript` (additive, does
  not replace Blizzard's own handler) the first time each button is seen; the hook scores the item
  against the player's live profile weights (`Scoring:ScoreEquippedItem`, same weights used for the
  gear-outline coloring) and prints the breakdown to chat. Extracted the shared chat-printing logic
  (previously inline in `Core.lua`'s `HandleScoreCommand`) into a new `Scoring:PrintBreakdown` so both
  this feature and the surviving `/lgs score` debug-bench command (kept for sanity-checking the raw
  `Priorities.lua` tables, per `DESIGN.md`) share one implementation. This pulls forward and closes
  `ROADMAP.md`'s previously-gated 0.33 item; see that file for the consequence to the future 0.6
  "suggest gear" flow (shift+left-click is no longer available as its trigger gesture). Bugs #28/#29
  are untouched from v0.302. `luac -p`/`luacheck` pass clean on all three touched files
  (`GearEvaluation.lua`, `Scoring.lua`, `Core.lua`). Full detail in `bugs/known-bugs.md` #30.
- **Previous step: 0.302 — processed the first real test report (T1-T15 of 35).** v0.301 was tested
  in game, `TEST_PLAN.md` filled in through T15, and testing stopped early on purpose after finding
  enough broken things to warrant fixing before continuing. Outcome — confirmed working: addon load, both
  slash commands, `/lgs debug`/`debug dump`, minimap toggle/click, window drag/Escape/close, scrolling
  with no overlap, and (important) bug #27's crash fix itself — gear evaluation now completes and
  scores items cleanly (16/17 slots, no errors), though T20's specific spec-aware-seeding check
  wasn't reached yet. Found and addressed: bug #28 (profile picker read as a "restore defaults"
  button — solved, added a "Profile:" label), bug #29 (window position restores consistently but not
  to the exact dragged spot — mitigated with diagnostic logging + pixel rounding, root cause still
  unconfirmed), bug #30 (`/lgs score` reported broken, no repro details captured — mitigated with a
  clearer usage message + logging, root cause still unconfirmed; **superseded by 0.303 above**). Also
  filed four new features in `ROADMAP.md`'s "Testing Phase 1 follow-ups" (0.31 minimap drag-to-
  reposition, 0.32 custom art, 0.33 shift-click item scoring, 0.34 a real profile-naming dialog) —
  explicitly not to be built until every current feature is confirmed working (0.33 was since pulled
  forward — see 0.303 above). `TEST_PLAN.md` updated so the next
  pass resumes at T1 (to re-confirm these fixes) and continues through T16-T35 (never reached last
  round). `luac -p`/`luacheck` pass on the two touched files (`UI.lua`, `Core.lua`). Full detail in
  `bugs/known-bugs.md` #28-#30.
- **Previous step: 0.301 — first Testing Phase 1 bugfix (bug #27)**, and **0.3 — "stable, reorganized
  baseline," entering Testing Phase 1** (the static conflict audit, the CLAUDE.md split, and
  `TESTERS.md`/`TEST_PLAN.md`'s original creation). See the Progress log below for full detail on
  both.

---

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
- **2026-07-13** — Repository committed (`e914633`, root commit) at v0.248; push deliberately
  skipped (no remote configured yet).
- **2026-07-13** — Built the v0.25 three-layer scoring engine per a fully-specified architecture
  provided up front (do not substitute a different design). Scoped as 0.25 (a new two-decimal
  sub-feature of the still-open 0.2 stat-weight milestone), not as pulling forward the 0.3
  database milestone — the versioning ladder reserves new two-decimal numbers exactly for "an
  actual new sub-feature of the current milestone." Every judgment call the brief asked for is
  recorded in `DESIGN.md`, not scattered across chat: rating fallback source, low-level default
  spec per class, Druid form-for-scoring, Hit/Crit/Haste offense-type simplification, why Spirit
  has no Layer 1 conversion, the `ScoreItem`/`ScoreEquippedItem` split, and the `/lgs score`
  (not `/lg score`) slash-command substitution.
- **2026-07-14** — Split `CLAUDE.md` (which had grown to ~800 lines, read in full on every command)
  into `PROGRESS.md` (this file), `ROADMAP.md`, and `CONVENTIONS.md`, leaving `CLAUDE.md` as a short
  index: current step + a table of which file to read for which kind of task. Goal is lower token
  usage per command without losing any recorded detail — this was a pure relocation, not a rewrite
  or summarization; every section moved verbatim to the file matching its purpose (history →
  PROGRESS.md, future plans → ROADMAP.md, standing rules → CONVENTIONS.md).
- **2026-07-14** — Reworded every reference to the project owner across the docs and code comments:
  the relationship with Claude Code is "user," but the relationship with the addon itself is
  author/designer — every prompt, decision, and much of the hand-editing is the author's own work.
  Changed "the user" (as project owner) to "the author" throughout `CLAUDE.md`, `CONVENTIONS.md`,
  `PROGRESS.md`, `ROADMAP.md`, `bugs/known-bugs.md`, and code comments; where a personal reference
  wasn't actually needed, removed it entirely (direct/impersonal phrasing instead); where text was
  about the addon's own future end-users (the WoW players who'll eventually install it, as distinct
  from the author), reworded to "player" instead, so "user" no longer does double duty for two
  different people across the doc set. Also, per an explicit request mid-task, wrote
  `DATA_PIPELINE.md`: verified (not guessed) download URLs, license status, and file structure for
  both `cmangos/tbc-db` (GPLv3, confirmed) and Questie's source Lua (no license found — flagged as
  an open blocker, not assumed resolved), plus a detailed parser design for `ROADMAP.md`'s 0.31-0.34
  steps; `ROADMAP.md` now points to it instead of carrying that detail inline.
- **2026-07-14** — Bumped to v0.3 and redefined what 0.3 means (was reserved for the data-schema
  milestone; now marks this stable, reorganized, about-to-be-tested baseline). The exact renumbering
  scheme for the roadmap required confirmation before touching it, since the collision affected
  version numbers with fixed meanings (Alpha/Beta/1.0) at the tail end — confirmed scheme: shift
  every milestone from the data-schema step onward up by one tick (0.3→0.4, 0.31-0.34→0.41-0.44,
  0.4→0.5, 0.5→0.6, 0.6→0.7, 0.7→0.8, 0.8→0.9, 0.9→0.91, stopping short of 1.0 so the shipped-release
  meaning stays intact). Applied that renumbering across `ROADMAP.md` and `DATA_PIPELINE.md`, and
  recorded the redefinition itself in `CONVENTIONS.md`'s versioning ladder rather than silently
  overriding an existing rule marked non-negotiable ("no matter how many bugfix/maintenance passes
  happen first").
- **2026-07-14** — Decided how tester findings actually get submitted: GitHub Issues, using two new
  issue templates (`.github/ISSUE_TEMPLATE/test-report.md`, `defect-report.md`) rather than an
  email/file-upload workflow. Reasoning: the repo is already public with Issues enabled (confirmed
  via the GitHub API, not assumed), so this needs zero new infrastructure and no git knowledge from
  testers — just a free GitHub account and a web form. This directly replaced an earlier, awkward
  instinct (renaming a filled-in `TEST_PLAN.md` copy and pushing/emailing it, which would have meant
  testers needing push access or the maintainer manually filing every submission by hand). The "Test
  report" template intentionally doesn't duplicate the checklist's instructional text (Instruction/
  Repeat/Expected) inline — that would drift from `TEST_PLAN.md` every time it's updated — it just
  provides Tester info/Summary bookends and a place to paste the completed T1-T35 results.
- **2026-07-14** — Reversed the GitHub Issues decision above: most actual testers are not experienced
  with GitHub (or git at all), so removed `.github/ISSUE_TEMPLATE/`
  entirely and switched to the simplest possible channel — download `TEST_PLAN.md`, fill it in with
  any plain text editor, rename it, email it to `wegatherinthesun@gmail.com`. Restructured
  `TEST_PLAN.md` around a "Quick start" at the very top so a tester needs to read roughly ten lines,
  not the whole document, to get going; moved the maintainer-only "keep this file current" process
  notes to a clearly-marked section at the bottom instead of the top, so testers don't have to
  scroll past them. Reframed `TESTERS.md` as explicitly optional reference material (severity
  levels, a more detailed defect template, environment nuances) rather than required onboarding —
  nothing in it is needed to complete a basic test pass. Updated `README.md` and `CLAUDE.md` to
  point testers at `TEST_PLAN.md` first instead of `TESTERS.md`.
- **2026-07-14** — Established how a completed test report from the project owner gets handled,
  since this was the first one received: it's treated as authoritative and actionable, not just
  informational. Confirmations get reflected in the ledger/history; real bugs get investigated and
  fixed or mitigated immediately (not just filed for later); new feature ideas get filed in
  `ROADMAP.md` at the next free two-decimal version slot (0.31 onward) but explicitly deferred — not
  built — until every currently-shipped feature is confirmed working. Where a
  bug's root cause couldn't be confirmed by static code review alone (bugs #29, #30), added targeted
  debug logging and asked for specific evidence (exact debug log excerpts) in the retest, rather than
  guessing at a fix the way earlier root-cause work in this project explicitly tried to avoid.
- **2026-07-14** — Refined how the project owner is referred to across the docs, following the
  2026-07-14 entry above that introduced "the author" terminology: outside of describing the project
  owner's own role/background (`CONVENTIONS.md`'s "Project owner" section) or a bug/decision record
  that genuinely needs to say who requested or reported something, this file set should read like
  standard project documentation — rules, history, and status stated directly — not like a transcript
  of a conversation. Reworded instances across `CLAUDE.md`, `CONVENTIONS.md`, `ROADMAP.md`,
  `PROGRESS.md`, `TESTERS.md`, `bugs/known-bugs.md`, and `TEST_PLAN.md` accordingly.

---

## Progress log

- 0.1 completed: created the addon folder and initial files for Leveling Gears, including Core.lua, LevelingGears.toc, and this CLAUDE.md spec file. Built the first runnable skeleton: a centered settings window titled "Leveling Gears" with a version label, close button, and slash-command entry points for /levelinggears, /lgs, and /lg.
- 0.11 completed: added a minimap button that opens and closes the same settings window used by the slash commands. Added a tooltip for the button and verified the Lua file still parses cleanly.
- 0.12 completed: polished the window with drag-and-drop positioning, saved placement, Escape-to-close behavior, and a vertically scrolling content area so the settings page can grow over time.
- 0.2 completed: added a visible, scrollable stat-weight list with per-stat up/down controls, 0–10 values, and per-character saving.
- 0.21 completed: added a profile-aware settings layout with addon-wide settings at the top, profile creation and switching below it, icon selection for profiles, and chat notifications on startup, profile load, and profile switch.
- 0.21 follow-up completed: simplified the profile section into a cleaner layout with a separate divider, a dropdown-based profile selector, and a higher window frame level so the window stays above overlays when open.
- 0.21 maintenance completed: added optional file-based debug logging, wrapped initialization and window callbacks in safe calls, and fixed an addon load blocker caused by an uninitialized profile hint UI object during setup.
- 0.22 completed: limited the addon slash commands to /levelinggears and /lgs, added a launch reminder to tell players how to open settings, and added comments around the remaining helper functions so the main Lua file is more self-documenting.
- UI cleanup completed: the stat-weight section now uses the same structured layout as the other settings sections, with a divider, a title, a short description, and content rows that stay separated so they do not overlap.
- 0.24 completed: added a visible color legend near the top of the settings page, expanded the equipped-gear evaluation to cover offhand and extra inventory slots where possible, and tightened the slash-command open path so /levelinggears and /lgs reliably open the settings window.
- Load-blocker fix confirmed: the addon initialization issue is resolved and documented as fixed.
- Profile-icon issue confirmed: the earlier icon-related UI problem has been fixed and documented as resolved.
- Metadata maintenance completed: the TOC version was brought into alignment with the current implementation so the addon reports version 0.22 consistently.
- Documentation pass completed: the Lua file now has more direct comments around the debug helpers, profile state, UI construction, and minimap/slash-command entry points so the code is easier to maintain.
- Bug: earlier profile UI revisions exposed icon options too early and caused layout overlap. The issue was documented and the UI was simplified to keep profile selection compact and avoid overlap.
- Bug: the addon hit a runtime initialization error when the profile hint text object was missing. The issue was fixed by creating the missing font string during setup and validating the file with luac.
- Bug: debug logging was added as an opt-in, file-gated feature so it remains silent unless explicitly enabled.
- 0.241 completed (maintenance pass): fixed a sandbox violation (file-based debug logging used `io.open`, which does not exist in the WoW addon environment) by replacing it with a SavedVariables-backed ring buffer plus chat output, gated by `/lgs debug` and readable via the new `/lgs debug dump`. Fixed five real call-order/scoping bugs: `PrintChat` and `ApplySavedPosition` were referenced before their `local` declarations existed (resolved as nil globals at runtime); `RefreshProfileList`, `SetActiveProfile`, and `CreateProfile` call each other and needed explicit forward declarations; `UpdateEquippedGearEvaluation` was an unintentional global, now a forward-declared local; the real minimap button frame was being created into a *second, shadowing* `local minimapButton` instead of the module-level one, so the "Show minimap button" checkbox never controlled it. Also discovered and fixed a critical persistence bug: the TOC file never declared `## SavedVariables: LevelingGearsDB`, so despite all the SavedVariables code, nothing had ever actually persisted between sessions. Removed dead code left over from the earlier profile-icon feature (`selectedProfileIcon` referenced a global that was never defined). Renamed three genuinely-unused `self` callback parameters to `_`. Updated `.luacheckrc` with the addon's real WoW API surface so luacheck stops flagging legitimate globals as errors; `luacheck` and `luac -p` both run clean now (one intentional "loop executed at most once" notice remains in `GetActiveProfile`, which is deliberate first-match logic, not a bug).
- 0.242 completed (bugfix): beta testing surfaced no colored outlines around equipped gear. Root cause (per bug #15): the paperdoll slot buttons (`CharacterHeadSlot`, etc.) this addon outlines aren't guaranteed to exist at login on this client — it loads the Character panel UI on demand, evidenced by the installed `GearScoreTBCClassic` addon deferring all of its own paperdoll work to `CharacterFrame`'s `OnShow`. Added the same `CharacterFrame:HookScript("OnShow", ...)` trigger so the outline evaluation re-runs once the panel is actually open and its slot buttons exist. Also added a debug-log line reporting slot-buttons-found vs. items-scored so this is diagnosable via `/lgs debug` + `/lgs debug dump` if it recurs. Not yet confirmed in-game.
- 0.243 completed (bugfix, confirmed via real evidence): beta testing reported settings not persisting and still no colored outlines. Read the actual on-disk SavedVariables file (`WTF/Account/ANDROIDEYES/SavedVariables/LevelingGears.lua`) directly and found: (1) settings persistence is in fact already working — the file contains real, non-default per-character stat weights and window position for "Xanga - Dreamscythe" — the likely earlier confusion was that a `.toc` metadata change (like adding `## SavedVariables`) only takes effect on a full client restart, not a `/reload`; and (2) the addon's own debug log (captured automatically by `SafeCall` regardless of whether debug mode was toggled on) had captured 50 repeats of `Core.lua:607: Invalid inventory slot in GetInventorySlotInfo` — the real root cause of the missing borders (see bug #16). `RelicSlot` isn't a real inventory slot in TBC (relics share the ranged-weapon slot until Wrath), so `GetInventorySlotInfo("RelicSlot")` threw a hard Lua error that silently aborted `UpdateEquippedGearEvaluation` before it ever reached the outline-coloring code, for every class, every time. Removed the `RelicSlot` entry and wrapped the per-slot `GetInventorySlotInfo` call in `pcall` so one bad slot name can never again kill the whole evaluation. Not yet confirmed in-game that borders now render (fix is evidence-based from the debug log, but this session cannot run the client).
- Testing confirmed colors now work as expected after 0.243.
- 0.244 completed (bug #17): beta testing still showed settings not retaining; a static Apply/Save button below the scroll area was requested, along with an explanation of how WoW addons conventionally save settings. Re-audited every settings-writing function (`SetWeight`, `SetMinimapButtonVisible`, `SaveWindowPosition`, `SetActiveProfile`, `CreateProfile`, `SetDebugEnabled`) and confirmed none of them buffer state — all write directly into `LevelingGearsDB` the instant they're called, and the 0.243 evidence already proved disk persistence itself works. Concluded the most likely explanation is the client being closed in a way that skips WoW's normal SavedVariables-flush points (`/reload`, Log Out, Exit Game) — e.g. a force-quit or crash — which is not something an addon can work around. Added a static "Save Settings" button in a fixed footer (anchored to the window frame, not the scroll child, so it never scrolls away) that calls `ReloadUI()`, giving a visible on-demand confirmation that a save-and-reload cycle happened — the same pattern Blizzard's own addon-list panel uses for its "Reload UI" button. Documented the actual SavedVariables persistence model in Technical notes so this isn't mistaken for a bug again. Shrank the scroll area's bottom margin (16px → 44px) to make room for the new footer and its divider.
- 0.245 completed (bugs #18, #19): beta testing reported the Save Settings button "is just reloading the UI and the settings aren't being updated at all"; also requested dropping the Shirt/Ammo/Tabard slots and clarifying relic handling by class. Found two real, compounding issues: (1) `SetWeight` never triggered `UpdateEquippedGearEvaluation`, so changing a stat weight never live-updated the equipped-gear outline colors — the only visible feedback loop available during testing; (2) the 0.244 button's `ReloadUI()` call had nothing new to persist (data was already live-saved), so it just produced a jarring, seemingly-pointless full UI reload. Fixed `SetWeight` to refresh the gear evaluation immediately, and removed `ReloadUI()` from the button entirely — it now only prints an honest confirmation of the current profile, since there is nothing left to save. Removed `ShirtSlot`, `AmmoSlot`, and `TabardSlot` from the equipped-gear evaluation (17 slots now). Verified via web search (Wowpedia) rather than assumption that TBC has no separate relic slot — Librams (Paladin), Idols (Druid), and Totems (Shaman) all share the ranged-weapon slot, which the addon already evaluates via `RangedSlot`; no per-class logic was needed, and this is now recorded in a code comment.
- 0.246 completed (bugs #20, #21): beta testing reported the +/- buttons were visually reversed (wanted `-` on the left) and that clicking them sometimes jumped the value by 1, 3, or 5 instead of 1; also re-raised whether `LevelingGearsDB` is declared correctly at load time. Confirmed the declaration is exactly correct (`LevelingGearsDB = LevelingGearsDB or {}`, matching the TOC's `## SavedVariables: LevelingGearsDB` case-for-case) and, via two separate on-disk SavedVariables reads taken minutes apart, confirmed weight values were genuinely changing and saving correctly throughout that testing session — the persistence mechanism itself is sound; logged as bug #21 (open) pending a precise repro of what specifically appears lost. Swapped the `+`/`-` button anchors. Root-caused the multi-jump report to this session's own 0.245 fix: making `SetWeight` run the full (17-slot) gear evaluation synchronously on every click was expensive enough that rapid clicking could queue up and burst-fire, exactly as shown by the debug log (two "Gear evaluation" entries logged in the same second). Fixed by debouncing the evaluation behind a `C_Timer.After(0.2, ...)` guard so a burst of clicks collapses into one evaluation instead of one per click.
- 0.247 completed (bug #22): beta testing reported the jump-by-4-or-5 was happening on the very *first* click on a stat, not just from rapid repeat clicks, and separately still reported settings not surviving a reload. Found the real root cause of both: `RefreshWeightLabels` (and `RefreshProfileList`/`RefreshGeneralSettingsUI`) only ever ran once, during the addon's initial load — never again when the settings window was later reopened. Every stat row starts with a hardcoded placeholder label of `"5"`; if a window reopen never re-synced that label against the true saved value (e.g. 9 or 10, per this character's actual saved weights), the *first* click on that stat would compute `trueValue + delta` and display it, looking like a jump of exactly the gap between 5 and the true value — matching the reported 4s and 5s precisely. This also fully explains the "settings don't survive reload" reports: the window can display a stale number until first touched, which reads exactly like data loss even though the saved data was correct the whole time (as repeatedly confirmed on disk). Fixed by forward-declaring `RefreshWeightLabels` (joining the existing `RefreshProfileList`/`SetActiveProfile`/`CreateProfile` forward-declaration block) and calling `RefreshGeneralSettingsUI()`, `RefreshProfileList()`, and `RefreshWeightLabels()` from the window's `OnShow` handler every time it opens, plus from the Save Settings button's click handler for concrete visible proof. The window can no longer show a stale value for longer than it takes to reopen it.
- **Testing confirmed bugs #20, #21, #22 all fixed.**
- 0.248 completed (bug #23): Armor also needed to be checked. Added `ARMOR`/"Armor" to `statDefinitions` and to the "Other stats" group (alongside Defense/Dodge/Parry/Block/Block Value/Resilience), and added `ARMOR = { "ITEM_MOD_ARMOR_SHORT" }` to `itemStatAliases`, matching the existing naming convention exactly. Recorded an honest caveat: a plain piece's base armor value isn't exposed by `GetItemStats` at all (it's intrinsic to material/ilvl/slot, not a modifier stat) — this token can only ever pick up BONUS armor modifiers (e.g. a shield's "of the Bear" suffix). Unverified on this client; documented the tooltip-scan fallback per the project's existing policy for uncertain `GetItemStats` coverage if it never contributes in practice.
- **0.25 completed: three-layer scoring engine + spec-aware default weights.** The weight sliders
  needed smart, spec-aware DEFAULT values (still fully hand-adjustable afterward),
  which meant finally building a real conversion-aware scorer instead of the flat
  `rawStatValue * weight` sum `GetEquippedItemScore` had used since 0.2 (that sum double-counted:
  e.g. Agility was weighted directly AND fed into AP/crit/armor, which already had their own
  weights). Added three new files: `Conversions.lua` (Layer 1: live, level-dependent API reads —
  rating-to-percent, Agility-to-crit/armor, Intellect-to-spell-crit — cached and refreshed on
  every score; Layer 2: the one hardcoded table, Attack Power per point of Strength/Agility per
  class/form, verified for TBC — Shaman is 1 melee AP/Str, NOT 2, that's a Wrath change),
  `Priorities.lua` (Layer 3: authored default weights for all 9 classes × 27 specs × 2 modes
  [speed/survival], applied to DERIVED stats only — explicit header comment warns future edits not
  to "correct" these against raid sims), and `Scoring.lua` (`ScoreItem`/`ScoreEquippedItem`,
  spec/form detection via `GetTalentTabInfo`, event wiring). Full rationale and every judgment call
  (rating fallback source, low-level default spec per class, Druid form-for-scoring, Hit/Crit/Haste
  offense-type simplification, why Spirit has no conversion, `ScoreItem` vs `ScoreEquippedItem`,
  and the `/lgs score` vs `/lg score` slash-command substitution) is recorded in the new
  `DESIGN.md`. UI consequence: the "Core stats" group's STR/AGI/STA/INT/SPI sliders are gone
  (weighting a primary directly would double-count it under the new engine) and replaced with
  HEALTH and MANA — the derived stats Stamina and Intellect actually turn into. `EnsureWeights` now
  seeds any never-set weight from the character's detected spec/mode default instead of a flat 5,
  but never touches a weight the player has already set — matching "the player can hand-adjust
  these" exactly. Added a `/lgs score <item link>` debug command (not `/lg score` — `/lg` was
  deliberately removed in bug #5) that prints the derived-stat breakdown and final score for a
  shift-clicked item against the character's detected class/spec/mode, for sanity-checking the
  Priorities tables in game. Added `CHARACTER_POINTS_CHANGED`/`PLAYER_LEVEL_UP` to the existing
  gear-evaluation event frame so a respec or level-up re-scores equipped gear immediately. `luac -p`
  and `luacheck` both pass on all 4 files.
- **0.26 completed: 0.05-precision weight sliders + Restore Defaults button.** The Priorities.lua
  defaults needed to be explicit and reversible (a visible "Restore Defaults" button, since
  before this a player's hand-adjustment could only ever be seeded once, never reset), and weights
  needed finer control than whole integers allowed. Kept the bar's visible range and units simple
  (still 0–10, "0 = ignore, 10 = highest importance") but the `+`/`-` buttons now move in 0.05 steps
  (`WEIGHT_STEP`, one constant to change if finer precision is ever wanted) instead of
  whole integers, with values rounded to the nearest step and displayed with only as many decimals
  as they need (`FormatWeight`: "5" for a whole number, "9.55" for a fractional one, never a
  trailing zero). Added a Shift-click modifier for a coarser ±1 step, since 0.05 alone would need up
  to 200 clicks to cross the full bar — documented in the settings page's own helper text. Added a
  "Restore Defaults" button in the stat-weights section that overwrites the ENTIRE active profile's
  weights with the character's detected spec/mode default (`LG.Scoring:GetDefaultWeights`),
  distinct from `EnsureWeights`, which only ever fills a never-touched key and is otherwise
  untouched by this change — "any adjustment the player makes overrides the default" still holds
  exactly as before. Bumped `ReflowStatGroups`' starting offset to make room for the new button row
  — **not yet visually confirmed in game that the first stat group doesn't overlap it** (see the
  in-code comment and known-bugs.md #25). `luac -p` and `luacheck` both pass.
- **0.261 completed (reorganization, not a feature change): split `Core.lua` into 9 focused
  files.** `Core.lua` needed to stay small, with logic/UI/debugging moved to wherever they
  belong, since it had grown to over 1100 lines covering everything from debug logging to window
  layout to gear scoring. New files (load order matters, see `LevelingGears.toc`): `Debug.lua`
  (logging ring buffer, `PrintChat`, `SafeCall`, the addon version string -- loads first since
  everything else depends on it), `Settings.lua` (SavedVariables data layer: general settings,
  per-character profile CRUD), `Weights.lua` (the weightable-stat list, 0.05-precision math,
  `EnsureWeights`/`SetWeight`/`RestoreDefaultWeights` -- `WEIGHT_STEP` now lives here, not
  `Core.lua`), `GearEvaluation.lua` (equipped-item scoring + outline coloring, unchanged from 0.26
  except namespaced), `UI.lua` (the entire settings window -- every frame, widget, and refresh
  function). `Core.lua` is now ~100 lines: slash-command dispatch (`/lgs`/`/levelinggears`,
  including the `score` subcommand) and the startup sequence that calls into the other modules once
  they've all loaded. Cross-file calls go through the shared `LG` namespace table (`LG.Debug`,
  `LG.Settings`, `LG.Weights`, `LG.GearEvaluation`, `LG.UI`, plus the existing `LG.Conversions`/
  `LG.Priorities`/`LG.Scoring` from 0.25) instead of the old same-file `local` forward-declarations
  -- since a table field is resolved at call time rather than parse time, this also fully retires
  the forward-declaration pattern that caused bugs #11 and #22 (a function referenced before its
  local existed, or never re-synced after being forward-declared). No behavior change other than
  one small, deliberate simplification: `statGroups` (UI.lua) now looks up each stat's name/key
  from `Weights.statDefinitions` by key instead of re-typing it, removing a pre-existing
  duplication between the two lists. `luac -p` and `luacheck` both pass on all 9 files (one
  pre-existing, documented notice remains in `Settings.lua`'s `GetActiveProfile`, previously in
  `Core.lua`).
- **2026-07-14 — CLAUDE.md split into PROGRESS.md/ROADMAP.md/CONVENTIONS.md.** See the decision log
  entry above; no code changed, this is documentation-only.
- **0.3 completed (process/version milestone, no code behavior change):** the 0.25/0.26/0.261 work
  was substantial enough to warrant formally bumping to 0.3 and entering a real testing phase before
  building anything further. Ran a static conflict/consistency audit first (see
  the decision log and Current status above — clean). Redefined what 0.3 means in `CONVENTIONS.md`'s
  versioning ladder (was reserved for the data-schema milestone) and renumbered `ROADMAP.md`'s
  data-schema-onward milestones from 0.3-0.9 to 0.4-0.91 accordingly, mirrored in `DATA_PIPELINE.md`.
  Added `TESTERS.md` (professional-style tester onboarding: environment setup, testing conventions,
  severity levels, defect-report template) and `TEST_PLAN.md` (a living, per-commit test plan with a
  full Phase 1 regression checklist covering every feature built to date, plus a "known, accepted —
  not a bug" section so testers don't file expected gaps like the minimap's identical left/right
  click behavior or intentionally-unbuilt roadmap features). `CONVENTIONS.md`'s mandatory maintenance
  rules now require keeping `TEST_PLAN.md` current every commit. `CLAUDE.md` updated to point at both
  new files. `luac -p` and `luacheck` re-verified clean on all 9 Lua files as part of the audit.
- **0.301 completed (bug #27):** the on-disk debug log (`WTF/.../SavedVariables/
  LevelingGears.lua`) had its entire 50-entry ring buffer filled with one repeating error:
  `Scoring.lua:102: attempt to perform arithmetic on local 'pointsSpent' (a string value)`, inside
  `DetectSpec`. Root cause: `local _, _, pointsSpent = GetTalentTabInfo(tabIndex)` assumed
  `pointsSpent` sits at return position 3 (the old Classic-era signature); on this client it doesn't
  — position 3 is a string. Web research found retail's modern signature prepends an `id` return,
  which would shift `pointsSpent` to position 4 or 5 depending on which later fields exist on this
  client build; no source confirmed the exact TBC Anniversary signature. Since `DetectSpec` underlies
  the entire v0.25+ scoring engine, every caller has been failing silently since v0.25: gear-outline
  coloring aborted before painting anything, and spec-aware default weights fell back to a flat 5
  every time (confirmed on disk — a freshly created test profile had every stat at exactly 5 except
  one manually adjusted during 0.05/Shift-click testing). Fixed defensively rather than by guessing a
  single position: capture positions 3/4/5 and use `tonumber(c) or tonumber(d) or tonumber(e) or 0`,
  so whichever position is actually numeric on this client wins, without needing certainty about the
  exact signature. `luac -p`/`luacheck` pass. Not yet re-verified live — see `bugs/known-bugs.md` #27
  and `TEST_PLAN.md` for the specific follow-up check (does a melee spec now seed high Attack Power
  instead of a flat 5 across every stat?).
- **0.302 completed: processed the first real test report (T1-T15 of 35; testing stopped early on
  purpose after finding real bugs).** Confirmed working from the report: clean load, both slash
  commands, `/lgs debug`/`debug dump`, minimap visibility toggle and click-to-open, window
  drag/Escape/close, scrolling with no section overlap, and bug #27's crash fix itself (gear
  evaluation now completes and scores items — 16/17 slots, zero errors — where before it aborted on
  the first slot every time). Three real issues found and addressed:
  - Bug #28 (solved): the profile picker button showed only the active profile's name (e.g.
    "Default") with nothing labeling what it was — read as a "restore defaults" button. Added a
    static "Profile:" text label to its left (`UI.lua`).
  - Bug #29 (open, mitigated): window position restores *consistently* every time, but not to the
    *exact* spot it was dragged to — "kind of in a similar general area." Reviewed
    `SaveWindowPosition`/`ApplySavedPosition` end to end and found no defect by static review, so
    rather than guess a fix with no evidence, added debug logging of the exact saved/restored
    point/relativePoint/x/y (`/lgs debug` level 1) and a defensive pixel-rounding pass on the saved
    offsets (safe regardless of root cause, since `SetPoint`/`GetPoint` round-trips can accumulate
    float drift). Root cause still unconfirmed pending the next test pass's debug log evidence.
  - Bug #30 (open, mitigated): `/lgs score` reported as "doesn't work" with no error text or debug
    log captured. Reviewed `HandleScoreCommand`/`HandleSlashCommand` end to end and found no code
    defect either; most likely explanation is the item link needing to be shift-clicked into the
    same chat line as the command before pressing Enter (typing the command alone first would
    silently no-op, matching "doesn't work" with no error). Reworded the usage message to spell out
    the exact required sequence, and added logging for the "no item stats returned" path so a real
    failure now leaves evidence. Root cause still unconfirmed.
  - Four new feature ideas from the same report were filed in `ROADMAP.md`'s new "Testing Phase 1
    follow-ups" section (0.31 minimap drag-to-reposition + position persistence, 0.32 custom
    minimap/addon art, 0.33 shift-click item scoring replacing `/lgs score`, 0.34 a profile-naming
    dialog with a text input and suggested-name tooltip) — explicitly gated: **not to be built until
    every currently-shipped feature is confirmed working**.
    `CONVENTIONS.md`'s versioning ladder updated to reflect 0.31-0.34 now being taken (next free
    two-decimal slot in the 0.3 milestone is 0.35).
  `TEST_PLAN.md` updated: "Recent changes to focus on" now points the next pass to resume at T1 (to
  re-confirm these three fixes) and continue through T16-T35 (never reached last round); T8/T11/T15
  updated in place to describe what changed and what evidence to capture this time. `luac -p` and
  `luacheck` both pass on the two touched files (`Core.lua`, `UI.lua`).
- 0.303 completed: bug #30's real fix. v0.302's usage-message mitigation was rejected outright as too
  complicated; the requested fix was direct: shift-click an equipped item in the character
  window to print its score to chat, no slash command needed. Verified Blizzard's real click behavior
  for equipped-item slot buttons against FrameXML source before implementing anything (rather than
  assuming): left-click branches on modifier (plain = pick up, Ctrl = dress up, Shift = insert item
  link in chat); right-click unconditionally calls `UseInventoryItem(slotId)` regardless of any held
  modifier, with no shift-check at all. That meant the literally-requested shift+right-click would
  also risk firing the item's on-use effect (e.g. a trinket proc) as an unwanted side effect on every
  score check. Implemented as **shift+left-click** instead: side-effect-free, and reuses Blizzard's
  own existing "shift-click to reference this item in chat" convention rather than inventing a new
  gesture. `GearEvaluation.lua` now hooks each equipped slot button's `OnClick` via `HookScript`
  (additive — runs alongside Blizzard's own handler, doesn't replace it) the first time each button is
  encountered in the existing gear-evaluation loop; the hook scores the clicked item against the
  player's live profile weights (`Scoring:ScoreEquippedItem`, the same weights driving the gear-
  outline coloring) and prints the breakdown to chat. Extracted the chat-printing/sorting logic that
  was inline in `Core.lua`'s `HandleScoreCommand` into a new shared `Scoring:PrintBreakdown`, so both
  this feature and the surviving `/lgs score` debug-bench command (kept for sanity-checking the raw
  `Priorities.lua` tables independent of a player's own weight customization, per `DESIGN.md`) print
  through one implementation instead of two. This pulls forward and closes `ROADMAP.md`'s previously-
  gated 0.33 item ahead of the rest of the Testing Phase 1 follow-ups (0.31/0.32/0.34 remain gated);
  noted in `ROADMAP.md` that the future 0.6 "suggest gear" flow will need a different trigger gesture
  now that shift+left-click is taken. Updated `bugs/known-bugs.md` #30 to Solved and `TEST_PLAN.md`'s
  T8 to test the new shift+left-click interaction as primary (added T8b for the `/lgs score`
  fallback). Version bumped to 0.303 in `Debug.lua`/`LevelingGears.toc`/`README.md`/`TESTERS.md`.
  `luac -p` and `luacheck` both pass clean on all three touched files (`GearEvaluation.lua`,
  `Scoring.lua`, `Core.lua`).
