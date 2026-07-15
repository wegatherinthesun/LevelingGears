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
local generalSettingsCheckbox = nil
local weightInputs = {}

-- Apply any previously saved frame position so the window appears where it was last left.
-- Bug #29 (open): testers report the restored position is consistently in "a similar general
-- area" but not the exact spot the window was dragged to -- logged here and in SaveWindowPosition
-- so a real debug-log comparison of saved vs. applied values is possible next test pass, rather
-- than guessing at a fix with no evidence.
local function ApplySavedPosition(frame)
	local settings = LG.Settings.GetGeneralSettings()
	local pos = settings.position
	if pos and pos.point and pos.relativePoint then
		frame:ClearAllPoints()
		frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x or 0, pos.y or 0)
		if LG.Debug then
			LG.Debug.WriteDebugLog(string.format(
				"ApplySavedPosition: point=%s relativePoint=%s x=%.2f y=%.2f",
				pos.point, pos.relativePoint, pos.x or 0, pos.y or 0), 1)
		end
	end
end

-- Persist the frame position so the window opens in the same place after reloads.
local function SaveWindowPosition(frame)
	local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
	if relativeTo ~= UIParent then
		relativePoint = point or "CENTER"
		xOfs, yOfs = 0, 0
	end

	-- Round to whole pixels: SetPoint/GetPoint round-trips can accumulate tiny floating-point
	-- drift across repeated save/restore cycles, and WoW positions are effectively pixel-integer
	-- anyway. Cheap, safe regardless of whether this turns out to be bug #29's actual cause.
	xOfs = math.floor((xOfs or 0) + 0.5)
	yOfs = math.floor((yOfs or 0) + 0.5)

	local settings = LG.Settings.GetGeneralSettings()
	settings.position = {
		point = point or "CENTER",
		relativePoint = relativePoint or "CENTER",
		x = xOfs,
		y = yOfs,
	}
	if LG.Debug then
		LG.Debug.WriteDebugLog(string.format(
			"SaveWindowPosition: point=%s relativePoint=%s x=%d y=%d",
			settings.position.point, settings.position.relativePoint, xOfs, yOfs), 1)
	end
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

-- Update just the one changed weight input -- used by Weights.SetWeightValue after a committed
-- edit, kept deliberately cheap (a single SetText, no full repaint or gear-evaluation trigger of
-- its own).
function UI.SetWeightLabelText(statKey, text)
	if weightInputs[statKey] then
		weightInputs[statKey]:SetText(text)
	end
end

-- Repaint every visible weight input from the character's saved weights so the settings page stays
-- in sync, then re-run the (debounce-free) gear evaluation -- used for coarse-grained refresh
-- moments (window open, Restore Defaults, reverting an invalid typed value), never per-keystroke.
function UI.RefreshWeightLabels()
	LG.Weights.EnsureWeights()
	local characterState = LG.Settings.GetCharacterState()
	for _, stat in ipairs(LG.Weights.statDefinitions) do
		if weightInputs[stat.key] then
			weightInputs[stat.key]:SetText(LG.Weights.FormatWeight(characterState.weights[stat.key] or 5))
		end
	end
	SafeCall(LG.GearEvaluation.UpdateEquippedGearEvaluation)
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
	UI.RefreshWeightLabels()
	PrintChat("Saved. Your settings for this character are stored and will still be here after /reload or a full relog.")
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
-- Stat weights section
-- ============================================================================

local weightSection = CreateFrame("Frame", nil, scrollChild)
weightSection:SetSize(320, 220)
weightSection:SetPoint("TOPLEFT", generalSection, "BOTTOMLEFT", 0, -20)

local weightHeader = weightSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
weightHeader:SetPoint("TOPLEFT", weightSection, "TOPLEFT", 8, -8)
weightHeader:SetText("Stat weights")

local helperText = weightSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
helperText:SetPoint("TOPLEFT", weightHeader, "BOTTOMLEFT", 0, -4)
helperText:SetWidth(300)
helperText:SetJustifyH("LEFT")
helperText:SetText("0 = ignore, 10 = highest importance. Type a value and press Enter (or click away) to save. Values are saved per character.")

local colorLegend = weightSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
colorLegend:SetPoint("TOPLEFT", helperText, "BOTTOMLEFT", 0, -8)
colorLegend:SetWidth(300)
colorLegend:SetJustifyH("LEFT")
colorLegend:SetText("Color guide: red/orange/yellow means below the current gear average, green means around average, and blue/violet means above it.")

-- The addon's own spec-aware weights (Priorities.lua) ARE the defaults; typing a new value into any
-- stat's edit box overrides that stat from then on (EnsureWeights never overwrites a touched
-- value). This button persists as the explicit, visible way back to those defaults if the player
-- wants a clean slate.
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
-- v0.305 (bugs/known-bugs.md #32): the old label + value + up/down-button row (with a Shift-click
-- modifier for coarser steps) was reported as too complicated. Replaced with a plain label and a
-- single edit box showing the exact value the scoring engine uses -- type a new value directly
-- instead of clicking +/- dozens of times.
local function CreateStatRow(parent, stat)
	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(300, 22)

	local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", 0, 0)
	label:SetText(stat.name)

	local input = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
	input:SetSize(50, 20)
	input:SetPoint("RIGHT", 0, 0)
	input:SetAutoFocus(false)
	input:SetJustifyH("CENTER")
	input:SetText("5")
	weightInputs[stat.key] = input

	-- Parses and commits whatever is currently typed. Invalid (non-numeric) text is not silently
	-- kept on screen -- reverting to the real saved value makes clear the edit didn't take effect,
	-- rather than leaving stale-looking text that implies it did.
	local function CommitValue()
		local parsed = tonumber(input:GetText())
		if not parsed then
			UI.RefreshWeightLabels()
			return
		end
		LG.Weights.SetWeightValue(stat.key, parsed)
	end

	input:SetScript("OnEnterPressed", function(self)
		CommitValue()
		self:ClearFocus()
	end)
	input:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	input:SetScript("OnEditFocusLost", CommitValue)

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
	scrollChild:SetHeight(math.max(760, generalSection:GetHeight() + weightSection:GetHeight() + 40))
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
