-- Leveling Gears -- Core.lua
-- The addon's entry point: loads last (see LevelingGears.toc), after every other module has
-- registered itself on the shared LG namespace. Owns only what's genuinely "core": slash-command
-- dispatch and the startup sequence that ties the other modules together. Everything else --
-- logging (Debug.lua), SavedVariables/profile data (Settings.lua), weight math (Weights.lua),
-- the scoring engine (Conversions.lua/Priorities.lua/Scoring.lua), equipped-gear evaluation
-- (GearEvaluation.lua), and the settings window (UI.lua) -- lives in its own file.

local _, LG = ...

local PrintChat = LG.Debug.PrintChat
local SafeCall = LG.Debug.SafeCall

-- Debug bench for the v0.25 scoring engine: prints the derived-stat breakdown and final score for
-- a shift-clicked item link, scored strictly against Priorities.lua's authored table (not the
-- player's own hand-adjusted weights), so the priority tables themselves can be sanity-checked
-- independent of any customization. Bug #30's real fix (per the author: shift+left-click an
-- equipped item instead) lives in `GearEvaluation.lua` and uses the player's live profile weights
-- via the same `Scoring:PrintBreakdown` this command calls -- this command remains as the
-- debug-bench fallback for checking the raw priority tables, per DESIGN.md.
local function HandleScoreCommand(argText)
	local itemLink = argText:gsub("^%s+", ""):gsub("%s+$", "")
	if itemLink == "" then
		PrintChat("Usage: type /lgs score , then (in that SAME line, before pressing Enter) shift-click an item, then press Enter. For everyday use, shift+left-click an equipped item instead.")
		return
	end

	local itemStats = GetItemStats(itemLink)
	if not itemStats or not next(itemStats) then
		LG.Debug.WriteDebugLog("HandleScoreCommand: GetItemStats returned " ..
			(itemStats and "an empty table" or "nil") .. " for '" .. itemLink .. "'", 1)
		PrintChat("Could not read item stats for that link (item may not be cached yet -- try again in a moment).")
		return
	end

	local class, specKey, mode = LG.Scoring:DetectSpec()
	local score, breakdown = LG.Scoring:ScoreItem(itemStats, class, specKey, mode)
	LG.Scoring:PrintBreakdown(itemLink, score, breakdown, LG.Scoring:DescribeCurrentSpec())
end

-- Slash commands are intentionally limited to the two primary entry points so the addon stays easy
-- to explain (the /lg alias was deliberately removed, see bug #5 in known-bugs.md) -- "score" is a
-- subcommand of /lgs and /levelinggears, not a new top-level command.
local function HandleSlashCommand(msg)
	local original = msg or ""

	-- Checked against the ORIGINAL casing, before the lowercasing below: an item link's |H/|h
	-- escape pair is case-sensitive, and lowercasing the whole message would corrupt any pasted
	-- item link and break GetItemStats on it.
	local scoreArg = original:match("^%s*[Ss][Cc][Oo][Rr][Ee]%s+(.+)$")
	if scoreArg then
		SafeCall(function()
			HandleScoreCommand(scoreArg)
		end)
		return
	end

	local msgLower = original:lower()
	if msgLower == "debug dump" then
		LG.Debug.DumpDebugLog()
		return
	end
	local level = tonumber(msgLower:match("debug (%d+)"))
	if msgLower == "debug" or level then
		LG.Debug.ToggleDebugMode(level or 1)
	else
		LG.UI.ToggleLevelingGears()
	end
end

-- Initialize the profile state on load so the settings page reflects the saved character data and
-- current defaults. Relies on LevelingGearsDB.general already existing (Debug.lua/Settings.lua,
-- both loaded earlier, guard it themselves).
local function InitializeProfileState()
	local activeProfile = LG.Settings.GetActiveProfile()
	LG.Weights.EnsureWeights()
	LG.UI.RefreshGeneralSettingsUI()
	LG.UI.RefreshProfileList()
	LG.UI.RefreshWeightLabels()
	if not LevelingGearsDB.general.bootMessageShown then
		PrintChat("Loaded.")
		PrintChat("Type /levelinggears or /lgs to open settings.")
		LevelingGearsDB.general.bootMessageShown = true
	end
	if activeProfile then
		PrintChat("Loaded profile '" .. activeProfile.name .. "'.")
	end
end

-- The addon exposes only the two primary entry points so the command surface stays simple for players.
SLASH_LEVELINGGEARS1 = "/levelinggears"
SLASH_LEVELINGGEARS2 = "/lgs"
SlashCmdList["LEVELINGGEARS"] = HandleSlashCommand

SafeCall(InitializeProfileState)
SafeCall(LG.GearEvaluation.UpdateEquippedGearEvaluation)
