-- Leveling Gears -- Weights.lua
-- The list of weightable derived stats, the 0.05-precision weight math, and the character's single
-- weight-set data logic (seed defaults, hand-adjust, restore defaults). No UI widgets are touched
-- here -- see UI.lua, which owns the actual weight-label widgets and calls into this file's
-- formatting/rounding.

local _, LG = ...
LG.Weights = LG.Weights or {}
local Weights = LG.Weights

local PrintChat = LG.Debug.PrintChat
local SafeCall = LG.Debug.SafeCall

-- The full list of weightable derived stats (v0.25+): primaries (STR/AGI/STA/INT/SPI) are
-- intentionally absent -- the scoring engine (Conversions.lua/Scoring.lua) folds them into these
-- before any weight is ever applied, which is what prevents double-counting. See DESIGN.md.
Weights.statDefinitions = {
	{ key = "SP", name = "Spell Power" },
	{ key = "HEAL", name = "Healing" },
	{ key = "AP", name = "Attack Power" },
	{ key = "RAP", name = "Ranged Attack Power" },
	{ key = "HEALTH", name = "Health" },
	{ key = "MANA", name = "Mana" },
	{ key = "HIT", name = "Hit Rating" },
	{ key = "CRIT", name = "Crit Rating" },
	{ key = "HASTE", name = "Haste Rating" },
	{ key = "EXP", name = "Expertise Rating" },
	{ key = "ARMORPEN", name = "Armor Penetration" },
	{ key = "ARMOR", name = "Armor" },
	{ key = "DEF", name = "Defense Rating" },
	{ key = "DODGE", name = "Dodge Rating" },
	{ key = "PARRY", name = "Parry Rating" },
	{ key = "BLOCK", name = "Block Rating" },
	{ key = "BLOCKVALUE", name = "Block Value" },
	{ key = "RESILIENCE", name = "Resilience" },
	{ key = "MP5", name = "MP5" },
	{ key = "SPELLPEN", name = "Spell Penetration" },
	{ key = "ARCANERES", name = "Arcane Resistance" },
	{ key = "FIRERES", name = "Fire Resistance" },
	{ key = "FROSTRES", name = "Frost Resistance" },
	{ key = "NATURERES", name = "Nature Resistance" },
	{ key = "SHADOWRES", name = "Shadow Resistance" },
}

-- Weights are shown on a simple 0-10 bar but move in fine 0.05 steps (v0.26); WEIGHT_STEP is the
-- one place to change if even finer precision is ever wanted later.
Weights.WEIGHT_MIN = 0
Weights.WEIGHT_MAX = 10
Weights.WEIGHT_STEP = 0.05

function Weights.RoundToStep(value, step)
	return math.floor((value / step) + 0.5) * step
end

-- Keep the display simple even at 0.05 precision: whole numbers show with no decimals ("5"),
-- fractional values show only as many decimals as the step ever produces (never a trailing zero).
function Weights.FormatWeight(value)
	local rounded = Weights.RoundToStep(value, Weights.WEIGHT_STEP)
	if rounded == math.floor(rounded) then
		return string.format("%d", rounded)
	end
	local text = string.format("%.2f", rounded)
	if text:sub(-1) == "0" then
		text = text:sub(1, -2)
	end
	return text
end

-- Look up the character's spec-aware default weights (v0.25 scoring engine), or nil if it can't
-- be resolved -- callers fall back to a flat 5 in that case.
local function GetSpecDefaults()
	if not LG.Scoring then
		return nil
	end
	local success, result = SafeCall(function()
		return LG.Scoring:GetDefaultWeights()
	end)
	if success then
		return result
	end
	return nil
end

-- Ensure the character has a complete set of weight values before the UI is refreshed. A missing
-- value is seeded from the character's detected spec/mode default when available, or a flat 5
-- otherwise -- these are only ever SEED values: they fill a gap once and never overwrite a weight
-- the player has already set or hand-adjusted afterward, and never re-seed on their own if the
-- player's spec later changes (see ROADMAP.md for the planned follow-up).
function Weights.EnsureWeights()
	local characterState = LG.Settings.GetCharacterState()
	characterState.weights = characterState.weights or {}

	local defaults = GetSpecDefaults()
	for _, stat in ipairs(Weights.statDefinitions) do
		if characterState.weights[stat.key] == nil then
			characterState.weights[stat.key] = (defaults and defaults[stat.key]) or 5
		end
	end
end

-- Update a single weight value. delta is normally +-WEIGHT_STEP (0.05); the settings UI passes a
-- coarser +-1 on Shift-click so a value can still be moved across the whole bar quickly. Updates
-- only the one changed label (via LG.UI.SetWeightLabelText) and debounces the gear-evaluation
-- refresh (LG.GearEvaluation.ScheduleGearEvaluation) rather than doing a full, immediate refresh --
-- a full RefreshWeightLabels() pass on every click reintroduced the multi-jump bug from #20/#21.
function Weights.SetWeight(statKey, delta)
	Weights.EnsureWeights()
	local characterState = LG.Settings.GetCharacterState()
	local newValue = Weights.RoundToStep((characterState.weights[statKey] or 5) + delta, Weights.WEIGHT_STEP)
	if newValue < Weights.WEIGHT_MIN then
		newValue = Weights.WEIGHT_MIN
	elseif newValue > Weights.WEIGHT_MAX then
		newValue = Weights.WEIGHT_MAX
	end
	characterState.weights[statKey] = newValue

	if LG.UI and LG.UI.SetWeightLabelText then
		LG.UI.SetWeightLabelText(statKey, Weights.FormatWeight(newValue))
	end
	if LG.GearEvaluation then
		LG.GearEvaluation.ScheduleGearEvaluation()
	end
end

-- Overwrite every one of the character's weights with their detected spec/mode default, replacing
-- any hand-adjustment -- the explicit "undo my changes" action, distinct from EnsureWeights, which
-- only ever fills a never-touched key. This is also the only way defaults update after a respec or
-- talent change today (see ROADMAP.md for the planned automatic follow-up).
function Weights.RestoreDefaultWeights()
	local characterState = LG.Settings.GetCharacterState()
	local defaults = GetSpecDefaults()

	characterState.weights = {}
	for _, stat in ipairs(Weights.statDefinitions) do
		characterState.weights[stat.key] = (defaults and defaults[stat.key]) or 5
	end

	if LG.UI and LG.UI.RefreshWeightLabels then
		LG.UI.RefreshWeightLabels()
	end

	local description
	if LG.Scoring then
		local success, result = SafeCall(function()
			return LG.Scoring:DescribeCurrentSpec()
		end)
		if success then
			description = result
		end
	end
	PrintChat("Restored default weights" .. (description and (" for " .. description) or "") .. ".")
end
