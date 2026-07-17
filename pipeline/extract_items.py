"""pipeline/extract_items.py -- builds Items[itemId] entries per ROADMAP.md's schema:

    Items[itemId] = { name, slot, subtype, armorType, reqLevel, classMask }

Only equippable gear (InventoryType maps to one of this addon's tracked slots -- see
wow_enums.INVENTORY_TYPE_TO_SLOT) gets an entry: reagents, quest items, containers, etc. are
referenced by id elsewhere (e.g. a recipe's reagents) without needing a full gear-shaped Items row.

Gear STATS are deliberately NOT stored here, matching ROADMAP.md's own note: the client already
knows every item's stats (read live via GetItemStats at runtime), so baking them here would
duplicate and risk desyncing from the client's own data.
"""

import logging
from pathlib import Path
from typing import Dict

import sql_extract
import wow_enums

log = logging.getLogger("big_data.extract_items")


def build_items(sql_path: Path, tables: Dict[str, list]) -> Dict[int, dict]:
    items = {}
    scanned = 0
    skipped_untracked_slot = 0

    for row in sql_extract.extract_rows(sql_path, "item_template", tables["item_template"]):
        scanned += 1
        slot = wow_enums.resolve_slot(row["InventoryType"])
        if slot is None:
            skipped_untracked_slot += 1
            continue

        item_class, subclass = row["class"], row["subclass"]
        items[row["entry"]] = {
            "name": row["name"],
            "slot": slot,
            "subtype": wow_enums.resolve_weapon_type(item_class, subclass),
            "armorType": wow_enums.resolve_armor_type(item_class, subclass),
            "reqLevel": row["RequiredLevel"],
            "classMask": row["AllowableClass"],
        }

    log.info(
        "item_template: %d rows scanned, %d equippable items kept, %d skipped (untracked slot: "
        "shirt/tabard/bag/ammo/quiver/misc)",
        scanned, len(items), skipped_untracked_slot,
    )
    return items
