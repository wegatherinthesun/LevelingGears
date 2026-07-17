"""pipeline/wow_enums.py -- stable WoW client constants used to translate item_template/quest_template
numeric codes into our schema's terms.

None of this comes from the cmangos SQL dump itself -- these are Blizzard's own client-side enums
(InventoryType, ItemClass/ItemSubclass, race bitmask), published and unchanged since TBC. Same
caveat as PROFESSION_SKILL_IDS in extract_recipes.py: worth double-checking against a second source
before trusting blindly, but these are well-documented, stable values, not guesses.
"""

# InventoryType -> this addon's own slot name (matching GearEvaluation.lua's equippedSlotDefinitions
# exactly, so BySlot[slot] keys line up with what the addon already outlines in-game). Slots the
# addon deliberately doesn't track (Shirt, Tabard, Bag, Ammo, the deprecated Quiver) map to None.
#
# One-handed weapons (13) and off-hand-only items (14 Shield, 22 Held-in-off-hand, 23 Holdable) are
# a real simplification here: a one-hander (13/21) is filed under MainHandSlot even though many
# classes could equally offhand it -- correctly modeling that needs per-class dual-wield knowledge
# this pass doesn't have. Flagged rather than silently guessed away; revisit once BySlot is actually
# driving in-game suggestions.
INVENTORY_TYPE_TO_SLOT = {
    1: "HeadSlot",
    2: "NeckSlot",
    3: "ShoulderSlot",
    4: None,  # Shirt -- not tracked
    5: "ChestSlot",
    6: "WaistSlot",
    7: "LegsSlot",
    8: "FeetSlot",
    9: "WristSlot",
    10: "HandsSlot",
    11: "FingerSlot",  # generic -- serves both Finger0Slot and Finger1Slot
    12: "TrinketSlot",  # generic -- serves both Trinket0Slot and Trinket1Slot
    13: "MainHandSlot",  # one-handed weapon -- simplification, see module docstring
    14: "SecondaryHandSlot",  # shield
    15: "RangedSlot",  # bow
    16: "BackSlot",
    17: "MainHandSlot",  # two-handed weapon
    18: None,  # Bag -- not tracked
    19: None,  # Tabard -- not tracked
    20: "ChestSlot",  # robe
    21: "MainHandSlot",  # main-hand-only weapon
    22: "SecondaryHandSlot",  # off-hand-only weapon
    23: "SecondaryHandSlot",  # held in off-hand (non-weapon, e.g. off-hand frills)
    24: None,  # Ammo -- not tracked
    25: "RangedSlot",  # thrown
    26: "RangedSlot",  # ranged right (gun/crossbow, depending on client build)
    27: None,  # Quiver -- deprecated, no real items use it
    28: "RangedSlot",  # relic (Libram/Idol/Totem/Sigil) -- matches GearEvaluation.lua's own comment
}

# item_template.class -- WoW's ItemClass enum. Only the handful this addon cares about.
ITEM_CLASS_ARMOR = 4
ITEM_CLASS_WEAPON = 2
ITEM_CLASS_RECIPE = 9  # already used by extract_recipes.py

# item_template.subclass when class == ITEM_CLASS_ARMOR -- WoW's ItemSubclassArmor enum.
ARMOR_SUBCLASS_TO_TYPE = {
    0: "Miscellaneous",
    1: "Cloth",
    2: "Leather",
    3: "Mail",
    4: "Plate",
    6: "Shield",
    7: "Libram",
    8: "Idol",
    9: "Totem",
    10: "Sigil",
}

# item_template.subclass when class == ITEM_CLASS_WEAPON -- WoW's ItemSubclassWeapon enum.
WEAPON_SUBCLASS_TO_TYPE = {
    0: "Axe1H",
    1: "Axe2H",
    2: "Bow",
    3: "Gun",
    4: "Mace1H",
    5: "Mace2H",
    6: "Polearm",
    7: "Sword1H",
    8: "Sword2H",
    10: "Staff",
    13: "FistWeapon",
    15: "Dagger",
    16: "Thrown",
    18: "Crossbow",
    19: "Wand",
    20: "FishingPole",
}

# quest_template.RequiredRaces -- WoW's race bitmask. 0 means no race restriction (both factions).
ALLIANCE_RACE_MASK = 1 | 4 | 8 | 64 | 512  # Human | Dwarf | NightElf | Gnome | Draenei
HORDE_RACE_MASK = 2 | 16 | 32 | 128 | 256  # Orc | Undead | Tauren | Troll | BloodElf


def resolve_faction(required_races: int) -> str:
    if not required_races:
        return "both"
    is_alliance = bool(required_races & ALLIANCE_RACE_MASK)
    is_horde = bool(required_races & HORDE_RACE_MASK)
    if is_alliance and is_horde:
        return "both"
    if is_alliance:
        return "alliance"
    if is_horde:
        return "horde"
    return "both"  # neither mask matched (e.g. a race added after TBC) -- don't over-filter


def resolve_slot(inventory_type: int):
    return INVENTORY_TYPE_TO_SLOT.get(inventory_type)


def resolve_armor_type(item_class: int, subclass: int):
    if item_class != ITEM_CLASS_ARMOR:
        return None
    return ARMOR_SUBCLASS_TO_TYPE.get(subclass, f"Unknown({subclass})")


def resolve_weapon_type(item_class: int, subclass: int):
    if item_class != ITEM_CLASS_WEAPON:
        return None
    return WEAPON_SUBCLASS_TO_TYPE.get(subclass, f"Unknown({subclass})")
