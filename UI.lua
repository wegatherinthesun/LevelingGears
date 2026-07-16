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
local specDropdownButton = nil
local specStatusText = nil

-- Bug #29: testers reported the restored position is consistently in "a similar general area" but
-- not the exact spot the window was dragged to, even though extensive debug-log evidence showed
-- this addon's own save/apply values always matched exactly (ruling out a UI-scale mismatch, the
-- earlier theory). Per direct instruction, compared against how other addons on this client handle
-- window position before guessing again: AceGUI-3.0's own Window widget (used by Bartender4 and
-- many other addons here -- see AceGUIContainer-Window.lua) does NOT save a single point/
-- relativePoint/offset triple from GetPoint(1) the way this file used to. It saves two independent
-- ABSOLUTE screen coordinates (GetLeft()/GetTop()) and restores them as two separate anchors tied to
-- opposite fixed screen edges (TOP from UIParent's BOTTOM, LEFT from UIParent's LEFT). That sidesteps
-- any ambiguity about which single corner/point WoW's drag system happened to pick internally after
-- StopMovingOrSizing() -- this addon now does the same thing.

-- Apply any previously saved frame position so the window appears where it was last left.
local function ApplySavedPosition(frame)
	local settings = LG.Settings.GetGeneralSettings()
	local pos = settings.position
	if pos and pos.left and pos.top then
		frame:ClearAllPoints()
		frame:SetPoint("TOP", UIParent, "BOTTOM", 0, pos.top)
		frame:SetPoint("LEFT", UIParent, "LEFT", pos.left, 0)
		if LG.Debug then
			LG.Debug.WriteDebugLog(string.format(
				"ApplySavedPosition: left=%d top=%d frameScale=%.4f frameEffScale=%.4f " ..
				"uiParentEffScale=%.4f",
				pos.left, pos.top,
				frame:GetScale(), frame:GetEffectiveScale(), UIParent:GetEffectiveScale()), 1, "window")
		end
	end
end

-- Persist the frame position so the window opens in the same place after reloads.
local function SaveWindowPosition(frame)
	local left = frame:GetLeft()
	local top = frame:GetTop()
	if not left or not top then
		return
	end

	local settings = LG.Settings.GetGeneralSettings()
	settings.position = {
		left = math.floor(left + 0.5),
		top = math.floor(top + 0.5),
	}
	if LG.Debug then
		LG.Debug.WriteDebugLog(string.format(
			"SaveWindowPosition: left=%d top=%d frameScale=%.4f frameEffScale=%.4f " ..
			"uiParentEffScale=%.4f",
			settings.position.left, settings.position.top,
			frame:GetScale(), frame:GetEffectiveScale(), UIParent:GetEffectiveScale()), 1, "window")
	end
end

-- Apply any previously saved frame size (from a corner drag-resize) so the window reopens at the
-- size it was last left, the same way ApplySavedPosition already does for position.
local function ApplySavedSize(frame)
	local settings = LG.Settings.GetGeneralSettings()
	local size = settings.size
	if size and size.width and size.height then
		frame:SetSize(size.width, size.height)
	end
end

-- Persist the frame size so a corner drag-resize survives a reload, mirroring SaveWindowPosition.
local function SaveWindowSize(frame)
	local width, height = frame:GetSize()
	if not width or not height then
		return
	end

	local settings = LG.Settings.GetGeneralSettings()
	settings.size = {
		width = math.floor(width + 0.5),
		height = math.floor(height + 0.5),
	}
	if LG.Debug then
		LG.Debug.WriteDebugLog(string.format(
			"SaveWindowSize: width=%d height=%d", settings.size.width, settings.size.height), 1, "window")
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

-- Builds the dropdown's menu entries fresh every time it's opened ("Auto-detect" + the player's own
-- class's 3 real specs), via Blizzard's own native dropdown API -- confirmed safe to call directly
-- on this client (no library shim needed) by finding a real installed addon (Omen.lua) that already
-- does the same thing: a plain `CreateFrame(..., "UIDropDownMenuTemplate")` with direct
-- `UIDropDownMenu_*`/`ToggleDropDownMenu` global calls, no version gating.
local function InitializeSpecDropdown(_, level)
	local _, class = UnitClass("player")
	local options = LG.Scoring and LG.Scoring.GetSpecOptions(class) or {}
	local characterState = LG.Settings.GetCharacterState()
	local override = characterState.specOverride

	local function OnSelect(self)
		LG.Settings.SetSpecOverride(self.value)
		CloseDropDownMenus()
	end

	local info = UIDropDownMenu_CreateInfo()
	info.text = "Auto-detect"
	info.value = nil
	info.func = OnSelect
	info.checked = (override == nil)
	UIDropDownMenu_AddButton(info, level)

	for _, option in ipairs(options) do
		info = UIDropDownMenu_CreateInfo()
		info.text = option.label
		info.value = option.key
		info.func = OnSelect
		info.checked = (override == option.key)
		UIDropDownMenu_AddButton(info, level)
	end
end

-- Refresh the "Spec:" dropdown's displayed text and the status line describing what's actually
-- being used to score gear right now -- called on window open and whenever the override changes, so
-- a player never has to guess whether their choice (or the auto-detected guess) took effect.
function UI.RefreshSpecUI()
	if not specDropdownButton then
		return
	end

	local _, class = UnitClass("player")
	local characterState = LG.Settings.GetCharacterState()
	local override = characterState.specOverride
	local options = LG.Scoring and LG.Scoring.GetSpecOptions(class) or {}
	local buttonLabel = "Auto-detect"
	for _, option in ipairs(options) do
		if option.key == override then
			buttonLabel = option.label
			break
		end
	end
	UIDropDownMenu_SetText(specDropdownButton, buttonLabel)

	if specStatusText then
		local description = "?"
		if LG.Scoring then
			local success, result = SafeCall(function()
				return LG.Scoring:DescribeCurrentSpec()
			end)
			if success and result then
				description = result
			end
		end
		specStatusText:SetText("Currently scoring as: " .. description)
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
LevelingGears:SetSize(588, 462) -- 40% bigger than the original 420x330 default
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
LevelingGears:SetResizable(true)
-- Min matches the original pre-resize default so the window can never be shrunk into something
-- unusably small; max is a reasoned, generous cap, not a measured in-game value. SetResizeBounds is
-- the modern replacement for SetMinResize/SetMaxResize (confirmed real, not guessed: Attune has
-- SetMinResize commented out on its own frame with a "--HC BUG" note, using SetResizeBounds instead;
-- AceGUI-3.0's AceGUIContainer-Frame.lua checks `if frame.SetResizeBounds then` before falling back
-- to SetMinResize, calling SetResizeBounds a "WoW 10.0" addition -- both installed on this client).
if LevelingGears.SetResizeBounds then
	LevelingGears:SetResizeBounds(420, 330, 900, 700)
else
	LevelingGears:SetMinResize(420, 330)
	LevelingGears:SetMaxResize(900, 700)
end
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
		ApplySavedSize(self)
		self:SetFrameStrata("DIALOG")
		self:SetFrameLevel(100)
		self:SetToplevel(true)
		-- Re-sync every displayed control from LevelingGearsDB on every open, not just once at
		-- file load: this guarantees what's on screen always matches what's actually saved,
		-- regardless of how long ago the addon originally loaded.
		UI.RefreshGeneralSettingsUI()
		UI.RefreshSpecUI()
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
			ApplySavedSize(self)
		end
	end)
end)
LevelingGears:RegisterEvent("ADDON_LOADED")
LevelingGears:Hide()

-- Corner resize handles. StartSizing/StopMovingOrSizing mirrors a real, confirmed-working pattern
-- already installed on this client (Questie's Modules/Tracker/TrackerBaseFrame.lua). Draggability is
-- shown with a visible grip texture instead of a cursor swap -- no installed addon on this client
-- uses a resize-specific SetCursor name (only BUY_CURSOR/UI_MOVE_CURSOR/CAST_CURSOR appear anywhere),
-- so rather than guess an unverified one, this mirrors DBM-GUI's own resize handle
-- (modules/MainFrame.lua): a Button using Blizzard's own shipped chat-frame resize textures
-- (Interface\ChatFrame\UI-ChatIM-SizeGrabber-*), which come with a highlight-on-hover for free.
-- Only BOTTOMRIGHT gets the visible grip, matching every real resize handle found on this client
-- (DBM-GUI, Omen). Top corners are disabled per direct instruction (BOTTOMLEFT stays resizable but
-- without its own grip graphic, matching the single-conventional-grip reasoning above).
local RESIZE_CORNERS = { "BOTTOMLEFT", "BOTTOMRIGHT" }
local RESIZE_HANDLE_SIZE = 14 -- 30% smaller than the original 20

for _, corner in ipairs(RESIZE_CORNERS) do
	local sizer = CreateFrame("Button", nil, LevelingGears)
	sizer:SetSize(RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE)
	sizer:SetPoint(corner, 0, 0)

	if corner == "BOTTOMRIGHT" then
		sizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
		sizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
		sizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	end

	sizer:SetScript("OnMouseDown", function(_, button)
		if button ~= "LeftButton" then
			return
		end
		SafeCall(function()
			LevelingGears:StartSizing(corner)
		end)
	end)
	sizer:SetScript("OnMouseUp", function()
		SafeCall(function()
			LevelingGears:StopMovingOrSizing()
			SaveWindowSize(LevelingGears)
		end)
	end)
end

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
	-- T22 (v0.382 test pass): "resets as soon as I hit save" -- typing a value then clicking this
	-- button directly (without pressing Enter or clicking elsewhere first) never gave the edit box a
	-- chance to fire OnEditFocusLost/commit its typed text, so RefreshWeightLabels below immediately
	-- overwrote the box from the still-old saved value, making a real edit look like it was rejected.
	-- Clearing focus on every weight input first forces any pending edit to commit before the
	-- refresh reads back from LevelingGearsDB. ClearFocus on a box that isn't focused is a no-op.
	for _, input in pairs(weightInputs) do
		input:ClearFocus()
	end

	-- Re-sync every displayed number from LevelingGearsDB so what's on screen is visibly, provably
	-- the same as what's saved, rather than just taking a chat message on faith.
	UI.RefreshGeneralSettingsUI()
	UI.RefreshSpecUI()
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
-- Spec section (v0.38, bug #37)
-- ============================================================================
-- Auto-detection reads literal current talent points, which doesn't reliably reflect a leveling
-- character's intended build (a partially-specced or early-hybrid talent spread is normal well
-- before every point lands in one tree -- see Scoring.lua's DetectSpec and bugs/known-bugs.md #37).
-- This lets a player just say which of their class's 3 specs they actually are, overriding whatever
-- the talent-point reading below would otherwise guess.

local specSection = CreateFrame("Frame", nil, scrollChild)
specSection:SetSize(320, 100)
specSection:SetPoint("TOPLEFT", generalSection, "BOTTOMLEFT", 0, -20)

local specHeader = specSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
specHeader:SetPoint("TOPLEFT", specSection, "TOPLEFT", 8, -8)
specHeader:SetText("Spec")

local specHint = specSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
specHint:SetPoint("TOPLEFT", specHeader, "BOTTOMLEFT", 0, -4)
specHint:SetWidth(300)
specHint:SetJustifyH("LEFT")
specHint:SetText("Auto-detect reads your talent points, which can be unreliable while leveling. Pick your spec directly if the detected one looks wrong.")

local specDropdownLabel = specSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
specDropdownLabel:SetPoint("TOPLEFT", specHint, "BOTTOMLEFT", 0, -12)
specDropdownLabel:SetText("Spec:")

-- A real Blizzard dropdown, not a custom button + hand-rolled menu frame (that approach read as
-- "just a button" and needed a permanently-reserved gap for its own menu -- reported in the v0.382
-- test pass). Confirmed `UIDropDownMenuTemplate` + the native `UIDropDownMenu_*`/`ToggleDropDownMenu`
-- globals are safe to call directly on this client (no library shim needed) by finding a real
-- installed addon doing exactly that with no version gating: Omen.lua's own right-click menu. The
-- template's built-in Button already handles click-to-open/close and outside-click-to-close on its
-- own -- no custom OnClick/OnLeave/auto-close logic needed here at all.
specDropdownButton = CreateFrame("Frame", "LevelingGearsSpecDropdown", specSection, "UIDropDownMenuTemplate")
-- The template reserves ~16px of invisible left-padding for its texture; -16 aligns the visible box
-- with where a plain widget would otherwise start. Standard, long-established convention for this
-- template, not a guess specific to this addon.
specDropdownButton:SetPoint("TOPLEFT", specDropdownLabel, "TOPRIGHT", -8, 8)
UIDropDownMenu_SetWidth(specDropdownButton, 130)
UIDropDownMenu_SetText(specDropdownButton, "Auto-detect")
UIDropDownMenu_Initialize(specDropdownButton, InitializeSpecDropdown)

-- Directly below the dropdown, matching its actual (not the label's) vertical position.
specStatusText = specSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
specStatusText:SetPoint("TOPLEFT", specDropdownLabel, "BOTTOMLEFT", 0, -20)
specStatusText:SetWidth(300)
specStatusText:SetJustifyH("LEFT")
specStatusText:SetText("Currently scoring as: ?")

local specDivider = specSection:CreateTexture(nil, "OVERLAY")
specDivider:SetColorTexture(0.6, 0.6, 0.6, 0.4)
specDivider:SetSize(300, 1)
specDivider:SetPoint("TOPLEFT", specStatusText, "BOTTOMLEFT", 0, -12)

-- Not yet visually confirmed in game (same caveat as every other UI-only change in this ledger, e.g.
-- bug #25) -- a reasoned estimate; the dropdown template's own extra vertical padding (~20px above
-- its clickable box) is accounted for in specStatusText's anchor above.
specSection:SetHeight(130)

-- ============================================================================
-- Stat weights section
-- ============================================================================

local weightSection = CreateFrame("Frame", nil, scrollChild)
weightSection:SetSize(320, 220)
weightSection:SetPoint("TOPLEFT", specSection, "BOTTOMLEFT", 0, -20)

local weightHeader = weightSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
weightHeader:SetPoint("TOPLEFT", weightSection, "TOPLEFT", 8, -8)
weightHeader:SetText("Stat weights")

local helperText = weightSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
helperText:SetPoint("TOPLEFT", weightHeader, "BOTTOMLEFT", 0, -4)
helperText:SetWidth(300)
helperText:SetJustifyH("LEFT")
helperText:SetText("Each box shows the exact weight used when scoring items for that stat. Raise it to care more, lower it (or zero it) to care less. Type a value and press Enter (or click away) to save. Values are saved per character.")

local colorLegend = weightSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
colorLegend:SetPoint("TOPLEFT", helperText, "BOTTOMLEFT", 0, -8)
colorLegend:SetWidth(300)
colorLegend:SetJustifyH("LEFT")
colorLegend:SetText("Color guide: red/orange/yellow means below the current gear average, green means around average, and blue/violet means above it.")

-- T20/T16 (v0.383+ queue): a tester scoring items on a Frost Mage asked why "Haste" was recommended
-- instead of a separate "Spell Haste" stat -- reasonable confusion, since Hit/Crit/Haste Rating are
-- shown as one box each rather than split by role. TBC itself never itemized a separate Spell Haste
-- stat (that split only arrived in Wrath) -- gear-granted Hit/Crit/Haste Rating already affects
-- melee, ranged, and spell at once, and Conversions.lua already converts each one using whichever of
-- those applies to the detected class/spec (CR_HASTE_SPELL for a Mage, etc. -- see its offense-type
-- lookup). The box was already being scored correctly as spell haste; nothing here told the player
-- that.
local hasteNote = weightSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
hasteNote:SetPoint("TOPLEFT", colorLegend, "BOTTOMLEFT", 0, -8)
hasteNote:SetWidth(300)
hasteNote:SetJustifyH("LEFT")
hasteNote:SetText("Hit, Crit, and Haste Rating are each a single box, not split by role -- TBC never itemized a separate \"Spell Haste\" stat, so the same Haste Rating value is converted for melee, ranged, or spell automatically, based on your class.")

-- ROADMAP.md 0.37: nothing previously told a player why familiar primary stats are missing from
-- this list. Strength/Agility/Intellect/Stamina/Spirit are converted into the derived stats shown
-- below (Conversions.lua) before any weight is applied -- weighting them directly too would
-- double-count (see DESIGN.md's double-counting rule).
local primaryStatsNote = weightSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
primaryStatsNote:SetPoint("TOPLEFT", hasteNote, "BOTTOMLEFT", 0, -8)
primaryStatsNote:SetWidth(300)
primaryStatsNote:SetJustifyH("LEFT")
primaryStatsNote:SetText("Strength, Agility, Intellect, Stamina, and Spirit aren't listed here -- they're automatically converted into the stats below (Attack Power, Crit, Health, Mana, etc.), so weighting them separately would count them twice.")

-- The addon's own spec-aware weights (Priorities.lua) ARE the defaults; typing a new value into any
-- stat's edit box overrides that stat from then on (EnsureWeights never overwrites a touched
-- value). This button persists as the explicit, visible way back to those defaults if the player
-- wants a clean slate.
local restoreDefaultsButton = CreateFrame("Button", nil, weightSection, "UIPanelButtonTemplate")
restoreDefaultsButton:SetSize(140, 20)
restoreDefaultsButton:SetPoint("TOPLEFT", primaryStatsNote, "BOTTOMLEFT", 0, -8)
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
	--
	-- T22 (v0.382 test pass): reported that typed values were not being accepted at all, for any
	-- stat. Trimmed leading/trailing whitespace before parsing (a real, if unconfirmed, candidate --
	-- EditBox:GetText() can include incidental whitespace depending on how focus/selection happened)
	-- and added a debug-log line showing the raw text and parse result, so if this doesn't fully fix
	-- it, the next attempt has real evidence instead of another guess.
	local function CommitValue()
		local rawText = input:GetText()
		local trimmed = rawText and rawText:match("^%s*(.-)%s*$") or rawText
		local parsed = tonumber(trimmed)
		if LG.Debug then
			LG.Debug.WriteDebugLog(string.format(
				"CommitValue: stat=%s rawText=%q parsed=%s",
				stat.key, tostring(rawText), tostring(parsed)), 1)
		end
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
	-- Real overlap reported live (Core stats overlapping Restore Defaults and the note above it) --
	-- this offset used to be a hand-guessed absolute number that had to be re-estimated (and kept
	-- getting it wrong, see bug #25/#26 and the -134 -> -160 -> -195 history) every time any note's
	-- text length changed. Anchored to restoreDefaultsButton's own actual bottom edge instead, so it
	-- can never drift out of sync with whatever text is above it again.
	local buttonBottom = restoreDefaultsButton:GetBottom()
	local sectionTop = weightSection:GetTop()
	local currentY = (buttonBottom and sectionTop) and (buttonBottom - sectionTop - 12) or -195
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

-- The minimap button is a second entry point into the same single settings window used by the slash
-- commands. T10 (v0.383+ queue): right-click used to just duplicate left-click's open/close, which
-- had no real purpose -- repurposed as press-and-drag instead, to reposition the button around the
-- minimap's edge (the same angle-around-the-circle technique most minimap-button addons use), with
-- the resulting angle persisted so it survives a reload.
local MINIMAP_BUTTON_RADIUS = 80

local function GetMinimapButtonAngle()
	local minimapX, minimapY = Minimap:GetCenter()
	local cursorX, cursorY = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	cursorX, cursorY = cursorX / scale, cursorY / scale
	return math.deg(math.atan2(cursorY - minimapY, cursorX - minimapX))
end

local function ApplyMinimapButtonAngle(button, angle)
	local radians = math.rad(angle)
	local x = math.cos(radians) * MINIMAP_BUTTON_RADIUS
	local y = math.sin(radians) * MINIMAP_BUTTON_RADIUS
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

minimapButton = CreateFrame("Button", "LevelingGearsMinimapButton", Minimap)
minimapButton:SetSize(31, 31)
minimapButton:SetFrameStrata("MEDIUM")

do
	local settings = LG.Settings.GetGeneralSettings()
	ApplyMinimapButtonAngle(minimapButton, settings.minimapAngle or 0)
end

minimapButton:RegisterForClicks("LeftButtonUp")
minimapButton:SetScript("OnClick", function(_, button)
	if button == "LeftButton" then
		UI.ToggleLevelingGears()
	end
end)

minimapButton:SetScript("OnMouseDown", function(self, button)
	if button ~= "RightButton" then
		return
	end
	self:SetScript("OnUpdate", function()
		ApplyMinimapButtonAngle(self, GetMinimapButtonAngle())
	end)
end)

minimapButton:SetScript("OnMouseUp", function(self, button)
	if button ~= "RightButton" then
		return
	end
	self:SetScript("OnUpdate", nil)
	local settings = LG.Settings.GetGeneralSettings()
	settings.minimapAngle = GetMinimapButtonAngle()
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
	GameTooltip:AddLine("Left-click to open or close the settings window", 1, 1, 1, true)
	GameTooltip:AddLine("Hold right-click and drag to move this button", 1, 1, 1, true)
	GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function(_)
	GameTooltip:Hide()
end)

-- ============================================================================
-- Score popout (shift+right-click on an equipped item -- see GearEvaluation.lua)
-- ============================================================================
-- Replaces the old chat-output score breakdown with a real flyout, per ROADMAP.md's "Starting to
-- actually use the database" section: opens near the clicked item, closes via its own X button or
-- by clicking anywhere else. One reusable frame (not one per click) -- showing it again just
-- repositions/repopulates it, so clicking a different item's slot while it's open doesn't stack
-- multiple popouts.

local scorePopout = nil
local scorePopoutOverlay = nil
local MAX_SCORE_POPOUT_LINES = 28 -- covers every derived stat key in Weights.lua's statDefinitions

-- A full-screen, invisible, mouse-enabled frame just below the popout in strata: clicking anywhere
-- that isn't the popout itself hits this instead and closes it. Standard "click away to close"
-- technique -- the popout's own strata sits above it so clicks ON the popout never reach here.
local function EnsureScorePopoutFrames()
	if scorePopout then
		return
	end

	scorePopoutOverlay = CreateFrame("Frame", nil, UIParent)
	scorePopoutOverlay:SetAllPoints(UIParent)
	scorePopoutOverlay:SetFrameStrata("FULLSCREEN")
	scorePopoutOverlay:EnableMouse(true)
	scorePopoutOverlay:Hide()
	scorePopoutOverlay:SetScript("OnMouseDown", function()
		UI.HideScorePopout()
	end)

	scorePopout = CreateFrame("Frame", "LevelingGearsScorePopout", UIParent,
		BackdropTemplateMixin and "BackdropTemplate" or nil)
	scorePopout:SetWidth(240)
	scorePopout:SetFrameStrata("FULLSCREEN_DIALOG")
	scorePopout:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	})
	scorePopout:EnableMouse(true)
	scorePopout:Hide()

	local popoutCloseButton = CreateFrame("Button", nil, scorePopout, "UIPanelCloseButton")
	popoutCloseButton:SetPoint("TOPRIGHT", -2, -2)
	popoutCloseButton:SetScript("OnClick", function()
		UI.HideScorePopout()
	end)

	local itemNameText = scorePopout:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	itemNameText:SetPoint("TOPLEFT", 16, -14)
	itemNameText:SetPoint("RIGHT", -28, 0)
	itemNameText:SetJustifyH("LEFT")
	scorePopout.itemNameText = itemNameText

	local scoreText = scorePopout:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	scoreText:SetPoint("TOPLEFT", itemNameText, "BOTTOMLEFT", 0, -6)
	scoreText:SetPoint("RIGHT", -16, 0)
	scoreText:SetJustifyH("LEFT")
	scorePopout.scoreText = scoreText

	local lines = {}
	for i = 1, MAX_SCORE_POPOUT_LINES do
		local line = scorePopout:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		line:SetPoint("TOPLEFT", scoreText, "BOTTOMLEFT", 0, -8 - (i - 1) * 14)
		line:SetPoint("RIGHT", -16, 0)
		line:SetJustifyH("LEFT")
		line:Hide()
		lines[i] = line
	end
	scorePopout.lines = lines
end

function UI.HideScorePopout()
	if scorePopout then
		scorePopout:Hide()
	end
	if scorePopoutOverlay then
		scorePopoutOverlay:Hide()
	end
end

-- Shows (or repositions/repopulates) the score popout anchored beside whichever slot button was
-- shift+right-clicked. `breakdown` is the same {statKey = contribution} table Scoring.lua's
-- PrintBreakdown used to print to chat -- sorted here the same way, largest contribution first.
function UI.ShowScorePopout(anchorFrame, itemLink, score, breakdown, specDescription)
	EnsureScorePopoutFrames()

	scorePopout.itemNameText:SetText(itemLink)
	scorePopout.scoreText:SetText(specDescription .. ": " .. string.format("%.1f", score))

	local sortedKeys = {}
	for statKey in pairs(breakdown) do
		table.insert(sortedKeys, statKey)
	end
	table.sort(sortedKeys, function(a, b)
		return math.abs(breakdown[a]) > math.abs(breakdown[b])
	end)

	for i, line in ipairs(scorePopout.lines) do
		local statKey = sortedKeys[i]
		if statKey then
			line:SetText(statKey .. ": " .. string.format("%.2f", breakdown[statKey]))
			line:Show()
		else
			line:Hide()
		end
	end

	-- Height follows however many stat lines actually showed, not a fixed guess: 14 = title, 30 =
	-- score line + gap, 8 = gap before the first stat line, 14 per stat line, 20 = bottom padding.
	local visibleLineCount = math.min(#sortedKeys, MAX_SCORE_POPOUT_LINES)
	scorePopout:SetHeight(14 + 30 + 8 + (visibleLineCount * 14) + 20)

	scorePopout:ClearAllPoints()
	scorePopout:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 8, 0)
	scorePopout:SetClampedToScreen(true)

	scorePopoutOverlay:Show()
	scorePopout:Show()
end
