"""pipeline/extract_loot.py -- builds Sources[itemId] kind="drop" entries per ROADMAP.md's schema:

    { kind="drop", npcId=, dropRate=, obtainLevel= }

`creature_loot_template`'s `mincountOrRef` is the real wrinkle here (see DATA_PIPELINE.md and
CONVENTIONS.md's own note): a NEGATIVE value is not a literal item count at all -- it's a pointer
into `reference_loot_template` (world/shared loot tables reused by many creatures), and the actual
item + drop chance come from the referenced rows, not the pointer row itself.

`obtainLevel` uses the dropping creature's own `MinLevel` (creature_template) -- a judgment call
(MinLevel rather than MaxLevel or an average), since that's roughly when a player could first
realistically start farming this creature.

A first real run against this dump showed shared reference groups (a "generic humanoid trash loot"
pool, etc.) get reused by hundreds to thousands of different creatures -- one group alone was
referenced by 1,517 creatures and had 118 items in it, contributing 179,006 rows by itself, and
across ~900 such groups the total blew Sources.lua up to 162MB. Real data, not a bug -- but far too
much of it to name every one of 1,517 near-identical "generic mob" sources for the same item. Per
direct instruction, only ONE representative creature (the lowest-level one that has it) is kept per
item from a shared reference group -- direct, non-shared drops are never capped this way, since
those aren't the rows that were exploding. The real, more thoughtful data-curation pass (drop gear
that's not great for any class, deduplicate near-identical items, prefer easier/cheaper/nearer
equivalents) is `ROADMAP.md`'s own later phase, not attempted here.
"""

import logging
from pathlib import Path
from typing import Dict

import sql_extract

log = logging.getLogger("big_data.extract_loot")

CREATURE_LOOT_COLUMNS_NEEDED = ["entry", "item", "ChanceOrQuestChance", "mincountOrRef"]


def _build_creature_levels(sql_path: Path, tables: Dict[str, list]) -> Dict[int, int]:
    """Returns {creatureEntry: MinLevel} from creature_template."""
    levels = {}
    for row in sql_extract.extract_rows(sql_path, "creature_template", tables["creature_template"]):
        levels[row["Entry"]] = row["MinLevel"]
    log.info("creature_template: %d creatures", len(levels))
    return levels


def _build_reference_groups(sql_path: Path, tables: Dict[str, list]) -> Dict[int, list]:
    """Returns {referenceEntry: [(itemId, chance), ...]} from reference_loot_template."""
    groups: Dict[int, list] = {}
    row_count = 0
    for row in sql_extract.extract_rows(sql_path, "reference_loot_template", tables["reference_loot_template"]):
        row_count += 1
        groups.setdefault(row["entry"], []).append((row["item"], row["ChanceOrQuestChance"]))
    log.info("reference_loot_template: %d rows across %d reference groups", row_count, len(groups))
    return groups


def build_loot_sources(sql_path: Path, tables: Dict[str, list]) -> Dict[int, list]:
    """Returns {itemId: [{"kind": "drop", "npcId":, "dropRate":, "obtainLevel":}, ...]}."""
    creature_levels = _build_creature_levels(sql_path, tables)
    reference_groups = _build_reference_groups(sql_path, tables)

    sources: Dict[int, list] = {}
    # itemId -> best (obtainLevel, npcId, dropRate) candidate seen so far from a REFERENCE-resolved
    # row. Only the single best candidate per item is kept (see module docstring) -- direct rows
    # below are added straight to `sources` since those never exploded.
    best_reference_candidate: Dict[int, tuple] = {}

    direct_rows = 0
    resolved_reference_rows = 0
    unresolved_references = 0

    for row in sql_extract.extract_rows(sql_path, "creature_loot_template", tables["creature_loot_template"]):
        creature_entry = row["entry"]
        obtain_level = creature_levels.get(creature_entry)
        min_count_or_ref = row["mincountOrRef"]

        if min_count_or_ref >= 0:
            direct_rows += 1
            sources.setdefault(row["item"], []).append({
                "kind": "drop",
                "npcId": creature_entry,
                "dropRate": row["ChanceOrQuestChance"],
                "obtainLevel": obtain_level,
            })
            continue

        reference_entry = -min_count_or_ref
        referenced_items = reference_groups.get(reference_entry)
        if not referenced_items:
            unresolved_references += 1
            continue
        for item_id, chance in referenced_items:
            resolved_reference_rows += 1
            # Sort key: lowest obtainLevel wins (None sorts last -- an unknown level is a worse pick
            # than a known one); ties broken by npcId only for deterministic, reproducible output.
            candidate = (obtain_level if obtain_level is not None else 9999, creature_entry, chance)
            existing = best_reference_candidate.get(item_id)
            if existing is None or candidate < existing:
                best_reference_candidate[item_id] = candidate

    for item_id, (obtain_level, creature_entry, chance) in best_reference_candidate.items():
        sources.setdefault(item_id, []).append({
            "kind": "drop",
            "npcId": creature_entry,
            "dropRate": chance,
            "obtainLevel": None if obtain_level == 9999 else obtain_level,
        })

    if unresolved_references:
        log.warning(
            "%d creature_loot_template row(s) pointed at a reference_loot_template entry that "
            "doesn't exist -- skipped",
            unresolved_references,
        )
    log.info(
        "creature_loot_template: %d direct rows kept as-is, %d rows resolved through "
        "reference_loot_template but collapsed to %d representative entries (one per item) -- "
        "%d distinct items have at least one drop source",
        direct_rows, resolved_reference_rows, len(best_reference_candidate), len(sources),
    )
    return sources
