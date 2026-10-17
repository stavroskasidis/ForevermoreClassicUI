--[[
	Forevermore Classic UI - Spellbook (WoW Forever only)

	Restores the vanilla spellbook (1.12 SpellBookFrame.xml): the 384x512
	book made of the four Interface\Spellbook\UI-SpellbookPanel-* pieces with
	the Spellbook-Icon in the portrait ring, the "Spellbook" title and the
	round close button, twelve spells per page (1-6 down the left column,
	7-12 down the right) in the UI-Quickslot2 frame over the dark slot with
	the yellow name and the brown rank text beside them (passives in the
	black frame and the passive colour, like 1.12), the skill line tabs down
	the right edge and "Page N" between the Prev / Next arrows.

	Forever's spellbook is the retail one with the camelot overlay
	(Blizzard_PlayerSpells\Camelot\*): a page (SpellBookFrame) of
	PlayerSpellsFrame (load-on-demand), a panel shared with the talents page
	but without the retail tab bar, with one icon tab per skill line (and
	the pet) and the panel sized by the page's OnShow. Spells are cast by
	Blizzard's SpellBookItem buttons through C_SpellBook.CastSpellBookItem,
	which is protected: their OnClick must run untainted, so the page is
	re-skinned in place and nothing on it is replaced or driven from here:

	  * the spells are listed by a PagedCondensedVerticalGridContentFrame:
	    three columns of 220x60 items (70px a row with the padding), a 51px
	    header (61px) at the start of each skill line, split into views by
	    the view frame's height. Its columns, views per page and data provider
	    are Lua fields / calls that addon code must not touch (the item
	    frames it builds afterwards would carry taint and casting would be
	    blocked). Only the view's height is set: 345px holds a header plus
	    four rows, or four rows, but never five, so every view gets twelve
	    spells like a vanilla page. After each Layout of the view the items
	    are re-anchored into the vanilla page and the headers faded out,
	  * a page shows one view only in Blizzard's single-page ("minimized")
	    mode, which is chosen from the spellBookMinimize CVar when
	    Blizzard_PlayerSpells loads. The CVar is set at login (its previous
	    value comes back at a login with the option off) and the maximize
	    button is hidden,
	  * while the spellbook page is shown the 384x512 vanilla book is drawn
	    at the panel's left edge, at the height of the other panels,
	    instead of its NineSlice, portrait and title (PlayerSpellsPanel.lua,
	    shared with the Talents option; the talents page gets the retail
	    chrome back unless that option draws its own frame). The panel keeps
	    Blizzard's compact size (809x720). On its own the manager centres
	    it; the book is then drawn where the character frame opens (see
	    OriginX), next to other panels at the panel's left edge. It is not
	    resized: the page holds a secure
	    button (the assisted combat spell, UIPanelSpellButtonFrameTemplate),
	    which makes the page and the panel protected, and in combat neither
	    could be changed from here. Instead a frame of the book's size takes
	    the clicks (the panel's own mouse is switched off, out of combat) and
	    the spell list's frame, which takes the mouse wheel, is moved onto
	    the book,
	  * the skill line tabs become the vanilla side tabs, the search box and
	    the settings button go into the dark band under the title and the
	    paging controls to their vanilla spots.

	Only widget state is touched (sizes, anchors, textures, colours, alpha);
	no Lua field is written on Blizzard's frames. Applied once at login
	(reload to switch off).
]]

local _, ns = ...
if not ns.IS_FOREVER then return end
local T = ns.T
local Point = ns.Point

T.SPELLBOOK_PANEL    = "Interface\\Spellbook\\UI-SpellbookPanel-" -- + TopLeft / TopRight / BotLeft / BotRight
T.SPELLBOOK_ICON     = "Interface\\Spellbook\\Spellbook-Icon"
T.SPELLBOOK_SKILLTAB = "Interface\\Spellbook\\SpellBook-SkillLineTab"
T.SPELLBOOK_SLOT     = "Interface\\Spellbook\\UI-Spellbook-SpellBackground"
T.PASSIVE_HIGHLIGHT  = "Interface\\Buttons\\UI-PassiveHighlight"

local module = ns:RegisterModule({
	key = "spellbook",
	name = "Spellbook",
	tooltip = "Restores the vanilla spellbook: the classic book with twelve spells per page, the skill line tabs down its side and the Prev / Next page arrows. Casting, dragging spells to the bars, flyouts and the search keep working.",
	live = false,
})

local BLIZZARD_ADDON = "Blizzard_PlayerSpells"
local MINIMIZE_CVAR = "spellBookMinimize"

-- Vanilla geometry (1.12 SpellBookFrame.xml), offsets from the top-left
-- corner of the 384x512 frame (the origin frame, at the panel's left edge,
-- see UpdateOrigin).
local HIT_WIDTH, HIT_HEIGHT = 354, 442         -- without the transparent art right of the book and under it (the tab shelf)
local BOX_WIDTH = 350                          -- to the border's right edge, for the controller UI's glow (seen in game)
local TITLE_X, TITLE_Y = 198, -26              -- centre
local CLOSE_X, CLOSE_Y = 340, -25              -- centre
local SPELL_X, SPELL_Y = 34, -85               -- SpellButton1
local BUTTON_SIZE, NAME_GAP, NAME_WIDTH = 37, 4, 103
local COLUMN_STRIDE, ROW_STRIDE = 157, 51      -- 37px buttons 14px apart
local ROWS = 6
local ITEM_WIDTH = BUTTON_SIZE + NAME_GAP + NAME_WIDTH
local SIDE_TAB_X, SIDE_TAB_Y, SIDE_TAB_SIZE, SIDE_TAB_GAP = 352, -65, 32, 17
local PREV_X, NEXT_X, ARROW_Y = 50, 314, -407  -- arrow centres
local PAGE_TEXT_X, PAGE_TEXT_Y, PAGE_TEXT_WIDTH = 178, -416, 102 -- bottom centre of "Page N"
-- The dark band between the title bar and the page, right of the portrait
-- ring (the classic "show all ranks" checkbox sat there): the search box
-- and the settings button.
local BAND_Y, BAND_LEFT, BAND_RIGHT = -55, 84, 338
local BAND_ICON_GAP = 4                           -- between a controller UI prompt and its control

-- See the header: 345px takes a header and four rows (61 + 4 * 70 = 341) or
-- four rows (280), but not five (350).
local VIEW_WIDTH, VIEW_HEIGHT = COLUMN_STRIDE + ITEM_WIDTH, 345

local SUB_TEXT_COLOR = { 0.35, 0.2, 0 }                                   -- SubSpellFont
local PASSIVE_COLOR = PASSIVE_SPELL_FONT_COLOR or { r = 0.77, g = 0.64, b = 0 } -- 1.12's value

local book, page          -- PlayerSpellsFrame and its spellbook page (SpellBookFrame)
local origin              -- the vanilla frame's top-left corner, which everything is placed from
local originOffset = 0    -- origin's offset below the panel's top (see UpdateOrigin)
local originX = 0         -- and right of the panel's left edge (see OriginX)
local art = {}            -- regions this module draws on the panel
local skins = setmetatable({}, { __mode = "k" }) -- Blizzard frame -> what this module added to it
local passiveHighlight

-- The classic look is on while the spellbook page is the panel's shown tab
-- (its own shown flag; the panel itself may be hidden).
local function IsClassic()
	return page:IsShown()
end

---------------------------------------------------------------------------
-- Panel
---------------------------------------------------------------------------

-- The compact spellbook panel is registered with yoffset 75 and is 720
-- tall, so the panel manager puts it above the line the other panels (the
-- character frame: yoffset 0) share; the book is moved down to where the
-- manager would put a vanilla-sized panel, its border where the modern
-- windows have theirs (ns.ClassicArtTop).
local PanelTop = ns.PanelTop

local function PanelAttribute(name)
	return book:GetAttribute("UIPanelLayout-" .. name)
end

-- On its own the compact panel is centred (anchored by its top); the book
-- then goes where a left panel (the character frame) opens instead. Next to
-- other panels the manager lines the panel up with them (by its top left)
-- and the book's border stays on the panel's left edge (its art's margin
-- out of it).
local function OriginX()
	local left = book:GetLeft()
	if book:GetPoint(1) ~= "TOP" or not left then return -ns.CLASSIC_ART_X end
	return ns.PanelLeft() * UIParent:GetEffectiveScale() / book:GetEffectiveScale() - left - ns.CLASSIC_ART_X
end

local function UpdateOrigin()
	local scale = book:GetScale()
	local height = book.GetDesiredMinimizedHeight and book:GetDesiredMinimizedHeight(book:GetTab()) or book:GetHeight(true)
	local panelTop = PanelTop(PanelAttribute("yoffset") or 0, height * scale, PanelAttribute("minYOffset"), PanelAttribute("bottomClampOverride"))
	local offset = math.min(0, (ns.ClassicArtTop(scale) - panelTop) / scale)
	local x = OriginX()
	if offset ~= originOffset or x ~= originX then
		originOffset, originX = offset, x
		Point(origin, "TOPLEFT", book, "TOPLEFT", x, offset)
	end
end

local function CreatePanelArt()
	local function Piece(name, width, x, y)
		local texture = book:CreateTexture(nil, "ARTWORK")
		texture:SetTexture(T.SPELLBOOK_PANEL .. name)
		texture:SetSize(width, 256)
		texture:SetPoint("TOPLEFT", origin, "TOPLEFT", x, y)
		table.insert(art, texture)
	end
	Piece("TopLeft", 256, 0, 0)
	Piece("TopRight", 128, 256, 0)
	Piece("BotLeft", 256, 0, -256)
	Piece("BotRight", 128, 256, -256)

	-- The book icon shows through the hole of the portrait ring.
	local icon = book:CreateTexture(nil, "BACKGROUND")
	icon:SetSize(58, 58)
	icon:SetPoint("TOPLEFT", origin, "TOPLEFT", 10, -8)
	if ns.HasTexture(T.SPELLBOOK_ICON) then
		icon:SetTexture(T.SPELLBOOK_ICON)
	else
		local info = C_SpellBook.GetSpellBookSkillLineInfo(Enum.SpellBookSkillLineIndex.General)
		if info and info.iconID then
			SetPortraitToTexture(icon, info.iconID)
		end
	end
	table.insert(art, icon)

	local title = book:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("CENTER", origin, "TOPLEFT", TITLE_X, TITLE_Y)
	title:SetText(SPELLBOOK or "Spellbook")
	table.insert(art, title)

	-- Clicks on the book, in place of the panel's own mouse (see
	-- PlayerSpellsPanel.lua). Below every other child of the panel.
	local blocker = CreateFrame("Frame", nil, book)
	blocker:SetFrameLevel(book:GetFrameLevel())
	blocker:SetPoint("TOPLEFT", origin, "TOPLEFT", 0, 0)
	blocker:SetSize(HIT_WIDTH, HIT_HEIGHT)
	blocker:EnableMouse(true)
	table.insert(art, blocker)
end

---------------------------------------------------------------------------
-- The protected part (see the header): out of combat only
---------------------------------------------------------------------------

local protectedQueued = false
local rotationOffset, rotationX -- the origin offsets the assisted combat spell was placed for (nil: not placed yet)
local LayoutBand, QueueProtected

-- The assisted combat spell (if offered) goes to the right end of the band. It
-- is protected, so it is anchored to the (protected) panel, never to the
-- origin frame, which would become protected with it; Blizzard never moves
-- it, so it is only placed again when the origin moved.
local function PlaceRotationButton()
	local rotation = page.AssistedCombatRotationSpellFrame
	if rotation and (rotationOffset ~= originOffset or rotationX ~= originX) then
		Point(rotation, "RIGHT", book, "TOPLEFT", originX + BAND_RIGHT, BAND_Y + originOffset)
		rotationOffset, rotationX = originOffset, originX
		LayoutBand()
	end
end

local function ApplyProtected()
	if InCombatLockdown() then
		QueueProtected()
		return
	end
	PlaceRotationButton()
end

function QueueProtected()
	if protectedQueued then return end
	protectedQueued = true
	ns:RunOutOfCombat(function()
		protectedQueued = false
		ApplyProtected()
	end)
end

---------------------------------------------------------------------------
-- Side tabs (the skill lines)
---------------------------------------------------------------------------

local SIDE_TAB_ART = { "Left", "Middle", "Right", "LeftActive", "MiddleActive", "RightActive", "LeftHighlight", "MiddleHighlight", "RightHighlight", "SquareBackground", "SquareBackgroundActive", "SquareBackgroundActiveGlow", "Icon", "Text" }

-- Each tab carries its skill line's icon, the pet tab the pet's (its
-- portrait when there is no icon).
local function UpdateSideTabIcon(tab)
	local icon = skins[tab].icon
	icon:SetTexCoord(0, 1, 0, 1)
	if tab.tabIcon then
		icon:SetTexture(tab.tabIcon)
	else
		SetPortraitTexture(icon, "pet")
	end
end

local function SkinSideTab(tab)
	local skin = skins[tab]
	if skin then return skin end
	skin = {}
	skins[tab] = skin

	skin.background = tab:CreateTexture(nil, "BACKGROUND")
	skin.background:SetTexture(T.SPELLBOOK_SKILLTAB)
	skin.background:SetSize(64, 64)
	skin.background:SetPoint("TOPLEFT", tab, "TOPLEFT", -3, 11)

	skin.icon = tab:CreateTexture(nil, "ARTWORK")
	skin.icon:SetAllPoints(tab)

	skin.checked = tab:CreateTexture(nil, "OVERLAY")
	skin.checked:SetTexture(T.BUTTON_CHECKED)
	skin.checked:SetBlendMode("ADD")
	skin.checked:SetAllPoints(tab)
	skin.checked:Hide()

	tab:SetHighlightTexture(T.BUTTON_HIGHLIGHT, "ADD")
	ns.Hook(tab, "SetTabSelected", function(self)
		skin.checked:SetShown(self.isSelected == true)
	end)
	return skin
end

-- After the category tab bar's Layout: Blizzard re-creates the tabs (from a
-- pool) on every show and spell change and lines them up; they are moved
-- down the book's right edge instead. The controller UI's L1 / R1 prompts,
-- which Blizzard puts at the ends of the bar, go over the first tab and
-- under the last.
local function LayoutSideTabs()
	local tabs = page.CategoryTabSystem
	local index = 0
	local first, last
	for _, tab in ipairs(tabs.tabs or {}) do
		if tab:IsShown() then
			first = first or tab
			last = tab
			local skin = SkinSideTab(tab)
			for _, key in ipairs(SIDE_TAB_ART) do
				if tab[key] then tab[key]:SetAlpha(0) end
			end
			tab:SetSize(SIDE_TAB_SIZE, SIDE_TAB_SIZE)
			Point(tab, "TOPLEFT", origin, "TOPLEFT", SIDE_TAB_X, SIDE_TAB_Y - index * (SIDE_TAB_SIZE + SIDE_TAB_GAP))
			UpdateSideTabIcon(tab)
			skin.checked:SetShown(tab.isSelected == true)
			index = index + 1
		end
	end
	if first and page.PreviousCategoryIcon and page.NextCategoryIcon then
		Point(page.PreviousCategoryIcon, "BOTTOM", first, "TOP", 0, 2)
		Point(page.NextCategoryIcon, "TOP", last, "BOTTOM", 0, -2)
	end
end

---------------------------------------------------------------------------
-- Spells
---------------------------------------------------------------------------

-- After Blizzard's UpdateVisuals, which re-applies the retail hover atlas
-- and sets the item's state: passives get the black frame, the passive
-- highlight and the passive name colour like 1.12, spells the yellow name.
local function UpdateItemVisuals(item)
	local skin = skins[item]
	local button = item.Button
	if button.IconHighlight then button.IconHighlight:SetTexture(nil) end
	local info = item.spellBookItemInfo
	local passive = info ~= nil and info.isPassive == true
	if skin.normal then
		local shade = passive and 0 or 1
		skin.normal:SetVertexColor(shade, shade, shade)
	end
	if passive ~= skin.passive then
		skin.passive = passive
		button:SetHighlightTexture(passive and passiveHighlight or T.BUTTON_HIGHLIGHT, "ADD")
	end
	local color = passive and PASSIVE_COLOR or NORMAL_FONT_COLOR
	item.Name:SetTextColor(color.r, color.g, color.b)
	item.SubName:SetTextColor(unpack(SUB_TEXT_COLOR))
	item.RequiredLevel:SetTextColor(unpack(SUB_TEXT_COLOR))
end

-- Vanilla SpellButtonTemplate: a 37px icon in the UI-Quickslot2 frame over
-- the UI-Spellbook-SpellBackground slot, the name (103px, GameFontNormal)
-- 4px right of it with the rank under it in SubSpellFont.
local function SkinItem(item)
	local button = item.Button
	local skin = {}
	skins[item] = skin

	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button.Icon:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	-- The rounded icon mask (square spells, circular passives).
	ns.StripMask(button.IconMask, button.Icon, button.LevelLinkIconCover, button.ClickBindingIconCover)
	for _, key in ipairs({ "Border", "BorderShadow", "BorderSheen", "TrainableShadow", "TrainableBackplate" }) do
		if button[key] then button[key]:SetAlpha(0) end
	end
	if item.Backplate then item.Backplate:Hide() end

	local slot = button:CreateTexture(nil, "BACKGROUND", nil, -2)
	slot:SetTexture(T.SPELLBOOK_SLOT)
	slot:SetSize(64, 64)
	slot:SetPoint("TOPLEFT", button, "TOPLEFT", -3, 3)

	button:SetNormalTexture(T.QUICKSLOT2)
	skin.normal = button:GetNormalTexture()
	skin.normal:ClearAllPoints()
	skin.normal:SetSize(64, 64)
	skin.normal:SetPoint("CENTER", button, "CENTER", 0, 0)
	button:SetPushedTexture(T.QUICKSLOT_PUSHED)
	button:SetHighlightTexture(T.BUTTON_HIGHLIGHT, "ADD")
	skin.passive = false

	local text = item.TextContainer
	Point(text, "LEFT", button, "RIGHT", NAME_GAP, -1)
	text:SetPoint("RIGHT", item, "RIGHT", 0, -1)
	item.Name:SetFontObject(GameFontNormal)
	item.SubName:SetFontObject(SubSpellFont or GameFontNormalSmall)
	item.RequiredLevel:SetFontObject(SubSpellFont or GameFontNormalSmall)

	ns.Hook(item, "UpdateVisuals", UpdateItemVisuals)
end

-- After StaticGridLayoutFrame:Layout of a view (right before Blizzard
-- initializes the items): the items Blizzard placed in its three columns go
-- into the vanilla page in their order, 1-6 down the left column and 7-12
-- down the right; the group headers are faded out.
local function LayoutView(view)
	local index = 0
	for _, frame in ipairs(page.PagedSpellsFrame:GetFrames()) do
		if frame:GetParent() == view then
			if frame.Button then
				if not skins[frame] then SkinItem(frame) end
				frame:SetSize(ITEM_WIDTH, BUTTON_SIZE)
				local column, row = math.floor(index / ROWS), index % ROWS
				Point(frame, "TOPLEFT", view, "TOPLEFT", column * COLUMN_STRIDE, -row * ROW_STRIDE)
				index = index + 1
			else
				frame:SetAlpha(0)
			end
		end
	end
end

---------------------------------------------------------------------------
-- Page furniture: paging controls, search box, settings
---------------------------------------------------------------------------

-- After the paging controls' Layout (a row of text + arrows, redone on every
-- page change): the arrows go to the page's bottom corners and "Page N" in
-- the vanilla yellow between them.
local function LayoutPaging(controls)
	Point(controls.PrevPageButton, "CENTER", origin, "TOPLEFT", PREV_X, ARROW_Y)
	Point(controls.NextPageButton, "CENTER", origin, "TOPLEFT", NEXT_X, ARROW_Y)
	Point(controls.PageText, "BOTTOM", origin, "TOPLEFT", PAGE_TEXT_X, PAGE_TEXT_Y)
	controls.PageText:SetFormattedText(PAGE_NUMBER, controls:GetCurrentPage())
end

-- After UpdateAttic (every show): from the right end of the band the
-- assisted combat spell (when shown and placed, see PlaceRotationButton),
-- the settings button, then the search box filling the rest up to the
-- portrait ring; both its anchors fix its width, so Blizzard's own sizing
-- of it has no effect. Only unprotected frames are anchored here (to the
-- protected spell button, never the other way round).
function LayoutBand()
	local gear, search, rotation = page.SettingsDropdown, page.SearchBox, page.AssistedCombatRotationSpellFrame
	local searchIcon, gearIcon = page.SearchBoxIcon, page.SettingsTopFaceIcon
	local anchor, relativePoint, x, y = origin, "TOPLEFT", BAND_RIGHT, BAND_Y
	if rotationOffset and rotation:IsShown() then
		anchor, relativePoint, x, y = rotation, "LEFT", -6, 0
	end
	if gear and gear:IsShown() then
		Point(gear, "RIGHT", anchor, relativePoint, x, y)
		anchor, relativePoint, x, y = gear, "LEFT", -8, 0
		-- The controller UI's prompts (Blizzard hangs them off the left
		-- edges of the gear and the box, and moves the box when the
		-- controller UI starts): each before its control, the box making
		-- room for them while they show.
		if gearIcon then
			Point(gearIcon, "RIGHT", gear, "LEFT", -BAND_ICON_GAP, 0)
			if gearIcon:IsShown() then
				anchor, relativePoint, x, y = gearIcon, "LEFT", -BAND_ICON_GAP, 0
			end
		end
	end
	local left = BAND_LEFT
	if searchIcon then
		Point(searchIcon, "LEFT", origin, "TOPLEFT", BAND_LEFT, BAND_Y)
		if searchIcon:IsShown() then left = BAND_LEFT + searchIcon:GetWidth() + BAND_ICON_GAP end
	end
	if search then
		search:ClearAllPoints()
		search:SetPoint("LEFT", origin, "TOPLEFT", left, BAND_Y)
		search:SetPoint("RIGHT", anchor, relativePoint, x, y)
	end
end

local function SkinPage()
	-- Retail's book art, ribbon and page-corner flipbook; Blizzard shows and
	-- hides them with the minimized state, alpha survives that.
	for _, key in ipairs({ "TopBar", "BookBGHalved", "BookBGLeft", "BookBGRight", "BookCornerFlipbook", "Bookmark" }) do
		if page[key] then page[key]:SetAlpha(0) end
	end
	if page.HelpPlateButton then
		page.HelpPlateButton:SetAlpha(0)
		page.HelpPlateButton:EnableMouse(false)
	end

	-- The spell list's frame takes the mouse wheel (paging); it spans the
	-- page (the panel's size) and is moved onto the book. It is not
	-- protected, the page around it is.
	local paged = page.PagedSpellsFrame
	paged:ClearAllPoints()
	paged:SetPoint("TOPLEFT", origin, "TOPLEFT", 0, 0)
	paged:SetPoint("BOTTOMRIGHT", origin, "TOPLEFT", HIT_WIDTH, -HIT_HEIGHT)
	for _, view in ipairs(paged.ViewFrames) do
		view:SetSize(VIEW_WIDTH, VIEW_HEIGHT)
		ns.Hook(view, "Layout", LayoutView)
	end
	Point(paged.ViewFrames[1], "TOPLEFT", origin, "TOPLEFT", SPELL_X, SPELL_Y)

	local controls = paged.PagingControls
	controls.PageText:SetFontObject(GameFontNormal)
	controls.PageText:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
	controls.PageText:SetSize(PAGE_TEXT_WIDTH, 0)
	controls.PageText:SetJustifyH("CENTER")
	ns.Hook(controls, "Layout", LayoutPaging)
	LayoutPaging(controls)

	ns.Hook(page, "UpdateAttic", LayoutBand)
	page:HookScript("OnShow", LayoutBand)
	for _, icon in ipairs({ page.SearchBoxIcon, page.SettingsTopFaceIcon }) do
		icon:HookScript("OnShow", LayoutBand)
		icon:HookScript("OnHide", LayoutBand)
	end
	LayoutBand()

	-- The tab bar itself is invisible, its tabs are anchored one by one. It
	-- is kept left of the search box: ResizeSearchBox measures the box's
	-- width from the bar's right edge.
	local tabs = page.CategoryTabSystem
	Point(tabs, "TOPRIGHT", origin, "TOPLEFT", 0, SIDE_TAB_Y)
	ns.Hook(tabs, "Layout", LayoutSideTabs)
	LayoutSideTabs()
end

---------------------------------------------------------------------------
-- Classic <-> retail look (the panel's chrome: PlayerSpellsPanel.lua)
---------------------------------------------------------------------------

local classicApplied = false -- the look UpdateMode last put on the panel

-- The book is (re)drawn whenever the page is shown; it goes once, when
-- another page takes over.
local function UpdateMode()
	local classic = IsClassic()
	if not classic and not classicApplied then return end
	classicApplied = classic
	for _, region in ipairs(art) do
		region:SetShown(classic)
	end
	if classic then
		UpdateOrigin()
		if book.MaximizeMinimizeButton then
			book.MaximizeMinimizeButton:Hide()
		end
		ApplyProtected()
	end
end

local function Skin()
	book = PlayerSpellsFrame
	page = book and book.SpellBookFrame
	local paged = page and page.PagedSpellsFrame
	if art[1] or not (paged and paged.ViewFrames and paged.PagingControls and page.CategoryTabSystem and book.CloseButton) then
		return
	end
	-- The single-page mode is read from the CVar when the frame loads; a
	-- frame loaded before Apply could set it keeps the retail look.
	if book.manualMinimizeEnabled == false then
		ns.Print("The spellbook was loaded before its single-page mode could be set; /reload to get the classic spellbook.")
		return
	end
	passiveHighlight = ns.HasTexture(T.PASSIVE_HIGHLIGHT) and T.PASSIVE_HIGHLIGHT or T.BUTTON_HIGHLIGHT

	origin = CreateFrame("Frame", nil, book)
	origin:SetSize(1, 1)
	origin:SetPoint("TOPLEFT", book, "TOPLEFT", 0, originOffset)
	CreatePanelArt()
	for _, region in ipairs(art) do
		region:Hide() -- shown by UpdateMode with the page
	end
	SkinPage()
	if not InCombatLockdown() then
		PlaceRotationButton()
	end

	-- The tab tracker shows / hides the page on every tab change; tab clicks
	-- reach PlayerSpellsFrame:SetTab through a closure no hook sees.
	ns.Hook(page, "SetShown", UpdateMode)
	book:HookScript("OnShow", UpdateMode)
	if book.MaximizeMinimizeButton then
		-- SetTab shows it after the page is shown.
		book.MaximizeMinimizeButton:HookScript("OnShow", function(self)
			if IsClassic() then self:Hide() end
		end)
	end
	-- The round classic close button sits inside the book's border.
	ns.PlayerSpellsPanel.Register(page, function(close)
		Point(close, "CENTER", origin, "TOPLEFT", CLOSE_X, CLOSE_Y)
	end, ns.CreateArtBox(book, origin, BOX_WIDTH, HIT_HEIGHT))
	-- The panel manager moves the panel (centred on its own, lined up next to
	-- other panels) when a panel opens or closes; its own frame cannot be
	-- hooked, these are the calls that start it.
	local function Reposition()
		if classicApplied and book:IsShown() then
			UpdateOrigin()
			ApplyProtected()
		end
	end
	for _, name in ipairs({ "ShowUIPanel", "HideUIPanel", "UpdateUIPanelPositions" }) do
		ns.Hook(name, Reposition)
	end
	UpdateMode()
end

---------------------------------------------------------------------------
-- Module
---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == BLIZZARD_ADDON then
			self:UnregisterEvent("ADDON_LOADED")
			xpcall(Skin, geterrorhandler())
		end
	elseif not ns:IsEnabled(module.key) and ns.db.spellbookPreviousMinimize ~= nil then
		-- Option off: the single / two page choice from before comes back.
		C_CVar.SetCVar(MINIMIZE_CVAR, ns.db.spellbookPreviousMinimize)
		ns.db.spellbookPreviousMinimize = nil
	end
end)

function module:Apply()
	if not (C_SpellBook and C_SpellBook.GetSpellBookSkillLineInfo and C_CVar.GetCVar(MINIMIZE_CVAR)) then return end
	for _, piece in ipairs({ "TopLeft", "TopRight", "BotLeft", "BotRight" }) do
		if not ns.HasTexture(T.SPELLBOOK_PANEL .. piece) then
			ns.Print("This client does not ship " .. T.SPELLBOOK_PANEL .. piece .. "; the spellbook keeps the retail look.")
			return
		end
	end

	-- Single-page mode; only a value that was off is worth remembering.
	if ns.db.spellbookPreviousMinimize == nil and not C_CVar.GetCVarBool(MINIMIZE_CVAR) then
		ns.db.spellbookPreviousMinimize = C_CVar.GetCVar(MINIMIZE_CVAR)
	end
	C_CVar.SetCVar(MINIMIZE_CVAR, "1")

	if C_AddOns.IsAddOnLoaded(BLIZZARD_ADDON) then
		Skin()
	else
		eventFrame:RegisterEvent("ADDON_LOADED")
	end
end
