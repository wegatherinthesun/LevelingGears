-- Leveling Gears -- 0.2 stat-weight list
-- This addon keeps a single settings window for the user and stores its state in SavedVariables.
-- The file is intentionally annotated so future edits stay easy to follow and so WoW-specific
-- UI and SavedVariable behavior is documented close to the code that uses it.

local ADDON_VERSION = "0.248"
LevelingGearsDB = LevelingGearsDB or {}
LevelingGearsDB.general = LevelingGearsDB.general or {}
LevelingGearsDB.characters = LevelingGearsDB.characters or {}
LevelingGearsDB.debugLog = LevelingGearsDB.debugLog or {}

local DEBUG_LOG_MAX_ENTRIES = 50

local minimapButton = nil
local profileDropdownButton = nil
local profileDropdownMenuFrame = nil
local profileRows = {}
local generalSettingsCheckbox = nil

-- Forward declarations: these are assigned further down the file but are called by functions
-- defined earlier, so per the dependency-graph rule they are declared here explicitly rather
-- than left as accidental globals.
local UpdateEquippedGearEvaluation
local RefreshProfileList
local RefreshWeightLabels
local SetActiveProfile
local CreateProfile

-- Send a message to the player's own chat frame using the addon's standard chat prefix.
local function PrintChat(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cff71d5ffLeveling Gears|r " .. message, 1, 1, 1)
end

-- Global addon settings live in the shared SavedVariable table and are not tied to a single character.
local function GetGeneralSettings()
	LevelingGearsDB.general = LevelingGearsDB.general or {}
	return LevelingGearsDB.general
end

-- Debug logging keeps a small ring buffer in SavedVariables and mirrors entries to chat when
-- enabled. WoW's addon sandbox has no io/file/os access, so this replaces file-based logging.
local function IsDebugEnabled()
	return GetGeneralSettings().debugEnabled == true
end

local function GetDebugLevel()
	return GetGeneralSettings().debugLevel or 1
end

local function WriteDebugLog(message, level)
	if level and GetDebugLevel() < level then
		return
	end

	local log = LevelingGearsDB.debugLog
	table.insert(log, { time = date("%H:%M:%S"), message = tostring(message) })
	while #log > DEBUG_LOG_MAX_ENTRIES do
		table.remove(log, 1)
	end

	if IsDebugEnabled() then
		PrintChat("|cffff8080Debug|r " .. tostring(message))
	end
end

local function SetDebugEnabled(enabled, level)
	local settings = GetGeneralSettings()
	settings.debugEnabled = enabled and true or false
	settings.debugLevel = level or settings.debugLevel or 1
	if enabled then
		PrintChat("Debug logging enabled (level " .. settings.debugLevel .. "). Use /lgs debug dump to view recent entries.")
	else
		PrintChat("Debug logging disabled.")
	end
end

local function ToggleDebugMode(level)
	SetDebugEnabled(not IsDebugEnabled(), level)
end

-- Print the stored debug entries to chat, since the addon has no file to read them back from.
local function DumpDebugLog()
	local log = LevelingGearsDB.debugLog
	if #log == 0 then
		PrintChat("Debug log is empty.")
		return
	end
	for _, entry in ipairs(log) do
		PrintChat("[" .. entry.time .. "] " .. entry.message)
	end
end

local function SafeCall(func, ...)
	local success, err = pcall(func, ...)
	if not success then
		WriteDebugLog(err, 1)
		PrintChat("A Lua error occurred. Use /lgs debug dump to view recent debug entries.")
	end
	return success, err
end

-- Character-scoped data is keyed by character name plus realm so each alt keeps its own profile state.
local function GetCharacterKey()
	local name = UnitName("player") or "Unknown"
	local realm = GetRealmName() or "Unknown"
	return name .. " - " .. realm
end

local function GetCharacterState()
	local key = GetCharacterKey()
	LevelingGearsDB.characters[key] = LevelingGearsDB.characters[key] or {
		activeProfile = nil,
		profiles = {},
	}
	return LevelingGearsDB.characters[key]
end

local function GetActiveProfile()
	local characterState = GetCharacterState()
	local profiles = characterState.profiles or {}
	if characterState.activeProfile and profiles[characterState.activeProfile] then
		return profiles[characterState.activeProfile]
	end

	if not next(profiles) then
		local defaultProfile = {
			id = "default",
			name = "Default",
			spec = nil,
			weights = {},
		}
		profiles[defaultProfile.id] = defaultProfile
		characterState.profiles = profiles
		characterState.activeProfile = defaultProfile.id
		return defaultProfile
	end

	for _, profile in pairs(profiles) do
		characterState.activeProfile = profile.id
		return profile
	end

	return nil
end

local function SetMinimapButtonVisible(visible)
	local settings = GetGeneralSettings()
	settings.minimapEnabled = visible
	if minimapButton then
		minimapButton:SetShown(visible)
	end
end

local function RefreshGeneralSettingsUI()
	if generalSettingsCheckbox then
		local settings = GetGeneralSettings()
		generalSettingsCheckbox:SetChecked(settings.minimapEnabled ~= false)
	end
end

-- Apply any previously saved frame position so the window appears where the user left it.
local function ApplySavedPosition(frame)
	local settings = GetGeneralSettings()
	local pos = settings.position
	if pos and pos.point and pos.relativePoint then
		frame:ClearAllPoints()
		frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x or 0, pos.y or 0)
	end
end

-- Open or close the single settings window that the addon uses for all configuration.
local function ToggleLevelingGears()
	local frame = _G["LevelingGearsFrame"]
	if not frame then
		return
	end

	if frame:IsShown() then
		frame:Hide()
	else
		SafeCall(function()
			frame:Show()
			frame:SetFrameStrata("DIALOG")
			frame:SetFrameLevel(100)
			frame:SetToplevel(true)
			ApplySavedPosition(frame)
		end)
	end
end

-- Slash commands are intentionally limited to the two primary entry points so the addon stays easy to explain.
local function HandleSlashCommand(msg)
	msg = (msg or ""):lower()
	if msg == "debug dump" then
		DumpDebugLog()
		return
	end
	local level = tonumber(msg:match("debug (%d+)"))
	if msg == "debug" or level then
		ToggleDebugMode(level or 1)
	else
		ToggleLevelingGears()
	end
end

-- Persist the frame position so the window opens in the same place after reloads.
local function SaveWindowPosition(frame)
	local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
	if relativeTo ~= UIParent then
		relativePoint = point or "CENTER"
		xOfs, yOfs = 0, 0
	end

	local settings = GetGeneralSettings()
	settings.position = {
		point = point or "CENTER",
		relativePoint = relativePoint or "CENTER",
		x = xOfs or 0,
		y = yOfs or 0,
	}
end

local LevelingGears = CreateFrame("Frame", "LevelingGearsFrame", UIParent,
	BackdropTemplateMixin and "BackdropTemplate" or nil)
LevelingGears:SetSize(420, 330)
LevelingGears:SetPoint("CENTER")
LevelingGears:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
LevelingGears:EnableMouse(true)
LevelingGears:SetMovable(true)
LevelingGears:RegisterForDrag("LeftButton")
LevelingGears:SetClampedToScreen(true)
LevelingGears:EnableKeyboard(true)
LevelingGears:SetFrameStrata("DIALOG")
LevelingGears:SetFrameLevel(100)
LevelingGears:SetToplevel(true)
LevelingGears:SetScript("OnDragStart", function(self)
	SafeCall(function()
		self:StartMoving()
	end)
end)
LevelingGears:SetScript("OnDragStop", function(self)
	SafeCall(function()
		self:StopMovingOrSizing()
		SaveWindowPosition(self)
	end)
end)
LevelingGears:SetScript("OnShow", function(self)
	SafeCall(function()
		ApplySavedPosition(self)
		self:SetFrameStrata("DIALOG")
		self:SetFrameLevel(100)
		self:SetToplevel(true)
		-- Re-sync every displayed control from LevelingGearsDB on every open, not just once at
		-- file load: this guarantees what's on screen always matches what's actually saved,
		-- regardless of how long ago the addon originally loaded.
		RefreshGeneralSettingsUI()
		RefreshProfileList()
		RefreshWeightLabels()
	end)
end)
LevelingGears:SetScript("OnHide", function(self)
	SafeCall(function()
		SaveWindowPosition(self)
	end)
end)
LevelingGears:SetScript("OnEvent", function(self, event, addonName)
	SafeCall(function()
		if event == "ADDON_LOADED" and addonName == "LevelingGears" then
			ApplySavedPosition(self)
		end
	end)
end)
LevelingGears:RegisterEvent("ADDON_LOADED")
LevelingGears:Hide()

if not tContains(UISpecialFrames, "LevelingGearsFrame") then
	tinsert(UISpecialFrames, "LevelingGearsFrame")
end

local title = LevelingGears:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", 0, -16)
title:SetText("Leveling Gears")

local version = LevelingGears:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
version:SetPoint("TOP", title, "BOTTOM", 0, -2)
version:SetText("v" .. ADDON_VERSION)

local closeButton = CreateFrame("Button", nil, LevelingGears, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -4, -4)

local scrollFrame = CreateFrame("ScrollFrame", nil, LevelingGears, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 20, -54)
scrollFrame:SetPoint("BOTTOMRIGHT", -28, 44)
scrollFrame:EnableMouseWheel(true)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(340, 420)
scrollFrame:SetScrollChild(scrollChild)

-- Static footer, anchored to the window itself (not the scroll child) so it stays visible and in a
-- fixed place no matter how far the settings content above is scrolled.
local footerDivider = LevelingGears:CreateTexture(nil, "OVERLAY")
footerDivider:SetColorTexture(0.6, 0.6, 0.6, 0.4)
footerDivider:SetPoint("BOTTOMLEFT", LevelingGears, "BOTTOMLEFT", 20, 38)
footerDivider:SetPoint("BOTTOMRIGHT", LevelingGears, "BOTTOMRIGHT", -20, 38)
footerDivider:SetHeight(1)

-- WoW addons have no manual "save" step: every setting above already writes straight into
-- LevelingGearsDB the instant it changes (SetWeight, SetMinimapButtonVisible, SaveWindowPosition,
-- etc. all do this directly), and the client itself flushes SavedVariables to disk at its own save
-- points (/reload, logout, exit). Forcing a ReloadUI() here would not save anything that wasn't
-- already saved -- it would just close and reopen the whole UI, which is why that was the wrong
-- design: nothing is meant to visibly change when this is clicked, because nothing needed to change.
-- This button only gives an honest, immediate confirmation of the state that already exists.
local saveSettingsButton = CreateFrame("Button", nil, LevelingGears, "UIPanelButtonTemplate")
saveSettingsButton:SetSize(150, 22)
saveSettingsButton:SetPoint("BOTTOM", LevelingGears, "BOTTOM", 0, 10)
saveSettingsButton:SetText("Save Settings")
saveSettingsButton:SetScript("OnClick", function()
	-- Re-sync every displayed number from LevelingGearsDB so what's on screen is visibly, provably
	-- the same as what's saved, rather than just taking a chat message on faith.
	RefreshGeneralSettingsUI()
	RefreshProfileList()
	RefreshWeightLabels()
	local profile = GetActiveProfile()
	local profileName = profile and profile.name or "Default"
	PrintChat("Saved. Profile '" .. profileName .. "' for this character is stored and will still be here after /reload or a full relog.")
end)

local statDefinitions = {
	{ key = "STR", name = "Strength" },
	{ key = "AGI", name = "Agility" },
	{ key = "STA", name = "Stamina" },
	{ key = "INT", name = "Intellect" },
	{ key = "SPI", name = "Spirit" },
	{ key = "SP", name = "Spell Power" },
	{ key = "HEAL", name = "Healing" },
	{ key = "AP", name = "Attack Power" },
	{ key = "RAP", name = "Ranged Attack Power" },
	{ key = "HIT", name = "Hit Rating" },
	{ key = "CRIT", name = "Crit Rating" },
	{ key = "HASTE", name = "Haste Rating" },
	{ key = "EXP", name = "Expertise Rating" },
	{ key = "ARMORPEN", name = "Armor Penetration" },
	{ key = "ARMOR", name = "Armor" },
	{ key = "DEF", name = "Defense Rating" },
	{ key = "DODGE", name = "Dodge Rating" },
	{ key = "PARRY", name = "Parry Rating" },
	{ key = "BLOCK", name = "Block Rating" },
	{ key = "BLOCKVALUE", name = "Block Value" },
	{ key = "RESILIENCE", name = "Resilience" },
	{ key = "MP5", name = "MP5" },
	{ key = "SPELLPEN", name = "Spell Penetration" },
	{ key = "ARCANERES", name = "Arcane Resistance" },
	{ key = "FIRERES", name = "Fire Resistance" },
	{ key = "FROSTRES", name = "Frost Resistance" },
	{ key = "NATURERES", name = "Nature Resistance" },
	{ key = "SHADOWRES", name = "Shadow Resistance" },
}

local statGroups = {
	{
		title = "Core stats",
		expanded = true,
		stats = {
			{ key = "STR", name = "Strength" },
			{ key = "AGI", name = "Agility" },
			{ key = "STA", name = "Stamina" },
			{ key = "INT", name = "Intellect" },
			{ key = "SPI", name = "Spirit" },
			{ key = "SP", name = "Spell Power" },
			{ key = "HEAL", name = "Healing" },
			{ key = "AP", name = "Attack Power" },
			{ key = "RAP", name = "Ranged Attack Power" },
		},
	},
	{
		title = "Other stats",
		expanded = false,
		stats = {
			{ key = "HIT", name = "Hit Rating" },
			{ key = "CRIT", name = "Crit Rating" },
			{ key = "HASTE", name = "Haste Rating" },
			{ key = "EXP", name = "Expertise Rating" },
			{ key = "ARMORPEN", name = "Armor Penetration" },
			{ key = "ARMOR", name = "Armor" },
			{ key = "DEF", name = "Defense Rating" },
			{ key = "DODGE", name = "Dodge Rating" },
			{ key = "PARRY", name = "Parry Rating" },
			{ key = "BLOCK", name = "Block Rating" },
			{ key = "BLOCKVALUE", name = "Block Value" },
			{ key = "RESILIENCE", name = "Resilience" },
			{ key = "MP5", name = "MP5" },
			{ key = "SPELLPEN", name = "Spell Penetration" },
		},
	},
	{
		title = "Resistances",
		expanded = false,
		stats = {
			{ key = "ARCANERES", name = "Arcane Resistance" },
			{ key = "FIRERES", name = "Fire Resistance" },
			{ key = "FROSTRES", name = "Frost Resistance" },
			{ key = "NATURERES", name = "Nature Resistance" },
			{ key = "SHADOWRES", name = "Shadow Resistance" },
		},
	},
}

local weightLabels = {}

-- Ensure every profile has a complete set of weight values before the UI is refreshed.
local function EnsureWeights()
	local profile = GetActiveProfile()
	profile.weights = profile.weights or {}
	for _, stat in ipairs(statDefinitions) do
		if profile.weights[stat.key] == nil then
			profile.weights[stat.key] = 5
		end
	end
end

local gearEvaluationPending = false

-- The gear evaluation walks every equipped slot and reads item stats, which is too expensive to run
-- synchronously on every single +/- click: doing so caused enough per-click delay that a burst of
-- quick clicks could queue up and fire together, making the weight jump by more than 1 at a time.
-- Debounce it instead: multiple calls within the delay collapse into a single evaluation.
local function ScheduleGearEvaluation()
	if gearEvaluationPending then
		return
	end
	gearEvaluationPending = true
	C_Timer.After(0.2, function()
		gearEvaluationPending = false
		SafeCall(UpdateEquippedGearEvaluation)
	end)
end

-- Update a single weight value and immediately refresh its visible label in the settings window.
local function SetWeight(statKey, delta)
	EnsureWeights()
	local profile = GetActiveProfile()
	local newValue = (profile.weights[statKey] or 5) + delta
	if newValue < 0 then
		newValue = 0
	elseif newValue > 10 then
		newValue = 10
	end
	profile.weights[statKey] = newValue
	if weightLabels[statKey] then
		weightLabels[statKey]:SetText(tostring(newValue))
	end
	ScheduleGearEvaluation()
end

-- Repaint every visible weight label from the currently active profile so the settings page stays in sync.
RefreshWeightLabels = function()
	EnsureWeights()
	local profile = GetActiveProfile()
	for _, stat in ipairs(statDefinitions) do
		if weightLabels[stat.key] then
			weightLabels[stat.key]:SetText(tostring(profile.weights[stat.key] or 5))
		end
	end
	SafeCall(UpdateEquippedGearEvaluation)
end

-- The profile picker is a compact dropdown-style menu that keeps the settings page simple.
local function ToggleProfileMenu()
	if not profileDropdownMenuFrame or not profileDropdownButton then
		return
	end
	profileDropdownMenuFrame:SetShown(not profileDropdownMenuFrame:IsShown())
end

-- A small set of Blizzard slot names lets us draw a thin outline around the equipped item buttons.
local equippedSlotDefinitions = {
	{ slotName = "HeadSlot", buttonName = "CharacterHeadSlot" },
	{ slotName = "NeckSlot", buttonName = "CharacterNeckSlot" },
	{ slotName = "ShoulderSlot", buttonName = "CharacterShoulderSlot" },
	{ slotName = "BackSlot", buttonName = "CharacterBackSlot" },
	{ slotName = "ChestSlot", buttonName = "CharacterChestSlot" },
	{ slotName = "WristSlot", buttonName = "CharacterWristSlot" },
	{ slotName = "HandsSlot", buttonName = "CharacterHandsSlot" },
	{ slotName = "WaistSlot", buttonName = "CharacterWaistSlot" },
	{ slotName = "LegsSlot", buttonName = "CharacterLegsSlot" },
	{ slotName = "FeetSlot", buttonName = "CharacterFeetSlot" },
	{ slotName = "Finger0Slot", buttonName = "CharacterFinger0Slot" },
	{ slotName = "Finger1Slot", buttonName = "CharacterFinger1Slot" },
	{ slotName = "Trinket0Slot", buttonName = "CharacterTrinket0Slot" },
	{ slotName = "Trinket1Slot", buttonName = "CharacterTrinket1Slot" },
	{ slotName = "MainHandSlot", buttonName = "CharacterMainHandSlot" },
	{ slotName = "SecondaryHandSlot", buttonName = "CharacterSecondaryHandSlot" },
	-- Covers ranged weapons AND class relics (Librams for Paladins, Idols for Druids, Totems for
	-- Shamans): TBC has no separate relic slot -- that was only added in Wrath -- so those classes'
	-- relics occupy this same slot, and it is already evaluated for every class through here.
	{ slotName = "RangedSlot", buttonName = "CharacterRangedSlot" },
}

local gearOutlineFrames = {}

-- Blizzard item stats are exposed through token-based keys, so we map our simpler weight names to those tokens.
local itemStatAliases = {
	STR = { "ITEM_MOD_STRENGTH_SHORT" },
	AGI = { "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_AGI_SHORT" },
	STA = { "ITEM_MOD_STAMINA_SHORT" },
	INT = { "ITEM_MOD_INTELLECT_SHORT" },
	SPI = { "ITEM_MOD_SPIRIT_SHORT" },
	SP = { "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT" },
	HEAL = { "ITEM_MOD_SPELL_HEALING_DONE_SHORT" },
	AP = { "ITEM_MOD_ATTACK_POWER_SHORT" },
	RAP = { "ITEM_MOD_RANGED_ATTACK_POWER_SHORT" },
	HIT = { "ITEM_MOD_HIT_RATING_SHORT" },
	CRIT = { "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_CRITICAL_STRIKE_RATING_SHORT" },
	HASTE = { "ITEM_MOD_HASTE_RATING_SHORT" },
	EXP = { "ITEM_MOD_EXPERTISE_RATING_SHORT" },
	ARMORPEN = { "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT" },
	-- NOTE: this only ever captures BONUS armor (e.g. a shield's "of the Bear"-style suffix, or a
	-- rare item with +Armor as an explicit modifier) -- a normal piece's base armor value is
	-- intrinsic to its material/item level/slot and is not exposed as an ITEM_MOD_* stat by
	-- GetItemStats at all. This token is unverified on this client (see Technical notes); if it
	-- never contributes to any item's score in testing, the fallback is a hidden-tooltip scan of
	-- the "Armor" line, per this project's existing stated policy for uncertain GetItemStats coverage.
	ARMOR = { "ITEM_MOD_ARMOR_SHORT" },
	DEF = { "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT" },
	DODGE = { "ITEM_MOD_DODGE_RATING_SHORT" },
	PARRY = { "ITEM_MOD_PARRY_RATING_SHORT" },
	BLOCK = { "ITEM_MOD_BLOCK_RATING_SHORT" },
	BLOCKVALUE = { "ITEM_MOD_BLOCK_VALUE_SHORT" },
	RESILIENCE = { "ITEM_MOD_RESILIENCE_RATING_SHORT" },
	MP5 = { "ITEM_MOD_MP5_SHORT" },
	SPELLPEN = { "ITEM_MOD_SPELL_PENETRATION_SHORT" },
	ARCANERES = { "ITEM_MOD_ARCANE_RESISTANCE_SHORT" },
	FIRERES = { "ITEM_MOD_FIRE_RESISTANCE_SHORT" },
	FROSTRES = { "ITEM_MOD_FROST_RESISTANCE_SHORT" },
	NATURERES = { "ITEM_MOD_NATURE_RESISTANCE_SHORT" },
	SHADOWRES = { "ITEM_MOD_SHADOW_RESISTANCE_SHORT" },
}

-- Resolve item stats through the Blizzard token names so the weighted evaluation can use real gear values.
local function ResolveItemStatValue(itemStats, statKey)
	local aliases = itemStatAliases[statKey] or {}
	for _, alias in ipairs(aliases) do
		if itemStats[alias] then
			return tonumber(itemStats[alias]) or 0
		end
	end
	return 0
end

-- Build a local score for each equipped item by applying the currently active profile weights to that item's stats.
local function GetEquippedItemScore(slotId)
	if not slotId then
		return nil
	end

	local itemLink = GetInventoryItemLink("player", slotId)
	if not itemLink then
		return nil
	end

	local itemStats = GetItemStats(itemLink)
	if not itemStats then
		return nil
	end

	EnsureWeights()
	local profile = GetActiveProfile()
	local weights = profile and profile.weights or {}
	local score = 0
	for statKey, weight in pairs(weights) do
		if weight and weight > 0 then
			score = score + (ResolveItemStatValue(itemStats, statKey) * weight)
		end
	end
	return score
end

-- Convert the gap between an item and the player's current average into a color from red to violet, with green at parity.
local function GetColorForRelativeScore(relativeScore)
	local anchors = {
		{ value = -1, color = { 1, 0, 0 } },
		{ value = -0.5, color = { 1, 0.5, 0 } },
		{ value = -0.25, color = { 1, 1, 0 } },
		{ value = 0, color = { 0, 1, 0 } },
		{ value = 0.25, color = { 0, 1, 1 } },
		{ value = 0.5, color = { 0, 0, 1 } },
		{ value = 1, color = { 0.5, 0, 1 } },
	}

	local clamped = math.max(-1, math.min(1, relativeScore or 0))
	for index = 1, #anchors - 1 do
		local current = anchors[index]
		local next = anchors[index + 1]
		if clamped <= next.value then
			local span = next.value - current.value
			local amount = span > 0 and (clamped - current.value) / span or 0
			return current.color[1] + (next.color[1] - current.color[1]) * amount,
				current.color[2] + (next.color[2] - current.color[2]) * amount,
				current.color[3] + (next.color[3] - current.color[3]) * amount
		end
	end

	return anchors[#anchors].color[1], anchors[#anchors].color[2], anchors[#anchors].color[3]
end

-- Create one thin border frame per item button so we can visually show how each piece compares to the gear average.
local function EnsureGearOutline(slotButton)
	if not slotButton then
		return nil
	end

	local key = slotButton:GetName() or "unknown"
	local outline = gearOutlineFrames[key]
	if outline then
		return outline
	end

	outline = CreateFrame("Frame", nil, slotButton)
	outline:SetAllPoints(slotButton)
	outline:SetFrameLevel(slotButton:GetFrameLevel() + 1)

	local top = outline:CreateTexture(nil, "OVERLAY")
	top:SetColorTexture(1, 1, 1, 1)
	top:SetPoint("TOPLEFT", outline, "TOPLEFT", -1, 1)
	top:SetPoint("TOPRIGHT", outline, "TOPRIGHT", 1, 1)
	top:SetHeight(1)

	local bottom = outline:CreateTexture(nil, "OVERLAY")
	bottom:SetColorTexture(1, 1, 1, 1)
	bottom:SetPoint("BOTTOMLEFT", outline, "BOTTOMLEFT", -1, -1)
	bottom:SetPoint("BOTTOMRIGHT", outline, "BOTTOMRIGHT", 1, -1)
	bottom:SetHeight(1)

	local left = outline:CreateTexture(nil, "OVERLAY")
	left:SetColorTexture(1, 1, 1, 1)
	left:SetPoint("TOPLEFT", outline, "TOPLEFT", -1, 1)
	left:SetPoint("BOTTOMLEFT", outline, "BOTTOMLEFT", -1, -1)
	left:SetWidth(1)

	local right = outline:CreateTexture(nil, "OVERLAY")
	right:SetColorTexture(1, 1, 1, 1)
	right:SetPoint("TOPRIGHT", outline, "TOPRIGHT", 1, 1)
	right:SetPoint("BOTTOMRIGHT", outline, "BOTTOMRIGHT", 1, -1)
	right:SetWidth(1)

	outline.top = top
	outline.bottom = bottom
	outline.left = left
	outline.right = right
	outline:Hide()
	gearOutlineFrames[key] = outline
	return outline
end

-- Recalculate the current gear evaluation, compare each item to the character's average, and repaint the outlines.
UpdateEquippedGearEvaluation = function()
	EnsureWeights()
	local itemScores = {}
	local scoreTotal = 0
	local scoreCount = 0
	local buttonsFound = 0

	for _, slotDefinition in ipairs(equippedSlotDefinitions) do
		if _G[slotDefinition.buttonName] then
			buttonsFound = buttonsFound + 1
		end
		-- Some slot names are only valid on certain expansions (see bug #16), so a single bad
		-- entry must not abort the evaluation for every other slot.
		local slotOk, slotId = pcall(GetInventorySlotInfo, slotDefinition.slotName)
		if slotOk and slotId then
			local score = GetEquippedItemScore(slotId)
			if score and score > 0 then
				itemScores[slotDefinition.buttonName] = score
				scoreTotal = scoreTotal + score
				scoreCount = scoreCount + 1
			end
		end
	end

	WriteDebugLog("Gear evaluation: " .. buttonsFound .. "/" .. #equippedSlotDefinitions ..
		" slot buttons found, " .. scoreCount .. " items scored.", 1)

	if scoreCount == 0 then
		for _, slotDefinition in ipairs(equippedSlotDefinitions) do
			local slotButton = _G[slotDefinition.buttonName]
			local outline = EnsureGearOutline(slotButton)
			if outline then
				outline:Hide()
			end
		end
		return
	end

	local averageScore = scoreTotal / scoreCount
	local maximumDelta = 0
	for _, slotDefinition in ipairs(equippedSlotDefinitions) do
		local score = itemScores[slotDefinition.buttonName]
		if score then
			local delta = math.abs(score - averageScore)
			if delta > maximumDelta then
				maximumDelta = delta
			end
		end
	end

	for _, slotDefinition in ipairs(equippedSlotDefinitions) do
		local slotButton = _G[slotDefinition.buttonName]
		local outline = EnsureGearOutline(slotButton)
		if outline then
			local itemScore = itemScores[slotDefinition.buttonName]
			if itemScore then
				local relativeScore = maximumDelta > 0 and ((itemScore - averageScore) / maximumDelta) or 0
				local red, green, blue = GetColorForRelativeScore(relativeScore)
				outline.top:SetColorTexture(red, green, blue, 1)
				outline.bottom:SetColorTexture(red, green, blue, 1)
				outline.left:SetColorTexture(red, green, blue, 1)
				outline.right:SetColorTexture(red, green, blue, 1)
				outline:Show()
			else
				outline:Hide()
			end
		end
	end
end

-- Keep the gear evaluation current when weights or gear change so the outlines remain meaningful.
local gearEvaluationFrame = CreateFrame("Frame", nil, UIParent)
gearEvaluationFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
gearEvaluationFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
gearEvaluationFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
gearEvaluationFrame:SetScript("OnEvent", function(_, event, unit)
	if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then
		return
	end
	SafeCall(UpdateEquippedGearEvaluation)
end)

-- The Character*Slot buttons this addon outlines belong to Blizzard's paperdoll UI, which this
-- client loads on demand rather than at login (confirmed by GearScoreTBCClassic, an installed
-- addon on this same client, which defers all paperdoll work to CharacterFrame's OnShow for the
-- same reason). Re-run the evaluation once the panel is actually open so the slot buttons exist.
CharacterFrame:HookScript("OnShow", function()
	SafeCall(UpdateEquippedGearEvaluation)
end)

-- Build and refresh the visible profile list so the current character's profiles are always represented in the UI.
RefreshProfileList = function()
	local characterState = GetCharacterState()
	local profiles = characterState.profiles or {}
	if not profileDropdownMenuFrame or not profileDropdownButton then
		return
	end

	for _, row in ipairs(profileRows) do
		row:Hide()
	end

	local index = 1
	local function AddMenuRow(label, profileId, isDefault)
		local row = profileRows[index]
		if not row then
			row = CreateFrame("Button", nil, profileDropdownMenuFrame, "UIPanelButtonTemplate")
			row:SetSize(160, 22)
			profileRows[index] = row
		end

		row:Show()
		row:SetText(label)
		row:SetPoint("TOPLEFT", profileDropdownMenuFrame, "TOPLEFT", 4, -(index - 1) * 24)
		row:SetScript("OnClick", function()
			if isDefault then
				CreateProfile("Default")
			elseif profileId == "create_new" then
				CreateProfile("Profile " .. tostring((next(profiles) and 1 or 0) + 1))
			else
				SetActiveProfile(profileId)
			end
			profileDropdownMenuFrame:Hide()
		end)
		row.profileId = profileId
		index = index + 1
	end

	AddMenuRow("Default", "default", true)
	for _, profile in pairs(profiles) do
		if profile.id ~= "default" then
			AddMenuRow(profile.name, profile.id, false)
		end
	end
	AddMenuRow("Create new profile", "create_new", false)

	profileDropdownButton:SetEnabled(true)
	if characterState.activeProfile and profiles[characterState.activeProfile] then
		profileDropdownButton:SetText(profiles[characterState.activeProfile].name)
	elseif profiles.default then
		profileDropdownButton:SetText("Default")
	else
		profileDropdownButton:SetText("Select profile")
	end
	profileDropdownMenuFrame:SetHeight(math.max(24, (index - 1) * 24))
end

-- Switch the active profile for the current character and update the visible weight controls immediately.
SetActiveProfile = function(profileId)
	local characterState = GetCharacterState()
	local profile = characterState.profiles and characterState.profiles[profileId]
	if not profile then
		return
	end

	characterState.activeProfile = profileId
	EnsureWeights()
	RefreshWeightLabels()
	RefreshProfileList()
	PrintChat("Switched to profile '" .. profile.name .. "'.")
end

-- Create a new profile entry and seed it with default weight values so the user can start editing immediately.
CreateProfile = function(name)
	local characterState = GetCharacterState()
	local profiles = characterState.profiles or {}
	local trimmedName = (name or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if trimmedName == "" then
		trimmedName = "New Profile"
	end

	local profileCount = 0
	for _ in pairs(profiles) do
		profileCount = profileCount + 1
	end

	local profileId = "profile" .. tostring(profileCount + 1)
	local profile = {
		id = profileId,
		name = trimmedName,
		spec = nil,
		weights = {},
	}
	profiles[profileId] = profile
	characterState.profiles = profiles
	characterState.activeProfile = profileId
	EnsureWeights()
	RefreshWeightLabels()
	RefreshProfileList()
	PrintChat("Created profile '" .. profile.name .. "'.")
end

-- Initialize the profile state on load so the settings page reflects the saved character data and current defaults.
local function InitializeProfileState()
	local activeProfile = GetActiveProfile()
	EnsureWeights()
	RefreshGeneralSettingsUI()
	RefreshProfileList()
	RefreshWeightLabels()
	if not LevelingGearsDB.general.bootMessageShown then
		PrintChat("Loaded.")
		PrintChat("Type /levelinggears or /lgs to open settings.")
		LevelingGearsDB.general.bootMessageShown = true
	end
	if activeProfile then
		PrintChat("Loaded profile '" .. activeProfile.name .. "'.")
	end
end

-- Build the settings page in one place so there is only one settings window and all controls remain discoverable.
local generalSection = CreateFrame("Frame", nil, scrollChild)
generalSection:SetSize(320, 110)
generalSection:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -12)

local generalHeader = generalSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
generalHeader:SetPoint("TOPLEFT", generalSection, "TOPLEFT", 8, -8)
generalHeader:SetText("General settings")

local generalHint = generalSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
generalHint:SetPoint("TOPLEFT", generalHeader, "BOTTOMLEFT", 0, -4)
generalHint:SetWidth(300)
generalHint:SetJustifyH("LEFT")
generalHint:SetText("These choices apply addon-wide. Window position and basic behavior are saved globally.")

generalSettingsCheckbox = CreateFrame("CheckButton", nil, generalSection, "UICheckButtonTemplate")
generalSettingsCheckbox:SetPoint("TOPLEFT", generalHint, "BOTTOMLEFT", -2, -8)
generalSettingsCheckbox:SetScript("OnClick", function(self)
	SetMinimapButtonVisible(self:GetChecked())
end)

local generalCheckboxText = generalSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
generalCheckboxText:SetPoint("LEFT", generalSettingsCheckbox, "RIGHT", 4, 1)
generalCheckboxText:SetText("Show minimap button")

local divider = generalSection:CreateTexture(nil, "OVERLAY")
divider:SetColorTexture(0.6, 0.6, 0.6, 0.4)
divider:SetSize(300, 1)
divider:SetPoint("TOPLEFT", generalSettingsCheckbox, "BOTTOMLEFT", 0, -12)

generalSection:SetHeight(92)

local profileSection = CreateFrame("Frame", nil, scrollChild)
profileSection:SetSize(320, 140)
profileSection:SetPoint("TOPLEFT", generalSection, "BOTTOMLEFT", 0, -20)

local profileHeader = profileSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
profileHeader:SetPoint("TOPLEFT", profileSection, "TOPLEFT", 8, -8)
profileHeader:SetText("Profiles")

local profileHint = profileSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
profileHint:SetPoint("TOPLEFT", profileHeader, "BOTTOMLEFT", 0, -4)
profileHint:SetWidth(300)
profileHint:SetJustifyH("LEFT")
profileHint:SetText("Create and switch profiles per character. These can later be tied to specs or roles.")

profileDropdownButton = CreateFrame("Button", nil, profileSection, "UIPanelButtonTemplate")
profileDropdownButton:SetSize(180, 24)
profileDropdownButton:SetPoint("TOPLEFT", profileHint, "BOTTOMLEFT", 0, -8)
profileDropdownButton:SetText("Select profile")
profileDropdownButton:SetScript("OnClick", ToggleProfileMenu)

profileDropdownMenuFrame = CreateFrame("Frame", nil, profileSection)
profileDropdownMenuFrame:SetSize(180, 100)
profileDropdownMenuFrame:SetPoint("TOPLEFT", profileDropdownButton, "BOTTOMLEFT", 0, -2)
profileDropdownMenuFrame:Hide()

local profileDivider = profileSection:CreateTexture(nil, "OVERLAY")
profileDivider:SetColorTexture(0.6, 0.6, 0.6, 0.4)
profileDivider:SetSize(300, 1)
profileDivider:SetPoint("TOPLEFT", profileDropdownMenuFrame, "BOTTOMLEFT", 0, -12)

local weightSection = CreateFrame("Frame", nil, scrollChild)
weightSection:SetSize(320, 220)
weightSection:SetPoint("TOPLEFT", profileSection, "BOTTOMLEFT", 0, -20)

local weightHeader = weightSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
weightHeader:SetPoint("TOPLEFT", weightSection, "TOPLEFT", 8, -8)
weightHeader:SetText("Stat weights")

local helperText = weightSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
helperText:SetPoint("TOPLEFT", weightHeader, "BOTTOMLEFT", 0, -4)
helperText:SetWidth(300)
helperText:SetJustifyH("LEFT")
helperText:SetText("0 = ignore, 5 = default, 10 = highest importance. Values are saved per character.")

local colorLegend = weightSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
colorLegend:SetPoint("TOPLEFT", helperText, "BOTTOMLEFT", 0, -8)
colorLegend:SetWidth(300)
colorLegend:SetJustifyH("LEFT")
colorLegend:SetText("Color guide: red/orange/yellow means below the current gear average, green means around average, and blue/violet means above it.")

-- The stat-weight section uses the same section shape as the other settings blocks: divider, title, short description, then rows.
local function CreateStatRow(parent, stat)
	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(300, 22)

	local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", 0, 0)
	label:SetText(stat.name)

	local value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	value:SetPoint("CENTER", 0, 0)
	value:SetText("5")
	weightLabels[stat.key] = value

	local upButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	upButton:SetSize(24, 20)
	upButton:SetPoint("RIGHT", 0, 0)
	upButton:SetText("+")
	upButton:SetScript("OnClick", function()
		SetWeight(stat.key, 1)
	end)

	local downButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	downButton:SetSize(24, 20)
	downButton:SetPoint("RIGHT", upButton, "LEFT", -4, 0)
	downButton:SetText("-")
	downButton:SetScript("OnClick", function()
		SetWeight(stat.key, -1)
	end)

	return row
end

local function ReflowStatGroups()
	local currentY = -102
	local totalHeight = 0

	for _, group in ipairs(statGroups) do
		local block = group._block
		if block then
			block.header:SetPoint("TOPLEFT", weightSection, "TOPLEFT", 16, currentY)
			block.divider:SetPoint("TOPLEFT", weightSection, "TOPLEFT", 16, currentY - 16)
			block.expandButton:SetPoint("TOPRIGHT", weightSection, "TOPRIGHT", -16, currentY)

			local rowSpacing = 24
			local visibleRowCount = group.expanded and #group.stats or 0
			for index, row in ipairs(block.rows) do
				local isVisible = group.expanded and index <= visibleRowCount
				row:SetShown(isVisible)
				if isVisible then
					row:SetPoint("TOPLEFT", weightSection, "TOPLEFT", 28, currentY - 28 - ((index - 1) * rowSpacing))
				end
			end

			currentY = currentY - 28 - (group.expanded and (visibleRowCount * rowSpacing) or 0) - 14
			totalHeight = math.abs(currentY) + 100
		end
	end

	weightSection:SetHeight(math.max(220, totalHeight))
	scrollChild:SetHeight(math.max(760, generalSection:GetHeight() + profileSection:GetHeight() + weightSection:GetHeight() + 40))
end

for _, group in ipairs(statGroups) do
	local block = {}
	block.header = weightSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	block.header:SetText(group.title)

	block.divider = weightSection:CreateTexture(nil, "OVERLAY")
	block.divider:SetColorTexture(0.6, 0.6, 0.6, 0.25)
	block.divider:SetSize(300, 1)

	block.expandButton = CreateFrame("Button", nil, weightSection, "UIPanelButtonTemplate")
	block.expandButton:SetSize(24, 20)
	block.expandButton:SetText(group.expanded and "-" or "+")
	block.expandButton:SetScript("OnClick", function(self)
		group.expanded = not group.expanded
		self:SetText(group.expanded and "-" or "+")
		ReflowStatGroups()
	end)

	block.rows = {}
	for _, stat in ipairs(group.stats) do
		local row = CreateStatRow(weightSection, stat)
		row:SetShown(group.expanded)
		table.insert(block.rows, row)
	end

	group._block = block
	group.rows = block.rows
end

ReflowStatGroups()
RefreshGeneralSettingsUI()
SafeCall(InitializeProfileState)

-- The minimap button is a second entry point into the same single settings window used by the slash commands.
minimapButton = CreateFrame("Button", "LevelingGearsMinimapButton", Minimap)
minimapButton:SetSize(31, 31)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetPoint("CENTER", Minimap, "CENTER", 80, 0)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:SetScript("OnClick", function(_, button)
	if button == "LeftButton" or button == "RightButton" then
		ToggleLevelingGears()
	end
end)

local minimapIcon = minimapButton:CreateTexture(nil, "ARTWORK")
minimapIcon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
minimapIcon:SetAllPoints(minimapButton)
minimapIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapBorder:SetSize(53, 53)
minimapBorder:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", -8, 8)

minimapButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	GameTooltip:SetText("Leveling Gears")
	GameTooltip:AddLine("Click to open or close the settings window", 1, 1, 1, true)
	GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function(_)
	GameTooltip:Hide()
end)

-- The addon exposes only the two primary entry points so the command surface stays simple for users.
SLASH_LEVELINGGEARS1 = "/levelinggears"
SLASH_LEVELINGGEARS2 = "/lgs"
SlashCmdList["LEVELINGGEARS"] = HandleSlashCommand
SafeCall(UpdateEquippedGearEvaluation)
