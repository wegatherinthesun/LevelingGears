# PROGRESS.md — Leveling Gears

Chronological build history: current status, dated decisions, and the full per-version progress
log. This file only needs to be read when you need context on what's already been done, why a past
decision was made, or before writing a new entry after finishing a step. `CLAUDE.md` carries only
the current single most important next step — this file has everything behind it.

---

## Current status

- **Current step: 0.382 — shipped roadmap item 0.37 (explain why primary stats aren't weightable)
  and closed out Testing Phase 1 follow-ups, no code left to build before a real test pass.** Part of
  a bug-fix→test→ship cycle: with bug #29 the only remaining open bug (no further code fix possible
  without live evidence), bundled in this small, already-scoped, ungated roadmap item rather than
  shipping a bugfix-only patch. Added a helper-text line to the stat-weights section (`UI.lua`)
  explaining that Strength/Agility/Intellect/Stamina/Spirit aren't listed because they're
  auto-converted into the derived stats shown (`DESIGN.md`'s double-counting rule) — closing a real
  gap where a first-time player had no way to know why familiar stats were missing. Bumped
  `ReflowStatGroups`'s starting offset (-134 to -160) to make room, a reasoned estimate pending visual
  confirmation, same caveat as every prior change to that offset (bug #25). `ROADMAP.md` updated: 0.37
  marked Built (shipped out of numeric order under a thousandths patch, same precedent as 0.33/v0.303);
  two stale "not built" references to the spec-override dropdown fixed (it shipped in 0.38); the
  "Testing Phase 1 follow-ups" section's intro rewritten to state plainly that every item in it is now
  Built and the section is done pending only a real test pass. Deleted a stale, blank, never-filled
  untracked `TEST_RESULTS_Helio_0311` file (leftover from an earlier attempt, no real data in it).
  `luac -p`/`luacheck` clean on `UI.lua`. Version bumped to 0.382 (thousandths patch). **Every
  currently-known code fix is now in — the sole next step is a real `TEST_PLAN.md` T1-T35 pass.**
- **Previous step: 0.381 — replaced `DetectSpec`'s entire talent-point-reading method.** Reported
  again immediately after 0.38 shipped: the same Enhancement Shaman, now with all 44 points in
  Enhancement (no ambiguity, definitely not a tie), was still auto-detected as Restoration. This
  disproved 0.38's tie-break theory as the sole explanation — with one tab holding all 44 points, the
  comparison loop can't mis-pick a different tab unless the underlying per-tab counts it compares are
  themselves wrong. That pointed back at what bug #27 already flagged as uncertain:
  `GetTalentTabInfo`'s aggregate `pointsSpent` return value, whose exact position was only ever a
  guess (`tonumber(c) or tonumber(d) or tonumber(e)`). Rather than guess a fourth position, replaced
  the whole method: `DetectSpec` now sums each individual talent's own `currentRank`
  (`select(5, GetTalentInfo(tabIndex, talentIndex))` for `talentIndex = 1, GetNumTalents(tabIndex)`)
  instead of trusting `GetTalentTabInfo`'s aggregate at all — confirmed as a real, working pattern
  (not another guess) by finding two other installed, actively-used addons on this exact client doing
  precisely this: `ShamanPower.lua`'s own talent scan and `PallyPower.lua`'s talent-point counter.
  `GetTalentTabInfo` is no longer called anywhere in the addon. `luac -p`/`luacheck` clean on
  `Scoring.lua`. Version bumped to 0.381 (thousandths patch — a bugfix, not a new sub-feature, per
  direct instruction). Full detail in `bugs/resolved-bugs.md` #37's second update.
- **Previous step: 0.38 — manual "Spec:" dropdown, plus a first (incomplete) fix to `DetectSpec`'s
  tie-break logic.** Direct live report: playing an Enhancement Shaman, the addon recommended Spell
  Power (Elemental's reference stat) instead of Attack Power. Investigated `Scoring.DetectSpec`'s
  talent-tab comparison and found a real bug: ties between two tabs' point counts silently resolved
  to tab order (tab 1 = Elemental for Shaman) rather than anything meaningful — a real shape for a
  leveling build that hasn't yet committed every point to one tree, exactly matching the report at
  the time. Fixed the tie-break to fall back to the documented low-level default instead of guessing
  from tab order (superseded by 0.381 above, which found this wasn't the whole story). Shipped the
  directly requested fix regardless of root-cause certainty: a new "Spec" section in the settings
  window with a "Spec:" dropdown (`Scoring.GetSpecOptions`/`Scoring.SPEC_DISPLAY_NAMES`) listing
  "Auto-detect" plus the player's class's 3 real specs, wired through `Settings.SetSpecOverride`
  (stores `characterState.specOverride`, restores weights to the newly-correct spec's defaults,
  refreshes the UI) and read first by `DetectSpec` before any talent-point logic. Added a status line
  ("Currently scoring as: ...") and a `source` return value (`"override"`/`"detected"`/`"assumed"`)
  so `DescribeCurrentSpec()` can say `[manually set]` instead of leaving the source of a spec guess
  invisible — this also closes `ROADMAP.md`'s old 0.37-adjacent gap of "no spec auto-detection UI
  feedback." `luac -p`/`luacheck` clean on `Scoring.lua`, `Settings.lua`, `UI.lua`. Version bumped to
  0.38 (next free two-decimal slot per `CONVENTIONS.md`'s versioning ladder — this is a real new
  sub-feature, not a thousandths bugfix). Full detail in `bugs/resolved-bugs.md` #37.
- **Previous step: bug ledger split into `bugs/known-bugs.md` (open only) and `bugs/resolved-bugs.md`
  (the append-only archive), no version bump.** Requested directly: outstanding bugs should live in
  `known-bugs.md`, resolved ones get their own file, since resolved history is genuinely useful when
  troubleshooting a new hard-to-pin-down bug (this project has repeated the same root-cause shapes —
  stale forward-declarations, an undebounced event handler, a client API returning an unexpected
  type — more than once, and a past entry's investigation technique, especially reading the on-disk
  debug log directly, is often the fastest way into a similar-looking new one). Moved bugs #1-28 and
  #30-36 to the new `bugs/resolved-bugs.md` (35 entries, original numbers kept, nothing renumbered);
  `bugs/known-bugs.md` now holds only bug #29, the sole entry still genuinely `Open`. Updated every
  cross-reference to a moved bug number across `CONVENTIONS.md`, `DESIGN.md`, `ROADMAP.md`,
  `README.md`, `TESTERS.md`, `TEST_PLAN.md`, `CLAUDE.md`, and this file's own Progress log to point at
  `bugs/resolved-bugs.md` instead — historical decision-log entries that just name which files were
  touched at a past point in time were left as-is, since `resolved-bugs.md` didn't exist yet at that
  point. `CLAUDE.md`'s "Read when relevant" table now lists both files, and its Current step section
  has a new standing note to check `bugs/resolved-bugs.md` first when troubleshooting a difficult
  bug, per the direct request. `CONVENTIONS.md`'s Mandatory maintenance rules updated to describe the
  two-file split and when to move an entry across.
- **Previous step: 0.313 — found and fixed a real debounce gap (bug #36), and reinforced bug #29's
  evidence with a third read.** Re-reading the on-disk debug log after the 0.312 ring-buffer bump
  showed it had grown to 123 total entries (confirming the bump works) with bug #29's position data
  now at 45 clean save/apply pairs across three anchor points (`CENTER`/`TOPLEFT`/`LEFT`), every one
  matching exactly — zero drift anywhere, still the strongest evidence yet that save/restore itself is
  sound (the one gap left is a real `/reload`/relaunch round-trip, not yet captured). The same read
  also turned up something new: a burst of 61 identical "Gear evaluation: 17/17 slot buttons found, 14
  items scored." lines all timestamped the same second. Traced to `GearEvaluation.lua`'s own event
  handler (`PLAYER_ENTERING_WORLD`/`PLAYER_EQUIPMENT_CHANGED`/`UNIT_INVENTORY_CHANGED`/
  `CHARACTER_POINTS_CHANGED`/`PLAYER_LEVEL_UP`) and the `CharacterFrame:HookScript("OnShow", ...)` hook
  both calling `SafeCall(GearEvaluation.UpdateEquippedGearEvaluation)` directly — bypassing
  `ScheduleGearEvaluation()`, the 0.2s debounce bug #20/#21 already built for exactly this class of
  problem, which was only ever wired to the UI's weight-adjustment click path, not this event path.
  Fixed by routing both call sites through `ScheduleGearEvaluation()` instead. `luac -p`/`luacheck`
  clean on `GearEvaluation.lua`. Version bumped to 0.313. Full detail in `bugs/resolved-bugs.md` #36
  (new) and `bugs/known-bugs.md` #29 (third update).
- **Previous step: 0.312 — increased the debug log ring buffer from 50 to 500 entries.** Directly
  motivated by bug #29: reading the on-disk debug log twice in the same session showed the 50-entry
  cap had already wrapped once, evicting whatever came before ~20:24 that session (including however
  it started). The second read (after the ring buffer had rolled further) did turn up real signal
  despite this: three clean drag-then-reopen round-trips, all matching exactly, at three different
  anchor points, with `frame:GetScale()`/`GetEffectiveScale()`/`UIParent:GetEffectiveScale()` all
  exactly `1.0000` throughout — strong evidence the save/restore mechanism itself is sound. Bumped
  `Debug.lua`'s `DEBUG_LOG_MAX_ENTRIES` to 500 (still a negligible SavedVariables size for small
  strings) so a full play session with debug mode on doesn't lose data before it can be dumped.
  Updated `bugs/known-bugs.md` #29 with the full second-read findings and downgraded its status from
  "root cause unconfirmed" to "may already be resolved, pending direct confirmation" — the one thing
  still worth checking is whether an actual `/reload` (not just an in-session close/reopen) also
  round-trips clean. Updated `TEST_PLAN.md` T7's expected ring-buffer size. `luac -p`/`luacheck` clean
  on `Debug.lua`. Version bumped to 0.312.
- **Previous step: documentation consistency pass (no version bump — docs/roadmap only, no code
  changed).** Prompted by a direct question ("when was the last time README.md was updated?") into
  auditing every doc for drift after the recent burst of versions (0.304-0.311). `README.md` itself
  was already current (last touched in the 0.31 consolidation). Found one real gap: `TEST_PLAN.md`'s
  "Recent changes to focus on" section and T2 still referenced v0.306, with no mention of v0.307's
  research pass, v0.308's analytical derivation, the 0.31 consolidation, or 0.311's bug-ledger
  work — rewrote that section, fixed T2's version expectation, updated T11 to mention the new scale
  diagnostics, and updated T20 with specific per-role weight expectations (e.g. a Restoration Shaman
  should seed MP5 *above* Healing Power — that's the real, correct ratio, not a bug) instead of the
  generic "not a flat 5." Also reordered `ROADMAP.md`'s Testing Phase 1 follow-ups list back into
  ascending numeric order (0.31 through 0.37 had drifted out of sequence across several edits). Added
  a new roadmap item, 0.37, per direct request: explain in the settings UI itself why primary stats
  (Strength/Agility/Intellect/Stamina/Spirit) aren't shown as weightable — nothing currently tells a
  player why familiar stats are missing from the list. `CONVENTIONS.md`'s versioning ladder updated
  to mark 0.37 taken and 0.38 as the next free two-decimal slot. `DATA_PIPELINE.md` checked and found
  already current (its 0.41-0.44 references are untouched by the 0.31-range renumbering).
- **Previous step: 0.311 — surveyed the bug ledger for what's genuinely still open, closed two
  research gaps, and armed bug #29 with more diagnostics.** Every bug in the ledger except #29
  (window position drift) is Solved or Mitigated pending the next live test pass — see
  `bugs/resolved-bugs.md` for the full archive —
  confirmed this by reading the whole ledger rather than assuming. Found and cited a real
  Defense-rating breakpoint for Feral Druid Bear Tank (~156 rating: raid bosses have a 5.6% chance to
  crit a tank, Survival of the Fittest suppresses 3% of that, the remaining 2.6% needs 2.4 Defense
  Rating per 0.1% — a genuine, Druid-specific number distinct from the Warrior/Paladin ~490 Defense
  Skill figure, since Druids have a crit-suppression talent those classes lack), closing one of the
  two "honest gap" flags from bug #34/#35. Re-checked Discipline Priest's citation: re-attempted a
  direct fetch of the Warcraft Tavern source (still 403s) and checked Wowhead's equivalent page
  (client-rendered, no static text to fetch) — no better source exists, so the original proxy-sourced
  numbers stay, now noting that a separate, independent search result corroborated the Spirit-to-
  Healing ratio exactly. For bug #29, added `frame:GetScale()`/`GetEffectiveScale()`/
  `UIParent:GetEffectiveScale()` logging to `SaveWindowPosition`/`ApplySavedPosition` alongside the
  existing point/x/y capture — pure additional diagnostics, not a guessed fix, since a "consistently
  offset, not random" symptom is exactly the signature a deterministic UI-scale mismatch between
  sessions would produce; if that theory is right, the next debug dump proves it immediately instead
  of needing a third round-trip. `luac -p`/`luacheck` clean on `UI.lua` and `Priorities.lua`. Version
  bumped to 0.311 (first patch under 0.31's thousandths rule). Full detail in `bugs/known-bugs.md`
  #29's updated "Attempts to fix" and `bugs/resolved-bugs.md` #34's new update note.
- **Previous step: 0.31 — consolidated release.** Squashes the `single-profile` fork (built and
  iterated internally as v0.304 through v0.308, detailed as "Previous step" entries below) into one
  shipped, two-decimal version: one weight set per character (no profiles), direct-entry stat editing
  with no imposed scale, and `Priorities.lua`'s default weights analytically derived from real TBC
  combat formulas instead of guessed or rank-derived numbers. The fork has been fast-forward-merged
  into `main` and the `single-profile` branch deleted — `main` is now the only branch. The individual
  v0.304-v0.308 version numbers are kept as-is in the Progress log below and in `bugs/resolved-bugs.md`
  #31-#35 (the real, accurate history of how 0.31 was built); they are not retroactively renamed.
  Patches to 0.31 follow the existing thousandths rule (0.311, 0.312… — see `CONVENTIONS.md`'s
  versioning ladder for why the next patch is 0.311 and not 0.301, which already exists as an
  unrelated, much earlier bugfix). `ROADMAP.md`'s old "0.31 — minimap drag-to-reposition" entry moved
  to 0.36 to free the number for this consolidation.
- **Previous step: 0.308 (same `single-profile` fork) — replaced `Priorities.lua`'s anchor-scale
  weights with values analytically derived from known TBC combat formulas.** v0.307's fix (below)
  was correctly called out as still a shortcut: a real stat-priority ORDER doesn't specify a
  magnitude, only a ranking, and inventing the magnitude (an anchor scale) wasn't "doing the math
  right." Investigated what real numeric stat weights actually require: confirmed by direct fetch
  that `wowsims/tbc` has a genuine simulated "Stat Weight Calculation" feature (real per-point DPS
  deltas), but it's gear/talent/rotation-dependent and running it would mean standing up a Go/
  protobuf/node toolchain and authoring per-spec configs — real infrastructure, not a quick task.
  Also confirmed by fetching several class pages directly that only the Warlock guides publish an
  actual numeric table; every other class checked (Fury Warrior, Elemental Shaman, Retribution
  Paladin, Restoration Druid) is rank-order only, with the Elemental Shaman page explicitly saying
  "real stat weights depend heavily on your current gear... use the Wowsims module for precise
  calculations." Confirmed with the requester: derive weights analytically from known combat
  mechanics rather than build/run a full simulator. Rewrote every one of `Priorities.lua`'s 54
  speed/survival tables using verified formulas (14 Attack Power = 1 DPS; a physical crit's +100%
  damage bonus and Haste's direct attack-frequency scaling place Crit/Haste at ~1.0x the spec's
  reference stat per 1%; Hit/Expertise's "a miss/dodge/parry is zero damage" effect places them at
  ~1.3x; Armor Penetration's nonlinear, target-armor-dependent curve discounts it to ~0.5x), plus
  real, cited per-class mechanical corrections: Warriors' rage-generation formula is normalized for
  attack speed in TBC (discounting Haste to ~0.3x, boosting Crit to ~1.2x since crit-generated rage
  closes gaps between special-ability casts); caster crit-multiplier talents (Elemental Fury for
  Elemental Shaman, Vengeance for Balance Druid) genuinely double the crit bonus; Shadow Priest's and
  every HoT-healer's periodic damage/healing cannot crit in TBC. Used the two real published numeric
  tables found (Warlock's Spell Power Equivalency values, Restoration Shaman's Heal/Haste/MP5/Crit/
  Int/Stam ratios) directly rather than approximating them. Caught and fixed a real conceptual error
  in the process: guide priority orders blend a stat's true marginal value with plain
  itemization-scarcity advice ("grab this when you see it, you'll get plenty of the other stat
  naturally" — e.g. Warrior guides explicitly deprioritize Strength/AP because it's "abundant on
  gear," not because it's worth less DPS); only the former belongs in a per-item scoring weight, so
  the primary reference stat (AP/RAP/SP/HEAL) is never suppressed by that reasoning in any spec.
  Added a `ROADMAP.md` "Past 1.0 — revisit later" entry to reconsider building a real simulator once
  the addon is otherwise stable. `DESIGN.md`'s Layer 3 description updated to match. `luac -p`/
  `luacheck` pass clean on `Priorities.lua`; the structural verification script (all 27 specs, all 25
  stat keys, both modes) was re-run with zero gaps before being deleted again. Full detail in
  `bugs/resolved-bugs.md` #35.
- **Previous step: 0.307 (same fork) — replaced `Priorities.lua`'s hand-authored default weights
  with values sourced from real, cited TBC Classic stat-priority research.** The
  file's own original header admitted these numbers were placeholders ("a design choice... not a
  lookup or a simulation result"), and after bug #33 confirmed the edit box already shows the exact
  value used (no hidden layer), the follow-up ask was direct: make that exact value a real one.
  Dispatched three parallel research passes (one per group of 3 classes) that fetched Icy Veins' (and
  one Warcraft Tavern) TBC-Classic-specific PvE stat-priority guides for all 27 specs, each returning
  a cited priority order, cap/breakpoint numbers, and avoid/situational notes per spec. Converted
  every spec's real priority order into a number via one documented anchor scale (10 = top-priority/
  cap stat, 8 = very important, 6 = good, 3 = minor, 0 = explicitly low-value or not itemized),
  applied consistently across all 27 specs × 2 modes (54 tables), with the source URL cited directly
  above every table in `Priorities.lua`. Corrected real inaccuracies the old guesses had (e.g. Fury
  Warrior was previously assumed to value Haste more than Arms; the real source gives both specs an
  identical priority that explicitly says not to stack Haste for either). Documented the honest
  limits directly in the file: rank-derived from real sources, not precise per-point sim multipliers;
  Hit/Expertise are cap-then-worthless stats this addon can't model dynamically (items score
  statically, no running total-vs-cap state), so they're weighted at pre-cap importance; "survival"
  (leveling) mode still has no real source to cite and stays a documented, unsourced defensive
  adjustment on top of the sourced "speed" baseline; Spirit still has no derived-stat key of its own
  (per the existing double-counting rule) so its priority is folded into MP5 as the closest proxy.
  Flagged rather than papered over two honest gaps: Discipline Priest's only available source
  (Warcraft Tavern) blocked a direct fetch during research (retrieved via proxy, recommended for
  manual spot-check), and Feral Druid Bear Tank's source doesn't give an exact Defense-rating
  crit-immunity breakpoint. Wrote and ran a standalone structural-verification script (loads
  `Priorities.lua` in isolation, confirms all 27 specs have both speed/survival tables with all 25
  stat keys present, zero gaps) before deleting it. `DESIGN.md`'s Layer 3 description updated to
  match, replacing the old "authored design choices" framing. `luac -p`/`luacheck` pass clean on
  `Priorities.lua`. Full detail in `bugs/resolved-bugs.md` #34.
- **Previous step: 0.306 (same `single-profile` fork) — removed the stat-weight edit box's remaining
  0-10 clamp and "importance scale" framing.** v0.305's edit box still enforced a 0-10 range
  (`Weights.WEIGHT_MIN`/`WEIGHT_MAX`) and the helper text still read "0 = ignore, 10 = highest
  importance," so it was reported as still showing "the 1-10 system" instead of the real value.
  Confirmed there was never a separate hidden "real" value — `Scoring.lua`'s `ComputeScore` already
  multiplies the derived stat by this exact stored number, so the fix was to stop imposing an
  artificial range/framing on it, not to expose some other number. `Weights.lua`: removed
  `WEIGHT_MIN`/`WEIGHT_MAX` entirely and the clamp inside `SetWeightValue` — whatever is typed
  (positive, negative, above 10, whatever) is stored and used exactly as given. `UI.lua`: reworded
  the stat-weights helper text to describe the box as showing the exact weight used when scoring,
  instead of a 0-10 importance rating. Updated `ROADMAP.md`/`DESIGN.md`/`README.md` to stop
  describing a "0-10 scale." `luac -p`/`luacheck` pass clean on `Weights.lua` and `UI.lua`. Full
  detail in `bugs/resolved-bugs.md` #33.
- **Previous step: 0.305 (same `single-profile` fork) — replaced the stat-weight rows' `+`/`-`
  buttons with a direct-entry edit box per stat.** Reported as "too complicated." Each row is now
  just a label and one `EditBox` (`InputBoxTemplate`) showing `FormatWeight`'s rendering of the
  exact value `characterState.weights` holds — type a value, press Enter (or click away from the
  box) to commit it. `Weights.lua`: removed `WEIGHT_STEP`, `RoundToStep`, and the delta-based
  `SetWeight(statKey, delta)`; added `SetWeightValue(statKey, value)`, an absolute setter clamped to
  `WEIGHT_MIN`/`WEIGHT_MAX` (0-10). `FormatWeight` still rounds only the *display* to a hundredth to
  hide floating-point noise — it no longer restricts what a player can type. `UI.lua`'s
  `CreateStatRow`: removed the value `FontString` and both step buttons; added the `EditBox` with
  `OnEnterPressed`/`OnEditFocusLost` handlers that parse the typed text and call `SetWeightValue`, or
  revert the box to the real saved value (via the existing `UI.RefreshWeightLabels()`) if the typed
  text doesn't parse as a number — invalid input never looks like it was silently accepted. Kept the
  existing collapsible group structure (Core stats/Other stats/Resistances) and the "Restore
  Defaults" button, both confirmed as still wanted. `luac -p`/`luacheck` pass clean on `Weights.lua`
  and `UI.lua`. Full detail in `bugs/resolved-bugs.md` #32.
- **Previous step: 0.304 (the "single-profile" fork) — removed the multi-profile system entirely.**
  Reported broadly as "lots of errors in the profile," on top of the already-fixed bug #28 (ambiguous
  picker label). Decision: stop patching the multi-profile system piece by piece and remove it —
  there is now exactly one hand-adjustable weight set per character, no naming/creating/switching.
  Committed the prior v0.302/v0.303 work to `main` first, then created a new `single-profile` git
  branch for this change (an explicit fork, per instruction, rather than continuing to build
  directly on `main`). `Settings.lua`'s `characterState.profiles`/`activeProfile` map became a flat
  `characterState.weights` table (`GetActiveProfile`/`SetActiveProfile`/`CreateProfile` removed;
  `GetCharacterState()` returns the weight state directly), with a one-time migration that pulls an
  existing character's previously active profile's weights into the new flat state so no one's
  hand-tuning is lost. `Weights.lua`/`GearEvaluation.lua` updated to match (same `.weights` shape, so
  the scoring logic itself didn't need to change). `UI.lua`'s entire "Profiles" section (header, hint,
  dropdown button/menu, divider) is gone; the stat-weights section now sits directly below general
  settings. `Core.lua`'s boot sequence (`InitializeProfileState` → `InitializeCharacterState`) no
  longer names a profile, and now prints a new one-time chat message explaining that weights don't
  auto-update on a respec or talent change and must be restored/re-adjusted by hand (the real fix for
  that is filed as `ROADMAP.md`'s new 0.35, not built yet). `ROADMAP.md`'s 0.34 ("profile creation
  dialog") is dropped as moot. `luac -p`/`luacheck` pass clean on all five touched files
  (`Settings.lua`, `Weights.lua`, `GearEvaluation.lua`, `UI.lua`, `Core.lua`). Full detail in
  `bugs/resolved-bugs.md` #31.
- **Previous step: 0.303 — bug #30's real fix: shift+left-click an equipped item to score it.**
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
  (`GearEvaluation.lua`, `Scoring.lua`, `Core.lua`). Full detail in `bugs/resolved-bugs.md` #30.
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
  `bugs/resolved-bugs.md` #28-#30.
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
  in-code comment and resolved-bugs.md #25). `luac -p` and `luacheck` both pass.
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
  exact signature. `luac -p`/`luacheck` pass. Not yet re-verified live — see `bugs/resolved-bugs.md` #27
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
  now that shift+left-click is taken. Updated `bugs/resolved-bugs.md` #30 to Solved and `TEST_PLAN.md`'s
  T8 to test the new shift+left-click interaction as primary (added T8b for the `/lgs score`
  fallback). Version bumped to 0.303 in `Debug.lua`/`LevelingGears.toc`/`README.md`/`TESTERS.md`.
  `luac -p` and `luacheck` both pass clean on all three touched files (`GearEvaluation.lua`,
  `Scoring.lua`, `Core.lua`).
- 0.304 completed (on the new `single-profile` branch, forked from `main` right after the v0.303
  commit): removed the multi-profile system, reported as "lots of errors in the profile." There is
  now exactly one weight set per character — hand-adjust it or click "Restore Defaults," nothing to
  name or switch. `Settings.lua`: `characterState.profiles`/`activeProfile` replaced by a flat
  `characterState.weights`; `GetActiveProfile`/`SetActiveProfile`/`CreateProfile` removed;
  `GetCharacterState()` now returns the weight state directly, with a one-time migration pulling an
  existing character's previously active profile's weights into the new flat field (old
  `profiles`/`activeProfile` left in place afterward, unused, per this project's existing
  don't-destructively-edit-SavedVariables policy). `Weights.lua`/`GearEvaluation.lua`: swapped every
  `GetActiveProfile()` call for `GetCharacterState()` — same `.weights` shape, so no scoring-logic
  change. `UI.lua`: removed the entire "Profiles" section (header, hint, dropdown button/menu,
  divider, and their supporting `ToggleProfileMenu`/`RefreshProfileList` code); stat weights now
  anchor directly below general settings; the Save Settings confirmation message no longer names a
  profile. `Core.lua`: `InitializeProfileState` renamed `InitializeCharacterState`; removed the
  "Loaded profile 'X'" boot line; added a new one-time boot chat message explaining that weights
  don't auto-update on a respec/talent change and must be restored or re-adjusted by hand — the real
  fix for that is filed as `ROADMAP.md`'s new 0.35 (auto-updating defaults on respec/talent change),
  with 0.34 ("profile creation dialog") dropped as moot since there's no more profile to name. Also
  swept every remaining "profile"/"active profile" reference in code comments and docs
  (`Scoring.lua`, `Priorities.lua`, `DESIGN.md`, `CONVENTIONS.md`, `ROADMAP.md`, `README.md`,
  `TESTERS.md`, `TEST_PLAN.md`, `bugs/known-bugs.md`) to match the new single-weight-set model.
  Version bumped to 0.304. `luac -p` and `luacheck` both pass clean on all five touched Lua files.
- 0.305 completed (same `single-profile` branch): replaced the stat-weight rows' value+/-buttons
  with a direct-entry edit box, reported as "too complicated." `Weights.lua`: removed `WEIGHT_STEP`
  (the old 0.05 step size), `RoundToStep`, and the delta-based `SetWeight(statKey, delta)`; added
  `SetWeightValue(statKey, value)`, an absolute setter clamped to `WEIGHT_MIN`/`WEIGHT_MAX` (0-10).
  `FormatWeight` now rounds only the *display* to a hundredth to hide floating-point noise (e.g.
  7.099999999996) rather than snapping input to any step grid — whatever the player types is honored
  as typed. `UI.lua`'s `CreateStatRow`: removed the read-only value `FontString` and the
  `upButton`/`downButton` pair; added a single `EditBox` (`InputBoxTemplate`) per stat, pre-filled
  with its current value. `OnEnterPressed` commits and clears focus; `OnEditFocusLost` commits on
  clicking away; either path parses the typed text with `tonumber` and calls `SetWeightValue` if it's
  a real number, or calls the existing `UI.RefreshWeightLabels()` to revert the box to the actual
  saved value if it isn't — an invalid entry never looks like it was accepted. Renamed the module
  local `weightLabels` to `weightInputs` throughout `UI.lua` to match (same `:SetText()`-compatible
  shape, so `UI.SetWeightLabelText`/`UI.RefreshWeightLabels` needed no behavioral changes, just the
  rename). Kept the existing collapsible group structure (Core stats/Other stats/Resistances) and
  the "Restore Defaults" button — both confirmed as still wanted rather than assumed. Updated the
  stat-weights helper text, and every doc describing the old step/Shift-click mechanism
  (`README.md`, `ROADMAP.md`, `DESIGN.md`, `TESTERS.md`, `TEST_PLAN.md`'s T22/T23). Version bumped to
  0.305. `luac -p` and `luacheck` both pass clean on all 9 Lua files.
- 0.306 completed (same `single-profile` branch): removed the stat-weight edit box's remaining 0-10
  clamp and "importance scale" framing, reported as still showing "the 1-10 system" rather than the
  real value. Confirmed there was never a second hidden "real" number to expose — `Scoring.lua`'s
  `ComputeScore` already multiplies the derived stat by the exact value stored in
  `characterState.weights`; the 0-10 range and "0 = ignore, 10 = highest importance" wording were
  purely a UI-imposed ceiling/floor and framing left over from the original 0.2 design, not a
  reflection of any real internal unit. `Weights.lua`: removed `WEIGHT_MIN`/`WEIGHT_MAX` and the
  clamp inside `SetWeightValue` — the typed value (positive, negative, above 10, whatever) is now
  stored and used exactly as given, with `FormatWeight` still only rounding the *display* to a
  hundredth to hide floating-point noise. `UI.lua`: reworded the stat-weights helper text from
  "0 = ignore, 10 = highest importance..." to describe the box as showing the exact weight used when
  scoring items for that stat. Updated `README.md`/`ROADMAP.md`/`DESIGN.md` to stop describing a
  "0-10 scale," and added `TEST_PLAN.md` T22b to specifically test values outside the old 0-10 range.
  Logged as `bugs/resolved-bugs.md` #33. Version bumped to 0.306. `luac -p` and `luacheck` both pass
  clean on all 9 Lua files.
- 0.307 completed (same `single-profile` branch): replaced `Priorities.lua`'s hand-authored default
  weights with values sourced from real, cited TBC Classic (Burning Crusade Classic, 2.5.x) PvE
  stat-priority research, per direct request after bug #33 ("show the actual weights... it was data
  we searched the internet for... research done on simulators"). Dispatched three parallel research
  passes (Warrior/Paladin/Hunter, Rogue/Priest/Shaman, Mage/Warlock/Druid), each fetching Icy Veins'
  TBC-Classic-specific guide pages (Warcraft Tavern for Discipline Priest, which Icy Veins doesn't
  cover as its own page) and returning a cited priority order + cap/breakpoint numbers + avoid/
  situational notes per spec. Converted all 27 specs' real priority orders into numbers using one
  documented anchor scale (10/8/6/3/0, defined once in `Priorities.lua`'s header and applied
  consistently), citing the source URL directly above every one of the 54 speed/survival tables.
  Corrected real errors the old guessed placeholders had (e.g. Fury Warrior was previously assumed to
  value Haste above Arms; the actual cited source gives both specs the identical priority and
  explicitly says not to stack Haste for either spec). Documented the engine's honest limits directly
  in the file: these are rank-derived from real sources, not precise per-point sim multipliers;
  Hit/Expertise are cap-then-worthless stats that this addon's static per-item scoring cannot model
  dynamically, so they're weighted at their pre-cap importance; "survival" mode still has no real
  leveling-specific source to cite and remains a documented, unsourced defensive adjustment layered
  on the sourced "speed" baseline (same qualitative transform as before, just applied to real numbers
  now); Spirit still has no derived-stat key of its own (unchanged double-counting rule) so its
  priority is folded into MP5. Flagged two honest research gaps rather than inventing values:
  Discipline Priest's only found source (Warcraft Tavern) blocked a direct fetch and was retrieved
  via a proxy (flagged for manual spot-check), and Feral Druid Bear Tank's source gives no exact
  Defense-rating crit-immunity breakpoint. Wrote a standalone Lua verification script that loads
  `Priorities.lua` in isolation and confirms all 27 specs have complete `speed`/`survival` tables
  with all 25 required stat keys (zero gaps found), then deleted the script. Updated `DESIGN.md`'s
  Layer 3 description to match, replacing the old "authored design choices, not a lookup or a
  simulation result" framing. Version bumped to 0.307. `luac -p` and `luacheck` both pass clean on
  `Priorities.lua`.
- 0.308 completed (same `single-profile` branch): replaced `Priorities.lua`'s anchor-scale weights
  with values analytically derived from known TBC combat formulas, per direct feedback that v0.307
  was still a shortcut ("Why are we taking shortcuts instead of doing the math right"). Investigated
  what real numeric stat weights require: `wowsims/tbc` genuinely computes them via simulation
  (confirmed by direct fetch of its "Stat Weight Calculation" feature), but they're gear/talent/
  rotation-dependent and running it means standing up a Go/protobuf/node toolchain plus per-spec
  configs; also confirmed, by fetching Fury Warrior/Elemental Shaman/Retribution Paladin/Restoration
  Druid's pages directly, that only Warlock's guides publish a real numeric table -- every other
  class is rank-order only (Elemental Shaman's page explicitly recommends the Wowsims module "for
  precise calculations" since "real stat weights depend heavily on your current gear"). Confirmed the
  path forward directly: derive analytically rather than build a full simulator. Rewrote all 54
  speed/survival tables using verified formulas -- 14 Attack Power = 1 DPS (cited, cross-checked
  across multiple sources); a physical crit's +100% damage bonus and Haste's direct attack-frequency
  scaling place Crit/Haste at ~1.0x a spec's reference stat per 1%; Hit/Expertise's "a miss/dodge/
  parry is zero damage" effect (plus, for resource-based classes, forfeited resource/proc generation)
  places them at ~1.3x; Armor Penetration's nonlinear, target-armor-dependent mitigation curve
  discounts it to ~0.5x -- plus real, cited per-class corrections: Warriors' TBC rage-generation
  formula is normalized for attack speed (confirmed via research into the actual mechanic), so Haste
  is discounted to ~0.3x and Crit boosted to ~1.2x (crit-generated rage closes gaps between
  special-ability casts, letting more abilities fire); Elemental Shaman's Elemental Fury and Balance
  Druid's Vengeance talents genuinely double their nuke's crit bonus, boosting Crit's ratio; Shadow
  Priest's periodic damage and every HoT-healer's periodic healing cannot crit in TBC, discounting
  their Crit ratio. Used the two real published numeric tables found directly rather than
  approximating them: Warlock's Icy Veins "Spell Power Equivalency" table (Hit 1.901 SP, Haste 1.353
  SP, Crit 0.829 SP, Intellect 0.245 SP, Stamina 0 SP, Spirit 0.110 SP w/ Improved Drain Soul) and
  Restoration Shaman's explicit ratios (Heal 1.0, Haste 1.5, MP5 2.0, Crit 0.6, Intellect 0.5, Stamina
  0.2), both scaled consistently so each spec's primary throughput stat sits at a fixed reference of
  10. Caught and corrected a real conceptual error along the way: a guide's priority order blends true
  marginal value with itemization-scarcity advice ("you'll get plenty of this stat anyway," e.g.
  Warrior guides explicitly deprioritizing Strength/AP for being "abundant on gear," not for being
  worth less DPS) -- only the former belongs in a per-item scoring weight, so every spec's primary
  reference stat is kept at its full, un-suppressed value regardless of how a source ranked it. Added
  a `ROADMAP.md` "Past 1.0 — revisit later" entry to reconsider building a real simulator once the
  addon is otherwise feature-complete and stable. `DESIGN.md`'s Layer 3 description updated to match.
  Version bumped to 0.308. `luac -p` and `luacheck` both pass clean on `Priorities.lua`; the
  standalone structural verification script (all 27 specs, both modes, all 25 stat keys) was re-run
  with zero gaps found before being deleted again.
- **0.31 consolidation completed:** squashed the `single-profile` fork's iterative internal versions
  (v0.304-v0.308 above) into one shipped two-decimal release, per direct instruction once the fork's
  work was judged complete and stable enough to merge back. Version strings bumped to 0.31 in
  `Debug.lua`/`LevelingGears.toc`/`README.md`/`TESTERS.md` (also fixed two remaining stale
  `README.md` lines that still called `Priorities.lua`'s weights "authored" instead of
  derived-from-real-formulas). `ROADMAP.md`'s "Testing Phase 1 follow-ups" section: repurposed 0.31
  for this consolidated release and renumbered the old "minimap drag-to-reposition" item to 0.36 (its
  entry now explicitly notes the renumbering reason). `CONVENTIONS.md`'s versioning ladder: recorded
  the 0.31 reclamation with today's date, and clarified that patches to 0.31 follow the existing
  thousandths rule (0.311, 0.312… — not 0.301, which already exists as an unrelated, much earlier
  bugfix from before this fork). `CLAUDE.md`'s Current step and this file's Current status section
  rewritten to present 0.31 as the headline version, with the detailed v0.304-v0.308 history kept
  exactly as written (not retroactively renamed) both here and in `bugs/resolved-bugs.md` #31-#35, since
  that's the accurate record of how 0.31 was actually built. Fast-forward merged the `single-profile`
  branch into `main` (a clean linear history, no conflicts) and deleted the `single-profile` branch,
  per instruction that only one branch is needed going forward.
- 0.311 completed: surveyed the full bug ledger to find what's genuinely still open before calling
  0.31 done. Result: only bug #29 (window position drift) is `Open`; every other entry is `Solved` or
  `Mitigated` pending the next live test pass, not more code. Closed two research gaps flagged during
  the 0.31 `Priorities.lua` rework (bug #34/#35): found a real Defense-rating breakpoint for Feral
  Druid Bear Tank via a fresh search (raid bosses have a 5.6% crit chance against a tank; Survival of
  the Fittest suppresses 3%; the remaining 2.6% needs 2.4 Defense Rating per 0.1%, i.e. ~156 rating
  for full immunity through Defense alone — a real, Druid-specific number, distinct from the Warrior/
  Paladin ~490 Defense Skill figure since Druids have an equivalent crit-suppression talent those
  classes don't) and updated `Priorities.lua`'s comment to cite it; re-attempted Discipline Priest's
  citation (Warcraft Tavern's page still 403s a direct fetch, Wowhead's equivalent page is
  client-rendered with no static text to fetch) — no better source found, so the existing numbers
  stay, now noting a separate search result independently corroborated the Spirit-to-Healing ratio
  exactly. For bug #29, added `frame:GetScale()`/`frame:GetEffectiveScale()`/
  `UIParent:GetEffectiveScale()` logging to `SaveWindowPosition`/`ApplySavedPosition` (`UI.lua`)
  alongside the existing point/relativePoint/x/y capture — pure additional diagnostic capture, not a
  guessed fix, since the bug's "consistently offset, not random" symptom is exactly what a
  deterministic UI-scale mismatch between the drag session and a later login would produce; this way
  the next test pass's debug dump either confirms or rules out that theory immediately instead of
  needing a third round of "please get more data." Updated `bugs/known-bugs.md` #29's "Attempts to
  fix"/"Follow-up" and added a #34 update note. Version bumped to 0.311. `luac -p`/`luacheck` both
  pass clean on `UI.lua` and `Priorities.lua`.
- 0.312 completed: increased `Debug.lua`'s debug log ring buffer (`DEBUG_LOG_MAX_ENTRIES`) from 50 to
  500 entries, directly motivated by bug #29. Reading the on-disk debug log a second time (after the
  first read used in the 0.311 entry above) found the buffer had rolled forward and turned up real
  signal: three clean drag-then-reopen round-trips, all matching exactly at three different anchor
  points (`TOPLEFT`, `LEFT`, back to `TOPLEFT`), with `frame:GetScale()`/`GetEffectiveScale()`/
  `UIParent:GetEffectiveScale()` all exactly `1.0000` throughout — strong evidence the save/restore
  mechanism itself is sound, though not yet confirmed across an actual `/reload` or client relaunch
  (an ~11-minute gap in the log has no matching reopen entry, and none of the captured cycles were
  confirmed to span a real reload — the original report specifically emphasized "reloads and
  relogs"). The 50-entry cap had also already fully wrapped once during this same session, evicting
  whatever came before it started being visible — the actual motivation for this version: bump the
  cap generously (500 entries of short strings is still a negligible SavedVariables size) so a full
  debug-enabled play session doesn't lose data before it can be dumped. Updated `bugs/known-bugs.md`
  #29 with the full second-read findings and downgraded its status from "root cause unconfirmed" to
  "may already be resolved, pending direct confirmation." Updated `TEST_PLAN.md` T7's expected
  ring-buffer size to match. `luac -p` and `luacheck` both pass clean on `Debug.lua`.
- 0.313 completed: a third read of the on-disk debug log (now 123 entries, confirming the 0.312
  ring-buffer bump is working) reinforced bug #29's evidence further — 45 total position log lines
  now on record, still zero drift across three different anchor points (`CENTER`, `TOPLEFT`, `LEFT`),
  scale still exactly `1.0000` throughout. The same read surfaced a genuinely new bug: 61 identical
  "Gear evaluation: 17/17 slot buttons found, 14 items scored." log lines all timestamped the same
  second (`grep -c "Gear evaluation"` showed 78 total occurrences; `sed`/`sort`/`uniq -c` isolated the
  burst). Root cause: `GearEvaluation.lua`'s own game-event handler and the `CharacterFrame` `OnShow`
  hook both called `SafeCall(GearEvaluation.UpdateEquippedGearEvaluation)` directly instead of through
  `ScheduleGearEvaluation()` — the same 0.2s debounce bug #20/#21 built for rapid-fire weight-adjust
  clicks, which had never been wired to this event path. `UNIT_INVENTORY_CHANGED` alone can fire many
  times within the same second during ordinary play (bag/vendor/trade interactions), and every firing
  was triggering a full, undebounced 17-slot re-evaluation. Fixed by routing both call sites through
  `GearEvaluation.ScheduleGearEvaluation()` instead of a direct `SafeCall`. `luac -p`/`luacheck` clean
  on `GearEvaluation.lua`. Version bumped to 0.313. Full detail in `bugs/resolved-bugs.md` #36 (new)
  and `bugs/known-bugs.md` #29's third update.
- Bug ledger split completed (documentation-only, no version bump): requested directly that resolved
  bugs get their own file so outstanding bugs are easier to find, and because resolved history is
  genuinely useful evidence when troubleshooting a new hard-to-pin-down bug. Created
  `bugs/resolved-bugs.md` holding bugs #1-28 and #30-36 (35 entries total, original numbers kept,
  nothing renumbered); `bugs/known-bugs.md` now holds only bug #29, the sole remaining `Open` entry.
  Updated every live cross-reference to a moved bug number in `CONVENTIONS.md`, `DESIGN.md`,
  `ROADMAP.md`, `README.md`, `TESTERS.md`, `TEST_PLAN.md`, `CLAUDE.md`, and this file's own Progress
  log to point at `bugs/resolved-bugs.md` — left alone the handful of historical decision-log entries
  that just name which files were touched at a past point in time, since `resolved-bugs.md` didn't
  exist yet then. `CLAUDE.md`'s file table now lists both files, and its Current step section carries
  a standing instruction to check `bugs/resolved-bugs.md` first when troubleshooting a difficult bug.
  `CONVENTIONS.md`'s Mandatory maintenance rules updated to describe the two-file split and exactly
  when an entry should move from one to the other.
- 0.38 completed: live report of an Enhancement Shaman scored as Elemental (Spell Power recommended
  instead of Attack Power). Investigated `Scoring.DetectSpec`'s talent-tab comparison loop and found
  a real bug: two tabs tied on points spent resolved silently to tab order (tab 1 = Elemental for
  Shaman) instead of anything meaningful -- a real shape for a leveling build with points not yet
  fully committed to one tree, matching the report exactly. Fixed the tie-break to fall back to the
  documented `LOW_LEVEL_DEFAULT_SPEC` per-class default instead of trusting tab order, and added
  debug logging of all 3 tabs' raw point counts plus whether a tie was hit -- logged once per unique
  reading (not every call, since `DetectSpec` runs once per equipped slot scored and unconditional
  logging would reintroduce bug #36's spam) so a real `/lgs debug dump` can confirm the theory
  directly. Shipped the directly-requested fix in parallel: a new "Spec" settings section with a
  "Spec:" dropdown listing "Auto-detect" plus the player's class's 3 real specs (new
  `Scoring.SPEC_DISPLAY_NAMES`/`Scoring.GetSpecOptions`), wired through a new
  `Settings.SetSpecOverride` (stores `characterState.specOverride`, restores weights to the newly-
  correct spec's defaults so stale wrong-spec weights don't linger, refreshes the UI) which
  `DetectSpec` now checks before any talent-point reading. Added a `source` return value
  (`"override"`/`"detected"`/`"assumed"`) alongside the existing `assumed` boolean so
  `DescribeCurrentSpec()` and a new settings-window status line ("Currently scoring as: ...") can say
  `[manually set]` rather than leaving a spec guess's origin invisible. Updated `README.md` (new
  feature bullet; removed the now-stale "no spec auto-detection UI feedback" limitation) and
  `ROADMAP.md` (new 0.38 entry, marked Built). `luac -p`/`luacheck` clean on `Scoring.lua`,
  `Settings.lua`, `UI.lua`. Version bumped to 0.38 (a real new sub-feature, not a thousandths
  bugfix -- see `CONVENTIONS.md`'s versioning ladder, next free slot now 0.39). Full detail in
  `bugs/resolved-bugs.md` #37.
- 0.381 completed: reported again right after 0.38 shipped -- same Enhancement Shaman, now with all
  44 points in Enhancement (no ambiguity, not a tie), still auto-detected as Restoration. Disproved
  0.38's tie-break theory as the sole explanation: with one tab holding all 44 points, the comparison
  loop's own logic cannot mis-pick a different tab unless the per-tab point counts it's comparing are
  themselves wrong. Checked the real on-disk debug log for the new `DetectSpec:` line added in
  0.38 -- none were present, meaning the report likely predates the client picking up 0.38's code (a
  `/reload`/relaunch is required after any Lua file change). Regardless, this pointed back at what
  bug #27 already flagged as uncertain: `GetTalentTabInfo`'s aggregate `pointsSpent` return value,
  whose exact position this addon was only ever guessing at (`tonumber(c) or tonumber(d) or
  tonumber(e)`). Rather than guess a fourth position, replaced the whole method: `DetectSpec` now
  sums each individual talent's own `currentRank` (`select(5, GetTalentInfo(tabIndex, talentIndex))`
  for `talentIndex = 1, GetNumTalents(tabIndex)`) instead of trusting `GetTalentTabInfo`'s aggregate
  at all. Verified this is a real, working pattern rather than another guess by finding two other
  installed, actively-used addons on this exact client already doing exactly this: `ShamanPower.lua`'s
  own talent scan (`for i = 1, GetNumTalents(t) do ... GetTalentInfo(t, i) ... end`) and
  `PallyPower.lua`'s talent-point counter (`select(5, GetTalentInfo(tab, loc))`). `GetTalentTabInfo`
  is no longer called anywhere in the addon (removed from `.luacheckrc`'s globals; `GetNumTalents`/
  `GetTalentInfo` added instead). Updated stale `GetTalentTabInfo` references in code comments
  (`Scoring.lua`, `Priorities.lua`) and `DESIGN.md`'s low-level-fallback section. `luac -p`/`luacheck`
  clean on `Scoring.lua`. Version bumped to 0.381 (thousandths patch per direct instruction -- a
  bugfix, not a new sub-feature). Full detail in `bugs/resolved-bugs.md` #37's second update.
- 0.382 completed: first cycle of a bug-fix -> test -> ship loop the author asked to set up and
  repeat until ready for the database milestone (0.4). With bug #29 the only open bug and no further
  code fix possible without live evidence, bundled in roadmap item 0.37 (confirmed with the author)
  since it was small, fully scoped, and ungated. Added a helper-text line to the stat-weights section
  (`UI.lua`) explaining why Strength/Agility/Intellect/Stamina/Spirit aren't listed (auto-converted
  into the derived stats shown, per `DESIGN.md`'s double-counting rule) -- a real gap where a
  first-time player had no way to know why familiar stats were missing. Bumped
  `ReflowStatGroups`'s starting offset from -134 to -160 to make room for the new line (a reasoned
  estimate, not a measured value -- flagged in `TEST_PLAN.md`'s T13 for the upcoming test pass).
  `ROADMAP.md` cleanup: marked 0.37 Built (shipped under a thousandths patch rather than its own
  two-decimal slot, matching the 0.33/v0.303 precedent); fixed two stale "not built" references to the
  spec-override dropdown, which actually shipped in 0.38; rewrote the "Testing Phase 1 follow-ups"
  intro to state plainly that every item in it (0.31-0.38) is now Built and the section is done
  pending only a real `TEST_PLAN.md` T1-T35 pass. Deleted a stale, blank, never-filled untracked
  `TEST_RESULTS_Helio_0311` file. `luac -p`/`luacheck` clean on `UI.lua`. Version bumped to 0.382.
  This closes out every currently-known code fix -- see `CLAUDE.md`'s Next step for the test-pass ask.
