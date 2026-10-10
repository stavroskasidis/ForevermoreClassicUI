--[[
	Forevermore Classic UI - Character window (WoW Forever only)

	Restores the vanilla character window (1.12 CharacterFrame.xml /
	PaperDollFrame.xml): the 384x512 frame with the player's portrait in the
	ring, the name on the title bar and the level and guild lines under it,
	the round close button and the tabs under the frame. The Character tab
	is the vanilla paperdoll (UI-Character-CharacterTab-* art): the equipment
	slots down both sides and along the bottom, the model between them, the
	resistances down the model's right edge and two stat boxes under it,
	each with the 2.x dropdown (base stats, melee, ranged, spell, defenses).
	Blizzard's pet view (the right pane's pet tab, which hides the slots
	and shows the pet in the model) gets 1.12's pet page instead
	(PetPaperDollFrame.xml): its art, the model over the whole width, the
	pet's stats, resistances, portrait and name, and the XP bar.
	The other tabs get the plain frame (UI-Character-General-*) with
	Blizzard's content inside it; they get their own vanilla pages later.

	Forever's character window is its own (Blizzard_UIPanels_Game\Camelot):
	a 631x484 PortraitFrame with six icon tabs down its right side
	(Character, Reputation, Skills, PvP, Currency, Statistics), a left pane
	(CharacterFrame.LeftPaneHost, 398 wide) that every page anchors its
	content to, and a right pane (RightPaneHost) holding the stats, gear
	sets, titles and pet view and the detail panels of the other pages.
	Blizzard's arrow button collapses the right pane (the frame is then 398
	wide). The frame is re-skinned in place:

	  * the vanilla art is drawn on CharacterFrame at its top-left corner;
	    the NineSlice, the panes' backgrounds and the modern portrait are
	    faded. The frame keeps Blizzard's size (the collapsed frame is the
	    vanilla frame's size); the pages take the mouse only over the art,
	  * the left pane is moved into the vanilla frame's content area, so the
	    pages that anchor to it (reputation, skills, currency, PvP) move with
	    it; the paperdoll's slots, model and ammo slot are placed one by one
	    on the vanilla spots,
	  * the right pane is docked to the right edge of the vanilla frame in
	    the 1.12 dialog box border (as 1.12 docked its reputation detail
	    panel there); the arrow button stays Blizzard's and sits in the band
	    under the title,
	  * the icon tabs are Blizzard's own tab frames, moved under the frame
	    and drawn as the vanilla tabs (so a click stays Blizzard's),
	  * the stat boxes and resistances are this module's frames, filled by
	    Blizzard's own stat functions (PAPERDOLL_STATINFO) whenever Blizzard
	    updates its stats,
	  * with the controller UI on, Blizzard's focus glow goes round the
	    vanilla window (and the docked pane), its L1 / R1 tab prompts under
	    the two ends of the tab row (Blizzard puts them over and under its
	    tab column) and the button prompt footers under those. Blizzard
	    hides the close button in that mode (B closes the window).

	Only widget state is touched (sizes, anchors, textures, colours, alpha,
	hit rects); no Lua field is written on Blizzard's frames. Nothing here
	is protected. Applied once at login (reload to switch off).
]]

local _, ns = ...
if not ns.IS_FOREVER then return end
local T = ns.T
local Point = ns.Point

-- T.TAB_INACTIVE / T.TAB_HIGHLIGHT (AuctionHouse.lua) come from a file loaded earlier.
T.CHARACTER_TAB_ART  = "Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-" -- + L1 / R1 / BottomLeft / BottomRight
T.CHARACTER_GENERAL  = "Interface\\PaperDollInfoFrame\\UI-Character-General-"      -- + TopLeft / TopRight / BottomLeft / BottomRight
T.STAT_BACKGROUND    = "Interface\\PaperDollInfoFrame\\UI-Character-StatBackground"
T.RESISTANCE_ICONS   = "Interface\\PaperDollInfoFrame\\UI-Character-ResistanceIcons"
T.AMMO_SLOT          = "Interface\\PaperDollInfoFrame\\UI-Character-AmmoSlot"
T.PET_PAPERDOLL      = "Interface\\PetPaperDollFrame\\UI-PetPaperDollFrame-"         -- + BotLeft / BotRight
-- T.DIALOG_BACKGROUND / T.DIALOG_BORDER come from GameMenu.lua (loaded earlier).

local module = ns:RegisterModule({
	key = "characterframe",
	name = "Character Window",
	tooltip = "Restores the vanilla character window: the classic frame with the tabs under it, the classic paperdoll with the equipment slots around the model, the resistances and two stat boxes with the classic stat dropdowns, the vanilla pet page, and the same vanilla paperdoll on the inspect window. The details pane (stats, gear sets, titles, pet) docks to the window's side in the classic dialog border.",
	live = false,
})

-- Vanilla geometry (1.12 CharacterFrame.xml / PaperDollFrame.xml, the stat
-- boxes from 2.x), offsets from the top-left corner of the 384x512 frame.
local HIT_WIDTH, HIT_HEIGHT = 354, 440         -- the art without its transparent right edge and the tab shelf
local PORTRAIT_X, PORTRAIT_Y, PORTRAIT_SIZE = 7, -6, 60
local CLOSE_X, CLOSE_Y = 340, -25              -- centre
local TITLE_LEFT, TITLE_RIGHT, TITLE_Y = 72, 324, -13 -- the title bar (Blizzard's title container)
local LEVEL_Y = -40                            -- top of the level line (centred on the title), the guild line under it
local TOGGLE_X, TOGGLE_Y = 330, -57            -- the right pane's arrow button (centre), at the right end of the band
-- The content area the left pane is moved to: the pages anchor their lists
-- 10 / 40 in from its top left and 25 / 15 in from its bottom right.
local CONTENT_X, CONTENT_Y, CONTENT_WIDTH, CONTENT_HEIGHT = 12, -40, 340, 395
local SLOT_LEFT_X, SLOT_RIGHT_X, SLOT_Y, SLOT_STRIDE = 21, 305, -74, 41 -- 37px slots 4px apart
local WEAPON_X, WEAPON_Y, WEAPON_STRIDE = 122, -385, 42
local AMMO_GAP = 15                            -- right of the ranged slot
local MODEL_X, MODEL_Y, MODEL_WIDTH, MODEL_HEIGHT = 65, -78, 233, 215
local STATS_X, STATS_Y = 67, -291              -- CharacterAttributesFrame
local STAT_BOX_WIDTH, STAT_ROW_WIDTH, STAT_ROW_HEIGHT, STAT_ROWS = 115, 104, 13, 6
local DROPDOWN_CLEAR_LEFT, DROPDOWN_CLEAR_RIGHT = 13, 14 -- the dropdown art's see-through ends (ns.SkinDropdownBox's 25px end pieces)
local RESIST_RIGHT, RESIST_Y, RESIST_WIDTH, RESIST_HEIGHT = 297, -77, 32, 29
-- Tabs: the first one's top left, each one 16px into the previous one
-- (1.12 CharacterFrameTabButtonTemplate). Six tabs sized like 1.12's
-- (the label between the 20px ends) run well past the frame, so the label
-- also takes the flat inner 7px of each end.
local TAB_X, TAB_Y, TAB_OVERLAP, TAB_END, TAB_HEIGHT = 12, -434, 16, 20, 32
local TAB_TEXT_INTO_END = 7
-- The controller UI's L1 / R1 prompts (26px) under the tab row's ends, and
-- the row they take there.
local TAB_INDICATOR_INSET, TAB_INDICATOR_ROW = 6, 28
-- The docked right pane: the 1.12 dialog box (as 1.12's reputation detail
-- frame, 33px into the frame's transparent right edge) and the pane inside
-- its border. It runs from the frame's top border down to the bottom of the
-- tab row, so the stats list shows about as much as Blizzard's full-height
-- pane.
local DOCK_X, DOCK_Y, DOCK_HEIGHT = 347, -12, 454
-- Blizzard's stats lists end 30px above their pane, over a scroll line
-- (faded here); they are taken down to this.
local STATS_LIST_BOTTOM = 6
local DOCK_INSET_LEFT, DOCK_INSET_TOP, DOCK_INSET_RIGHT, DOCK_INSET_BOTTOM = 11, 12, 12, 11
-- The 1.12 pet page (PetPaperDollFrame.xml): the model over the page's
-- whole width, the stat boxes a little lower, the resistances at the
-- model's right edge, the XP bar in the art's groove (top left) and the
-- happiness icon under the model's top left corner.
local PET_MODEL_X, PET_MODEL_Y, PET_MODEL_WIDTH, PET_MODEL_HEIGHT = 25, -78, 318, 224
local PET_STATS_Y = -300
local PET_RESIST_RIGHT = 347
local PET_XP_X, PET_XP_Y, PET_XP_WIDTH, PET_XP_HEIGHT = 23, -396, 319, 11
local PET_XP_COLOR = { 0.58, 0, 0.55 }
local PET_HAPPINESS_X, PET_HAPPINESS_Y = 30, -111

-- The 1.12 slot columns, top to bottom, and the weapon row.
local LEFT_SLOTS = { "CharacterHeadSlot", "CharacterNeckSlot", "CharacterShoulderSlot", "CharacterBackSlot",
	"CharacterChestSlot", "CharacterShirtSlot", "CharacterTabardSlot", "CharacterWristSlot" }
local RIGHT_SLOTS = { "CharacterHandsSlot", "CharacterWaistSlot", "CharacterLegsSlot", "CharacterFeetSlot",
	"CharacterFinger0Slot", "CharacterFinger1Slot", "CharacterTrinket0Slot", "CharacterTrinket1Slot" }
local WEAPON_SLOTS = { "CharacterMainHandSlot", "CharacterSecondaryHandSlot", "CharacterRangedSlot" }

-- 1.12's resistance column, top to bottom: the resistance (damage class)
-- and its icon's rows in UI-Character-ResistanceIcons.
local RESISTANCES = {
	{ id = 6, top = 0.2265625, bottom = 0.33984375 }, -- arcane
	{ id = 2, top = 0,         bottom = 0.11328125 }, -- fire
	{ id = 3, top = 0.11328125, bottom = 0.2265625 }, -- nature
	{ id = 4, top = 0.33984375, bottom = 0.453125 },  -- frost
	{ id = 5, top = 0.453125,  bottom = 0.56640625 }, -- shadow
}

-- The stat boxes' choices (2.x PLAYERSTAT_DROPDOWN_OPTIONS), as the stats
-- of Forever's PAPERDOLL_STATINFO: { stat, hideAt, label }. A stat whose
-- value comes back as its hideAt is left out, like Blizzard's stats pane
-- does. Blizzard's labels are written for its wide pane; the ones that do
-- not fit the 104px row get 2.x's shorter ones. (ATTACK_DAMAGE is not used:
-- its GetAppropriateDamage does not exist on Forever.)
local LABEL_DAMAGE = DAMAGE or "Damage"
local LABEL_ATTACK_POWER = STAT_ATTACK_POWER or ATTACK_POWER_TOOLTIP or "Attack Power"
local LABEL_CRIT = CRIT_CHANCE or "Crit Chance"
local STAT_CATEGORIES = {
	{ key = "PLAYERSTAT_BASE_STATS", fallback = "Base Stats",
		stats = { { "STRENGTH" }, { "AGILITY" }, { "STAMINA" }, { "INTELLECT" }, { "SPIRIT" }, { "ARMOR" } } },
	{ key = "PLAYERSTAT_MELEE_COMBAT", fallback = "Melee",
		stats = { { "MAINHAND_DAMAGE" }, { "OFFHAND_DAMAGE", 0 }, { "ATTACK_ATTACKSPEED" }, { "ATTACK_AP" }, { "HITCHANCE" }, { "CRITCHANCE", nil, LABEL_CRIT } } },
	{ key = "PLAYERSTAT_RANGED_COMBAT", fallback = "Ranged",
		stats = { { "RANGED_DAMAGE", 0, LABEL_DAMAGE }, { "RANGED_ATTACK_AP", nil, LABEL_ATTACK_POWER }, { "HITCHANCE" }, { "CRITCHANCE", nil, LABEL_CRIT } } },
	{ key = "PLAYERSTAT_SPELL_COMBAT", fallback = "Spell",
		stats = { { "SPELLPOWER" }, { "SPELLHEALING" }, { "HITCHANCE" }, { "CRITCHANCE", nil, LABEL_CRIT }, { "SPELLPENETRATION", 0 }, { "MANAREGEN" } } },
	{ key = "PLAYERSTAT_DEFENSES", fallback = "Defenses",
		stats = { { "ARMOR" }, { "DEFENSE" }, { "DODGE", 0 }, { "PARRY", 0 }, { "BLOCK", 0 } } },
}
-- The pet page's boxes (no dropdowns in 1.12): the stats of Blizzard's pet
-- pane (pets have no attributes on Forever).
local PET_STATS = {
	left = { { "HEALTH" }, { "ARMOR" }, { "MAINHAND_DAMAGE", nil, LABEL_DAMAGE }, { "ATTACK_AP", 0, LABEL_ATTACK_POWER }, { "SPELLPOWER", 0 } },
	right = { { "HITCHANCE", 0 }, { "CRITCHANCE", 0, LABEL_CRIT }, { "HASTE", 0 }, { "MOVESPEED", nil, SPEED or "Speed" } },
}
local STAT_CVARS = { left = "playerStatLeftDropdown", right = "playerStatRightDropdown" }
-- 2.x's default right box by class (the left one shows the base stats).
local CASTERS = { MAGE = true, PRIEST = true, WARLOCK = true }

-- Blizzard's backgrounds, borders and scroll lines in the panes, and the
-- ammo slot's modern frame and arrow (atlas names).
local PANE_ART = {
	["common-insideframe"] = true,
	["UI-Character-Info-ScrollLine"] = true,
}
local AMMO_ART = {
	["UI-Character-Info-GearSlotSmall"] = true,
	["UI-Character-Info-GearSlot-Arrow"] = true,
}

-- Blizzard reads the right pane's collapsed state from this CVar when the
-- frame loads (and never writes it, see StartCollapsed).
local COLLAPSED_CVAR = "characterFrameCollapsed"

local frame                -- CharacterFrame
local origin               -- the vanilla art's top-left corner (ns.ArtOrigin), which everything is placed from
local paperdollArt, generalArt, petArt = {}, {}, {}
local portrait, levelText, guildText, petNameText
local attributes           -- the stat boxes' frame
local petXPBar
local dockBox              -- the docked right pane's dialog box
local controllerBox        -- what the controller UI's glow and footers go round (SetUpController)
local statBoxes = {}       -- "left" / "right" -> { rows = { stat frames }, dropdown }
local resistances = {}     -- the resistance frames, in RESISTANCES order
local tabSkins = setmetatable({}, { __mode = "k" }) -- Blizzard tab frame -> what this module added to it

local function Fade(region)
	if region then region:SetAlpha(0) end
end

-- Fades a frame's own textures (not its children's).
local function FadeRegions(owner)
	for _, region in ipairs({ owner:GetRegions() }) do
		if region:IsObjectType("Texture") then region:SetAlpha(0) end
	end
end

-- Fades the textures of a frame (and its children, one level down) that
-- carry one of the given atlases.
local function FadeAtlases(owner, atlases)
	local function Scan(target)
		for _, region in ipairs({ target:GetRegions() }) do
			if region:IsObjectType("Texture") and atlases[region:GetAtlas() or ""] then
				region:SetAlpha(0)
			end
		end
	end
	if not owner then return end
	Scan(owner)
	for _, child in ipairs({ owner:GetChildren() }) do
		Scan(child)
	end
end

---------------------------------------------------------------------------
-- Frame art
---------------------------------------------------------------------------

-- Blizzard's pet view hides the slots (PaperDollItemsFrame) and puts the
-- pet in the model; the slots stay hidden while the right pane is collapsed
-- on it.
local function IsPetPage()
	return PaperDollFrame:IsShown() and PaperDollItemsFrame ~= nil and not PaperDollItemsFrame:IsShown()
end

-- Four files (256 / 128 wide, 256 tall) on `owner` at its art's top left
-- (`ownerOrigin`), shifted by x, y.
local function CreateArt(list, files, x, y, owner, ownerOrigin)
	local pieces = {
		{ files[1], 256, 0, 0 }, { files[2], 128, 256, 0 },
		{ files[3], 256, 0, -256 }, { files[4], 128, 256, -256 },
	}
	for _, piece in ipairs(pieces) do
		local texture = (owner or frame):CreateTexture(nil, "BACKGROUND", nil, -6)
		texture:SetTexture(piece[1])
		texture:SetSize(piece[2], 256)
		texture:SetPoint("TOPLEFT", ownerOrigin or origin, "TOPLEFT", x + piece[3], y + piece[4])
		table.insert(list, texture)
	end
end

local function UpdateArt()
	local paperdoll = PaperDollFrame:IsShown()
	local pet = IsPetPage()
	for _, texture in ipairs(paperdollArt) do texture:SetShown(paperdoll and not pet) end
	for _, texture in ipairs(petArt) do texture:SetShown(pet) end
	for _, texture in ipairs(generalArt) do texture:SetShown(not paperdoll) end
end

-- The player's portrait under the art's ring (1.12 drew it on the frame,
-- under the page's art), the pet's on the pet page; Blizzard's own portrait
-- (its spec icon on the Character tab) is faded.
local function UpdatePortrait()
	SetPortraitTexture(portrait, IsPetPage() and "pet" or "player")
end

local function SkinChrome()
	origin = ns.ArtOrigin(frame)
	FadeRegions(frame)
	CreateArt(paperdollArt, { T.CHARACTER_TAB_ART .. "L1", T.CHARACTER_TAB_ART .. "R1",
		T.CHARACTER_TAB_ART .. "BottomLeft", T.CHARACTER_TAB_ART .. "BottomRight" }, 0, 0)
	-- 1.12 ReputationFrame / SkillFrame / PetPaperDollFrame drew these 2px
	-- right and 1px down; the pet page has its own bottom (with the XP bar's
	-- groove), the general one where the client lacks it.
	CreateArt(generalArt, { T.CHARACTER_GENERAL .. "TopLeft", T.CHARACTER_GENERAL .. "TopRight",
		T.CHARACTER_GENERAL .. "BottomLeft", T.CHARACTER_GENERAL .. "BottomRight" }, 2, -1)
	local petBottom = ns.HasTexture(T.PET_PAPERDOLL .. "BotLeft") and T.PET_PAPERDOLL .. "Bot" or T.CHARACTER_GENERAL .. "Bottom"
	CreateArt(petArt, { T.CHARACTER_GENERAL .. "TopLeft", T.CHARACTER_GENERAL .. "TopRight",
		petBottom .. "Left", petBottom .. "Right" }, 2, -1)
	UpdateArt()

	portrait = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
	portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait:SetPoint("TOPLEFT", origin, "TOPLEFT", PORTRAIT_X, PORTRAIT_Y)
	UpdatePortrait()
	if frame.PortraitContainer then Fade(frame.PortraitContainer.portrait) end

	Fade(frame.NineSlice)
	FadeRegions(frame.LeftPaneHost)
	FadeRegions(frame.RightPaneHost)
	for _, child in ipairs({ frame.RightPaneHost:GetChildren() }) do
		Fade(child) -- the divider between the panes
	end

	local title = frame.TitleContainer
	if title then
		title:ClearAllPoints()
		title:SetPoint("TOPLEFT", origin, "TOPLEFT", TITLE_LEFT, TITLE_Y)
		title:SetPoint("TOPRIGHT", origin, "TOPLEFT", TITLE_RIGHT, TITLE_Y)
	end

	local close = frame.CloseButton
	if close then
		ns.SkinCloseButton(close)
		Point(close, "CENTER", origin, "TOPLEFT", CLOSE_X, CLOSE_Y)
	end

	-- The pages anchor their content to the left pane.
	local left = frame.LeftPaneHost
	left:ClearAllPoints()
	left:SetPoint("TOPLEFT", origin, "TOPLEFT", CONTENT_X, CONTENT_Y)
	left:SetSize(CONTENT_WIDTH, CONTENT_HEIGHT)

	-- The art follows the page shown. Opened straight on another tab (the
	-- honor key, say), the page is switched while the frame is hidden, when
	-- the paperdoll's OnHide does not fire: the tab switch and the frame's
	-- show update it too.
	PaperDollFrame:HookScript("OnShow", UpdateArt)
	PaperDollFrame:HookScript("OnHide", UpdateArt)
	ns.Hook(frame, "ShowSubFrame", UpdateArt)
	frame:HookScript("OnShow", UpdateArt)
	frame:HookScript("OnShow", UpdatePortrait)
	frame:HookScript("OnEvent", function(_, event, unit)
		if event == "PORTRAITS_UPDATED" or (event == "UNIT_PORTRAIT_UPDATE" and unit == "player") then
			UpdatePortrait()
		end
	end)
end

-- The pages span the whole frame (631 wide with the right pane open) and
-- take the mouse; they are cut to the art so that the empty space around it
-- lets clicks through. The docked pane takes its own clicks.
local function UpdateHitRects()
	local left, right, top, bottom = ns.ArtHitRectInsets(frame, 0, origin:GetWidth() - HIT_WIDTH, 0, origin:GetHeight() - HIT_HEIGHT)
	right, bottom = math.max(0, right), math.max(0, bottom)
	frame:SetHitRectInsets(left, right, top, bottom)
	for _, name in ipairs(CHARACTERFRAME_SUBFRAMES or {}) do
		local page = _G[name]
		if page and page.SetHitRectInsets then
			page:SetHitRectInsets(left, right, top, bottom)
		end
	end
end

---------------------------------------------------------------------------
-- Tabs (1.12 CharacterFrameTabButtonTemplate)
---------------------------------------------------------------------------

-- The labels of Blizzard's tabs, by the page they show.
local TAB_LABELS = {
	PaperDollFrame = CHARACTER or "Character",
	ReputationFrame = REPUTATION or "Reputation",
	SkillsFrame = SKILLS or "Skills",
	PVPRankFrame = HONOR or "Honor", -- 1.12's name for the tab ("Player vs. Player" is too wide for the row)
	TokenFrame = CURRENCY or "Currency",
	StatisticsFrame = STATISTICS or "Statistics",
	GuildFrame = GUILD or "Guild", -- the inspect window's (CharacterInspect.lua)
}
local TAB_ART = { "Background", "Icon", "SelectedTexture", "HighlightTexture" }

-- The tab pieces (UI-Character-InActiveTab, 20px ends), as AuctionHouse.lua
-- draws them: the selected tab is the same file without its top rim,
-- stretched 5px up into the frame's border (the retail UI-Character-ActiveTab
-- is a different tab), with the white text.
local TAB_RIM_TOP, TAB_RIM_BOTTOM, TAB_ACTIVE_RISE = 0.15625, 0.875, 5

local function SetTabPiece(texture, left, right, top, bottom)
	ns.SetTexture(texture, T.TAB_INACTIVE, left, right, top, bottom)
end

local function UpdateTab(tab)
	local skin = tabSkins[tab]
	local selected = tab.SelectedTexture and tab.SelectedTexture:IsShown()
	local top, bottom, height, rise = 0, 1, TAB_HEIGHT, 0
	if selected then
		top, bottom, height, rise = TAB_RIM_TOP, TAB_RIM_BOTTOM, 28 + TAB_ACTIVE_RISE, TAB_ACTIVE_RISE
	end
	SetTabPiece(skin.left, 0, 0.15625, top, bottom)
	SetTabPiece(skin.middle, 0.15625, 0.84375, top, bottom)
	SetTabPiece(skin.right, 0.84375, 1, top, bottom)
	for _, piece in ipairs({ skin.left, skin.middle, skin.right }) do
		piece:SetHeight(height)
	end
	Point(skin.left, "TOPLEFT", tab, "TOPLEFT", 0, rise)
	skin.text:SetFontObject(selected and GameFontHighlightSmall or GameFontNormalSmall)
	skin.selected = selected
end

-- `label` is the tab's text; Blizzard's tabs of this window are named by
-- the page they show (TAB_LABELS).
local function SkinTab(tab, label)
	local skin = tabSkins[tab]
	if skin then return skin end
	skin = {}
	tabSkins[tab] = skin

	for _, key in ipairs(TAB_ART) do
		Fade(tab[key])
	end
	-- Blizzard pulses this glow's alpha; it is hidden instead.
	if tab.TabGlow then tab.TabGlow:Hide() end

	skin.left = tab:CreateTexture(nil, "BACKGROUND")
	skin.left:SetWidth(TAB_END)
	skin.middle = tab:CreateTexture(nil, "BACKGROUND")
	skin.middle:SetPoint("TOPLEFT", skin.left, "TOPRIGHT", 0, 0)
	skin.right = tab:CreateTexture(nil, "BACKGROUND")
	skin.right:SetWidth(TAB_END)
	skin.right:SetPoint("TOPLEFT", skin.middle, "TOPRIGHT", 0, 0)

	skin.text = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	skin.text:SetPoint("CENTER", tab, "CENTER", 0, 2)
	skin.text:SetText(label or TAB_LABELS[tab.frameName] or "")

	if ns.HasTexture(T.TAB_HIGHLIGHT) then
		local glow = tab:CreateTexture(nil, "HIGHLIGHT")
		ns.SetTexture(glow, T.TAB_HIGHLIGHT)
		glow:SetBlendMode("ADD")
		glow:SetHeight(TAB_HEIGHT)
		glow:SetPoint("LEFT", tab, "LEFT", 10, 2)
		glow:SetPoint("RIGHT", tab, "RIGHT", -10, 2)
	end
	-- The text lights up under the mouse (1.12's highlight font).
	tab:HookScript("OnEnter", function() skin.text:SetFontObject(GameFontHighlightSmall) end)
	tab:HookScript("OnLeave", function() UpdateTab(tab) end)

	ns.Hook(tab, "SetChecked", UpdateTab)
	return skin
end

-- The controller UI's L1 / R1 prompts (the window's TabIndicators):
-- Blizzard puts them over the first and under the last of its tab column;
-- on the tab row they go under its two ends (left of it, L1 would leave the
-- screen: the window opens at its left edge), with the footers under them.
local function PlaceTabIndicators(owner)
	local indicators = owner.TabIndicators
	local tabs = owner.ModeTabs and owner.ModeTabs.Tabs
	if not (indicators and indicators.LeftTabButton and indicators.RightTabButton and tabs) then return end
	local first, last
	for _, tab in ipairs(tabs) do
		if tab:IsShown() then
			first = first or tab
			last = tab
		end
	end
	if not first then return end
	Point(indicators.LeftTabButton, "TOPLEFT", first, "BOTTOMLEFT", TAB_INDICATOR_INSET, 0)
	Point(indicators.RightTabButton, "TOPRIGHT", last, "BOTTOMRIGHT", -TAB_INDICATOR_INSET, 0)
end

-- After Blizzard's tab layout (a column down the frame's right side): the
-- shown tabs of `owner` (the character or the inspect window) go into a row
-- under its art (`ownerOrigin`), each sized to its label.
local function LayoutModeTabs(owner, ownerOrigin)
	local tabs = owner.ModeTabs and owner.ModeTabs.Tabs
	if not tabs then return end
	local previous
	for _, tab in ipairs(tabs) do
		if tab:IsShown() then
			local skin = SkinTab(tab)
			local width = math.max(1, math.ceil(skin.text:GetStringWidth()) - 2 * TAB_TEXT_INTO_END)
			skin.middle:SetWidth(width)
			tab:SetSize(width + 2 * TAB_END, TAB_HEIGHT)
			if previous then
				Point(tab, "TOPLEFT", previous, "TOPRIGHT", -TAB_OVERLAP, 0)
			else
				Point(tab, "TOPLEFT", ownerOrigin, "TOPLEFT", TAB_X, TAB_Y)
			end
			UpdateTab(tab)
			previous = tab
		end
	end
	PlaceTabIndicators(owner)
end

-- The controller UI's focus glow (ns.SetGamepadBox) goes round the vanilla
-- window of `owner` (the character or the inspect window): from the art's
-- border down to the bottom of the tab row, which 1.12's hit rect also took
-- in. The jump hints and footers go under the L1 / R1 prompts. Blizzard
-- places those prompts again whenever they show; they go back under the
-- tab row after it. Returns the box.
local function SetUpController(owner, ownerOrigin)
	local box = ns.CreateArtBox(owner, ownerOrigin, HIT_WIDTH, TAB_HEIGHT - TAB_Y)
	local footerBox = CreateFrame("Frame", nil, owner)
	footerBox:SetPoint("TOPLEFT", box, "TOPLEFT", 0, 0)
	footerBox:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 0, -TAB_INDICATOR_ROW)
	ns.SetGamepadBox(owner, box, footerBox)
	if owner.TabIndicators then
		ns.Hook(owner.TabIndicators, "UpdateTabVisibility", function() PlaceTabIndicators(owner) end)
	end
	PlaceTabIndicators(owner)
	return box
end

local function LayoutTabs()
	LayoutModeTabs(frame, origin)
end

---------------------------------------------------------------------------
-- The right pane, docked in the 1.12 dialog box
---------------------------------------------------------------------------

local function DockRightPane()
	local pane = frame.RightPaneHost
	local width = pane:GetWidth()
	pane:ClearAllPoints()
	pane:SetPoint("TOPLEFT", origin, "TOPLEFT", DOCK_X + DOCK_INSET_LEFT, DOCK_Y - DOCK_INSET_TOP)
	pane:SetSize(width, DOCK_HEIGHT - DOCK_INSET_TOP - DOCK_INSET_BOTTOM)

	-- A child of the pane, so it shows and hides with it; at the frame's own
	-- level, behind the pane's contents (the frame's children).
	local box = CreateFrame("Frame", nil, pane, "BackdropTemplate")
	dockBox = box
	box:SetFrameLevel(frame:GetFrameLevel())
	box:SetPoint("TOPLEFT", pane, "TOPLEFT", -DOCK_INSET_LEFT, DOCK_INSET_TOP)
	box:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", DOCK_INSET_RIGHT, -DOCK_INSET_BOTTOM)
	box:SetBackdrop({ edgeFile = T.DIALOG_BORDER, edgeSize = 32 })
	box:EnableMouse(true)
	-- The dialog background (UI-DialogBox-Background, tiled) is see-through,
	-- fine for 1.12's small pop-outs; the pane's text needs a solid page, so
	-- it is drawn over black.
	local black = box:CreateTexture(nil, "BACKGROUND", nil, -8)
	black:SetColorTexture(0, 0, 0, 1)
	local tile = box:CreateTexture(nil, "BACKGROUND", nil, -7)
	tile:SetTexture(T.DIALOG_BACKGROUND, "REPEAT", "REPEAT")
	tile:SetHorizTile(true)
	tile:SetVertTile(true)
	for _, page in ipairs({ black, tile }) do
		page:SetPoint("TOPLEFT", box, "TOPLEFT", DOCK_INSET_LEFT, -DOCK_INSET_TOP)
		page:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -DOCK_INSET_RIGHT, DOCK_INSET_BOTTOM)
	end

	-- The pane's scroll lists: their borders and scroll lines go, the scroll
	-- bars become the classic knob bars.
	local panes = { CharacterStatsPaneScrollBox, CharacterStatsPanePetScrollBox, PaperDollFrame.EquipmentManagerPane, PaperDollFrame.TitleManagerPane }
	for _, list in pairs(panes) do
		FadeAtlases(list, PANE_ART)
		ns.SkinScrollBar(list.ScrollBar)
	end
	if CharacterStatsPaneScrollBox then Fade(CharacterStatsPaneScrollBox.ClassBackground) end
	for _, list in pairs({ CharacterStatsPaneScrollBox, CharacterStatsPanePetScrollBox }) do
		local scrollBox = list.ScrollBox
		if scrollBox then
			-- CharacterStatsPaneScrollBoxTemplate's insets, the bottom one cut.
			scrollBox:ClearAllPoints()
			scrollBox:SetPoint("TOPLEFT", list, "TOPLEFT", 10, -8)
			scrollBox:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -30, STATS_LIST_BOTTOM)
		end
	end

	local toggle = frame.RightPaneToggleButton
	if toggle then
		Point(toggle, "CENTER", origin, "TOPLEFT", TOGGLE_X, TOGGLE_Y)
	end
end

---------------------------------------------------------------------------
-- Paperdoll: slots, model, name lines
---------------------------------------------------------------------------

-- A vanilla slot (ItemButtonTemplate): the UI-Quickslot2 frame round the
-- icon, in place of the modern gear slot frame.
local function SkinSlot(slot)
	if slot.BorderFrame then Fade(slot.BorderFrame) end
	slot:SetNormalTexture(T.QUICKSLOT2)
	local normal = slot:GetNormalTexture()
	normal:ClearAllPoints()
	normal:SetSize(64, 64)
	normal:SetPoint("CENTER", slot, "CENTER", 0, -1)
end

local function PlaceSlots()
	for index, name in ipairs(LEFT_SLOTS) do
		local slot = _G[name]
		if slot then
			SkinSlot(slot)
			Point(slot, "TOPLEFT", origin, "TOPLEFT", SLOT_LEFT_X, SLOT_Y - (index - 1) * SLOT_STRIDE)
		end
	end
	for index, name in ipairs(RIGHT_SLOTS) do
		local slot = _G[name]
		if slot then
			SkinSlot(slot)
			Point(slot, "TOPLEFT", origin, "TOPLEFT", SLOT_RIGHT_X, SLOT_Y - (index - 1) * SLOT_STRIDE)
		end
	end
	-- Without a ranged slot (Blizzard hides it for good at load) the other
	-- two are centred on the three sockets.
	local ranged = not C_PaperDollInfo.IsRangedSlotShown or C_PaperDollInfo.IsRangedSlotShown()
	local x = WEAPON_X + (ranged and 0 or WEAPON_STRIDE / 2)
	for index, name in ipairs(WEAPON_SLOTS) do
		local slot = _G[name]
		if slot then
			SkinSlot(slot)
			Point(slot, "TOPLEFT", origin, "TOPLEFT", x + (index - 1) * WEAPON_STRIDE, WEAPON_Y)
		end
	end

	local ammo = CharacterAmmoSlot
	if ammo then
		-- Its modern slot frame and arrow go; the vanilla ammo socket instead.
		FadeAtlases(ammo, AMMO_ART)
		local socket = ammo:CreateTexture(nil, "BACKGROUND", nil, -1)
		ns.SetTexture(socket, T.AMMO_SLOT, 0, 0.640625, 0, 0.640625)
		socket:SetSize(41, 41)
		socket:SetPoint("CENTER", ammo, "CENTER", 0, 0)
		local anchor = ranged and CharacterRangedSlot or CharacterSecondaryHandSlot
		Point(ammo, "LEFT", anchor, "RIGHT", AMMO_GAP, 0)
	end
end

-- Between the slots, or over the pet page's whole width.
local function SetModelSpot(pet)
	local scene = CharacterModelScene
	if pet then
		Point(scene, "TOPLEFT", origin, "TOPLEFT", PET_MODEL_X, PET_MODEL_Y)
		scene:SetSize(PET_MODEL_WIDTH, PET_MODEL_HEIGHT)
	else
		Point(scene, "TOPLEFT", origin, "TOPLEFT", MODEL_X, MODEL_Y)
		scene:SetSize(MODEL_WIDTH, MODEL_HEIGHT)
	end
end

local function PlaceModel()
	local scene = CharacterModelScene
	if not scene then return end
	SetModelSpot(false)
	-- The race backgrounds: vanilla drew the model on the dark page.
	for _, key in ipairs({ "BackgroundTopLeft", "BackgroundTopRight", "BackgroundBotLeft", "BackgroundBotRight", "BackgroundOverlay" }) do
		Fade(scene[key])
	end
	-- The rock strip Blizzard draws across the top of the left pane, over the
	-- art's band (behind its level line, see CreateNameLines).
	if PaperDollFrame.TopBackgroundStripHost then
		FadeRegions(PaperDollFrame.TopBackgroundStripHost)
	end
	-- The zoom / rotate bar shows while the mouse is over the model (the
	-- scene's OnEnter / OnLeave), but PaperDollFrame_OnShow shows it on every
	-- open as well, where it stayed until the mouse had crossed the model.
	-- Blizzard hangs it under the left pane's top (under its rock strip); it
	-- goes back to the model's top, on the paperdoll and the pet page.
	local controls = scene.ControlFrame
	if controls then
		Point(controls, "TOP", scene, "TOP", 0, -10)
		PaperDollFrame:HookScript("OnShow", function()
			if not scene:IsMouseOver() and not controls:IsMouseOver() then
				controls:Hide()
			end
		end)
	end
end

local function UpdateGuild()
	local guild, rank = GetGuildInfo("player")
	if guild then
		guildText:SetFormattedText(GUILD_TITLE_TEMPLATE or "%s of %s", rank, guild)
	else
		guildText:SetText("")
	end
end

-- 1.12's small level line under the title. The player's is copied from
-- Blizzard's whenever Blizzard sets it; the pet's is written as Blizzard's
-- old one was ("Level 20 Wolf"): Blizzard's adds the loyalty, which goes on
-- the guild line here.
local function UpdateLevel()
	if IsPetPage() and UnitExists("pet") then
		levelText:SetFormattedText(UNIT_TYPE_LEVEL_TEMPLATE or "Level %d %s", UnitLevel("pet"), UnitCreatureFamily("pet") or "")
	else
		levelText:SetText(CharacterLevelText and CharacterLevelText:GetText() or "")
	end
end

-- The pet page: the pet's name on the title bar (in place of Blizzard's
-- title, the player's name) and its loyalty in place of the guild line.
local function UpdatePetLines()
	local pet = IsPetPage()
	if frame.TitleContainer then frame.TitleContainer:SetAlpha(pet and 0 or 1) end
	petNameText:SetShown(pet)
	if not pet then
		UpdateGuild()
		return
	end
	petNameText:SetText(UnitName("pet") or "")
	local loyalty = C_PetInfo and C_PetInfo.GetPetLoyalty and C_PetInfo.GetPetLoyalty()
	guildText:SetText(loyalty or "")
end

local function CreateNameLines(parent)
	local lines = CreateFrame("Frame", nil, parent)
	lines:SetAllPoints(frame)
	lines:SetFrameLevel(CharacterModelScene:GetFrameLevel() + 5)
	levelText = lines:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	levelText:SetPoint("TOP", origin, "TOPLEFT", (TITLE_LEFT + TITLE_RIGHT) / 2, LEVEL_Y)
	guildText = lines:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	guildText:SetPoint("TOP", levelText, "BOTTOM", 0, -1)
	-- On the title bar (1.12's PetNameText), where Blizzard's title is faded.
	petNameText = lines:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	petNameText:SetPoint("TOPLEFT", origin, "TOPLEFT", TITLE_LEFT, TITLE_Y)
	petNameText:SetPoint("TOPRIGHT", origin, "TOPLEFT", TITLE_RIGHT, TITLE_Y)
	petNameText:SetHeight(frame.TitleContainer and frame.TitleContainer:GetHeight() or 20)
	petNameText:Hide()
	-- Blizzard's level lines (the player's and the pet's, a large outlined
	-- font over the top of the left pane, shown and hidden by Blizzard).
	Fade(PaperDollLevelInfo)
	Fade(PaperDollPetLevelInfo)
	UpdateLevel()
	UpdateGuild()
	ns.Hook("PaperDollFrame_SetLevel", UpdateLevel)
	ns.Hook("PaperDollFrame_SetPetLevel", function()
		UpdateLevel()
		UpdatePetLines()
	end)
	lines:RegisterEvent("PLAYER_GUILD_UPDATE")
	lines:RegisterUnitEvent("UNIT_NAME_UPDATE", "pet")
	lines:SetScript("OnEvent", UpdatePetLines)
	lines:SetScript("OnShow", UpdatePetLines)
end

---------------------------------------------------------------------------
-- Stat boxes and resistances
---------------------------------------------------------------------------

local function CategoryLabel(category)
	return _G[category.key] or category.fallback
end

local function CategoryByKey(key)
	for _, category in ipairs(STAT_CATEGORIES) do
		if category.key == key then return category end
	end
end

-- The chosen category of a box: the client's 2.x CVar when it has one, else
-- the addon's saved variables.
local function DefaultCategory(side)
	if side == "left" then return STAT_CATEGORIES[1].key end
	local _, class = UnitClass("player")
	if CASTERS[class] then return "PLAYERSTAT_SPELL_COMBAT" end
	if class == "HUNTER" then return "PLAYERSTAT_RANGED_COMBAT" end
	return "PLAYERSTAT_MELEE_COMBAT"
end

local function GetCategory(side)
	local key = C_CVar.GetCVar(STAT_CVARS[side])
	if not CategoryByKey(key or "") then
		key = ns.db["characterStats_" .. side]
	end
	return CategoryByKey(key or "") or CategoryByKey(DefaultCategory(side))
end

local function SetCategory(side, key)
	if C_CVar.GetCVar(STAT_CVARS[side]) ~= nil then
		C_CVar.SetCVar(STAT_CVARS[side], key)
	end
	ns.db["characterStats_" .. side] = key
end

-- Fills a box's rows from Blizzard's stat functions (they set the label,
-- the value and the tooltip on the row, as on Blizzard's own stat rows).
-- A stat is left out (and the rows close up) when its function fails,
-- returns its hideAt, hides the row or writes no value: some return early
-- when the stat does not apply (no ranged weapon, no off hand).
-- In combat the stat functions work on secret values (12.x): what they
-- return and the text / shown state they set read back secret, and addon
-- code may not compare or test those. A secret stat is shown as is.
local function IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value)
end

local function StatsUnit()
	return IsPetPage() and "pet" or "player"
end

local function UpdateStatBox(side, unit)
	local box = statBoxes[side]
	local stats = unit == "pet" and PET_STATS[side] or GetCategory(side).stats
	local shown = 0
	for _, stat in ipairs(stats) do
		local info = PAPERDOLL_STATINFO and PAPERDOLL_STATINFO[stat[1]]
		local row = box.rows[shown + 1]
		if info and info.updateFunc and row then
			row.onEnterFunc = nil
			row.tooltip, row.tooltip2, row.tooltip3 = nil, nil, nil
			row.Label:SetText("")
			row.Value:SetText("")
			row:Show()
			local ok, value = pcall(info.updateFunc, row, unit)
			local hidden = stat[2] ~= nil and not IsSecret(value) and value == stat[2]
			local rowShown = row:IsShown()
			rowShown = IsSecret(rowShown) or rowShown
			local text = row.Value:GetText()
			local hasValue = IsSecret(text) or (text or "") ~= ""
			if ok and not hidden and rowShown and hasValue then
				if stat[3] then
					row.Label:SetFormattedText(STAT_FORMAT or "%s:", stat[3])
				end
				shown = shown + 1
			end
		end
	end
	for index, row in ipairs(box.rows) do
		row:SetShown(index <= shown)
	end
end

local function UpdateResistances()
	local unit = StatsUnit()
	for _, resistance in ipairs(resistances) do
		local id = resistance:GetID()
		local _, total, positive, negative = UnitResistance(unit, id)
		local color = HIGHLIGHT_FONT_COLOR
		if IsSecret(total) or IsSecret(positive) or IsSecret(negative) then
			-- Shown as is (white); the colour needs a comparison.
		else
			total, positive, negative = total or 0, positive or 0, negative or 0
			if math.abs(negative) > positive then
				color = RED_FONT_COLOR
			elseif math.abs(negative) < positive then
				color = GREEN_FONT_COLOR
			end
		end
		resistance.text:SetText(total)
		resistance.text:SetTextColor(color:GetRGB())
		resistance.tooltip, resistance.tooltip2 = nil, nil
		if PaperDollFrame_SetResistanceTooltips then
			pcall(PaperDollFrame_SetResistanceTooltips, resistance, _G["DAMAGE_SCHOOL" .. (id + 1)] or "", total, unit, id)
		end
	end
end

-- The stat functions only work on combat's secret values when Blizzard's
-- own code calls them (called from here, most fail), so the stat boxes keep
-- what they show during combat and are filled again when it ends. They are
-- also filled out of combat while the window is closed (`always`), so that
-- a window first opened in combat is not empty. The resistances are shown
-- as they come (secret ones in white, see UpdateResistances). Switched
-- between the player and the pet in combat, the boxes stay empty until it
-- ends.
local statsPending = false
local statsUnit            -- whose stats the boxes show
local function UpdateStats(always)
	if not (always or PaperDollFrame:IsShown()) then return end
	local unit = StatsUnit()
	if InCombatLockdown() then
		statsPending = true
		if unit ~= statsUnit then
			for _, box in pairs(statBoxes) do
				for _, row in ipairs(box.rows) do row:Hide() end
			end
			statsUnit = nil
		end
	else
		statsPending = false
		statsUnit = unit
		UpdateStatBox("left", unit)
		UpdateStatBox("right", unit)
	end
	UpdateResistances()
end

-- A stat row: Blizzard's CharacterStatFrameTemplate (label, value and its
-- tooltip script) at the size and fonts of 1.12's StatFrameTemplate.
local function CreateStatRow(parent)
	local row = CreateFrame("Frame", nil, parent, "CharacterStatFrameTemplate")
	row:SetSize(STAT_ROW_WIDTH, STAT_ROW_HEIGHT)
	Fade(row.Background)
	row.Value:SetFontObject(GameFontHighlightSmall)
	Point(row.Value, "RIGHT", row, "RIGHT", 0, 0)
	-- A label that is still too long is cut short instead of running into
	-- the value.
	row.Label:SetFontObject(GameFontNormalSmall)
	row.Label:SetJustifyH("LEFT")
	row.Label:SetWordWrap(false)
	Point(row.Label, "LEFT", row, "LEFT", 0, 0)
	row.Label:SetPoint("RIGHT", row.Value, "LEFT", -2, 0)
	return row
end

-- 2.x's stat box: UI-Character-StatBackground's top, middle and bottom
-- (115 wide), six rows 6px in, and the dropdown over its top.
local function CreateStatBox(parent, side, x)
	local pieces = {
		{ 16, 0, 0.125 }, { 53, 0.125, 0.1953125 }, { 16, 0.484375, 0.609375 },
	}
	local y = 0
	for _, piece in ipairs(pieces) do
		local texture = parent:CreateTexture(nil, "BACKGROUND")
		ns.SetTexture(texture, T.STAT_BACKGROUND, 0, 0.8984375, piece[2], piece[3])
		texture:SetSize(STAT_BOX_WIDTH, piece[1])
		texture:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
		y = y - piece[1]
	end

	local box = { rows = {} }
	for index = 1, STAT_ROWS do
		local row = CreateStatRow(parent)
		row:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 6, -3 - (index - 1) * STAT_ROW_HEIGHT)
		box.rows[index] = row
	end

	-- The box art (CharacterCreate-LabelFrame) is see-through for 13px at
	-- its left end and 14px at its right: the frame is that much wider than
	-- the drawn box, which spans the stat box (1px in at each side), and it
	-- takes the mouse on the drawn box only.
	local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
	ns.SkinDropdownBox(dropdown, STAT_BOX_WIDTH - 2 + DROPDOWN_CLEAR_LEFT + DROPDOWN_CLEAR_RIGHT - 50)
	dropdown:SetHitRectInsets(DROPDOWN_CLEAR_LEFT, DROPDOWN_CLEAR_RIGHT, 0, 0)
	dropdown:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", x + 1 - DROPDOWN_CLEAR_LEFT, -2)
	dropdown:SetupMenu(function(_, root)
		for _, category in ipairs(STAT_CATEGORIES) do
			root:CreateRadio(CategoryLabel(category), function(key)
				return GetCategory(side).key == key
			end, function(key)
				SetCategory(side, key)
				UpdateStats()
			end, category.key)
		end
	end)
	box.dropdown = dropdown
	statBoxes[side] = box
end

local function CreateResistances(parent)
	local previous
	for index, entry in ipairs(RESISTANCES) do
		local resistance = CreateFrame("Frame", nil, parent)
		resistance:SetID(entry.id)
		resistance:SetSize(RESIST_WIDTH, RESIST_HEIGHT)
		if previous then
			resistance:SetPoint("TOP", previous, "BOTTOM", 0, 0)
		else
			resistance:SetPoint("TOPRIGHT", origin, "TOPLEFT", RESIST_RIGHT, RESIST_Y)
		end
		local icon = resistance:CreateTexture(nil, "BACKGROUND")
		ns.SetTexture(icon, T.RESISTANCE_ICONS, 0, 1, entry.top, entry.bottom)
		icon:SetAllPoints(resistance)
		resistance.text = resistance:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		resistance.text:SetPoint("BOTTOM", resistance, "BOTTOM", 0, 3)
		-- Tooltips only; clicks go on to the model (turning it).
		resistance:SetMouseMotionEnabled(true)
		resistance:SetScript("OnEnter", PaperDollStatTooltip)
		resistance:SetScript("OnLeave", GameTooltip_Hide)
		resistances[index] = resistance
		previous = resistance
	end
end

local function CreateStats()
	-- Above the model (it takes the mouse for turning it), below the slots.
	local level = CharacterModelScene:GetFrameLevel() + 5
	attributes = CreateFrame("Frame", nil, PaperDollFrame)
	attributes:SetFrameLevel(level)
	attributes:SetSize(2 * STAT_BOX_WIDTH, 85)
	attributes:SetPoint("TOPLEFT", origin, "TOPLEFT", STATS_X, STATS_Y)
	CreateStatBox(attributes, "left", 0)
	CreateStatBox(attributes, "right", STAT_BOX_WIDTH)

	local column = CreateFrame("Frame", nil, PaperDollFrame)
	column:SetFrameLevel(level)
	column:SetAllPoints(frame)
	CreateResistances(column)

	ns.Hook("PaperDollFrame_UpdateStats", function() UpdateStats() end)
	local events = CreateFrame("Frame", nil, attributes)
	events:RegisterUnitEvent("UNIT_RESISTANCES", "player", "pet")
	events:RegisterEvent("PLAYER_ENTERING_WORLD")
	events:RegisterEvent("PLAYER_REGEN_ENABLED")
	events:SetScript("OnEvent", function(_, event)
		if event == "UNIT_RESISTANCES" then
			UpdateResistances()
		elseif event == "PLAYER_ENTERING_WORLD" or statsPending then
			UpdateStats(true)
		end
	end)
	UpdateStats(true)
end

---------------------------------------------------------------------------
-- Pet page (1.12 PetPaperDollFrame)
---------------------------------------------------------------------------

-- Blizzard's XP bar (a modern progress bar, over the model's bottom) is
-- faded; this is 1.12's, shown whenever Blizzard shows its own (pets that
-- gain experience).
local function UpdatePetXPBar()
	local blizzard = PetPaperDollFrameExpBar
	local shown = IsPetPage() and blizzard ~= nil and blizzard:IsShown()
	petXPBar:SetShown(shown)
	if not shown then return end
	local current, needed = GetPetExperience()
	current, needed = current or 0, needed or 0
	petXPBar:SetMinMaxValues(0, math.max(1, needed))
	petXPBar:SetValue(current)
	petXPBar.text:SetFormattedText("%s %s / %s", XP or "XP", current, needed)
end

local function CreatePetXPBar()
	petXPBar = CreateFrame("StatusBar", nil, PaperDollFrame)
	petXPBar:SetFrameLevel(CharacterModelScene:GetFrameLevel() + 5)
	petXPBar:SetSize(PET_XP_WIDTH, PET_XP_HEIGHT)
	petXPBar:SetPoint("TOPLEFT", origin, "TOPLEFT", PET_XP_X, PET_XP_Y)
	ns.SetBarTexture(petXPBar, T.STATUS_BAR)
	petXPBar:SetStatusBarColor(unpack(PET_XP_COLOR))
	-- The border: two halves of the main menu bar's XP bar frame.
	local previous
	for _, width in ipairs({ 160, 159 }) do
		local border = petXPBar:CreateTexture(nil, "OVERLAY")
		ns.SetTexture(border, T.MAINMENUBAR_STRIP, 0.203125, 0.8046875, 0.2890625, 0.33984375)
		border:SetSize(width, 13)
		if previous then
			border:SetPoint("LEFT", previous, "RIGHT", 0, 0)
		else
			border:SetPoint("TOPLEFT", petXPBar, "TOPLEFT", 0, 0)
		end
		previous = border
	end
	petXPBar.text = petXPBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	petXPBar.text:SetPoint("CENTER", petXPBar, "CENTER", 0, 1)
	petXPBar:Hide()

	local blizzard = PetPaperDollFrameExpBar
	if blizzard then
		blizzard:SetAlpha(0)
		blizzard:HookScript("OnShow", UpdatePetXPBar)
		blizzard:HookScript("OnHide", UpdatePetXPBar)
	end
end

-- Switches the page between the paperdoll and the pet page whenever
-- Blizzard switches the view (its right pane's tabs, the pet going away,
-- the page showing).
local function UpdatePetPage()
	local pet = IsPetPage()
	UpdateArt()
	UpdatePortrait()
	SetModelSpot(pet)
	Point(attributes, "TOPLEFT", origin, "TOPLEFT", STATS_X, pet and PET_STATS_Y or STATS_Y)
	for _, box in pairs(statBoxes) do
		box.dropdown:SetShown(not pet)
	end
	Point(resistances[1], "TOPRIGHT", origin, "TOPLEFT", pet and PET_RESIST_RIGHT or RESIST_RIGHT, RESIST_Y)
	UpdateLevel()
	UpdatePetLines()
	UpdatePetXPBar()
	if pet ~= (statsUnit == "pet") then
		UpdateStats()
	end
end

local function CreatePetPage()
	CreatePetXPBar()
	if PetPaperDollPetHappinessInfo then
		Point(PetPaperDollPetHappinessInfo, "TOPLEFT", origin, "TOPLEFT", PET_HAPPINESS_X, PET_HAPPINESS_Y)
	end

	ns.Hook("PaperDollFrame_ShowSidebar", UpdatePetPage)
	PaperDollFrame:HookScript("OnShow", UpdatePetPage)
	PaperDollFrame:HookScript("OnHide", UpdatePetPage)
	local events = CreateFrame("Frame", nil, PaperDollFrame)
	events:RegisterUnitEvent("UNIT_PET", "player")
	events:RegisterUnitEvent("UNIT_PET_EXPERIENCE", "player")
	events:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "pet")
	events:SetScript("OnEvent", UpdatePetPage)
	UpdatePetPage()
end

---------------------------------------------------------------------------
-- Shared by the tab pages' lists (CharacterReputation.lua,
-- CharacterSkills.lua)
--
-- Forever's pages list their rows in a ScrollBox whose row heights and
-- spacing come from the row templates and the view's padding. Those are
-- Lua fields the rows' initialization reads, and a row's click opens the
-- right pane (which feeds the panel manager), so they must stay untainted.
-- The rows are brought to the vanilla spacing by scaling the whole list
-- down and each row's content back up to full size (the pages do the
-- latter); a header row has no content frame, so its button, text and
-- offsets are enlarged by the same factor instead.
---------------------------------------------------------------------------

-- T.PLUS_BUTTON / T.MINUS_BUTTON (+ Up / Down / Hilight) come from TrainerFrame.lua.
T.SKILLS_BAR   = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar"

local list = {}
ns.CharacterList = list

local EXPAND_BUTTON_SIZE = 16 -- 1.12's +/- buttons

-- Fades a frame's own textures that carry an atlas (Blizzard's modern
-- backgrounds and highlights; the module's own textures are files).
function list.FadeAtlasRegions(owner)
	for _, region in ipairs({ owner:GetRegions() }) do
		if region:IsObjectType("Texture") and region:GetAtlas() then
			region:SetAlpha(0)
		end
	end
end

-- Puts a page's list on the vanilla list spot (offsets from the art's top
-- left), scaled down: its own offsets and size are in its smaller units.
-- The scroll lines and fading edges go, the scroll bar (Blizzard anchors it
-- to the list's right edge) becomes the classic knob bar, and a frame over
-- the page (it spans the character frame at the frame's level) gets the
-- scroll bar trough; the page draws its own art on it too.
function list.SkinList(page, left, top, right, bottom, scale)
	local scrollBox = page.ScrollBox
	scrollBox:SetScale(scale)
	scrollBox:ClearAllPoints()
	scrollBox:SetPoint("TOPLEFT", origin, "TOPLEFT", left / scale, top / scale)
	scrollBox:SetSize((right - left) / scale, (top - bottom) / scale)
	for _, child in ipairs({ scrollBox:GetChildren() }) do
		list.FadeAtlasRegions(child)
	end
	if scrollBox.GetUpperShadowTexture then
		Fade(scrollBox:GetUpperShadowTexture())
		Fade(scrollBox:GetLowerShadowTexture())
	end
	ns.SkinScrollBar(page.ScrollBar)

	local overlay = CreateFrame("Frame", nil, page)
	overlay:SetAllPoints(page)
	overlay:SetFrameLevel(page:GetFrameLevel() + 1)
	-- UI-Character-ScrollBar: the trough's top piece cut to the list's
	-- height, over its bottom cap.
	local height = top - bottom
	local capHeight = 106
	local topHeight = math.min(256, height + 7 - capHeight)
	local trough = overlay:CreateTexture(nil, "BACKGROUND")
	ns.SetTexture(trough, T.CHARACTER_SCROLLBAR, 0, 0.484375, 0, topHeight / 256)
	trough:SetSize(31, topHeight)
	trough:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", -2, 5)
	local cap = overlay:CreateTexture(nil, "BACKGROUND")
	ns.SetTexture(cap, T.CHARACTER_SCROLLBAR, 0.515625, 1, 0, 0.4140625)
	cap:SetSize(31, capHeight)
	cap:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", -2, -2)
	return overlay
end

-- The vanilla +/- (UI-PlusButton / UI-MinusButton).
function list.SetExpandTexture(texture, collapsed, state)
	texture:SetTexture((collapsed and T.PLUS_BUTTON or T.MINUS_BUTTON) .. state)
end

-- A header row (the row's own regions, scaled down with the list): Blizzard's
-- band and state icon go; the +/- at buttonX and the name at textX in the
-- given font, enlarged by 1 / scale.
function list.SkinHeader(row, scale, fontObject, buttonX, textX)
	local skin = {}
	list.FadeAtlasRegions(row)
	Fade(row.StateIcon)
	skin.button = row:CreateTexture(nil, "ARTWORK")
	skin.button:SetSize(EXPAND_BUTTON_SIZE / scale, EXPAND_BUTTON_SIZE / scale)
	skin.button:SetPoint("LEFT", row, "LEFT", buttonX / scale, 0)
	local glow = row:CreateTexture(nil, "HIGHLIGHT")
	glow:SetTexture(T.PLUS_BUTTON .. "Hilight")
	glow:SetBlendMode("ADD")
	glow:SetAllPoints(skin.button)
	Point(row.Name, "LEFT", row, "LEFT", textX / scale, 0)
	local font, size, flags = fontObject:GetFont()
	row.Name:SetFont(font, size / scale, flags or "")
	return skin
end

-- A sub-header's collapse button (the row's, scaled down with the list) as
-- the vanilla +/-. Blizzard sets atlases (at their own size) on its
-- textures on every refresh; anchored at both corners they keep its size.
function list.SkinToggle(toggle, scale)
	toggle:SetSize(EXPAND_BUTTON_SIZE / scale, EXPAND_BUTTON_SIZE / scale)
	toggle:SetHighlightTexture(T.PLUS_BUTTON .. "Hilight", "ADD")
	for _, texture in ipairs({ toggle:GetNormalTexture(), toggle:GetPushedTexture(), toggle:GetHighlightTexture() }) do
		texture:ClearAllPoints()
		texture:SetAllPoints(toggle)
	end
end

-- After Blizzard's RefreshIcon (its atlases).
function list.UpdateToggle(toggle, collapsed)
	toggle:SetNormalTexture((collapsed and T.PLUS_BUTTON or T.MINUS_BUTTON) .. "Up")
	toggle:SetPushedTexture((collapsed and T.PLUS_BUTTON or T.MINUS_BUTTON) .. "Down")
end

-- A bar fill: the vanilla bar texture on its bar's left, cut to the
-- percentage like a StatusBar's fill.
function list.SetFill(fill, width, percent)
	percent = math.min(1, math.max(0, percent or 0))
	fill:SetShown(percent > 0)
	fill:SetWidth(math.max(1, width * percent))
	fill:SetTexCoord(0, percent, 0, 1)
end

-- Skins a page's rows: skin(row) when the ScrollBox acquires a row (before
-- its first Initialize, so hooks on it see every update) and update(row,
-- skin) after every Initialize.
function list.OnRows(page, owner, skin, update)
	local skins = setmetatable({}, { __mode = "k" })
	local function Get(row)
		if skins[row] == nil then
			skins[row] = skin(row) or false
		end
		return skins[row]
	end
	ScrollUtil.AddAcquiredFrameCallback(page.ScrollBox, function(_, row) Get(row) end, owner)
	ScrollUtil.AddInitializedFrameCallback(page.ScrollBox, function(_, row)
		local rowSkin = Get(row)
		if rowSkin then update(row, rowSkin) end
	end, owner)
end

---------------------------------------------------------------------------
-- Module
---------------------------------------------------------------------------

-- Every session starts with the window collapsed (the vanilla window
-- alone); the arrow opens the pane. Blizzard reads the CVar when the frame
-- loads, before any addon, so this takes effect from the next session on
-- (the frame's state is never changed from here: Blizzard reads it in the
-- panel layout). The value from before comes back at a login with the
-- option off (on Forever, whose beta client does not load saved variables,
-- the window then simply stays collapsed by default).
local function StartCollapsed()
	local value = C_CVar.GetCVar(COLLAPSED_CVAR)
	if value == nil then return end
	if ns.db.characterPreviousCollapsed == nil and value ~= "1" then
		ns.db.characterPreviousCollapsed = value
	end
	C_CVar.SetCVar(COLLAPSED_CVAR, "1")
end

-- With the right pane open the controller UI's glow and footers go round
-- the vanilla window and the docked pane together (the dialog box ends at
-- the bottom of the tab row too).
local function UpdateControllerBox()
	if not controllerBox then return end
	if dockBox and frame.RightPaneHost:IsShown() then
		controllerBox:SetPoint("BOTTOMRIGHT", dockBox, "BOTTOMRIGHT", 0, 0)
	else
		controllerBox:SetPoint("BOTTOMRIGHT", origin, "TOPLEFT", HIT_WIDTH, TAB_Y - TAB_HEIGHT)
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
	if not ns:IsEnabled(module.key) and ns.db.characterPreviousCollapsed ~= nil then
		C_CVar.SetCVar(COLLAPSED_CVAR, ns.db.characterPreviousCollapsed)
		ns.db.characterPreviousCollapsed = nil
	end
end)

function module:Apply()
	frame = CharacterFrame
	if not (frame and frame.LeftPaneHost and frame.RightPaneHost and frame.ModeTabs and PaperDollFrame and CharacterModelScene) then
		return
	end
	for _, piece in ipairs({ "L1", "R1", "BottomLeft", "BottomRight" }) do
		if not ns.HasTexture(T.CHARACTER_TAB_ART .. piece) then
			ns.Print("This client does not ship " .. T.CHARACTER_TAB_ART .. piece .. "; the character window keeps the retail look.")
			return
		end
	end

	SkinChrome()
	DockRightPane()
	PlaceSlots()
	PlaceModel()
	CreateNameLines(PaperDollFrame)
	CreateStats()
	CreatePetPage()

	ns.Hook(frame, "UpdateTabLayout", LayoutTabs)
	LayoutTabs()
	ns.Hook(frame, "UpdateSize", UpdateHitRects)
	UpdateHitRects()
	controllerBox = SetUpController(frame, origin)
	ns.Hook(frame, "UpdateSize", UpdateControllerBox)
	UpdateControllerBox()
	StartCollapsed()
	-- The tab pages (CharacterReputation.lua, ...) and the inspect window
	-- (CharacterInspect.lua) are skinned only with it.
	ns.characterWindowSkinned = true
end

-- What the inspect window (CharacterInspect.lua) shares with this one: the
-- 1.12 art and geometry (offsets from the art's top left), the slot skin
-- and the tab row.
ns.CharacterWindow = {
	CreateArt = CreateArt,
	SkinSlot = SkinSlot,
	LayoutModeTabs = LayoutModeTabs,
	SetUpController = SetUpController,
	-- The vanilla tab skin on a Blizzard LargeSideTabButtonTemplate tab (the
	-- group finder's, GroupFinder.lua): SkinTab(tab, label) returns the skin
	-- (its label is skin.text, its middle piece skin.middle), UpdateTab
	-- redraws it after a size change.
	SkinTab = SkinTab,
	UpdateTab = UpdateTab,
	TAB_END = TAB_END, TAB_HEIGHT = TAB_HEIGHT, TAB_OVERLAP = TAB_OVERLAP, TAB_TEXT_INTO_END = TAB_TEXT_INTO_END,
	PORTRAIT_X = PORTRAIT_X, PORTRAIT_Y = PORTRAIT_Y, PORTRAIT_SIZE = PORTRAIT_SIZE,
	CLOSE_X = CLOSE_X, CLOSE_Y = CLOSE_Y,
	TITLE_LEFT = TITLE_LEFT, TITLE_RIGHT = TITLE_RIGHT, TITLE_Y = TITLE_Y, LEVEL_Y = LEVEL_Y,
	SLOT_LEFT_X = SLOT_LEFT_X, SLOT_RIGHT_X = SLOT_RIGHT_X, SLOT_Y = SLOT_Y, SLOT_STRIDE = SLOT_STRIDE,
	WEAPON_X = WEAPON_X, WEAPON_Y = WEAPON_Y, WEAPON_STRIDE = WEAPON_STRIDE,
	MODEL_X = MODEL_X, MODEL_Y = MODEL_Y, MODEL_WIDTH = MODEL_WIDTH,
	HIT_WIDTH = HIT_WIDTH, HIT_HEIGHT = HIT_HEIGHT,
}
