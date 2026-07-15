-- Leveling Gears -- GearEvaluation.lua
-- Evaluates each equipped item against the character's own average (using the v0.25/0.26 scoring
-- engine and the character's own weights) and draws a thin colored outline around its paperdoll
-- slot button. See CLAUDE.md's roadmap (0.23) and DESIGN.md for the scoring rationale.

local _, LG = ...
LG.GearEvaluation = LG.GearEvaluation or {}
local GearEvaluation = LG.GearEvaluation

local SafeCall = LG.Debug.SafeCall
local WriteDebugLog = LG.Debug.WriteDebugLog
local PrintChat = LG.Debug.PrintChat

-- A small set of Blizzard slot names lets us draw a thin outline around the equipped item buttons.
-- Shirt/Ammo/Tabard are deliberately excluded (not stat-relevant for gearing). RangedSlot also
-- covers class relics (Librams/Idols/Totems) since TBC has no separate relic slot -- that was only
-- added in Wrath -- so those classes' relics are already evaluated for every class through here.
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
	{ slotName = "RangedSlot", buttonName = "CharacterRangedSlot" },
}

local gearOutlineFrames = {}
local scoreClickHookedButtons = {}

-- Bug #30's real fix (per the author, after rejecting the /lgs score slash command as "too
-- complicated"): shift-click an equipped item in the character window to print its score breakdown
-- to chat. HookScript (not SetScript) is required here -- it runs alongside Blizzard's own OnClick
-- handler instead of replacing it, so the native left-click (pick up), ctrl-click (dress up), and
-- shift-click (insert item link in chat) behaviors all stay intact.
--
-- Implemented as shift+LEFT-click, not shift+right-click as literally requested: confirmed against
-- FrameXML's PaperDollItemSlotButton_OnClick that right-click unconditionally calls
-- UseInventoryItem(slotId) regardless of any held modifier, so hooking shift+right-click would also
-- risk firing the item's on-use effect (e.g. a trinket proc) as an unwanted side effect. Left-click
-- already branches on Shift for its own "insert item link in chat" behavior, so shift+left-click is
-- both side-effect-free and reuses a gesture every WoW player already knows.
local function EnsureScoreClickHook(slotButton, slotId)
	if not slotButton or scoreClickHookedButtons[slotButton] then
		return
	end
	scoreClickHookedButtons[slotButton] = true

	slotButton:HookScript("OnClick", function(_, button)
		if button ~= "LeftButton" or not IsShiftKeyDown() then
			return
		end

		local itemLink = GetInventoryItemLink("player", slotId)
		if not itemLink then
			return
		end

		local itemStats = GetItemStats(itemLink)
		if not itemStats or not next(itemStats) then
			WriteDebugLog("EnsureScoreClickHook: GetItemStats returned " ..
				(itemStats and "an empty table" or "nil") .. " for '" .. itemLink .. "'", 1)
			-- T8b (v0.382 test pass): this used to fail silently (only a debug-log line, no chat
			-- message), which looks exactly like "the feature is broken" to a player -- e.g.
			-- shift-clicking a totem, whose only real effect is a passive "Equip:" bonus this addon's
			-- v1 policy deliberately doesn't score (see ROADMAP.md's proc/effect note), just did
			-- nothing visible at all. Now says so explicitly, same wording as /lgs score's message.
			if itemStats then
				PrintChat("This item has no stats this addon can score (only clean numeric stats are counted -- passive \"Equip:\" effects and procs aren't itemized yet).")
			end
			return
		end

		LG.Weights.EnsureWeights()
		local characterState = LG.Settings.GetCharacterState()
		local score, breakdown = LG.Scoring:ScoreEquippedItem(itemStats, characterState and characterState.weights)
		LG.Scoring:PrintBreakdown(itemLink, score, breakdown, LG.Scoring:DescribeCurrentSpec())
	end)
end

-- Score a single equipped slot using the v0.25/0.26 engine and the character's own weights.
-- EnsureWeights seeds any never-set stat from the detected spec's Priorities default, then leaves
-- it alone forever -- so the player's own saved weights (post any hand adjustment) are always the
-- right table to score against here, not the raw Priorities table.
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

	LG.Weights.EnsureWeights()
	local characterState = LG.Settings.GetCharacterState()
	return LG.Scoring:ScoreEquippedItem(itemStats, characterState and characterState.weights)
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
function GearEvaluation.UpdateEquippedGearEvaluation()
	LG.Weights.EnsureWeights()
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
			EnsureScoreClickHook(_G[slotDefinition.buttonName], slotId)
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

local gearEvaluationPending = false

-- The gear evaluation walks every equipped slot and reads item stats, which is too expensive to run
-- synchronously on every single +/- click: doing so caused enough per-click delay that a burst of
-- quick clicks could queue up and fire together, making the weight jump by more than 1 at a time.
-- Debounce it instead: multiple calls within the delay collapse into a single evaluation.
function GearEvaluation.ScheduleGearEvaluation()
	if gearEvaluationPending then
		return
	end
	gearEvaluationPending = true
	C_Timer.After(0.2, function()
		gearEvaluationPending = false
		SafeCall(GearEvaluation.UpdateEquippedGearEvaluation)
	end)
end

-- Keep the gear evaluation current when weights or gear change so the outlines remain meaningful.
-- CHARACTER_POINTS_CHANGED/PLAYER_LEVEL_UP re-trigger it too: a respec or level-up can change the
-- character's detected spec, which changes which Priorities table scores each item.
--
-- Routed through ScheduleGearEvaluation (not a direct SafeCall), same as the weight-adjustment path
-- -- found via real debug-log data (v0.313) that UNIT_INVENTORY_CHANGED can fire dozens of times
-- within the same second during ordinary gameplay (a burst of 61 identical "Gear evaluation" log
-- lines all timestamped the same second was captured live), and every one of those was triggering a
-- full, undebounced 17-slot re-evaluation. This debounce already existed for exactly this class of
-- problem (see bug #20/#21) but was only ever wired to the UI click path, not this event path.
local gearEvaluationFrame = CreateFrame("Frame", nil, UIParent)
gearEvaluationFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
gearEvaluationFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
gearEvaluationFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
gearEvaluationFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
gearEvaluationFrame:RegisterEvent("PLAYER_LEVEL_UP")
gearEvaluationFrame:SetScript("OnEvent", function(_, event, unit)
	if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then
		return
	end
	GearEvaluation.ScheduleGearEvaluation()
end)

-- The Character*Slot buttons this addon outlines belong to Blizzard's paperdoll UI, which this
-- client loads on demand rather than at login (confirmed by GearScoreTBCClassic, an installed
-- addon on this same client, which defers all paperdoll work to CharacterFrame's OnShow for the
-- same reason). Re-run the evaluation once the panel is actually open so the slot buttons exist.
CharacterFrame:HookScript("OnShow", function()
	GearEvaluation.ScheduleGearEvaluation()
end)
