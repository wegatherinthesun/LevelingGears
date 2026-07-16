"""pipeline/extract_recipes.py -- builds Recipes[recipeId] entries per ROADMAP.md's schema:

    Recipes[recipeId] = { prof, skill, reagents={ {itemId,n}, ... }, taughtBy=, recipeDropRate= }

Draws on tables confirmed real by inspect_schema.py's schema_report.txt:
- npc_trainer / npc_trainer_template: which NPC teaches which spell (trainer-taught recipes).
- item_template (class == 9, WoW's ItemClass "Recipe"): which item teaches which spell
  (drop/vendor/quest-taught recipes -- the item itself is already a normal Items/Sources entry;
  this just links it to the spell it teaches).
- skill_discovery_template: spells learned by random chance while crafting (e.g. rogue poisons).
- spell_template: the actual crafting spell's Reagent1-8/ReagentCount1-8 (consumed) and its
  "create item" effect's EffectItemTypeN (created) -- this is where reagents/output actually come
  from, not from any of the tables above.

Two things below are general WoW-server domain knowledge (mangos/TrinityCore's published, stable
enums), not something this specific dump defines or that this script has verified against a header
file in this exact repo -- flagged here rather than silently assumed correct:
- SPELL_EFFECT_CREATE_ITEM = 24 (which EffectN slot means "this spell creates an item").
- PROFESSION_SKILL_IDS (Blizzard's client-side Skill-line.dbc isn't in this server-side SQL dump at
  all, so these numeric ids can't be confirmed from the dump itself -- worth double-checking against
  a second source before trusting this table blindly).
"""

import logging
from pathlib import Path
from typing import Dict

import inspect_schema
import sql_extract

log = logging.getLogger("big_data.extract_recipes")

SPELL_EFFECT_CREATE_ITEM = 24

PROFESSION_SKILL_IDS = {
    129: "First Aid",
    164: "Blacksmithing",
    165: "Leatherworking",
    171: "Alchemy",
    182: "Herbalism",
    185: "Cooking",
    186: "Mining",
    197: "Tailoring",
    202: "Engineering",
    333: "Enchanting",
    356: "Fishing",
    393: "Skinning",
    755: "Jewelcrafting",
}

REAGENT_COLUMNS = [f"Reagent{i}" for i in range(1, 9)]
REAGENT_COUNT_COLUMNS = [f"ReagentCount{i}" for i in range(1, 9)]
EFFECT_COLUMNS = [f"Effect{i}" for i in range(1, 4)]
EFFECT_ITEM_COLUMNS = [f"EffectItemType{i}" for i in range(1, 4)]


def _collect_trainer_taught(sql_path: Path, tables: Dict[str, list]) -> Dict[int, dict]:
    """Returns {spellId: {"taughtBy": npcOrTemplateId, "reqskill": ..., "reqskillvalue": ...}}.

    `npc_trainer`/`npc_trainer_template` teach EVERY kind of trainer-taught spell, not just
    tradeskill recipes -- class trainers (e.g. a Warrior trainer teaching "Heroic Strike Rank 5")
    use the exact same tables with `reqskill = 0`. A first real run against this dump showed 1770 of
    2676 "recipes" had `reqskill == 0` -- almost certainly class abilities, not recipes. Only keep
    rows whose `reqskill` is a real tradeskill profession (PROFESSION_SKILL_IDS), which correctly
    excludes class trainers, riding trainers (skill 762), and language/faction skills.
    """
    taught = {}
    skipped_non_profession = 0
    for table in ("npc_trainer", "npc_trainer_template"):
        before = len(taught)
        for row in sql_extract.extract_rows(sql_path, table, tables[table]):
            spell_id = row["spell"]
            if not spell_id:
                continue
            if row["reqskill"] not in PROFESSION_SKILL_IDS:
                skipped_non_profession += 1
                continue
            if spell_id not in taught:
                taught[spell_id] = {
                    "taughtBy": row["entry"],
                    "reqskill": row["reqskill"],
                    "reqskillvalue": row["reqskillvalue"],
                }
        log.info("%s contributed %d new spell(s)", table, len(taught) - before)
    log.info("Skipped %d trainer-taught spell(s) with a non-profession reqskill (class/riding/etc.)",
              skipped_non_profession)
    return taught


def _collect_item_taught(sql_path: Path, tables: Dict[str, list]) -> Dict[int, int]:
    """Returns {spellId: itemId} for recipe items (item_template class == 9) that teach a spell."""
    taught = {}
    scanned = 0
    for row in sql_extract.extract_rows(sql_path, "item_template", tables["item_template"]):
        scanned += 1
        if row["class"] == 9 and row["spellid_1"]:
            taught[row["spellid_1"]] = row["entry"]
    log.info("item_template: %d rows scanned, %d recipe items (class==9) found", scanned, len(taught))
    return taught


def _collect_discovery_taught(sql_path: Path, tables: Dict[str, list]) -> Dict[int, dict]:
    """Returns {spellId: {"taughtBy": "discovery", "recipeDropRate": chance}}."""
    taught = {}
    for row in sql_extract.extract_rows(sql_path, "skill_discovery_template", tables["skill_discovery_template"]):
        taught[row["spellId"]] = {"taughtBy": "discovery", "recipeDropRate": row["chance"]}
    log.info("skill_discovery_template: %d spell(s)", len(taught))
    return taught


def _spell_reagents_and_output(sql_path: Path, tables: Dict[str, list], recipe_spell_ids: set) -> Dict[int, dict]:
    """Returns {spellId: {"reagents": [[itemId, count], ...], "createsItemId": itemId or None}}."""
    results = {}
    scanned = 0
    for row in sql_extract.extract_rows(sql_path, "spell_template", tables["spell_template"]):
        scanned += 1
        spell_id = row["Id"]
        if spell_id not in recipe_spell_ids:
            continue

        reagents = []
        for reagent_col, count_col in zip(REAGENT_COLUMNS, REAGENT_COUNT_COLUMNS):
            item_id, count = row[reagent_col], row[count_col]
            if item_id:
                reagents.append([item_id, count])

        creates_item_id = None
        for effect_col, effect_item_col in zip(EFFECT_COLUMNS, EFFECT_ITEM_COLUMNS):
            if row[effect_col] == SPELL_EFFECT_CREATE_ITEM:
                creates_item_id = row[effect_item_col]
                break

        results[spell_id] = {"reagents": reagents, "createsItemId": creates_item_id}

    log.info("spell_template: %d rows scanned, %d matched a known recipe spell id", scanned, len(results))
    return results


def build_recipes(sql_path: Path, tables: Dict[str, list] = None) -> Dict[int, dict]:
    """Merges all four sources above into ROADMAP.md's Recipes[recipeId] shape. `tables` lets a
    caller that already scanned the schema (e.g. build_database.py) skip re-scanning it here."""
    if tables is None:
        log.info("Confirming real column order for every table this extractor touches...")
        tables = inspect_schema.scan_sql_file(sql_path)

    trainer_taught = _collect_trainer_taught(sql_path, tables)
    item_taught = _collect_item_taught(sql_path, tables)
    discovery_taught = _collect_discovery_taught(sql_path, tables)

    all_spell_ids = set(trainer_taught) | set(item_taught) | set(discovery_taught)
    log.info("Total distinct recipe spell ids across all 3 teaching methods: %d", len(all_spell_ids))

    spell_data = _spell_reagents_and_output(sql_path, tables, all_spell_ids)
    if "spell_template" not in tables or not spell_data:
        log.warning(
            "spell_template has no rows in this dump (confirmed: DISABLE/ENABLE KEYS with nothing "
            "in between) -- cmangos tbc-db does not ship spell reagent/effect data at all, it isn't "
            "just missing for these specific spells. Every recipe below will have empty reagents/"
            "createsItemId until a different source for that data is found -- see DATA_PIPELINE.md."
        )

    recipes = {}
    missing_spell_data = 0
    for spell_id in all_spell_ids:
        data = spell_data.get(spell_id)
        if not data:
            missing_spell_data += 1
            data = {"reagents": [], "createsItemId": None}

        if spell_id in trainer_taught:
            taught_by = trainer_taught[spell_id]["taughtBy"]
            skill = trainer_taught[spell_id]["reqskill"]
            recipe_drop_rate = None
        elif spell_id in item_taught:
            taught_by = item_taught[spell_id]
            skill = None
            recipe_drop_rate = None
        else:
            taught_by = discovery_taught[spell_id]["taughtBy"]
            skill = None
            recipe_drop_rate = discovery_taught[spell_id]["recipeDropRate"]

        recipes[spell_id] = {
            "prof": PROFESSION_SKILL_IDS.get(skill, skill),
            "skill": skill,
            "reagents": data["reagents"],
            "createsItemId": data["createsItemId"],
            "taughtBy": taught_by,
            "recipeDropRate": recipe_drop_rate,
        }

    if missing_spell_data:
        log.warning(
            "%d of %d recipe(s) have no reagent/createsItemId data (empty in this dump)",
            missing_spell_data, len(recipes),
        )
    log.info("Built %d Recipes entries", len(recipes))
    return recipes
