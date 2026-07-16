"""pipeline/extract_quests.py -- builds Quests/Chains, and quest-reward Sources entries, per
ROADMAP.md's schema:

    Quests[questId] = { pickup={zone,x,y,npc}, turnin={...}, chainId, requiredLevel, faction }
    Chains[chainId] = { steps = { {questId}, {questId}, ... } }
    Sources[itemId] += { kind="quest", questId=, chainId=, choiceGroup=, obtainLevel= }

DATA_PIPELINE.md originally assumed quest pickup/turn-in coordinates could only come from Questie
(still license-blocked). That turned out not to be true: cmangos's own `creature`/`gameobject`
tables carry real spawn coordinates, and `creature_questrelation`/`creature_involvedrelation`
(+ the `gameobject_*` equivalents) already say which NPC/object starts and finishes each quest --
no Questie dependency needed for basic pickup/turn-in locations at all.

Two real gaps, not guessed around:
- `map` here is the numeric continent/instance id (e.g. 0 = Eastern Kingdoms), NOT a human-readable
  zone name like "Elwynn Forest" -- that's Blizzard's client-side Area/Zone data, not present in
  this server-side SQL dump either (same category of gap as spell_template's missing reagent data).
  `zone` is left as this numeric map id until a real zone-name source is found.
- A creature/gameobject template id can have many spawns (guids) across the world; this takes the
  FIRST spawn found for pickup/turn-in purposes, not every possible location.
"""

import logging
from pathlib import Path
from typing import Dict, Optional, Tuple

import sql_extract
import wow_enums

log = logging.getLogger("big_data.extract_quests")

REWARD_ITEM_COLUMNS = [f"RewItemId{i}" for i in range(1, 5)]
REWARD_ITEM_COUNT_COLUMNS = [f"RewItemCount{i}" for i in range(1, 5)]
CHOICE_ITEM_COLUMNS = [f"RewChoiceItemId{i}" for i in range(1, 7)]
CHOICE_ITEM_COUNT_COLUMNS = [f"RewChoiceItemCount{i}" for i in range(1, 7)]


def _build_spawn_locations(sql_path: Path, tables: Dict[str, list], table_name: str) -> Dict[int, Tuple]:
    """Returns {templateId: (map, x, y)} using the FIRST spawn found per template id."""
    locations = {}
    for row in sql_extract.extract_rows(sql_path, table_name, tables[table_name]):
        template_id = row["id"]
        if template_id not in locations:
            locations[template_id] = (row["map"], row["position_x"], row["position_y"])
    return locations


def _build_quest_givers(sql_path: Path, tables: Dict[str, list], relation_table: str) -> Dict[int, Tuple[str, int]]:
    """Returns {questId: (kind, templateId)} where kind is "creature" or "gameobject", from
    `creature_questrelation`/`gameobject_questrelation` (pickup) or the `*_involvedrelation`
    equivalents (turn-in). First giver found per quest wins if more than one exists."""
    givers = {}
    for row in sql_extract.extract_rows(sql_path, relation_table, tables[relation_table]):
        quest_id = row["quest"]
        if quest_id not in givers:
            kind = "gameobject" if relation_table.startswith("gameobject") else "creature"
            givers[quest_id] = (kind, row["id"])
    return givers


def _resolve_location(giver: Optional[Tuple[str, int]], creature_locations: dict, gameobject_locations: dict):
    if not giver:
        return None
    kind, template_id = giver
    locations = gameobject_locations if kind == "gameobject" else creature_locations
    location = locations.get(template_id)
    if not location:
        return {"npc": template_id}
    map_id, x, y = location
    return {"zone": map_id, "x": x, "y": y, "npc": template_id}


def _build_chains(quest_next_in_chain: Dict[int, int]) -> Tuple[Dict[int, dict], Dict[int, int]]:
    """Returns (Chains[chainId], {questId: chainId}) built by walking NextQuestInChain forward from
    every quest that's never itself a "next" target (a chain root)."""
    next_targets = set(quest_next_in_chain.values())
    roots = [quest_id for quest_id in quest_next_in_chain if quest_id not in next_targets]

    chains = {}
    quest_to_chain = {}
    for root in roots:
        steps = [root]
        current = root
        seen = {root}
        while current in quest_next_in_chain:
            next_quest = quest_next_in_chain[current]
            if next_quest in seen:
                log.warning("Chain rooted at %d has a cycle at %d -- stopping this chain here", root, next_quest)
                break
            steps.append(next_quest)
            seen.add(next_quest)
            current = next_quest

        chain_id = root
        chains[chain_id] = {"steps": [[step] for step in steps]}
        for step in steps:
            quest_to_chain[step] = chain_id

    log.info("Built %d chains from %d NextQuestInChain links", len(chains), len(quest_next_in_chain))
    return chains, quest_to_chain


def build_quests(sql_path: Path, tables: Dict[str, list]):
    """Returns (Quests[questId], Chains[chainId], {itemId: [quest-reward Source entries]})."""
    creature_locations = _build_spawn_locations(sql_path, tables, "creature")
    gameobject_locations = _build_spawn_locations(sql_path, tables, "gameobject")
    pickup_givers = _build_quest_givers(sql_path, tables, "creature_questrelation")
    pickup_givers.update(_build_quest_givers(sql_path, tables, "gameobject_questrelation"))
    turnin_givers = _build_quest_givers(sql_path, tables, "creature_involvedrelation")
    turnin_givers.update(_build_quest_givers(sql_path, tables, "gameobject_involvedrelation"))

    quests = {}
    quest_next_in_chain = {}
    quest_sources: Dict[int, list] = {}
    scanned = 0

    for row in sql_extract.extract_rows(sql_path, "quest_template", tables["quest_template"]):
        scanned += 1
        quest_id = row["entry"]
        required_level = row["QuestLevel"] if row["QuestLevel"] and row["QuestLevel"] > 0 else row["MinLevel"]

        quests[quest_id] = {
            "pickup": _resolve_location(pickup_givers.get(quest_id), creature_locations, gameobject_locations),
            "turnin": _resolve_location(turnin_givers.get(quest_id), creature_locations, gameobject_locations),
            "chainId": None,  # filled in once _build_chains has run, below
            "requiredLevel": required_level,
            "faction": wow_enums.resolve_faction(row["RequiredRaces"]),
        }

        if row["NextQuestInChain"]:
            quest_next_in_chain[quest_id] = row["NextQuestInChain"]

        for reward_col, count_col in zip(REWARD_ITEM_COLUMNS, REWARD_ITEM_COUNT_COLUMNS):
            item_id = row[reward_col]
            if item_id:
                quest_sources.setdefault(item_id, []).append({
                    "kind": "quest", "questId": quest_id, "choiceGroup": None, "obtainLevel": required_level,
                })
        for index, (choice_col, choice_count_col) in enumerate(zip(CHOICE_ITEM_COLUMNS, CHOICE_ITEM_COUNT_COLUMNS)):
            item_id = row[choice_col]
            if item_id:
                quest_sources.setdefault(item_id, []).append({
                    "kind": "quest", "questId": quest_id, "choiceGroup": index + 1, "obtainLevel": required_level,
                })

    chains, quest_to_chain = _build_chains(quest_next_in_chain)
    for quest_id, chain_id in quest_to_chain.items():
        if quest_id in quests:
            quests[quest_id]["chainId"] = chain_id
    for entries in quest_sources.values():
        for entry in entries:
            entry["chainId"] = quest_to_chain.get(entry["questId"])

    log.info(
        "quest_template: %d rows, %d quests built, %d distinct items have a quest-reward source",
        scanned, len(quests), len(quest_sources),
    )
    return quests, chains, quest_sources
