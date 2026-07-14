-- Leveling Gears -- Priorities.lua (v0.25)
-- Layer 3 of the three-layer scoring engine: authored default weights per class/spec/mode, applied
-- to DERIVED stats only (never to primaries -- those are converted by Conversions.lua first).
--
-- IMPORTANT: every number in this file is a design choice made from general TBC leveling
-- knowledge, not a lookup or a simulation result. Do NOT "correct" these against raid stat weights
-- or sim output later -- raid weights are the wrong target for a leveling addon: no hit/crit caps
-- apply while leveling, and Stamina is worth more solo without a healer. These are seed DEFAULTS
-- for the player's own weight sliders (0-10, same scale and same stat keys as the settings UI) --
-- the player can and is expected to hand-adjust every value afterward.
--
-- Spec key format: "CLASS/spec", e.g. "WARRIOR/arms". Spec name order per class matches
-- GetTalentTabInfo(1..3) tab order on this client.

local _, LG = ...
LG.Priorities = LG.Priorities or {}
local Priorities = LG.Priorities

local function Merge(base, overrides)
	local result = {}
	for key, value in pairs(base) do
		result[key] = value
	end
	if overrides then
		for key, value in pairs(overrides) do
			result[key] = value
		end
	end
	return result
end

-- Archetype bases. Every weight key here matches the settings UI's existing stat keys exactly
-- (see Weights.lua's statDefinitions) so a spec's table can be dropped straight into a character's
-- weights with no translation step. Resistances, Armor Penetration, Resilience, and Spell
-- Penetration default to 0 everywhere: all four are situational/zone- or PvP-specific rather than
-- a general leveling priority, and the player can raise any of them by hand when it matters.
local MELEE_DPS_SPEED = {
	AP = 10, RAP = 0, SP = 0, HEAL = 0, HEALTH = 5, MANA = 0,
	HIT = 8, CRIT = 7, HASTE = 5, EXP = 6, ARMORPEN = 1, ARMOR = 2,
	DEF = 2, DODGE = 2, PARRY = 2, BLOCK = 1, BLOCKVALUE = 0,
	RESILIENCE = 0, MP5 = 0, SPELLPEN = 0,
	ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
}
local MELEE_DPS_SURVIVAL = Merge(MELEE_DPS_SPEED, {
	AP = 7, HIT = 6, CRIT = 5, HASTE = 4, EXP = 4, HEALTH = 9, ARMOR = 6,
	DEF = 5, DODGE = 5, PARRY = 5, BLOCK = 3,
})

local RANGED_DPS_SPEED = {
	AP = 0, RAP = 10, SP = 0, HEAL = 0, HEALTH = 5, MANA = 2,
	HIT = 8, CRIT = 7, HASTE = 5, EXP = 0, ARMORPEN = 1, ARMOR = 1,
	DEF = 0, DODGE = 1, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
	RESILIENCE = 0, MP5 = 1, SPELLPEN = 0,
	ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
}
local RANGED_DPS_SURVIVAL = Merge(RANGED_DPS_SPEED, {
	RAP = 7, HIT = 6, CRIT = 5, HASTE = 4, HEALTH = 9, ARMOR = 5, DODGE = 3, MANA = 2,
})

local CASTER_DPS_SPEED = {
	AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 4, MANA = 6,
	HIT = 8, CRIT = 7, HASTE = 5, EXP = 0, ARMORPEN = 0, ARMOR = 1,
	DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
	RESILIENCE = 0, MP5 = 4, SPELLPEN = 0,
	ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
}
local CASTER_DPS_SURVIVAL = Merge(CASTER_DPS_SPEED, {
	SP = 7, CRIT = 5, HIT = 6, HASTE = 4, MANA = 7, MP5 = 6, HEALTH = 8, ARMOR = 3,
})

-- Healer specs mostly play as damage hybrids while leveling (per the given design brief), so these
-- weight spell damage/healing hybrid stats and mana sustain rather than pure +healing.
local HEALER_SPEED = {
	AP = 0, RAP = 0, SP = 6, HEAL = 8, HEALTH = 5, MANA = 7,
	HIT = 5, CRIT = 5, HASTE = 4, EXP = 0, ARMORPEN = 0, ARMOR = 1,
	DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
	RESILIENCE = 0, MP5 = 6, SPELLPEN = 0,
	ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
}
local HEALER_SURVIVAL = Merge(HEALER_SPEED, {
	SP = 4, HEAL = 9, MANA = 8, MP5 = 8, HEALTH = 8, ARMOR = 3, CRIT = 3, HIT = 3,
})

local TANK_SPEED = {
	AP = 6, RAP = 0, SP = 0, HEAL = 0, HEALTH = 8, MANA = 0,
	HIT = 6, CRIT = 3, HASTE = 2, EXP = 4, ARMORPEN = 0, ARMOR = 8,
	DEF = 8, DODGE = 6, PARRY = 6, BLOCK = 6, BLOCKVALUE = 5,
	RESILIENCE = 0, MP5 = 0, SPELLPEN = 0,
	ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
}
local TANK_SURVIVAL = Merge(TANK_SPEED, {
	AP = 4, HIT = 4, CRIT = 2, EXP = 3, HEALTH = 10, ARMOR = 10, DEF = 10,
	DODGE = 8, PARRY = 8, BLOCK = 8, BLOCKVALUE = 7,
})

-- Bear-form Druids cannot block or parry (no shield, no parry mechanic in Bear Form), so those
-- weights are zeroed even though the rest of the tank archetype still applies. Only survival mode
-- needs this (Feral's speed mode assumes Cat, not Bear -- see the Priorities.DRUID.feral entry).
local BEAR_TANK_SURVIVAL = Merge(TANK_SURVIVAL, { PARRY = 0, BLOCK = 0, BLOCKVALUE = 0 })

-- Each spec entry: offense = "melee"/"ranged"/"spell" (which CR_HIT_*/CR_CRIT_*/CR_HASTE_* triplet
-- Conversions.lua should use for this spec), defaultMode = which mode seeds a brand-new character's
-- weights, speed/survival = the two authored weight tables (0-10).
Priorities.WARRIOR = {
	arms = { offense = "melee", defaultMode = "speed", speed = MELEE_DPS_SPEED, survival = MELEE_DPS_SURVIVAL },
	fury = { offense = "melee", defaultMode = "speed", speed = Merge(MELEE_DPS_SPEED, { HASTE = 7 }), survival = MELEE_DPS_SURVIVAL },
	-- Protection defaults to survival mode: a tank-flavored spec per the given design brief.
	protection = { offense = "melee", defaultMode = "survival", speed = TANK_SPEED, survival = TANK_SURVIVAL },
}

Priorities.PALADIN = {
	holy = { offense = "spell", defaultMode = "speed", speed = HEALER_SPEED, survival = HEALER_SURVIVAL },
	protection = { offense = "melee", defaultMode = "survival", speed = TANK_SPEED, survival = TANK_SURVIVAL },
	retribution = { offense = "melee", defaultMode = "speed", speed = MELEE_DPS_SPEED, survival = MELEE_DPS_SURVIVAL },
}

Priorities.HUNTER = {
	beastmastery = { offense = "ranged", defaultMode = "speed", speed = RANGED_DPS_SPEED, survival = RANGED_DPS_SURVIVAL },
	marksmanship = { offense = "ranged", defaultMode = "speed", speed = RANGED_DPS_SPEED, survival = RANGED_DPS_SURVIVAL },
	survival = { offense = "ranged", defaultMode = "speed", speed = Merge(RANGED_DPS_SPEED, { EXP = 2 }), survival = RANGED_DPS_SURVIVAL },
}

Priorities.ROGUE = {
	assassination = { offense = "melee", defaultMode = "speed", speed = Merge(MELEE_DPS_SPEED, { CRIT = 9 }), survival = MELEE_DPS_SURVIVAL },
	combat = { offense = "melee", defaultMode = "speed", speed = Merge(MELEE_DPS_SPEED, { HASTE = 7, EXP = 8 }), survival = MELEE_DPS_SURVIVAL },
	subtlety = { offense = "melee", defaultMode = "speed", speed = MELEE_DPS_SPEED, survival = MELEE_DPS_SURVIVAL },
}

Priorities.PRIEST = {
	discipline = { offense = "spell", defaultMode = "speed", speed = HEALER_SPEED, survival = HEALER_SURVIVAL },
	holy = { offense = "spell", defaultMode = "speed", speed = HEALER_SPEED, survival = HEALER_SURVIVAL },
	shadow = { offense = "spell", defaultMode = "speed", speed = CASTER_DPS_SPEED, survival = CASTER_DPS_SURVIVAL },
}

Priorities.SHAMAN = {
	elemental = { offense = "spell", defaultMode = "speed", speed = CASTER_DPS_SPEED, survival = CASTER_DPS_SURVIVAL },
	enhancement = { offense = "melee", defaultMode = "speed", speed = Merge(MELEE_DPS_SPEED, { MANA = 2, MP5 = 1 }), survival = MELEE_DPS_SURVIVAL },
	restoration = { offense = "spell", defaultMode = "speed", speed = HEALER_SPEED, survival = HEALER_SURVIVAL },
}

Priorities.MAGE = {
	arcane = { offense = "spell", defaultMode = "speed", speed = CASTER_DPS_SPEED, survival = CASTER_DPS_SURVIVAL },
	fire = { offense = "spell", defaultMode = "speed", speed = CASTER_DPS_SPEED, survival = CASTER_DPS_SURVIVAL },
	frost = { offense = "spell", defaultMode = "speed", speed = CASTER_DPS_SPEED, survival = CASTER_DPS_SURVIVAL },
}

Priorities.WARLOCK = {
	affliction = { offense = "spell", defaultMode = "speed", speed = CASTER_DPS_SPEED, survival = CASTER_DPS_SURVIVAL },
	demonology = { offense = "spell", defaultMode = "speed", speed = CASTER_DPS_SPEED, survival = CASTER_DPS_SURVIVAL },
	destruction = { offense = "spell", defaultMode = "speed", speed = CASTER_DPS_SPEED, survival = CASTER_DPS_SURVIVAL },
}

Priorities.DRUID = {
	balance = { offense = "spell", defaultMode = "speed", speed = CASTER_DPS_SPEED, survival = CASTER_DPS_SURVIVAL },
	-- Feral form-for-scoring (given, not a judgment call): speed mode assumes Cat (melee dps),
	-- survival mode assumes Bear (tank) -- Scoring.lua picks the AP table entry the same way.
	feral = { offense = "melee", defaultMode = "speed", speed = Merge(MELEE_DPS_SPEED, { HEALTH = 6 }), survival = BEAR_TANK_SURVIVAL },
	restoration = { offense = "spell", defaultMode = "speed", speed = HEALER_SPEED, survival = HEALER_SURVIVAL },
}

-- Low-level fallback (judgment call): under level 10 / 0 talent points spent, no spec can be
-- detected. One assumed default per class, kept here as a plain data table so it can be revised
-- without touching Scoring.lua's logic. Scoring.lua marks the result `assumed = true` when used.
Priorities.LOW_LEVEL_DEFAULT_SPEC = {
	WARRIOR = "fury",
	PALADIN = "protection",
	HUNTER = "beastmastery",
	ROGUE = "combat",
	PRIEST = "shadow",
	SHAMAN = "enhancement",
	MAGE = "fire",
	WARLOCK = "affliction",
	DRUID = "balance",
}
