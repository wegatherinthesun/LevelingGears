-- Leveling Gears -- SuggestionsUI.lua
-- The per-slot recommendation window (ROADMAP.md's `0.6`) -- a new frame, deliberately kept out of
-- UI.lua per that file's own note ("the popout box and the recommendation window are new frames
-- that get their own new file(s)"). Pure widget/display code: all the real query/scoring logic lives
-- in Suggestions.lua, this file just calls it and draws the result. Opened for now via the
-- `/lgs suggestwindow <slot>` debug command -- the real in-game trigger (tooltip hook / popout
-- button / etc.) is still an open decision, not resolved here.

local _, LG = ...
LG.SuggestionsUI = LG.SuggestionsUI or {}
local SuggestionsUI = LG.SuggestionsUI

local SafeCall = LG.Debug.SafeCall

local ROW_COUNT = 6
local ROW_HEIGHT = 46
local WINDOW_WIDTH = 420

local window = nil
local rows = {}
local currentSlotName = nil
local autoRefreshTimer = nil
local autoRefreshAttempts = 0

-- A densely-populated slot's first look can have hundreds of uncached items (real evidence: a level
-- 59 character's MainHandSlot had 271, none resolved within a couple of seconds) -- rather than make
-- the player manually mash Refresh while GetItemInfo's async requests trickle in, auto-retry a few
-- times on a timer. Capped (not indefinite) so a slot that's genuinely thin stops polling instead of
-- ticking forever; cancelled whenever a new Show() call supersedes it (slot switch or manual Refresh).
local AUTO_REFRESH_INTERVAL = 3
local AUTO_REFRESH_MAX_ATTEMPTS = 5

-- ROYGBIV isn't used here -- item quality has its own separate, native color system per
-- CONVENTIONS.md's color-system rule (never mix the two). ITEM_QUALITY_COLORS[quality] confirmed as
-- the real, working pattern on this client via an installed addon (Auctionator's ViewItem.lua),
-- rather than the GetItemQualityColor() function form.
local function GetQualityColor(quality)
	local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
	if color then
		return color.r, color.g, color.b
	end
	return 1, 1, 1
end

local function FormatUpgradeText(candidateScore, equippedScore)
	if not equippedScore or equippedScore == 0 then
		return "New"
	end
	local percent = (candidateScore - equippedScore) / math.abs(equippedScore) * 100
	return string.format("+%.0f%%", percent)
end

local function FormatSourceText(candidate)
	local bestSource = candidate.sources and candidate.sources[1]
	if not bestSource then
		return "Unknown source"
	end
	if bestSource.kind == "drop" then
		return string.format("Drops from a creature (%.0f%% chance, ~lvl %s)",
			(bestSource.dropRate or 0) * 100, tostring(bestSource.obtainLevel))
	elseif bestSource.kind == "quest" then
		return string.format("Quest reward (~lvl %s)", tostring(bestSource.obtainLevel))
	elseif bestSource.kind == "craft" then
		return string.format("Crafted (~lvl %s)", tostring(bestSource.obtainLevel))
	elseif bestSource.kind == "vendor" then
		return string.format("Vendor (%s copper)", tostring(bestSource.cost))
	elseif bestSource.kind == "boe" then
		return "Bind on Equip -- check the Auction House"
	end
	return "Unknown source"
end

local function FormatCategoryText(categories)
	local labels = {
		["crafted"] = "Crafted", ["boe"] = "BOE/AH", ["quest-local"] = "Nearby quest",
		["quest-nearby"] = "Same-continent quest", ["quest-far"] = "Distant quest", ["dungeon"] = "Dungeon",
	}
	local parts = {}
	for category in pairs(categories) do
		table.insert(parts, labels[category] or category)
	end
	table.sort(parts)
	return table.concat(parts, ", ")
end

local function CreateRow(parent)
	local row = CreateFrame("Button", nil, parent)
	row:SetSize(WINDOW_WIDTH - 32, ROW_HEIGHT)

	local icon = row:CreateTexture(nil, "ARTWORK")
	icon:SetSize(36, 36)
	icon:SetPoint("LEFT", 0, 0)
	row.icon = icon

	local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
	nameText:SetPoint("RIGHT", -60, 0)
	nameText:SetJustifyH("LEFT")
	row.nameText = nameText

	local upgradeText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	upgradeText:SetPoint("TOPRIGHT", 0, -2)
	upgradeText:SetJustifyH("RIGHT")
	row.upgradeText = upgradeText

	local sourceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	sourceText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -3)
	sourceText:SetPoint("RIGHT", -8, 0)
	sourceText:SetJustifyH("LEFT")
	row.sourceText = sourceText

	local categoryText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	categoryText:SetPoint("TOPLEFT", sourceText, "BOTTOMLEFT", 0, -2)
	categoryText:SetJustifyH("LEFT")
	row.categoryText = categoryText

	row:SetScript("OnEnter", function(self)
		if not self.itemLink then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink(self.itemLink)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(self.sourceLine, 1, 1, 1, true)
		if self.categoryLine ~= "" then
			GameTooltip:AddLine(self.categoryLine, 0.6, 0.6, 0.6, true)
		end
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	-- Inserts the item link into an open chat edit box, same native gesture every player already
	-- knows (Blizzard's own shift-click-to-link behavior) -- there's no "next-step" engine yet
	-- (ROADMAP.md's 0.7) for a click to meaningfully "select" this item against, so this is the one
	-- immediately useful action available today rather than a no-op.
	row:SetScript("OnClick", function(self)
		if self.itemLink and ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow() then
			ChatEdit_InsertLink(self.itemLink)
		end
	end)

	return row
end

local function EnsureWindow()
	if window then
		return
	end

	window = CreateFrame("Frame", "LevelingGearsSuggestionsWindow", UIParent,
		BackdropTemplateMixin and "BackdropTemplate" or nil)
	window:SetWidth(WINDOW_WIDTH)
	window:SetPoint("CENTER")
	window:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	})
	window:EnableMouse(true)
	-- Deliberately NOT draggable for now (no SetMovable/RegisterForDrag/drag scripts) -- real evidence
	-- this window's anchor point was drifting all over the screen (CENTER/LEFT/TOP/TOPLEFT) during a
	-- single test session, almost certainly from accidental drags: the whole window body was
	-- drag-enabled, not just a title strip, and 6 tightly-packed rows leave very little safe
	-- background to click without nudging the whole window. Removed outright rather than just
	-- fighting the drift after the fact -- Show() also force-resets position every call as a second
	-- safety net, but this is the real fix. Revisit once a dedicated title-bar-only drag zone is
	-- worth building.
	window:SetClampedToScreen(true)
	window:SetFrameStrata("DIALOG")
	window:SetToplevel(true)
	window:Hide()

	local closeButton = CreateFrame("Button", nil, window, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", -4, -4)

	local title = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	title:SetPoint("TOP", 0, -16)
	window.title = title

	local equippedText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	equippedText:SetPoint("TOP", title, "BOTTOM", 0, -6)
	window.equippedText = equippedText

	-- A small fixed-size container, itself centered below equippedText via a single TOP-to-BOTTOM
	-- anchor pair -- both buttons anchor to ITS edges, not to the window or to equippedText's own
	-- (content-dependent, so unpredictable) width. Avoids the hand-guessed-pixel-offset trap this
	-- project has been bitten by more than once (bug #25/#26/#41): nothing here depends on how wide
	-- any text turns out to render.
	local buttonRow = CreateFrame("Frame", nil, window)
	buttonRow:SetSize(90 + 4 + 90, 20)
	buttonRow:SetPoint("TOP", equippedText, "BOTTOM", 0, -12)
	window.buttonRow = buttonRow

	local refreshButton = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
	refreshButton:SetSize(90, 20)
	refreshButton:SetPoint("LEFT", 0, 0)
	refreshButton:SetText("Refresh")
	refreshButton:SetScript("OnClick", function()
		SafeCall(function()
			if currentSlotName then
				SuggestionsUI.Show(currentSlotName)
			end
		end)
	end)
	window.refreshButton = refreshButton

	local settingsButton = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
	settingsButton:SetSize(90, 20)
	settingsButton:SetPoint("LEFT", refreshButton, "RIGHT", 4, 0)
	settingsButton:SetText("Settings")
	settingsButton:SetScript("OnClick", function()
		SafeCall(function()
			LG.UI.ToggleLevelingGears()
		end)
	end)
	window.settingsButton = settingsButton

	local rowParent = CreateFrame("Frame", nil, window)
	rowParent:SetSize(WINDOW_WIDTH - 32, ROW_COUNT * ROW_HEIGHT + (ROW_COUNT - 1) * 6)
	rowParent:SetPoint("TOP", buttonRow, "BOTTOM", 0, -14)
	window.rowParent = rowParent

	for i = 1, ROW_COUNT do
		local row = CreateRow(rowParent)
		if i == 1 then
			row:SetPoint("TOPLEFT", 0, 0)
		else
			row:SetPoint("TOPLEFT", rows[i - 1], "BOTTOMLEFT", 0, -6)
		end
		rows[i] = row
	end

	local emptyText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	emptyText:SetPoint("TOPLEFT", rowParent, "TOPLEFT", 0, 0)
	emptyText:SetText("No qualifying upgrades found for this slot right now.")
	emptyText:Hide()
	window.emptyText = emptyText

	local footerText = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	footerText:SetPoint("BOTTOM", 0, 12)
	window.footerText = footerText
end

-- Populates (or re-populates, on Refresh or an auto-retry tick) the window for one slot.
-- `isAutoRefresh` is true only when this call came from the timer below, not a real user action
-- (click, Refresh button) -- distinguishes "keep counting toward the retry cap" from "a fresh
-- interaction resets it."
function SuggestionsUI.Show(slotName, isAutoRefresh)
	if LG.Debug then
		LG.Debug.WriteDebugLog(string.format("SuggestionsUI.Show: called for slot=%s isAutoRefresh=%s",
			tostring(slotName), tostring(isAutoRefresh)), 1)
	end

	EnsureWindow()

	-- Force a known, dead-center position on every single Show() call, not just at first creation.
	-- Real evidence this was needed: the window's own saved debug log shows its anchor point jumping
	-- between CENTER/LEFT/TOP/TOPLEFT across one test session (149/15/29/62 occurrences respectively)
	-- -- the whole window body is drag-enabled (not just a title strip), and with 6 rows packed in
	-- tightly there's very little safe background left to click without nudging the whole thing.
	-- SetClampedToScreen keeps it from fully leaving the screen, but "somewhere on screen" isn't the
	-- same as "somewhere the player is actually looking" -- this is very likely why candidates that
	-- were genuinely found (confirmed in the log) were never actually seen.
	window:ClearAllPoints()
	window:SetPoint("CENTER")

	if autoRefreshTimer then
		autoRefreshTimer:Cancel()
		autoRefreshTimer = nil
	end
	if not isAutoRefresh then
		autoRefreshAttempts = 0
		-- A real user action (click, manual Refresh) -- bump this slot to the front of the
		-- background cache-warming queue too, per direct instruction ("if one is shift clicked
		-- during this phase, the window opens and its search is put to the front, while the others
		-- search in the background").
		if LG.Suggestions.PrioritizeSlot then
			LG.Suggestions.PrioritizeSlot(slotName)
		end
	end
	currentSlotName = slotName

	local selected, skippedUncached, equippedScore, playerContinent, instanceId =
		LG.Suggestions.GetCandidates(slotName)

	window.title:SetText("Suggestions -- " .. slotName)
	window.equippedText:SetText(string.format("Equipped score: %s  |  Continent: %s",
		equippedScore and string.format("%.2f", equippedScore) or "none (empty slot)",
		playerContinent or ("unknown, instanceID=" .. tostring(instanceId))))

	for i, row in ipairs(rows) do
		local candidate = selected[i]
		if candidate then
			row:Show()
			row.icon:SetTexture(GetItemIcon(candidate.itemId))
			local r, g, b = GetQualityColor(candidate.quality)
			row.nameText:SetText(candidate.item.name or ("Item " .. candidate.itemId))
			row.nameText:SetTextColor(r, g, b)
			row.upgradeText:SetText(FormatUpgradeText(candidate.score, equippedScore))
			row.sourceText:SetText(FormatSourceText(candidate))
			row.categoryText:SetText(FormatCategoryText(candidate.categories))

			row.itemLink = "item:" .. candidate.itemId
			row.sourceLine = FormatSourceText(candidate)
			row.categoryLine = FormatCategoryText(candidate.categories)
		else
			row:Hide()
		end
	end

	-- Distinguishes "genuinely checked everything, nothing qualifies" from "still warming up" --
	-- both used to show the identical static "No qualifying upgrades found" text, which reads as a
	-- dead end even when the real answer is "give it a few more seconds." Real UX bug, not just a
	-- wording nitpick: this is very likely why the empty-but-still-caching case kept reading as
	-- broken across multiple live tests.
	if #selected == 0 then
		if skippedUncached > 0 then
			window.emptyText:SetText(string.format(
				"Still loading item data (%d item(s) not cached yet) -- checking again shortly...",
				skippedUncached))
		else
			window.emptyText:SetText("No qualifying upgrades found for this slot right now.")
		end
		window.emptyText:Show()
	else
		window.emptyText:Hide()
	end

	if skippedUncached > 0 then
		if autoRefreshAttempts < AUTO_REFRESH_MAX_ATTEMPTS then
			window.footerText:SetText(string.format(
				"%d item(s) not yet cached -- auto-refreshing (attempt %d/%d)...",
				skippedUncached, autoRefreshAttempts + 1, AUTO_REFRESH_MAX_ATTEMPTS))
			autoRefreshAttempts = autoRefreshAttempts + 1
			autoRefreshTimer = C_Timer.NewTimer(AUTO_REFRESH_INTERVAL, function()
				autoRefreshTimer = nil
				if window:IsShown() and currentSlotName == slotName then
					SafeCall(function()
						SuggestionsUI.Show(slotName, true)
					end)
				end
			end)
		else
			window.footerText:SetText(skippedUncached .. " item(s) still not cached -- click Refresh to try again.")
		end
		window.footerText:Show()
	else
		window.footerText:Hide()
	end

	-- 154 = summed fixed chrome above/below the row list (title, equipped-score line, button row,
	-- their gaps, and the footer/bottom margin) -- a reasoned estimate from each element's own known
	-- size and gap, not a single guessed constant; first live open should still confirm no clipping,
	-- per this project's standing UI-overlap rule (bug #25/#26/#41's own history).
	local visibleRowCount = math.min(#selected, ROW_COUNT)
	local contentHeight = (visibleRowCount > 0) and (visibleRowCount * ROW_HEIGHT + (visibleRowCount - 1) * 6) or 20
	window:SetHeight(154 + contentHeight)

	window:Show()

	if LG.Debug then
		LG.Debug.WriteDebugLog(string.format(
			"SuggestionsUI.Show: window shown=%s width=%s height=%s point=%s strata=%s frameLevel=%s alpha=%s",
			tostring(window:IsShown()), tostring(window:GetWidth()), tostring(window:GetHeight()),
			tostring(select(1, window:GetPoint())), tostring(window:GetFrameStrata()),
			tostring(window:GetFrameLevel()), tostring(window:GetAlpha())), 1)

		-- Objective geometry/visibility check for the first row -- rather than infer from a verbal
		-- description, read the actual resolved screen coordinates and ancestor-aware visibility
		-- directly. GetLeft/GetTop return nil if the anchor chain never actually resolved (as
		-- opposed to resolving to 0 or some valid number) -- that distinction matters here.
		local firstRow = rows[1]
		if firstRow then
			LG.Debug.WriteDebugLog(string.format(
				"SuggestionsUI.Show: row1 isShown=%s isVisible=%s left=%s top=%s width=%s height=%s " ..
				"frameLevel=%s frameStrata=%s alpha=%s nameText=%q",
				tostring(firstRow:IsShown()), tostring(firstRow:IsVisible()),
				tostring(firstRow:GetLeft()), tostring(firstRow:GetTop()),
				tostring(firstRow:GetWidth()), tostring(firstRow:GetHeight()),
				tostring(firstRow:GetFrameLevel()), tostring(firstRow:GetFrameStrata()),
				tostring(firstRow:GetAlpha()), tostring(firstRow.nameText and firstRow.nameText:GetText())), 1)
		end
	end
end

function SuggestionsUI.Hide()
	if autoRefreshTimer then
		autoRefreshTimer:Cancel()
		autoRefreshTimer = nil
	end
	if window then
		window:Hide()
	end
end
