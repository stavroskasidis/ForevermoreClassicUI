--[[
	Forevermore Classic UI - Social window (WoW Forever only)

	Restores the classic social window (the O key): the friends list frame
	of 3.3.5, when Battle.net friends arrived, the vanilla friends frame
	with Battle.net's stone band under its title (UI-FriendsFrame-TopLeft-bnet /
	TopRight-bnet, the only classic friends art with room for the
	Battle.net bar) and the band across its bottom
	(UI-FriendsFrame-Pending-BotLeft / BotRight), with vanilla's scroll
	portrait (FriendsFrameScrollIcon) in its ring: the Battle.net bar and
	the search box in the band, the list in the art's well with the
	classic knob scroll bar in the trough beside it, the tab's button in
	the band under the well and the tabs under the frame.

	Forever's social window is not the FriendsFrame but the 12.x Social UI
	(Blizzard_SocialUI): SocialUIFrame, a 410x675 PortraitFrameTemplate
	with the Battle.net bar under its title, one content frame per tab
	(friends, recent allies, quick join, friend requests, recruit a friend,
	raid), created at load and anchored to the bar and the frame's corners,
	pooled LargeSideTabButtonTemplate icon tabs down its right side
	(released on every hide, laid out again by RefreshTabs on every show)
	and side windows (ignore list, broadcast, raid info) beside the tabs.
	The frame is re-skinned in place:

	  * SocialUIFrame is sized to the classic art (so the panel manager
	    places the next window at its edge) and the art drawn on it from
	    ns.ArtOrigin; its own textures, nine-slice and portrait are faded,
	  * the contact tabs (SocialUIContactsFrameTemplate: a filter bar, a
	    ScrollBox of 70px cards and an action button) are laid out on the
	    art: the filter bar in the band's lower row, the list scaled down
	    into the well, the button in the band under it with the classic red
	    button look,
	  * the raid tab's counters, all-assist box and Raid Info button go into
	    the band, its groups (two columns of four 135px groups) are scaled
	    down into the well,
	  * the side windows open at the art's right edge,
	  * the tabs are Blizzard's pooled tab buttons, drawn as the vanilla tabs
	    under the frame (ns.CharacterWindow.SkinTab), so a click stays
	    Blizzard's.

	The raid tab's player buttons are secure unit buttons: once a raid has
	been shown the window and the raid page are protected, so their size,
	anchors and scales are set once, out of combat, when the window is
	skinned; the hooks only move the (unprotected) tabs. Only widget state is
	touched; no Lua field is written on Blizzard's frames. Applied once at
	login (reload to switch off).
]]

local _, ns = ...
if not ns.IS_FOREVER then return end
local T = ns.T
local Point, SetTexture = ns.Point, ns.SetTexture

T.FRIENDS_FRAME    = "Interface\\FriendsFrame\\UI-FriendsFrame-" -- + TopLeft-bnet / TopRight-bnet / Pending-BotLeft / ...
T.FRIENDS_PORTRAIT = "Interface\\FriendsFrame\\FriendsFrameScrollIcon"
local PANEL_BUTTON = "Interface\\Buttons\\UI-Panel-Button-" -- + Up / Down / Disabled / Highlight

local ADDON = "Blizzard_SocialUI"

local module = ns:RegisterModule({
	key = "socialframe",
	name = "Social Window",
	tooltip = "Restores the classic social window: the friends list frame with the Battle.net bar and the search box in its stone band, the list in its well with the classic scroll bar, the classic buttons and the tabs under the frame.",
	live = false,
})

-- The art (offsets from the top-left corner of its 384x512 files). Its
-- border runs from 12 to 348 across and 13 to 435 down; the panel is the
-- border less ns.CLASSIC_ART_X / Y.
local ART_TOP = { "TopLeft-bnet", "TopRight-bnet" }
local ART_BOTTOM = { "Pending-BotLeft", "Pending-BotRight" }   -- one band across the bottom
local ART_BOTTOM_TWO = { "BotLeft-bnet", "BotRight-bnet" }      -- two button cells, if the client lacks the above
local FRAME_WIDTH, FRAME_HEIGHT = 334, 422
local PORTRAIT_X, PORTRAIT_Y, PORTRAIT_SIZE = 6, -4, 64         -- the ring's hole: 10-64 across, 9-62 down
local TITLE_X, TITLE_Y = 197, -24                               -- centre of the title bar (69-325, 15-32)
local CLOSE_X, CLOSE_Y = 337, -24                               -- centre of the close button's socket
-- The stone band under the title (22-346 across, 34-96 down): the
-- Battle.net bar on its upper row, the filter bar on its lower one.
local BAND_LEFT, BAND_RIGHT = 22, 346
local BN_LEFT, BN_Y, BN_HEIGHT = 70, -49, 30                    -- the bar starts right of the portrait ring
local STATUS_X = 0                                              -- the status dropdown, from the bar's left
local MENU_SIZE, MENU_RIGHT = 28, -4                            -- the Battle.net menu button
local FILTER_Y, FILTER_HEIGHT = -80, 30
local FILTER_WIDTH = 60                                         -- the classic filter box's middle
-- The well (20-318 across, 99-407 down) and the trough right of it
-- (323-341, its arrow boxes 99-115 and 390-407).
local LIST_LEFT, LIST_TOP, LIST_RIGHT, LIST_BOTTOM = 21, -100, 317, -406
local LIST_SCALE = 0.75                                         -- Blizzard's cards: 70px rows laid out for a 385px list
local SCROLLBAR_X, SCROLLBAR_TOP, SCROLLBAR_BOTTOM = 324, -99, -407
-- The band under the well (15-345 across, 411-431 down).
local BUTTON_X, BUTTON_Y, BUTTON_HEIGHT = 180, -421, 22
-- The raid page's groups (RaidFrameSocialView.lua: two columns of 195x135
-- groups 5px / 6px apart from 9, -7) scaled into the well.
local RAID_GROUPS_WIDTH, RAID_GROUPS_HEIGHT = 413, 565
local RAID_COUNTERS_X, RAID_COUNTER_GAP = 186, 46               -- the middle role counter's centre, and the gap
local RAID_ASSIST_X = 6                                         -- the all-assist check box, from the band's left
local RAID_INFO_WIDTH = 80
-- Side windows: at the art's right edge, level with its top.
local SIDE_X, SIDE_Y = 350, -13
-- Tabs (1.12 CharacterFrameTabButtonTemplate), the first one's top left.
-- They hang from under the frame's bottom edge (art rows 432-440: its rim
-- and shadow), which is drawn again over them, so the selected tab's 5px
-- rise goes in under the rim. A row wider than the frame squeezes its
-- labels.
local TAB_X, TAB_Y = 16, -435
local TABS_MAX_WIDTH = 332
local RIM_TOP, RIM_BOTTOM = 432, 440

local frame  -- SocialUIFrame
local origin -- the art's top-left corner (ns.ArtOrigin), which everything is placed from
local bottomArt
local skinnedTabs = setmetatable({}, { __mode = "k" })

local function Fade(region)
	if region then region:SetAlpha(0) end
end

---------------------------------------------------------------------------
-- Frame art
---------------------------------------------------------------------------

local function CreateArt()
	local function Piece(file, width, x, y)
		local texture = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
		texture:SetTexture(T.FRIENDS_FRAME .. file)
		texture:SetSize(width, 256)
		texture:SetPoint("TOPLEFT", origin, "TOPLEFT", x, y)
	end
	Piece(ART_TOP[1], 256, 0, 0)
	Piece(ART_TOP[2], 128, 256, 0)
	Piece(bottomArt[1], 256, 0, -256)
	Piece(bottomArt[2], 128, 256, -256)

	-- Under the art: its ring cuts the square portrait round.
	if ns.HasTexture(T.FRIENDS_PORTRAIT) then
		local portrait = frame:CreateTexture(nil, "BACKGROUND", nil, -2)
		portrait:SetTexture(T.FRIENDS_PORTRAIT)
		portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
		portrait:SetPoint("TOPLEFT", origin, "TOPLEFT", PORTRAIT_X, PORTRAIT_Y)
	end
end

-- The classic red panel button (UI-Panel-Button-*: the 80x22 button in the
-- corner of the 128x32 files, stretched as UIPanelButtonTemplate did) on a
-- Blizzard ThreeSliceButtonTemplate button, whose atlas pieces are swapped
-- by its mixin on every state change and are faded instead. The art is
-- BUTTON_HEIGHT tall across the middle of the button, whatever height
-- Blizzard (or the user's text size) gives it.
local skinnedButtons = setmetatable({}, { __mode = "k" })

local function SkinRedButton(button)
	if not button or skinnedButtons[button] then return end
	skinnedButtons[button] = true
	if not ns.HasTexture(PANEL_BUTTON .. "Up") then return end
	for _, key in ipairs({ "Left", "Right", "Center" }) do
		Fade(button[key])
	end
	Fade(button:GetHighlightTexture())

	local function Piece(layer)
		local texture = button:CreateTexture(nil, layer, nil, 1)
		texture:SetPoint("LEFT", button, "LEFT", 0, 0)
		texture:SetPoint("RIGHT", button, "RIGHT", 0, 0)
		texture:SetHeight(BUTTON_HEIGHT)
		return texture
	end
	local art = Piece("BACKGROUND")
	local glow = Piece("HIGHLIGHT")
	SetTexture(glow, PANEL_BUTTON .. "Highlight", 0, 0.625, 0, 0.6875)
	glow:SetBlendMode("ADD")

	local function Update(pushed)
		local state = not button:IsEnabled() and "Disabled" or pushed and "Down" or "Up"
		SetTexture(art, PANEL_BUTTON .. state, 0, 0.625, 0, 0.6875)
	end
	button:HookScript("OnMouseDown", function() Update(button:IsEnabled()) end)
	button:HookScript("OnMouseUp", function() Update(false) end)
	button:HookScript("OnEnable", function() Update(false) end)
	button:HookScript("OnDisable", function() Update(false) end)
	button:HookScript("OnShow", function() Update(false) end)
	Update(false)
end

-- A MinimalScrollBar as the classic knob bar, in the art's trough.
local function PlaceScrollBar(scrollBar)
	if not scrollBar then return end
	ns.SkinScrollBar(scrollBar)
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("TOPLEFT", origin, "TOPLEFT", SCROLLBAR_X, SCROLLBAR_TOP)
	scrollBar:SetPoint("BOTTOMLEFT", origin, "TOPLEFT", SCROLLBAR_X, SCROLLBAR_BOTTOM)
end

-- The frame's own textures go (its black background, the fades round the
-- Battle.net bar, the camelot overlay's pieces), with its nine-slice and
-- portrait; its title goes to the title bar.
local function SkinFrame()
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:IsObjectType("Texture") then region:SetAlpha(0) end
	end
	Fade(frame.NineSlice)
	Fade(frame.PortraitContainer)

	frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	frame:SetHitRectInsets(0, 0, 0, 0)
	origin = ns.ArtOrigin(frame)
	CreateArt()

	local close = frame.CloseButton
	if close then
		ns.SkinCloseButton(close)
		Point(close, "CENTER", origin, "TOPLEFT", CLOSE_X, CLOSE_Y)
	end
	local title = frame.TitleContainer and frame.TitleContainer.TitleText
	if title then
		Point(title, "CENTER", origin, "TOPLEFT", TITLE_X, TITLE_Y)
	end

	-- The Battle.net bar on the band's upper row: the status dropdown at
	-- its left (Blizzard leaves room for its portrait), the BattleTag on
	-- Blizzard's strip, the menu button at its right.
	local bar = frame.BattleNetBar
	if bar then
		Fade(bar.Background)
		bar:ClearAllPoints()
		bar:SetPoint("LEFT", origin, "TOPLEFT", BN_LEFT, BN_Y)
		bar:SetPoint("RIGHT", origin, "TOPLEFT", BAND_RIGHT, BN_Y)
		bar:SetHeight(BN_HEIGHT)
		local controls = bar.ControlsContainer
		if controls then
			controls:ClearAllPoints()
			controls:SetPoint("LEFT", bar, "LEFT", 0, 0)
			controls:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
			if controls.OnlineStatusDropdown then
				Point(controls.OnlineStatusDropdown, "LEFT", controls, "LEFT", STATUS_X, 0)
			end
			local menu = controls.BattleNetMenuButton
			if menu then
				menu:SetSize(MENU_SIZE, MENU_SIZE)
				Point(menu, "RIGHT", controls, "RIGHT", MENU_RIGHT, 0)
			end
		end
	end

	-- Blizzard puts them right of its tab column.
	for _, window in pairs(frame.sideWindowFrames or {}) do
		Point(window, "TOPLEFT", origin, "TOPLEFT", SIDE_X, SIDE_Y)
	end
end

---------------------------------------------------------------------------
-- Contact tabs (friends, recent allies, quick join, friend requests,
-- recruit a friend)
---------------------------------------------------------------------------

-- The page fills the well. Its dividers go; Blizzard's texts that hang
-- from them (the "unavailable" text, the friend request warning) stay
-- between the band and the button.
local function SkinContacts(page)
	Point(page, "TOPLEFT", origin, "TOPLEFT", LIST_LEFT, LIST_TOP)
	page:SetPoint("BOTTOMRIGHT", origin, "TOPLEFT", LIST_RIGHT, LIST_BOTTOM)
	Fade(page.TopDivider)
	Fade(page.BottomDivider)

	-- The search box and the filter, which Blizzard anchors across the bar,
	-- in the band's lower row; the filter gets the classic dropdown box.
	local bar = page.FilterBar
	if bar then
		bar:ClearAllPoints()
		bar:SetPoint("LEFT", origin, "TOPLEFT", BAND_LEFT, FILTER_Y)
		bar:SetPoint("RIGHT", origin, "TOPLEFT", BAND_RIGHT, FILTER_Y)
		bar:SetHeight(FILTER_HEIGHT)
		if bar.SearchFilterDropdown then
			ns.SkinDropdownBox(bar.SearchFilterDropdown, FILTER_WIDTH)
		end
	end

	-- The cards are scaled down to fit their layout's width in the well.
	local scrollBox = page.ScrollBox
	if scrollBox then
		local s = LIST_SCALE
		scrollBox:SetScale(s)
		scrollBox:ClearAllPoints()
		scrollBox:SetPoint("TOPLEFT", origin, "TOPLEFT", LIST_LEFT / s, LIST_TOP / s)
		scrollBox:SetSize((LIST_RIGHT - LIST_LEFT) / s, (LIST_TOP - LIST_BOTTOM) / s)
	end
	PlaceScrollBar(page.ScrollBar)

	local button = page.ActionButton
	if button then
		SkinRedButton(button)
		Point(button, "CENTER", origin, "TOPLEFT", BUTTON_X, BUTTON_Y)
	end
end

---------------------------------------------------------------------------
-- Raid tab
---------------------------------------------------------------------------

-- The page holds secure unit buttons (anchored to it through its groups),
-- so it is anchored to the window, never to the origin frame.
local function SkinRaid(page)
	local x, y = select(4, origin:GetPoint(1))
	page:ClearAllPoints()
	page:SetPoint("TOPLEFT", frame, "TOPLEFT", x + LIST_LEFT, y + LIST_TOP)
	page:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", x + LIST_RIGHT, y + LIST_BOTTOM)

	-- Blizzard hangs the groups from the all-assist box; they fill the well,
	-- centred across it.
	local groups = page.GroupsFrame
	if groups then
		local width, height = LIST_RIGHT - LIST_LEFT, LIST_TOP - LIST_BOTTOM
		local s = math.min(width / RAID_GROUPS_WIDTH, height / RAID_GROUPS_HEIGHT)
		groups:SetScale(s)
		groups:ClearAllPoints()
		groups:SetPoint("TOPLEFT", page, "TOPLEFT", (width - RAID_GROUPS_WIDTH * s) / 2 / s, 0)
		groups:SetSize(RAID_GROUPS_WIDTH, RAID_GROUPS_HEIGHT)
	end

	-- The controls over the groups go into the band's lower row.
	if page.AllAssistCheckButton then
		Point(page.AllAssistCheckButton, "LEFT", origin, "TOPLEFT", BAND_LEFT + RAID_ASSIST_X, FILTER_Y)
	end
	for i, key in ipairs({ "TankFrame", "HealerFrame", "DamagerFrame" }) do
		if page[key] then
			Point(page[key], "CENTER", origin, "TOPLEFT", RAID_COUNTERS_X + (i - 2) * RAID_COUNTER_GAP, FILTER_Y)
		end
	end
	local info = page.RaidInfoButton
	if info then
		SkinRedButton(info)
		info:SetSize(RAID_INFO_WIDTH, BUTTON_HEIGHT)
		Point(info, "RIGHT", origin, "TOPLEFT", BAND_RIGHT - 6, FILTER_Y)
	end
	local convert = page.ConvertToRaidButton
	if convert then
		SkinRedButton(convert)
		convert:SetHeight(BUTTON_HEIGHT)
		Point(convert, "CENTER", origin, "TOPLEFT", BUTTON_X, BUTTON_Y)
	end
end

---------------------------------------------------------------------------
-- Tabs
---------------------------------------------------------------------------

-- A tab's label: the tab's name (Blizzard's tooltip), with the count
-- Blizzard shows under its icon (the quick join groups).
local function TabLabel(tab)
	local data = tab.tabData
	local label = data and data.tabName or ""
	local count = tab.Count
	if count and count:IsShown() and (count:GetText() or "") ~= "" then
		label = label .. " (" .. count:GetText() .. ")"
	end
	return label
end

-- A tab Blizzard disables (the raid tab in a story raid) has grey text.
local function UpdateTabLook(tab)
	local skin = skinnedTabs[tab]
	if skin and not tab:IsEnabled() then
		skin.text:SetFontObject(GameFontDisableSmall)
	end
end

local LayoutTabs

local function SkinTab(tab)
	local skin = skinnedTabs[tab]
	if skin then return skin end
	skin = ns.CharacterWindow.SkinTab(tab, "")
	skinnedTabs[tab] = skin
	skin.text:SetWordWrap(false)
	Fade(tab.Count)
	-- After the tab skin's own hooks.
	ns.Hook(tab, "SetChecked", UpdateTabLook)
	ns.Hook(tab, "SetTabEnabled", UpdateTabLook)
	tab:HookScript("OnEnter", UpdateTabLook)
	tab:HookScript("OnLeave", UpdateTabLook)
	ns.Hook(tab, "SetCount", function(self)
		if self.tabData and frame:IsShown() then LayoutTabs() end
	end)
	return skin
end

-- After Blizzard's RefreshTabs (a column down the frame's right side): the
-- tabs in Blizzard's order, in a row under the art, each sized to its
-- label.
function LayoutTabs()
	local CW = ns.CharacterWindow
	local tabs, widths = {}, {}
	local total, textTotal = 0, 0
	for _, data in ipairs(frame.availableTabData or {}) do
		local tab = frame:GetTabByType(data.tabType)
		if tab then
			local skin = SkinTab(tab)
			skin.text:SetWidth(0)
			skin.text:SetText(TabLabel(tab))
			local width = math.max(1, math.ceil(skin.text:GetStringWidth()) - 2 * CW.TAB_TEXT_INTO_END)
			tabs[#tabs + 1] = tab
			widths[#tabs] = width
			textTotal = textTotal + width
			total = total + width + 2 * CW.TAB_END - (#tabs > 1 and CW.TAB_OVERLAP or 0)
		end
	end
	local excess = total - TABS_MAX_WIDTH
	local previous
	for i, tab in ipairs(tabs) do
		local skin = skinnedTabs[tab]
		local width = widths[i]
		if excess > 0 then
			width = math.max(1, math.floor(width - excess * width / textTotal))
			skin.text:SetWidth(width + 2 * CW.TAB_TEXT_INTO_END)
		end
		skin.middle:SetWidth(width)
		tab:SetSize(width + 2 * CW.TAB_END, CW.TAB_HEIGHT)
		if previous then
			Point(tab, "TOPLEFT", previous, "TOPRIGHT", -CW.TAB_OVERLAP, 0)
		else
			Point(tab, "TOPLEFT", origin, "TOPLEFT", TAB_X, TAB_Y)
		end
		CW.UpdateTab(tab)
		UpdateTabLook(tab)
		previous = tab
	end
end

-- The frame's bottom rim again, on a frame over the tabs (the pooled tabs
-- are the frame's children, one level above it).
local function CreateTabRim()
	local rim = CreateFrame("Frame", nil, frame)
	rim:SetFrameLevel(frame:GetFrameLevel() + 2)
	rim:SetSize(384, RIM_BOTTOM - RIM_TOP)
	rim:SetPoint("TOPLEFT", origin, "TOPLEFT", 0, -RIM_TOP)
	local top, bottom = (RIM_TOP - 256) / 256, (RIM_BOTTOM - 256) / 256
	local left = rim:CreateTexture(nil, "ARTWORK")
	SetTexture(left, T.FRIENDS_FRAME .. bottomArt[1], 0, 1, top, bottom)
	left:SetSize(256, RIM_BOTTOM - RIM_TOP)
	left:SetPoint("TOPLEFT", rim, "TOPLEFT", 0, 0)
	local right = rim:CreateTexture(nil, "ARTWORK")
	SetTexture(right, T.FRIENDS_FRAME .. bottomArt[2], 0, 1, top, bottom)
	right:SetSize(128, RIM_BOTTOM - RIM_TOP)
	right:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------

local function Skin()
	frame = SocialUIFrame
	if not (frame and frame.tabDefinitions and frame.GetTabByType) then return end
	-- The window's size and the raid page's anchors cannot change in combat
	-- once a raid has been shown (secure unit buttons).
	if InCombatLockdown() then
		ns:RunOutOfCombat(Skin)
		return
	end
	for _, file in ipairs(ART_TOP) do
		if not ns.HasTexture(T.FRIENDS_FRAME .. file) then
			ns.Print("This client does not ship " .. T.FRIENDS_FRAME .. file .. "; the social window keeps the retail look.")
			return
		end
	end
	bottomArt = ns.HasTexture(T.FRIENDS_FRAME .. ART_BOTTOM[1]) and ns.HasTexture(T.FRIENDS_FRAME .. ART_BOTTOM[2])
		and ART_BOTTOM or ART_BOTTOM_TWO

	SkinFrame()
	for _, data in pairs(frame.tabDefinitions) do
		local page = data.contentFrame
		if page then
			if page == frame.RaidFrame then
				SkinRaid(page)
			elseif page.ScrollBox and page.FilterBar then
				SkinContacts(page)
			end
		end
	end
	if ns.CharacterWindow and ns.CharacterWindow.SkinTab then
		ns.Hook(frame, "RefreshTabs", LayoutTabs)
		LayoutTabs()
		CreateTabRim()
	end
end

function module:Apply()
	if C_AddOns.IsAddOnLoaded(ADDON) then
		Skin()
		return
	end
	local loader = CreateFrame("Frame")
	loader:RegisterEvent("ADDON_LOADED")
	loader:SetScript("OnEvent", function(self, _, name)
		if name == ADDON then
			self:UnregisterEvent("ADDON_LOADED")
			xpcall(Skin, geterrorhandler())
		end
	end)
end
