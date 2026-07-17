-- Leveling Gears -- Weights.lua
-- The list of weightable derived stats and the character's single weight-set data logic (seed
-- defaults, hand-adjust via direct entry, restore defaults). No UI widgets are touched here -- see
-- UI.lua, which owns the actual weight-input widgets and calls into this file's formatting.

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

-- Weights are typed directly into an edit box (v0.305 -- see bugs/known-bugs.md #32) showing the
-- exact number the scoring engine multiplies a derived stat by (`ComputeScore` in Scoring.lua does
-- `score = score + derivedStatValue * weight` -- there is no separate "real" value hidden behind an
-- abstracted 0-10 rating; the number in the box IS the weight). v0.306 removed the artificial 0-10
-- ceiling this used to enforce -- see bugs/known-bugs.md #33. T23/T24 (v0.384 test pass) reintroduced
-- a real bound -- 0-20, rounded to the nearest tenth -- since unbounded/negative input had no warning
-- at all; see ValidateWeightInput below.

-- A typed weight must land in this range -- anything outside it is rejected outright (with an
-- explanation shown to the player -- see UI.lua's CommitValue), not silently clamped into range.
Weights.MIN_WEIGHT = 0
Weights.MAX_WEIGHT = 20

-- Validates a parsed (already tonumber'd) weight input and rounds it to the nearest tenth. Returns
-- the rounded value on success, or nil plus a human-readable reason on failure -- callers show that
-- reason to the player (a rejected edit is never a silent revert, per the T23/T24 tester report).
function Weights.ValidateWeightInput(statName, parsed)
	if not parsed then
		return nil, string.format("%s must be a number.", statName)
	end
	if parsed < Weights.MIN_WEIGHT or parsed > Weights.MAX_WEIGHT then
		return nil, string.format("%s must be between %d and %d.", statName, Weights.MIN_WEIGHT, Weights.MAX_WEIGHT)
	end
	return math.floor((parsed * 10) + 0.5) / 10
end

-- Rounds to the nearest hundredth purely to hide floating-point noise (e.g. 7.099999999996) --
-- NOT a step grid the player is restricted to; any value they type is honored as-is once rounded to
-- this display precision. Whole numbers show with no decimals ("5"), fractional values show only as
-- many decimals as they need (never a trailing zero).
function Weights.FormatWeight(value)
	local rounded = math.floor((value * 100) + 0.5) / 100
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

-- Set a single weight to the exact value typed directly into its edit box -- no clamping, no
-- rescaling; this is the literal number ComputeScore multiplies the derived stat by from now on.
-- Updates only the one changed input (via LG.UI.SetWeightLabelText) and debounces the
-- gear-evaluation refresh (LG.GearEvaluation.ScheduleGearEvaluation) rather than doing a full,
-- immediate refresh -- a full RefreshWeightLabels() pass on every edit reintroduced the multi-jump
-- bug from #20/#21 back when weights changed via rapid-fire +/- clicks; direct entry is naturally
-- one commit per stat, but the same debounce is kept since nothing about that risk has changed.
function Weights.SetWeightValue(statKey, value)
	Weights.EnsureWeights()
	local characterState = LG.Settings.GetCharacterState()
	characterState.weights[statKey] = value

	if LG.UI and LG.UI.SetWeightLabelText then
		LG.UI.SetWeightLabelText(statKey, Weights.FormatWeight(value))
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
