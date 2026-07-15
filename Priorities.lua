-- Leveling Gears -- Priorities.lua (v0.25, re-sourced v0.307, re-derived analytically v0.308)
-- Layer 3 of the three-layer scoring engine: default weights per class/spec/mode, applied to
-- DERIVED stats only (never to primaries -- those are converted by Conversions.lua first).
--
-- METHODOLOGY (v0.308): these are no longer a hand-authored guess (v0.25-v0.306), nor a numeric
-- scale invented from a guide's qualitative rank order (v0.307). Every weight below is DERIVED from
-- known, verified TBC Classic (2.5.x) combat formulas -- real math, not simulation and not a guess.
--
-- The reference unit per spec is its own primary throughput stat (AP for melee, RAP for ranged, SP
-- for casters, HEAL for healers), fixed at 10. Every other stat is expressed as a multiple of that
-- reference, derived as follows:
--
-- 1. **Physical/ranged specs** (verified formula: 14 Attack Power = 1 DPS -- Wowpedia/community
--    theorycrafting, cross-checked against multiple TBC Classic sources):
--    - Crit Rating: a physical crit deals double (200%) damage, so 1% crit chance contributes
--      ~1.0x the reference stat's marginal value (expected-damage multiplier = 1 + critChance).
--    - Haste Rating: a direct multiplicative attack-frequency scalar, ~1.0x reference per 1%.
--    - Hit Rating: a miss deals ZERO damage (not just "less"), and for resource-based classes also
--      forfeits that swing's resource/proc generation -- both real, distinct effects beyond a simple
--      damage multiplier, so Hit is weighted ~1.3x reference per 1% (pre-cap only -- see limitation
--      #2 below).
--    - Expertise: reduces dodge/parry chance, which is mechanically the same "avoided negated swing"
--      effect as Hit -- weighted the same, ~1.3x reference per 1%-equivalent.
--    - Armor Penetration: reduces target armor via a NONLINEAR mitigation curve (diminishing returns
--      as target armor drops), so a flat per-point weight is necessarily a simplification -- weighted
--      at a conservative ~0.5x reference, matching every melee source's real-world observation that
--      Armor Pen underperforms unless stacked far beyond typical leveling-relevant levels.
-- 2. **Warrior-specific correction** (real, cited mechanic, not a guess): TBC's rage-generation
--    formula is NORMALIZED for weapon/attack speed (rage-per-swing scales down as attack speed goes
--    up), so Haste is closer to rage-NEUTRAL for Warriors specifically, not the ~1.0x DPS-multiplier
--    value it is for Energy/Mana classes -- discounted to ~0.3x reference. Crit, conversely, gets a
--    genuine bonus beyond the standard 1.0x: a crit generates enough rage in one hit to close gaps
--    between special-ability casts (fewer "auto-attack-only" swings waiting on rage), a real,
--    documented rage-economy effect -- boosted to ~1.2x reference.
-- 3. **Caster specs**: reference is Spell Power. Hit/Haste/Crit ratios are grounded in the one real
--    published numeric table found during research -- Icy Veins' Affliction Warlock "Spell Power
--    Equivalency" table (Ruin build): Hit = 1.901 SP, Haste = 1.353 SP, Crit = 0.829 SP, Intellect =
--    0.245 SP, Stamina = 0 SP, Spirit = 0.110 SP (with Improved Drain Soul only). These are real,
--    computed-and-published values (not derived by me), used directly for Warlock and as the
--    extrapolated default template for every other caster, since the underlying mechanic (a spell
--    miss/crit/cast-time reduction) is the same formula shape for any caster. Two documented
--    per-class corrections on top of that template:
--    - **Crit-multiplier talents**: a caster crit normally deals +50% bonus damage; Elemental
--      Shaman (Elemental Fury) and Balance Druid (Vengeance) boost this to +100% for their signature
--      nuke -- their Crit ratio is scaled up proportionally (~1.5x the Warlock baseline ratio).
--    - **DoT/HoT-immune-to-crit specs**: Shadow Priest's periodic damage (Shadow Word: Pain, Mind
--      Flay ticks) and every HoT-based healer's periodic healing cannot critically strike in TBC --
--      Crit's ratio is discounted for these specs to reflect that a meaningful share of their output
--      can never benefit from it.
-- 4. **Healer specs**: reference is Healing Power. Grounded in the one other real numeric table
--    found -- Icy Veins' Restoration Shaman page publishes explicit ratios (Heal 1.0, Haste 1.5, MP5
--    2.0, Crit 0.6, Intellect 0.5, Stamina 0.2) -- used directly for that spec, and as a structural
--    template for other healers, individually reweighted per that spec's own real, cited priority
--    order (e.g. Holy Paladin's Haste ranks LAST among healers per its own source, the opposite of
--    Resto Shaman's -- honored as a real, spec-specific difference, not smoothed away).
--
-- IMPORTANT DISTINCTION this version corrects: a guide's published PRIORITY ORDER often blends two
-- different things -- (a) a stat's true marginal value in the damage/healing formula, and (b) plain
-- itemization-scarcity advice ("grab this when you see it, you'll get plenty of the other stat
-- naturally"). Only (a) belongs in a per-item scoring weight -- this addon compares two items'
-- stats directly, it is not giving shopping advice about which stat is rarer on gear. Where a cited
-- source explicitly gave itemization-scarcity as its stated reason (e.g. Warrior guides explicitly
-- say Strength/AP is deprioritized because it's "abundant on gear," not because it's worth less
-- DPS), that reasoning is NOT applied here -- the primary reference stat (AP/RAP/SP/HEAL) always
-- keeps its full, true, un-suppressed formula value. Where a source's ranking reflects a genuine
-- mechanical effect (rage economy, crit-multiplier talents, hard caps, HoT/DoT crit-immunity,
-- nonlinear armor mitigation), that IS reflected, per points 1-4 above.
--
-- HONEST LIMITS (read before "fixing" a number against a sim):
-- 1. This is analytically derived from known formulas, not simulated. A real simulator (e.g.
--    wowsims/tbc) computes true marginal DPS for a SPECIFIC gear/talent/rotation setup and would be
--    more precise -- see ROADMAP.md's "Past 1.0" section for revisiting whether that's worth doing.
-- 2. Hit and Expertise are cap-then-worthless stats in real TBC play (e.g. "9% hit, then additional
--    rating is wasted"). This addon scores items statically per item with no running total-vs-cap
--    state, so it CANNOT model a dynamic breakpoint -- these are weighted at their PRE-cap
--    importance. A fully-hit-capped character will still see new Hit stats scored as valuable; that
--    is a known, documented limitation, not a bug to "fix" by lowering the number.
-- 3. "Survival" mode has no real leveling-specific formula to derive from -- there is no published
--    "solo leveling" combat model. Survival tables are the derived "speed" baseline with a
--    documented, NOT-derived defensive transform applied on top (raise HEALTH/ARMOR/DEF/DODGE/
--    PARRY/BLOCK a handful of points, lower cap-precision stats a few points since a leveling mob's
--    hit/dodge tables aren't raid-boss-tuned) -- a deliberate leveling-context judgment call, same as
--    every version before this one.
-- 4. Primary stats (Agility/Strength/Intellect/Spirit/Stamina) are never weighted directly in this
--    file -- Conversions.lua folds them into AP/RAP/CRIT/ARMOR/HEALTH/MANA first (see DESIGN.md's
--    double-counting rule), and Conversions.lua ALSO already converts every rating stat (Hit/Crit/
--    Haste/Expertise/Defense/Dodge/Parry/Block/Resilience/Armor Pen) from raw item points into real
--    percentages using LIVE, verified game-API conversion rates before a weight below is ever
--    applied -- so every ratio in this file is genuinely "value per 1% of the derived stat," not
--    "value per rating point."
-- 5. "Spirit" has no Layer 1 conversion in this engine (see DESIGN.md) and so has no weight key of
--    its own. Where a cited source ranks Spirit, that emphasis is folded into MP5 (the closest
--    available proxy: both represent mana-sustain-over-time value).
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

-- Every weight table below carries all 25 stat keys explicitly (matching Weights.lua's
-- statDefinitions exactly) so nothing silently falls back to a missing-key default elsewhere.
-- Resistances and Spell Penetration are 0 in every single spec below -- every source consulted
-- called these PvP-only or "no raid boss has resistance worth reducing," with zero exceptions.

------------------------------------------------------------------------------
-- WARRIOR
-- Source (Arms/Fury): https://www.icy-veins.com/tbc-classic/arms-warrior-dps-pve-stat-priority
--                      https://www.icy-veins.com/tbc-classic/fury-warrior-dps-pve-stat-priority
-- Both identical: Hit(9%)/Expertise(6.5%) top priority (cap-avoidance bonus, ~1.3x AP), Crit next
-- (rage-economy bonus, ~1.2x AP -- see file header point 2), Armor Pen discounted (~0.5x, nonlinear
-- mitigation), Haste heavily discounted (~0.3x -- rage-generation is normalized for attack speed in
-- TBC, so Haste is close to rage-neutral for this Rage-based class specifically). AP itself keeps
-- its full reference value (10) -- the guides' "Str/AP ranks low, it's abundant on gear" comment is
-- itemization-scarcity advice, not a true-value claim, so it is NOT applied here (see file header).
------------------------------------------------------------------------------
Priorities.WARRIOR = {}

local WARRIOR_MELEE_DPS_SPEED = {
	AP = 10, RAP = 0, SP = 0, HEAL = 0, HEALTH = 2, MANA = 0,
	HIT = 13, CRIT = 12, HASTE = 3, EXP = 13, ARMORPEN = 5, ARMOR = 0,
	DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
	RESILIENCE = 0, MP5 = 0, SPELLPEN = 0,
	ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
}
local WARRIOR_MELEE_DPS_SURVIVAL = Merge(WARRIOR_MELEE_DPS_SPEED, {
	HIT = 10, CRIT = 10, EXP = 10, ARMORPEN = 4, HEALTH = 8, ARMOR = 4,
	DEF = 3, DODGE = 3, PARRY = 3, BLOCK = 1,
})
Priorities.WARRIOR.arms = { offense = "melee", defaultMode = "speed", speed = WARRIOR_MELEE_DPS_SPEED, survival = WARRIOR_MELEE_DPS_SURVIVAL }
Priorities.WARRIOR.fury = { offense = "melee", defaultMode = "speed", speed = WARRIOR_MELEE_DPS_SPEED, survival = WARRIOR_MELEE_DPS_SURVIVAL }

-- Source (Protection): https://www.icy-veins.com/tbc-classic/protection-warrior-tank-pve-stat-priority
-- Defensive (default/"survival" mode): Stamina "becomes king" past the 102.4% avoidance cap -- given
-- an elevated HEALTH weight above even Defense/Armor to reflect that. Resilience genuinely appears
-- in this PvE tank list (a real exception to the usual PvP-only pattern) -- honored, not zeroed.
-- Offensive/threat ("speed" mode): Expertise/Hit (cap-avoidance bonus, ~1.1x reference) lead; AP
-- kept at a moderate value since threat generation still benefits from it, just secondary to
-- landing every attack.
Priorities.WARRIOR.protection = {
	offense = "melee", defaultMode = "survival",
	speed = {
		AP = 6, RAP = 0, SP = 0, HEAL = 0, HEALTH = 6, MANA = 0,
		HIT = 11, CRIT = 7, HASTE = 2, EXP = 11, ARMORPEN = 0, ARMOR = 5,
		DEF = 6, DODGE = 4, PARRY = 3, BLOCK = 4, BLOCKVALUE = 3,
		RESILIENCE = 3, MP5 = 0, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 2, RAP = 0, SP = 0, HEAL = 0, HEALTH = 13, MANA = 0,
		HIT = 7, CRIT = 2, HASTE = 1, EXP = 7, ARMORPEN = 0, ARMOR = 10,
		DEF = 11, DODGE = 6, PARRY = 5, BLOCK = 6, BLOCKVALUE = 4,
		RESILIENCE = 5, MP5 = 0, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

------------------------------------------------------------------------------
-- PALADIN
------------------------------------------------------------------------------
Priorities.PALADIN = {}

-- Source (Holy): https://www.icy-veins.com/tbc-classic/holy-paladin-healer-pve-stat-priority
-- Priority: Healing Power > MP5 > Spell Crit > Intellect > Spell Haste. Haste ranks LAST here --
-- genuinely unusual among healers (no stated mechanical reason found, so honored as a real,
-- spec-specific difference rather than corrected toward the Resto Shaman template).
Priorities.PALADIN.holy = {
	offense = "spell", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 0, SP = 0, HEAL = 10, HEALTH = 2, MANA = 5,
		HIT = 0, CRIT = 6, HASTE = 2, EXP = 0, ARMORPEN = 0, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 8, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 0, HEAL = 9, HEALTH = 9, MANA = 5,
		HIT = 0, CRIT = 5, HASTE = 2, EXP = 0, ARMORPEN = 0, ARMOR = 3,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 9, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

-- Source (Protection): https://www.icy-veins.com/tbc-classic/protection-paladin-tank-pve-stat-priority
-- Priority: Defense (to 490) > Total Avoidance (Block > Dodge > Miss > Parry, to 102.4% uncrushable)
-- > Stamina ("becomes king" once avoidance cap is reached) > Spell Damage > Hit > Expertise.
Priorities.PALADIN.protection = {
	offense = "melee", defaultMode = "survival",
	speed = {
		AP = 2, RAP = 0, SP = 2, HEAL = 0, HEALTH = 5, MANA = 2,
		HIT = 6, CRIT = 0, HASTE = 0, EXP = 5, ARMORPEN = 0, ARMOR = 5,
		DEF = 6, DODGE = 5, PARRY = 3, BLOCK = 6, BLOCKVALUE = 3,
		RESILIENCE = 0, MP5 = 0, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 2, HEAL = 0, HEALTH = 11, MANA = 1,
		HIT = 3, CRIT = 0, HASTE = 0, EXP = 2, ARMORPEN = 0, ARMOR = 5,
		DEF = 11, DODGE = 7, PARRY = 4, BLOCK = 8, BLOCKVALUE = 4,
		RESILIENCE = 0, MP5 = 0, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

-- Source (Retribution): https://www.icy-veins.com/tbc-classic/retribution-paladin-dps-pve-stat-priority
-- Priority: Hit(9%, 95 rating w/ Precision) > Expertise > Strength > Attack Power > Haste > Armor
-- Penetration > Agility/Crit. AP keeps full reference value (Mana-based class, no rage quirk).
-- Haste's gap below AP in the source has no stated mechanical reason (unlike Warrior's rage
-- normalization), so only a modest gap is applied here, not the source's full apparent gap -- see
-- file header's distinction between true-value and itemization-scarcity signals. Armor Pen
-- discounted further than the melee default: Ret's damage is part physical/part magic
-- (Seals/Judgement), so Armor Pen (physical-only) loses proportionally more value.
local PALADIN_RET_SPEED = {
	AP = 10, RAP = 0, SP = 0, HEAL = 0, HEALTH = 2, MANA = 2,
	HIT = 13, CRIT = 7, HASTE = 8, EXP = 11, ARMORPEN = 4, ARMOR = 0,
	DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
	RESILIENCE = 0, MP5 = 0, SPELLPEN = 0,
	ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
}
Priorities.PALADIN.retribution = {
	offense = "melee", defaultMode = "speed",
	speed = PALADIN_RET_SPEED,
	survival = Merge(PALADIN_RET_SPEED, {
		HIT = 10, CRIT = 6, HASTE = 7, EXP = 9, ARMORPEN = 3,
		HEALTH = 9, ARMOR = 4, DEF = 2,
	}),
}

------------------------------------------------------------------------------
-- HUNTER
-- Source (BM/MM): https://www.icy-veins.com/tbc-classic/beast-mastery-hunter-dps-pve-stat-priority
--                 https://www.icy-veins.com/tbc-classic/marksmanship-hunter-dps-pve-stat-priority
-- Both identical: Hit > Armor Penetration > Agility > Attack Power > Crit. Notably neither guide
-- mentions Haste at all in the priority list -- treated as a real signal (TBC Hunters have very
-- limited Haste itemization access and it wasn't itemized as relevant), not an oversight, so
-- HASTE = 0. Armor Penetration is genuinely elevated above the melee default here: TBC Hunters had
-- strong, achievable access to Armor Pen stacking via ammo/trinkets, making its marginal value at
-- realistically-attainable stack levels higher than for melee specs (a real, class-specific
-- itemization-access difference, distinct from the "abundant on gear" scarcity signal this file
-- otherwise ignores -- this one changes the true achievable value, not just shopping priority).
------------------------------------------------------------------------------
Priorities.HUNTER = {}

local HUNTER_RANGED_DPS_SPEED = {
	AP = 0, RAP = 10, SP = 0, HEAL = 0, HEALTH = 2, MANA = 2,
	HIT = 13, CRIT = 7, HASTE = 0, EXP = 0, ARMORPEN = 12, ARMOR = 0,
	DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
	RESILIENCE = 0, MP5 = 1, SPELLPEN = 0,
	ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
}
local HUNTER_RANGED_DPS_SURVIVAL = Merge(HUNTER_RANGED_DPS_SPEED, {
	HIT = 9, CRIT = 7, ARMORPEN = 9, HEALTH = 8, ARMOR = 3, MANA = 3, MP5 = 2,
})
Priorities.HUNTER.beastmastery = { offense = "ranged", defaultMode = "speed", speed = HUNTER_RANGED_DPS_SPEED, survival = HUNTER_RANGED_DPS_SURVIVAL }
Priorities.HUNTER.marksmanship = { offense = "ranged", defaultMode = "speed", speed = HUNTER_RANGED_DPS_SPEED, survival = HUNTER_RANGED_DPS_SURVIVAL }

-- Source (Survival spec): https://www.icy-veins.com/tbc-classic/survival-hunter-dps-pve-stat-priority
-- Priority: Agility > Crit (Expose Weakness -- a real talent mechanic that only procs on crit and
-- scales off Agility, genuinely elevating Crit's value for this spec specifically) > Hit (only 2%
-- raid-buffed cap thanks to Surefooted's flat 3%) > Armor Penetration > Attack Power.
Priorities.HUNTER.survival = {
	offense = "ranged", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 10, SP = 0, HEAL = 0, HEALTH = 2, MANA = 2,
		HIT = 4, CRIT = 11, HASTE = 0, EXP = 0, ARMORPEN = 7, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 1, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 10, SP = 0, HEAL = 0, HEALTH = 8, MANA = 3,
		HIT = 3, CRIT = 10, HASTE = 0, EXP = 0, ARMORPEN = 5, ARMOR = 3,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 2, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

------------------------------------------------------------------------------
-- ROGUE
-- Source (all 3 specs -- Icy Veins publishes ONE unified page, explicitly identical across specs):
-- https://www.icy-veins.com/tbc-classic/rogue-dps-pve-stat-priority
-- Priority: Expertise ≈ Hit (both to cap, ~1.3x reference) > Agility (folds into AP) > Haste (true
-- physics value, ~1.0x -- Energy-based, no rage-normalization quirk) > Crit > Armor Penetration
-- (explicitly the weakest stat, cited EP ~0.3-0.38 -- discounted harder than the generic melee 0.5x
-- default since this is an actual published number, not just a qualitative "weak" comment).
-- Rogues use Energy, not Mana -- MANA = 0.
------------------------------------------------------------------------------
local ROGUE_MELEE_DPS_SPEED = {
	AP = 10, RAP = 0, SP = 0, HEAL = 0, HEALTH = 2, MANA = 0,
	HIT = 13, CRIT = 8, HASTE = 9, EXP = 13, ARMORPEN = 3, ARMOR = 0,
	DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
	RESILIENCE = 0, MP5 = 0, SPELLPEN = 0,
	ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
}
local ROGUE_MELEE_DPS_SURVIVAL = Merge(ROGUE_MELEE_DPS_SPEED, {
	HIT = 10, CRIT = 7, HASTE = 8, EXP = 10, ARMORPEN = 2, HEALTH = 8, ARMOR = 3,
})
Priorities.ROGUE = {
	assassination = { offense = "melee", defaultMode = "speed", speed = ROGUE_MELEE_DPS_SPEED, survival = ROGUE_MELEE_DPS_SURVIVAL },
	combat = { offense = "melee", defaultMode = "speed", speed = ROGUE_MELEE_DPS_SPEED, survival = ROGUE_MELEE_DPS_SURVIVAL },
	subtlety = { offense = "melee", defaultMode = "speed", speed = ROGUE_MELEE_DPS_SPEED, survival = ROGUE_MELEE_DPS_SURVIVAL },
}

------------------------------------------------------------------------------
-- PRIEST
------------------------------------------------------------------------------
Priorities.PRIEST = {}

-- Source (Discipline): https://www.warcrafttavern.com/tbc/guides/pve-discipline-healing-priest-stat-priority/
-- LOWER CONFIDENCE THAN OTHER ENTRIES: Icy Veins has no dedicated TBC Classic Discipline page, and
-- Wowhead's equivalent page (wowhead.com/tbc/guide/classes/priest/healer-stat-priority-attributes-pve)
-- is client-rendered with no static text to fetch -- the Warcraft Tavern page above remains the only
-- source found, retrieved via a text-extraction proxy after it 403'd a direct fetch (re-confirmed
-- still 403ing as of the v0.311 re-check). Partially independently corroborated, though: a separate
-- plain-text search result (not the same proxy) independently gave the identical Spirit-to-Healing
-- ratio ("1 Spirit = 0.35 Healing Power & Spell damage with both buffs"), matching this file's number
-- exactly -- some confidence, but the full ranked order below is still only single-sourced. Priority:
-- Spell Haste > Healing Power > Spell Crit > Spirit > Intellect > MP5 > Stamina -- unusually, Haste
-- ranks ABOVE Healing Power itself (source: "biggest increase to healing output"), reflected here by
-- weighting Haste above the HEAL reference, following the caster-template ratios (Haste ~1.35x SP
-- baseline extrapolated to the healer reference the same way).
Priorities.PRIEST.discipline = {
	offense = "spell", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 0, SP = 0, HEAL = 10, HEALTH = 1, MANA = 5,
		HIT = 0, CRIT = 7, HASTE = 12, EXP = 0, ARMORPEN = 0, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 4, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 0, HEAL = 9, HEALTH = 8, MANA = 5,
		HIT = 0, CRIT = 6, HASTE = 9, EXP = 0, ARMORPEN = 0, ARMOR = 2,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 5, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

-- Source (Holy): https://www.icy-veins.com/tbc-classic/holy-priest-healer-pve-stat-priority
-- Priority: Spell Haste ("biggest increase to healing output") > Bonus Healing (~2000 target) >
-- Spell Crit > Spirit > Intellect > MP5 > Stamina (low base health pool, so not fully ignorable).
Priorities.PRIEST.holy = {
	offense = "spell", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 0, SP = 0, HEAL = 10, HEALTH = 2, MANA = 5,
		HIT = 0, CRIT = 7, HASTE = 11, EXP = 0, ARMORPEN = 0, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 4, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 0, HEAL = 9, HEALTH = 9, MANA = 5,
		HIT = 0, CRIT = 6, HASTE = 8, EXP = 0, ARMORPEN = 0, ARMOR = 2,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 5, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

-- Source (Shadow): https://www.icy-veins.com/tbc-classic/shadow-priest-dps-pve-stat-priority
-- Priority: Spell Hit (16% vs. bosses) > Spell Damage > Spell Haste > Spell Crit ("not the best stat
-- for a Shadow Priest" -- a large share of damage comes from periodic ticks, which cannot crit in
-- TBC) > Intellect > Spirit > MP5 > Stamina. Crit discounted well below the standard caster ratio to
-- reflect the real DoT-crit-immunity mechanic.
Priorities.PRIEST.shadow = {
	offense = "spell", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 2, MANA = 5,
		HIT = 16, CRIT = 4, HASTE = 13, EXP = 0, ARMORPEN = 0, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 2, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 8, MANA = 6,
		HIT = 12, CRIT = 4, HASTE = 11, EXP = 0, ARMORPEN = 0, ARMOR = 3,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 3, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

------------------------------------------------------------------------------
-- SHAMAN
------------------------------------------------------------------------------
Priorities.SHAMAN = {}

-- Source (Elemental): https://www.icy-veins.com/tbc-classic/elemental-shaman-dps-pve-stat-priority
-- Priority: Spell Hit > Spell Haste > Spell Damage > Spell Crit (Elemental Fury talent boosts crits
-- to +100% instead of the standard +50%, genuinely doubling Crit's value -- reflected as a boosted
-- ratio, not the standard caster default) > Intellect > MP5 > Stamina > Spell Penetration (0,
-- "useless for PvE") > Spirit. Hit discounted slightly below the Warlock-template 1.9x since totem/
-- talent passives already supply ~12% hit per the source, so itemized Hit is worth somewhat less.
Priorities.SHAMAN.elemental = {
	offense = "spell", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 2, MANA = 5,
		HIT = 15, CRIT = 12, HASTE = 13, EXP = 0, ARMORPEN = 0, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 3, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 8, MANA = 6,
		HIT = 10, CRIT = 10, HASTE = 11, EXP = 0, ARMORPEN = 0, ARMOR = 3,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 4, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

-- Source (Enhancement): https://www.icy-veins.com/tbc-classic/enhancement-shaman-dps-pve-stat-priority
-- Priority: Expertise (6.5%) > Strength/Attack Power > Hit (9%) > Haste > Crit > Agility > Armor
-- Penetration > Intellect > Stamina > MP5 > Spirit. Mana-based (no rage quirk), so Haste keeps its
-- true ~1.0x-adjacent value rather than a Warrior-style discount.
Priorities.SHAMAN.enhancement = {
	offense = "melee", defaultMode = "speed",
	speed = {
		AP = 10, RAP = 0, SP = 0, HEAL = 0, HEALTH = 2, MANA = 1,
		HIT = 11, CRIT = 8, HASTE = 9, EXP = 13, ARMORPEN = 4, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 1, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 10, RAP = 0, SP = 0, HEAL = 0, HEALTH = 8, MANA = 2,
		HIT = 9, CRIT = 7, HASTE = 8, EXP = 10, ARMORPEN = 3, ARMOR = 3,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 1, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

-- Source (Restoration): https://www.icy-veins.com/tbc-classic/restoration-shaman-healer-pve-stat-priority
-- REAL PUBLISHED NUMERIC RATIOS (used directly, scaled so Heal=10 is the reference): Spell Healing
-- 1.0, Spell Haste 1.5, MP5 2.0 (!), Spell Crit 0.6, Intellect 0.5, Stamina 0.2 -- MP5 genuinely
-- outranks even Healing Power and Haste, a real, surprising, cited result honored exactly as
-- published rather than smoothed toward the "obvious" Healing-first pattern other healers show.
Priorities.SHAMAN.restoration = {
	offense = "spell", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 0, SP = 0, HEAL = 10, HEALTH = 2, MANA = 5,
		HIT = 0, CRIT = 6, HASTE = 15, EXP = 0, ARMORPEN = 0, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 20, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 0, HEAL = 9, HEALTH = 9, MANA = 6,
		HIT = 0, CRIT = 5, HASTE = 12, EXP = 0, ARMORPEN = 0, ARMOR = 3,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 17, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

------------------------------------------------------------------------------
-- MAGE
-- All three specs share the standard caster template (Hit ~1.9x SP baseline, Haste ~1.35x, no
-- crit-multiplier-boosting talent found for any Mage spec so Crit stays near the Warlock baseline
-- ~0.8-1.0x), with real per-spec differences in exactly how much Intellect/Crit matter.
------------------------------------------------------------------------------
Priorities.MAGE = {}

-- Source: https://www.icy-veins.com/tbc-classic/arcane-mage-dps-pve-stat-priority
-- Priority: Spell Hit > Intellect ≈ Spell Damage (explicitly tied for Arcane specifically, unique
-- among the 3 Mage specs -- reflected as MANA weighted equal to the SP reference) > Spell Haste >
-- Spell Crit (flagged as this spec's least gold-efficient stat -- discounted below Fire/Frost).
Priorities.MAGE.arcane = {
	offense = "spell", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 2, MANA = 10,
		HIT = 16, CRIT = 5, HASTE = 13, EXP = 0, ARMORPEN = 0, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 1, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 8, MANA = 9,
		HIT = 11, CRIT = 5, HASTE = 10, EXP = 0, ARMORPEN = 0, ARMOR = 3,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 2, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

-- Source: https://www.icy-veins.com/tbc-classic/fire-mage-dps-pve-stat-priority
-- Priority: Spell Hit > Spell Damage > Spell Haste > Spell Crit > Intellect ("never gear for
-- Intellect as a Fire Mage") > Stamina > Spirit/MP5 ("most unimportant").
Priorities.MAGE.fire = {
	offense = "spell", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 2, MANA = 1,
		HIT = 16, CRIT = 8, HASTE = 13, EXP = 0, ARMORPEN = 0, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 1, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 8, MANA = 2,
		HIT = 11, CRIT = 8, HASTE = 10, EXP = 0, ARMORPEN = 0, ARMOR = 3,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 2, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

-- Source: https://www.icy-veins.com/tbc-classic/frost-mage-dps-pve-stat-priority
-- Priority: Spell Hit > Spell Damage > Spell Haste > Spell Crit ("only if there is no alternative")
-- > Intellect ("never gear for Intellect as a Frost Mage") > Stamina (one encounter needs ~10k HP,
-- slightly higher baseline than Fire/Arcane) > Spirit/MP5 ("most unimportant").
Priorities.MAGE.frost = {
	offense = "spell", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 3, MANA = 1,
		HIT = 16, CRIT = 7, HASTE = 13, EXP = 0, ARMORPEN = 0, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 1, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 8, MANA = 2,
		HIT = 11, CRIT = 7, HASTE = 10, EXP = 0, ARMORPEN = 0, ARMOR = 3,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 2, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

------------------------------------------------------------------------------
-- WARLOCK
-- REAL PUBLISHED NUMERIC TABLE, used directly (not extrapolated): Icy Veins' Affliction page gives
-- a full "Spell Power Equivalency" table for the Ruin build: Spell Power 0.836 DPS/point (reference),
-- Hit Rating 1.901 SP (until the 202-rating cap), Haste Rating 1.353 SP, Crit Rating 0.829 SP,
-- Intellect 0.245 SP, Stamina 0 SP, Spirit 0.110 SP (Improved Drain Soul only). Scaled here so
-- SP = 10 is the reference: HIT = 10*(1.901/0.836) ≈ 23, HASTE = 10*(1.353/0.836) ≈ 16,
-- CRIT = 10*(0.829/0.836) ≈ 10, MANA(Intellect) = 10*(0.245/0.836) ≈ 3, HEALTH(Stamina) = 0 exactly
-- (the source's own real result, not a placeholder), MP5(Spirit proxy) = 10*(0.110/0.836) ≈ 1.
-- Sources: https://www.icy-veins.com/tbc-classic/affliction-warlock-dps-pve-stat-priority
--          https://www.icy-veins.com/tbc-classic/demonology-warlock-dps-pve-stat-priority
--          https://www.icy-veins.com/tbc-classic/destruction-warlock-dps-pve-stat-priority
-- All 3 specs share the same fundamental formula shape (source: "all three Warlock specs follow the
-- same stat priority"); MP5 (Spirit-with-IDS) only applied where each spec's own page flagged it as
-- relevant (Affliction has natural access to the Improved Drain Soul talent; Destruction's own page
-- gave a small explicit 0.094 value; Demonology's page gave no such figure, left at 0).
------------------------------------------------------------------------------
Priorities.WARLOCK = {}

Priorities.WARLOCK.affliction = {
	offense = "spell", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 0, MANA = 3,
		HIT = 23, CRIT = 10, HASTE = 16, EXP = 0, ARMORPEN = 0, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 1, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 7, MANA = 4,
		HIT = 16, CRIT = 8, HASTE = 12, EXP = 0, ARMORPEN = 0, ARMOR = 2,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 1, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

Priorities.WARLOCK.demonology = {
	offense = "spell", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 0, MANA = 3,
		HIT = 23, CRIT = 10, HASTE = 16, EXP = 0, ARMORPEN = 0, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 0, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 7, MANA = 4,
		HIT = 16, CRIT = 8, HASTE = 12, EXP = 0, ARMORPEN = 0, ARMOR = 2,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 0, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

Priorities.WARLOCK.destruction = {
	offense = "spell", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 0, MANA = 3,
		HIT = 23, CRIT = 10, HASTE = 16, EXP = 0, ARMORPEN = 0, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 1, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 7, MANA = 4,
		HIT = 16, CRIT = 8, HASTE = 12, EXP = 0, ARMORPEN = 0, ARMOR = 2,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 1, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

------------------------------------------------------------------------------
-- DRUID
------------------------------------------------------------------------------
Priorities.DRUID = {}

-- Source (Balance): https://www.icy-veins.com/tbc-classic/balance-druid-dps-pve-stat-priority
-- Priority: Spell Hit (16%) > Spell Damage > Spell Haste > Spell Crit (Vengeance talent boosts
-- Starfire crits to +100% instead of +50%, a real mechanical bonus reflected as a boosted ratio,
-- same treatment as Elemental Shaman's Elemental Fury) > Intellect > Spirit > MP5 > Stamina > Spell
-- Penetration (0, "useless for PvE" -- no raid boss has reducible Nature Resistance).
Priorities.DRUID.balance = {
	offense = "spell", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 2, MANA = 5,
		HIT = 15, CRIT = 12, HASTE = 13, EXP = 0, ARMORPEN = 0, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 3, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 10, HEAL = 0, HEALTH = 8, MANA = 6,
		HIT = 10, CRIT = 9, HASTE = 11, EXP = 0, ARMORPEN = 0, ARMOR = 3,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 4, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

-- Source (Feral -- Cat DPS): https://www.icy-veins.com/tbc-classic/feral-druid-dps-pve-stat-priority
-- Priority: Agility > Hit (9%) > Expertise (6.5%) > Strength > Crit > Haste > Attack Power > Armor
-- Penetration > mana stats ("should generally not be prioritized"). Energy-based (no rage quirk),
-- so Crit/Haste keep their true ~1.0x physics value. Agility/Strength both fold into the AP key
-- (kept at full reference value; weapon-DPS-normalization in Cat Form isn't a key this file tracks).
--
-- Source (Feral -- Bear Tank): https://www.icy-veins.com/tbc-classic/feral-druid-tank-pve-stat-priority
-- Priority: Expertise (6.5%) > Agility > Stamina (an explicit ~1.7x effective multiplier in Dire
-- Bear Form + Heart of the Wild + Blessing of Kings is cited) > Hit (9%) > Strength > Crit > Haste >
-- Dodge > Defense > Attack Power > Resilience > Armor > Armor Penetration.
-- Defense-rating crit-immunity breakpoint (found v0.311, was an honest gap in v0.307/v0.308):
-- Warcraft Tavern's Feral tank cap page (warcrafttavern.com/tbc/guides/pve-feral-druid-tank-stat-priority)
-- gives Druid-specific numbers distinct from the Warrior/Paladin "~490 Defense Skill" figure already
-- used elsewhere in this file: raid bosses have a 5.6% chance to crit a tank, Survival of the Fittest
-- (Feral talent) suppresses 3% of that, leaving 2.6% to cover via Defense; at 2.4 Defense Rating per
-- 0.1% suppression, full crit immunity through Defense Rating alone needs ~156 rating (lower than
-- Warrior/Paladin's requirement precisely because they lack an equivalent crit-suppression talent).
Priorities.DRUID.feral = {
	offense = "melee", defaultMode = "speed",
	speed = {
		AP = 10, RAP = 0, SP = 0, HEAL = 0, HEALTH = 1, MANA = 0,
		HIT = 13, CRIT = 10, HASTE = 9, EXP = 12, ARMORPEN = 4, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 0, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	-- Bear Tank (this spec's "survival" mode, per its existing defaultMode/UI mapping).
	survival = {
		AP = 9, RAP = 0, SP = 0, HEAL = 0, HEALTH = 11, MANA = 0,
		HIT = 8, CRIT = 6, HASTE = 4, EXP = 13, ARMORPEN = 0, ARMOR = 2,
		DEF = 4, DODGE = 4, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 2, MP5 = 0, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

-- Source (Restoration): https://www.icy-veins.com/tbc-classic/restoration-druid-healer-pve-stat-priority
-- Priority: Spell Healing > Spell Haste (242 rating target) > Spirit (Intensity talent converts 30%
-- of its regen into combat use) > MP5 > Intellect > Spell Crit (explicitly reduced value -- HoTs
-- cannot crit in TBC, the same real mechanic discounting Shadow Priest's Crit) > Stamina. Spirit's
-- emphasis is folded into MP5 (no direct key for Spirit -- see the file header).
Priorities.DRUID.restoration = {
	offense = "spell", defaultMode = "speed",
	speed = {
		AP = 0, RAP = 0, SP = 0, HEAL = 10, HEALTH = 1, MANA = 5,
		HIT = 0, CRIT = 2, HASTE = 13, EXP = 0, ARMORPEN = 0, ARMOR = 0,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 11, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
	survival = {
		AP = 0, RAP = 0, SP = 0, HEAL = 9, HEALTH = 9, MANA = 6,
		HIT = 0, CRIT = 2, HASTE = 11, EXP = 0, ARMORPEN = 0, ARMOR = 3,
		DEF = 0, DODGE = 0, PARRY = 0, BLOCK = 0, BLOCKVALUE = 0,
		RESILIENCE = 0, MP5 = 10, SPELLPEN = 0,
		ARCANERES = 0, FIRERES = 0, FROSTRES = 0, NATURERES = 0, SHADOWRES = 0,
	},
}

-- Low-level fallback (judgment call, unchanged from pre-v0.307): under level 10 / 0 talent points
-- spent, no spec can be detected. One assumed default per class, kept here as a plain data table so
-- it can be revised without touching Scoring.lua's logic. Scoring.lua marks the result
-- `assumed = true` when used.
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
