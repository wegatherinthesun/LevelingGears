# DATA_PIPELINE.md — Leveling Gears

Detailed plan for `ROADMAP.md`'s 0.41–0.44 steps: exactly where the source data comes from, how to
get it, and how the Python parser turns it into the schema `ROADMAP.md` already defines (`Items`/
`Sources`/`Quests`/`Chains`/`Recipes`/`BySlot`). `ROADMAP.md`'s roadmap entries for these steps just
point here so the staged-milestone list doesn't have to carry this much detail inline.

## Status

`pipeline/big_data.py --build-database` (built on the `data_implementation` branch) runs end-to-end
against the real cmangos dump and writes real `Items`/`Sources`/`Quests`/`Chains`/`Recipes`/`BySlot`
Lua files to `pipeline/output/` — **cmangos-only** (Questie still deferred, see below). See
`pipeline/README.md` for how to run it; see `ROADMAP.md`'s `0.41-0.44` entry for the full list of
real findings and known gaps from the first real run against actual data:
- Quest pickup/turn-in coordinates work with **no Questie dependency** (cmangos's own
  `creature`/`gameobject` + `*questrelation`/`*involvedrelation` tables are enough).
- Recipe `reagents`/`createsItemId` are **empty** — `spell_template` ships with zero rows in this
  dump (confirmed, not a parsing bug); a different source is needed, not yet investigated.
- `zone` is a numeric map id, not a human-readable zone name (same category of gap as the above —
  client-side DBC data cmangos doesn't ship).
- Shared loot-pool reference groups are collapsed to one representative creature per item as a
  stopgap (162MB -> 16MB) — the real fix is `ROADMAP.md`'s `0.46` data-curation phase, scheduled
  after the addon otherwise works, before Alpha.

**This output now ships as real, committed addon data (per direct instruction) — `LevelingGears.toc`
loads all six `pipeline/output/*.lua` files directly, and they're tracked in git (`.gitignore`
carves out exactly these six filenames from the rest of `pipeline/output/`'s otherwise-ignored build
artifacts).** Current total size is ~20MB (Sources.lua alone ~16MB) — accepted as the known cost of
real coverage for now, not blocking on `0.46`'s curation pass first: "everyone knew this would be a
big addon from the beginning." `Suggestions.lua` is the first consumer (see `ROADMAP.md`'s "Begin
suggesting" entry).

**Questie is intentionally not included yet.** Its license question (see Source B below) is still
open; the author is resolving it directly before that source gets touched by any code.

**Real data-shape quirks found while building `Suggestions.lua` (checked directly against the real
generated files, not assumed — see `bugs/resolved-bugs.md` #51/#52):**
- `Items[itemId].armorType` isn't only `"Cloth"`/`"Leather"`/`"Mail"`/`"Plate"` (the four real class
  armor-proficiency types) — it's also `"Miscellaneous"` (rings, necks, trinkets, cloaks),
  `"Shield"`, and `"Idol"`/`"Libram"`/`"Totem"` (relics), none of which are governed by class armor
  proficiency at all. Any future code filtering on `armorType` needs to allow-list just the four real
  proficiency types, not treat every other value as a mismatch.
- `Items[itemId].reqLevel` uses `0` (not `nil`) to mean "no real requirement was set" — confirmed
  4,313 real items carry this. Since `0` is truthy in Lua, `not item.reqLevel` alone does NOT catch
  this case; check `item.reqLevel == 0` explicitly too.

Everything below citing a URL, license, or file structure was checked directly (GitHub API/page
fetches) while writing this, not guessed — per `CONVENTIONS.md`'s "never invent/guess" rule. Where
something couldn't be confirmed without the actual file in hand, that's flagged explicitly rather
than asserted.

---

## Source A: cmangos tbc-db (loot, quests, professions)

- **Repository:** <https://github.com/cmangos/tbc-db> — "A content database for mangos-tbc, and
  World of Warcraft Client Patch 2.4.3."
- **License: GPLv3** (confirmed via GitHub's repo metadata). Any derived data we redistribute needs
  to stay compatible with that — re-deriving facts into our own schema and crediting the source
  (already the plan in `ROADMAP.md`) keeps us clear of GPL's copyleft triggering on the *addon's own
  code*, since we're not shipping their SQL or code, only facts extracted from it.
- **What's actually in the repo:** not one-file-per-table. The whole database ships as a single
  compressed SQL dump: `Full_DB/TBCDB_<version>_<codename>.sql.gz` (e.g.
  `TBCDB_1.10.0_ReturnOfTheVengeance.sql.gz` at the time this was checked — **the exact filename
  changes with each DB release, so check the `Full_DB/` folder for the current one instead of
  hardcoding this name**). Repo size is roughly 390 MB. There's also an `InstallFullDB.sh` script
  and MySQL-server installation docs — **we don't need any of that**; we only want the raw `.sql.gz`
  to parse offline, never a running MySQL server (matches `CONVENTIONS.md`'s "never a database
  server" rule for our own pipeline).
- **How to get it:** download (or `git clone --depth 1`) the repo, then decompress
  `Full_DB/<the current .sql.gz file>` to get one large `.sql` text file.
- **Table names we expect to need** (standard mangos-family schema — **names below are from general
  mangos-schema knowledge, not yet confirmed against this exact dump; confirm each one actually
  exists, with these columns, by grepping the decompressed `.sql` once it's downloaded, before
  writing parser code against it**):
  - `creature_loot_template` — creature → item drop rows, with a `mincountOrRef` column (negative
    value = pointer into `reference_loot_template`, must be resolved, not a literal count).
  - `reference_loot_template` — shared/world-drop loot tables referenced by the above.
  - `quest_template` — quest definitions including reward item columns.
  - `creature_template` — `MinLevel`/`MaxLevel` per creature, needed for `obtainLevel`.
  - `npc_vendor` — vendor sale listings (item + NPC + cost).
  - `skill_line_ability` and/or `item_template`'s recipe-related columns — profession recipe →
    taught-by mapping; exact table(s) TBD once the dump is in hand.
- **What we extract:** drop sources + rates (`Sources[itemId]` kind="drop"), quest rewards (feeds
  `Quests`), vendor sources (kind="vendor"), and recipe teaching/reagent data (`Recipes`).

## Source B: Questie source Lua (quest chains, coordinates, corrections)

- **Repository:** <https://github.com/Questie/Questie> (the live addon source, not a separate "data
  only" repo — a `Questie/QuestieDB` repo also exists on GitHub but the actual `Database/` folder
  lives inside the main `Questie/Questie` repo, confirmed by browsing it directly).
- **⚠️ License: NONE FOUND.** Checked GitHub's own license detection (reports `null`) and the
  repository's README text directly (no license section, no `LICENSE` file mention, no "all rights
  reserved" statement either). This is a real open question, not a detail to gloss over — **this
  needs a decision before 0.42 actually starts extracting Questie data**: either (a) find an
  explicit statement elsewhere (their Discord/wiki/CurseForge page) granting reuse rights, (b) ask
  the Questie maintainers directly, or (c) don't use Questie's source at all and rely solely on
  cmangos (GPLv3, unambiguous) plus hand-corrections for the handful of things cmangos alone won't
  give us (quest chain ordering, pickup/turn-in coordinates). Flagging this here rather than
  quietly proceeding as if it were already resolved.
- **Structure relevant to TBC:** `Database/TBC/` contains four files: `tbcItemDB.lua`,
  `tbcQuestDB.lua`, `tbcNpcDB.lua`, `tbcObjectDB.lua`. There's also a shared `Database/DropTables/`
  folder (loot-adjacent data Questie itself tracks) and `Database/Corrections/` (hand-applied fixes
  cmangos lacks — this is the specific value-add `ROADMAP.md` already called out).
- **Format (confirmed by reading `tbcQuestDB.lua` directly):** quest records are NOT named-key Lua
  tables. Each quest is a **positional array** keyed by quest ID, e.g.
  `QuestieDB.questData[questId] = { field1, field2, field3, ... }`, where what each position *means*
  is defined separately in a parallel `QuestieDB.questKeys` ordinal-index table (position 1 = name,
  2 = startedBy, 3 = finishedBy, 4 = requiredLevel, 5 = questLevel, 6 = requiredRaces bitmask, 7 =
  requiredClasses bitmask, 8 = objectivesText, 9 = triggerEnd/coordinates, 10 = objectives, and on
  through ~36 fields covering rewards, prequests, next-quest-in-chain, etc.). **The parser must read
  `questKeys` itself (not hardcode these position numbers from this document) so a future Questie
  update that reorders fields doesn't silently corrupt our extraction.**
- **What we extract:** `preQuestSingle`/`preQuestGroup` (prerequisites), `nextQuestInChain`,
  pickup/turn-in NPC or object IDs and their coordinates (from `triggerEnd`/`startedBy`/`finishedBy`
  plus the companion `npcDB.lua`/`objectDB.lua` spawn-coordinate data), and the `Corrections/` fixes.

## Target schema

Already frozen in `ROADMAP.md`'s "DATA: the shape now vs. the shape we need" section
(`Items`/`Sources`/`Quests`/`Chains`/`Recipes`/`BySlot`) — not repeated here. This file is only
about how the two sources above get turned into that shape.

---

## Parser design

### Reading Questie's Lua tables from Python (0.42)

Questie's data files are real Lua source (`dofile`-able), not JSON — Python can't `import` them
directly. Rather than adding a new dependency (a Lua-in-Python binding like `lupa`, which would need
compiling a C extension — against the "never require compiling anything from source" rule), use the
Lua interpreter already installed on this machine (Homebrew `lua`, already present for `luacheck`/
`luac` — see `PROGRESS.md`'s decision log) as a one-shot converter:

1. Write a small `.lua` script (lives in the pipeline folder, not the addon) that `dofile()`s
   Questie's `Database/TBC/tbcQuestDB.lua` (and the `Constants.lua`/`questKeys` file it depends on
   for field meanings) and walks the resulting `QuestieDB.questData`/`questKeys` tables.
2. That script serializes what we need to plain JSON. Rather than pull in a third-party Lua JSON
   library (another dependency + its own license to track), hand-write a ~30-40 line minimal
   serializer — we only ever need to encode strings, numbers, booleans, nested arrays/tables, which
   is a small, fully-controllable amount of code.
3. The Lua script writes `questdata.json` (or similar) to disk; the Python pipeline script reads
   that JSON with the standard library `json` module — no Lua dependency inside Python at all.
4. Python then re-shapes the JSON into our `Quests`/`Chains` schema, resolving `preQuestSingle`/
   `preQuestGroup`/`nextQuestInChain` into `Chains[chainId].steps` (ordered), and merging in
   NPC/object coordinates from the companion DB files (same Lua→JSON bridge, reused).

### Reading cmangos's SQL dump from Python (0.43 — "the genuinely hard part")

The dump is a MySQL-flavored `.sql` file (backtick identifiers, `ENGINE=InnoDB`, `AUTO_INCREMENT`,
etc.), not something SQLite can execute as-is. Two viable approaches — **recommended: (a)**, since
we only need a handful of tables out of the hundreds in the dump, and (b) is real, non-trivial work
for facts we're not using:

**(a) Recommended: targeted streaming extraction.** Decompress once, then stream the `.sql` file
line-by-line (it's too large to load into memory at once — ~390 MB repo, dump itself likely larger
uncompressed) with a Python regex that recognizes `INSERT INTO `creature_loot_template`` (and the
handful of other needed tables) and parses just those `VALUES (...)` tuples using Python's own
tokenizer for the comma-separated, quoted-string-aware value lists (a small hand-rolled parser, not
a full SQL parser — MySQL dump `INSERT` syntax is regular enough for this). Everything else in the
file is skipped without ever being fully parsed.

**(b) Fallback: load into SQLite.** Translate the subset of MySQL DDL/DML syntax the needed
`CREATE TABLE`/`INSERT INTO` statements use into SQLite-compatible syntax (strip `ENGINE=`/
`AUTO_INCREMENT`/backticks-as-MySQL-quoting quirks, keep backticks-as-identifiers since SQLite
accepts those) and load only the needed tables into a local `.db` file, then query them with normal
SQL. More robust if the targeted-regex approach in (a) turns out to be fragile against edge cases
in the dump's quoting/escaping, at the cost of writing a small MySQL-dump-subset-to-SQLite
translator first.

Once rows are extracted (either way): resolve `reference_loot_template` indirection (a negative
`mincountOrRef` on a `creature_loot_template` row is a pointer to a `reference_loot_template` row,
not a literal count — follow it before emitting the final `Sources[itemId]` entry), join
`creature_template` for `MinLevel`/`MaxLevel` → `obtainLevel`, and emit `drop`/`vendor`/`craft`
source entries per the target schema.

### Merge + bake (0.44)

Once both parsers emit their own partial `Items`/`Sources`/`Quests`/`Chains`/`Recipes` tables:

1. Merge by ID — a single `itemId` can gain `Sources` entries from both the cmangos parser (drop/
   vendor/craft) and the Questie parser (quest reward, folded into `Quests[questId]`'s reward list
   rather than `Sources`, per the existing schema note that reqLevel/obtainLevel and heavy detail
   live off the hot path).
2. Join quest pickup/turn-in NPC or object IDs to their spawn coordinates (from Questie's
   `npcDB`/`objectDB`) so `Quests[questId].pickup`/`.turnin` carry `{zone, x, y, npc}` inline —
   this is what removes the runtime Questie dependency TomTom integration would otherwise need.
3. Build the `BySlot[slot]` index as the final pass (just an ID list per slot, referencing the
   `Items` table already built).
4. Make the whole thing one repeatable script (`pipeline/build.py` or similar), so it can be re-run
   whenever cmangos or Questie publish an updated dump/source without hand-editing anything.

## Open items before 0.41 can actually start

- **Resolve the Questie license question above.** This blocks whether Questie is a source at all.
- Confirm the exact cmangos table/column names against the real downloaded dump (this document's
  table list is standard-schema-informed, not yet verified against this specific file).
- Decide (a) vs (b) for the cmangos SQL parsing approach once the dump's actual quoting/escaping is
  visible.
