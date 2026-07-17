-- Leveling Gears -- Debug.lua
-- Foundational, addon-wide helpers every other file relies on: the addon version string, chat
-- printing, pcall safety, and debug logging. WoW's addon sandbox has no io/file/os access, so
-- debug logging is a small SavedVariables-backed ring buffer instead of a log file. Loads first
-- (see LevelingGears.toc) so every later file can rely on LG.Debug already being complete.

local _, LG = ...
LG.Debug = LG.Debug or {}
local Debug = LG.Debug

-- The addon's version string. Read at runtime from the single source of truth -- the "## Version:"
-- line in LevelingGears.toc -- so the two can never drift. The C_AddOns shim is REQUIRED on this
-- client: the Anniversary build (though it reports Interface 20505) runs the modern engine, which
-- removed the old global GetAddOnMetadata in favour of C_AddOns.GetAddOnMetadata -- calling the bare
-- global here is exactly what broke addon load once. Shim pattern confirmed against working installed
-- addons (Auctionator, Clique). Lives here (rather than in Core.lua, which loads last) because
-- UI.lua's version label needs it at UI.lua's own load time, before Core.lua has run. The two nil
-- guards mean the worst case is a "?" version, never a load-time error.
local getAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
LG.ADDON_VERSION = (getAddOnMetadata and getAddOnMetadata("LevelingGears", "Version")) or "?"

LevelingGearsDB = LevelingGearsDB or {}
LevelingGearsDB.general = LevelingGearsDB.general or {}
LevelingGearsDB.general.debugCategories = LevelingGearsDB.general.debugCategories or {}
LevelingGearsDB.debugLog = LevelingGearsDB.debugLog or {}

-- Bumped from 50 to 500 (v0.312): bug #29's investigation showed the 50-entry buffer wrapping and
-- evicting position-log entries mid-session (an 11-minute gap with other activity was enough to
-- roll useful drag/reopen data out before it could be dumped). Bumped again to 2000 (v0.383) to
-- comfortably capture a full test-plan pass (T1-T35) plus bug #29/#37 diagnostics without wrapping
-- mid-session. Still negligible SavedVariables size for small strings.
local DEBUG_LOG_MAX_ENTRIES = 2000

-- Send a message to the player's own chat frame using the addon's standard chat prefix.
function Debug.PrintChat(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cff71d5ffLeveling Gears|r " .. message, 1, 1, 1)
end

function Debug.IsDebugEnabled()
	return LevelingGearsDB.general.debugEnabled == true
end

function Debug.GetDebugLevel()
	return LevelingGearsDB.general.debugLevel or 1
end

-- A category defaults to enabled unless explicitly turned off with /lgs debug <category> -- see
-- T7's queue item: once a bug tied to one log channel (e.g. window position) is closed and
-- confirmed, that channel can be silenced on its own without touching the main debug toggle or
-- every other channel's logging.
function Debug.IsCategoryEnabled(category)
	if not category then
		return true
	end
	local categories = LevelingGearsDB.general.debugCategories
	local enabled = categories and categories[category]
	if enabled == nil then
		return true
	end
	return enabled == true
end

function Debug.SetCategoryEnabled(category, enabled)
	LevelingGearsDB.general.debugCategories = LevelingGearsDB.general.debugCategories or {}
	LevelingGearsDB.general.debugCategories[category] = enabled and true or false
	Debug.PrintChat("Debug category '" .. category .. "' " .. (enabled and "enabled" or "disabled") .. ".")
end

function Debug.ToggleCategory(category)
	Debug.SetCategoryEnabled(category, not Debug.IsCategoryEnabled(category))
end

function Debug.WriteDebugLog(message, level, category)
	if level and Debug.GetDebugLevel() < level then
		return
	end
	if not Debug.IsCategoryEnabled(category) then
		return
	end

	local log = LevelingGearsDB.debugLog
	table.insert(log, { time = date("%H:%M:%S"), message = tostring(message) })
	while #log > DEBUG_LOG_MAX_ENTRIES do
		table.remove(log, 1)
	end

	if Debug.IsDebugEnabled() then
		Debug.PrintChat("|cffff8080Debug|r " .. tostring(message))
	end
end

function Debug.SetDebugEnabled(enabled, level)
	local settings = LevelingGearsDB.general
	settings.debugEnabled = enabled and true or false
	settings.debugLevel = level or settings.debugLevel or 1
	if enabled then
		Debug.PrintChat("Debug logging enabled (level " .. settings.debugLevel ..
			"). Use /lgs debug dump to view recent entries, or /lgs debug again to turn it back off.")
	else
		Debug.PrintChat("Debug logging disabled.")
	end
end

function Debug.ToggleDebugMode(level)
	Debug.SetDebugEnabled(not Debug.IsDebugEnabled(), level)
end

-- Print the stored debug entries to chat, since the addon has no file to read them back from.
function Debug.DumpDebugLog()
	local log = LevelingGearsDB.debugLog
	if #log == 0 then
		Debug.PrintChat("Debug log is empty.")
		return
	end
	for _, entry in ipairs(log) do
		Debug.PrintChat("[" .. entry.time .. "] " .. entry.message)
	end
end

-- Build the full copy-ready report text: addon version, character context, and the stored debug
-- log. The addon sandbox has no way to SEND this (no network/io/os), so the report is prepared for
-- the player to copy and email to the developer -- UI.ShowReportWindow displays it with the text
-- pre-selected. Class/level/spec are read at call time (runtime), so LG.Scoring loading after
-- Debug.lua is not a problem.
function Debug.BuildReportText()
	local lines = {}
	table.insert(lines, "Leveling Gears -- bug report")
	table.insert(lines, "Please email this to wegatherinthesun@gmail.com")
	table.insert(lines, "")
	table.insert(lines, "Version: v" .. tostring(LG.ADDON_VERSION))

	local playerName = UnitName("player") or "?"
	local realm = GetRealmName() or "?"
	local _, className = UnitClass("player")
	local level = UnitLevel("player") or 0
	table.insert(lines, "Character: " .. playerName .. "-" .. realm ..
		" (" .. tostring(className) .. ", level " .. tostring(level) .. ")")

	-- Spec is a nice-to-have; a failure here must never break report generation (the whole point is
	-- to work even when something else is broken), so it's pcall-guarded and simply omitted on error.
	if LG.Scoring and LG.Scoring.DescribeCurrentSpec then
		local ok, spec = pcall(function() return LG.Scoring:DescribeCurrentSpec() end)
		if ok and spec then
			table.insert(lines, "Scoring as: " .. tostring(spec))
		end
	end

	local log = LevelingGearsDB.debugLog
	table.insert(lines, "")
	table.insert(lines, "--- Debug log (" .. #log .. " entries) ---")
	if #log == 0 then
		table.insert(lines, "(empty -- enable logging with /lgs debug, reproduce the issue, then " ..
			"reopen this report for detail)")
	else
		for _, entry in ipairs(log) do
			table.insert(lines, "[" .. entry.time .. "] " .. entry.message)
		end
	end

	return table.concat(lines, "\n")
end

-- Every other file's pcall-wrapped blocks route through this so a Lua error is logged and
-- reported instead of silently breaking the addon.
function Debug.SafeCall(func, ...)
	local success, err = pcall(func, ...)
	if not success then
		Debug.WriteDebugLog(err, 1)
		Debug.PrintChat("A Lua error occurred. Type /lgs report to open a copy-ready report for the " ..
			"developer (or /lgs debug dump to view raw entries).")
		-- Auto-offer the copy-ready report dialog, but only ONCE per session: a Lua error can fire
		-- repeatedly (e.g. from an OnUpdate path), and an unthrottled popup would spam the screen. The
		-- dialog is registered in UI.lua; the guard also covers an error firing before UI.lua has
		-- loaded (Debug.lua loads first). The flag lives on the session-scoped Debug table, so it
		-- resets on /reload -- a fresh session can offer again.
		if not Debug.errorReportOffered
			and StaticPopupDialogs and StaticPopupDialogs["LEVELINGGEARS_ERROR_REPORT"] then
			Debug.errorReportOffered = true
			Debug.WriteDebugLog("report: auto-offering error report (first caught error this session)", 1, "report")
			StaticPopup_Show("LEVELINGGEARS_ERROR_REPORT")
		else
			Debug.WriteDebugLog("report: error report auto-offer suppressed (already offered this " ..
				"session, or dialog not registered yet)", 1, "report")
		end
	end
	return success, err
end
