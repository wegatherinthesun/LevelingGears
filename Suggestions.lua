-- Leveling Gears -- Suggestions.lua
-- The upgrade-recommendation engine: turns the pipeline's baked Items/Sources/Quests/BySlot data
-- (pipeline/output/*.lua -- see LevelingGears.toc's own load-wiring note) into a per-slot list of up
-- to Suggestions.MAX_CANDIDATES real upgrade candidates. Pure data/query logic -- no UI widgets are
-- touched here, matching UI.lua/Weights.lua's existing split (see DESIGN.md). Not yet wired into any
-- window; verify via the `/lgs suggest <slot>` debug command until `ROADMAP.md`'s `0.6` recommendation
-- window exists to call this for real.

local _, LG = ...
LG.Suggestions = LG.Suggestions or {}
local Suggestions = LG.Suggestions

local PrintChat = LG.Debug.PrintChat
local SafeCall = LG.Debug.SafeCall

-- One reserved slot per qualifying category (crafted, BOE/AH, current-zone quest, nearby-zone
-- quest -- dungeon blue deferred, see ROADMAP.md's known gap on instance detection), filled by that
-- category's single best scorer; remaining slots up to this count are filled by pure score across
-- the whole remaining pool. Per direct instruction.
Suggestions.MAX_CANDIDATES = 6

-- cmangos classic Map.dbc numbering -> continent bucket (see ROADMAP.md's DATA section). NOT yet
-- confirmed live against UnitPosition's own instanceID return on THIS client -- ROADMAP.md flags
-- this explicitly ("confirm this live in game before trusting it, not an assumed mapping"). The
-- debug command below prints the raw instanceID read every time so this can be checked against a
-- known current continent.
local MAP_ID_CONTINENT = {
	[0] = "EASTERN_KINGDOMS",
	[1] = "KALIMDOR",
	[530] = "OUTLAND",
	[571] = "NORTHREND",
}

-- Distance thresholds, in the raw world-position units UnitPosition and the pipeline's quest
-- pickup x/y both use -- only meaningful between two points already confirmed to share a continent.
-- The pipeline's Quests.pickup.zone is only a 4-value continent id, not a per-zone id (ROADMAP.md's
-- known gap), so "current zone" vs. "nearby zone" can't be matched by zone id at all -- distance from
-- the player's own live position is used instead. Rough starting points, not researched against real
-- zone sizes -- expect to retune after live testing.
local LOCAL_ZONE_DISTANCE = 400
local NEARBY_ZONE_DISTANCE = 1500

-- An opposite-continent quest source needs to beat the best already-available same-continent
-- candidate by this fraction to be shown at all -- scaled by how deep the local candidate pool
-- already is, not a fixed number: "if the pool is thin, trigger it easier; if everything we need is
-- nearby, why bother unless it's incredible" (direct instruction). At FAR_CONTINENT_RICH_POOL_COUNT
-- or more same-continent candidates, the full base margin applies; with zero, the margin is zero (any
-- real upgrade qualifies, since there's nothing local to prefer instead).
local FAR_CONTINENT_BASE_MARGIN = 0.5
local FAR_CONTINENT_RICH_POOL_COUNT = 4

-- Category quota priority order. "dungeon" is listed but never actually assigned yet -- no installed
-- data can classify a drop as dungeon-vs-overworld today (see ROADMAP.md's known gap on this) -- kept
-- here so wiring it in later is a one-line addition to ClassifyCandidateCategories, not a new quota
-- loop.
local QUOTA_CATEGORIES = { "dungeon", "crafted", "boe", "quest-local", "quest-nearby" }

-- ===================== Continent / position =====================

-- Reads the player's live world position and continent bucket. Return order matches UnitPosition's
-- own signature (y, x, z, instanceID) -- confirmed via a real installed addon's usage (Questie's
-- bundled HereBeDragons-2.0.lua's GetPlayerWorldPosition), not assumed.
function Suggestions.GetPlayerLocation()
	local y, x, _, instanceId = UnitPosition("player")
	return MAP_ID_CONTINENT[instanceId], x, y, instanceId
end

-- Classifies a quest's location relative to the player: "local" (within LOCAL_ZONE_DISTANCE),
-- "nearby" (within NEARBY_ZONE_DISTANCE, same continent), "far-same-continent" (same continent but
-- beyond both thresholds -- not a guaranteed quota category, still eligible for the score-fill pool),
-- "far" (a different continent entirely), or nil if there's not enough location data to say.
local function ClassifyQuestLocation(playerContinent, playerX, playerY, quest)
	if not quest then
		return nil
	end
	local location = quest.pickup or quest.turnin
	if not location or not location.zone then
		return nil
	end
	local questContinent = MAP_ID_CONTINENT[location.zone]
	if not questContinent or questContinent ~= playerContinent then
		return "far"
	end
	if not location.x or not location.y or not playerX or not playerY then
		return "nearby" -- same continent, no coordinates to refine further
	end
	local dx, dy = location.x - playerX, location.y - playerY
	local distance = math.sqrt(dx * dx + dy * dy)
	if distance <= LOCAL_ZONE_DISTANCE then
		return "local"
	elseif distance <= NEARBY_ZONE_DISTANCE then
		return "nearby"
	end
	return "far-same-continent"
end

-- ===================== Class filtering =====================

-- `AllowableClass`-style bitmask (bit N-1 = classId N, e.g. Warrior=1, Paladin=2, Hunter=4...),
-- confirmed against a real installed addon's own classId<->bitmask handling (Questie's
-- QuestiePlayer.lua: `2 ^ (classId - 1)` for the player's own flag, `mask % (flag * 2) >= flag` to
-- test membership) -- pure Lua 5.1 arithmetic, no `bit` library dependency needed. -1 (no
-- restriction, seen on real pipeline data) naturally passes this test for any classFlag, so it needs
-- no special case.
local function GetPlayerClassFlag()
	local _, _, classId = UnitClass("player")
	return 2 ^ (classId - 1)
end

local function ItemAllowsClass(classMask, classFlag)
	if not classMask then
		return true
	end
	return classMask % (classFlag * 2) >= classFlag
end

-- classMask alone doesn't exclude off-armor-type items -- a Shaman's AllowableClass generally
-- permits both Mail and Leather (they can wear either), but at level 59 a Leather item is essentially
-- never the right suggestion over Mail. This is a real, direct lever on how much gets scanned: most
-- of an armor slot's pool is types the class would never actually want, and this check is free
-- (string compare) compared to the GetItemInfo call every surviving candidate still costs. Mail
-- unlocks at level 40 in TBC; below that, Mail-capable classes use Leather instead -- confirmed TBC
-- game rule, not a guess.
--
-- Checked pipeline/output/Items.lua directly rather than assume: armorType isn't only
-- Cloth/Leather/Mail/Plate -- it's also "Miscellaneous" (rings, necks, trinkets, cloaks), "Shield",
-- and "Idol"/"Libram"/"Totem" (relics), none of which are governed by class armor-proficiency at
-- all. PROFICIENCY_ARMOR_TYPES restricts this filter to only the four real proficiency types --
-- without it, every ring/neck/trinket/cloak/shield/relic candidate was being wrongly excluded
-- entirely (real bug, not a guess this time either).
local ARMOR_TYPE_BY_CLASS = {
	WARRIOR = "Plate", PALADIN = "Plate",
	HUNTER = "Mail", SHAMAN = "Mail",
	ROGUE = "Leather", DRUID = "Leather",
	MAGE = "Cloth", PRIEST = "Cloth", WARLOCK = "Cloth",
}
local MAIL_UNLOCK_LEVEL = 40
local PROFICIENCY_ARMOR_TYPES = { Cloth = true, Leather = true, Mail = true, Plate = true }

local function GetPreferredArmorType(class, playerLevel)
	local armorType = ARMOR_TYPE_BY_CLASS[class]
	if armorType == "Mail" and playerLevel < MAIL_UNLOCK_LEVEL then
		return "Leather"
	end
	return armorType
end

local function ItemMatchesArmorType(itemArmorType, preferredArmorType)
	if not itemArmorType or not preferredArmorType then
		return true
	end
	if not PROFICIENCY_ARMOR_TYPES[itemArmorType] then
		return true
	end
	return itemArmorType == preferredArmorType
end

-- ===================== Item stats (async-cache-aware) =====================

local pendingItemInfoRequests = {}
local itemInfoWatcher = nil

local function EnsureItemInfoWatcher()
	if itemInfoWatcher then
		return
	end
	itemInfoWatcher = CreateFrame("Frame")
	itemInfoWatcher:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	itemInfoWatcher:SetScript("OnEvent", function(_, _, itemId)
		pendingItemInfoRequests[itemId] = nil
	end)
end

-- Returns (itemStats, itemString) if the item is already cached client-side, or nil if not --
-- GetItemStats/GetItemInfo are both async for anything the client hasn't seen yet (CONVENTIONS.md's
-- Technical notes). A bare "item:<id>" string is enough for both calls -- no real item link needed.
-- The single GetItemInfo call below both checks AND (on a miss) queues the client's own fetch in one
-- shot -- calling it a second time on a miss was pure redundant API traffic, not a separate trigger;
-- GET_ITEM_INFO_RECEIVED (watched above) clears our own pending-request bookkeeping once it lands.
-- This is a pull-based debug query today, not yet a push-based UI that redraws the moment data lands
-- (0.6's recommendation window will need that, not built here).
--
-- Cache check MUST use GetItemInfo's name return, not GetItemStats' emptiness: GetItemStats
-- legitimately returns an EMPTY (not nil) table for a fully-cached plain armor piece with no bonus
-- stat mods -- CONVENTIONS.md/bug #23/#43 already document this and built ScanItemArmorValue's
-- hidden-tooltip fallback specifically for it. Treating that empty table as "not cached yet" (an
-- earlier version of this function did) silently discarded every such item -- a huge fraction of
-- leveling gear -- from the candidate pool entirely, well before ComputeScore ever got a chance to
-- apply that same armor fallback.
-- Returns (itemStats, itemString, quality) -- quality comes from GetItemInfo (the pipeline's own
-- Items table doesn't carry it at all, see ROADMAP.md's DATA section's declared shape: name/slot/
-- subtype/armorType/reqLevel/classMask, no quality field), captured here since GetItemInfo is
-- already being called for the cache check anyway.
local function GetCandidateItemStats(itemId)
	local itemString = "item:" .. itemId
	local cachedName, _, quality = GetItemInfo(itemString)
	if not cachedName then
		if not pendingItemInfoRequests[itemId] then
			EnsureItemInfoWatcher()
			pendingItemInfoRequests[itemId] = true
		end
		return nil
	end
	return GetItemStats(itemString) or {}, itemString, quality
end

-- ===================== Candidate gathering =====================

-- Classifies one candidate item's Sources entries into the set of quota categories it qualifies
-- for. An item can qualify for more than one (e.g. both a quest reward and a vendor stock) --
-- QUOTA_CATEGORIES' priority order decides which one it actually fills if more than one is open.
local function ClassifyCandidateCategories(sources, playerContinent, playerX, playerY)
	local categories = {}
	for _, source in ipairs(sources or {}) do
		if source.kind == "craft" then
			categories["crafted"] = true
		elseif source.kind == "boe" then
			categories["boe"] = true
		elseif source.kind == "quest" and source.questId then
			local quest = LevelingGearsData_Quests and LevelingGearsData_Quests[source.questId]
			local location = ClassifyQuestLocation(playerContinent, playerX, playerY, quest)
			if location == "local" then
				categories["quest-local"] = true
			elseif location == "nearby" then
				categories["quest-nearby"] = true
			elseif location == "far" then
				categories["quest-far"] = true
			end
		end
		-- "dungeon" intentionally never set here -- see ROADMAP.md's known gap; kind="drop" alone
		-- can't say whether a creature was a dungeon boss or an overworld mob yet.
	end
	return categories
end

-- Builds the full eligible-upgrade candidate pool for one slot: every BySlot item that's usable by
-- this class, is currently equippable and reasonably close to the player's own level, scores above
-- the equipped item's baseline (the hard no-downgrades rule), and has cached stats available right
-- now. Returns the pool (array of candidate tables) plus a count of items skipped because their
-- stats aren't cached yet (informational only -- see GetCandidateItemStats's note).
-- Returns (pool, skippedUncached, totalItems, classEligible, downgradesRejected) -- the extra three
-- counts exist purely for /lgs suggest's debug-log breakdown (see PrintSuggestions), since "0
-- candidates" alone doesn't say whether that's a class filter, the no-downgrade rule, or an
-- uncached-items problem -- see bug where GetItemStats' empty-but-cached table was misread as
-- "not cached" and silently dropped a huge fraction of real candidates (fixed; kept these counters
-- so a similar future problem shows up in the log immediately instead of needing another live guess).
--
-- Level filter (added after a live report: a level 59 character's Head slot alone had 625
-- class-eligible items, most of them ancient low-level gear that could never plausibly beat the
-- equipped score AND that the client has never cached -- burning a GetItemInfo call on every one of
-- them was the real reason "808 items not cached" showed up, not a caching bug).
--
-- LEVEL_WINDOW_ABOVE exists on real evidence, not a guess: an original hard `reqLevel <= playerLevel`
-- cap wiped out 8 of 9 tested slots to zero candidates on a live level 59 character -- almost
-- certainly because a lot of the best early-Outland dungeon blues require level 60, exactly one level
-- past this character. A leveling-gear addon should still surface "grab this very soon" items, not
-- just "wear this literally right now" ones -- the UI doesn't yet visually distinguish the two
-- (SuggestionsUI.lua doesn't show reqLevel at all yet), which is a real follow-up, not resolved here.
-- LEVEL_WINDOW_BELOW tightened from 15 to 3 per direct instruction, to cut scan volume as
-- aggressively as the level window can bear -- a much narrower band than the original starting
-- point, on top of LEVEL_WINDOW_ABOVE's unchanged +3 for "about to be equippable" items.
local LEVEL_WINDOW_BELOW = 3
local LEVEL_WINDOW_ABOVE = 3

local function BuildCandidatePool(slotName, equippedScore, classFlag, playerLevel, playerClass, playerContinent, playerX, playerY)
	local preferredArmorType = GetPreferredArmorType(playerClass, playerLevel)
	local itemIds = LevelingGearsData_BySlot and LevelingGearsData_BySlot[slotName]
	if not itemIds then
		return {}, 0, 0, 0, 0
	end

	local characterState = LG.Settings.GetCharacterState()
	local weights = characterState and characterState.weights

	local pool = {}
	local skippedUncached = 0
	local classEligible = 0
	local downgradesRejected = 0

	for _, itemId in ipairs(itemIds) do
		local item = LevelingGearsData_Items and LevelingGearsData_Items[itemId]
		-- reqLevel=0 means "no real requirement" in the pipeline data (confirmed: 4,313 real items
		-- carry it), same as nil -- 0 is truthy in Lua, so without this check every one of them was
		-- being evaluated as a literal level-0 requirement and excluded for any player above level 3.
		local levelOk = item and (not item.reqLevel or item.reqLevel == 0 or
			(item.reqLevel <= playerLevel + LEVEL_WINDOW_ABOVE and item.reqLevel >= playerLevel - LEVEL_WINDOW_BELOW))
		local armorOk = item and ItemMatchesArmorType(item.armorType, preferredArmorType)
		if item and levelOk and armorOk and ItemAllowsClass(item.classMask, classFlag) then
			classEligible = classEligible + 1
			local itemStats, itemString, quality = GetCandidateItemStats(itemId)
			if itemStats then
				local score = LG.Scoring:ScoreEquippedItem(itemStats, weights, itemString)
				if not equippedScore or score > equippedScore then
					local sources = LevelingGearsData_Sources and LevelingGearsData_Sources[itemId]
					table.insert(pool, {
						itemId = itemId,
						item = item,
						quality = quality,
						sources = sources,
						score = score,
						categories = ClassifyCandidateCategories(sources, playerContinent, playerX, playerY),
					})
				else
					downgradesRejected = downgradesRejected + 1
				end
			else
				skippedUncached = skippedUncached + 1
			end
		end
	end

	return pool, skippedUncached, #itemIds, classEligible, downgradesRejected
end

-- The "mix": one reserved slot per qualifying category (best scorer in that category), then the
-- rest filled by pure score across whatever's left -- guarantees diversity without letting it
-- dominate the list. Opposite-continent ("quest-far") candidates are excluded from both the quota
-- and the fill unless they clear the dynamic margin against the best same-continent candidate found.
local function SelectCandidates(pool)
	local assigned = {}
	local selected = {}

	-- Sort once, descending by score -- both the quota pass and the fill pass want "best first".
	table.sort(pool, function(a, b) return a.score > b.score end)

	local bestLocalScore = nil
	local localPoolCount = 0
	for _, candidate in ipairs(pool) do
		if not candidate.categories["quest-far"] then
			localPoolCount = localPoolCount + 1
			if not bestLocalScore or candidate.score > bestLocalScore then
				bestLocalScore = candidate.score
			end
		end
	end

	local farMargin = FAR_CONTINENT_BASE_MARGIN * math.min(localPoolCount / FAR_CONTINENT_RICH_POOL_COUNT, 1)

	local function PassesFarContinentGate(candidate)
		if not candidate.categories["quest-far"] then
			return true
		end
		if not bestLocalScore then
			return true -- nothing local at all -- any real upgrade qualifies
		end
		return candidate.score > bestLocalScore * (1 + farMargin)
	end

	-- Quota pass: for each category in priority order, take the best unassigned, gate-passing
	-- candidate that qualifies for it.
	for _, category in ipairs(QUOTA_CATEGORIES) do
		if #selected >= Suggestions.MAX_CANDIDATES then
			break
		end
		for _, candidate in ipairs(pool) do
			if not assigned[candidate.itemId] and candidate.categories[category] and PassesFarContinentGate(candidate) then
				assigned[candidate.itemId] = true
				table.insert(selected, candidate)
				break
			end
		end
	end

	-- Fill pass: pure score across whatever's left, still subject to the far-continent gate.
	for _, candidate in ipairs(pool) do
		if #selected >= Suggestions.MAX_CANDIDATES then
			break
		end
		if not assigned[candidate.itemId] and PassesFarContinentGate(candidate) then
			assigned[candidate.itemId] = true
			table.insert(selected, candidate)
		end
	end

	return selected
end

-- ===================== Persistent suggestion memory =====================
--
-- Once a real candidate is found for a slot, its itemId is remembered in the character's own
-- SavedVariables (not just the client's in-session GetItemInfo cache, which this session's cold
-- start keeps re-proving isn't enough on its own) -- per direct instruction: "any upgrade you find,
-- save the info about it... so you don't have to check as often." Only the itemId list is persisted
-- -- Items/Sources/Quests are already baked pipeline data, no need to duplicate any of it -- and a
-- remembered item is always re-verified live (current score vs. the CURRENT equipped item and
-- CURRENT weights) before ever being shown again, never trusted blindly: gear changes, weight
-- changes, and level-ups can all make a once-good suggestion stale.
local function GetSuggestionMemory(slotName)
	local characterState = LG.Settings.GetCharacterState()
	characterState.suggestionMemory = characterState.suggestionMemory or {}
	characterState.suggestionMemory[slotName] = characterState.suggestionMemory[slotName] or {}
	return characterState.suggestionMemory[slotName]
end

local function RememberCandidates(slotName, selected)
	local memory = GetSuggestionMemory(slotName)
	for i = #memory, 1, -1 do
		memory[i] = nil
	end
	for _, candidate in ipairs(selected) do
		table.insert(memory, candidate.itemId)
	end
end

-- Used as a fallback only when this session's fresh live pool comes up empty purely because the
-- client's own item cache hasn't caught back up yet -- re-scores every remembered itemId against
-- the current equipped item/weights right now, so a stale or no-longer-valid memory never shows.
local function GetRememberedCandidates(slotName, equippedScore, weights, playerContinent, playerX, playerY)
	local memory = GetSuggestionMemory(slotName)
	local remembered = {}
	for _, itemId in ipairs(memory) do
		local item = LevelingGearsData_Items and LevelingGearsData_Items[itemId]
		if item then
			local itemStats, itemString = GetCandidateItemStats(itemId)
			if itemStats then
				local score = LG.Scoring:ScoreEquippedItem(itemStats, weights, itemString)
				if not equippedScore or score > equippedScore then
					local sources = LevelingGearsData_Sources and LevelingGearsData_Sources[itemId]
					table.insert(remembered, {
						itemId = itemId,
						item = item,
						sources = sources,
						score = score,
						categories = ClassifyCandidateCategories(sources, playerContinent, playerX, playerY),
					})
				end
			end
		end
	end
	table.sort(remembered, function(a, b) return a.score > b.score end)
	return remembered
end

-- Full per-slot query: the no-downgrades baseline, the candidate pool, and the final up-to-6
-- selection, all in one call. Returns (selected, skippedUncached, equippedScore, playerContinent,
-- instanceId, totalItems, classEligible, downgradesRejected) -- callers (the debug command today,
-- `0.6`'s recommendation window later) decide how to present it; the last three exist for
-- diagnostics, see BuildCandidatePool's own note.
function Suggestions.GetCandidates(slotName)
	local slotOk, slotId = pcall(GetInventorySlotInfo, slotName)
	if not slotOk or not slotId then
		return {}, 0, nil, nil, nil, 0, 0, 0
	end

	local equippedScore = LG.GearEvaluation.GetEquippedItemScore(slotId)
	local classFlag = GetPlayerClassFlag()
	local _, playerClass = UnitClass("player")
	local playerLevel = UnitLevel("player")
	local playerContinent, playerX, playerY, instanceId = Suggestions.GetPlayerLocation()

	local pool, skippedUncached, totalItems, classEligible, downgradesRejected =
		BuildCandidatePool(slotName, equippedScore, classFlag, playerLevel, playerClass, playerContinent, playerX, playerY)
	local selected = SelectCandidates(pool)

	local usedMemory = false
	if #selected > 0 then
		RememberCandidates(slotName, selected)
	elseif skippedUncached > 0 then
		local characterState = LG.Settings.GetCharacterState()
		local remembered = GetRememberedCandidates(slotName, equippedScore, characterState and characterState.weights,
			playerContinent, playerX, playerY)
		if #remembered > 0 then
			selected = remembered
			usedMemory = true
		end
	end

	-- Logged here (not just by the /lgs suggest text command) so EVERY caller -- including
	-- SuggestionsUI's window -- leaves a diagnostic trail, not just the debug-bench path.
	if LG.Debug then
		LG.Debug.WriteDebugLog(string.format(
			"Suggestions.GetCandidates: slot=%s totalItems=%d classEligible=%d downgradesRejected=%d " ..
			"skippedUncached=%d selected=%d usedMemory=%s equippedScore=%s continent=%s instanceId=%s",
			slotName, totalItems, classEligible, downgradesRejected, skippedUncached, #selected,
			tostring(usedMemory), tostring(equippedScore), tostring(playerContinent), tostring(instanceId)), 1)
	end

	return selected, skippedUncached, equippedScore, playerContinent, instanceId, totalItems, classEligible, downgradesRejected
end

-- ===================== Debug output =====================

-- Case-insensitive slot-name resolution against GearEvaluation's own canonical 17-slot list, so
-- `/lgs suggest handsslot` and `/lgs suggest HandsSlot` both work.
local function ResolveSlotName(rawName)
	local lowered = rawName and rawName:lower()
	for _, slotDefinition in ipairs(LG.GearEvaluation.SLOT_DEFINITIONS) do
		if slotDefinition.slotName:lower() == lowered then
			return slotDefinition.slotName
		end
	end
	return nil
end

local function DescribeCandidate(candidate)
	local categoryList = {}
	for category in pairs(candidate.categories) do
		table.insert(categoryList, category)
	end
	table.sort(categoryList)
	local categoryText = #categoryList > 0 and table.concat(categoryList, ", ") or "no category tag"

	local sourceText = "no known source"
	local bestSource = candidate.sources and candidate.sources[1]
	if bestSource then
		if bestSource.kind == "drop" then
			sourceText = string.format("drop: npc %s, %.0f%% chance, obtain ~lvl %s",
				tostring(bestSource.npcId), (bestSource.dropRate or 0) * 100, tostring(bestSource.obtainLevel))
		elseif bestSource.kind == "quest" then
			sourceText = string.format("quest %s, obtain ~lvl %s", tostring(bestSource.questId), tostring(bestSource.obtainLevel))
		elseif bestSource.kind == "craft" then
			sourceText = string.format("craft: recipe %s, obtain ~lvl %s", tostring(bestSource.recipeId), tostring(bestSource.obtainLevel))
		elseif bestSource.kind == "vendor" then
			sourceText = string.format("vendor: npc %s, %s copper", tostring(bestSource.npcId), tostring(bestSource.cost))
		elseif bestSource.kind == "boe" then
			sourceText = string.format("BOE (Auction House), obtain ~lvl %s", tostring(bestSource.obtainLevel))
		end
	end

	return string.format("[%.2f] %s (%s) -- %s", candidate.score, candidate.item.name or ("item " .. candidate.itemId),
		categoryText, sourceText)
end

-- `/lgs suggest <slot>` -- debug bench for this engine until 0.6's recommendation window exists to
-- call Suggestions.GetCandidates for real. Prints the raw continent/instanceId read too, so the
-- MAP_ID_CONTINENT mapping's real-world accuracy can be confirmed live (see this file's own note).
function Suggestions.PrintSuggestions(rawSlotName)
	if not LevelingGearsData_BySlot then
		PrintChat("Pipeline data isn't loaded -- run pipeline/big_data.py --build-database and check LevelingGears.toc's data-file lines.")
		return
	end

	local slotName = ResolveSlotName(rawSlotName)
	if not slotName then
		PrintChat("Unknown slot '" .. tostring(rawSlotName) .. "'. Try one of: " ..
			table.concat((function()
				local names = {}
				for _, slotDefinition in ipairs(LG.GearEvaluation.SLOT_DEFINITIONS) do
					table.insert(names, slotDefinition.slotName)
				end
				return names
			end)(), ", "))
		return
	end

	-- Diagnostic breakdown is logged inside GetCandidates itself now (every caller gets it, not just
	-- this text command) -- see that function's own note.
	local selected, skippedUncached, equippedScore, playerContinent, instanceId = Suggestions.GetCandidates(slotName)

	PrintChat(string.format("Suggestions for %s -- equipped score: %s, continent: %s (instanceID=%s), %d candidate(s), %d skipped (not yet cached)",
		slotName, equippedScore and string.format("%.2f", equippedScore) or "none",
		playerContinent or "unknown", tostring(instanceId), #selected, skippedUncached))

	if #selected == 0 then
		PrintChat("No qualifying upgrades found for this slot right now.")
		return
	end

	for index, candidate in ipairs(selected) do
		PrintChat(index .. ". " .. DescribeCandidate(candidate))
	end

	if skippedUncached > 0 then
		PrintChat(skippedUncached .. " item(s) skipped because their stats aren't cached yet -- run this command again in a few seconds to pick them up.")
	end
end

-- ===================== Background pre-fetch (cache warmer) =====================
--
-- What actually makes a slot's window feel instant on click: GetCandidateItemStats' GetItemInfo
-- calls are what warm the client's own item-info cache, and that cache is what GetCandidates' speed
-- depends on -- there's no separate results cache to maintain here, just the client's native one.
-- Walking all 17 slots once in the background (one slot per tick, not all at once) means most of a
-- slot's items are very likely already resolved by the time a player actually opens it, instead of
-- starting the wait cold at click-time. Per direct instruction from the very start of this feature:
-- "we will not call the data on frame, but on startup, continent switches, equipping a piece of gear
-- (unless it has been equipped before), spec changes and level ups... Get all suggestions for one
-- before moving onto the next... This will be less resource intensive than spikes."
local backgroundQueue = {}
local backgroundQueueSet = {}
local backgroundTicker = nil

local BACKGROUND_QUEUE_INTERVAL = 1.5

local function ProcessNextBackgroundSlot()
	local slotName = table.remove(backgroundQueue, 1)
	if not slotName then
		if backgroundTicker then
			backgroundTicker:Cancel()
			backgroundTicker = nil
		end
		return
	end
	backgroundQueueSet[slotName] = nil
	-- Return value discarded on purpose -- this call's only job here is its side effect (warming
	-- GetItemInfo's cache for this slot's item pool). A real caller (SuggestionsUI) gets the actual
	-- result later, cheaply, once this has already run.
	Suggestions.GetCandidates(slotName)
end

local function EnsureBackgroundTicker()
	if not backgroundTicker then
		backgroundTicker = C_Timer.NewTicker(BACKGROUND_QUEUE_INTERVAL, function()
			SafeCall(ProcessNextBackgroundSlot)
		end)
	end
end

-- Rebuilds the queue to all 17 slots and (re)starts the ticker -- called on the tracked trigger
-- events below. Re-running this on a trigger that fires again mid-pass just restarts from a full
-- 17-slot queue -- simple and correct, if slightly wasteful on back-to-back triggers, which is
-- acceptable given how infrequently these actually fire in real play.
function Suggestions.RefreshAllSlotsInBackground()
	for i = #backgroundQueue, 1, -1 do
		backgroundQueue[i] = nil
	end
	for key in pairs(backgroundQueueSet) do
		backgroundQueueSet[key] = nil
	end
	for _, slotDefinition in ipairs(LG.GearEvaluation.SLOT_DEFINITIONS) do
		table.insert(backgroundQueue, slotDefinition.slotName)
		backgroundQueueSet[slotDefinition.slotName] = true
	end
	EnsureBackgroundTicker()
end

-- Moves a slot to the very front of the queue so it's the next one the ticker processes -- used
-- when the player opens that slot's window before the background pass reaches it naturally on its
-- own (SuggestionsUI.Show calls this). The window's own GetCandidates call already runs immediately
-- regardless -- this just means an in-progress background pass doesn't keep that slot waiting
-- behind everything else for its own next warm-up tick.
function Suggestions.PrioritizeSlot(slotName)
	for i, name in ipairs(backgroundQueue) do
		if name == slotName then
			table.remove(backgroundQueue, i)
			break
		end
	end
	table.insert(backgroundQueue, 1, slotName)
	backgroundQueueSet[slotName] = true
	EnsureBackgroundTicker()
end

-- ===================== Trigger events =====================

local lastKnownContinent = nil
-- Tracked SEPARATELY from lastKnownContinent, deliberately. The old code used
-- `lastKnownContinent == nil` to mean "first check of the session", but nil is also what
-- GetPlayerLocation returns for ANY instance (no MAP_ID_CONTINENT entry for an instance's map id).
-- Overloading nil that way meant every dungeon left the state permanently looking like "first
-- check", so every later loading screen re-triggered a full 17-slot rescan. See bug notes below.
local hasRunInitialScan = false

-- Does this character already have a stored suggestion record? Checked once on login/reload to
-- decide whether the initial scan is needed at all: an intact record means no rescan, a missing one
-- (brand-new character, or a record lost at some point) rebuilds. Deliberately NOT re-checked
-- mid-session -- per direct instruction, a record lost while logged in rebuilds on the next relog,
-- not immediately.
local function HasSuggestionRecord()
	local characterState = LG.Settings.GetCharacterState()
	local memory = characterState and characterState.suggestionMemory
	return memory ~= nil and next(memory) ~= nil
end

-- "Equipping a piece of gear (unless it has been equipped before)" -- gates the equip-change
-- trigger so swapping between two already-owned items (e.g. toggling a PvP trinket) doesn't restart
-- the whole background pass every time. Persisted per character (Settings.lua's characterState),
-- same storage pattern as weights/specOverride.
local function HasNewlyEquippedItem()
	local characterState = LG.Settings.GetCharacterState()
	characterState.seenEquippedItemIds = characterState.seenEquippedItemIds or {}
	local seen = characterState.seenEquippedItemIds

	local foundNew = false
	for _, slotDefinition in ipairs(LG.GearEvaluation.SLOT_DEFINITIONS) do
		local slotOk, slotId = pcall(GetInventorySlotInfo, slotDefinition.slotName)
		if slotOk and slotId then
			local itemId = GetInventoryItemID("player", slotId)
			if itemId and not seen[itemId] then
				seen[itemId] = true
				foundNew = true
			end
		end
	end
	return foundNew
end

local triggerFrame = CreateFrame("Frame", nil, UIParent)
triggerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
triggerFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
triggerFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
triggerFrame:RegisterEvent("PLAYER_LEVEL_UP")
triggerFrame:SetScript("OnEvent", function(_, event)
	SafeCall(function()
		if event == "PLAYER_ENTERING_WORLD" then
			-- Fires on login/reload AND every loading screen (zone change, instance entry/exit,
			-- release, summon) -- not just a continent switch.
			local continent = Suggestions.GetPlayerLocation()

			-- Instances have no MAP_ID_CONTINENT entry, so GetPlayerLocation returns nil for them.
			-- Ignore those loading screens entirely and leave lastKnownContinent untouched: the
			-- player's gear needs did not change because they zoned into a dungeon. Treating nil as
			-- a continent change is what caused a full 17-slot rescan on every instance entry AND
			-- exit AND every loading screen in between -- the real cause of the "script ran too
			-- long" errors, which were a symptom of scanning when we never needed to scan at all.
			if continent == nil then
				return
			end

			-- First real (non-instance) check of the session: this is the login/reload case. Only
			-- scan if there's no stored record to work from.
			if not hasRunInitialScan then
				hasRunInitialScan = true
				lastKnownContinent = continent
				if not HasSuggestionRecord() then
					Suggestions.RefreshAllSlotsInBackground()
				end
				return
			end

			-- After that, only a genuine continent change justifies a full rescan.
			if continent ~= lastKnownContinent then
				lastKnownContinent = continent
				Suggestions.RefreshAllSlotsInBackground()
			end
			return
		end
		if event == "PLAYER_EQUIPMENT_CHANGED" then
			if HasNewlyEquippedItem() then
				Suggestions.RefreshAllSlotsInBackground()
			end
			return
		end
		-- CHARACTER_POINTS_CHANGED / PLAYER_LEVEL_UP: always refresh -- either can change which
		-- spec/mode scores every item, and a level-up also shifts the whole level-window filter.
		Suggestions.RefreshAllSlotsInBackground()
	end)
end)
