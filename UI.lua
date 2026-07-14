-- Leveling Gears -- UI.lua
-- The single settings window: every frame and widget the addon ever shows, plus the small
-- "Refresh*"/"Set*" functions that keep them in sync with SavedVariables. Pure data and weight
-- math live in Settings.lua/Weights.lua; this file only creates and updates widgets, calling into
-- LG.Settings/LG.Weights/LG.Scoring/LG.GearEvaluation for the data and logic behind what's shown.

local _, LG = ...
LG.UI = LG.UI or {}
local UI = LG.UI

local PrintChat = LG.Debug.PrintChat
local SafeCall = LG.Debug.SafeCall

local minimapButton = nil
local profileDropdownButton = nil
local profileDropdownMenuFrame = nil
local profileRows = {}
local generalSettingsCheckbox = nil
local weightLabels = {}

-- Apply any previously saved frame position so the window appears where it was last left.
local function ApplySavedPosition(frame)
	local settings = LG.Settings.GetGeneralSettings()
	local pos = settings.position
	if pos and pos.point and pos.relativePoint then
		frame:ClearAllPoints()
		frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x or 0, pos.y or 0)
	end
end

-- Persist the frame position so the window opens in the same place after reloads.
local function SaveWindowPosition(frame)
	local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
	if relativeTo ~= UIParent then
		relativePoint = point or "CENTER"
		xOfs, yOfs = 0, 0
	end

	local settings = LG.Settings.GetGeneralSettings()
	settings.position = {
		point = point or "CENTER",
		relativePoint = relativePoint or "CENTER",
		x = xOfs or 0,
		y = yOfs or 0,
	}
end

-- Open or close the single settings window that the addon uses for all configuration.
function UI.ToggleLevelingGears()
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

function UI.SetMinimapButtonShown(visible)
	if minimapButton then
		minimapButton:SetShown(visible)
	end
end

function UI.RefreshGeneralSettingsUI()
	if generalSettingsCheckbox then
		local settings = LG.Settings.GetGeneralSettings()
		generalSettingsCheckbox:SetChecked(settings.minimapEnabled ~= false)
	end
end

-- Update just the one changed weight label -- used by Weights.SetWeight on every +/- click, kept
-- deliberately cheap (a single SetText, no full repaint or gear-evaluation trigger of its own).
function UI.SetWeightLabelText(statKey, text)
	if weightLabels[statKey] then
		weightLabels[statKey]:SetText(text)
	end
end

-- Repaint every visible weight label from the currently active profile so the settings page stays
-- in sync, then re-run the (debounce-free) gear evaluation -- used for coarse-grained refresh
-- moments (window open, profile switch/create, Restore Defaults), never per-click.
function UI.RefreshWeightLabels()
	LG.Weights.EnsureWeights()
	local profile = LG.Settings.GetActiveProfile()
	for _, stat in ipairs(LG.Weights.statDefinitions) do
		if weightLabels[stat.key] then
			weightLabels[stat.key]:SetText(LG.Weights.FormatWeight(profile.weights[stat.key] or 5))
		end
	end
	SafeCall(LG.GearEvaluation.UpdateEquippedGearEvaluation)
end

-- The profile picker is a compact dropdown-style menu that keeps the settings page simple.
local function ToggleProfileMenu()
	if not profileDropdownMenuFrame or not profileDropdownButton then
		return
	end
	profileDropdownMenuFrame:SetShown(not profileDropdownMenuFrame:IsShown())
end

-- Build and refresh the visible profile list so the current character's profiles are always represented in the UI.
function UI.RefreshProfileList()
	local characterState = LG.Settings.GetCharacterState()
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
				LG.Settings.CreateProfile("Default")
			elseif profileId == "create_new" then
				LG.Settings.CreateProfile("Profile " .. tostring((next(profiles) and 1 or 0) + 1))
			else
				LG.Settings.SetActiveProfile(profileId)
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

-- ============================================================================
-- Main window frame
-- ============================================================================

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
		UI.RefreshGeneralSettingsUI()
		UI.RefreshProfileList()
		UI.RefreshWeightLabels()
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
version:SetText("v" .. LG.ADDON_VERSION)

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
-- LevelingGearsDB the instant it changes, and the client itself flushes SavedVariables to disk at
-- its own save points (/reload, logout, exit). This button only gives an honest, immediate
-- confirmation of the state that already exists -- see CLAUDE.md's Technical notes.
local saveSettingsButton = CreateFrame("Button", nil, LevelingGears, "UIPanelButtonTemplate")
saveSettingsButton:SetSize(150, 22)
saveSettingsButton:SetPoint("BOTTOM", LevelingGears, "BOTTOM", 0, 10)
saveSettingsButton:SetText("Save Settings")
saveSettingsButton:SetScript("OnClick", function()
	-- Re-sync every displayed number from LevelingGearsDB so what's on screen is visibly, provably
	-- the same as what's saved, rather than just taking a chat message on faith.
	UI.RefreshGeneralSettingsUI()
	UI.RefreshProfileList()
	UI.RefreshWeightLabels()
	local profile = LG.Settings.GetActiveProfile()
	local profileName = profile and profile.name or "Default"
	PrintChat("Saved. Profile '" .. profileName .. "' for this character is stored and will still be here after /reload or a full relog.")
end)

-- ============================================================================
-- General settings section
-- ============================================================================

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
	LG.Settings.SetMinimapEnabled(self:GetChecked())
end)

local generalCheckboxText = generalSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
generalCheckboxText:SetPoint("LEFT", generalSettingsCheckbox, "RIGHT", 4, 1)
generalCheckboxText:SetText("Show minimap button")

local divider = generalSection:CreateTexture(nil, "OVERLAY")
divider:SetColorTexture(0.6, 0.6, 0.6, 0.4)
divider:SetSize(300, 1)
divider:SetPoint("TOPLEFT", generalSettingsCheckbox, "BOTTOMLEFT", 0, -12)

generalSection:SetHeight(92)

-- ============================================================================
-- Profiles section
-- ============================================================================

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

-- ============================================================================
-- Stat weights section
-- ============================================================================

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
helperText:SetText("0 = ignore, 10 = highest importance, in steps of 0.05 (hold Shift for +-1). Values are saved per character.")

local colorLegend = weightSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
colorLegend:SetPoint("TOPLEFT", helperText, "BOTTOMLEFT", 0, -8)
colorLegend:SetWidth(300)
colorLegend:SetJustifyH("LEFT")
colorLegend:SetText("Color guide: red/orange/yellow means below the current gear average, green means around average, and blue/violet means above it.")

-- The addon's own spec-aware weights (Priorities.lua) ARE the defaults; any +/- adjustment
-- overrides them from then on (EnsureWeights never overwrites a touched value). This button is the
-- explicit, visible way back to those defaults if the player wants a clean slate.
local restoreDefaultsButton = CreateFrame("Button", nil, weightSection, "UIPanelButtonTemplate")
restoreDefaultsButton:SetSize(140, 20)
restoreDefaultsButton:SetPoint("TOPLEFT", colorLegend, "BOTTOMLEFT", 0, -8)
restoreDefaultsButton:SetText("Restore Defaults")
restoreDefaultsButton:SetScript("OnClick", function()
	SafeCall(LG.Weights.RestoreDefaultWeights)
end)

-- Every group's stats are looked up by key from LG.Weights.statDefinitions (the single
-- authoritative key+name list) rather than re-typed here, so a stat only ever needs to be named
-- in one place.
local STAT_GROUP_LAYOUT = {
	{ title = "Core stats", expanded = true, keys = { "SP", "HEAL", "AP", "RAP", "HEALTH", "MANA" } },
	{ title = "Other stats", expanded = false, keys = {
		"HIT", "CRIT", "HASTE", "EXP", "ARMORPEN", "ARMOR", "DEF", "DODGE", "PARRY",
		"BLOCK", "BLOCKVALUE", "RESILIENCE", "MP5", "SPELLPEN",
	} },
	{ title = "Resistances", expanded = false, keys = {
		"ARCANERES", "FIRERES", "FROSTRES", "NATURERES", "SHADOWRES",
	} },
}

local statByKey = {}
for _, stat in ipairs(LG.Weights.statDefinitions) do
	statByKey[stat.key] = stat
end

local statGroups = {}
for _, groupLayout in ipairs(STAT_GROUP_LAYOUT) do
	local stats = {}
	for _, key in ipairs(groupLayout.keys) do
		table.insert(stats, statByKey[key])
	end
	table.insert(statGroups, { title = groupLayout.title, expanded = groupLayout.expanded, stats = stats })
end

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
		LG.Weights.SetWeight(stat.key, IsShiftKeyDown() and 1 or LG.Weights.WEIGHT_STEP)
	end)

	local downButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	downButton:SetSize(24, 20)
	downButton:SetPoint("RIGHT", upButton, "LEFT", -4, 0)
	downButton:SetText("-")
	downButton:SetScript("OnClick", function()
		LG.Weights.SetWeight(stat.key, IsShiftKeyDown() and -1 or -LG.Weights.WEIGHT_STEP)
	end)

	return row
end

local function ReflowStatGroups()
	-- Starting offset accounts for the header, helper text, color legend, and the Restore Defaults
	-- button above the stat groups; verify in game that the first group's header doesn't overlap
	-- that button after any font/wrap-width change (see CLAUDE.md's UI-overlap rule).
	local currentY = -134
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

-- ============================================================================
-- Minimap button
-- ============================================================================

-- The minimap button is a second entry point into the same single settings window used by the slash commands.
minimapButton = CreateFrame("Button", "LevelingGearsMinimapButton", Minimap)
minimapButton:SetSize(31, 31)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetPoint("CENTER", Minimap, "CENTER", 80, 0)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:SetScript("OnClick", function(_, button)
	if button == "LeftButton" or button == "RightButton" then
		UI.ToggleLevelingGears()
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
