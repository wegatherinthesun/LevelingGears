-- Leveling Gears -- Core.lua
-- First full wow addon created by We Gather in the Sun! Helio is the sole worker and coder at
-- We Gather in the Sun. I hope you enjoy it, and that there will be more to come!
-- Contact the developer at wegatherinthesun@gmail.com
-- The addon's entry point: loads last (see LevelingGears.toc), after every other module has
-- registered itself on the shared LG namespace. Owns only what's genuinely "core": slash-command
-- dispatch and the startup sequence that ties the other modules together. Everything else --
-- logging (Debug.lua), SavedVariables/character data (Settings.lua), weight math (Weights.lua),
-- the scoring engine (Conversions.lua/Priorities.lua/Scoring.lua), equipped-gear evaluation
-- (GearEvaluation.lua), and the settings window (UI.lua) -- lives in its own file.

local _, LG = ...

local PrintChat = LG.Debug.PrintChat
local SafeCall = LG.Debug.SafeCall

-- Debug bench for the v0.25 scoring engine: prints the derived-stat breakdown and final score for
-- a shift-clicked item link, scored strictly against Priorities.lua's authored table (not the
-- player's own hand-adjusted weights), so the priority tables themselves can be sanity-checked
-- independent of any customization. Bug #30's real fix (shift+left-click an equipped item instead)
-- lives in `GearEvaluation.lua` and uses the character's own live weights via the same
-- `Scoring:PrintBreakdown` this command calls -- this command remains as the debug-bench fallback
-- for checking the raw priority tables, per DESIGN.md.
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
		if itemStats then
			-- T8b (v0.382 test pass): a totem reportedly "didn't work" -- GetItemStats returning an
			-- empty (not nil) table means the client DID read the item, it just has no clean numeric
			-- stats to score (a totem's only real effect is usually a passive "Equip:" bonus, which
			-- this addon's v1 policy deliberately doesn't value -- see ROADMAP.md's proc/effect note).
			-- The old message implied a caching problem for every failure, which is actively
			-- misleading for this real, legitimate case.
			PrintChat("This item has no stats this addon can score (only clean numeric stats are counted -- passive \"Equip:\" effects and procs aren't itemized yet).")
		else
			PrintChat("Could not read item stats for that link (item may not be cached yet -- try again in a moment).")
		end
		return
	end

	local class, specKey, mode = LG.Scoring:DetectSpec()
	local score, breakdown = LG.Scoring:ScoreItem(itemStats, class, specKey, mode, itemLink)
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
	local level = tonumber(msgLower:match("^debug (%d+)$"))
	if msgLower == "debug" or level then
		LG.Debug.ToggleDebugMode(level or 1)
		return
	end

	-- Per-channel toggle (e.g. /lgs debug window) -- lets one noisy log channel be silenced once its
	-- bug is closed and confirmed, without touching the main debug switch or any other channel.
	local category = msgLower:match("^debug (%a+)$")
	if category then
		LG.Debug.ToggleCategory(category)
		return
	end

	LG.UI.ToggleLevelingGears()
end

-- Initialize the character's weight state on load so the settings page reflects the saved data and
-- current defaults. Relies on LevelingGearsDB.general already existing (Debug.lua/Settings.lua,
-- both loaded earlier, guard it themselves).
local function InitializeCharacterState()
	LG.Weights.EnsureWeights()
	LG.UI.RefreshGeneralSettingsUI()
	LG.UI.RefreshWeightLabels()
	if not LevelingGearsDB.general.bootMessageShown then
		PrintChat("Loaded.")
		PrintChat("Type /levelinggears or /lgs to open settings.")
		-- EnsureWeights only ever seeds a stat the FIRST time it's ever missing -- it does not
		-- re-seed on a later respec or talent change (that's ROADMAP.md's planned follow-up). Told
		-- once at boot, not on every respec, so this doesn't become a repeated chat-spam nag.
		PrintChat("Stat weights are set once per character and won't update automatically if your " ..
			"spec or talents change later -- use \"Restore Defaults\" or adjust them by hand when they do.")
		LevelingGearsDB.general.bootMessageShown = true
	end
end

-- The addon exposes only the two primary entry points so the command surface stays simple for players.
SLASH_LEVELINGGEARS1 = "/levelinggears"
SLASH_LEVELINGGEARS2 = "/lgs"
SlashCmdList["LEVELINGGEARS"] = HandleSlashCommand

SafeCall(InitializeCharacterState)
SafeCall(LG.GearEvaluation.UpdateEquippedGearEvaluation)
