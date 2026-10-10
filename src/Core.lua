--[[
	Forevermore Classic UI - Core

	Shared state, module registry, saved variables and small helpers used by
	every module. Each module registers itself with ns:RegisterModule() and is
	activated from PLAYER_LOGIN when its option is enabled.

	Modules come in two flavours:
	  * "live" modules (cast bars, breath timers) implement Enable()/Disable() and
	    can be toggled at any time without a reload.
	  * "reload" modules (unit frames, with portraits and health/power bars as
	    its parts) implement Apply() once at login; turning them off restores
	    the retail look after a UI reload, because Blizzard's frames cannot be
	    safely un-skinned at runtime.
]]

local ADDON_NAME, ns = ...
_G.ForevermoreClassicUI = ns

ns.ADDON_NAME = ADDON_NAME
ns.TITLE = "Forevermore Classic UI"
ns.VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "dev" -- stamped into the .toc by build.ps1

-- One build serves retail (Interface 12xxxx) and WoW Forever (1.60.x, 16001).
-- The Forever-only files return early when this is false; the client ignores
-- [AllowLoadGameType camelot] on addon .toc lines, so the .toc cannot do it.
ns.IS_FOREVER = (select(4, GetBuildInfo())) < 20000

-- Legacy textures that still ship with the retail client.
ns.T = {
	STATUS_BAR         = "Interface\\TargetingFrame\\UI-StatusBar",
	TARGET_FRAME       = "Interface\\TargetingFrame\\UI-TargetingFrame",
	TARGET_ELITE       = "Interface\\TargetingFrame\\UI-TargetingFrame-Elite",
	TARGET_RARE        = "Interface\\TargetingFrame\\UI-TargetingFrame-Rare",
	TARGET_RARE_ELITE  = "Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite",
	TARGET_MINUS       = "Interface\\TargetingFrame\\UI-TargetingFrame-Minus",
	TARGET_FLASH       = "Interface\\TargetingFrame\\UI-TargetingFrame-Flash",
	TARGET_MINUS_FLASH = "Interface\\TargetingFrame\\UI-TargetingFrame-Minus-Flash",
	LEVEL_BG           = "Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground",
	SKULL              = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
	TOT_FRAME          = "Interface\\TargetingFrame\\UI-TargetofTargetFrame",
	SMALL_FRAME        = "Interface\\TargetingFrame\\UI-SmallTargetingFrame",
	PARTY_FRAME        = "Interface\\TargetingFrame\\UI-PartyFrame",
	PARTY_FLASH        = "Interface\\TargetingFrame\\UI-PartyFrame-Flash",
	BOSS_FRAME         = "Interface\\TargetingFrame\\UI-UnitFrame-Boss",
	BOSS_FLASH         = "Interface\\TargetingFrame\\UI-UnitFrame-Boss-Flash",
	ATTACK_BG          = "Interface\\TargetingFrame\\UI-TargetingFrame-AttackBackground",
	QUEST_BADGE        = "Interface\\TargetingFrame\\PortraitQuestBadge",
	PET_ATTACK         = "Interface\\TargetingFrame\\UI-Player-AttackStatus",
	PORTRAIT_MASK      = "Interface\\CharacterFrame\\TempPortraitAlphaMask",
	STATE_ICON         = "Interface\\CharacterFrame\\UI-StateIcon",
	PLAYER_STATUS      = "Interface\\CharacterFrame\\UI-Player-Status",
	GROUP_INDICATOR    = "Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator",
	LEADER_ICON        = "Interface\\GroupFrame\\UI-Group-LeaderIcon",
	ROLE_ICONS         = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES",
	LFG_EYE            = "Interface\\LFGFrame\\LFG-Eye",
	VEHICLE_FRAME      = "Interface\\Vehicles\\UI-Vehicle-Frame",
	VEHICLE_FLASH      = "Interface\\Vehicles\\UI-Vehicle-Frame-Flash",
	VEHICLE_PARTY      = "Interface\\Vehicles\\UI-Vehicles-PartyFrame",
	CAST_BORDER        = "Interface\\CastingBar\\UI-CastingBar-Border",
	CAST_BORDER_SMALL  = "Interface\\CastingBar\\UI-CastingBar-Border-Small",
	CAST_SHIELD_SMALL  = "Interface\\CastingBar\\UI-CastingBar-Small-Shield",
	CAST_SPARK         = "Interface\\CastingBar\\UI-CastingBar-Spark",
	CAST_FLASH         = "Interface\\CastingBar\\UI-CastingBar-Flash",
	CAST_FLASH_SMALL   = "Interface\\CastingBar\\UI-CastingBar-Flash-Small",
	RAID_HP_FILL       = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
	RAID_RES_FILL      = "Interface\\RaidFrame\\Raid-Bar-Resource-Fill",
	RAID_RES_BG        = "Interface\\RaidFrame\\Raid-Bar-Resource-Background",
	ABSORB_FILL        = "Interface\\RaidFrame\\Absorb-Fill",
	SHIELD_FILL        = "Interface\\RaidFrame\\Shield-Fill",
	MINIMAP_BORDER     = "Interface\\Minimap\\UI-Minimap-Border",
	MINIMAP_BACKGROUND = "Interface\\Minimap\\UI-Minimap-Background",
	MINIMAP_RING       = "Interface\\Minimap\\MiniMap-TrackingBorder",
	MINIMAP_NORTH_TAG  = "Interface\\Minimap\\CompassNorthTag",
	MINIMAP_COMPASS    = "Interface\\Minimap\\CompassRing",
	MINIMAP_TRACKING   = "Interface\\Minimap\\Tracking\\None",
	MINIMAP_ZOOM_IN    = "Interface\\Minimap\\UI-Minimap-ZoomInButton-",   -- + Up / Down / Disabled
	MINIMAP_ZOOM_OUT   = "Interface\\Minimap\\UI-Minimap-ZoomOutButton-",  -- + Up / Down / Disabled
	MINIMAP_HIGHLIGHT  = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight",
	MINIMAP_WORLD_MAP  = "Interface\\Minimap\\UI-Minimap-WorldMapSquare",
	CALENDAR_BUTTON    = "Interface\\Calendar\\UI-Calendar-Button",
	CLOCK_BACKGROUND   = "Interface\\TimeManager\\ClockBackground",
	MAIL_ICON          = "Interface\\Icons\\INV_Letter_15",
	MOUSE_HIGHLIGHT    = "Interface\\Buttons\\UI-Common-MouseHilight",
	LOOT_PANEL         = "Interface\\LootFrame\\UI-LootPanel",
	PANEL_CLOSE        = "Interface\\Buttons\\UI-Panel-MinimizeButton-", -- + Up / Down / Disabled / Highlight
	LOOT_NAME_FRAME    = "Interface\\QuestFrame\\UI-QuestItemNameFrame",
	LOOT_SKULL         = "Interface\\TargetingFrame\\TargetDead",
	LOOT_FISHING       = "Interface\\LootFrame\\FishingLoot-Icon",
	CHAT_SCROLL_UP     = "Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-",   -- + Up / Down / Disabled
	CHAT_SCROLL_DOWN   = "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-", -- + Up / Down / Disabled
	SCROLL_UP          = "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-",   -- + Up / Down / Disabled
	SCROLL_DOWN        = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-", -- + Up / Down / Disabled
	SCROLL_KNOB        = "Interface\\Buttons\\UI-ScrollBar-Knob",
	DROPDOWN_BOX       = "Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame",
	MAINMENUBAR_STRIP  = "Interface\\MainMenuBar\\UI-MainMenuBar-Dwarf",
	QUICKSLOT2         = "Interface\\Buttons\\UI-Quickslot2",
	QUICKSLOT_PUSHED   = "Interface\\Buttons\\UI-Quickslot-Depress",
	BUTTON_HIGHLIGHT   = "Interface\\Buttons\\ButtonHilight-Square",
	BUTTON_CHECKED     = "Interface\\Buttons\\CheckButtonHilight",
	TAB_INACTIVE       = "Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab",
	TAB_HIGHLIGHT      = "Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight",
}

-- Classic colours.
ns.C = {
	HEALTH   = { 0, 1, 0 },
	BACKDROP = { 0, 0, 0, 0.5 },
}

---------------------------------------------------------------------------
-- Module registry
---------------------------------------------------------------------------

ns.modules = {}
ns.moduleByKey = {}
ns.appliedState = {} -- what each reload-module was applied with at login

-- A module with a `parent` key is a part of that module: it has no option of
-- its own and follows the parent's setting (e.g. the classic health/power bar
-- textures are part of the "Unit Frames" option).
function ns:RegisterModule(module)
	assert(module.key and module.name, "Module needs a key and a name")
	table.insert(self.modules, module)
	self.moduleByKey[module.key] = module
	return module
end

function ns:IsEnabled(key)
	local module = self.moduleByKey[key]
	if module and module.parent then
		return self:IsEnabled(module.parent)
	end
	return self.db ~= nil and self.db[key] == true
end

-- True if the reload-module's classic look is currently active on screen.
function ns:IsApplied(key)
	return self.appliedState[key] == true
end

-- True when any reload-required module's saved setting differs from what is
-- currently applied on screen.
function ns:NeedsReload()
	for _, module in ipairs(self.modules) do
		local applied = self.appliedState[module.key]
		if not module.live and not module.parent and applied ~= nil and applied ~= self.db[module.key] then
			return true
		end
	end
	return false
end

-- Functions called after any option changed (the options page and the
-- setup wizard refresh themselves from them).
local changeListeners = {}
function ns:OnSettingsChanged(fn)
	table.insert(changeListeners, fn)
end

-- Turns a top-level option on or off. Live modules are switched at once;
-- the others take effect after a reload (see ns:NeedsReload).
function ns:SetModuleEnabled(key, value)
	local module = self.moduleByKey[key]
	value = (value == true)
	if not module or module.parent or self.db[key] == value then
		return
	end
	self.db[key] = value
	if self.activated and module.live then
		local method = value and module.Enable or module.Disable
		if method then xpcall(method, geterrorhandler(), module) end
	end
	for _, fn in ipairs(changeListeners) do
		xpcall(fn, geterrorhandler())
	end
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

-- Run a function now, or after the current combat ends if it would touch
-- protected frames while in combat lockdown.
local pendingOutOfCombat = {}
function ns:RunOutOfCombat(fn)
	if InCombatLockdown() then
		table.insert(pendingOutOfCombat, fn)
	else
		fn()
	end
end

-- Safe hooksecurefunc wrappers; missing globals/methods are skipped so that a
-- future Blizzard rename does not break the whole addon.
--   ns.Hook("GlobalFunctionName", fn)
--   ns.Hook(frame, "MethodName", fn)
-- Each hook runs in its own protected call: hooks on the same function form a
-- chain, so an error in one would otherwise silently skip every hook installed
-- after it (by this addon or others). Errors still reach the error handler.
local function Protect(fn)
	return function(...)
		xpcall(fn, geterrorhandler(), ...)
	end
end

function ns.Hook(target, method, fn)
	if type(method) == "function" then
		fn = method
		if type(target) == "string" and type(_G[target]) == "function" then
			hooksecurefunc(target, Protect(fn))
			return true
		end
		return false
	end
	if type(target) == "table" and type(target[method]) == "function" then
		hooksecurefunc(target, method, Protect(fn))
		return true
	end
	return false
end

-- Clear anchors and set a single point.
--   ns.Point(region, "TOPLEFT", x, y)
--   ns.Point(region, "TOPLEFT", relativeTo, "BOTTOMLEFT", x, y)
function ns.Point(region, point, relativeTo, relativePoint, x, y)
	region:ClearAllPoints()
	if type(relativeTo) == "number" or relativeTo == nil then
		region:SetPoint(point, relativeTo or 0, relativePoint or 0)
	else
		region:SetPoint(point, relativeTo, relativePoint, x or 0, y or 0)
	end
end

-- Apply a legacy file texture (with optional tex coords) to a texture region.
function ns.SetTexture(texture, path, left, right, top, bottom)
	texture:SetTexture(path)
	if left then
		texture:SetTexCoord(left, right, top, bottom)
	else
		texture:SetTexCoord(0, 1, 0, 1)
	end
end

-- Whether a texture file exists in this client. The legacy art is referenced
-- by path and not bundled, so pieces a client no longer ships need a fallback;
-- SetTexture reports whether the file was found.
local probe = UIParent:CreateTexture()
probe:Hide()
function ns.HasTexture(path)
	local found = probe:SetTexture(path)
	probe:SetTexture(nil)
	return found == true
end

-- Applies an atlas only if this client has it (SetAtlas errors on unknown
-- names). Returns true when it was applied.
function ns.SetAtlas(texture, name, useAtlasSize)
	if C_Texture.GetAtlasInfo(name) then
		texture:SetAtlas(name, useAtlasSize)
		return true
	end
	return false
end

-- Detach a MaskTexture from the given textures (and hide it) so that the
-- retail bar-shaped masks stop clipping the rectangular classic bars.
function ns.StripMask(mask, ...)
	if not mask then return end
	for i = 1, select("#", ...) do
		local texture = select(i, ...)
		if texture and texture.RemoveMaskTexture then
			pcall(texture.RemoveMaskTexture, texture, mask)
		end
	end
	mask:Hide()
end

-- Create the classic semi-transparent black backdrop that sits behind the
-- name/health/power area of a frame.
function ns.CreateBackdrop(parent, width, height, point, relativeTo, relativePoint, x, y)
	local backdrop = parent:CreateTexture(nil, "BACKGROUND", nil, -8)
	backdrop:SetColorTexture(unpack(ns.C.BACKDROP))
	backdrop:SetSize(width, height)
	backdrop:SetPoint(point, relativeTo, relativePoint, x, y)
	return backdrop
end

function ns.Print(msg)
	print("|cff33ccff" .. ns.TITLE .. "|r: " .. tostring(msg))
end

---------------------------------------------------------------------------
-- The vanilla bar strip, shared by the action bar and bags bar art
--
-- UI-MainMenuBar-Dwarf (256x256) holds the 1024x43 vanilla bar as four
-- 256px pieces, read left to right from the file's rows 213-256, 149-192,
-- 85-128 and 21-64 (the rows in between are the XP bar's frame). The
-- action slots are 42px cells separated by 3px metal columns; piece 2
-- holds six whole cells, their columns centred 2px in.
---------------------------------------------------------------------------

local STRIP_CELL_WIDTH, STRIP_CELL_HEIGHT = 42, 43
local STRIP_CELLS = {}
do
	local top = 149 -- piece 2
	for k = 0, 5 do
		STRIP_CELLS[k + 1] = { (2 + 42 * k) / 256, (44 + 42 * k) / 256, top / 256, (top + STRIP_CELL_HEIGHT) / 256 }
	end
end

-- One strip cell behind a button (the cells differ slightly, so `index`
-- walks through them); size it with ns.SizeStripCell.
function ns.CreateStripCell(button, index)
	local cell = button:CreateTexture(nil, "BACKGROUND", nil, -3)
	ns.SetTexture(cell, ns.T.MAINMENUBAR_STRIP, unpack(STRIP_CELLS[(index - 1) % #STRIP_CELLS + 1]))
	cell:SetPoint("CENTER", button, "CENTER", 0, 0)
	return cell
end

-- Sizes a cell to its button's width (keeping the strip's 42:43
-- proportion) plus the bar's padding along the bar, so neighbouring cells
-- meet on their shared metal column instead of leaving a gap.
function ns.SizeStripCell(cell, width, padding, vertical)
	local height = width * STRIP_CELL_HEIGHT / STRIP_CELL_WIDTH
	if vertical then
		height = height + padding
	else
		width = width + padding
	end
	cell:SetSize(width, height)
end

-- A narrow cell for a button narrower than the strip's cells along the bar
-- (vanilla drew its key ring in its own narrow slot): the ends of a cell,
-- with a plain slice of it (its border and dark inside, clear of the
-- gryphon) stretched between them. The slices are cell pixels.
local NARROW_CELL_END = 4
local NARROW_CELL_SLICE_X, NARROW_CELL_SLICE_Y = 5, 3

function ns.CreateNarrowStripCell(button)
	local parts = {}
	for i = 1, 3 do
		parts[i] = button:CreateTexture(nil, "BACKGROUND", nil, -3)
		parts[i]:SetTexture(ns.T.MAINMENUBAR_STRIP)
	end
	return parts
end

-- Sizes it like ns.SizeStripCell: its button's size plus the bar's padding
-- along the bar, and a whole cell's size across it.
function ns.SizeNarrowStripCell(parts, button, padding, vertical)
	local left, right, top, bottom = unpack(STRIP_CELLS[1])
	local first, middle, last = parts[1], parts[2], parts[3]
	for _, part in ipairs(parts) do part:ClearAllPoints() end
	if vertical then
		local width = button:GetWidth()
		local height = button:GetHeight() + padding
		local cap = NARROW_CELL_END * width / STRIP_CELL_WIDTH
		local slice = top + (NARROW_CELL_SLICE_Y + 0.5) / 256
		first:SetTexCoord(left, right, top, top + NARROW_CELL_END / 256)
		middle:SetTexCoord(left, right, slice, slice)
		last:SetTexCoord(left, right, bottom - NARROW_CELL_END / 256, bottom)
		first:SetSize(width, cap)
		last:SetSize(width, cap)
		first:SetPoint("TOP", button, "CENTER", 0, height / 2)
		last:SetPoint("BOTTOM", button, "CENTER", 0, -height / 2)
		middle:SetPoint("TOPLEFT", first, "BOTTOMLEFT")
		middle:SetPoint("BOTTOMRIGHT", last, "TOPRIGHT")
	else
		local height = button:GetHeight() * STRIP_CELL_HEIGHT / STRIP_CELL_WIDTH
		local width = button:GetWidth() + padding
		local cap = NARROW_CELL_END * height / STRIP_CELL_HEIGHT
		local slice = left + (NARROW_CELL_SLICE_X + 0.5) / 256
		first:SetTexCoord(left, left + NARROW_CELL_END / 256, top, bottom)
		middle:SetTexCoord(slice, slice, top, bottom)
		last:SetTexCoord(right - NARROW_CELL_END / 256, right, top, bottom)
		first:SetSize(cap, height)
		last:SetSize(cap, height)
		first:SetPoint("LEFT", button, "CENTER", -width / 2, 0)
		last:SetPoint("RIGHT", button, "CENTER", width / 2, 0)
		middle:SetPoint("TOPLEFT", first, "TOPRIGHT")
		middle:SetPoint("BOTTOMRIGHT", last, "BOTTOMLEFT")
	end
end

-- Fades every divider frame Blizzard acquired between a bar's buttons (the
-- pools are re-filled on each layout; alpha sticks to the pooled frames).
function ns.HideBarDividers(bar)
	for _, key in ipairs({ "HorizontalDividersPool", "VerticalDividersPool" }) do
		local pool = bar[key]
		if pool then
			for divider in pool:EnumerateActive() do
				divider:SetAlpha(0)
			end
		end
	end
end

---------------------------------------------------------------------------
-- The UI panel spot
---------------------------------------------------------------------------

-- The panel manager puts a panel's top TOP_OFFSET (-116) plus its yoffset
-- below UIParent's top, raised so that its bottom stays 140 above the
-- screen's bottom and its top at least 10 below the screen's top
-- (ClampUIPanelY). Returns that top offset for a panel of the given height,
-- in UIParent units.
function ns.PanelTop(yOffset, height, minYOffset, bottomClamp)
	local y = (GetUIPanelLayoutAttribute and GetUIPanelLayoutAttribute("TOP_OFFSET") or -116) + yOffset
	local bottom = UIParent:GetTop() + y - height
	bottomClamp = bottomClamp or 140
	if bottom < bottomClamp then
		y = y + bottomClamp - bottom
	end
	return math.min(y, minYOffset or -10)
end

-- The left edge of a "left" area panel (the character frame): LEFT_OFFSET
-- from UIParent's left, in UIParent units.
function ns.PanelLeft()
	return GetUIPanelLayoutAttribute and GetUIPanelLayoutAttribute("LEFT_OFFSET") or 16
end

-- A panel's layout attribute (xoffset, yoffset, ...). The manager copies
-- the panel's UIPanelWindows entry onto the frame the first time it
-- positions it; until then the entry is read.
function ns.PanelAttribute(panel, name)
	if panel:GetAttribute("UIPanelLayout-defined") then
		return panel:GetAttribute("UIPanelLayout-" .. name)
	end
	local attributes = UIPanelWindows and panel.GetName and UIPanelWindows[panel:GetName() or ""]
	return attributes and attributes[name]
end

-- Every window opens where the modern ones (vendor, mailbox, ...) do: its
-- frame border on the panel spot. The vanilla art (the 384x512 files of the
-- spellbook, talents, trainer, trade skill and character windows, the
-- auction house's) has a transparent margin around the border, which starts
-- CLASSIC_ART_X right of and CLASSIC_ART_Y below the art's top-left corner
-- (measured in game on the spellbook, 2026-09-29; the vanilla panels share
-- its corner), so the art is drawn that far up and left of the spot.
ns.CLASSIC_ART_X, ns.CLASSIC_ART_Y = 15, 14

-- A vanilla window's art height without its tab shelf: the manager lines
-- the art up as a panel of that height.
ns.CLASSIC_PANEL_HEIGHT = 424

-- Where the top-left corner of a vanilla window's art goes when the addon
-- places it itself (the spellbook and talents, which are drawn on a larger
-- panel), in UIParent units, for art drawn at `scale` (UIParent's = 1).
function ns.ClassicArtLeft(scale)
	return ns.PanelLeft() - ns.CLASSIC_ART_X * (scale or 1)
end

function ns.ClassicArtTop(scale)
	scale = scale or 1
	return ns.PanelTop(0, (ns.CLASSIC_PANEL_HEIGHT - ns.CLASSIC_ART_Y) * scale) + ns.CLASSIC_ART_Y * scale
end

-- A frame to lay a vanilla window drawn on a Blizzard panel out from: the
-- size of the art (384x512 by default), at its top-left corner. That is the
-- panel's top left moved up and left by the art's margin and back by the
-- panel's registered xoffset (the auction house's), so the border sits
-- where a modern window's frame would. Not protected: nothing secure may be
-- anchored to it. One per panel.
local artOrigins = setmetatable({}, { __mode = "k" })
function ns.ArtOrigin(panel, width, height)
	local origin = artOrigins[panel]
	if not origin then
		origin = CreateFrame("Frame", nil, panel)
		origin:SetSize(width or 384, height or 512)
		local x = -(ns.PanelAttribute(panel, "xoffset") or 0) / panel:GetScale() - ns.CLASSIC_ART_X
		origin:SetPoint("TOPLEFT", panel, "TOPLEFT", x, ns.CLASSIC_ART_Y)
		artOrigins[panel] = origin
	end
	return origin
end

-- The hit rect insets that put a panel's mouse (or that of a frame at its
-- top left, as big as the panel) over a part of its art, at the art's
-- origin: `left`, `right`, `top`, `bottom` are insets from the art's edges
-- (the origin's size). They are negative where the art hangs out of the
-- panel.
function ns.ArtHitRectInsets(panel, left, right, top, bottom)
	local origin = ns.ArtOrigin(panel)
	local x, y = select(4, origin:GetPoint(1))
	local artRight = x + origin:GetWidth()
	local artBottom = -y + origin:GetHeight()
	return x + left, panel:GetWidth() - artRight + right, -y + top, panel:GetHeight() - artBottom + bottom
end

function ns.SetArtHitRect(panel, left, right, top, bottom)
	panel:SetHitRectInsets(ns.ArtHitRectInsets(panel, left, right, top, bottom))
end

-- The controller UI (Forever's Blizzard_Gamepad) draws on the window that
-- has the focus a gold glow (FrameGlow, anchored round its NineSlice), the
-- jump hints (LeftJumpHint, RightJumpHint, FocusJumpHint, centred on its
-- bottom edge) and footers of button prompts (each footer's legend: a child
-- of the window anchored under its bottom edge, built the first time the
-- footer shows). On a window whose vanilla art is smaller than Blizzard's
-- frame they would sit round the invisible modern frame, so
-- ns.SetGamepadBox(panel, box, footerBox) moves them onto `box`, an addon
-- frame round the vanilla window (ns.CreateArtBox), the hints and footers
-- onto `footerBox` if given (a window that puts more prompts under its
-- tabs): every anchor they hold on the window, its NineSlice or another box
-- of the window goes to the same point of the box, with Blizzard's
-- offsets. A window that switches
-- between a vanilla and a modern page (the spells panel, the professions
-- window) calls it again on every switch, with nil for the modern look
-- (back onto the window). Blizzard anchors the glow and the hints once, at
-- load; a legend is anchored whenever its footer is built or moved to
-- another window, so the legends' SetPoint is hooked. On retail nothing of
-- this exists.
local gamepadBoxes = setmetatable({}, { __mode = "k" }) -- panel -> its box, false for none (once it had one)
local footerBoxes = setmetatable({}, { __mode = "k" })  -- panel -> the box its hints and footers go under, if not its box
local boxOwners = setmetatable({}, { __mode = "k" })    -- box -> its panel
local hookedLegends = setmetatable({}, { __mode = "k" })

local function MoveToGamepadBox(region)
	local panel = region:GetParent()
	local box = panel and gamepadBoxes[panel]
	if box == nil then return end
	local target = box and region ~= panel.FrameGlow and footerBoxes[panel] or box or panel
	local points, moved = {}, false
	for i = 1, region:GetNumPoints() do
		local point, relativeTo, relativePoint, x, y = region:GetPoint(i)
		if relativeTo ~= target and relativeTo ~= nil and (relativeTo == panel or relativeTo == panel.NineSlice
			or boxOwners[relativeTo] == panel) then
			relativeTo, moved = target, true
		end
		points[i] = { point, relativeTo, relativePoint, x, y }
	end
	if not moved then return end
	region:ClearAllPoints()
	for _, p in ipairs(points) do
		region:SetPoint(p[1], p[2], p[3], p[4], p[5])
	end
end

local function HookLegend(legend)
	if hookedLegends[legend] then return end
	hookedLegends[legend] = true
	ns.Hook(legend, "SetPoint", MoveToGamepadBox)
	MoveToGamepadBox(legend)
end

local legendFactoryHooked
function ns.SetGamepadBox(panel, box, footerBox)
	if box then boxOwners[box] = panel end
	if footerBox then boxOwners[footerBox] = panel end
	if (gamepadBoxes[panel] or nil) == box and footerBoxes[panel] == footerBox then return end
	gamepadBoxes[panel] = box or false
	footerBoxes[panel] = footerBox
	-- Every legend built from now on (a footer can be moved to another
	-- window later); the ones built before are the window's children.
	if not legendFactoryHooked and InputPromptLegends then
		legendFactoryHooked = ns.Hook(InputPromptLegends, "CreateInputLegend", function(parent, key)
			local legend = parent and key and parent[key]
			if type(legend) == "table" and legend.promptContainerFrame then HookLegend(legend) end
		end)
	end
	for _, child in ipairs({ panel:GetChildren() }) do
		if child.promptContainerFrame then
			HookLegend(child)
			MoveToGamepadBox(child)
		end
	end
	for _, key in ipairs({ "FrameGlow", "LeftJumpHint", "RightJumpHint", "FocusJumpHint" }) do
		local region = panel[key]
		if type(region) == "table" and region.GetPoint then MoveToGamepadBox(region) end
	end
end

-- Whether the controller UI is on (Forever; the style can change in a
-- session, INPUT_DEVICE_INTERFACE_TRANSITION).
function ns.IsControllerUI()
	return C_InputInterfaceStyle ~= nil and Enum.InputDeviceInterfaceType ~= nil
		and C_InputInterfaceStyle.GetCurrentStyle() == Enum.InputDeviceInterfaceType.Gamepad
end

-- A box round a vanilla window for ns.SetGamepadBox: from its border's
-- top-left corner (the art's margin in from `origin`, the art's top-left
-- corner) to `right`, `bottom` px right of and below the art's corner (the
-- border's right edge, and the bottom of the tab row when tabs hang under
-- it). A child of `parent`; not protected.
function ns.CreateArtBox(parent, origin, right, bottom)
	local box = CreateFrame("Frame", nil, parent)
	box:SetPoint("TOPLEFT", origin, "TOPLEFT", ns.CLASSIC_ART_X, -ns.CLASSIC_ART_Y)
	box:SetPoint("BOTTOMRIGHT", origin, "TOPLEFT", right, -bottom)
	return box
end

---------------------------------------------------------------------------
-- Classic widget skins shared by the panel modules (trainer, auction house,
-- window frames)
---------------------------------------------------------------------------

-- MinimalScrollBar's steppers swap atlases on their own Texture from their
-- mixin; that texture is faded and a classic arrow drawn over it. The arrow
-- files are 32x32 with the arrow in their middle; the 16x16 classic button
-- (UIPanelScrollUpButtonTemplate) showed that middle only.
local STEPPER_COORDS = { 0.2, 0.8, 0.25, 0.75 }

local function SkinStepper(button, prefix)
	if not button then return end
	if button.Texture then button.Texture:SetAlpha(0) end
	button:SetSize(16, 16)
	local texture = button:CreateTexture(nil, "ARTWORK")
	texture:SetAllPoints(button)
	local function Update(pushed)
		local state = not button:IsEnabled() and "Disabled" or pushed and "Down" or "Up"
		ns.SetTexture(texture, prefix .. state, unpack(STEPPER_COORDS))
	end
	button:HookScript("OnMouseDown", function() Update(true) end)
	button:HookScript("OnMouseUp", function() Update(false) end)
	button:HookScript("OnEnable", function() Update(false) end)
	button:HookScript("OnDisable", function() Update(false) end)
	if ns.HasTexture(prefix .. "Highlight") then
		button:SetHighlightTexture(prefix .. "Highlight", "ADD")
		local highlight = button:GetHighlightTexture()
		if highlight then highlight:SetTexCoord(unpack(STEPPER_COORDS)) end
	end
	Update(false)
end

-- Re-skins a MinimalScrollBar into the classic knob bar: the track is faded,
-- a fixed 18x24 knob is drawn on the thumb and the steppers become the classic
-- arrow buttons. Only the look changes; the bar keeps its scroll logic.
function ns.SkinScrollBar(scrollBar)
	if not scrollBar then return end
	scrollBar:SetWidth(16)
	local track = scrollBar.Track
	if track then
		for _, key in ipairs({ "Begin", "End", "Middle" }) do
			if track[key] then track[key]:SetAlpha(0) end
		end
		local thumb = track.Thumb
		if thumb then
			for _, key in ipairs({ "Begin", "End", "Middle" }) do
				if thumb[key] then thumb[key]:SetAlpha(0) end
			end
			-- The classic knob is a fixed 18x24 whatever the thumb's extent.
			-- The thumb covers the visible part of the list (long in a short
			-- list), so the knob runs along it with the scroll position:
			-- flush with its top at the start and its bottom at the end,
			-- which moves it evenly over the whole track like a classic knob.
			local knob = thumb:CreateTexture(nil, "ARTWORK")
			ns.SetTexture(knob, ns.T.SCROLL_KNOB, 0.2, 0.8, 0.125, 0.875)
			knob:SetSize(18, 24)
			knob:SetPoint("CENTER", thumb, "CENTER", 0, 0)
			local function PlaceKnob()
				local percentage = scrollBar.GetScrollPercentage and scrollBar:GetScrollPercentage() or 0
				local travel = math.max(0, thumb:GetHeight() - knob:GetHeight())
				ns.Point(knob, "TOP", thumb, "TOP", 0, -travel * percentage)
			end
			if not scrollBar.isHorizontal and ns.Hook(scrollBar, "Update", PlaceKnob) then
				thumb:HookScript("OnSizeChanged", PlaceKnob)
				PlaceKnob()
			end
		end
	end
	SkinStepper(scrollBar.Back, ns.T.SCROLL_UP)
	SkinStepper(scrollBar.Forward, ns.T.SCROLL_DOWN)
end

-- Draws the classic dropdown box (the CharacterCreate label frame art that
-- UIDropDownMenuTemplate used) on a modern WowStyle1 dropdown button. The
-- button's own atlas art is faded, the box is `width` wide plus the art's
-- 25px ends, and the text is right-aligned before the arrow like the
-- classic menu. The menu logic is untouched; the caller positions the
-- button. Blizzard re-sizes some of these buttons to their text on every
-- update, so the width is re-applied after UpdateText.
function ns.SkinDropdownBox(dropdown, width)
	local T = ns.T
	local total = width + 50
	dropdown:SetSize(total, 32)
	if dropdown.Background then dropdown.Background:SetAlpha(0) end
	if dropdown.Arrow then dropdown.Arrow:SetAlpha(0) end
	ns.Hook(dropdown, "UpdateText", function(self) self:SetWidth(total) end)

	local right = dropdown
	if ns.HasTexture(T.DROPDOWN_BOX) then
		local left = dropdown:CreateTexture(nil, "ARTWORK")
		ns.SetTexture(left, T.DROPDOWN_BOX, 0, 0.1953125, 0, 1)
		left:SetSize(25, 64)
		left:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 0, 17)
		local middle = dropdown:CreateTexture(nil, "ARTWORK")
		ns.SetTexture(middle, T.DROPDOWN_BOX, 0.1953125, 0.8046875, 0, 1)
		middle:SetSize(width, 64)
		middle:SetPoint("LEFT", left, "RIGHT", 0, 0)
		right = dropdown:CreateTexture(nil, "ARTWORK")
		ns.SetTexture(right, T.DROPDOWN_BOX, 0.8046875, 1, 0, 1)
		right:SetSize(25, 64)
		right:SetPoint("LEFT", middle, "RIGHT", 0, 0)
	end

	local arrowPrefix = ns.HasTexture(T.CHAT_SCROLL_DOWN .. "Up") and T.CHAT_SCROLL_DOWN or T.SCROLL_DOWN
	local arrow = dropdown:CreateTexture(nil, "OVERLAY")
	ns.SetTexture(arrow, arrowPrefix .. "Up")
	arrow:SetSize(24, 24)
	arrow:SetPoint("TOPRIGHT", right, "TOPRIGHT", -16, -18)
	dropdown:HookScript("OnMouseDown", function() ns.SetTexture(arrow, arrowPrefix .. "Down") end)
	dropdown:HookScript("OnMouseUp", function() ns.SetTexture(arrow, arrowPrefix .. "Up") end)
	dropdown:SetHighlightTexture(T.MOUSE_HIGHLIGHT, "ADD")
	local highlight = dropdown:GetHighlightTexture()
	if highlight then
		highlight:ClearAllPoints()
		highlight:SetSize(24, 24)
		highlight:SetPoint("CENTER", arrow, "CENTER", 0, 0)
	end

	local text = dropdown.Text
	if text then
		text:SetFontObject(GameFontHighlightSmall)
		text:SetJustifyH("RIGHT")
		ns.Point(text, "RIGHT", right, "RIGHT", -43, 2)
	end

	-- A filter dropdown's reset button (the red x, shown while a filter is
	-- off its default) sits on the button's top-right corner, over whatever
	-- is next to the box; it goes into the box's empty left end instead
	-- (the text is right-aligned before the arrow).
	if dropdown.ResetButton then
		ns.Point(dropdown.ResetButton, "CENTER", dropdown, "LEFT", 42, 1)
	end
end

-- The classic red panel button look (UI-Panel-Button-*: the 80x22 button in
-- the corner of the 128x32 files, white text) on a plain button.
function ns.SkinPanelTextButton(button, text)
	button:SetSize(80, 22)
	local file = "Interface\\Buttons\\UI-Panel-Button-"
	for _, state in ipairs({
		{ "SetNormalTexture", "GetNormalTexture", "Up" },
		{ "SetPushedTexture", "GetPushedTexture", "Down" },
		{ "SetDisabledTexture", "GetDisabledTexture", "Disabled" },
		{ "SetHighlightTexture", "GetHighlightTexture", "Highlight", "ADD" },
	}) do
		button[state[1]](button, file .. state[3], state[4])
		local texture = button[state[2]](button)
		if texture then
			texture:ClearAllPoints()
			texture:SetAllPoints(button)
			texture:SetTexCoord(0, 0.625, 0, 0.6875)
		end
	end
	button:SetFontString(button:CreateFontString(nil, "OVERLAY"))
	button:SetNormalFontObject(GameFontHighlight)
	button:SetHighlightFontObject(GameFontHighlight)
	button:SetDisabledFontObject(GameFontDisable)
	button:SetText(text)
end

-- A classic red panel button that closes the panel it is created on
-- (vanilla's Exit / Close buttons), through Blizzard's UIPanelCloseButton
-- click script. Addon code may not hide a UI panel in combat ("Interface
-- action failed because of an AddOn"), and a template script on a button
-- the addon created runs as addon code, so this one only works out of
-- combat; a panel that must close in combat forwards a secure click to its
-- own close button instead (see ProfessionsFrame.lua). `panel` must be the
-- UI panel itself; the caller positions the button.
function ns.CreatePanelCloseTextButton(panel, text)
	local button = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
	ns.SkinPanelTextButton(button, text)
	return button
end

-- The classic round close button (UI-Panel-MinimizeButton, 32x32) on a
-- modern UIPanelCloseButton; the caller positions it.
function ns.SkinCloseButton(close)
	if not close then return end
	close:SetSize(32, 32)
	if ns.HasTexture(ns.T.PANEL_CLOSE .. "Up") then
		close:SetNormalTexture(ns.T.PANEL_CLOSE .. "Up")
		close:SetPushedTexture(ns.T.PANEL_CLOSE .. "Down")
		close:SetDisabledTexture(ns.T.PANEL_CLOSE .. "Disabled")
		close:SetHighlightTexture(ns.T.PANEL_CLOSE .. "Highlight", "ADD")
	end
end

-- PanelTabButtonTemplate draws three atlas pieces for the inactive tab,
-- three for the active one (shown / hidden by PanelTemplates_SelectTab) and
-- three additive highlights. They become the vanilla CharacterFrame tab
-- pieces (UI-Character-InActiveTab, 20px ends) with the classic glow
-- highlight. Vanilla's active tab (UI-Character-ActiveTab) was the same
-- body without its top rim, drawn 5px up into the frame border; the retail
-- client's file of that name is a different, short gold-glow tab, so the
-- active pieces are cut from the inactive file (its rim rows skipped)
-- instead: its body rows (below the top rim, down to the bottom rim) are
-- stretched from 5px above the tab to the inactive tab's bottom edge, and
-- the text stays where the inactive tab has it. Top tabs
-- (PanelTopTabButtonTemplate) are the same art flipped and cut to 24px, as
-- Blizzard's PanelTopTabButtonMixin does with its atlases; their active
-- state is the same art in place (a shift into the panel would cover its
-- top border). `flat` keeps a bottom tab's active state the same art in
-- place too, for tabs drawn under a frame border that the rise would poke
-- out over. The caller positions the tab.
local TAB_RIM_TOP, TAB_RIM_BOTTOM = 0.15625, 0.875 -- InActiveTab: rows 0-4 rim, 5-27 body, 28-31 empty
local TAB_ACTIVE_RISE = 5
local skinnedTabs = setmetatable({}, { __mode = "k" }) -- tab -> "bottom" / "top"

function ns.SkinPanelTab(tab, isTop, flat)
	if not tab or skinnedTabs[tab] then return end
	skinnedTabs[tab] = isTop and "top" or "bottom"
	local T = ns.T
	local height = isTop and 24 or 32
	local topCoord, bottomCoord = 0, 1
	local activeTop, activeBottom, activeHeight, activeY = TAB_RIM_TOP, TAB_RIM_BOTTOM, 28 + TAB_ACTIVE_RISE, TAB_ACTIVE_RISE
	if isTop then
		topCoord, bottomCoord = 1, 0.25
	end
	if isTop or flat then
		activeTop, activeBottom, activeHeight, activeY = topCoord, bottomCoord, height, 0
	end
	local function Piece(texture, left, right, top, bottom, pieceHeight)
		if not texture then return end
		ns.SetTexture(texture, T.TAB_INACTIVE, left, right, top, bottom)
		texture:SetHeight(pieceHeight)
	end
	local function End(texture, left, right, top, bottom, pieceHeight, point, x, y)
		if not texture then return end
		Piece(texture, left, right, top, bottom, pieceHeight)
		texture:SetWidth(20)
		ns.Point(texture, point, tab, point, x, y)
	end
	local topPoint, rightPoint = "TOPLEFT", "TOPRIGHT"
	if isTop then
		topPoint, rightPoint = "BOTTOMLEFT", "BOTTOMRIGHT"
	end
	End(tab.Left, 0, 0.15625, topCoord, bottomCoord, height, topPoint, 0, 0)
	Piece(tab.Middle, 0.15625, 0.84375, topCoord, bottomCoord, height)
	End(tab.Right, 0.84375, 1, topCoord, bottomCoord, height, rightPoint, 0, 0)
	End(tab.LeftActive, 0, 0.15625, activeTop, activeBottom, activeHeight, topPoint, 0, activeY)
	Piece(tab.MiddleActive, 0.15625, 0.84375, activeTop, activeBottom, activeHeight)
	End(tab.RightActive, 0.84375, 1, activeTop, activeBottom, activeHeight, rightPoint, 0, activeY)

	for _, key in ipairs({ "LeftHighlight", "MiddleHighlight", "RightHighlight" }) do
		if tab[key] then tab[key]:SetAlpha(0) end
	end
	if ns.HasTexture(T.TAB_HIGHLIGHT) then
		local glow = tab:CreateTexture(nil, "HIGHLIGHT")
		ns.SetTexture(glow, T.TAB_HIGHLIGHT, 0, 1, topCoord, bottomCoord)
		glow:SetBlendMode("ADD")
		glow:SetHeight(height)
		glow:SetPoint("LEFT", tab, "LEFT", 10, isTop and -2 or 2)
		glow:SetPoint("RIGHT", tab, "RIGHT", -10, isTop and -2 or 2)
	end
end

-- PanelTemplates_SelectTab drops the text 5px for its taller active atlas;
-- the merged classic body keeps the inactive text position.
ns.Hook("PanelTemplates_SelectTab", function(tab)
	if skinnedTabs[tab] == "bottom" and tab.Text then
		tab.Text:SetPoint("CENTER", tab, "CENTER", 0, 2)
	end
end)

---------------------------------------------------------------------------
-- Mirror bars
--
-- Blizzard's unit frame status bars and their containers inherit
-- SecureFrameTemplate, so an addon cannot move or resize them while in
-- combat (the calls are blocked, and Blizzard's secure code restores the
-- retail geometry on every target change). The classic layout therefore
-- draws its bars on unprotected StatusBars that mirror the min/max/value of
-- Blizzard's bar (secret values may be passed through) and only fades
-- Blizzard's fill texture, which is always allowed.
---------------------------------------------------------------------------

ns.mirrors = setmetatable({}, { __mode = "k" }) -- Blizzard bar -> mirror

-- Sets a bar's fill texture. SetStatusBarTexture resets the fill's draw
-- layer, so for mirrors the BACKGROUND layer (behind the frame art) and full
-- alpha are re-applied afterwards.
function ns.SetBarTexture(bar, file)
	bar:SetStatusBarTexture(file)
	if bar.source then
		local fill = bar:GetStatusBarTexture()
		if fill then
			fill:SetAlpha(1)
			fill:SetDrawLayer("BACKGROUND", 0)
		end
	end
end

-- Copies the retail fill texture and colour from the source bar unless a
-- classic module has taken ownership of the mirror's appearance.
function ns.SyncMirrorAppearance(mirror)
	if mirror.classicOwned then return end
	local sourceFill = mirror.source:GetStatusBarTexture()
	local fill = mirror:GetStatusBarTexture()
	if sourceFill and fill then
		local atlas = sourceFill:GetAtlas()
		if atlas then
			fill:SetAtlas(atlas, false)
		else
			local texture = sourceFill:GetTexture()
			if texture then
				fill:SetTexture(texture)
			end
		end
		fill:SetAlpha(1)
		fill:SetDrawLayer("BACKGROUND", 0)
	end
	mirror:SetStatusBarColor(mirror.source:GetStatusBarColor())
end

-- Creates a mirror for a Blizzard status bar. The mirror is a child of the
-- source (so it shows/hides with it) but is given the unit frame's own frame
-- level so it draws behind the classic frame art.
function ns.CreateMirrorBar(source, level)
	local mirror = CreateFrame("StatusBar", nil, source)
	mirror:SetFrameLevel(level)
	mirror.source = source
	ns.SetBarTexture(mirror, ns.T.STATUS_BAR)
	mirror:SetMinMaxValues(source:GetMinMaxValues())
	mirror:SetValue(source:GetValue())
	ns.SyncMirrorAppearance(mirror)

	source:HookScript("OnValueChanged", function(_, value)
		mirror:SetValue(value)
	end)
	source:HookScript("OnMinMaxChanged", function(_, minValue, maxValue)
		mirror:SetMinMaxValues(minValue, maxValue)
	end)

	-- Blizzard's own fill (and spark) become invisible; everything else on
	-- the source bar (texts, overlays) keeps working.
	local fill = source:GetStatusBarTexture()
	if fill then fill:SetAlpha(0) end
	if source.Spark then source.Spark:SetAlpha(0) end

	ns.mirrors[source] = mirror
	return mirror
end

-- The bar that should carry classic textures/colours for a Blizzard bar.
function ns.GetBar(source)
	return ns.mirrors[source] or source
end

-- Moves an unprotected companion frame (loss bars, prediction segments,
-- feedback glows) onto a mirror so it is drawn with the classic bar.
function ns.AttachToMirror(companion, mirror, level)
	if not companion or not companion.SetParent then return end
	companion:SetParent(mirror)
	companion:ClearAllPoints()
	companion:SetAllPoints(mirror)
	if companion.SetFrameLevel then
		companion:SetFrameLevel(level)
	end
end

-- Heal prediction / absorb segments are anchored by Blizzard to the edge of
-- its own (now invisible) fill texture; re-anchor the first segment of each
-- chain to the mirror's fill. Offsets are kept at zero because the values
-- Blizzard uses may be secret and cannot be read by addon code.
local function RetargetSegment(segment, fill)
	if segment and segment.FillMask and segment:IsShown() then
		segment.FillMask:ClearAllPoints()
		segment.FillMask:SetPoint("TOPLEFT", fill, "TOPRIGHT", 0, 0)
		segment.FillMask:SetPoint("BOTTOMLEFT", fill, "BOTTOMRIGHT", 0, 0)
	end
end

local function RetargetHealPrediction(frame)
	local mirror = frame and frame.healthbar and ns.mirrors[frame.healthbar]
	if not mirror then return end
	local fill = mirror:GetStatusBarTexture()
	local mine, other, absorb, healAbsorb = frame.myHealPredictionBar, frame.otherHealPredictionBar, frame.totalAbsorbBar, frame.healAbsorbBar
	local mineShown = mine and mine:IsShown()
	local otherShown = other and other:IsShown()
	local healAbsorbShown = healAbsorb and healAbsorb:IsShown()
	if mineShown then
		RetargetSegment(mine, fill)
	end
	if otherShown and not mineShown then
		RetargetSegment(other, fill)
	end
	if absorb and absorb:IsShown() and not healAbsorbShown and not mineShown and not otherShown then
		RetargetSegment(absorb, fill)
	end
end

local function RetargetManaCostPrediction(frame)
	local mirror = frame and frame.manabar and ns.mirrors[frame.manabar]
	if mirror and frame.myManaCostPredictionBar then
		RetargetSegment(frame.myManaCostPredictionBar, mirror:GetStatusBarTexture())
	end
end

local function SyncMirrorOf(bar)
	local mirror = bar and ns.mirrors[bar]
	if mirror then
		ns.SyncMirrorAppearance(mirror)
	end
end

ns.Hook("UnitFrameHealthBar_Update", SyncMirrorOf)
ns.Hook("UnitFrameManaBar_UpdateType", SyncMirrorOf)
ns.Hook("UnitFrameHealPredictionBars_Update", RetargetHealPrediction)
ns.Hook("UnitFrameManaCostPredictionBars_Update", RetargetManaCostPrediction)

---------------------------------------------------------------------------
-- Saved variables & lifecycle
---------------------------------------------------------------------------

-- Temporary migration from the addon's old name; remove once the beta
-- testers have moved over. Until 2026-09-27 the addon was the
-- ClassicUIRestoration folder with ClassicUIRestorationDB /
-- ClassicUIRestorationCharDB. The client loads saved variables per addon
-- folder, so the old settings can only be read while the old folder is still
-- installed and enabled: it then loads before this one (addons load in folder
-- name order), its settings are copied into an empty table here, and it is
-- disabled (for every character) so the two never run side by side again.
local OLD_ADDON_NAME = "ClassicUIRestoration"

local function MigrateFromOldName(db)
	if not C_AddOns.IsAddOnLoaded(OLD_ADDON_NAME) then
		return false
	end
	local old = ClassicUIRestorationDB
	if type(old) ~= "table" or next(old) == nil then
		old = ClassicUIRestorationCharDB
	end
	if next(db) == nil and type(old) == "table" then
		for key, value in pairs(old) do
			db[key] = value
		end
	end
	C_AddOns.DisableAddOn(OLD_ADDON_NAME)
	return true
end

StaticPopupDialogs["FOREVERMORECLASSICUI_MIGRATED"] = {
	text = ns.TITLE .. "\n\nClassic UI Restoration is now Forevermore Classic UI. Your settings were copied over and the old addon has been disabled; you can delete its ClassicUIRestoration folder from Interface\\AddOns.\n\nBoth ran this session. Reload now?",
	button1 = RELOADUI or "Reload UI",
	button2 = CANCEL or "Cancel",
	OnAccept = function() ReloadUI() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

-- The options are account-wide (ForevermoreClassicUIDB). The same table is
-- also declared per character (ForevermoreClassicUICharDB): both globals point
-- at one table, the client serialises it into both files, and at load the
-- per-character copy is used whenever the account copy comes back empty. On a
-- working client the account copy wins. The mirror was added for an early
-- WoW Forever beta client that wrote both files but loaded neither back (a
-- client bug, fixed by Blizzard by 2026-09-28).
local function InitializeDB()
	local account = ForevermoreClassicUIDB
	local character = ForevermoreClassicUICharDB
	local db = account
	if type(db) ~= "table" or next(db) == nil then
		db = (type(character) == "table" and next(character) ~= nil) and character or {}
	end
	-- The setup wizard opens at login until it has been closed once
	-- (db.setupDone), for new installs and existing users alike.
	ns.migrated = MigrateFromOldName(db)
	ForevermoreClassicUIDB = db
	ForevermoreClassicUICharDB = db
	ns.db = db
	for _, module in ipairs(ns.modules) do
		if module.parent then
			ns.db[module.key] = nil -- follows the parent's setting
		elseif ns.db[module.key] == nil then
			ns.db[module.key] = true
		end
	end
end

local function SafeCall(module, methodName)
	local fn = module[methodName]
	if type(fn) ~= "function" then return end
	xpcall(fn, geterrorhandler(), module)
end

local function ActivateModules()
	for _, module in ipairs(ns.modules) do
		local enabled = ns:IsEnabled(module.key)
		if module.live then
			if enabled then
				SafeCall(module, "Enable")
			end
		else
			if not module.parent then
				ns.appliedState[module.key] = enabled
			end
			if enabled then
				SafeCall(module, "Apply")
			end
		end
	end
	ns.activated = true
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == ADDON_NAME then
			InitializeDB()
			if ns.BuildOptions then
				xpcall(ns.BuildOptions, geterrorhandler(), ns)
			end
			self:UnregisterEvent("ADDON_LOADED")
		end
	elseif event == "PLAYER_LOGIN" then
		ActivateModules()
		if ns.migrated then
			StaticPopup_Show("FOREVERMORECLASSICUI_MIGRATED")
		elseif not ns.db.setupDone and ns.OpenSetup then
			-- PLAYER_LOGIN fires under the loading screen; the wizard opens
			-- as it goes away.
			self:RegisterEvent("LOADING_SCREEN_DISABLED")
		end
	elseif event == "LOADING_SCREEN_DISABLED" then
		self:UnregisterEvent("LOADING_SCREEN_DISABLED")
		if not ns.db.setupDone then
			ns:OpenSetup()
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if #pendingOutOfCombat > 0 then
			local queue = pendingOutOfCombat
			pendingOutOfCombat = {}
			for _, fn in ipairs(queue) do
				xpcall(fn, geterrorhandler())
			end
		end
	end
end)

---------------------------------------------------------------------------
-- Temporary diagnostics ("/cuir debug"): dumps the target frame's health bar
-- geometry. Will be removed once the bar overflow issue is resolved.
---------------------------------------------------------------------------

local function Geo(region)
	local ok, text = pcall(function()
		local w, h = region:GetSize()
		local l, b, rw, rh = region:GetRect()
		local n = region:GetNumPoints()
		local points = {}
		for i = 1, n do
			local point, rel, relPoint, x, y = region:GetPoint(i)
			table.insert(points, string.format("%s->%s.%s(%.0f,%.0f)", point, rel and (rel.GetName and rel:GetName() or "?") or "nil", relPoint or "", x or 0, y or 0))
		end
		return string.format("size=%.1fx%.1f rect=%s,%s %sx%s points=[%s]", w or 0, h or 0, tostring(l and math.floor(l)), tostring(b and math.floor(b)), tostring(rw and math.floor(rw)), tostring(rh and math.floor(rh)), table.concat(points, " "))
	end)
	return ok and text or ("(restricted: " .. tostring(text) .. ")")
end

local function Desc(region, label)
	if not region then print(label .. " = nil") return end
	local ok, text = pcall(function()
		local parts = {}
		table.insert(parts, "shown=" .. tostring(region:IsShown()) .. " visible=" .. tostring(region:IsVisible()))
		table.insert(parts, string.format("alpha=%.2f eff=%.2f", region:GetAlpha() or -1, region.GetEffectiveAlpha and region:GetEffectiveAlpha() or -1))
		if region.GetFrameLevel then
			table.insert(parts, "strata=" .. tostring(region:GetFrameStrata()) .. " level=" .. tostring(region:GetFrameLevel()))
		end
		if region.GetDrawLayer then
			local layer, sub = region:GetDrawLayer()
			table.insert(parts, "layer=" .. tostring(layer) .. "/" .. tostring(sub))
		end
		if region.GetMinMaxValues then
			local mn, mx = region:GetMinMaxValues()
			table.insert(parts, string.format("min=%s max=%s value=%s", tostring(mn), tostring(mx), tostring(region:GetValue())))
			local r, g, b, a = region:GetStatusBarColor()
			table.insert(parts, string.format("color=%.2f,%.2f,%.2f,%.2f", r or -1, g or -1, b or -1, a or -1))
			local fill = region:GetStatusBarTexture()
			if fill then
				table.insert(parts, "tex=" .. tostring(fill:GetAtlas() or fill:GetTexture()) .. " fillshown=" .. tostring(fill:IsShown()) .. string.format(" fillalpha=%.2f", fill:GetAlpha()))
				local l, sub = fill:GetDrawLayer()
				table.insert(parts, "filllayer=" .. tostring(l) .. "/" .. tostring(sub) .. " " .. Geo(fill))
			end
		elseif region.GetTexture then
			table.insert(parts, "tex=" .. tostring(region:GetAtlas() or region:GetTexture()))
		end
		table.insert(parts, "parent=" .. tostring(region:GetParent() and (region:GetParent():GetName() or "(anon)")))
		return table.concat(parts, " ")
	end)
	print(label .. " " .. (ok and text or ("(restricted: " .. tostring(text) .. ")")) .. " " .. Geo(region))
end

local function DebugMirror(label, source)
	local mirror = source and ns.mirrors[source]
	Desc(source, label .. " source")
	Desc(mirror, label .. " mirror")
	if mirror then
		print(label .. " mirror classicOwned=" .. tostring(mirror.classicOwned))
		for i, child in ipairs({ mirror:GetChildren() }) do
			Desc(child, label .. " child" .. i .. " " .. tostring(child:GetName() or child.fillAtlas or child.fillTexture or "?"))
			if child.Fill then Desc(child.Fill, label .. " child" .. i .. ".Fill") end
			if child.FillMask then Desc(child.FillMask, label .. " child" .. i .. ".FillMask") end
		end
		for i, region in ipairs({ mirror:GetRegions() }) do
			Desc(region, label .. " region" .. i)
		end
	end
end

function ns:DebugTarget()
	local frame = TargetFrame
	local main = frame.TargetFrameContent.TargetFrameContentMain
	local hbc = main.HealthBarsContainer
	print("modules: healthbars=" .. tostring(ns:IsEnabled("healthbars")) .. " powerbars=" .. tostring(ns:IsEnabled("powerbars")) .. " unitframes=" .. tostring(ns:IsEnabled("unitframes")))
	print("== TargetFrame " .. Geo(frame) .. " level=" .. tostring(frame:GetFrameLevel()) .. " strata=" .. tostring(frame:GetFrameStrata()))
	print("HealthBarsContainer " .. Geo(hbc) .. " level=" .. tostring(hbc:GetFrameLevel()))
	DebugMirror("T.Health", hbc.HealthBar)
	DebugMirror("T.Mana", main.ManaBar)
	Desc(frame.CUIR_Backdrop, "T.Backdrop")

	local pmain = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
	print("== PlayerFrame " .. Geo(PlayerFrame) .. " level=" .. tostring(PlayerFrame:GetFrameLevel()) .. " strata=" .. tostring(PlayerFrame:GetFrameStrata()))
	DebugMirror("P.Health", pmain.HealthBarsContainer.HealthBar)
	DebugMirror("P.Mana", pmain.ManaBarArea.ManaBar)
end

---------------------------------------------------------------------------
-- Slash command
---------------------------------------------------------------------------

-- Not /fcui: ClassicUI Forever (another addon) registers it, and the last one loaded wins.
SLASH_FOREVERMORECLASSICUI1 = "/fmcui"
SLASH_FOREVERMORECLASSICUI2 = "/forevermore"
SLASH_FOREVERMORECLASSICUI3 = "/cuir"
SLASH_FOREVERMORECLASSICUI4 = "/classicui"
SlashCmdList.FOREVERMORECLASSICUI = function(msg)
	msg = strtrim((msg or ""):lower())
	if msg == "reload" or msg == "rl" then
		ReloadUI()
		return
	elseif (msg == "setup" or msg == "wizard") and ns.OpenSetup then
		ns:OpenSetup()
		return
	elseif msg == "debug" then
		xpcall(ns.DebugTarget, geterrorhandler(), ns)
		return
	elseif msg == "loot" and ns.DebugLoot then
		xpcall(ns.DebugLoot, geterrorhandler(), ns)
		return
	end
	if ns.OpenOptions then
		ns:OpenOptions()
	end
end
