# Scoring engine design (v0.25) and file organization (v0.261)

## File map (v0.261)

The addon is split by responsibility, loaded in this order (see `LevelingGears.toc`):

1. **`Debug.lua`** — chat printing, pcall safety (`SafeCall`), the SavedVariables-backed debug log,
   and the addon version string. Loads first; every other file depends on `LG.Debug`.
2. **`Conversions.lua`** / **`Priorities.lua`** / **`Scoring.lua`** — the three-layer scoring engine
   (see below).
3. **`Settings.lua`** — the SavedVariables data layer: general (account-wide) settings and each
   character's own single weight set (`GetCharacterState`). No profiles (removed in v0.304 — see
   `bugs/known-bugs.md` #31).
4. **`Weights.lua`** — the weightable-stat list (`statDefinitions`) and weight math: 0.05-precision
   rounding/formatting, seeding defaults (`EnsureWeights`), hand-adjusting (`SetWeight`), and
   resetting to spec defaults (`RestoreDefaultWeights`).
5. **`GearEvaluation.lua`** — scores each equipped item and colors its paperdoll slot outline.
6. **`UI.lua`** — the single settings window: every frame/widget the addon shows, and the
   `Refresh*`/`Set*` functions that keep them in sync with SavedVariables.
7. **`Core.lua`** — loads last. Slash-command dispatch and the startup sequence that calls into
   the other modules once everything is loaded. Deliberately small.

**Layering rule:** `Settings.lua`/`Weights.lua` never touch a UI widget directly; they call a
narrow `LG.UI.*` hook (e.g. `LG.UI.SetWeightLabelText`) after mutating data, and `UI.lua` never
mutates SavedVariables directly; it calls `LG.Settings.*`/`LG.Weights.*`. This keeps "what changed"
(data) and "what's drawn" (widgets) separately testable and easy to locate.

**Cross-file calls use the shared `LG` namespace table**, not `local` forward-declarations: e.g.
`Weights.lua` defines `function Weights.SetWeight(...)` and `UI.lua` calls
`LG.Weights.SetWeight(...)`. A table field is resolved at CALL time, not parse time, so — unlike
the pre-0.261 single-file `Core.lua`, where several functions needed explicit `local X` forward
declarations to be callable before their own definition point (see known-bugs.md #11 and #22, both
caused by exactly this) — load/definition order among these files only matters for a file's own
top-level (immediately-executed) code, never for what a function body references, since every
function body only actually runs after the whole addon has finished loading.

---

This documents the three-layer stat-weighting/scoring engine added in v0.25
(`Conversions.lua`, `Priorities.lua`, `Scoring.lua`) and the specific judgment calls made while
building it. The architecture itself (three layers, exact TBC AP-per-primary table) was given and
implemented as specified, not designed from scratch.

## The three layers, and why they're separate files

1. **Conversions.lua, Layer 1 (live)** -- rating-to-percent, Agility-to-crit/armor,
   Intellect-to-spell-crit, read from the game's own API every time a score is computed. These
   scale with character level and current stats, so they are never hardcoded.
2. **Conversions.lua, Layer 2 (the one static table)** -- Attack Power per point of Strength/Agility,
   per class/form. The API has no clean way to expose this, so it's the one deliberately hardcoded
   piece of conversion data.
3. **Priorities.lua, Layer 3 (authored)** -- how much each DERIVED stat matters, per class/spec/mode.
   These are design choices from TBC leveling knowledge, not a lookup or a sim result.

Keeping these in separate files is the point: conversions are game mechanics (Layers 1-2), priorities
are opinions (Layer 3). Mixing them is exactly how double-counting bugs happen -- e.g. weighting
Agility directly AND weighting the Attack Power / crit% / armor it produces.

## The double-counting rule

`Scoring.lua` never weights a primary stat (STR/AGI/STA/INT/SPI) directly. Every primary is first
converted into a derived stat by `Conversions:ApplyConversions` (Layers 1-2), and only derived stats
(AP, RAP, SP, HEAL, HEALTH, MANA, HIT, CRIT, HASTE, EXP, ARMORPEN, ARMOR, DEF, DODGE, PARRY, BLOCK,
BLOCKVALUE, RESILIENCE, MP5, SPELLPEN, and the 5 resistances) ever get multiplied by a Layer 3
weight. This is why the settings UI's old "Core stats" group lost its STR/AGI/STA/INT/SPI sliders
in v0.25 and gained HEALTH and MANA instead -- those two are the derived stats Stamina and
Intellect actually turn into, and they needed a weight slot the old primary-only sliders never gave
them.

**Key-reuse simplification:** the derived-stat keys in `Conversions`/`Priorities`/`Scoring` are the
SAME short keys the settings UI already used (`AP`, `HIT`, `CRIT`, `ARMOR`, ...), not new verbose
names. This means `characterState.weights` (SavedVariables) and the Priorities tables share one vocabulary
with zero translation layer -- a stat's UI slider, its saved weight, and its Priorities default are
always the exact same key.

## Shaman Attack Power note

Shaman melee AP is **1 per Strength in TBC, not 2**. The 2-per-Strength change is a Wrath of the
Lich King change; using it here would silently overvalue Strength gear for Shamans on this client.

## Rating conversion fallback (judgment call)

`GetCombatRatingBonus(CR)/GetCombatRating(CR)` gives the live, level-correct %-per-point -- but only
when `GetCombatRating(CR) > 0`. A character with zero of some rating (e.g. a fresh level 20 with no
Hit gear yet) can't compute it that way. Chosen fallback: **the documented TBC level-70
rating-per-percent constants, applied uniformly regardless of the character's actual level**
(Defense 2.4, Dodge 18.9, Parry 22.4 -- the post-2.1-patch value, not the old 31.5 -- Block 7.9,
Hit/Haste 15.8, Crit 22.1, Expertise 3.9423, Resilience 39.4 rating per point/percent). This is the
simpler of the two options the brief allowed ("weight the rating at a conservative default" rather
than a full per-level lookup table), and erring toward the level-70 value rather than undervaluing
the stat is fine for a rough leveling guide, not a raid sim.

Rating TYPES are read via the named Blizzard globals (`CR_CRIT_MELEE`, `CR_HIT_SPELL`, etc.), never
hardcoded numeric indices -- those indices have changed across expansions (confirmed: retail's
current index list includes Mastery/Versatility/Multistrike slots that push TBC-era ratings to
different numbers than they'll have on this client). Reading the name and letting the running
client resolve it sidesteps needing to know the index at all.

**Armor Penetration Rating caveat:** itemization of Armor Penetration Rating didn't happen until
patch 3.0.2 (the pre-Wrath prepatch, after TBC's own content patches) -- `CR_ARMOR_PENETRATION` may
not exist, or may exist but never be populated by any TBC-era item, on this client. Guarded exactly
like every other rating, so it contributes 0 if there's nothing to report; the `ARMORPEN` slider
stays in the UI for the (unlikely) TBC item that does grant it.

**Hit/Crit/Haste offense-type simplification:** a single item stat ("Hit Rating") affects melee,
ranged, AND spell hit simultaneously in-game, but the addon only shows one slider for it. Each spec
is tagged with an `offense` ("melee"/"ranged"/"spell") in Priorities.lua, and Conversions uses
whichever `CR_HIT_*`/`CR_CRIT_*`/`CR_HASTE_*` matches that offense type for the whole derived value.
Documented simplification, not a precision claim.

**Spirit has no Layer 1 conversion.** The given architecture specifies only Stamina->Health,
Intellect->Mana, and Agility->crit%/armor as primary conversions -- Spirit was not among them. A
Spirit item still scores normally on its OTHER stats; only the Spirit value itself contributes
nothing. Revisit with a Spirit->regen conversion later if this proves to matter in practice.

## Druid form-for-scoring (given, not a judgment call)

Score using the form implied by the detected SPEC, not the live shapeshift form, so an item's score
doesn't flicker as the player actually shifts in and out of a form. Feral spec -> Cat form (melee
AP table) in speed mode, Bear form (tank AP table) in survival mode. Balance and Restoration always
use the Bear/other AP table entry (no Cat-only Agility-to-AP bonus) since neither typically fights
in Cat form. Bear-form Druids can't block or parry (no shield, no parry mechanic), so `BLOCK` and
`PARRY` are zeroed in the Bear-derived priority tables even though the rest of the tank archetype
applies.

## Low-level fallback spec (judgment call)

Under level 10 (0 talent points spent anywhere), no spec can be detected from
`GetTalentTabInfo`. One assumed default per class is used instead (`Priorities.LOW_LEVEL_DEFAULT_SPEC`):
Warrior->Fury, Paladin->Protection, Hunter->Beast Mastery, Rogue->Combat, Priest->Shadow,
Shaman->Enhancement, Mage->Fire, Warlock->Affliction, Druid->Balance. These are commonly-cited easy
TBC leveling specs, not a claim about optimal play; `DetectSpec` marks the result `assumed = true`
so a future UI could label it. Easily changed by editing that one table -- no logic depends on the
specific choices.

## `ScoreItem` vs `ScoreEquippedItem`

The task's literal contract is `LG:ScoreItem(itemStats, class, spec, mode) -> score`, scoring
strictly against Priorities.lua's authored table -- this is the debug-bench function `/lgs score`
uses, so the priority tables themselves can be sanity-checked against real items independent of any
player customization.

The actual in-game gear-outline evaluation needs the OPPOSITE: score against whatever the player has
saved in `characterState.weights` (seeded from Priorities once, then freely hand-adjustable forever,
per "the player can hand adjust these"). `Scoring:ScoreEquippedItem(itemStats, weights)` shares the
same Conversions/offense/apKey machinery as `ScoreItem` but takes the live weights table as a
parameter instead of re-reading Priorities. `GearEvaluation.lua`'s `GetEquippedItemScore` calls this
one, passing the character's own `weights` (one flat set per character since v0.304 — no profiles).

## Slash command: `/lgs score`, not `/lg score`

The task asks for `/lg score [itemLink]`. `/lg` was deliberately removed as a top-level command in
an earlier version (see `known-bugs.md` bug #5: "the addon now supports only `/levelinggears` and
`/lgs`"). Implemented as `/lgs score <item link>` (and `/levelinggears score`) instead, as a new
subcommand of the existing dispatcher, to avoid regressing that decision.

`HandleSlashCommand` lowercases its whole argument for the `debug`/`debug dump` subcommands. An item
link's `|H`/`|h` hyperlink escape pair is case-sensitive, so the `score` subcommand is matched
against the ORIGINAL casing and the item-link argument is never lowercased, avoiding a real bug that
would otherwise corrupt every pasted item link.

## Weight precision and Restore Defaults (v0.26)

The Priorities.lua tables ARE the defaults; `EnsureWeights` only ever seeds a key the player has
never touched, and a manual `+`/`-` click permanently overrides that key going forward. v0.26 made
this reversible and finer-grained without changing that basic model:

- **Restore Defaults** (`RestoreDefaultWeights` in `Weights.lua`) overwrites the character's ENTIRE
  `weights` table with the current `LG.Scoring:GetDefaultWeights()` result — the explicit
  "undo everything I've changed" action, distinct from `EnsureWeights`'s
  fill-only-what's-missing behavior.
- **0.05 step size** (`WEIGHT_STEP` in Core.lua): the visible scale and units stay the same simple
  0-10 bar ("0 = ignore, 10 = highest importance"), but each `+`/`-` click now moves 0.05 instead of
  a whole integer, rounded via `RoundToStep` to avoid floating-point drift, and displayed via
  `FormatWeight` with only as many decimals as needed (a whole number shows with none; "9.50" shows
  as "9.5", never a trailing zero) — keeping the display itself simple even though the underlying
  precision is finer.
- **Shift-click coarse step:** 0.05 alone would take up
  to 200 clicks to cross the full bar. Added a Shift-click modifier on both buttons for a coarser
  ±1 step, documented in the settings page's own helper text, so quick large adjustments and fine
  0.05 tuning are both available from the same two buttons rather than adding new UI elements.
  `WEIGHT_STEP` is a single named constant specifically so an even finer step (e.g. 0.01) is a
  one-line change later if ever wanted, per "allow for more precision if required."
