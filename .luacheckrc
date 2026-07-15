std = "lua51"
max_line_length = false
globals = {
	"LevelingGearsDB",
	"LevelingGearsFrame",
	"SLASH_LEVELINGGEARS1", "SLASH_LEVELINGGEARS2",
	"SlashCmdList",
}
read_globals = {
	"CreateFrame", "UIParent", "BackdropTemplateMixin",
	"DEFAULT_CHAT_FRAME", "UnitName", "GetRealmName", "date",
	"GetInventoryItemLink", "GetItemStats", "GetInventorySlotInfo",
	"tContains", "tinsert", "UISpecialFrames",
	"Minimap", "GameTooltip", "CharacterFrame", "C_Timer",
	-- v0.25 scoring engine (Conversions.lua/Priorities.lua/Scoring.lua):
	"UnitClass", "UnitStat", "GetCritChanceFromAgility", "GetSpellCritChanceFromIntellect",
	"ARMOR_PER_AGILITY", "MANA_PER_INTELLECT",
	"GetCombatRating", "GetCombatRatingBonus",
	"GetNumTalents", "GetTalentInfo",
	"CR_DEFENSE_SKILL", "CR_DODGE", "CR_PARRY", "CR_BLOCK",
	"CR_HIT_MELEE", "CR_HIT_RANGED", "CR_HIT_SPELL",
	"CR_CRIT_MELEE", "CR_CRIT_RANGED", "CR_CRIT_SPELL",
	"CR_HASTE_MELEE", "CR_HASTE_RANGED", "CR_HASTE_SPELL",
	"CR_EXPERTISE", "CR_RESILIENCE", "CR_ARMOR_PENETRATION",
	"IsShiftKeyDown",
}
