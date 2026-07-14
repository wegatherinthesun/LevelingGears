-- Leveling Gears -- Settings.lua
-- The SavedVariables data layer for account-wide general settings and per-character profiles:
-- reading/writing LevelingGearsDB, and profile CRUD. No UI widgets are created or touched here --
-- see UI.lua for that; this file calls a small set of LG.UI.* refresh hooks after mutating data so
-- the settings page stays in sync with whatever changed.

local _, LG = ...
LG.Settings = LG.Settings or {}
local Settings = LG.Settings

local PrintChat = LG.Debug.PrintChat

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

-- Character-scoped data is keyed by character name plus realm so each alt keeps its own profile state.
function Settings.GetCharacterKey()
	local name = UnitName("player") or "Unknown"
	local realm = GetRealmName() or "Unknown"
	return name .. " - " .. realm
end

function Settings.GetCharacterState()
	local key = Settings.GetCharacterKey()
	LevelingGearsDB.characters[key] = LevelingGearsDB.characters[key] or {
		activeProfile = nil,
		profiles = {},
	}
	return LevelingGearsDB.characters[key]
end

function Settings.GetActiveProfile()
	local characterState = Settings.GetCharacterState()
	local profiles = characterState.profiles or {}
	if characterState.activeProfile and profiles[characterState.activeProfile] then
		return profiles[characterState.activeProfile]
	end

	if not next(profiles) then
		local defaultProfile = {
			id = "default",
			name = "Default",
			spec = nil,
			weights = {},
		}
		profiles[defaultProfile.id] = defaultProfile
		characterState.profiles = profiles
		characterState.activeProfile = defaultProfile.id
		return defaultProfile
	end

	for _, profile in pairs(profiles) do
		characterState.activeProfile = profile.id
		return profile
	end

	return nil
end

-- Refresh the two UI surfaces that always need to reflect the active profile after it changes.
local function RefreshProfileDependentUI()
	if not LG.UI then
		return
	end
	if LG.UI.RefreshWeightLabels then
		LG.UI.RefreshWeightLabels()
	end
	if LG.UI.RefreshProfileList then
		LG.UI.RefreshProfileList()
	end
end

-- Switch the active profile for the current character and update the visible weight controls immediately.
function Settings.SetActiveProfile(profileId)
	local characterState = Settings.GetCharacterState()
	local profile = characterState.profiles and characterState.profiles[profileId]
	if not profile then
		return
	end

	characterState.activeProfile = profileId
	if LG.Weights then
		LG.Weights.EnsureWeights()
	end
	RefreshProfileDependentUI()
	PrintChat("Switched to profile '" .. profile.name .. "'.")
end

-- Create a new profile entry and seed it with default weight values so editing can start immediately.
function Settings.CreateProfile(name)
	local characterState = Settings.GetCharacterState()
	local profiles = characterState.profiles or {}
	local trimmedName = (name or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if trimmedName == "" then
		trimmedName = "New Profile"
	end

	local profileCount = 0
	for _ in pairs(profiles) do
		profileCount = profileCount + 1
	end

	local profileId = "profile" .. tostring(profileCount + 1)
	local profile = {
		id = profileId,
		name = trimmedName,
		spec = nil,
		weights = {},
	}
	profiles[profileId] = profile
	characterState.profiles = profiles
	characterState.activeProfile = profileId
	if LG.Weights then
		LG.Weights.EnsureWeights()
	end
	RefreshProfileDependentUI()
	PrintChat("Created profile '" .. profile.name .. "'.")
end
