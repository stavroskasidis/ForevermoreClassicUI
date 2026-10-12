--[[
	Forevermore Classic UI - Window Frames

	Most of Blizzard's other windows (vendor, mail, quest and gossip, trade,
	dressing room, tabard, guild registrar and charter, books and letters,
	flight map, macros, the social window, inspect) are ButtonFrameTemplate /
	PortraitFrameTemplate panels. Their stone (UI-Background-Rock), inset
	marble and red panel buttons are still the pre-Dragonflight art; what
	Dragonflight changed is the metal around them (the NineSlice layouts
	PortraitFrameTemplate / ButtonFrameTemplateNoPortrait and their
	Minimizable versions, whose UI-Frame-Metal-* atlases were redrawn, and are
	Forever's bronze on WoW Forever), the red X close button and the tabs.
	This module puts those back on the windows listed in WINDOWS:

	  * the border: Blizzard's NineSlice pieces are faded and the Cataclysm to
	    Legion frame is drawn on the NineSlice container from the legacy
	    UI-Frame-* atlases the client still ships (BasicFrameTemplate, the
	    flight map's frame, is still drawn with them): the portrait ring, the
	    title bar with the dark strip behind the title, the corners and the
	    edges, laid out as the pre-Dragonflight PortraitFrameTemplate did.
	    Blizzard switches a window between its portrait and no-portrait
	    layouts with NineSliceUtil.ApplyLayout (ButtonFrameTemplate_HidePortrait
	    / ShowPortrait), so the border follows it from a hook there; any other
	    layout (a themed border) gets Blizzard's own art back,
	  * the close button: the round classic one on the corner, and the
	    classic bigger / smaller buttons beside it on a minimizable window,
	  * the tabs: the vanilla character window tabs under the window
	    (PanelTabButtonTemplate, ns.SkinPanelTab), the pre-Dragonflight
	    TabButtonTemplate ones at its top (PanelTopTabButtonTemplate, the
	    macro window's),
	  * the trade window's second portrait gets the classic ring too.

	The windows other options redraw in full (character, spellbook, talents,
	professions, trainer, auction house, loot, bags, bank, game menu) are not
	in the list. Windows of load-on-demand addons (macros, inspect) are
	skinned when their addon loads. A window another option draws in full
	on this client is left to it (ns.windowOwners: on WoW Forever the
	Character Window option draws the vanilla inspect window,
	CharacterInspect.lua). The vendor window's icons are a part of this option
	(MerchantFrame.lua).

	Everything is widget state (alpha, textures, the close button's anchor);
	no Lua field is written on Blizzard's frames. Applied once at login
	(reload to switch off).
]]

local _, ns = ...
local T = ns.T

T.PANEL_BIGGER  = "Interface\\Buttons\\UI-Panel-BiggerButton-"  -- + Up / Down / Disabled / Highlight
T.PANEL_SMALLER = "Interface\\Buttons\\UI-Panel-SmallerButton-" -- + Up / Down / Disabled / Highlight
T.HELP_TAB_ACTIVE   = "Interface\\HelpFrame\\HelpFrameTab-Active"
T.HELP_TAB_INACTIVE = "Interface\\HelpFrame\\HelpFrameTab-Inactive"

local module = ns:RegisterModule({
	key = "windows",
	name = "Window Frames",
	tooltip = "Restores the pre-Dragonflight frame on the vendor, mail, quest, gossip, trade, dressing room, tabard, guild charter, book, flight map, macro, social and inspect windows: the silver metal border with the portrait ring, the round close button and the classic tabs, plus the vendor's classic repair / junk icons and plain buyback slot.",
	live = false,
})

-- Global names; the ones a load-on-demand addon creates are skinned when it
-- loads.
local WINDOWS = {
	"MerchantFrame", "MailFrame", "OpenMailFrame", "QuestFrame", "GossipFrame",
	"TradeFrame", "DressUpFrame", "TabardFrame", "GuildRegistrarFrame",
	"PetitionFrame", "ItemTextFrame", "TaxiFrame", "FriendsFrame", "MacroFrame",
	"InspectFrame",
}

---------------------------------------------------------------------------
-- The classic border (shared with the preview)
---------------------------------------------------------------------------

-- The legacy atlases at the sizes of their texture templates
-- (SharedUIPanelTemplates.xml).
local ART = {
	ring     = { "UI-Frame-Portrait", 78, 78 },
	topLeft  = { "UI-Frame-TopLeftCornerNoPortrait", 33, 33 },
	topRight = { "UI-Frame-TopCornerRight", 33, 33 },
	top      = { "_UI-Frame-TitleTile", nil, 28, "horizontal" },
	titleBg  = { "_UI-Frame-TitleTileBg", nil, 18, "horizontal" },
	botLeft  = { "UI-Frame-BotCornerLeft", 14, 14 },
	botRight = { "UI-Frame-BotCornerRight", 11, 11 },
	bottom   = { "_UI-Frame-Bot", nil, 9, "horizontal" },
	left     = { "!UI-Frame-LeftTile", 16, nil, "vertical" },
	right    = { "!UI-Frame-RightTile", 10, nil, "vertical" },
}

function ns.HasClassicBorderArt()
	for _, art in pairs(ART) do
		if not C_Texture.GetAtlasInfo(art[1]) then
			return false
		end
	end
	return true
end

local function Piece(parent, key, layer, sublevel)
	local art = ART[key]
	local texture = parent:CreateTexture(nil, layer, nil, sublevel)
	texture:SetHorizTile(art[4] == "horizontal")
	texture:SetVertTile(art[4] == "vertical")
	ns.SetAtlas(texture, art[1])
	if art[2] then texture:SetWidth(art[2]) end
	if art[3] then texture:SetHeight(art[3]) end
	return texture
end

-- Shows or hides the border; shown, `portrait` picks the portrait ring or
-- the plain top-left corner (the title bar and the left edge start from it).
local function ShowClassicBorder(border, shown, portrait)
	for _, texture in pairs(border) do
		texture:SetShown(shown)
	end
	if not shown then return end
	border.ring:SetShown(portrait)
	border.topLeft:SetShown(not portrait)
	local corner = portrait and border.ring or border.topLeft
	border.top:ClearAllPoints()
	border.top:SetPoint("TOPLEFT", corner, "TOPRIGHT", 0, portrait and -10 or 0)
	border.top:SetPoint("TOPRIGHT", border.topRight, "TOPLEFT", 0, 0)
	border.left:ClearAllPoints()
	border.left:SetPoint("TOPLEFT", corner, "BOTTOMLEFT", portrait and 8 or 0, 0)
	border.left:SetPoint("BOTTOMLEFT", border.botLeft, "TOPLEFT", 0, 0)
end

-- Draws the pre-Dragonflight PortraitFrameTemplate border around `frame`:
-- the metal on `parent` (a frame over the window's content, like its
-- NineSlice), the title strip on `frame` behind the title and portrait.
function ns.CreateClassicBorder(parent, frame, portrait)
	local border = {}
	border.titleBg = Piece(frame, "titleBg", "BACKGROUND", 1)
	border.titleBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -3)
	border.titleBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -25, -3)
	border.ring = Piece(parent, "ring", "OVERLAY", 1)
	border.ring:SetPoint("TOPLEFT", frame, "TOPLEFT", -14, 11)
	border.topLeft = Piece(parent, "topLeft", "OVERLAY")
	border.topLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", -6, 1)
	border.topRight = Piece(parent, "topRight", "OVERLAY")
	border.topRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 1)
	border.top = Piece(parent, "top", "OVERLAY")
	border.botLeft = Piece(parent, "botLeft", "OVERLAY")
	border.botLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -6, -5)
	border.botRight = Piece(parent, "botRight", "OVERLAY")
	border.botRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, -5)
	border.bottom = Piece(parent, "bottom", "OVERLAY")
	border.bottom:SetPoint("BOTTOMLEFT", border.botLeft, "BOTTOMRIGHT", 0, 0)
	border.bottom:SetPoint("BOTTOMRIGHT", border.botRight, "BOTTOMLEFT", 0, 0)
	border.left = Piece(parent, "left", "OVERLAY")
	border.right = Piece(parent, "right", "OVERLAY")
	border.right:SetPoint("TOPRIGHT", border.topRight, "BOTTOMRIGHT", 1, 0)
	border.right:SetPoint("BOTTOMRIGHT", border.botRight, "TOPRIGHT", 0, 0)
	ShowClassicBorder(border, true, portrait)
	return border
end

---------------------------------------------------------------------------
-- The windows
---------------------------------------------------------------------------

local NINE_SLICE_PIECES = {
	"TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
	"TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
}

-- The layouts ButtonFrameTemplate and PortraitFrameTemplate switch between,
-- true for the ones with a portrait.
local LAYOUTS = {
	PortraitFrameTemplate = true,
	PortraitFrameTemplateMinimizable = true,
	ButtonFrameTemplateNoPortrait = false,
	ButtonFrameTemplateNoPortraitMinimizable = false,
}

local borders = setmetatable({}, { __mode = "k" }) -- NineSlice container -> classic border

-- Which of LAYOUTS the container shows, read from its top-left corner's
-- atlas (nil for any other layout).
local function CurrentPortrait(container)
	local corner = container.TopLeftCorner
	local atlas = corner and corner:GetAtlas()
	if not atlas then return nil end
	atlas = atlas:lower()
	for name, portrait in pairs(LAYOUTS) do
		local layout = NineSliceUtil.GetLayout(name)
		local piece = layout and layout.TopLeftCorner
		if piece and piece.atlas and piece.atlas:lower() == atlas then
			return portrait
		end
	end
	return nil
end

local function UpdateBorder(container)
	local portrait = CurrentPortrait(container)
	local classic = portrait ~= nil
	for _, key in ipairs(NINE_SLICE_PIECES) do
		local piece = container[key]
		if piece then piece:SetAlpha(classic and 0 or 1) end
	end
	ShowClassicBorder(borders[container], classic, portrait)
end

-- The round close button sat 4px right of and 5px above the corner.
local function SkinCloseButtons(frame)
	local close = frame.CloseButton
	if not close then return end
	ns.SkinCloseButton(close)
	ns.Point(close, "TOPRIGHT", frame, "TOPRIGHT", 4, 5)

	local maxMin = frame.MaximizeMinimizeFrame or frame.MaxMinButtonFrame
	if not maxMin or not ns.HasTexture(T.PANEL_BIGGER .. "Up") then return end
	for key, prefix in pairs({ MaximizeButton = T.PANEL_BIGGER, MinimizeButton = T.PANEL_SMALLER }) do
		local button = maxMin[key]
		if button then
			button:SetNormalTexture(prefix .. "Up")
			button:SetPushedTexture(prefix .. "Down")
			button:SetDisabledTexture(prefix .. "Disabled")
			button:SetHighlightTexture(prefix .. "Highlight", "ADD")
		end
	end
	maxMin:SetSize(32, 32)
	-- The classic buttons' art has a transparent margin; they overlap by it.
	ns.Point(maxMin, "RIGHT", close, "LEFT", 10, 0)
end

-- Vanilla hung the bottom tabs from the frame's bottom edge, each as wide as
-- its label plus the tab's ends and 16px into the one before
-- (CharacterFrame.lua's tabs). Blizzard sizes them for the modern art
-- (PanelTemplates_TabResize, on every show: the label and 20px, which is
-- all ends for the vanilla art) and anchors them from its XML or
-- PanelTemplates_AnchorTabs with gaps the modern art's overhanging ends
-- fill, so they are laid out again after it. They stay under the border
-- (Blizzard's frame levels), which covers their tops, so the selected tab
-- keeps the same art in place (its vanilla rise would poke out over the
-- stone) and only its white text marks it.
-- TAB_Y tucks a tab's top under the border's lower edge and TAB_OVERLAP
-- makes neighbouring tabs' outlines meet (measured in game on Forever,
-- 2026-09-29).
local TAB_X, TAB_Y, TAB_END, TAB_TEXT_INTO_END, TAB_OVERLAP = 12, 1, 20, 7, 19
local bottomTabs = setmetatable({}, { __mode = "k" }) -- window -> its skinned bottom tabs
local tabWindows = setmetatable({}, { __mode = "k" }) -- bottom tab -> its window

-- Lays the shown `tabs` out under `frame` (the bank's tab system too).
function ns.LayoutClassicTabs(frame, tabs)
	local previous
	for _, tab in ipairs(tabs) do
		if tab:IsShown() then
			local textWidth = tab.Text and math.ceil(tab.Text:GetStringWidth()) or 0
			tab:SetWidth(math.max(1, textWidth - 2 * TAB_TEXT_INTO_END) + 2 * TAB_END)
			if previous then
				ns.Point(tab, "TOPLEFT", previous, "TOPRIGHT", -TAB_OVERLAP, 0)
			else
				ns.Point(tab, "TOPLEFT", frame, "BOTTOMLEFT", TAB_X, TAB_Y)
			end
			previous = tab
		end
	end
end

local function LayoutTabs(frame)
	ns.LayoutClassicTabs(frame, bottomTabs[frame])
end

local tabHooksInstalled = false

local function InstallTabHooks()
	if tabHooksInstalled then return end
	tabHooksInstalled = true
	ns.Hook("PanelTemplates_TabResize", function(tab)
		local frame = tabWindows[tab]
		if frame then LayoutTabs(frame) end
	end)
	for _, name in ipairs({ "PanelTemplates_AnchorTabs", "PanelTemplates_UpdateTabs" }) do
		ns.Hook(name, function(frame)
			if bottomTabs[frame] then LayoutTabs(frame) end
		end)
	end
end

-- Top tabs (PanelTopTabButtonTemplate, the macro window's) were
-- TabButtonTemplate before Dragonflight: HelpFrameTab-Inactive, and
-- HelpFrameTab-Active 3px lower while selected (it joins the box under it),
-- each cut into 16px ends and a middle, 32px tall from the tab's bottom edge
-- (the art is the file's lower 21 rows), with UI-Character-Tab-Highlight
-- hanging 8px under it, 7px wider each side (9.2.7
-- SharedUIPanelTemplates.xml). 9.2 put the label 2px above the tab's centre
-- (3px below it while selected), which pokes it out over the inactive art's
-- top with today's font; it sits as deep in both states instead. The
-- template's middle pieces tile, and a file (clamped, unlike its atlases)
-- tiles its transparent last column, so the tiling is switched off. The
-- tabs keep Blizzard's place; their width is 9.2's (label + 17px:
-- PanelTemplates_TabResize(tab, -15) on 16px ends), re-applied after every
-- PanelTemplates_TabResize (each tab's OnShow) and kept inside the window, so
-- the second label is no longer cut short at the window's maxTabWidth.
local HELP_TAB_END, HELP_TAB_PADDING, HELP_TAB_ACTIVE_DROP = 16, 17, 3
local HELP_TAB_TEXT_Y, HELP_TAB_ACTIVE_TEXT_Y = 0, -3
local helpTabs = setmetatable({}, { __mode = "k" }) -- tab -> its window

local function PlaceHelpTabText(tab)
	if tab.Text then
		tab.Text:SetPoint("CENTER", tab, "CENTER", 0, tab.LeftActive:IsShown() and HELP_TAB_ACTIVE_TEXT_Y or HELP_TAB_TEXT_Y)
	end
end

local function SkinHelpTab(frame, tab)
	if helpTabs[tab] then return end
	helpTabs[tab] = frame
	local function Pieces(file, left, middle, right, y)
		for _, piece in ipairs({ { left, 0, 0.25 }, { middle, 0.25, 0.75 }, { right, 0.75, 1 } }) do
			piece[1]:SetHorizTile(false)
			ns.SetTexture(piece[1], file, piece[2], piece[3], 0, 1)
			piece[1]:SetHeight(32)
		end
		left:SetWidth(HELP_TAB_END)
		right:SetWidth(HELP_TAB_END)
		ns.Point(left, "BOTTOMLEFT", tab, "BOTTOMLEFT", 0, y)
		ns.Point(right, "BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, y)
		ns.Point(middle, "TOPLEFT", left, "TOPRIGHT", 0, 0)
		middle:SetPoint("TOPRIGHT", right, "TOPLEFT", 0, 0)
	end
	Pieces(T.HELP_TAB_INACTIVE, tab.Left, tab.Middle, tab.Right, 0)
	Pieces(T.HELP_TAB_ACTIVE, tab.LeftActive, tab.MiddleActive, tab.RightActive, -HELP_TAB_ACTIVE_DROP)
	for _, key in ipairs({ "LeftHighlight", "MiddleHighlight", "RightHighlight" }) do
		if tab[key] then tab[key]:SetAlpha(0) end
	end
	if ns.HasTexture(T.TAB_HIGHLIGHT) then
		local glow = tab:CreateTexture(nil, "HIGHLIGHT")
		ns.SetTexture(glow, T.TAB_HIGHLIGHT)
		glow:SetBlendMode("ADD")
		glow:SetHeight(32)
		glow:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", -5, -8)
		glow:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 9, -8)
	end
	PlaceHelpTabText(tab)
end

local function SizeHelpTab(tab)
	local frame, text = helpTabs[tab], tab.Text
	if not (text and text.GetUnboundedStringWidth) then return end
	local width = math.ceil(text:GetUnboundedStringWidth()) + HELP_TAB_PADDING
	local left, right = tab:GetLeft(), frame:GetRight()
	if left and right then
		width = math.min(width, math.floor(right - left) - TAB_X)
	end
	tab:SetWidth(width)
	text:SetWidth(width - HELP_TAB_PADDING)
end

local helpTabHooksInstalled = false

local function InstallHelpTabHooks()
	if helpTabHooksInstalled then return end
	helpTabHooksInstalled = true
	for _, name in ipairs({ "PanelTemplates_SelectTab", "PanelTemplates_DeselectTab", "PanelTemplates_SetDisabledTabState" }) do
		ns.Hook(name, function(tab)
			if helpTabs[tab] then PlaceHelpTabText(tab) end
		end)
	end
	ns.Hook("PanelTemplates_TabResize", function(tab)
		if helpTabs[tab] then SizeHelpTab(tab) end
	end)
end

local function SkinTabs(frame)
	if not frame.Tabs then return end
	local topTabLoad = PanelTopTabButtonMixin and PanelTopTabButtonMixin.OnLoad
	local helpArt = ns.HasTexture(T.HELP_TAB_ACTIVE) and ns.HasTexture(T.HELP_TAB_INACTIVE)
	local bottom, top = {}, false
	for _, tab in ipairs(frame.Tabs) do
		-- Only PanelTabButtonTemplate's pieces (other templates also collect
		-- into a Tabs array).
		if tab.LeftActive and tab.MiddleActive and tab.RightActive then
			local isTop = topTabLoad ~= nil and tab.OnLoad == topTabLoad
			if isTop and helpArt then
				SkinHelpTab(frame, tab)
				SizeHelpTab(tab)
				top = true
			else
				ns.SkinPanelTab(tab, isTop, true)
				if not isTop then
					table.insert(bottom, tab)
					tabWindows[tab] = frame
				end
			end
		end
	end
	if top then
		InstallHelpTabHooks()
	end
	if #bottom == 0 then return end
	bottomTabs[frame] = bottom
	InstallTabHooks()
	frame:HookScript("OnShow", LayoutTabs)
	LayoutTabs(frame)
end

-- The trade window draws the other player's portrait in a ring of its own.
local function SkinTradeRecipient(frame)
	local overlay = frame.RecipientOverlay
	local ring = overlay and overlay.portraitFrame
	if ring and overlay.portrait and ns.SetAtlas(ring, ART.ring[1]) then
		ring:SetSize(ART.ring[2], ART.ring[3])
		-- The same place around the portrait as the window's own ring.
		ns.Point(ring, "TOPLEFT", overlay.portrait, "TOPLEFT", -8, 4)
	end
end

local function SkinWindow(frame)
	local container = frame.NineSlice
	if container and not borders[container] then
		borders[container] = ns.CreateClassicBorder(container, frame, false)
		UpdateBorder(container)
	end
	SkinCloseButtons(frame)
	SkinTabs(frame)
	if frame == TradeFrame then
		SkinTradeRecipient(frame)
	end
end

-- Window name -> function returning true while another option draws that
-- window in full (set by that option's file, loaded after this one).
ns.windowOwners = {}

local pending = {}
local watcher

local function SkinPending()
	for name in pairs(pending) do
		local frame = _G[name]
		if frame then
			pending[name] = nil
			local owner = ns.windowOwners[name]
			if not (owner and owner()) then
				xpcall(SkinWindow, geterrorhandler(), frame)
			end
		end
	end
	if watcher and not next(pending) then
		watcher:UnregisterAllEvents()
	end
end

---------------------------------------------------------------------------
-- Module entry point
---------------------------------------------------------------------------

function module:Apply()
	if not ns.HasClassicBorderArt() then
		ns.Print("This client does not ship the classic window frame art; the windows keep their modern frame.")
		return
	end
	-- Tooltips re-apply their layout on every show, so the hook returns at
	-- once for any container that is not a skinned window's.
	ns.Hook(NineSliceUtil, "ApplyLayout", function(container)
		if borders[container] then
			UpdateBorder(container)
		end
	end)
	for _, name in ipairs(WINDOWS) do
		pending[name] = true
	end
	SkinPending()
	if next(pending) then
		watcher = CreateFrame("Frame")
		watcher:RegisterEvent("ADDON_LOADED")
		watcher:SetScript("OnEvent", SkinPending)
	end
end
