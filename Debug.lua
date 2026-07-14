-- Leveling Gears -- Debug.lua
-- Foundational, addon-wide helpers every other file relies on: the addon version string, chat
-- printing, pcall safety, and debug logging. WoW's addon sandbox has no io/file/os access, so
-- debug logging is a small SavedVariables-backed ring buffer instead of a log file. Loads first
-- (see LevelingGears.toc) so every later file can rely on LG.Debug already being complete.

local _, LG = ...
LG.Debug = LG.Debug or {}
local Debug = LG.Debug

-- The addon's version string. Lives here (rather than in Core.lua, which loads last) because
-- UI.lua's version label needs it at UI.lua's own load time, before Core.lua has run.
LG.ADDON_VERSION = "0.303"

LevelingGearsDB = LevelingGearsDB or {}
LevelingGearsDB.general = LevelingGearsDB.general or {}
LevelingGearsDB.debugLog = LevelingGearsDB.debugLog or {}

local DEBUG_LOG_MAX_ENTRIES = 50

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

function Debug.WriteDebugLog(message, level)
	if level and Debug.GetDebugLevel() < level then
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
		Debug.PrintChat("Debug logging enabled (level " .. settings.debugLevel .. "). Use /lgs debug dump to view recent entries.")
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

-- Every other file's pcall-wrapped blocks route through this so a Lua error is logged and
-- reported instead of silently breaking the addon.
function Debug.SafeCall(func, ...)
	local success, err = pcall(func, ...)
	if not success then
		Debug.WriteDebugLog(err, 1)
		Debug.PrintChat("A Lua error occurred. Use /lgs debug dump to view recent debug entries.")
	end
	return success, err
end
