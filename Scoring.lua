-- Leveling Gears -- Scoring.lua (v0.25)
-- ScoreItem() combines Conversions.lua (Layers 1-2) with Priorities.lua (Layer 3) into a single
-- number, plus spec/form detection so the right priority table and AP conversion get picked
-- automatically. See DESIGN.md for the full rationale.

local _, LG = ...
LG.Scoring = LG.Scoring or {}
local Scoring = LG.Scoring

-- Talent tab order per class on this client (index 1/2/3 -> spec key). Matching by tab INDEX
-- rather than a displayed name avoids locale issues entirely (talent tab/talent names are
-- localized text; the tab order itself is not).
local TALENT_TAB_ORDER = {
	WARRIOR = { "arms", "fury", "protection" },
	PALADIN = { "holy", "protection", "retribution" },
	HUNTER = { "beastmastery", "marksmanship", "survival" },
	ROGUE = { "assassination", "combat", "subtlety" },
	PRIEST = { "discipline", "holy", "shadow" },
	SHAMAN = { "elemental", "enhancement", "restoration" },
	MAGE = { "arcane", "fire", "frost" },
	WARLOCK = { "affliction", "demonology", "destruction" },
	DRUID = { "balance", "feral", "restoration" },
}

-- Human-readable labels for the manual spec-override dropdown (v0.38, bug #37) -- kept here rather
-- than guessed from the key itself (e.g. "beastmastery" would title-case wrong) since these are the
-- exact names players expect from Blizzard's own talent UI.
Scoring.SPEC_DISPLAY_NAMES = {
	WARRIOR = { arms = "Arms", fury = "Fury", protection = "Protection" },
	PALADIN = { holy = "Holy", protection = "Protection", retribution = "Retribution" },
	HUNTER = { beastmastery = "Beast Mastery", marksmanship = "Marksmanship", survival = "Survival" },
	ROGUE = { assassination = "Assassination", combat = "Combat", subtlety = "Subtlety" },
	PRIEST = { discipline = "Discipline", holy = "Holy", shadow = "Shadow" },
	SHAMAN = { elemental = "Elemental", enhancement = "Enhancement", restoration = "Restoration" },
	MAGE = { arcane = "Arcane", fire = "Fire", frost = "Frost" },
	WARLOCK = { affliction = "Affliction", demonology = "Demonology", destruction = "Destruction" },
	DRUID = { balance = "Balance", feral = "Feral", restoration = "Restoration" },
}

-- Ordered {key, label} pairs for a class's 3 specs, used to build the manual spec-override dropdown
-- (UI.lua) without duplicating TALENT_TAB_ORDER's class->spec mapping a second time.
function Scoring.GetSpecOptions(class)
	local tabOrder = TALENT_TAB_ORDER[class]
	if not tabOrder then
		return {}
	end
	local names = Scoring.SPEC_DISPLAY_NAMES[class] or {}
	local options = {}
	for _, specKey in ipairs(tabOrder) do
		table.insert(options, { key = specKey, label = names[specKey] or specKey })
	end
	return options
end

-- Blizzard item stats are exposed through token-based keys, so this maps our stat keys to those
-- tokens. Moved here (from Core.lua) since Scoring is now the single owner of raw-item-stat
-- extraction; Core.lua's gear-outline evaluation calls into ScoreEquippedItem instead.
Scoring.itemStatAliases = {
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
	-- Only ever captures BONUS armor (e.g. a shield's "of the Bear"-style suffix) -- a normal
	-- piece's base armor is intrinsic to material/ilvl/slot and isn't an ITEM_MOD_* stat at all.
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

function Scoring.ResolveItemStatValue(itemStats, statKey)
	local aliases = Scoring.itemStatAliases[statKey] or {}
	for _, alias in ipairs(aliases) do
		if itemStats[alias] then
			return tonumber(itemStats[alias]) or 0
		end
	end
	return 0
end

-- T8 (v0.383+ queue): a plain item's base armor isn't itemized via GetItemStats at all (see
-- CONVENTIONS.md's Armor note -- ITEM_MOD_ARMOR_SHORT only ever picks up a BONUS armor modifier,
-- e.g. a shield's "of the Bear" suffix). That leaves low-level gear -- which very often has no
-- clean numeric stats yet -- scoring a dead, indistinguishable 0 across completely different
-- items. Read the real total via the documented fallback: a hidden tooltip scan of the "Armor"
-- line. Weighted deliberately tiny (see ARMOR_VALUE_WEIGHT below) -- this should separate otherwise-
-- tied items a little, never compete with real stat weights.
local armorScanTooltip = CreateFrame("GameTooltip", "LevelingGearsArmorScanTooltip", nil, "GameTooltipTemplate")
armorScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

function Scoring.ScanItemArmorValue(itemLink)
	if not itemLink then
		return 0
	end
	armorScanTooltip:ClearLines()
	armorScanTooltip:SetHyperlink(itemLink)
	for lineIndex = 2, armorScanTooltip:NumLines() do
		local fontString = _G["LevelingGearsArmorScanTooltipTextLeft" .. lineIndex]
		local text = fontString and fontString:GetText()
		local armor = text and text:match("^(%d+) Armor$")
		if armor then
			return tonumber(armor) or 0
		end
	end
	return 0
end

-- Small and fixed on purpose -- not a user-adjustable weight in the settings UI. A level 5 item
-- with 15 armor vs. 8 armor should no longer tie at 0; a level 70 item with 500 armor should still
-- be dwarfed by its real stat contributions.
local ARMOR_VALUE_WEIGHT = 0.01

-- Druids need form awareness for the AP table: score using the form implied by the detected spec
-- (feral -> cat unless survival mode -> bear) rather than live shapeshift form, so scores don't
-- flicker when the player actually shapeshifts. This is a given design decision, not a judgment call.
local function GetApKey(class, specKey, mode)
	if class ~= "DRUID" then
		return class
	end
	if specKey == "feral" then
		return mode == "survival" and "DRUID_BEAR" or "DRUID_CAT"
	end
	return "DRUID_BEAR" -- Balance/Restoration: "bear/other" per the given AP table
end

local lastLoggedSpecSignature = nil

-- Detect class/spec/mode. Returns (class, specKey, mode, assumed, source) -- assumed is true when
-- no real spec could be pinned down (0 points spent anywhere, typically under level 10, or a tied
-- talent read -- see below) and a per-class default had to be guessed instead; source is one of
-- "override" (the player's own manual choice), "detected" (read from talent points), or "assumed"
-- (the fallback default), for UI/chat text that wants to say which kind of answer this is. Defined
-- with an explicit unused `_self` (rather than colon sugar) since this function needs no instance
-- state -- still callable as `LG.Scoring:DetectSpec()` either way, since Lua's colon-call sugar just
-- passes the object as the first argument regardless of what the function itself calls that
-- parameter.
function Scoring.DetectSpec(_self)
	local _, class = UnitClass("player")
	local tabOrder = TALENT_TAB_ORDER[class]
	if not tabOrder then
		return class, nil, "speed", false, "assumed"
	end

	-- Manual override (v0.38, bug #37): the "Spec:" dropdown in the settings window always wins
	-- over whatever the talent-point reading below produces. Reading literal current talent points
	-- can't reliably reflect a leveling character's intended build (a partially-specced or
	-- early-hybrid talent spread is normal while leveling, well before every point lands in one
	-- tree) -- the dropdown lets a player just say which spec they actually are.
	local characterState = LG.Settings and LG.Settings.GetCharacterState()
	local override = characterState and characterState.specOverride
	if override and LG.Priorities[class] and LG.Priorities[class][override] then
		local specEntry = LG.Priorities[class][override]
		return class, override, specEntry.defaultMode or "speed", false, "override"
	end

	-- Points spent per tab, summed from each individual talent's own current rank
	-- (`select(5, GetTalentInfo(tabIndex, talentIndex))`) rather than trusting
	-- `GetTalentTabInfo`'s own aggregate `pointsSpent` return value (bug #27/#37: that value's exact
	-- return position has been uncertain on this client -- a live report of an Enhancement Shaman
	-- with 44 points detected as Restoration proved the position-guessing fallback chain
	-- (`tonumber(c) or tonumber(d) or tonumber(e)`) that used to live here is not reliable). Summing
	-- individual talent ranks sidesteps that ambiguity entirely: `GetTalentInfo`'s signature (name,
	-- icon, tier, column, currentRank, maxRank, ...) is stable and well-established -- confirmed by
	-- two other real, actively-used addons on this exact client reading `currentRank` the same way:
	-- ShamanPower's own talent scan (`GetTalentInfo(t, i)`) and PallyPower's paladin-aura talent
	-- counter (`select(5, GetTalentInfo(tab, loc))`).
	local bestIndex, bestPoints, totalPoints = nil, -1, 0
	local tiedWithBest = false
	local pointsPerTab = { 0, 0, 0 }
	if GetNumTalents and GetTalentInfo then
		for tabIndex = 1, 3 do
			local pointsSpent = 0
			local numTalents = GetNumTalents(tabIndex) or 0
			for talentIndex = 1, numTalents do
				pointsSpent = pointsSpent + (tonumber((select(5, GetTalentInfo(tabIndex, talentIndex)))) or 0)
			end
			pointsPerTab[tabIndex] = pointsSpent
			totalPoints = totalPoints + pointsSpent
			if pointsSpent > bestPoints then
				bestPoints = pointsSpent
				bestIndex = tabIndex
				tiedWithBest = false
			elseif pointsSpent == bestPoints and bestPoints > 0 then
				tiedWithBest = true
			end
		end
	end

	-- Logged once per unique reading (not every call -- DetectSpec runs once per equipped slot
	-- scored, so unconditional logging here would spam the ring buffer the same way bug #36 did).
	-- Real evidence this per-talent-rank approach is landing on the right numbers, and for bug #37's
	-- tie theory below.
	if LG.Debug then
		local signature = string.format("%s:%d:%d:%d:%s:%s", class, pointsPerTab[1], pointsPerTab[2],
			pointsPerTab[3], tostring(bestIndex), tostring(tiedWithBest))
		if signature ~= lastLoggedSpecSignature then
			lastLoggedSpecSignature = signature
			LG.Debug.WriteDebugLog(string.format(
				"DetectSpec: class=%s tab1=%d tab2=%d tab3=%d bestIndex=%s tied=%s",
				class, pointsPerTab[1], pointsPerTab[2], pointsPerTab[3],
				tostring(bestIndex), tostring(tiedWithBest)), 1)
		end
	end

	local specKey, assumed
	if totalPoints > 0 and bestIndex and not tiedWithBest then
		specKey = tabOrder[bestIndex]
		assumed = false
	else
		-- No points spent yet, OR two-plus trees are tied for the most points spent (bug #37: a
		-- real shape for a leveling build -- e.g. an early-leveling Enhancement Shaman who has put
		-- equal points into Elemental so far). The old code silently resolved a tie to whichever
		-- tab happened to be checked first (tab order, not intent) -- for Shaman that's Elemental,
		-- which matches the exact symptom reported (an Enhancement player scored as Elemental).
		-- Falling back to the documented per-class low-level default is more honest than guessing
		-- from tab order, though the real fix for a leveling character is the manual override above.
		specKey = (LG.Priorities.LOW_LEVEL_DEFAULT_SPEC or {})[class]
		assumed = true
	end

	local specEntry = LG.Priorities[class] and LG.Priorities[class][specKey]
	local mode = specEntry and specEntry.defaultMode or "speed"

	return class, specKey, mode, assumed, (assumed and "assumed" or "detected")
end

local loggedMissingWeights = {}

-- A gap in the priority tables (a derived stat this spec's table never mentions) contributes 0,
-- but is logged once per stat key so gaps surface during testing instead of silently disappearing.
local function LogMissingWeightOnce(statKey)
	if loggedMissingWeights[statKey] then
		return
	end
	loggedMissingWeights[statKey] = true
	if LG.Debug then
		LG.Debug.WriteDebugLog("No priority weight for derived stat '" .. statKey .. "' -- contributing 0.", 1)
	end
end

-- Shared core: derived = Layers 1-2 (Conversions), score = sum(derived * weights). Primaries are
-- never weighted directly here -- they were already folded into derived stats by ApplyConversions,
-- which is what prevents double-counting by construction.
local function ComputeScore(itemStats, class, apKey, offense, weights, itemLink)
	local rawStats = {}
	for statKey in pairs(Scoring.itemStatAliases) do
		rawStats[statKey] = Scoring.ResolveItemStatValue(itemStats, statKey)
	end

	local derived = LG.Conversions:ApplyConversions(rawStats, class, apKey, offense)

	local score = 0
	local breakdown = {}
	for statKey, amount in pairs(derived) do
		local weight = weights and weights[statKey]
		if weight == nil then
			LogMissingWeightOnce(statKey)
			weight = 0
		end
		if weight ~= 0 and amount ~= 0 then
			local contribution = amount * weight
			score = score + contribution
			breakdown[statKey] = contribution
		end
	end

	local armorValue = Scoring.ScanItemArmorValue(itemLink)
	if armorValue ~= 0 then
		local contribution = armorValue * ARMOR_VALUE_WEIGHT
		score = score + contribution
		breakdown.BASEARMOR = contribution
	end

	return score, breakdown
end

-- LG:ScoreItem(itemStats, class, spec, mode) -> score, breakdown -- the debug-bench contract used
-- by /lgs score: scores strictly against Priorities.lua's AUTHORED table for that class/spec/mode,
-- ignoring any live character weights, so the priority tables themselves can be sanity-checked
-- against real items independent of whatever a player has since hand-tweaked. See the _self note on
-- DetectSpec.
function Scoring.ScoreItem(_self, itemStats, class, specKey, mode, itemLink)
	itemStats = itemStats or {}
	local specEntry = LG.Priorities[class] and LG.Priorities[class][specKey]
	local weights = specEntry and specEntry[mode or "speed"]
	local offense = specEntry and specEntry.offense or "melee"
	local apKey = GetApKey(class, specKey, mode)
	return ComputeScore(itemStats, class, apKey, offense, weights, itemLink)
end

-- Score an item for the character's own currently-detected spec/mode, against a LIVE weights
-- table (normally the character's own characterState.weights, already seeded with Priorities
-- defaults for any key the player hasn't touched -- see Weights.lua's EnsureWeights). This is what
-- the equipped-gear outline evaluation calls, so player hand-adjustments always take effect.
function Scoring:ScoreEquippedItem(itemStats, weights, itemLink)
	itemStats = itemStats or {}
	local class, specKey, mode = self:DetectSpec()
	local specEntry = LG.Priorities[class] and LG.Priorities[class][specKey]
	local offense = specEntry and specEntry.offense or "melee"
	local apKey = GetApKey(class, specKey, mode)
	local effectiveWeights = weights or (specEntry and specEntry[mode])
	return ComputeScore(itemStats, class, apKey, offense, effectiveWeights, itemLink)
end

-- Look up this character's default (seed) weights for a brand-new character or a missing stat key.
-- Returns nil if the class/spec/mode can't be resolved, so callers should fall back to their own
-- flat default in that case.
function Scoring:GetDefaultWeights()
	local class, specKey, mode = self:DetectSpec()
	local specEntry = LG.Priorities[class] and LG.Priorities[class][specKey]
	return specEntry and specEntry[mode or "speed"]
end

-- Human-readable "Class/Spec (mode)" summary for the /lgs score debug command, the settings
-- window's spec status line, and shift-click score breakdowns.
function Scoring:DescribeCurrentSpec()
	local class, specKey, mode, _, source = self:DetectSpec()
	local displayName = specKey and Scoring.SPEC_DISPLAY_NAMES[class] and Scoring.SPEC_DISPLAY_NAMES[class][specKey]
	local label = tostring(class) .. "/" .. tostring(displayName or specKey or "?") .. " (" .. tostring(mode) .. ")"
	if source == "override" then
		label = label .. " [manually set]"
	elseif source == "assumed" then
		label = label .. " [assumed - no talent points spent yet, or tied]"
	end
	return label
end

-- Shared presentation for an already-computed score/breakdown: both the /lgs score debug command
-- (Core.lua, scores against Priorities.lua directly) and the shift+left-click-on-equipped-item
-- feature (GearEvaluation.lua, scores against the character's own live weights) print through
-- this one function so the chat output format only exists in one place.
function Scoring.PrintBreakdown(_self, itemLink, score, breakdown, specDescription)
	if not LG.Debug then
		return
	end
	LG.Debug.PrintChat("Score for " .. itemLink .. " as " .. specDescription .. ": " .. string.format("%.1f", score))

	local sortedKeys = {}
	for statKey in pairs(breakdown) do
		table.insert(sortedKeys, statKey)
	end
	table.sort(sortedKeys, function(a, b)
		return math.abs(breakdown[a]) > math.abs(breakdown[b])
	end)
	for _, statKey in ipairs(sortedKeys) do
		LG.Debug.PrintChat("  " .. statKey .. ": " .. string.format("%.2f", breakdown[statKey]))
	end
end
