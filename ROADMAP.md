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

**This shape is now real, not just planned** — `pipeline/big_data.py --build-database` (cmangos
source only; Questie still license-blocked) produces real `Items`/`Sources`/`Quests`/`Chains`/
`Recipes`/`BySlot` Lua files exactly in this shape, and they're now wired directly into the addon
(`LevelingGears.toc` loads `pipeline/output/*.lua`, tracked in git — see `DATA_PIPELINE.md`'s Status
note) and consumed for real by `Suggestions.lua`. See `ROADMAP.md`'s own `0.41-0.44` entry below and
`DATA_PIPELINE.md`'s Status note for real numbers and known gaps (recipe reagents, zone names, the
shared-loot-pool size cap).

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
  box per stat, then in v0.306 the 0-10 ceiling itself was dropped — see `bugs/resolved-bugs.md` #32/
  #33 — since it was still being read as an artificial rating system rather than what it actually
  is.) What the player sees in the box **is** the real number `Scoring.lua`'s `ComputeScore`
  multiplies the derived stat by — there is no separate hidden value, and no imposed range.
  Per-character, saved.
  Every OTHER setting the addon ever gains (minimap toggle, suggestion count, source checkboxes,
  spec dropdown, TomTom row, etc.) also lives on THIS one scrolling page — there is no second
  settings screen anywhere in the app. (v0.385 reintroduced a real bound — 0-20, rejecting anything
  outside it with an explanatory popup instead of silently accepting or clamping — see this file's
  "Settings inventory" section and `bugs/resolved-bugs.md` #49.)
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
what already exists. **Every item below except 0.32 is now Built** — 0.32 (custom art) is real,
unbuilt work that had been sitting unmarked in this "all built" list by mistake; relocated to
"Coloring it in" below, where cosmetic polish actually belongs. (0.35, also unbuilt, was found
misfiled here the same way — also relocated.) What's left before Testing Phase 1 itself is over is
**not more building, it's a real `TEST_PLAN.md` T1-T35 pass** (see `PROGRESS.md`'s Current status /
`CLAUDE.md`'s Next step). Bug #29 (window position) is now closed — see `bugs/resolved-bugs.md` #29
— and `bugs/known-bugs.md` currently has zero open bugs. Once a full T1-T35 pass comes back clean (no
unresolved Blocker/Critical/Major findings — see `TESTERS.md`'s severity scale), the next real step
is `0.4` below, not before.

**That gate is now considered cleared as of v0.384** — remaining `queue.md` items were minor UX
polish, not Blocker/Critical/Major findings, and continued in parallel rather than blocking `0.4`.
**v0.385 closed two of them:** T20b's Auto-detect edge case (`bugs/resolved-bugs.md` #48) and
T23/T24's weight-ceiling validation (`bugs/resolved-bugs.md` #49). T13's blank-space polish is still
open (see `TEST_PLAN.md` T13). **The push to `0.4` is now the active work**, happening on the
`data_implementation` branch — see this file's `0.4`-`0.45` entries below and `DATA_PIPELINE.md`'s
Status note for where the pipeline (`big_data.py`) actually stands. Merges back to `main` once this
branch tests well.

- **0.31 — Consolidated release: single weight set per character, direct-entry stat editing,
  analytically-derived defaults.** Squashes the `single-profile` fork's iterative work (previously
  tracked internally as v0.304-0.308, kept in `PROGRESS.md`/`bugs/resolved-bugs.md` #31-#35 as the
  detailed history of how this was built) into one consolidated version once merged back to `main`.
  Replaces the multi-profile system with exactly one hand-adjustable weight set per character;
  replaces the stat-weight +/- buttons with a direct-entry edit box per stat, showing and accepting
  the exact value the scoring engine uses with no imposed scale; and replaces `Priorities.lua`'s
  default weights with values analytically derived from real TBC combat formulas (see `DESIGN.md`'s
  Layer 3 section) instead of either hand-authored guesses or an invented rank-to-number scale.
  **Built.**
- ~~**0.33 — Shift-click scoring on equipped items, replacing `/lgs score`.**~~ **Built in v0.303**,
  pulled forward and shipped as bug #30's real fix (`bugs/resolved-bugs.md` #30) rather than staying
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
  removed the multi-profile system entirely (repeated real bugs, see `bugs/resolved-bugs.md` #28 and
  the "single-profile" fork's PROGRESS.md entry) in favor of exactly one hand-adjustable weight set
  per character. There is no longer a profile to name.
- **0.36 — Minimap button: drag to reposition.** **Built (shipped in v0.384, out of numeric order —
  same versioning-ladder precedent as 0.37/0.38).** Right-click-and-drag moves the button around the
  minimap (the standard convention most players expect from an addon minimap icon); the new position
  (`settings.minimapAngle`) persists across sessions the same way window position does. Left-click
  still opens/closes the settings window; a plain right-click no longer also opens/closes it now that
  drag is its own distinct gesture — the "Known, accepted" note in `TEST_PLAN.md` about left/
  right-click doing the same thing has been removed to match. (Renumbered from 0.31, which the
  consolidated release above now occupies.)
- **0.37 — Explain, in the settings UI itself, why primary stats aren't weightable.** **Built (shipped
  in v0.382, out of numeric order — see `CONVENTIONS.md`'s versioning ladder for why this two-decimal
  slot shipped under a thousandths patch number instead of its own).** The stat-weights section only
  ever shows DERIVED stats (Attack Power, Spell Power, Crit Rating, Armor, Health, Mana, etc.) —
  Strength/Agility/Intellect/Stamina/Spirit have never had their own rows, since v0.25 (`DESIGN.md`'s
  double-counting rule: primaries are auto-converted into the derived stats already shown, so
  weighting them directly too would double-count). Nothing in the UI said this before — a player who
  opened the section for the first time and didn't see familiar stats like Strength had no way to
  know why. Added a small helper-text line (`UI.lua`, same small font as the existing helper text)
  explaining this in plain terms.
- **0.38 — Manual spec-override dropdown.** **Built.** A live report (an Enhancement Shaman scored
  as Elemental — spell power recommended instead of attack power) showed `DetectSpec`'s pure
  talent-point reading isn't reliable for a leveling character whose points aren't yet fully
  committed to one tree. Added a "Spec:" dropdown to a new "Spec" settings section: "Auto-detect"
  plus the player's own class's 3 real specs, overriding whatever the talent-point reading would
  otherwise guess, plus a status line showing which spec is actually being used right now (and
  whether it's auto-detected, assumed, or manually set). Also fixed a real bug in the auto-detection
  itself found while investigating this report: a tie between two talent tabs' point counts used to
  resolve silently to tab order rather than falling back to the documented low-level default — see
  `bugs/resolved-bugs.md` #37 for the full investigation and fix.

- **0.4 — Freeze the schema + hand-made sample.** **Superseded by the real thing.** Implement the
  exact table shapes above as real Lua files. Originally planned as a ~12-item HAND-MADE sample
  spanning every source kind (drop, quest, chain, craft, vendor, boe) so all later UI could be built
  and tested with zero pipeline — instead, `0.41-0.44` below shipped the real pipeline first, so the
  schema froze against real data (18,711 items, 6,599 quests) rather than a hand-made stand-in. This
  is the contract every other module codes against. **Shipped as v0.44.**
- **0.41 — Download the sources. 0.42 — Parser: quests first. 0.43 — Parser: loot + recipes.
  0.44 — Bake coordinates + merge.** **Built and shipped as v0.44** (cmangos-only — Questie
  still deferred, license unresolved) — `pipeline/big_data.py --build-database` runs all of it
  end-to-end against the real cmangos dump and writes real `Items`/`Sources`/`Quests`/`Chains`/
  `Recipes`/`BySlot` Lua files to `pipeline/output/`. Full detail — exact repo URLs, confirmed
  license status for each source, confirmed file/table structure, and the parser design — is in
  [`DATA_PIPELINE.md`](DATA_PIPELINE.md), not repeated here. Short version: cmangos tbc-db (GPLv3)
  supplies loot/quest-reward/vendor/recipe facts from its SQL dump; Questie's source Lua (license
  status unresolved — see `DATA_PIPELINE.md`) would add quest chain corrections and hand-verified
  pickup/turn-in details on top, once unblocked — basic chain ordering and coordinates turned out to
  need it less than expected (see below). Re-derive facts into our own schema and credit sources
  rather than redistributing either source directly; using cmangos for loot avoids AtlasLoot's GPL
  entirely.
  - **Real finding: quest pickup/turn-in coordinates don't need Questie at all.** cmangos's own
    `creature`/`gameobject` tables carry real spawn coordinates, and `creature_questrelation`/
    `_involvedrelation` (+ the `gameobject_*` equivalents) already say which NPC/object starts and
    finishes each quest. `DATA_PIPELINE.md` originally assumed this required Questie — it doesn't,
    for the basic case.
  - **Known gap: recipe reagents/created-item are empty.** `spell_template` — where a crafting
    spell's `Reagent1-8`/`EffectItemType` would come from — ships completely empty in this cmangos
    dump (confirmed: `DISABLE KEYS`/`ENABLE KEYS` with zero rows between them). Spell data is
    client-side DBC content cmangos doesn't redistribute in the SQL dump. Every `Recipes` entry
    currently has real `taughtBy`/`skill`/`prof` but empty `reagents`/`createsItemId` until a
    different source for that data is found (raises its own license question, same category as
    Questie — not yet investigated).
  - **Known gap: `zone` is a numeric map id, not a readable zone name.** Human-readable zone names
    (e.g. "Elwynn Forest") are Blizzard's client-side Area/Zone data, not present in this
    server-side SQL dump either — same category of gap as the reagent one above.
  - **Known gap: no way to tell a dungeon/instance drop apart from an overworld drop.**
    `extract_loot.py` builds every `kind="drop"` `Sources` entry from `creature_loot_template` joined
    only against `creature_template.MinLevel` — it never touches the `creature` spawn table (which
    would give a `map` id, the same join `extract_quests.py`'s `_build_spawn_locations()` already does
    for quest coordinates) or `creature_template.rank` (mangos's standard 0=normal/1=elite/
    2=rare-elite/3=boss/4=rare column, free from a table already being read but not currently
    selected). Without either, nothing in `Sources` can answer "is this a dungeon-boss drop" —
    surfaced by the "Begin suggesting" item below, which wants to guarantee a dungeon-blue candidate
    when one exists. Fix: join the spawn table for `map`, cross-reference against `instance_template`
    (or a hardcoded instance-mapId list) to classify world vs. instance, and select `rank` for a
    boss/elite/rare signal — not attempted yet, deferred until the suggestion engine actually needs
    it (which it does, but ships without this category in the meantime — see below).
  - **Known, deliberate simplification: one representative source per shared loot pool.** A first
    real run showed some `reference_loot_template` groups (shared "generic trash loot" tables) are
    reused by hundreds to thousands of different creatures — one group alone was referenced by 1,517
    creatures, blowing `Sources.lua` up to 162MB for what's mostly redundant near-duplicate entries.
    Collapsed to the single lowest-level qualifying creature per item for now (down to ~16MB) — the
    real fix is 0.46 below, not a bigger cap.
(0.45 and 0.46, originally planned here, are pure data-quality refinement on top of an already-working
suggestion flow — relocated to "Coloring it in" below, after the outline that actually needs them
first exists.)

### Starting to actually use the database

Everything below this line is ordered but **deliberately not version-numbered yet** — per direct
instruction, versioning past the current step stays loose ("we will increment as we make progress...
just put it in front of us and we will version change as it makes sense"). A version (thousandths
place, one patch = a batch of accepted fixes) gets assigned once each item is actually built, not in
this planning pass.

- **Settings window resize.** **Built.** Default size increased 40% (420x330 → 588x462); resizable
  by dragging the bottom two corners (top corners deliberately disabled per direct instruction).
  `SetResizable(true)` + a `Button`-type "sizer" frame per corner, `OnMouseDown` →
  `frame:StartSizing(corner)`, `OnMouseUp` → `StopMovingOrSizing()` + persists the new size the same
  way window position already persists. Real bug found and fixed during this build: `SetMinResize`/
  `SetMaxResize` silently aborted the rest of `UI.lua`'s load on this client (confirmed via two
  installed addons — Attune has `SetMinResize` commented out with a `--HC BUG` note; AceGUI-3.0
  calls it a pre-"WoW 10.0" API) — replaced with `SetResizeBounds` (falling back to
  `SetMinResize`/`SetMaxResize` only if `SetResizeBounds` doesn't exist). See `bugs/resolved-bugs.md`
  #47. Draggability is shown with a visible grip texture (Blizzard's own
  `Interface\ChatFrame\UI-ChatIM-SizeGrabber-*`, the same real pattern DBM-GUI uses for its own
  resize handle) rather than a cursor swap — no installed addon on this client uses a resize-specific
  `SetCursor` name, so this was chosen over guessing one. Also in this same batch: shift-clicking an
  equipped item no longer prints a score breakdown to chat (removed bug #30/T8's old chat-output
  behavior), and the trigger itself moved from shift+left-click to **shift+right-click** (per direct
  instruction — shift+left-click already means "insert item link in chat" to players).
- **Popout box.** **Built, but since superseded.** Shift+right-clicking an equipped item used to
  open a clickable flyout (`UI.ShowScorePopout`, still present in `UI.lua`) showing the score
  breakdown (item name, spec/score line, sorted per-stat breakdown) — closes via its own X button or
  by clicking anywhere else. This was `0.5`'s flyout-frame concept, built early. **Shift+right-click
  now opens the Suggestions window instead** (see "Begin suggesting" below) — `ShowScorePopout` is
  unreferenced by any click today, kept in place rather than deleted since nothing has asked for its
  removal.
- **Continent-aware querying.** **Built and confirmed live** (`Suggestions.GetPlayerLocation`) —
  `UnitPosition("player")`'s `instanceID` return was the right match after all: the on-disk debug log
  confirms it correctly resolved to `EASTERN_KINGDOMS` (instanceId=0) and, later the same session
  after the character actually traveled there, `OUTLAND` (instanceId=530) — real live confirmation,
  not an assumed mapping. Upgrade queries scope to "obtainable on your own continent first" per
  `Suggestions.lua`'s dynamic opposite-continent threshold (see "Begin suggesting" below).
- **Begin suggesting: the real recommendation engine.** **Built, live-verified, and merged to
  `main`** (`Suggestions.lua` + `SuggestionsUI.lua`) — confirmed via the on-disk debug log finding 6
  real candidates across multiple different slots (Head/Neck/Chest/Ranged/Feet/Wrist/Waist/Hands/Legs)
  in real live sessions, and the window (`SuggestionsUI.lua`, `0.6` below) confirmed actually
  rendering its content after bug #55 (`bugs/resolved-bugs.md`) was closed. Query `BySlot`/`Sources`/
  `Items`/`Quests` (all six now committed, real, and loaded — see this file's DATA section above and
  `DATA_PIPELINE.md`'s Status note) for actual upgrades to show the player, instead of `0.4`'s
  hand-made sample. Opens today via shift+right-click on an equipped item, or the `/lgs suggest
  <slot>` (text) / `/lgs suggestwindow <slot>` (window) debug commands — `0.5` below is the still-open
  gap for a real in-game trigger. Concrete design, decided per direct instruction:
  - **Hard rule: no downgrades, ever.** A candidate only enters the pool if its score beats the
    currently-equipped item's score for that slot — applied before any category logic touches the
    pool, not a display-side filter. **Built.**
  - **Level and armor-type filters**, added after live evidence showed the unfiltered pool was both
    slow (hundreds of never-cached items scanned per slot) and occasionally wrong (items the player
    couldn't even equip yet). Level window: `reqLevel` within 3 below to 3 above the player's own
    level (tightened from an initial, too-generous 15-below per direct instruction: "it should shave
    off possibilities quickly"). Armor type: restricts armor-slot candidates to the player's class's
    real proficiency type (with TBC's level-40 Mail unlock rule), while passing non-proficiency values
    (`"Miscellaneous"`, `"Shield"`, relics) through untouched. **Built** — two real bugs found and
    fixed along the way by checking the pipeline's actual generated data instead of assuming its
    shape: `reqLevel = 0` (4,313 real items) means "no requirement," not a literal level-0 requirement
    (`bugs/resolved-bugs.md` #52); armor slots also use `"Miscellaneous"`/`"Shield"`/relic values that
    aren't governed by class proficiency at all, and were being wrongly excluded before the fix
    (`bugs/resolved-bugs.md` #51).
  - **6 suggestions per slot**, chosen as a mix of guaranteed category diversity and pure score: one
    reserved slot per category that has at least one qualifying candidate (crafted, BOE/AH-obtainable,
    a same-continent quest close to the player, a same-continent quest further but not opposite-
    continent — plus a dungeon-blue category once the pipeline gap above is fixed; ships without that
    category for now, not faked), filled by that category's single best-scoring candidate; remaining
    slots up to 6 filled by pure score across the whole remaining pool (all categories, duplicates
    allowed). **Built.** Each candidate's shown info carries its `Sources` entry's `dropRate` forward
    (in addition to source kind, obtain level, etc.), not just used internally to pick candidates.
    **Real pivot from the original ask:** "a quest in the zone we're in" isn't buildable as literally
    specified — the pipeline's `zone` field is only a 4-value continent id, not a per-zone id (this
    file's known-gap note above). Used straight-line distance between the player's live position and
    each quest's pickup coordinates instead (both already in the data): "local" within 400 units,
    "nearby" within 1500, same-continent only — arguably more precise than zone-name matching, but
    those two distance numbers are unresearched starting points, not tuned against real zone sizes.
  - **Opposite-continent quest sources are excluded** from both the category quota and the score fill
    *unless* the candidate clears a dynamic margin, not a fixed threshold: it must beat the best
    same-continent candidate's score by a percentage that scales with how deep the same-continent pool
    already is — 0% margin at an empty local pool (any real upgrade qualifies, nothing local to prefer
    instead), up to 50% at 4+ local candidates ("if the pool is thin, trigger it easier; if everything
    we need is nearby, why bother unless it's incredible" — direct instruction). **Built**, not yet
    tuned against real play.
  - **Computed one slot at a time, not all 17 at once, to avoid a computation spike.** **Built**: a
    background queue walks the 17 equipped slots one per ~1.5s, warming the client's own `GetItemInfo`
    cache for each (there's no separate results cache — once an item's info is cached, `GetCandidates`
    just returns it instantly on its own). Wired to the tracked trigger events: `PLAYER_ENTERING_WORLD`
    (startup and real continent switches only, not every minor zone change), `PLAYER_EQUIPMENT_CHANGED`
    (gated on a genuinely new item via a persisted per-character "seen before" set), spec/level changes.
    Opening a slot's window bumps it to the front of the queue.
  - **Persistent suggestion memory.** **Built**, per direct instruction ("any upgrade you find, save
    the info about it... so you don't have to check as often"): once a real candidate is found for a
    slot, its item ID (not the full data, which is already baked pipeline data) is saved into the
    character's own SavedVariables, and re-verified live (never trusted blindly) as a fallback whenever
    a fresh check comes back empty purely from caching lag.
  - **UI requirements for the recommendation window (`0.6` below):** a **Refresh** button that
    re-runs just that slot's 6-candidate query on demand and a **Settings** button opening the main
    settings window without closing this one. **Built.**
- UI.lua reorganization: not split yet (707 lines across 5 sections as of this writing) — the
  popout box above and the recommendation window (`0.6`) are new frames that get their own new
  file(s) regardless of what happens to UI.lua itself; revisit UI.lua's size once those exist and
  its real shape is visible, rather than splitting preemptively now.

### Outline: close the loop from suggestion to action (continues directly from "Begin suggesting" above)

**Philosophy: draw the whole outline first, color it in after.** These three pick up exactly where
"Begin suggesting" above leaves off — get a full suggest → see it in game → act on it loop working
end to end, even crudely, before refining any single piece of it. "Coloring it in" below is
everything that only makes sense once this loop already works.

- **0.5 — Tooltip hook.** Hovering an EQUIPPED item adds a small Leveling Gears section for that
  slot. TECHNICAL REALITY: Blizzard's GameTooltip cannot host clickable buttons — tooltips aren't
  mouse-interactive and vanish when the cursor leaves the item. So implement as: informational
  lines appended INTO the tooltip (selected upgrade + where to get it), and the clickable actions
  ("Select Gears" / "next step") on a small separate clickable flyout frame anchored beside the
  tooltip, or triggered by a modifier key (e.g., "Alt+click to Select Gears") — propose the
  approach for review and record the chosen one here. No upgrade chosen for that slot → the Select
  Gears action. One chosen → show it + where to get it + the next-step action. **Not built** — this
  is the real in-game trigger for `SuggestionsUI.lua`'s window, which today only opens via debug
  commands (`/lgs suggestwindow <slot>`) or shift+right-click (which took over the old score-popout
  gesture — see `GearEvaluation.lua`). This is now the real, immediate next outline gap — the engine
  and window both work; the only thing missing is a real way for a player to reach them in normal play.
- **0.6 — Recommendation window.** **Mostly built and confirmed working live** as `SuggestionsUI.lua`
  (merged to `main`) — opens scoped to one slot, 6-row list (icon + name in native quality color + %
  upgrade + source summary + category tags), hovering a row shows the native item tooltip plus
  appended source/category lines, Refresh and Settings buttons. Not yet opened by a real trigger (0.5
  above is still an open decision). Still not built from the original spec: a character-summary
  header (name/level/color-rated gearscore) and a group-content marker — both cosmetic/informational
  additions on top of the working list, not blocking. Scores via the real engine (`Suggestions.lua`),
  real pipeline data, not the old `0.4` hand-made sample.
- **0.7 — Next-step engine.** Selected upgrade shows current next step and iterates it: quest
  chains advance to the first uncompleted quest (completed quests excluded everywhere); crafted
  items show reagents and open the profession window; recipe-is-a-drop shows the recipe's own drop
  source + rate (show the rate, player decides). TomTom present → button sets a waypoint (mob area,
  boss's dungeon, quest pickup, vendor, or AH for BoE). TomTom absent → button reads "Install
  TomTom for waypoints" and coords/zone still show as text. BoE: button also prints a clickable
  item link LOCALLY into the player's own chat frame (no self-whisper — client forbids it) so their
  pricing addon can act on it. **Not built** — this is what actually closes the outline: without it,
  a suggestion is just an inert list, not "tells you exactly where to get it" (this addon's own
  stated purpose). A minimal version (just show the location clearly as text) closes the loop before
  TomTom/chain-iteration polish is worth adding.

### Coloring it in (refinements on an already-working outline — build only once 0.5-0.7 all work end to end)

- **0.8 — Sorting & filters.** Sorts: **Best upgrade %** (default, top 3 by default, count
  configurable), **Most accessible** (composite of mob level vs player, elite/group, chain length —
  imperfect OK, list scrolls to less accessible), **Highest stats**, **By particular stat**.
  Source-type checkboxes, ALL ON by default (quest, dungeon, world/mob, craft, vendor, BoE/AH).
  Faction = HARD filter. Race = NOT filtered (show it, player judges the trip). Group-required
  content is explicitly marked so no one gets waypointed to an unsoloable dungeon blind.
- **0.9 — Equipped-gear glow, relative to a specific available upgrade.** `0.23` already built a
  self-relative version (**Built** — thin colored outline against the character's own gear average,
  see "Testing Phase 1 follow-ups" above) — this item is the real refinement on top of it: once 0.6/
  0.7's suggestion data exists, an outline can say "this slot is bad because a specific better item
  exists," not just "below your own average." Not buildable until the outline above is real (this
  was previously filed twice, once as a stale duplicate under "Deferred minor polish" as tester
  feedback T20 — merged here, one entry).
- **0.91 — Alt professions & crafter fallback.** Checkbox: consider alts' professions (needs the alt
  to have logged in once with the addon; per-character data unioned in a global SavedVariable —
  "known alts only"). Toggle: if no one you have can craft it, still show reagents + offer a
  pre-written trade-chat message to find a crafter. Both default on, both disableable.
- **0.45 — Auction House BOE scanner (supplemental, client-side, not part of the offline pipeline).**
  The baked `Items`/`Sources` tables from 0.41-0.44 come from static, offline sources (cmangos/
  Questie) — neither can tell us an item is a Bind-on-Equip that's realistically bought/sold on the
  AH rather than dropped/quested/vendored, since that's a live, realm-and-faction-specific economic
  fact, not something a static DB snapshot captures. Python has no access to a live game session, so
  this can't be a `big_data.py` pipeline step — it has to be an in-game Lua feature: while the player
  has the Auction House window open, page through current listings (respecting the client's own
  built-in query throttling, same as every other AH addon) and, for each item seen, check whether it
  already has an entry in our baked `Items`/`Sources` tables. If it does, skip it — a real drop/quest/
  vendor/craft source is always more useful than "buy it." If it doesn't, record a `kind="boe"`
  `Sources[itemId]` entry locally (a supplemental, addon-side SavedVariable table, not the baked
  data — AH content varies by realm/faction and can't be shipped as one global fact). This closes the
  gap for exactly the items the static schema already reserved `kind="boe"` for (see this file's
  "DATA" section above) but that the pipeline alone can never discover.
- **0.46 — Data curation pass (shrink the database down to what's actually worth recommending).**
  Scheduled for **after the addon works as envisioned otherwise, but before Alpha** — not now, and
  not by capping/sampling harder in the pipeline itself (0.41-0.44's one-representative-per-pool
  simplification is a stopgap, not this). The real fix is judgment, applied in phases, in this
  order:
  1. Eliminate gear that isn't great for any class/spec at all (scores poorly everywhere our engine
     evaluates it).
  2. Remove pieces that are very similar to another already-kept piece (near-duplicate stat spreads
     for the same slot).
  3. Between remaining equivalent options, prefer the one that's less difficult to obtain.
  4. Between remaining equivalent options, prefer the one that's cheaper to craft (fewer/cheaper
     reagents) over one that's equivalent but pricier.
  5. When recommending a source, prefer one that's geographically nearby the player when a
     comparably-good option exists, rather than always the single mathematically-best pick.
  This is what actually solves 0.41-0.44's file-size problem (162MB collapsed to 16MB by a blunt cap;
  this phase is the real, considered reduction) and is a prerequisite for a genuinely useful
  recommendation list, not just a smaller file.
- **0.32 — Custom art: minimap button icon/border, and the addon's own icon/logo.** The current
  minimap button uses a generic placeholder icon (`INV_Misc_Gear_01`) and the border appears larger
  than the clickable button itself. `CONVENTIONS.md`'s Branding section already calls for "a small
  gear meshing with a big gear" — this is where that actually gets designed and built, for the
  minimap button and anywhere else the addon shows its own icon. Pure cosmetic polish — relocated
  here from "Testing Phase 1 follow-ups" above, where it had been sitting unbuilt and unmarked.
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
  track. Decide and record the choice here before implementing. Relocated here from "Testing Phase 1
  follow-ups" above (same reason as 0.32 — unbuilt, was sitting unmarked in an "all built" list).

- **Debug log dump window (dev/tester tooling — not shipped to players; part of the debug suite
  `queue.md` Q6's ship/no-ship manifest strips from the player build).** Today `/lgs debug dump`
  prints the stored ring buffer straight to chat, which floods it on a large buffer. Give the dump
  its own **scrollable window that can display all stored messages at once** instead of dumping to
  chat — reusing the scrollable, copyable multiline-editbox infrastructure already built for the
  developer report window (`UI.ShowReportWindow`, #56). Because the window can display the whole
  buffer, **raise the log capacity to ~5000 entries** (from the current `DEBUG_LOG_MAX_ENTRIES = 2000`
  in `Debug.lua`) as part of this. This **supersedes the cancelled `queue.md` Q3** (an in-chat
  50-line cap) — the window is the full view, so no chat truncation is needed; `/lgs debug dump` opens
  here instead.
- **Player-friendly score presentation (was `queue.md` Q4, T8).** Today the score breakdown is a flat
  list of derived-stat contributions — useful for debugging, but not designed for a first-time player
  to read at a glance. Refine it into something a player can actually interpret. Note the moving
  parts around it: the raw `/lgs score` command is tester-only and slated for retirement once `0.5`'s
  tooltip hook exists (`queue.md` Q5), and shift+right-click now opens the Suggestions window rather
  than the old score popout — so this is really about how score *reasoning* is surfaced to players
  wherever it appears, not about polishing the debug command.

Smaller tester-feedback nitpicks live in `queue.md` instead of here — small enough to pick up one at
a time without needing a permanent roadmap slot. Of the original set: **error reports to the
developer** and **debug-toggle message clarity** are now **Built** (`bugs/resolved-bugs.md` #56/#57 —
`/lgs report`, a settings button, and a once-per-session offer on a caught error); `/lgs debug dump`'s
line limit was **cancelled**, superseded by the scrollable dump window above; `/lgs score` output
clarity was promoted to "Coloring it in" above; and retiring `/lgs score` once 0.5 exists is still
queued.

### Later
- **Spec guesser / chooser (later version).** Reads talent point distribution (e.g., 21/5/33),
  matches a table of popular builds (hand-made, expanded over time). Its ONLY job is to **fill in the
  visible weight boxes on the 0.2 page automatically** to a preset — the player watches them update and
  can still edit any box by hand afterward. It never hides or replaces the weight page; it's a
  convenience layer on top of it, not a separate scoring path. Dropdown to override the guess; must
  allow off-meta specs (Dreamstate Resto Druid, Shockadin, etc.). A wrong guess just means the player
  adjusts the same always-visible boxes themselves. (Superseded by the v0.25 scoring engine's
  automatic spec detection/default-weight seeding plus v0.38's "Spec:" override dropdown and status
  line — see `DESIGN.md` and `bugs/resolved-bugs.md` #37 — though this item's own "matches a table of
  popular off-meta builds" idea is broader than what 0.38 built and could still be revisited later.)
- **Proc/effect valuation (optional).** See the proc note under 0.2 — contingent on committing to
  the second scraped database.
- **Player/tester build split (release packaging).** Fully specified in `PACKAGING.md` (the
  ship/no-ship manifest): the player build is lean, its only diagnostic surface the error report;
  testers get a separate, fuller download with the whole debug suite. Implementation: delete the dead
  `ShowScorePopout` code, annotate no-ship commands/functions with `--@debug@` markers (plain
  comments — consumable by a local strip script or `git archive`, **not** Curse-dependent), express
  the file-exclusion list, emit the player zip, and **verify a stripped player build live**. Curse
  and non-Curse backends are both laid out in `PACKAGING.md`; the intended path for now is non-Curse
  (local script / `git archive`). A pre-Alpha release gate; the manifest exists now so it doesn't have
  to be reconstructed later.
- **A / B / 1.0** — per the versioning ladder (see `CONVENTIONS.md`); each requires explicit
  approval before starting.

### Past 1.0 — revisit later
- **Re-evaluate whether to "farm" `Priorities.lua`'s stat weights the real way: an actual simulator.**
  v0.307 sourced real TBC Classic stat *priority orders* (Icy Veins/Warcraft Tavern) and, where no
  numeric table existed (every spec except Warlock), derived weights analytically from known combat
  formulas (rating→% conversions, crit multipliers, attack-frequency math) rather than guessing —
  see `DESIGN.md`'s Layer 3 section and `bugs/resolved-bugs.md` #34/#35. This is real derived math, but
  it is NOT the same as running an actual simulator (e.g. `wowsims/tbc`, which computes true
  per-point DPS deltas for a specific gear/talent/rotation setup) — that would need real
  infrastructure (Go/protobuf/node toolchain, per-spec gear/rotation configs, a chosen reference
  gear baseline, and materially more time) that wasn't justified for a leveling addon's first pass.
  Once the addon is otherwise feature-complete and stable (post-1.0), it's worth revisiting whether
  the accuracy gain from real simulated weights is worth that infrastructure cost, or whether the
  analytical approximation has held up fine in practice by then.

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
screen exists anywhere. (The `0.6` recommendation window, `SuggestionsUI.lua`, is a separate frame,
but it is NOT settings — it is the per-slot upgrade picker, today opened via shift+right-click or a
debug command, eventually from `0.5`'s "Select Gears" tooltip action. Those are the only two frames.)

- Per-stat weights — the main content of the window, visible and directly editable from early (0.2);
  since 0.25 these are DERIVED-stat inputs only (primaries STR/AGI/STA/INT/SPI were removed from the
  list — see DESIGN.md), seeded with spec-aware defaults on first use, and later spec automation just
  fills these in. Each stat is a direct-entry edit box since v0.305 (replacing the 0.26-era up/down
  buttons with 0.05 steps and a Shift-click coarser ±1 — see `bugs/resolved-bugs.md` #32); v0.306
  removed the box's artificial 0-10 clamp/framing entirely (see `bugs/resolved-bugs.md` #33), and
  v0.385 reintroduced a real bound — 0-20, rounded to the nearest tenth, with a popup explaining
  exactly why a value outside that range (or non-numeric) gets rejected rather than a silent revert
  (see `bugs/resolved-bugs.md` #49) — so it shows and accepts the exact number `Scoring.lua`
  multiplies the stat by, within that bound. A "Restore Defaults" button in the same section resets
  the character's own weights back to the spec-aware defaults on demand. Since v0.304 there is
  exactly one weight set per character (no profiles — see the "Testing Phase 1 follow-ups" section
  above); defaults do not yet auto-update on respec (0.35). **Built.**
- Minimap button on/off. **Built.**
- Suggestion count (configurable, originally spec'd default 3). **Not built** — `SuggestionsUI.lua`
  currently shows a fixed 6 per slot (see "Begin suggesting" above), not yet a player-configurable
  count.
- Sort mode default. **Not built** (depends on 0.8).
- Source-type checkboxes (all on by default). **Not built** (depends on 0.8/data pipeline).
- Alt professions toggle; crafter-search fallback toggle. **Not built** (depends on 0.91).
- Spec override dropdown (adjusts the weights; also shows what's actually being used to score gear
  right now). **Built (0.38)** — see `bugs/resolved-bugs.md` #37.
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
