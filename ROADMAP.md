# ROADMAP.md — Leveling Gears

The staged feature roadmap, the target data shape it's building toward, and the full settings
inventory. Read this before proposing or starting the next build step, or whenever asked
"what's next" / "what's left." See `PROGRESS.md` for what's already been built and `CONVENTIONS.md`
for the versioning ladder that governs how each step gets numbered.

---

## DATA: the shape now vs. the shape we need (read before the roadmap)

This addon lives or dies on its data. Two source shapes exist and must be inverted into ours. (This
section is the rationale/target-shape overview; see [`DATA_PIPELINE.md`](DATA_PIPELINE.md) for the
actionable download links, confirmed license status, and parser design for turning one into the
other.)

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
                      -- runtime via GetItemStats (see CONVENTIONS.md's Technical notes; item must
                      -- be cached — GetItemInfo async rules apply). The client already knows every
                      -- item's stats; baking them would duplicate and desync.
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
  etc. — a finite, knowable list, not discovered dynamically). Each stat is a row the player sees and
  edits directly: the stat's name and its current value. Default: **every stat equal.** (Originally
  built as a 0-10 "importance" scale with up/down arrows; replaced in v0.305 by a direct-entry edit
  box per stat, then in v0.306 the 0-10 ceiling itself was dropped — see `bugs/known-bugs.md` #32/
  #33 — since it was still being read as an artificial rating system rather than what it actually
  is.) What the player sees in the box **is** the real number `Scoring.lua`'s `ComputeScore`
  multiplies the derived stat by — there is no separate hidden value, and no imposed range.
  Per-character, saved.
  Every OTHER setting the addon ever gains (minimap toggle, suggestion count, source checkboxes,
  spec dropdown, TomTom row, etc.) also lives on THIS one scrolling page — there is no second
  settings screen anywhere in the app.
- **0.21 — The scorer.** A function behind the page: score(item) = sum over the item's numeric
  stats of (statValue × that stat's weight). It reads the exact values shown on the 0.2 page.
  It has no results window YET (that's the recommendation window later), so at this step prove it
  with a print/debug against a couple of hand-typed fake items — but the WEIGHTS driving it are
  already fully visible and editable on the 0.2 page. Nothing about the weights is background.
  (Superseded in practice by the richer v0.25 three-layer scoring engine — see `DESIGN.md` — but
  the principle that weights are always visible/editable on this one page still holds.)
- **Proc/effect stats — LATER, OPTIONAL track.** "Chance on hit," "increases healing by up to N,"
  and use-effects are TEXT, not clean numeric stats; the client won't hand them over as
  multipliable numbers. v1 policy: **weight only clean numeric stats; ignore procs/use-effects in
  scoring** (item still appears, its normal stats still count). Assigning values to named effects
  would need a SECOND scraped database (e.g., an effect→value table) — spec this as an explicit
  future option, not something to build into early versions.

### Data pipeline (build the schema early; fill it in stages)
- **0.23 — Equipped-gear weakness evaluation.** Using the visible 0.2 weights, evaluate each
  equipped piece of gear against the character's current gear average. Show a thin colored outline
  around the item's slot button so the player can see at a glance which pieces are below average,
  at average, or above average for the current build. The color scale is relative to the largest
  gap in the current gear set, with green marking parity, red/orange/yellow marking weaker-than-
  average pieces, and cyan/blue/violet marking stronger-than-average pieces. This is a no-database
  step and is intentionally aimed at identifying improvement opportunities rather than producing a
  traditional "gear score".

### Testing Phase 1 follow-ups (found during v0.301 testing; gated on all current features passing)

These came out of the first real test pass (`TEST_PLAN.md`, v0.301) as things to build, not bugs in
what already exists. **Do not start any of these until every currently-built feature is confirmed
working** — fix what's broken first (see `bugs/known-bugs.md` #28-#30), finish the Phase 1
regression checklist, then come back here.

- **0.31 — Minimap button: drag to reposition.** Right-click-and-drag moves the button around the
  minimap (the standard convention most players expect from an addon minimap icon); the new position
  persists across sessions the same way window position does. Left-click still opens/closes the
  settings window. A plain right-click (no drag) no longer needs to also open/close the window once
  drag is its own distinct gesture — see the "Known, accepted" note in `TEST_PLAN.md` about left/
  right-click currently doing the same thing; that note goes away once this ships.
- **0.32 — Custom art: minimap button icon/border, and the addon's own icon/logo.** The current
  minimap button uses a generic placeholder icon (`INV_Misc_Gear_01`) and the border appears larger
  than the clickable button itself. `CONVENTIONS.md`'s Branding section already calls for "a small
  gear meshing with a big gear" — this is where that actually gets designed and built, for the
  minimap button and anywhere else the addon shows its own icon.
- ~~**0.33 — Shift-click scoring on equipped items, replacing `/lgs score`.**~~ **Built in v0.303**,
  pulled forward and shipped as bug #30's real fix (`bugs/known-bugs.md` #30) rather than staying
  gated — direct feedback on that bug ("too complicated... shift-click an equipped item to output the
  information about the gear into the chat") superseded the gating for this piece specifically.
  Implemented as **shift+left-click**, not the originally-requested shift+right-click: verified
  against FrameXML that right-click unconditionally fires `UseInventoryItem` regardless of
  modifiers (risking an unwanted trinket-proc etc.), while left-click already branches on Shift for
  its own safe "insert item link in chat" behavior — see bug #30 for the full reasoning. `/lgs score`
  stays working as the debug-bench fallback (per its original purpose — sanity-checking
  `Priorities.lua` — even after the click-based path exists).
  **Consequence for the future 0.6 "suggest gear" flow:** that feature was originally slated to use
  shift+left-click as its trigger gesture; shift+left-click is now taken by scoring, so 0.6 needs a
  different gesture (e.g. shift+right-click, alt+click, or a button in the tooltip) decided when that
  milestone is actually scoped — not decided here.
- ~~**0.34 — Profile creation dialog with a name field.**~~ **Dropped in v0.304.** The v0.304 fork
  removed the multi-profile system entirely (repeated real bugs, see `bugs/known-bugs.md` #28 and
  the "single-profile" fork's PROGRESS.md entry) in favor of exactly one hand-adjustable weight set
  per character. There is no longer a profile to name.
- **0.35 — Auto-updating default weights on respec/talent change.** Today `EnsureWeights` only ever
  seeds a stat the FIRST time it's missing (v0.25) and never again — spending a talent point or
  respeccing does not re-seed the character's weights, even though `DetectSpec` itself already
  re-runs on `CHARACTER_POINTS_CHANGED`/`PLAYER_LEVEL_UP` (`GearEvaluation.lua`). The player currently
  has to notice this themselves and click "Restore Defaults" or hand-adjust again (v0.304 added a
  one-time boot chat message explaining this limitation). This item is the real fix: defaults should
  update automatically whenever the player spends a talent point or changes spec. Needs a judgment
  call on scope before building: overwrite EVERY weight on every talent-point spend (matching
  `RestoreDefaultWeights`'s existing "start clean" behavior, but would also silently discard any
  hand-adjustment made since the last spec change), or only re-seed stats the player has never
  hand-touched (needs a new "touched by player" flag per stat, since today there's no way to tell a
  hand-set 5 apart from a seeded 5) — the second option preserves customization but is more state to
  track. Decide and record the choice here before implementing.

- **0.4 — Freeze the schema + hand-made sample.** Implement the exact table shapes above as real
  Lua files. Populate with a ~12-item HAND-MADE sample spanning every source kind (drop, quest,
  chain, craft, vendor, boe) so all later UI can be built and tested with zero pipeline. This is
  the contract every other module codes against.
- **0.41 — Download the sources. 0.42 — Parser: quests first. 0.43 — Parser: loot + recipes.
  0.44 — Bake coordinates + merge.** Full detail — exact repo URLs, confirmed license status for
  each source (Questie's has a real open question, not yet resolved), confirmed file/table
  structure, and the step-by-step parser design for both sources — is in
  [`DATA_PIPELINE.md`](DATA_PIPELINE.md), not repeated here. Short version: cmangos tbc-db (GPLv3)
  supplies loot/quest-reward/vendor/recipe facts from its SQL dump; Questie's source Lua (license
  status unresolved — see `DATA_PIPELINE.md`) supplies quest chain ordering, prerequisites, and
  coordinates. Re-derive facts into our own schema and credit sources rather than redistributing
  either source directly; using cmangos for loot avoids AtlasLoot's GPL entirely.

### The product (UI against sample data, then real data once 0.4x lands)
- **0.5 — Tooltip hook.** Hovering an EQUIPPED item adds a small Leveling Gears section for that
  slot. TECHNICAL REALITY: Blizzard's GameTooltip cannot host clickable buttons — tooltips aren't
  mouse-interactive and vanish when the cursor leaves the item. So implement as: informational
  lines appended INTO the tooltip (selected upgrade + where to get it), and the clickable actions
  ("Select Gears" / "next step") on a small separate clickable flyout frame anchored beside the
  tooltip, or triggered by a modifier key (e.g., "Alt+click to Select Gears") — propose the
  approach for review and record the chosen one here. No upgrade chosen for that slot → the Select
  Gears action. One chosen → show it + where to get it + the next-step action.
- **0.6 — Recommendation window.** Opens from "Select Gears," scoped to the hovered slot (gloves →
  glove upgrades). Layout top→bottom: header (name + icon + version), character summary (name,
  level, color-rated gearscore), then suggested items: each row = icon + name (native quality
  color), % upgrade, source summary, group-content marker. Hovering a row shows the NATIVE item
  tooltip (Blizzard renders stats free) PLUS our appended lines (source, drop %, quest/chain
  position, profession, mob/boss, dungeon, quest-giver location). Clicking selects it for the slot.
  Scores via the 0.21 engine; data from the sample table until the pipeline is done.
- **0.7 — Next-step engine.** Selected upgrade shows current next step and iterates it: quest
  chains advance to the first uncompleted quest (completed quests excluded everywhere); crafted
  items show reagents and open the profession window; recipe-is-a-drop shows the recipe's own drop
  source + rate (show the rate, player decides). TomTom present → button sets a waypoint (mob area,
  boss's dungeon, quest pickup, vendor, or AH for BoE). TomTom absent → button reads "Install
  TomTom for waypoints" and coords/zone still show as text. BoE: button also prints a clickable
  item link LOCALLY into the player's own chat frame (no self-whisper — client forbids it) so their
  pricing addon can act on it.
- **0.8 — Sorting & filters.** Sorts: **Best upgrade %** (default, top 3 by default, count
  configurable), **Most accessible** (composite of mob level vs player, elite/group, chain length —
  imperfect OK, list scrolls to less accessible), **Highest stats**, **By particular stat**.
  Source-type checkboxes, ALL ON by default (quest, dungeon, world/mob, craft, vendor, BoE/AH).
  Faction = HARD filter. Race = NOT filtered (show it, player judges the trip). Group-required
  content is explicitly marked so no one gets waypointed to an unsoloable dungeon blind.
- **0.9 — Equipped-gear glow.** Thin, clean, non-invasive colored outline showing upgrade need,
  computed RELATIVE to the character's OWN average item quality (a quest-gear player is judged
  against themselves, never dungeon standards).
- **0.91 — Alt professions & crafter fallback.** Checkbox: consider alts' professions (needs the alt
  to have logged in once with the addon; per-character data unioned in a global SavedVariable —
  "known alts only"). Toggle: if no one you have can craft it, still show reagents + offer a
  pre-written trade-chat message to find a crafter. Both default on, both disableable.

### Later
- **Spec guesser / chooser (later version).** Reads talent point distribution (e.g., 21/5/33),
  matches a table of popular builds (hand-made, expanded over time). Its ONLY job is to **fill in the
  visible weight boxes on the 0.2 page automatically** to a preset — the player watches them update and
  can still edit any box by hand afterward. It never hides or replaces the weight page; it's a
  convenience layer on top of it, not a separate scoring path. Dropdown to override the guess; must
  allow off-meta specs (Dreamstate Resto Druid, Shockadin, etc.). A wrong guess just means the player
  adjusts the same always-visible boxes themselves. (Partially superseded by the v0.25 scoring
  engine's automatic spec detection and default-weight seeding — see `DESIGN.md` — but a visible
  "assumed spec" indicator/override dropdown in the UI is still not built.)
- **Proc/effect valuation (optional).** See the proc note under 0.2 — contingent on committing to
  the second scraped database.
- **A / B / 1.0** — per the versioning ladder (see `CONVENTIONS.md`); each requires explicit
  approval before starting.

---

## The color system (used addon-wide, unanimously)

ROYGBIV, one consistent meaning everywhere:
**Red = urgent/worst → Orange → Yellow → Green = solid/good → Blue → Indigo/Violet = exceptional.**
Gearscore is never a number — it is a colored outline/rating on this scale. Glows use it. Item
NAMES keep Blizzard's native quality colors (a different, familiar system — do not mix the two).

---

## Settings inventory (ALL on the ONE scrolling settings window; build each when its step arrives)

There is exactly ONE settings window in this addon. Slash commands and the minimap button both open
it, and every setting below lives on that single vertically-scrolling page — no second settings
screen exists anywhere. (The 0.5 recommendation window is a separate frame, but it is NOT settings —
it is the per-slot upgrade picker opened from "Select Gears." Those are the only two frames.)

- Per-stat weights — the main content of the window, visible and directly editable from early (0.2);
  since 0.25 these are DERIVED-stat inputs only (primaries STR/AGI/STA/INT/SPI were removed from the
  list — see DESIGN.md), seeded with spec-aware defaults on first use, and later spec automation just
  fills these in. Each stat is a direct-entry edit box since v0.305 (replacing the 0.26-era up/down
  buttons with 0.05 steps and a Shift-click coarser ±1 — see `bugs/known-bugs.md` #32); v0.306
  removed the box's artificial 0-10 clamp/framing too, so it shows and accepts the exact number
  `Scoring.lua` multiplies the stat by, with no imposed scale (see `bugs/known-bugs.md` #33). A
  "Restore Defaults" button in the same section resets the character's own weights back to the
  spec-aware defaults on demand. Since v0.304 there is exactly one weight set per character (no
  profiles — see the "Testing Phase 1 follow-ups" section above); defaults do not yet auto-update on
  respec (0.35). **Built.**
- Minimap button on/off. **Built.**
- Suggestion count (default 3). **Not built** (depends on 0.6 recommendation window).
- Sort mode default. **Not built** (depends on 0.8).
- Source-type checkboxes (all on by default). **Not built** (depends on 0.8/data pipeline).
- Alt professions toggle; crafter-search fallback toggle. **Not built** (depends on 0.91).
- Spec override dropdown (later; adjusts the weights). **Not built** — the scoring engine detects
  spec automatically (v0.25), but there's no on-screen override control yet.
- TomTom integration (auto-detected; row explains if missing). **Not built** (depends on 0.7).

**Static footer:** a "Save Settings" button lives in a fixed footer below the scroll area (anchored
to the window frame itself, not the scroll child, so it never scrolls out of view — the same
structural exception as the title/version/close button at the top). Every setting already writes
into `LevelingGearsDB` the instant it changes; WoW addons have no separate manual "save" step, and
the client itself flushes SavedVariables to disk on `/reload`, logout, or exit (see
`CONVENTIONS.md`'s Technical notes). The button does NOT call `ReloadUI()` (an earlier version did,
briefly — see `PROGRESS.md` bug #18 — but there was nothing left to persist, so it just produced a
jarring no-op reload). It now only prints an honest chat confirmation that the character's settings
are saved.
