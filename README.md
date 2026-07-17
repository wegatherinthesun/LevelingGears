# Leveling Gears

A World of Warcraft addon for **TBC Classic Anniversary** that helps a leveling player judge their
own equipped gear against their own priorities — no external database or dungeon-standard "gear
score" required.

> **Status: early, active development (v0.385, plus unversioned work since).** The stat-weighting and
> scoring engine is built and usable today, and a first real upgrade-recommendation engine and window
> now exist too — shift+right-click an equipped item to see up to 6 real suggested upgrades for that
> slot. What's still missing: a proper in-game entry point for it (today it's shift+right-click or a
> debug command, not the planned tooltip hook) and the "next step" that actually walks you to go get
> one. See [Roadmap](#roadmap--current-limitations). If you're testing this addon, start with
> [`TEST_PLAN.md`](TEST_PLAN.md) — its "Quick start" has everything you need.

## What it does today

- **One settings window** (`/levelinggears` or `/lgs`, or the minimap button) — there is only ever
  one settings screen in this addon. Resizable by dragging its bottom-left or bottom-right corner
  (look for the grip icon in the bottom-right) if the default size doesn't suit you.
- **Weight the stats you care about** by typing directly into each stat's edit box — the exact
  number the scoring engine uses (0-20, rounded to the nearest tenth), no abstracted rating scale. A
  rejected value (negative, over 20, or not a number) pops up an explanation instead of silently
  reverting. Covers Spell Power, Healing, Attack
  Power, Ranged Attack Power, Health, Mana, every combat
  rating (Hit/Crit/Haste/Expertise/Armor Penetration/Defense/Dodge/Parry/Block/Resilience), Block
  Value, MP5, Spell Penetration, Armor, and all 5 resistances.
- **Spec-aware smart defaults, sourced from real TBC Classic theorycrafting.** Weights are pre-filled
  from your detected class/talent spec the first time you touch them, based on real, cited stat
  priority guides for that spec (see `Priorities.lua` for sources) — not a flat, meaningless "5" on
  everything. Fully hand-adjustable afterward, and a **Restore Defaults** button resets back to those
  researched values whenever you want a clean slate.
- **A "Spec:" dropdown** shows which spec is actually being used to score your gear right now, and
  lets you override the auto-detected guess with one of your class's 3 real specs — useful while
  leveling, when your talent points don't yet fully reflect your intended build.
- **Colored outlines on your equipped gear** — each item's slot gets a thin border colored red
  through violet, showing how it stacks up against the average of your *own* current gear (not a
  raid or dungeon standard), using your weights.
- **One weight set per character**, saved and restored automatically — hand-adjust it or click
  "Restore Defaults" any time.
- **Shift+right-click an equipped item** in the character window to open the Suggestions window for
  that slot — up to 6 real upgrade candidates (never a downgrade from what's equipped), each with its
  name in native item-quality color, upgrade %, and where to get it (drop, quest, craft, vendor, or
  Bind on Equip). Hover a row for the full native item tooltip; Refresh re-checks on demand; Settings
  opens the main settings window alongside it.
- **`/lgs score <item link>`** — a debug command that prints the same kind of breakdown for any
  item link (scored against the raw default priorities, not your own weights), so the underlying
  priority tables can be sanity-checked independent of any hand-adjustment.

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
3. **Derived priorities** — default weights per class/spec/mode, analytically derived from known TBC
   combat formulas (see `DESIGN.md`), used only to *seed* your own editable weights.

Keeping these separate is what prevents double-counting (e.g. weighting Agility directly *and* the
Attack Power/crit/armor it produces). Full rationale and every specific judgment call (rating
fallbacks, Druid form handling, low-level spec assumptions, etc.) are documented in
[`DESIGN.md`](DESIGN.md).

## Project structure

| File | Responsibility |
|---|---|
| `Debug.lua` | Chat printing, pcall safety, debug log, addon version |
| `Conversions.lua` | Live stat conversions + the Attack Power table |
| `Priorities.lua` | Default weights per class/spec/mode, derived from real combat formulas |
| `Scoring.lua` | Combines the above into a single item score |
| `Settings.lua` | SavedVariables: general settings, each character's own stat weights |
| `Weights.lua` | The weightable-stat list and weight-value math (set/seed/restore) |
| `GearEvaluation.lua` | Scores equipped items and colors their slot outlines |
| `UI.lua` | The settings window (all frames/widgets) |
| `Suggestions.lua` | The upgrade-recommendation engine: queries the pipeline data for real candidates |
| `SuggestionsUI.lua` | The recommendation window (opened via shift+right-click) |
| `Core.lua` | Slash commands and startup sequence |

See [`DESIGN.md`](DESIGN.md) for how these fit together.

## Roadmap / current limitations

Not built yet (see `ROADMAP.md` for the full staged roadmap):

- No tooltip integration — the recommendation window exists (shift+right-click an equipped item) but
  there's no way to reach it yet by just hovering an item, the originally-planned entry point.
- No "next step" — a suggestion shows what to get and roughly where, but nothing yet walks you
  through quest chains, opens the profession window for crafted items, or sets a TomTom waypoint.
- No sorting/filtering by source type, accessibility, or faction.
- No dungeon-vs-overworld distinction in drop sources yet (a real data-pipeline gap, not a design
  choice — see `ROADMAP.md`'s `0.41-0.44` entry).

## Development

This project keeps unusually thorough living documentation instead of relying on tribal knowledge,
split by purpose so a given change only needs to load the piece it actually needs:

- [`ROADMAP.md`](ROADMAP.md) — the staged feature roadmap and the target data shape. Start here.
- [`PROGRESS.md`](PROGRESS.md) — chronological build history, dated decisions, and current status.
- [`CONVENTIONS.md`](CONVENTIONS.md) — coding conventions, the WoW/Lua sandbox rules, process rules,
  the versioning ladder, and technical reference notes verified against this client.
- [`DESIGN.md`](DESIGN.md) — the scoring engine's architecture and every judgment call behind it.
- [`DATA_PIPELINE.md`](DATA_PIPELINE.md) — source URLs, license status, and parser design for the
  future data pipeline (roadmap steps 0.41-0.44).
- [`bugs/known-bugs.md`](bugs/known-bugs.md) — still-open bugs only. See also
  [`bugs/resolved-bugs.md`](bugs/resolved-bugs.md), the archive of everything already solved/mitigated.
- [`TEST_PLAN.md`](TEST_PLAN.md) — start here if you're testing this addon. A fillable checklist
  template with a "Quick start": save it, fill it in, email it back. Also the living record of what
  changed recently and what's at risk.
- [`TESTERS.md`](TESTERS.md) — optional extra context for testers (severity levels, environment
  notes, giving more detail on a serious finding) — not required reading.
- `.luacheckrc` — configuration for [luacheck](https://github.com/lunarmodules/luacheck), used as a
  local linter only; the addon itself has zero runtime dependency on it.

## License

Not yet decided.
