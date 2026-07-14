-- Leveling Gears -- Settings.lua
-- The SavedVariables data layer for account-wide general settings and each character's single set
-- of stat weights: reading/writing LevelingGearsDB. No UI widgets are created or touched here --
-- see UI.lua for that; this file calls a small set of LG.UI.* refresh hooks after mutating data so
-- the settings page stays in sync with whatever changed.
--
-- v0.304 fork: replaced the earlier multi-profile system (create/switch/name profiles per
-- character) with exactly one weight set per character, hand-adjustable or restorable to spec
-- defaults, but never named or duplicated. The old system was a source of repeated real bugs
-- (see bugs/known-bugs.md #28 and the confusing "which profile am I even on" reports it kept
-- generating) for a level of flexibility nothing in this addon's design actually needed.

local _, LG = ...
LG.Settings = LG.Settings or {}
local Settings = LG.Settings

LevelingGearsDB = LevelingGearsDB or {}
LevelingGearsDB.general = LevelingGearsDB.general or {}
LevelingGearsDB.characters = LevelingGearsDB.characters or {}

-- Global addon settings live in the shared SavedVariable table and are not tied to a single character.
function Settings.GetGeneralSettings()
	LevelingGearsDB.general = LevelingGearsDB.general or {}
	return LevelingGearsDB.general
end

function Settings.SetMinimapEnabled(visible)
	local settings = Settings.GetGeneralSettings()
	settings.minimapEnabled = visible
	if LG.UI and LG.UI.SetMinimapButtonShown then
		LG.UI.SetMinimapButtonShown(visible)
	end
end

-- Character-scoped data is keyed by character name plus realm so each alt keeps its own weight state.
function Settings.GetCharacterKey()
	local name = UnitName("player") or "Unknown"
	local realm = GetRealmName() or "Unknown"
	return name .. " - " .. realm
end

-- One flat weight set per character -- no names, no create/switch. `characterState.weights` is
-- the single source of truth every other module reads and writes.
function Settings.GetCharacterState()
	local key = Settings.GetCharacterKey()
	local characterState = LevelingGearsDB.characters[key]
	if not characterState then
		characterState = { weights = {} }
		LevelingGearsDB.characters[key] = characterState
	elseif not characterState.weights then
		-- Migrate from the pre-fork multi-profile format: carry the previously active profile's
		-- weights over once so a hand-tuned character doesn't lose its work to this simplification.
		-- The old `profiles`/`activeProfile` fields are left in place, unused -- harmless dead data,
		-- same policy this project already uses for other retired SavedVariables fields.
		local oldProfiles = characterState.profiles
		local oldActive = oldProfiles and characterState.activeProfile and oldProfiles[characterState.activeProfile]
		characterState.weights = (oldActive and oldActive.weights) or {}
	end
	return characterState
end
