-- Leveling Gears -- Conversions.lua (v0.25)
-- Layer 1 (live, level/class-dependent API reads) and Layer 2 (the one hardcoded conversion
-- table: primary stat -> Attack Power per class/form) of the three-layer scoring engine.
-- Layer 3 (Priorities.lua) supplies the weights that get multiplied against this layer's output;
-- keeping the layers in separate files is the point -- conversions are game mechanics, priorities
-- are design choices, and mixing them causes double-counting bugs. See DESIGN.md.

local _, LG = ...
LG.Conversions = LG.Conversions or {}
local Conversions = LG.Conversions

-- Fallback used ONLY when GetCombatRating(CR) == 0 (the character owns none of that rating yet, so
-- the live bonus/rating division below is impossible). These are the documented TBC level-70
-- rating-per-percent constants (post-2.1-patch Parry value of 22.4, not the pre-patch 31.5), applied
-- uniformly regardless of the character's actual level. This is a deliberate simplification (the
-- "weight the rating at a conservative default" option) rather than a full per-level lookup table --
-- acceptable for a rough leveling guide, and it errs toward not undervaluing the stat.
-- Sources: TBC 2.4.3 combat rating conversion tables (Warcraft Wiki / community theorycrafting).
local RATING_FALLBACK = {
	{ const = "CR_DEFENSE_SKILL", pointsPerPercent = 2.4 },
	{ const = "CR_DODGE", pointsPerPercent = 18.9 },
	{ const = "CR_PARRY", pointsPerPercent = 22.4 },
	{ const = "CR_BLOCK", pointsPerPercent = 7.9 },
	{ const = "CR_HIT_MELEE", pointsPerPercent = 15.8 },
	{ const = "CR_HIT_RANGED", pointsPerPercent = 15.8 },
	{ const = "CR_HIT_SPELL", pointsPerPercent = 15.8 },
	{ const = "CR_CRIT_MELEE", pointsPerPercent = 22.1 },
	{ const = "CR_CRIT_RANGED", pointsPerPercent = 22.1 },
	{ const = "CR_CRIT_SPELL", pointsPerPercent = 22.1 },
	{ const = "CR_HASTE_MELEE", pointsPerPercent = 15.8 },
	{ const = "CR_HASTE_RANGED", pointsPerPercent = 15.8 },
	{ const = "CR_HASTE_SPELL", pointsPerPercent = 15.8 },
	{ const = "CR_EXPERTISE", pointsPerPercent = 3.9423 },
	{ const = "CR_RESILIENCE", pointsPerPercent = 39.4 },
	-- Armor Penetration Rating was not itemized until patch 3.0.2 (the pre-Wrath prepatch, after
	-- TBC's own content patches) -- CR_ARMOR_PENETRATION may not exist, or may exist but never be
	-- populated by any TBC-era item, on this client. Guarded exactly like every other rating below,
	-- so it simply contributes 0 if the client has nothing to report. See DESIGN.md.
	{ const = "CR_ARMOR_PENETRATION", pointsPerPercent = 15.8 },
}

-- Layer 2: the API has no clean way to expose "Attack Power per point of primary stat," so this
-- small table is the one deliberately hardcoded piece of conversion data. Verified for TBC 2.5.x.
Conversions.AP_TABLE = {
	WARRIOR = { str = 2, agiRanged = 1 },
	PALADIN = { str = 2 },
	ROGUE = { str = 1, agi = 1, agiRanged = 1 },
	HUNTER = { str = 1, agiRanged = 1 }, -- ranged is what matters; melee AP is not weighted for Hunters
	SHAMAN = { str = 1 }, -- NOT 2 -- the 2-per-Str change is Wrath, not TBC
	DRUID_CAT = { str = 2, agi = 1 },
	DRUID_BEAR = { str = 2 }, -- also used for Balance/Restoration ("bear/other" per the given spec)
	MAGE = { str = 1 },
	PRIEST = { str = 1 },
	WARLOCK = { str = 1 },
	-- Block value from Strength (Str/20 for shield users) is deliberately omitted: negligible while
	-- leveling, and adding it would require plumbing a shield-equipped check through every caller.
}

Conversions.cache = {
	agiToCritPct = 0,
	intToSpellCritPct = 0,
	agiToArmor = 0,
	intToMana = 0,
	staToHealth = 10, -- marginal HP-per-Stamina; correct for item deltas even though the first ~20
	                   -- points of a character's base Stamina give only 1 HP each
	ratingPctPerPoint = {},
}

local function SafeDivide(numerator, denominator, fallback)
	if not denominator or denominator == 0 then
		return fallback or 0
	end
	return numerator / denominator
end

-- Re-reads every live, level/class-dependent conversion from the character. Cheap enough to call
-- on demand (a handful of API calls, no loops over gear), but still only called from PLAYER_LEVEL_UP
-- and ScoreItem's entry point -- never on a timer, since these values cannot change mid-combat in a
-- leveling addon's use case and there's no reason to re-read them more often than that.
function Conversions:Refresh()
	local cache = self.cache

	local agility = UnitStat and UnitStat("player", 2) or 0
	local agiCritPct = GetCritChanceFromAgility and GetCritChanceFromAgility("player") or 0
	cache.agiToCritPct = SafeDivide(agiCritPct, agility, 0)

	local intellect = UnitStat and UnitStat("player", 4) or 0
	local intCritPct = GetSpellCritChanceFromIntellect and GetSpellCritChanceFromIntellect("player") or 0
	cache.intToSpellCritPct = SafeDivide(intCritPct, intellect, 0)

	-- Both are real Blizzard globals, not addon-defined constants; nil-guarded in case a future
	-- client build ever removes them, per this project's "never assume a global exists" rule.
	cache.agiToArmor = ARMOR_PER_AGILITY or 0
	cache.intToMana = MANA_PER_INTELLECT or 0

	for _, entry in ipairs(RATING_FALLBACK) do
		-- Talent/buff contamination is possible here (these APIs report the buffed character), which
		-- is acceptable for a leveling addon -- this is why Refresh is called lazily, not mid-combat.
		local ratingType = _G[entry.const]
		if ratingType then
			local currentRating = GetCombatRating and GetCombatRating(ratingType) or 0
			local currentBonusPct = GetCombatRatingBonus and GetCombatRatingBonus(ratingType) or 0
			if currentRating and currentRating > 0 then
				cache.ratingPctPerPoint[entry.const] = SafeDivide(currentBonusPct, currentRating, 1 / entry.pointsPerPercent)
			else
				cache.ratingPctPerPoint[entry.const] = 1 / entry.pointsPerPercent
			end
		end
	end
end

-- Turn an item's raw stat table (keyed the same as the addon's existing stat keys: STR, AGI, HIT,
-- CRIT, ARMOR, etc.) into derived stats using the SAME short keys the settings UI already weights
-- (AP, RAP, SP, HEAL, HEALTH, MANA, HIT, CRIT, HASTE, EXP, ARMORPEN, ARMOR, DEF, DODGE, PARRY,
-- BLOCK, BLOCKVALUE, RESILIENCE, MP5, SPELLPEN, and the 5 resistances). Reusing the existing key
-- names means Priorities.lua and the player's saved weights need no separate vocabulary.
--
-- offenseType is "melee", "ranged", or "spell" -- which CR_HIT_*/CR_CRIT_*/CR_HASTE_* triplet
-- applies. A single item's Hit/Crit/Haste Rating value affects all three combat types at once in
-- the game, but this addon only shows one "Hit Rating" style slider, so it deliberately scores
-- using whichever type matches the spec's primary offense (documented simplification, see DESIGN.md).
function Conversions:ApplyConversions(rawStats, class, apKey, offenseType)
	self:Refresh()
	local cache = self.cache
	local derived = {}

	local function add(key, amount)
		if amount and amount ~= 0 then
			derived[key] = (derived[key] or 0) + amount
		end
	end

	-- Layer 2: primaries -> Attack Power, per class/form.
	local apEntry = self.AP_TABLE[apKey] or self.AP_TABLE[class] or {}
	add("AP", (rawStats.STR or 0) * (apEntry.str or 0))
	add("AP", (rawStats.AGI or 0) * (apEntry.agi or 0))
	add("RAP", (rawStats.AGI or 0) * (apEntry.agiRanged or 0))

	-- Stats that already arrive in derived form on the item -- pass through unchanged.
	add("AP", rawStats.AP)
	add("RAP", rawStats.RAP)
	add("SP", rawStats.SP)
	add("HEAL", rawStats.HEAL)
	add("MP5", rawStats.MP5)
	add("BLOCKVALUE", rawStats.BLOCKVALUE)
	add("SPELLPEN", rawStats.SPELLPEN)
	add("ARCANERES", rawStats.ARCANERES)
	add("FIRERES", rawStats.FIRERES)
	add("FROSTRES", rawStats.FROSTRES)
	add("NATURERES", rawStats.NATURERES)
	add("SHADOWRES", rawStats.SHADOWRES)
	-- ARMOR: bonus/suffix armor modifiers only -- a plain piece's base armor isn't exposed by
	-- GetItemStats at all (see the existing caveat in Scoring.lua / CLAUDE.md Technical notes).
	add("ARMOR", rawStats.ARMOR)

	-- Layer 1: Stamina -> Health, Intellect -> Mana (marginal per-point rates).
	add("HEALTH", (rawStats.STA or 0) * cache.staToHealth)
	add("MANA", (rawStats.INT or 0) * cache.intToMana)

	-- Layer 1: Agility -> armor (live client constant).
	add("ARMOR", (rawStats.AGI or 0) * cache.agiToArmor)

	-- Layer 1: Agility -> crit% (physical), Intellect -> spell crit% (casters), read live from the
	-- character rather than hardcoded, since both scale with level and current stat totals.
	local offense = offenseType or "melee"
	local critConst = offense == "spell" and "CR_CRIT_SPELL" or (offense == "ranged" and "CR_CRIT_RANGED" or "CR_CRIT_MELEE")
	local hitConst = offense == "spell" and "CR_HIT_SPELL" or (offense == "ranged" and "CR_HIT_RANGED" or "CR_HIT_MELEE")
	local hasteConst = offense == "spell" and "CR_HASTE_SPELL" or (offense == "ranged" and "CR_HASTE_RANGED" or "CR_HASTE_MELEE")

	if offense == "spell" then
		add("CRIT", (rawStats.INT or 0) * cache.intToSpellCritPct)
	else
		add("CRIT", (rawStats.AGI or 0) * cache.agiToCritPct)
	end
	add("CRIT", (rawStats.CRIT or 0) * (cache.ratingPctPerPoint[critConst] or 0))
	add("HIT", (rawStats.HIT or 0) * (cache.ratingPctPerPoint[hitConst] or 0))
	add("HASTE", (rawStats.HASTE or 0) * (cache.ratingPctPerPoint[hasteConst] or 0))

	-- Layer 1: the remaining ratings convert 1:1 regardless of offense type.
	add("DEF", (rawStats.DEF or 0) * (cache.ratingPctPerPoint.CR_DEFENSE_SKILL or 0))
	add("DODGE", (rawStats.DODGE or 0) * (cache.ratingPctPerPoint.CR_DODGE or 0))
	add("PARRY", (rawStats.PARRY or 0) * (cache.ratingPctPerPoint.CR_PARRY or 0))
	add("BLOCK", (rawStats.BLOCK or 0) * (cache.ratingPctPerPoint.CR_BLOCK or 0))
	add("EXP", (rawStats.EXP or 0) * (cache.ratingPctPerPoint.CR_EXPERTISE or 0))
	add("RESILIENCE", (rawStats.RESILIENCE or 0) * (cache.ratingPctPerPoint.CR_RESILIENCE or 0))
	add("ARMORPEN", (rawStats.ARMORPEN or 0) * (cache.ratingPctPerPoint.CR_ARMOR_PENETRATION or 0))

	-- Spirit intentionally has no Layer 1 conversion here: the given architecture only specifies
	-- Stamina->Health, Intellect->Mana, and Agility->crit%/armor as primary conversions. A Spirit
	-- item's other stats still score normally; only its own Spirit value contributes nothing. See
	-- DESIGN.md for the reasoning and a note on revisiting this if Spirit should be valued later.

	return derived
end
