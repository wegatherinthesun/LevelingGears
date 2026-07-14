# Leveling Gears

A World of Warcraft addon for **TBC Classic Anniversary** that helps a leveling player judge their
own equipped gear against their own priorities — no external database or dungeon-standard "gear
score" required.

> **Status: early, active development (v0.301), entering Testing Phase 1.** The stat-weighting and
> scoring engine is built and usable today. The longer-term goal — pointing you at exactly where to
> get your next upgrade (quest, drop, vendor, recipe) — is planned but not built yet. See
> [Roadmap](#roadmap--current-limitations). If you're testing this addon, start with
> [`TEST_PLAN.md`](TEST_PLAN.md) — its "Quick start" has everything you need.

## What it does today

- **One settings window** (`/levelinggears` or `/lgs`, or the minimap button) — there is only ever
  one settings screen in this addon.
- **Weight the stats you care about**, 0–10, in fine 0.05 steps (hold Shift for a coarser ±1 jump).
  Covers Spell Power, Healing, Attack Power, Ranged Attack Power, Health, Mana, every combat
  rating (Hit/Crit/Haste/Expertise/Armor Penetration/Defense/Dodge/Parry/Block/Resilience), Block
  Value, MP5, Spell Penetration, Armor, and all 5 resistances.
- **Spec-aware smart defaults.** Weights are pre-filled from your detected class/talent spec the
  first time you touch them, so you're not starting from a flat, meaningless "5" on everything.
  Fully hand-adjustable afterward, and a **Restore Defaults** button resets back to those spec-aware
  values whenever you want a clean slate.
- **Colored outlines on your equipped gear** — each item's slot gets a thin border colored red
  through violet, showing how it stacks up against the average of your *own* current gear (not a
  raid or dungeon standard), using your weights.
- **Per-character profiles**, saved and restored automatically.
- **`/lgs score <item link>`** — a debug command that prints the full derived-stat breakdown and
  final score for any item, so you can sanity-check the numbers behind a color.

## Requirements

- World of Warcraft: **TBC Classic Anniversary** (the client build that reports `Interface: 20505`,
  2.5.x). Not tested on, or targeting, retail, other Classic versions, or Season of Discovery.

## Installation

Not yet published to CurseForge/Wago — install manually:

1. Download or clone this repository.
2. Place the folder at `World of Warcraft/_anniversary_/Interface/AddOns/LevelingGears`, so that
   `LevelingGears.toc` sits directly inside that `LevelingGears` folder.
3. **Fully restart the client** (not just `/reload`) the first time — the addon's SavedVariables
   declaration is only read on a full client start.
4. Type `/levelinggears` or `/lgs`, or click the minimap button, to open the settings window.

## Usage

| Command | Effect |
|---|---|
| `/levelinggears` or `/lgs` | Open/close the settings window |
| `/lgs debug` | Toggle debug logging on/off |
| `/lgs debug dump` | Print recent debug log entries to chat |
| `/lgs score <item link>` | Shift-click an item link after this command to print its score breakdown |

## How the scoring works, briefly

Three deliberately separate layers turn an item's raw stats into a score:

1. **Live conversions** — rating-to-percent, Agility→crit/armor, Intellect→spell crit, read from
   the game's own API so they're always correct for your character's actual level.
2. **One hardcoded table** — Attack Power per point of Strength/Agility, per class/form (the one
   thing the API doesn't expose directly).
3. **Authored priorities** — default weights per class/spec/mode, used only to *seed* your own
   editable weights.

Keeping these separate is what prevents double-counting (e.g. weighting Agility directly *and* the
Attack Power/crit/armor it produces). Full rationale and every specific judgment call (rating
fallbacks, Druid form handling, low-level spec assumptions, etc.) are documented in
[`DESIGN.md`](DESIGN.md).

## Project structure

| File | Responsibility |
|---|---|
| `Debug.lua` | Chat printing, pcall safety, debug log, addon version |
| `Conversions.lua` | Live stat conversions + the Attack Power table |
| `Priorities.lua` | Authored default weights per class/spec/mode |
| `Scoring.lua` | Combines the above into a single item score |
| `Settings.lua` | SavedVariables: general settings, per-character profiles |
| `Weights.lua` | The weightable-stat list and 0.05-precision weight math |
| `GearEvaluation.lua` | Scores equipped items and colors their slot outlines |
| `UI.lua` | The settings window (all frames/widgets) |
| `Core.lua` | Slash commands and startup sequence |

See [`DESIGN.md`](DESIGN.md) for how these fit together.

## Roadmap / current limitations

Not built yet (see `CLAUDE.md` for the full staged roadmap):

- No item database — "where to get this upgrade" (quest, drop, vendor, recipe) isn't implemented.
- No tooltip integration or recommendation window for unequipped upgrades.
- No sorting/filtering by source type, accessibility, or faction.
- No spec auto-detection UI feedback (the engine detects your spec internally, but there's no
  on-screen "assumed spec" indicator yet).

## Development

This project keeps unusually thorough living documentation instead of relying on tribal knowledge,
split by purpose so a given change only needs to load the piece it actually needs:

- [`CLAUDE.md`](CLAUDE.md) — small index: the current step, and which of the files below to read
  for a given kind of task. Start here.
- [`ROADMAP.md`](ROADMAP.md) — the staged feature roadmap and the target data shape.
- [`PROGRESS.md`](PROGRESS.md) — chronological build history, dated decisions, and current status.
- [`CONVENTIONS.md`](CONVENTIONS.md) — coding conventions, the WoW/Lua sandbox rules, process rules,
  the versioning ladder, and technical reference notes verified against this client.
- [`DESIGN.md`](DESIGN.md) — the scoring engine's architecture and every judgment call behind it.
- [`DATA_PIPELINE.md`](DATA_PIPELINE.md) — source URLs, license status, and parser design for the
  future data pipeline (roadmap steps 0.41-0.44).
- [`bugs/known-bugs.md`](bugs/known-bugs.md) — the working bug ledger (open/solved/mitigated).
- [`TEST_PLAN.md`](TEST_PLAN.md) — start here if you're testing this addon. A fillable checklist
  template with a "Quick start": save it, fill it in, email it back. Also the living record of what
  changed recently and what's at risk.
- [`TESTERS.md`](TESTERS.md) — optional extra context for testers (severity levels, environment
  notes, giving more detail on a serious finding) — not required reading.
- `.luacheckrc` — configuration for [luacheck](https://github.com/lunarmodules/luacheck), used as a
  local linter only; the addon itself has zero runtime dependency on it.

## License

Not yet decided.
