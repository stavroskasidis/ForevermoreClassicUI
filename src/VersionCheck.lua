--[[
	Forevermore Classic UI - Version check

	Tells the player when a newer version of the addon is out. The game gives
	addons no internet access, so the only way to learn about a newer release
	is from other players running the addon (as DBM and BigWigs do): each
	copy sends its own version on the guild and group addon channels, and a
	copy that hears a newer one prints a notice once a session and saves the
	version, so the notice is printed again at the next login until the addon
	is updated.

	Traffic is kept low: the version is sent once at login (guild, and the
	group if in one) and when joining a group. A copy that hears an older
	version answers on the same channel after a random delay, unless another
	player sent a version at least as new meanwhile, so one answer goes out
	however many guild members run the newer version; answers only ever carry
	a newer version than the message they answer, so they cannot ping-pong.

	Versions are addon.json's (1.2.3, optionally -alphaN / -betaN). A newer
	alpha or beta is only reported to players running an alpha or beta
	themselves (CurseForge only offers those to players who opted in). An
	unbuilt copy (version "@project-version@") neither sends nor reports.
]]

local _, ns = ...

local PREFIX = "FMCUI"
local MESSAGE = "V:"
local SEND_COOLDOWN = 60 -- seconds between two sends on one channel
local REPLY_DELAY_MIN, REPLY_DELAY_MAX = 1, 8
local SAVED_EXPIRY = 14 * 24 * 60 * 60 -- forget a saved version not heard again for two weeks

local PRERELEASE_RANK = { alpha = 1, beta = 2 }
local RELEASE_RANK = 3

-- "1.28.6" -> { 1, 28, 6, 3, 0 }; "1.29.0-beta2" -> { 1, 29, 0, 2, 2 }; anything else -> nil.
local function ParseVersion(text)
	if type(text) ~= "string" then return nil end
	local major, minor, patch, suffix = text:match("^(%d+)%.(%d+)%.(%d+)(.*)$")
	if not major then return nil end
	local rank, number = RELEASE_RANK, 0
	if suffix ~= "" then
		local kind, n = suffix:lower():match("^%-(%a+)(%d*)$")
		rank = kind and PRERELEASE_RANK[kind]
		if not rank then return nil end
		number = tonumber(n) or 0
	end
	return { tonumber(major), tonumber(minor), tonumber(patch), rank, number }
end

-- < 0 when a is older than b, 0 when equal, > 0 when newer.
local function CompareVersions(a, b)
	for i = 1, 5 do
		if a[i] ~= b[i] then
			return a[i] - b[i]
		end
	end
	return 0
end

local current = ParseVersion(ns.VERSION)
if not current then return end
local currentIsPrerelease = current[4] ~= RELEASE_RANK

-- Whether a version heard from another player is worth telling about: newer
-- than ours, a release unless we run a prerelease, and not an absurd major
-- version (someone sending made-up numbers).
local function IsNewer(version)
	if not version or CompareVersions(version, current) <= 0 then return false end
	if version[4] ~= RELEASE_RANK and not currentIsPrerelease then return false end
	return version[1] <= current[1] + 1
end

local notified = false

local function Notify(text)
	if notified then return end
	notified = true
	ns.Print(string.format("A newer version is out: |cffffd100%s|r (you have %s). Update it from CurseForge or your addon manager.", text, ns.VERSION))
end

local function Remember(text, version)
	local db = ns.db
	if not db then return end
	local saved = ParseVersion(db.newestVersion)
	if not saved or CompareVersions(version, saved) >= 0 then
		db.newestVersion = text
		db.newestVersionSeen = time()
	end
end

---------------------------------------------------------------------------
-- Sending
---------------------------------------------------------------------------

local lastSent = {}      -- channel -> GetTime() of the last send
local pendingReply = {}  -- channel -> C_Timer handle

local function Send(channel)
	local now = GetTime()
	if lastSent[channel] and now - lastSent[channel] < SEND_COOLDOWN then return end
	-- 12.x blocks addon messages during encounters and some instanced content.
	if C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return end
	lastSent[channel] = now
	pcall(C_ChatInfo.SendAddonMessage, PREFIX, MESSAGE .. ns.VERSION, channel)
end

local function GroupChannel()
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and not IsInGroup(LE_PARTY_CATEGORY_HOME) then
		return "INSTANCE_CHAT"
	elseif IsInRaid() then
		return "RAID"
	elseif IsInGroup() then
		return "PARTY"
	end
end

-- Sent out of combat, where 12.x is least likely to block addon messages.
local function Announce(toGuild)
	ns:RunOutOfCombat(function()
		if toGuild and IsInGuild() then
			Send("GUILD")
		end
		local group = GroupChannel()
		if group then
			Send(group)
		end
	end)
end

local REPLY_CHANNELS = { GUILD = true, PARTY = true, RAID = true, INSTANCE_CHAT = true }

local function ScheduleReply(channel)
	if pendingReply[channel] or not REPLY_CHANNELS[channel] then return end
	pendingReply[channel] = C_Timer.NewTimer(REPLY_DELAY_MIN + math.random() * (REPLY_DELAY_MAX - REPLY_DELAY_MIN), function()
		pendingReply[channel] = nil
		if not InCombatLockdown() then
			Send(channel)
		end
	end)
end

local function CancelReply(channel)
	local timer = pendingReply[channel]
	if timer then
		timer:Cancel()
		pendingReply[channel] = nil
	end
end

---------------------------------------------------------------------------
-- Receiving
---------------------------------------------------------------------------

local function OnAddonMessage(prefix, text, channel, sender)
	if issecretvalue and (issecretvalue(prefix) or issecretvalue(text) or issecretvalue(sender)) then return end
	if prefix ~= PREFIX or type(text) ~= "string" or text:sub(1, #MESSAGE) ~= MESSAGE then return end
	if sender and Ambiguate(sender, "none") == UnitName("player") then return end
	local versionText = text:sub(#MESSAGE + 1)
	local version = ParseVersion(versionText)
	if not version then return end

	local order = CompareVersions(version, current)
	if order >= 0 then
		-- Someone already told this channel about a version at least as new as ours.
		CancelReply(channel)
		if IsNewer(version) then
			Remember(versionText, version)
			Notify(versionText)
		end
	else
		ScheduleReply(channel)
	end
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------

-- At login, the version saved from an earlier session.
local function NotifySaved()
	local db = ns.db
	if not db or not db.newestVersion then return end
	local saved = ParseVersion(db.newestVersion)
	local expired = not db.newestVersionSeen or time() - db.newestVersionSeen > SAVED_EXPIRY
	if IsNewer(saved) and not expired then
		Notify(db.newestVersion)
	else
		db.newestVersion = nil
		db.newestVersionSeen = nil
	end
end

C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

local wasInGroup = false
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "CHAT_MSG_ADDON" then
		OnAddonMessage(...)
	elseif event == "GROUP_ROSTER_UPDATE" then
		local inGroup = IsInGroup()
		if inGroup and not wasInGroup then
			Announce(false)
		end
		wasInGroup = inGroup
	elseif event == "PLAYER_ENTERING_WORLD" then
		local isInitialLogin, isReloadingUi = ...
		if not (isInitialLogin or isReloadingUi) then return end
		wasInGroup = IsInGroup()
		-- After the loading screen and the login chatter, and once the
		-- guild is known (IsInGuild is false for a moment after login).
		C_Timer.After(8, function()
			NotifySaved()
			Announce(true)
		end)
	end
end)
