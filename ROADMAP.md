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
  edits directly: the stat's name, its current value, and **up/down arrows** on a **0–10 scale** —
  **0 = ignore entirely, 1 = lowest importance, 10 = most important.** Default: **every stat
  equal.** The 0–10 is what the player sees and controls; internally map it to whatever real
  multiplier the scorer needs (the math is hidden, the sliders are not). Per-character, saved.
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
  future option only if the author wants it. Do NOT build it into early versions.

### Data pipeline (build the schema early; fill it in stages)
- **0.23 — Equipped-gear weakness evaluation.** Using the visible 0.2 weights, evaluate each
  equipped piece of gear against the character's current gear average. Show a thin colored outline
  around the item's slot button so the player can see at a glance which pieces are below average,
  at average, or above average for the current build. The color scale is relative to the largest
  gap in the current gear set, with green marking parity, red/orange/yellow marking weaker-than-
  average pieces, and cyan/blue/violet marking stronger-than-average pieces. This is a no-database
  step and is intentionally aimed at identifying improvement opportunities rather than producing a
  traditional "gear score".
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
  approach, let the author pick, record it here. No upgrade chosen for that slot → the Select Gears
  action. One chosen → show it + where to get it + the next-step action.
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
  matches a table of popular builds (hand-made, author-expanded). Its ONLY job is to **move the
  visible 0–10 sliders on the 0.2 page automatically** to a preset — the player watches them move and
  can still grab any slider by hand afterward. It never hides or replaces the weight page; it's a
  convenience layer on top of it, not a separate scoring path. Dropdown to override the guess; must
  allow off-meta specs (Dreamstate Resto Druid, Shockadin, etc.). A wrong guess just means the player
  adjusts the same always-visible sliders themselves. (Partially superseded by the v0.25 scoring
  engine's automatic spec detection and default-weight seeding — see `DESIGN.md` — but a visible
  "assumed spec" indicator/override dropdown in the UI is still not built.)
- **Proc/effect valuation (optional).** See the proc note under 0.2 — only if the author commits to
  the second scraped database.
- **A / B / 1.0** — per the versioning ladder (see `CONVENTIONS.md`), gated by the author.

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

- Per-stat weights, 0–10, up/down arrows — the main content of the window, visible and directly
  editable from early (0.2); since 0.25 these are DERIVED-stat sliders only (primaries STR/AGI/
  STA/INT/SPI were removed from the list — see DESIGN.md), seeded with spec-aware defaults on
  first use, and later spec automation just moves these sliders. Since 0.26, steps move in 0.05
  increments (Shift-click for a coarser ±1), and a "Restore Defaults" button in the same section
  resets the whole active profile back to the spec-aware defaults on demand. **Built.**
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
jarring no-op reload). It now only prints an honest chat confirmation of the current profile.
