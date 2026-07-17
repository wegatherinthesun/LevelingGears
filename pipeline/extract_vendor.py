"""pipeline/extract_vendor.py -- builds Sources[itemId] kind="vendor" entries per ROADMAP.md's
schema:

    { kind="vendor", npcId=, cost=, obtainLevel= }

`npc_vendor` itself has no price column -- an item's gold cost is just its own `item_template.
BuyPrice` (vendors don't set custom prices; only faction reputation discounts it, client-side).
`ExtendedCost` (non-zero) means the item is bought with a special currency/token instead of or in
addition to gold -- flagged rather than priced, since that needs its own display logic later.

`obtainLevel` uses the vendor NPC's own `MinLevel` (creature_template), the same judgment call as
extract_loot.py's -- a rough "when can you reasonably reach this vendor," not a hard rule.
"""

import logging
from pathlib import Path
from typing import Dict

import sql_extract

log = logging.getLogger("big_data.extract_vendor")


def _build_creature_levels(sql_path: Path, tables: Dict[str, list]) -> Dict[int, int]:
    levels = {}
    for row in sql_extract.extract_rows(sql_path, "creature_template", tables["creature_template"]):
        levels[row["Entry"]] = row["MinLevel"]
    return levels


def _build_buy_prices(sql_path: Path, tables: Dict[str, list]) -> Dict[int, int]:
    prices = {}
    for row in sql_extract.extract_rows(sql_path, "item_template", tables["item_template"]):
        prices[row["entry"]] = row["BuyPrice"]
    return prices


def build_vendor_sources(sql_path: Path, tables: Dict[str, list]) -> Dict[int, list]:
    """Returns {itemId: [{"kind": "vendor", "npcId":, "cost":, "obtainLevel":}, ...]}."""
    creature_levels = _build_creature_levels(sql_path, tables)
    buy_prices = _build_buy_prices(sql_path, tables)

    sources: Dict[int, list] = {}
    row_count = 0
    extended_cost_count = 0

    for row in sql_extract.extract_rows(sql_path, "npc_vendor", tables["npc_vendor"]):
        row_count += 1
        item_id = row["item"]
        entry = {
            "kind": "vendor",
            "npcId": row["entry"],
            "cost": buy_prices.get(item_id),
            "obtainLevel": creature_levels.get(row["entry"]),
        }
        if row["ExtendedCost"]:
            entry["extendedCost"] = True
            extended_cost_count += 1
        sources.setdefault(item_id, []).append(entry)

    if extended_cost_count:
        log.info(
            "%d vendor listing(s) use ExtendedCost (a token/currency, not plain gold) -- flagged "
            "with extendedCost=true, cost left as the item's plain gold BuyPrice regardless",
            extended_cost_count,
        )
    log.info("npc_vendor: %d rows, %d distinct items have at least one vendor source", row_count, len(sources))
    return sources
