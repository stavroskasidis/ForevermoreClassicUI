--[[
	Forevermore Classic UI - Character window: Inspect window (WoW Forever only)

	Restores the vanilla inspect window (1.12 InspectFrame.xml /
	InspectPaperDollFrame.xml), as part of the Character Window option so the
	two windows always match: the same 384x512 frame and paperdoll art as the
	vanilla character window (CharacterFrame.lua), the inspected player's
	portrait in the ring, their name on the title bar and their level line
	under it, the equipment slots down both sides and along the bottom in the
	classic UI-Quickslot2 frames, the model over the whole dark page (1.12's
	inspect window had no stat boxes), the round close button and the tabs
	under the frame (Character, and Guild when the player has one). The
	guild page gets the plain frame (UI-Character-General-*), as the
	character window's other pages do.

	Forever's inspect window (Blizzard_InspectUI\Camelot) is a
	ButtonFrameTemplate panel (338x424) with the paperdoll page
	(InspectPaperDollFrame: level line, the model, the slots) and the guild page,
	switched by icon tabs down its right side (InspectFrame.ModeTabs,
	LargeSideTabButtonTemplate, as on its character window); its bottom tabs
	are hidden. It is re-skinned in place with CharacterFrame.lua's art, slot
	skin, geometry and tab row (ns.CharacterWindow):

	  * the vanilla art is drawn at the frame's top-left corner (ns.ArtOrigin;
	    the frame is the vanilla window's height without its tab shelf, so it
	    opens where the modern one does); the NineSlice, the inset and the
	    modern portrait are faded and the frame takes the mouse over the art,
	  * the slots, model, level line (in 1.12's small font) and the faction
	    logo (shown instead of an out-of-range player's model) are placed on
	    the vanilla spots,
	  * the icon tabs are Blizzard's own tab frames, moved under the frame and
	    drawn as the vanilla tabs (so a click stays Blizzard's),
	  * with the controller UI on, its focus glow, footer and L1 / R1 tab
	    prompts go round the vanilla window and its tab row, as on the
	    character window.

	Blizzard_InspectUI is load-on-demand: the window is skinned when it
	loads. Window Frames (Windows.lua) leaves it to this part. Only widget
	state is touched; no Lua field is written on Blizzard's frames. Nothing
	here is protected. Applied once at login with the Character Window option.
]]

local _, ns = ...
if not ns.IS_FOREVER then return end
local T = ns.T
local Point = ns.Point
local CW = ns.CharacterWindow

local module = ns:RegisterModule({
	key = "characterinspect",
	name = "Character Window: Inspect",
	parent = "characterframe",
	live = false,
})

-- Window Frames draws its frame on the inspect window unless this part does.
ns.windowOwners.InspectFrame = function()
	return ns:IsEnabled("characterframe")
end

-- The model over the whole dark page, from under the band down to the
-- weapon row (1.12 had no stat boxes on the inspect page); Blizzard's View
-- button in the band, under the level line.
local MODEL_HEIGHT = 300
local BUTTON_Y = -53
local FACTION_SIZE = 200

local LEFT_SLOTS = { "InspectHeadSlot", "InspectNeckSlot", "InspectShoulderSlot", "InspectBackSlot",
	"InspectChestSlot", "InspectShirtSlot", "InspectTabardSlot", "InspectWristSlot" }
local RIGHT_SLOTS = { "InspectHandsSlot", "InspectWaistSlot", "InspectLegsSlot", "InspectFeetSlot",
	"InspectFinger0Slot", "InspectFinger1Slot", "InspectTrinket0Slot", "InspectTrinket1Slot" }
local WEAPON_SLOTS = { "InspectMainHandSlot", "InspectSecondaryHandSlot", "InspectRangedSlot" }

local frame               -- InspectFrame
local origin              -- the vanilla art's top-left corner (ns.ArtOrigin)
local paperdollArt, generalArt = {}, {}
local portrait

local function Fade(region)
	if region then region:SetAlpha(0) end
end

-- Fades a frame's own textures (not its children's).
local function FadeRegions(owner)
	for _, region in ipairs({ owner:GetRegions() }) do
		if region:IsObjectType("Texture") then region:SetAlpha(0) end
	end
end

---------------------------------------------------------------------------
-- Frame art
---------------------------------------------------------------------------

local function UpdateArt()
	local paperdoll = InspectPaperDollFrame:IsShown()
	for _, texture in ipairs(paperdollArt) do texture:SetShown(paperdoll) end
	for _, texture in ipairs(generalArt) do texture:SetShown(not paperdoll) end
end

-- The inspected player's portrait under the art's ring (Blizzard's own
-- portrait is faded); Blizzard sets it with SetPortraitToUnit on every
-- open and unit change.
local function UpdatePortrait(unit)
	unit = unit or frame.unit
	if unit then SetPortraitTexture(portrait, unit) end
end

local function SkinChrome()
	origin = ns.ArtOrigin(frame)
	FadeRegions(frame)
	Fade(frame.NineSlice)
	Fade(frame.Inset)
	if frame.PortraitContainer then Fade(frame.PortraitContainer.portrait) end

	CW.CreateArt(paperdollArt, { T.CHARACTER_TAB_ART .. "L1", T.CHARACTER_TAB_ART .. "R1",
		T.CHARACTER_TAB_ART .. "BottomLeft", T.CHARACTER_TAB_ART .. "BottomRight" }, 0, 0, frame, origin)
	-- Drawn 2px right and 1px down, as the character window's other pages.
	CW.CreateArt(generalArt, { T.CHARACTER_GENERAL .. "TopLeft", T.CHARACTER_GENERAL .. "TopRight",
		T.CHARACTER_GENERAL .. "BottomLeft", T.CHARACTER_GENERAL .. "BottomRight" }, 2, -1, frame, origin)
	UpdateArt()

	portrait = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
	portrait:SetSize(CW.PORTRAIT_SIZE, CW.PORTRAIT_SIZE)
	portrait:SetPoint("TOPLEFT", origin, "TOPLEFT", CW.PORTRAIT_X, CW.PORTRAIT_Y)

	local title = frame.TitleContainer
	if title then
		title:ClearAllPoints()
		title:SetPoint("TOPLEFT", origin, "TOPLEFT", CW.TITLE_LEFT, CW.TITLE_Y)
		title:SetPoint("TOPRIGHT", origin, "TOPLEFT", CW.TITLE_RIGHT, CW.TITLE_Y)
	end

	local close = frame.CloseButton
	if close then
		ns.SkinCloseButton(close)
		Point(close, "CENTER", origin, "TOPLEFT", CW.CLOSE_X, CW.CLOSE_Y)
	end

	InspectPaperDollFrame:HookScript("OnShow", UpdateArt)
	InspectPaperDollFrame:HookScript("OnHide", UpdateArt)
	frame:HookScript("OnShow", function()
		UpdateArt()
		UpdatePortrait()
	end)
	ns.Hook(frame, "SetPortraitToUnit", function(_, unit) UpdatePortrait(unit) end)
	frame:HookScript("OnEvent", function(_, event, unit)
		if event == "PORTRAITS_UPDATED" or (event == "UNIT_PORTRAIT_UPDATE" and unit == frame.unit) then
			UpdatePortrait()
		end
	end)
end

-- The frame and its pages (the guild page takes the mouse and spans the
-- frame) take the mouse over the art: its right edge is see-through and it
-- runs past the frame's bottom down to the tab shelf.
local function SetHitRects()
	local insets = { ns.ArtHitRectInsets(frame, 0, origin:GetWidth() - CW.HIT_WIDTH, 0, origin:GetHeight() - CW.HIT_HEIGHT) }
	frame:SetHitRectInsets(unpack(insets))
	for _, page in ipairs({ InspectPaperDollFrame, InspectGuildFrame }) do
		if page and page.SetHitRectInsets then
			page:SetHitRectInsets(unpack(insets))
		end
	end
end

---------------------------------------------------------------------------
-- Paperdoll: slots, model, level line
---------------------------------------------------------------------------

local function PlaceSlots()
	for index, name in ipairs(LEFT_SLOTS) do
		local slot = _G[name]
		if slot then
			CW.SkinSlot(slot)
			Point(slot, "TOPLEFT", origin, "TOPLEFT", CW.SLOT_LEFT_X, CW.SLOT_Y - (index - 1) * CW.SLOT_STRIDE)
		end
	end
	for index, name in ipairs(RIGHT_SLOTS) do
		local slot = _G[name]
		if slot then
			CW.SkinSlot(slot)
			Point(slot, "TOPLEFT", origin, "TOPLEFT", CW.SLOT_RIGHT_X, CW.SLOT_Y - (index - 1) * CW.SLOT_STRIDE)
		end
	end
	-- Without a ranged slot the other two are centred on the three sockets.
	local x = CW.WEAPON_X + (InspectRangedSlot and 0 or CW.WEAPON_STRIDE / 2)
	for index, name in ipairs(WEAPON_SLOTS) do
		local slot = _G[name]
		if slot then
			CW.SkinSlot(slot)
			Point(slot, "TOPLEFT", origin, "TOPLEFT", x + (index - 1) * CW.WEAPON_STRIDE, CW.WEAPON_Y)
		end
	end
end

local function PlaceModel()
	local model = InspectModelFrame
	Point(model, "TOPLEFT", origin, "TOPLEFT", CW.MODEL_X, CW.MODEL_Y)
	model:SetSize(CW.MODEL_WIDTH, MODEL_HEIGHT)
	-- The race backgrounds, their black overlay and Blizzard's inner border
	-- round the page: vanilla drew the model on the art's dark page.
	FadeRegions(model)
	-- The faction logo Blizzard shows instead of an out-of-range player's
	-- model, in the middle of the page.
	if InspectFaction then
		InspectFaction:SetSize(FACTION_SIZE, FACTION_SIZE)
		Point(InspectFaction, "CENTER", origin, "TOPLEFT", CW.MODEL_X + CW.MODEL_WIDTH / 2, CW.MODEL_Y - MODEL_HEIGHT / 2)
	end
end

local function PlaceLines()
	local page = InspectPaperDollFrame
	local center = (CW.TITLE_LEFT + CW.TITLE_RIGHT) / 2
	if page.LevelTextWrapper then
		Point(page.LevelTextWrapper, "TOP", origin, "TOPLEFT", center, CW.LEVEL_Y)
	end
	-- 1.12's small level line (Blizzard's is in a large outlined font).
	if InspectLevelText then InspectLevelText:SetFontObject(GameFontNormalSmall) end
	if page.ViewButton then
		Point(page.ViewButton, "TOP", origin, "TOPLEFT", center, BUTTON_Y)
	end
end

---------------------------------------------------------------------------
-- Tabs
---------------------------------------------------------------------------

-- Blizzard lays the tabs out in InspectFrame_Show (UpdateTabLayout) and
-- shows or hides the guild tab once the inspect data is in (UpdateTabs).
local function LayoutTabs()
	CW.LayoutModeTabs(frame, origin)
end

---------------------------------------------------------------------------
-- Module
---------------------------------------------------------------------------

local function Skin()
	frame = InspectFrame
	if not (frame and frame.ModeTabs and InspectPaperDollFrame and InspectModelFrame) then return end
	SkinChrome()
	PlaceSlots()
	PlaceModel()
	PlaceLines()
	ns.Hook(frame, "UpdateTabLayout", LayoutTabs)
	ns.Hook(frame, "UpdateTabs", LayoutTabs)
	frame:HookScript("OnShow", LayoutTabs)
	LayoutTabs()
	SetHitRects()
	CW.SetUpController(frame, origin)
end

function module:Apply()
	-- Only with the vanilla character window (CharacterFrame.lua, applied
	-- before this part).
	if not ns.characterWindowSkinned or not CW then return end
	if InspectFrame then
		Skin()
		return
	end
	local watcher = CreateFrame("Frame")
	watcher:RegisterEvent("ADDON_LOADED")
	watcher:SetScript("OnEvent", function(self, _, name)
		if name == "Blizzard_InspectUI" then
			self:UnregisterAllEvents()
			xpcall(Skin, geterrorhandler())
		end
	end)
end
