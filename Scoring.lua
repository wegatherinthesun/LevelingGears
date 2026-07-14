-- Leveling Gears -- Scoring.lua (v0.25)
-- ScoreItem() combines Conversions.lua (Layers 1-2) with Priorities.lua (Layer 3) into a single
-- number, plus spec/form detection so the right priority table and AP conversion get picked
-- automatically. See DESIGN.md for the full rationale.

local _, LG = ...
LG.Scoring = LG.Scoring or {}
local Scoring = LG.Scoring

-- Talent tab order per class on this client (index 1/2/3 -> spec key). Matching by tab INDEX
-- rather than the tab's displayed name avoids locale issues entirely (GetTalentTabInfo's name
-- field is localized text; the tab order itself is not).
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

-- Detect class/spec/mode from talent points. Returns (class, specKey, mode, assumed) -- assumed is
-- true when the character has 0 points spent anywhere (typically under level 10) and a per-class
-- default had to be guessed instead of read from the character. Defined with an explicit unused
-- `_self` (rather than colon sugar) since this function needs no instance state -- still callable
-- as `LG.Scoring:DetectSpec()` either way, since Lua's colon-call sugar just passes the object as
-- the first argument regardless of what the function itself calls that parameter.
function Scoring.DetectSpec(_self)
	local _, class = UnitClass("player")
	local tabOrder = TALENT_TAB_ORDER[class]
	if not tabOrder then
		return class, nil, "speed", false
	end

	local bestIndex, bestPoints, totalPoints = nil, -1, 0
	if GetTalentTabInfo then
		for tabIndex = 1, 3 do
			-- pointsSpent's exact return position is uncertain on this client (bug #27): assuming
			-- the old-style signature (name, icon, pointsSpent, background, ...) put pointsSpent at
			-- position 3, but the live debug log caught "attempt to perform arithmetic on local
			-- 'pointsSpent' (a string value)" here -- position 3 is actually a string on this
			-- client, consistent with a modern-retail-style signature (id, name, icon, pointsSpent,
			-- background, ...) shifting it to position 4. Rather than commit to either guess, try
			-- both plausible positions (and position 5, in case a description field is also
			-- present) and use whichever one is actually numeric.
			local _, _, c, d, e = GetTalentTabInfo(tabIndex)
			local pointsSpent = tonumber(c) or tonumber(d) or tonumber(e) or 0
			totalPoints = totalPoints + pointsSpent
			if pointsSpent > bestPoints then
				bestPoints = pointsSpent
				bestIndex = tabIndex
			end
		end
	end

	local specKey, assumed
	if totalPoints > 0 and bestIndex then
		specKey = tabOrder[bestIndex]
		assumed = false
	else
		specKey = (LG.Priorities.LOW_LEVEL_DEFAULT_SPEC or {})[class]
		assumed = true
	end

	local specEntry = LG.Priorities[class] and LG.Priorities[class][specKey]
	local mode = specEntry and specEntry.defaultMode or "speed"

	return class, specKey, mode, assumed
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
local function ComputeScore(itemStats, class, apKey, offense, weights)
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

	return score, breakdown
end

-- LG:ScoreItem(itemStats, class, spec, mode) -> score, breakdown -- the debug-bench contract used
-- by /lgs score: scores strictly against Priorities.lua's AUTHORED table for that class/spec/mode,
-- ignoring any live character weights, so the priority tables themselves can be sanity-checked
-- against real items independent of whatever a player has since hand-tweaked. See the _self note on
-- DetectSpec.
function Scoring.ScoreItem(_self, itemStats, class, specKey, mode)
	itemStats = itemStats or {}
	local specEntry = LG.Priorities[class] and LG.Priorities[class][specKey]
	local weights = specEntry and specEntry[mode or "speed"]
	local offense = specEntry and specEntry.offense or "melee"
	local apKey = GetApKey(class, specKey, mode)
	return ComputeScore(itemStats, class, apKey, offense, weights)
end

-- Score an item for the character's own currently-detected spec/mode, against a LIVE weights
-- table (normally the character's own characterState.weights, already seeded with Priorities
-- defaults for any key the player hasn't touched -- see Weights.lua's EnsureWeights). This is what
-- the equipped-gear outline evaluation calls, so player hand-adjustments always take effect.
function Scoring:ScoreEquippedItem(itemStats, weights)
	itemStats = itemStats or {}
	local class, specKey, mode = self:DetectSpec()
	local specEntry = LG.Priorities[class] and LG.Priorities[class][specKey]
	local offense = specEntry and specEntry.offense or "melee"
	local apKey = GetApKey(class, specKey, mode)
	local effectiveWeights = weights or (specEntry and specEntry[mode])
	return ComputeScore(itemStats, class, apKey, offense, effectiveWeights)
end

-- Look up this character's default (seed) weights for a brand-new character or a missing stat key.
-- Returns nil if the class/spec/mode can't be resolved, so callers should fall back to their own
-- flat default in that case.
function Scoring:GetDefaultWeights()
	local class, specKey, mode = self:DetectSpec()
	local specEntry = LG.Priorities[class] and LG.Priorities[class][specKey]
	return specEntry and specEntry[mode or "speed"]
end

-- Human-readable "Class/spec (mode)" summary for the /lgs score debug command and any future UI.
function Scoring:DescribeCurrentSpec()
	local class, specKey, mode, assumed = self:DetectSpec()
	local label = tostring(class) .. "/" .. tostring(specKey or "?") .. " (" .. tostring(mode) .. ")"
	if assumed then
		label = label .. " [assumed - no talent points spent yet]"
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
