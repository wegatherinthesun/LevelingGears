std = "lua51"
max_line_length = false
globals = {
	"LevelingGearsDB",
	"LevelingGearsFrame",
	"SLASH_LEVELINGGEARS1", "SLASH_LEVELINGGEARS2",
	"SlashCmdList",
	"StaticPopupDialogs",
}
read_globals = {
	"CreateFrame", "UIParent", "BackdropTemplateMixin", "GetAddOnMetadata", "C_AddOns",
	"DEFAULT_CHAT_FRAME", "UnitName", "GetRealmName", "date", "ChatFontNormal",
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
	-- v0.383 native "Spec:" dropdown (UI.lua):
	"UIDropDownMenu_SetWidth", "UIDropDownMenu_SetText", "UIDropDownMenu_Initialize",
	"UIDropDownMenu_CreateInfo", "UIDropDownMenu_AddButton", "CloseDropDownMenus",
	-- T10 (minimap button drag-to-reposition):
	"GetCursorPosition",
	-- v0.385 (T23/T24, bug #49): weight-validation rejection popup:
	"OKAY", "StaticPopup_Show",
	-- Suggestions.lua (the upgrade-recommendation engine):
	"UnitPosition", "GetItemInfo", "UnitLevel", "GetInventoryItemID",
	-- Pipeline output (pipeline/big_data.py --build-database), wired into LevelingGears.toc:
	"LevelingGearsData_Items", "LevelingGearsData_Sources", "LevelingGearsData_Quests",
	"LevelingGearsData_Chains", "LevelingGearsData_Recipes", "LevelingGearsData_BySlot",
	-- SuggestionsUI.lua (the recommendation window):
	"ITEM_QUALITY_COLORS", "GetItemIcon", "ChatEdit_GetActiveWindow", "ChatEdit_InsertLink",
}
