--[[
	Forevermore Classic UI - Previews (WoW Forever only)

	Forever's modern look is the mainline UI with the camelot overlay, which
	redraws some of the frames the previews picture. Its "modern" pictures
	replace the retail ones here, drawn from the forever branch of Blizzard's
	source (the Camelot\ folders):
	  * nameplates: the name inside the health bar, the level in its box
	    (ui-hud-nameplates-levelindicator) to the right of the bar
	    (Blizzard_NamePlateLevelFrame.xml, Blizzard_NamePlateConstants.lua);
	  * gryphons: always gryphons, 154x95 (MainMenuBarEndCaps.xml);
	  * bags: square 45px slots in the action button frame
	    (ui-hud-actionbar-iconframe-bags) on the action bar plate, the
	    ui-hud-actionbar-bag backpack and the narrow key ring
	    (MainMenuBarBagButtons.xml / .lua);
	  * XP & reputation bars: the full-width bars with twenty segments
	    (StatusTrackingBarConstants.lua), which the classic frame is fitted
	    to as well;
	  * micro menu: the retail buttons on the action bar plate
	    (MainMenuBarMicroMenu.xml), with Forever's spellbook button;
	  * minimap: the UI-HUD-Minimap-Frame art around the map cut by its
	    generic mask (Camelot\Minimap.lua);
	  * bank: the slot atlases and uniform columns of Camelot\BankFrame.xml.
	The windows (character, spellbook, talents, trainer, auction house,
	professions, loot) are in-game screenshots of both looks instead, in
	Textures\Previews; the Looking For Group and social windows have a
	screenshot of their modern look and a drawing of their classic one
	(GroupFinder.lua's and SocialFrame.lua's layouts).
]]

local _, ns = ...
if not ns.IS_FOREVER then return end

local K = ns.PreviewKit
local Previews = ns.Previews

-- Forever's windows are shown as screenshots (see ns.PreviewImages in
-- Previews.lua); tools/make_previews.py makes the files and these entries.
local function Image(file, width, height, fileWidth, fileHeight)
	return { file = file, width = width, height = height, fileWidth = fileWidth, fileHeight = fileHeight }
end

ns.PreviewImages = {
	characterframe = {
		modern = Image("forever-characterframe-modern", 224, 256, 256, 256),
		classic = Image("forever-characterframe-classic", 188, 256, 256, 256),
	},
	spellbook = {
		modern = Image("forever-spellbook-modern", 285, 256, 512, 256),
		classic = Image("forever-spellbook-classic", 262, 256, 512, 256),
	},
	talents = {
		modern = Image("forever-talents-modern", 429, 256, 512, 256),
		classic = Image("forever-talents-classic", 228, 256, 256, 256),
	},
	trainer = {
		modern = Image("forever-trainer-modern", 208, 256, 256, 256),
		classic = Image("forever-trainer-classic", 202, 256, 256, 256),
	},
	auctionhouse = {
		modern = Image("forever-auctionhouse-modern", 381, 256, 512, 256),
		classic = Image("forever-auctionhouse-classic", 489, 256, 512, 256),
	},
	professions = {
		modern = Image("forever-professions-modern", 289, 256, 512, 256),
		classic = Image("forever-professions-classic", 207, 256, 256, 256),
	},
	lootframe = {
		modern = Image("forever-lootframe-modern", 220, 145, 256, 256),
		classic = Image("forever-lootframe-classic", 190, 245, 256, 256),
	},
	lfgframe = {
		modern = Image("forever-lfgframe-modern", 240, 256, 256, 256),
	},
	socialframe = {
		modern = Image("forever-socialframe-modern", 176, 256, 256, 256),
	},
}
local Atlas, At, Color, File, Fill, Layer, Mask = K.Atlas, K.At, K.Color, K.File, K.Fill, K.Layer, K.Mask

---------------------------------------------------------------------------
-- Nameplates
---------------------------------------------------------------------------

-- Constants: 190 wide less 12 each side, the large bar 20 tall, the level
-- box 28 wide and 5px right of the bar.
local PLATE_WIDTH, PLATE_HEIGHT = 166, 20
local LEVEL_WIDTH, LEVEL_HEIGHT = 28, 23

Previews.nameplates.width = PLATE_WIDTH + 5 + LEVEL_WIDTH + 16
Previews.nameplates.modern = function(c)
	local barX, barY = 8, -14
	Color(c, 0, 0, 0, 1, PLATE_WIDTH + 2, PLATE_HEIGHT + 2, barX - 1, barY + 1, "BACKGROUND", -2)
	Color(c, 0.08, 0.08, 0.08, 1, PLATE_WIDTH, PLATE_HEIGHT, barX, barY, "BACKGROUND", -1)
	At(Fill(c, "UI-HUD-CoolDownManager-Bar", PLATE_WIDTH, PLATE_HEIGHT, 0.8, { 0.9, 0.1, 0.1 }, "ARTWORK"), "TOPLEFT", barX, barY)
	local name = c:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	name:SetText(K.NAMEPLATE_NAME)
	name:SetShadowOffset(1, -1)
	name:SetPoint("LEFT", c, "TOPLEFT", barX + 6, barY - PLATE_HEIGHT / 2)
	local levelX = barX + PLATE_WIDTH + 5
	local box = Atlas(c, "ui-hud-nameplates-levelindicator", "ARTWORK", 0, LEVEL_WIDTH, LEVEL_HEIGHT)
	box:SetPoint("LEFT", c, "TOPLEFT", levelX, barY - PLATE_HEIGHT / 2)
	local level = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	level:SetText("11")
	level:SetTextColor(1, 0.82, 0)
	level:SetPoint("CENTER", box, "CENTER", 0, 0)
end

---------------------------------------------------------------------------
-- Action bar gryphons
---------------------------------------------------------------------------

Previews.endcaps.modern = function(c)
	local barX, barBottom = K.EndCapBar(c)
	local left = Atlas(c, "ui-hud-actionbar-gryphon-left", "OVERLAY", 1, 154, 95)
	left:SetPoint("BOTTOMRIGHT", c, "TOPLEFT", barX + 9, barBottom - 5)
	local right = Atlas(c, "ui-hud-actionbar-gryphon-right", "OVERLAY", 1, 154, 95)
	right:SetPoint("BOTTOMLEFT", c, "TOPLEFT", barX + K.ENDCAP_BAR_WIDTH - 9, barBottom - 5)
end

---------------------------------------------------------------------------
-- Bags
---------------------------------------------------------------------------

local SLOT, PADDING, KEYRING_WIDTH = 45, 2, 33
local BAR_WIDTH = KEYRING_WIDTH + PADDING + 5 * SLOT + 4 * PADDING

local function BagSlot(c, x, y, width, icon, frameAtlas)
	local slot = CreateFrame("Frame", nil, c)
	slot:SetSize(width, SLOT)
	slot:SetPoint("TOPLEFT", c, "TOPLEFT", x, y)
	local texture = slot:CreateTexture(nil, "ARTWORK")
	texture:SetPoint("CENTER", slot, "CENTER", 0, 0)
	texture:SetSize(width, SLOT)
	if icon then
		texture:SetTexture(icon)
		local mask = slot:CreateMaskTexture()
		if ns.SetAtlas(mask, "UI-HUD-ActionBar-IconFrame-Mask") then
			mask:SetAllPoints(texture)
			texture:AddMaskTexture(mask)
		end
	else
		ns.SetAtlas(texture, "ui-hud-actionbar-iconframe-slot")
	end
	At(Atlas(slot, frameAtlas, "OVERLAY", 0, width + 1, SLOT + 1), "TOPLEFT")
	return slot
end

Previews.bags.width = BAR_WIDTH + 24
Previews.bags.height = 70
Previews.bags.modern = function(c)
	local x, y = 12, -12
	local plate = Atlas(c, "UI-HUD-ActionBar-Frame", "BACKGROUND", -3)
	plate:SetPoint("TOPLEFT", c, "TOPLEFT", x - 6, y + 6)
	plate:SetPoint("BOTTOMRIGHT", c, "TOPLEFT", x + BAR_WIDTH + 5, y - SLOT - 5)
	-- The key ring, then bags 4..1, then the backpack at the right end.
	local keyring = BagSlot(c, x, y, KEYRING_WIDTH, nil, "UI-HUD-ActionBar-IconFrame-Small")
	local ring = Atlas(keyring, "UI-HUD-ActionBar-Keyring-Small", "OVERLAY", 1)
	ring:SetPoint("CENTER", keyring, "CENTER", 0, 0)
	x = x + KEYRING_WIDTH + PADDING
	for bag = 4, 1, -1 do
		BagSlot(c, x, y, SLOT, K.BagIcon(bag), "ui-hud-actionbar-iconframe-bags")
		x = x + SLOT + PADDING
	end
	BagSlot(c, x, y, SLOT, "Interface\\Icons\\ui-hud-actionbar-bag", "ui-hud-actionbar-iconframe-bags")
end

---------------------------------------------------------------------------
-- XP & reputation bars
---------------------------------------------------------------------------

-- Camelot\StatusTrackingBarConstants.lua: 1192px containers with 1189x14
-- bars, twenty segments, the rested tick level with the bar's middle. Both
-- looks change, since the classic frame is fitted to the bar.
Previews.xpbar.classic, Previews.xpbar.modern = K.StatusBarPictures({ width = 1192, barWidth = 1189, barHeight = 14, tickOffset = 0, segments = 20 })

---------------------------------------------------------------------------
-- Micro menu
---------------------------------------------------------------------------

local MICRO = { "SpellbookAbilities", "SpecTalents", "Achievements", "Questlog", "GuildCommunities", "Groupfinder", "Collections", "GameMenu" }
local MICRO_STRIDE = 27 -- 32px buttons, 5px into each other
local MICRO_WIDTH = #MICRO * MICRO_STRIDE + 5

Previews.micromenu.width = MICRO_WIDTH + 60
Previews.micromenu.height = 70
Previews.micromenu.modern = function(c)
	local x, y = 30, -15
	local plate = Atlas(c, "UI-HUD-ActionBar-Frame", "BACKGROUND", -3)
	plate:SetPoint("TOPLEFT", c, "TOPLEFT", x - 8, y + 8)
	plate:SetPoint("BOTTOMRIGHT", c, "TOPLEFT", x + MICRO_WIDTH + 8, y - 40 - 8)
	local background = Atlas(c, "UI-HUD-ActionBar-IconFrame-Background", "BACKGROUND", -4)
	background:SetPoint("TOPLEFT", plate, "TOPLEFT", -13, 0)
	background:SetPoint("BOTTOMRIGHT", plate, "BOTTOMRIGHT", 14, 4)
	for i, name in ipairs(MICRO) do
		local centerX = x + 16 + (i - 1) * MICRO_STRIDE
		At(Atlas(c, "UI-HUD-MicroMenu-ButtonBG-Up", "BACKGROUND"), "CENTER", centerX, y - 20, c, "TOPLEFT")
		At(Atlas(c, "UI-HUD-MicroMenu-" .. name .. "-Up", "ARTWORK", 0, 32, 40), "CENTER", centerX, y - 20, c, "TOPLEFT")
	end
end

---------------------------------------------------------------------------
-- Minimap
---------------------------------------------------------------------------

Previews.minimap.modern = function(c)
	-- Camelot\Minimap.lua: the frame art at its own size centred on the
	-- 198px map, which its generic mask cuts to the frame's opening; the
	-- zone text on its header button between the tracking and calendar
	-- buttons (drawn a little smaller to fit the picture).
	local mapX, mapY = 105, -120
	K.MapDisc(c, 170, mapX, mapY, "ui-hud-minimap-frame-generic-mask")
	local art = Layer(c, 5)
	local frame = Atlas(art, "UI-HUD-Minimap-Frame", "ARTWORK")
	local width, height = frame:GetSize()
	if width and width > 0 then
		frame:SetSize(width * 170 / 198, height * 170 / 198)
	end
	frame:SetPoint("CENTER", art, "TOPLEFT", mapX, mapY)
	local header = Atlas(art, "ui-hud-minimap-header-button", "ARTWORK", 1, 140, 21)
	header:SetPoint("TOPLEFT", art, "TOPLEFT", 24, -2)
	local zone = art:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	zone:SetText(K.ZoneText())
	zone:SetPoint("LEFT", header, "LEFT", 8, -1)
	local tracking = Atlas(art, "ui-hud-minimap-tracking-button", "OVERLAY", 0, 21, 21)
	tracking:SetPoint("RIGHT", header, "LEFT", 0, 0)
	local calendar = Atlas(art, "ui-hud-minimap-calendar-button", "OVERLAY", 0, 21, 21)
	calendar:SetPoint("TOPLEFT", header, "TOPRIGHT", -4, 0)
	local zoomIn = Atlas(art, "ui-hud-minimap-zoom-in", "OVERLAY")
	zoomIn:SetPoint("CENTER", art, "TOPLEFT", mapX + 72, mapY - 62)
	local zoomOut = Atlas(art, "ui-hud-minimap-zoom-out", "OVERLAY")
	zoomOut:SetPoint("CENTER", art, "TOPLEFT", mapX + 56, mapY - 76)
end

-- Bank: Camelot\BankFrame.xml's slots, 13px apart across from 47px in (eight
-- columns; the picture shows seven), 47px down, on bags-item-bankslot64
-- under bank-frame-item-slotframe (bank-frame-bag-slotframe while the slot
-- holds an item; BankFrame.lua's CamelotBankPanelItemButtonMixin:Refresh).
local BANK_WIDTH = 47 + 6 * 50 + 37 + 47
Previews.bank.width = 18 + BANK_WIDTH + 12
Previews.bank.modern = function(c)
	K.ModernBank(c, BANK_WIDTH, function(column)
		return 47 + column * 50
	end, "bags-item-bankslot64", function(holdsItem)
		return holdsItem and "bank-frame-bag-slotframe" or "bank-frame-item-slotframe"
	end)
end

---------------------------------------------------------------------------
-- Looking For Group (GroupFinder.lua: Classic Era's layout on UI-LFG-FRAME)
---------------------------------------------------------------------------

local LFG_FRAME = "Interface\\LFGFrame\\UI-LFG-FRAME"
local LFG_ROLES = "Interface\\LFGFrame\\UI-LFG-ICON-ROLES"
local LFG_ROLE_BACKGROUNDS = "Interface\\LFGFrame\\UI-LFG-ICONS-ROLEBACKGROUNDS"
local LFG_ROLES_SHOWN = { { "TANK", 0.6 }, { "HEALER", 0.4 }, { "DAMAGER", 0.6, true } }
local LFG_CATEGORIES = {
	{ "groupfinder-button-dungeons", "Dungeons" },
	{ "groupfinder-button-questing", "Quests & Zones" },
	{ "groupfinder-button-battlegrounds", "Battlegrounds" },
	{ "groupfinder-button-custom-pve", "Custom" },
}
local LFG_TAB_LABELS = { LFG_LIST_TAB_1 or "List Self", LFG_LIST_TAB_2 or "Browse Groups", LFG_LIST_TAB_3 or "Who" }

-- A vanilla tab (UI-Character-InActiveTab, 20px ends) sized to its label;
-- returns its width.
local function LfgTab(c, x, y, label, selected)
	local text = K.Text(c, selected and "GameFontHighlightSmall" or "GameFontNormalSmall", label, "CENTER", 0, 0)
	local middle = math.max(1, math.ceil(text:GetStringWidth()) - 14)
	local width = middle + 40
	File(c, ns.T.TAB_INACTIVE, 20, 32, x, y, "BACKGROUND", 2, { 0, 0.15625, 0, 1 })
	File(c, ns.T.TAB_INACTIVE, middle, 32, x + 20, y, "BACKGROUND", 2, { 0.15625, 0.84375, 0, 1 })
	File(c, ns.T.TAB_INACTIVE, 20, 32, x + 20 + middle, y, "BACKGROUND", 2, { 0.84375, 1, 0, 1 })
	text:ClearAllPoints()
	At(text, "CENTER", x + width / 2, y - 14, c, "TOPLEFT")
	return width
end

-- A disabled red panel button in the band under the window.
local function LfgButton(c, x, width, label)
	File(c, "Interface\\Buttons\\UI-Panel-Button-Disabled", width, 22, x, -411, "ARTWORK", 0, { 0, 0.625, 0, 0.6875 })
	K.Text(c, "GameFontDisable", label, "CENTER", x + width / 2, -422, "TOPLEFT")
end

Previews.lfgframe = {
	width = 384, height = 470,
	classic = function(c)
		File(c, "Interface\\LFGFrame\\UI-LFG-PORTRAIT", 64, 64, 9, -5, "BACKGROUND", -2)
		File(c, LFG_FRAME, 512, 256, 0, 0, "BACKGROUND", -1, { 0, 1, 0, 0.5 })
		local background = Atlas(c, "groupfinder-background-classic", "BACKGROUND", 0, 324, 282)
		if not background:IsShown() then
			background = Atlas(c, "groupfinder-background", "BACKGROUND", 0, 324, 282)
		end
		At(background, "TOPLEFT", 22, -129)
		File(c, LFG_FRAME, 512, 256, 0, -256, "BACKGROUND", 1, { 0, 1, 0.5, 1 })
		K.Text(c, "GameFontNormal", LFG_TITLE or "Looking For Group", "TOP", 192, -17, "TOPLEFT")
		File(c, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 32, 32, 323, -9, "ARTWORK")

		for i, role in ipairs(LFG_ROLES_SHOWN) do
			local x, y = 67 + (i - 1) * 73, -60
			File(c, LFG_ROLE_BACKGROUNDS, 80, 80, x - 16, y + 16, "BORDER", 0, { GetBackgroundTexCoordsForRole(role[1]) }):SetAlpha(role[2])
			File(c, LFG_ROLES, 48, 48, x, y, "ARTWORK", 0, { GetTexCoordsForRole(role[1]) })
			File(c, "Interface\\Buttons\\UI-CheckBox-Up", 24, 24, x - 5, y - 29, "OVERLAY", 0)
			if role[3] then
				File(c, "Interface\\Buttons\\UI-CheckBox-Check", 24, 24, x - 5, y - 29, "OVERLAY", 1)
			end
		end
		File(c, LFG_ROLES, 48, 48, 289, -60, "ARTWORK", 0, { GetTexCoordsForRole("GUIDE") })
		File(c, "Interface\\Buttons\\UI-CheckBox-Up", 24, 24, 284, -89, "OVERLAY", 0)
		local badge = Atlas(c, "newplayerchat-chaticon-newcomer", "OVERLAY", 1, 20, 20)
		At(badge, "BOTTOMRIGHT", 338, -109, c, "TOPLEFT")

		for i, category in ipairs(LFG_CATEGORIES) do
			local x, y = 40, -143 - (i - 1) * 52
			local icon = Atlas(c, category[1], "BORDER", 1, 277, 34)
			At(icon, "TOPLEFT", x + 5, y - 5)
			local cover = Atlas(c, "groupfinder-button-cover", "ARTWORK", 1, 287, 44)
			At(cover, "TOPLEFT", x, y)
			K.Text(c, "GameFontNormal", category[2], "LEFT", x + 20, y - 22, "TOPLEFT")
		end
		LfgButton(c, 19, 111, BACK or "Back")
		LfgButton(c, 235, 109, LFG_POST_GROUP or "List Self")

		local x = 16
		for i, label in ipairs(LFG_TAB_LABELS) do
			x = x + LfgTab(c, x, -435, label, i == 1) - 16
		end
	end,
}

---------------------------------------------------------------------------
-- Social window (SocialFrame.lua: the Battle.net friends frame)
---------------------------------------------------------------------------

local FRIENDS_FRAME = "Interface\\FriendsFrame\\UI-FriendsFrame-"
local SOCIAL_TAB_LABELS = {
	SOCIAL_UI_FRIENDS_TAB_NAME or "Friends", SOCIAL_UI_RECENT_ALLIES_TAB_NAME or "Recent Allies",
	SOCIAL_UI_FRIEND_REQUESTS_TAB_NAME or "Friend Requests", SOCIAL_UI_RAID_TAB_NAME or "Raid",
}
local SOCIAL_FRIENDS = {
	{ "Thrall", 60, "SHAMAN", "Orgrimmar", "friends-status-online" },
	{ "Rexxar", 60, "HUNTER", "Desolace", "friends-status-online" },
	{ "Rokhan", 58, "ROGUE", "Stranglethorn Vale", "friends-status-away" },
}

Previews.socialframe = {
	width = 384, height = 470,
	classic = function(c)
		File(c, "Interface\\FriendsFrame\\FriendsFrameScrollIcon", 64, 64, 6, -4, "BACKGROUND", -2)
		File(c, FRIENDS_FRAME .. "TopLeft-bnet", 256, 256, 0, 0, "BACKGROUND", -1)
		File(c, FRIENDS_FRAME .. "TopRight-bnet", 128, 256, 256, 0, "BACKGROUND", -1)
		File(c, FRIENDS_FRAME .. "Pending-BotLeft", 256, 256, 0, -256, "BACKGROUND", -1)
		File(c, FRIENDS_FRAME .. "Pending-BotRight", 128, 256, 256, -256, "BACKGROUND", -1)
		K.Text(c, "GameFontNormal", SOCIAL_UI_FRIENDS_TAB_NAME or "Friends", "CENTER", 197, -24, "TOPLEFT")
		File(c, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 32, 32, 321, -8, "ARTWORK")

		-- The Battle.net bar: status, BattleTag strip, menu button.
		At(Atlas(c, "friends-status-online", "ARTWORK", 0, 14, 14), "CENTER", 84, -49, c, "TOPLEFT")
		File(c, "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up", 24, 24, 94, -37, "ARTWORK")
		File(c, "Interface\\FriendsFrame\\battlenet-friends-main", 184, 29, 128, -35, "BORDER", 0,
			{ 0.00390625, 0.74609375, 0.00195313, 0.05859375 })
		local battleTag = BNGetInfo and select(2, BNGetInfo())
		K.Text(c, "GameFontNormal", battleTag or BATTLETAG or "BattleTag", "CENTER", 220, -49, "TOPLEFT", { 0.345, 0.667, 0.867 })
		At(Atlas(c, "common-button-tertiary-square-normal", "BORDER", 0, 28, 28), "CENTER", 328, -49, c, "TOPLEFT")
		At(Atlas(c, "friends-icon-menu", "ARTWORK", 0), "CENTER", 328, -49, c, "TOPLEFT")

		-- The search box and the classic filter box.
		At(Atlas(c, "common-searchbar-a", "BORDER", 0, 168, 20), "LEFT", 37, -80, c, "TOPLEFT")
		K.Text(c, "GameFontDisableSmall", SOCIAL_UI_SEARCH_BOX_INSTRUCTIONS or SEARCH or "Search", "LEFT", 56, -80, "TOPLEFT")
		File(c, ns.T.DROPDOWN_BOX, 25, 64, 226, -47, "ARTWORK", 0, { 0, 0.1953125, 0, 1 })
		File(c, ns.T.DROPDOWN_BOX, 60, 64, 251, -47, "ARTWORK", 0, { 0.1953125, 0.8046875, 0, 1 })
		File(c, ns.T.DROPDOWN_BOX, 25, 64, 311, -47, "ARTWORK", 0, { 0.8046875, 1, 0, 1 })
		K.Text(c, "GameFontHighlightSmall", FILTER or "Filter", "RIGHT", 293, -78, "TOPLEFT")
		File(c, "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up", 24, 24, 296, -65, "OVERLAY")

		-- Blizzard's cards, scaled into the well, and the scroll bar in the
		-- trough.
		for i, friend in ipairs(SOCIAL_FRIENDS) do
			local y = -101 - (i - 1) * 53
			At(Atlas(c, "friends-card-default", "BORDER", 1, 296, 52), "TOPLEFT", 21, y)
			At(Atlas(c, friend[5], "ARTWORK", 0, 14, 14), "TOPLEFT", 25, y - 4)
			local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[friend[3]]
			K.Text(c, "GameFontNormal", friend[1], "TOPLEFT", 42, y - 5, "TOPLEFT", color and { color.r, color.g, color.b })
			local class = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[friend[3]] or friend[3]
			K.Text(c, "GameFontHighlightSmall", (LEVEL or "Level") .. " " .. friend[2] .. " " .. class, "TOPLEFT", 43, y - 21, "TOPLEFT")
			K.Text(c, "GameFontDisableSmall", friend[4], "TOPLEFT", 43, y - 35, "TOPLEFT")
		end
		File(c, ns.T.SCROLL_UP .. "Up", 16, 16, 324, -99, "ARTWORK", 0, { 0.2, 0.8, 0.25, 0.75 })
		File(c, ns.T.SCROLL_DOWN .. "Up", 16, 16, 324, -391, "ARTWORK", 0, { 0.2, 0.8, 0.25, 0.75 })
		File(c, ns.T.SCROLL_KNOB, 18, 24, 323, -115, "ARTWORK", 0, { 0.2, 0.8, 0.125, 0.875 })

		File(c, "Interface\\Buttons\\UI-Panel-Button-Up", 160, 22, 100, -410, "ARTWORK", 0, { 0, 0.625, 0, 0.6875 })
		K.Text(c, "GameFontNormal", SOCIAL_UI_FRIENDS_LIST_ADD_FRIEND_BUTTON_LABEL or ADD_FRIEND or "Add Friend", "CENTER", 180, -421, "TOPLEFT")

		local x = 16
		for i, label in ipairs(SOCIAL_TAB_LABELS) do
			x = x + LfgTab(c, x, -435, label, i == 1) - 16
		end
	end,
}
