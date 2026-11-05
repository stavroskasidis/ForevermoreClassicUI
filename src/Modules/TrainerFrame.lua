--[[
	Forevermore Classic UI - Trainer Window

	Restores the vanilla class / profession trainer window (1.12
	Blizzard_TrainerUI.xml): the 384x512 panel assembled from the four
	Interface\ClassTrainerFrame\UI-ClassTrainer-* pieces with the trainer's
	portrait in its ring, the trainer's greeting under the name, a compact
	list of 16px skill rows coloured by state (green available, red
	unavailable, grey already known) with the selected row on a tinted
	highlight bar, a detail pane under the list with the selected skill's
	icon, name, requirements, cost and description, the Train / Exit buttons
	and the player's money at the bottom, the filter in the classic dropdown
	box and the classic knob scroll bars.

	Retail's ClassTrainerFrame (Blizzard_TrainerUI, load-on-demand) is a
	ButtonFrameTemplate whose ScrollBox lists 47px card rows
	(ClassTrainerSkillButtonTemplate: icon, name, requirements, price) with a
	tooltip on hover and no detail pane; a filter dropdown and, for
	professions, a skill rank bar sit in its header. The frame is re-skinned
	in place so that Blizzard's selection, training, filters, tooltips and
	the profession "next rank" step button keep working:

	  * the panel's NineSlice, backgrounds and insets are hidden and the
	    vanilla art is drawn on the frame; the title, portrait, close button,
	    Train button, money frame, filter dropdown and rank bar are moved to
	    their vanilla spots (the portrait container is dropped to the LOW
	    strata so the portrait shows through the ring's hole like vanilla),
	  * the rows keep Blizzard's name text (re-anchored and coloured by
	    service type) and get the vanilla highlight bar; their icon, price,
	    requirement text and card textures are faded out. The list is
	    scaled down (listScale) so Blizzard's 47px rows stack as the vanilla
	    16px ones, the rows' text enlarged back. The view's extents and
	    padding are never set: they are Lua state every layout reads, and
	    on Forever a row click selects through the row's displayIndex field
	    that layout writes, which the Train button hands to the protected
	    BuyTrainerService (pet training was blocked, 2026-09-29). The
	    MinimalScrollBar is re-skinned into the classic knob bar,
	  * ClassTrainerFrame_Update (which re-anchors the ScrollBox every time)
	    and ClassTrainer_SetSelection are hooked to lay the list out and to
	    fill the addon's own detail pane. The description comes from the
	    service's tooltip data (C_TooltipInfo.GetTrainerService) when the
	    vanilla GetTrainerServiceDescription is not available.

	Two client layouts are handled (structural, not by flavor): on retail
	the ScrollBox is a linear list that also contains the profession step
	service, so the pinned step button is hidden; on WoW Forever the list is
	a tree with collapsible category headers (re-skinned into the vanilla
	+/- header rows) and the step service is only on the pinned button,
	which becomes the list's first row.

	Everything touched is widget state; no Lua field is written on
	Blizzard's frames. Applied once at login (reload to switch off).
]]

local _, ns = ...
local T = ns.T
local Point, SetTexture = ns.Point, ns.SetTexture

T.TRAINER_ART        = "Interface\\ClassTrainerFrame\\UI-ClassTrainer-" -- + TopLeft / TopRight / BotLeft / BotRight / HorizontalBar / ScrollBar
T.TRADESKILL_ART     = "Interface\\TradeSkillFrame\\UI-TradeSkill-"     -- same pieces (the classic trade skill panel), fallback
T.LISTBOX_HIGHLIGHT  = "Interface\\Buttons\\UI-Listbox-Highlight2"
T.LISTBOX_HIGHLIGHT1 = "Interface\\Buttons\\UI-Listbox-Highlight"
T.PLUS_BUTTON        = "Interface\\Buttons\\UI-PlusButton-"  -- + Up / Down / Hilight
T.MINUS_BUTTON       = "Interface\\Buttons\\UI-MinusButton-" -- + Up / Down
T.PLUS_HILIGHT       = "Interface\\Buttons\\UI-PlusButton-Hilight"
T.EMPTY_SLOT         = "Interface\\Buttons\\UI-EmptySlot"

local module = ns:RegisterModule({
	key = "trainer",
	name = "Trainer Window",
	tooltip = "Restores the vanilla class / profession trainer window: the classic panel with the trainer's greeting, the compact colour-coded skill list, the selected skill's details below it and the Train / Exit buttons.",
	live = false,
})

-- Vanilla geometry (1.12 Blizzard_TrainerUI.xml). The frame is 384x512 with
-- transparent art in its right 34px and bottom 75px.
local FRAME_WIDTH, FRAME_HEIGHT = 384, 512
local ROW_HEIGHT = 16
local LIST_LEFT, LIST_TOP, LIST_WIDTH = 21, -96, 296 -- ClassTrainerListScrollFrame
local ROW_LEFT, ROW_WIDTH = 22, 294                   -- the rows sit 1px in and 4px down from it
local LIST_HEIGHT_CLASS, LIST_HEIGHT_TRADE = 184, 168 -- 11 / 10 rows
local DETAIL_HEIGHT_CLASS, DETAIL_HEIGHT_TRADE = 119, 135
local SKILL_TEXT_WIDTH = 266                          -- vanilla: 270, minus the tree indent on Forever
local BLIZZARD_ROW_HEIGHT = 47                        -- CLASS_TRAINER_SKILL_HEIGHT, the fallback
local DROPDOWN_WIDTH = 130                            -- UIDropDownMenu_SetWidth(130); the box adds 25px each side

-- 1.12 colours: GameFontNormalLeftGreen / GameFontNormalLeftRed /
-- GameFontDisable for the names, ClassTrainer_SetSubTextColor for the
-- "(Rank n)" text and the ClassTrainerSkillHighlight vertex colour.
local TYPE_COLORS = {
	available   = { text = { 0.1, 1, 0.1 },     sub = { 0, 0.6, 0 },       bar = { 0, 1, 0 } },
	unavailable = { text = { 1, 0.1, 0.1 },     sub = { 0.6, 0, 0 },       bar = { 0.9, 0, 0 } },
	used        = { text = { 0.5, 0.5, 0.5 },   sub = { 0.5, 0.5, 0.5 },   bar = { 0.5, 0.5, 0.5 } },
}

local art = {}                                       -- regions/frames created by this module
local origin                                         -- the vanilla art's top-left corner (ns.ArtOrigin), which everything is placed from
local rows = setmetatable({}, { __mode = "k" })      -- skill row -> { bar = highlight texture }
local headers = setmetatable({}, { __mode = "k" })   -- category row -> { icon = +/- texture }
local artPrefix                                      -- T.TRAINER_ART or T.TRADESKILL_ART, whichever this client ships
local listScale = 1                                  -- the ScrollBox's scale: Blizzard's row height -> ROW_HEIGHT
local highlightFile

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

-- The list's element data is a plain table on retail and a tree node (whose
-- .data holds that table) on Forever.
local function SkillIndexOf(elementData)
	local data = elementData and (elementData.data or elementData)
	return type(data) == "table" and data.skillIndex or nil
end

-- The profession "next rank" service (GetTrainerServiceStepIndex) is shown
-- on Blizzard's pinned skillStepButton. Retail lists it as well, so the pin
-- is redundant there; Forever leaves it out of the list, so the pin becomes
-- the list's first row.
local function IsStepPinned()
	local step = GetTrainerServiceStepIndex()
	if not step then return false end
	local scrollBox = ClassTrainerFrame.ScrollBox
	if not scrollBox:HasDataProvider() then return true end
	local function IsStep(elementData)
		return SkillIndexOf(elementData) == step
	end
	if scrollBox.ContainsElementDataByPredicate then
		return not scrollBox:ContainsElementDataByPredicate(IsStep)
	end
	return scrollBox:FindElementDataByPredicate(IsStep) == nil
end

-- The selected service's skill index. Retail keeps it in selectedService;
-- Forever sorts the list and keeps a display index there instead (the step
-- service is display index 0), mapped back through displayIndexToSkillIndex
-- like Blizzard's ClassTrainer_GetSkillIndexForDisplayIndex.
local function SelectedSkillIndex()
	local frame = ClassTrainerFrame
	local selected = frame.selectedService
	if not selected then return nil end
	local map = frame.displayIndexToSkillIndex
	return map and map[selected] or selected
end

local function IsPetTrainer()
	return C_Trainer ~= nil and C_Trainer.GetTrainerType ~= nil and Enum.TrainerType ~= nil
		and C_Trainer.GetTrainerType() == Enum.TrainerType.Pet
end

-- The rows and headers in the ScrollBox are drawn at listScale, so their
-- offsets and fonts are divided by it; the pinned step button is not.
local function RowScale(row)
	return row == ClassTrainerFrame.skillStepButton and 1 or listScale
end

-- Enlarges a font string's current font by 1 / scale. The shadow offset
-- keeps its size: it does not shrink with the list's scale (enlarged, the
-- shadow showed as a ghost copy of the text).
local function ScaleFont(fontString, scale)
	local font, size, flags = fontString:GetFont()
	if font then
		fontString:SetFont(font, size / scale, flags or "")
	end
	fontString:SetHeight(0) -- the template's fixed height would clip the enlarged text
end

local function ResolveArtPrefix()
	for _, prefix in ipairs({ T.TRAINER_ART, T.TRADESKILL_ART }) do
		if ns.HasTexture(prefix .. "TopLeft") and ns.HasTexture(prefix .. "BotRight") then
			return prefix
		end
	end
end

---------------------------------------------------------------------------
-- Frame art
---------------------------------------------------------------------------

local function ApplyFrameArt(frame)
	frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	origin = ns.ArtOrigin(frame, FRAME_WIDTH, FRAME_HEIGHT)
	ns.SetArtHitRect(frame, 0, 34, 0, 75)
	-- The controller UI's focus glow and button prompts go round the art.
	ns.SetGamepadBox(frame, ns.CreateArtBox(frame, origin, FRAME_WIDTH - 34, FRAME_HEIGHT - 75))

	if frame.NineSlice then frame.NineSlice:Hide() end
	if frame.Bg then frame.Bg:Hide() end
	if frame.TopTileStreaks then frame.TopTileStreaks:Hide() end
	if frame.BG then frame.BG:Hide() end -- the TrainerTextures list background
	-- Blizzard's Update re-anchors the inset and shows the bottom one; alpha survives that.
	if frame.Inset then frame.Inset:SetAlpha(0) end
	if frame.bottomInset then frame.bottomInset:SetAlpha(0) end
	if ClassTrainerFrameMoneyBg then ClassTrainerFrameMoneyBg:Hide() end

	local function Piece(name, width, height, point)
		local texture = frame:CreateTexture(nil, "BORDER")
		texture:SetTexture(artPrefix .. name)
		texture:SetSize(width, height)
		texture:SetPoint(point, origin, point, 0, 0)
		return texture
	end
	art.topLeft = Piece("TopLeft", 256, 256, "TOPLEFT")
	art.topRight = Piece("TopRight", 128, 256, "TOPRIGHT")
	art.bottomLeft = Piece("BotLeft", 256, 256, "BOTTOMLEFT")
	art.bottomRight = Piece("BotRight", 128, 256, "BOTTOMRIGHT")

	-- The bar between the list and the detail pane; anchored in LayoutFrame.
	if ns.HasTexture(artPrefix .. "HorizontalBar") then
		art.barLeft = frame:CreateTexture(nil, "ARTWORK")
		SetTexture(art.barLeft, artPrefix .. "HorizontalBar", 0, 1, 0, 0.25)
		art.barLeft:SetSize(256, 16)
		art.barRight = frame:CreateTexture(nil, "ARTWORK")
		SetTexture(art.barRight, artPrefix .. "HorizontalBar", 0, 0.29296875, 0.25, 0.5)
		art.barRight:SetSize(75, 16)
		art.barRight:SetPoint("LEFT", art.barLeft, "RIGHT", 0, 0)
	end

	-- Vanilla drew the square portrait on the BACKGROUND layer and let the
	-- ring in the frame art cut it round. Retail's portrait lives in a child
	-- frame (drawn above the frame's own art) with a circle mask; the
	-- container is dropped below the frame's strata instead, so the art's
	-- hole does the masking again.
	local container = frame.PortraitContainer
	local portrait = container and container.portrait or ClassTrainerFramePortrait
	if portrait then
		portrait:SetSize(60, 60)
		Point(portrait, "TOPLEFT", origin, "TOPLEFT", 7, -6)
		if container then
			container:SetFrameStrata("LOW")
			ns.StripMask(container.CircleMask, portrait)
		end
	end

	local title = frame.TitleContainer and frame.TitleContainer.TitleText
	if title then
		Point(title, "TOP", origin, "TOP", 0, -17)
	end

	-- The greeting API went away with the Cataclysm trainer; shown when present.
	if GetTrainerGreetingText then
		art.greeting = frame:CreateFontString(nil, "BORDER", "GameFontHighlight")
		art.greeting:SetSize(260, 30)
		art.greeting:SetJustifyH("LEFT")
		art.greeting:SetJustifyV("TOP")
		art.greeting:SetPoint("TOPLEFT", origin, "TOPLEFT", 76, -38)
	end

	local close = frame.CloseButton
	if close then
		ns.SkinCloseButton(close)
		Point(close, "TOPRIGHT", origin, "TOPRIGHT", -29, -8)
	end

	local train = ClassTrainerTrainButton or frame.TrainButton
	if train then
		train:SetSize(80, 22)
		Point(train, "CENTER", origin, "TOPLEFT", 224, -420)
	end
	art.exit = ns.CreatePanelCloseTextButton(frame, EXIT or "Exit")
	art.exit:SetPoint("CENTER", origin, "TOPLEFT", 305, -420)

	local money = frame.money or ClassTrainerFrameMoneyFrame
	if money then
		Point(money, "BOTTOMRIGHT", origin, "BOTTOMLEFT", 180, 86)
	end
	-- Forever's pet trainer shows training points in place of the money.
	if frame.trainingPoints then
		Point(frame.trainingPoints, "BOTTOMLEFT", origin, "BOTTOMLEFT", 28, 84)
	end

	-- The profession rank bar goes where vanilla had its "All" collapse tab
	-- (retail has no headers to collapse).
	if ClassTrainerStatusBar then
		Point(ClassTrainerStatusBar, "TOPLEFT", origin, "TOPLEFT", 24, -75)
	end
end

-- Retail's filter is a WowStyle1FilterDropdownTemplate button (an atlas
-- swapped by its mixin on every state change, sized to its text on every
-- update); it gets the classic dropdown box (ns.SkinDropdownBox).
local function SkinFilterDropdown(frame)
	local dropdown = frame.FilterDropdown
	if not dropdown then return end
	Point(dropdown, "TOPRIGHT", origin, "TOPRIGHT", -26, -64)
	ns.SkinDropdownBox(dropdown, DROPDOWN_WIDTH)
end

---------------------------------------------------------------------------
-- Scroll bars
---------------------------------------------------------------------------

-- The scroll trough art (UI-ClassTrainer-ScrollBar) that vanilla drew behind
-- both scroll bars: a top and a bottom piece that overlap in the middle.
-- Returns the two textures (on `parent`) for the caller to anchor; the
-- professions window (ProfessionsFrame.lua) uses it too.
function ns.CreateScrollTrough(parent, file, topInset)
	if not ns.HasTexture(file) then return end
	local top = parent:CreateTexture(nil, "ARTWORK")
	SetTexture(top, file, 0, 0.46875, topInset, 0.9609375)
	top:SetSize(30, 123 * (0.9609375 - topInset) / 0.9609375)
	local bottom = parent:CreateTexture(nil, "ARTWORK")
	SetTexture(bottom, file, 0.53125, 1, 0.03125, 1)
	bottom:SetSize(30, 123)
	return top, bottom
end

local function CreateTrough(frame, topInset)
	return ns.CreateScrollTrough(frame, artPrefix .. "ScrollBar", topInset)
end

---------------------------------------------------------------------------
-- Skill rows
---------------------------------------------------------------------------

-- Name / sub text colours: white while hovered or selected (the vanilla
-- button's highlight font), the service type's colour otherwise; the
-- highlight bar is shown under the selected row. Blizzard's Init shows the
-- (faded) selectedTex on the selected row, which works with both the skill
-- and the display index selection.
local function ColorRow(row, hovered)
	local state = rows[row]
	if not state then return end
	local id = row:GetID()
	local _, serviceType = GetTrainerServiceInfo(id)
	local colors = TYPE_COLORS[serviceType] or TYPE_COLORS.available
	local selected
	if row.selectedTex then
		selected = row.selectedTex:IsShown()
	else
		selected = SelectedSkillIndex() == id
	end
	if hovered or selected then
		row.name:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
		if row.nameSubText then row.nameSubText:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB()) end
	else
		row.name:SetTextColor(unpack(colors.text))
		if row.nameSubText then row.nameSubText:SetTextColor(unpack(colors.sub)) end
	end
	state.bar:SetVertexColor(unpack(colors.bar))
	state.bar:SetShown(selected)
end

-- Vanilla row (ClassTrainerSkillButtonTemplate): 293x16, the name 21px in,
-- the "(Rank n)" sub text 10px after it. Blizzard's Init only sets texts,
-- so the anchors and fonts are set once here; what Init touches is fixed in
-- OnRowInit.
local function SkinRow(row)
	local state = { bar = row:CreateTexture(nil, "BACKGROUND") }
	rows[row] = state
	local scale = RowScale(row)

	for _, key in ipairs({ "icon", "subText", "selectedTex", "disabledBG", "lock", "money", "alternateCost" }) do
		if row[key] then row[key]:SetAlpha(0) end -- Init shows some of these again; alpha survives that
	end
	local normal, highlight = row:GetNormalTexture(), row:GetHighlightTexture()
	if normal then normal:SetAlpha(0) end
	if highlight then highlight:SetAlpha(0) end

	SetTexture(state.bar, highlightFile)
	state.bar:SetAllPoints(row)
	state.bar:Hide()

	if row.name then
		row.name:SetWordWrap(false)
		row.name:SetJustifyH("LEFT")
		ScaleFont(row.name, scale)
		Point(row.name, "LEFT", row, "LEFT", 21 / scale, 1 / scale)
	end
	if row.nameSubText and row.name then
		row.nameSubText:SetJustifyH("LEFT")
		ScaleFont(row.nameSubText, scale)
		Point(row.nameSubText, "LEFT", row.name, "RIGHT", 10 / scale, 0)
	end

	row:HookScript("OnEnter", function(self) ColorRow(self, true) end)
	row:HookScript("OnLeave", function(self) ColorRow(self, false) end)
end

-- After Blizzard's ClassTrainerFrame_InitServiceButton (rows and the step button).
local function OnRowInit(row)
	if not row.name then return end
	if not rows[row] then SkinRow(row) end

	if row == ClassTrainerFrame.skillStepButton and not IsStepPinned() then
		row:Hide()
		return
	end

	-- Vanilla let the name run free when a sub text followed it and capped
	-- it (no wrap, so it truncates) otherwise.
	local sub = row.nameSubText and row.nameSubText:GetText()
	local hasSub = sub ~= nil and sub ~= ""
	row.name:SetWidth(hasSub and 0 or SKILL_TEXT_WIDTH / RowScale(row))
	-- Forever's Init ends in UpdateNameWidth, which fixes the sub text's width
	-- to what it measures (hiding it when it does not fit beside the price):
	-- on a row's first Init that measure is in the template's font, before
	-- SkinRow enlarged it, so "(Rank 2)" showed as "(..." until the next Init.
	-- The sub text fits its text here instead, like the name above.
	if row.nameSubText then
		row.nameSubText:SetWidth(0)
		row.nameSubText:SetShown(hasSub)
	end
	ColorRow(row, row:IsMouseOver())
end

-- Forever's category headers (TrainerUICategoryTemplate): the atlas pieces
-- and collapse arrow are faded and the vanilla +/- box drawn in their place.
-- Blizzard re-sets the header's scripts on every Init (they swap the
-- label's font object), so the font hooks are re-added each time; the +/-
-- follows the CollapseIcon atlas Blizzard swaps when the category is
-- toggled. The header is Blizzard's 25 list units high (about half a
-- vanilla row, and it cannot be made taller without tainting the list), so
-- its label is in the small font (the normal one crowded the rows around
-- it), and the label and +/- sit HEADER_RISE above its middle, where the
-- text sat low against the recipe row under it (measured in game,
-- 2026-09-29).
-- The size comes from the font object, not the label: SetFontObject with
-- the object the label already has leaves the enlarged font in place, so
-- scaling the label's own font again on every Init or hover made the header
-- text grow each time.
local HEADER_RISE = 2

local function SetHeaderFont(label, hovered)
	local fontObject = hovered and GameFontHighlightSmall or GameFontNormalSmall
	label:SetFontObject(fontObject)
	local font, size, flags = fontObject:GetFont()
	if font then
		label:SetFont(font, size / listScale, flags or "")
	end
	label:SetHeight(0) -- the template's fixed height would clip the enlarged text
end

local function OnCategoryInit(button, node)
	local state = headers[button]
	if not state then
		local size = 16 / listScale
		state = { icon = button:CreateTexture(nil, "ARTWORK") }
		headers[button] = state
		for _, key in ipairs({ "LeftPiece", "RightPiece", "CenterPiece", "CollapseIcon", "CollapseIconAlphaAdd" }) do
			if button[key] then button[key]:SetAlpha(0) end
		end
		state.icon:SetSize(size, size)
		state.icon:SetPoint("LEFT", button, "LEFT", 3 / listScale, HEADER_RISE / listScale)
		if button.Label then
			Point(button.Label, "LEFT", button, "LEFT", 21 / listScale, HEADER_RISE / listScale)
		end
		if ns.HasTexture(T.PLUS_HILIGHT) then
			button:SetHighlightTexture(T.PLUS_HILIGHT, "ADD")
			local highlight = button:GetHighlightTexture()
			if highlight then
				highlight:ClearAllPoints()
				highlight:SetSize(size, size)
				highlight:SetPoint("LEFT", button, "LEFT", 3 / listScale, HEADER_RISE / listScale)
			end
		end
		if button.CollapseIcon then
			ns.Hook(button.CollapseIcon, "SetAtlas", function(_, atlas)
				SetTexture(state.icon, ((type(atlas) == "string" and atlas:find("expand")) and T.PLUS_BUTTON or T.MINUS_BUTTON) .. "Up")
			end)
		end
	end

	local collapsed = node and node.IsCollapsed and node:IsCollapsed()
	SetTexture(state.icon, (collapsed and T.PLUS_BUTTON or T.MINUS_BUTTON) .. "Up")
	if button.Label then
		SetHeaderFont(button.Label, false)
		button:HookScript("OnEnter", function(self) SetHeaderFont(self.Label, true) end)
		button:HookScript("OnLeave", function(self) SetHeaderFont(self.Label, false) end)
	end
end

---------------------------------------------------------------------------
-- Detail pane (vanilla ClassTrainerDetailScrollFrame)
---------------------------------------------------------------------------

local function CreateDetailPane(frame)
	-- UIPanelScrollFrameTemplate is the classic knob scroll frame; with
	-- scrollBarHideable the bar only appears when the text overflows.
	local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scroll:SetSize(LIST_WIDTH, DETAIL_HEIGHT_CLASS)
	scroll.scrollBarHideable = 1
	if scroll.ScrollBar then
		scroll.ScrollBar:Hide() -- the template's OnLoad ran before scrollBarHideable was set
	end
	art.detail = scroll

	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(LIST_WIDTH, 50)
	scroll:SetScrollChild(child)
	art.detailChild = child

	local icon = CreateFrame("Button", nil, child)
	icon:SetSize(37, 37)
	icon:SetPoint("TOPLEFT", child, "TOPLEFT", 5, -4)
	local slot = icon:CreateTexture(nil, "BACKGROUND")
	slot:SetTexture(T.EMPTY_SLOT)
	slot:SetSize(64, 64)
	slot:SetPoint("TOPLEFT", icon, "TOPLEFT", -13, 13)
	icon:SetScript("OnEnter", function(self)
		local id = SelectedSkillIndex()
		if not id then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetTrainerService(id)
		GameTooltip:Show()
	end)
	icon:SetScript("OnLeave", GameTooltip_Hide)
	icon:SetScript("OnClick", function()
		local id = SelectedSkillIndex()
		if id and GetTrainerServiceItemLink then
			HandleModifiedItemClick(GetTrainerServiceItemLink(id))
		end
	end)
	art.icon = icon

	art.name = child:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	art.name:SetJustifyH("LEFT")
	art.name:SetWordWrap(false)
	art.name:SetPoint("TOPLEFT", child, "TOPLEFT", 46, -2)

	art.subName = child:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	art.subName:SetJustifyH("LEFT")
	art.subName:SetPoint("LEFT", art.name, "RIGHT", 5, 0)

	art.requirements = child:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	art.requirements:SetWidth(244)
	art.requirements:SetJustifyH("LEFT")
	art.requirements:SetPoint("TOPLEFT", art.name, "BOTTOMLEFT", 0, 0)

	art.costLabel = child:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
	art.costLabel:SetJustifyH("LEFT")
	art.costLabel:SetText(COSTS_LABEL or "Costs:")
	art.costLabel:SetPoint("TOPLEFT", child, "TOPLEFT", 5, -50)

	art.money = CreateFrame("Frame", nil, child, "SmallMoneyFrameTemplate")
	art.money:SetPoint("LEFT", art.costLabel, "RIGHT", 5, 0)
	MoneyFrame_SetType(art.money, "STATIC")
	MoneyFrame_SetMaxDisplayWidth(art.money, 100)

	art.pointsCost = child:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	art.pointsCost:SetJustifyH("LEFT")
	art.pointsCost:SetPoint("LEFT", art.costLabel, "RIGHT", 5, 0)

	art.description = child:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	art.description:SetWidth(290)
	art.description:SetJustifyH("LEFT")
	art.description:SetJustifyV("TOP")
	art.description:SetPoint("TOPLEFT", art.costLabel, "BOTTOMLEFT", 0, -10)
end

-- Mirrors the requirement text ClassTrainerFrame_InitServiceButton builds
-- for the (now hidden) row sub text.
local function BuildRequirements(id, serviceType, reqLevel, unit)
	if serviceType == "used" then
		return ITEM_SPELL_KNOWN
	end
	local parts = {}
	if reqLevel and reqLevel > 1 then
		local met = UnitLevel(unit) >= reqLevel
		table.insert(parts, format(met and TRAINER_REQ_LEVEL or TRAINER_REQ_LEVEL_RED, reqLevel))
	end
	local skill, rank, hasSkill = GetTrainerServiceSkillReq(id)
	if skill then
		table.insert(parts, format(hasSkill and TRAINER_REQ_SKILL_RANK or TRAINER_REQ_SKILL_RANK_RED, skill, rank))
	end
	for i = 1, GetTrainerServiceNumAbilityReq(id) or 0 do
		local ability, hasAbility = GetTrainerServiceAbilityReq(id, i)
		if ability then
			table.insert(parts, format(hasAbility and TRAINER_REQ_ABILITY or TRAINER_REQ_ABILITY_RED, ability))
		end
	end
	if #parts == 0 then
		return ""
	end
	return REQUIRES_LABEL .. " " .. table.concat(parts, PLAYER_LIST_DELIMITER)
end

local function GetTooltipLines(id)
	if not (C_TooltipInfo and C_TooltipInfo.GetTrainerService) then return end
	local data = C_TooltipInfo.GetTrainerService(id)
	local lines = data and data.lines
	if not lines then return end
	-- Pre-10.1 tooltip data needs its arguments surfaced first.
	if lines[1] and lines[1].leftText == nil and TooltipUtil and TooltipUtil.SurfaceArgs then
		TooltipUtil.SurfaceArgs(data)
		for _, line in ipairs(lines) do
			TooltipUtil.SurfaceArgs(line)
		end
	end
	return lines
end

local function IsWhite(color)
	return color.r == nil or (color.r > 0.99 and color.g > 0.99 and color.b > 0.99)
end

-- The description text and, when known, the service's sub text ("Rank 2").
-- Vanilla's GetTrainerServiceDescription is used when the client has it;
-- otherwise the service tooltip's lines after the name are shown.
local function GetDescription(id)
	if GetTrainerServiceDescription then
		local text = GetTrainerServiceDescription(id)
		if text and text ~= "" then
			return text
		end
	end
	local lines = GetTooltipLines(id)
	if not lines then return "" end
	local out = {}
	for i = 2, #lines do
		local line = lines[i]
		local text = line.leftText
		if text and text ~= "" then
			if line.rightText and line.rightText ~= "" then
				text = text .. "  " .. line.rightText
			end
			local color = line.leftColor
			if type(color) == "table" and color.WrapTextInColorCode and not IsWhite(color) then
				text = color:WrapTextInColorCode(text)
			end
			table.insert(out, text)
		end
	end
	return table.concat(out, "\n"), lines[1] and lines[1].rightText
end

local function HideDetails()
	for _, key in ipairs({ "icon", "name", "subName", "requirements", "costLabel", "money", "pointsCost", "description" }) do
		art[key]:Hide()
	end
end

local function UpdateDetails()
	local frame = ClassTrainerFrame
	if not art.detail or not frame:IsShown() then return end

	local id = SelectedSkillIndex()
	local name, serviceType, texture, reqLevel, subText
	if id then
		name, serviceType, texture, reqLevel, subText = GetTrainerServiceInfo(id)
	end
	if not name then
		HideDetails()
		return
	end

	local isPet = IsPetTrainer()
	local description, tooltipSubText = GetDescription(id)
	if not subText or subText == "" then
		subText = tooltipSubText
	end

	if texture then
		art.icon:SetNormalTexture(texture)
	else
		art.icon:ClearNormalTexture()
	end
	art.name:SetText(name)
	art.name:SetWidth(0) -- fit the text so the sub text follows it; vanilla's 244px cap otherwise
	if art.name:GetStringWidth() > 244 then
		art.name:SetWidth(244)
	end
	if subText and subText ~= "" then
		art.subName:SetText(PARENS_TEMPLATE:format(subText))
		art.subName:Show()
	else
		art.subName:Hide()
	end
	art.requirements:SetText(BuildRequirements(id, serviceType, reqLevel, isPet and "pet" or "player"))

	local cost = GetTrainerServiceCost(id) or 0
	local showCost = cost > 0 and serviceType ~= "used"
	art.costLabel:SetShown(showCost)
	art.money:SetShown(showCost and not isPet)
	art.pointsCost:SetShown(showCost and isPet)
	if showCost and isPet then
		art.pointsCost:SetText(format(TRAINING_POINTS_ABBREV or TRAINING_POINTS or "%s", cost))
	elseif showCost then
		MoneyFrame_Update(art.money, cost)
		SetMoneyFrameColorByFrame(art.money, GetMoney() >= cost and "white" or "red")
	end

	art.description:ClearAllPoints()
	local descriptionTop = 50
	if showCost then
		descriptionTop = descriptionTop + art.costLabel:GetStringHeight() + 10
		art.description:SetPoint("TOPLEFT", art.costLabel, "BOTTOMLEFT", 0, -10)
	else
		art.description:SetPoint("TOPLEFT", art.costLabel, "TOPLEFT", 0, 0)
	end
	art.description:SetText(description or "")

	art.icon:Show()
	art.name:Show()
	art.requirements:Show()
	art.description:Show()

	-- Size the scroll child to its content so the bar only shows when needed.
	art.detailChild:SetHeight(math.max(50, descriptionTop + art.description:GetStringHeight() + 8))
	art.detail:UpdateScrollChildRect()
end

---------------------------------------------------------------------------
-- Layout
---------------------------------------------------------------------------

-- The list scrolls by pixels, so the row at its top is often cut in half
-- under the pinned step row; vanilla only ever showed whole rows. A row cut
-- off at the list's top is faded (alpha is never read by Blizzard, so the
-- list's own state stays untouched).
local function FadeClippedRows()
	local scrollBox = ClassTrainerFrame and ClassTrainerFrame.ScrollBox
	local top = scrollBox and scrollBox:GetTop()
	if not top then return end
	scrollBox:ForEachFrame(function(row)
		local rowTop = row:GetTop()
		row:SetAlpha((rowTop and rowTop > top + 0.5) and 0 or 1)
	end)
end

-- Vanilla shows 11 rows for a class trainer and 10 (with a taller detail
-- pane) for a profession trainer. Runs after ClassTrainerFrame_Update, which
-- anchors the ScrollBox to the retail insets every time.
local function LayoutFrame()
	local frame = ClassTrainerFrame
	local trade = IsTradeskillTrainer()
	local listHeight = trade and LIST_HEIGHT_TRADE or LIST_HEIGHT_CLASS
	local listBottom = LIST_TOP - listHeight
	local rowsTop = LIST_TOP - 4
	local rowsHeight = listHeight - 8

	local scrollBox = frame.ScrollBox
	local step = frame.skillStepButton
	local boxTop, boxHeight = rowsTop, rowsHeight
	if step and IsStepPinned() then
		step:SetSize(ROW_WIDTH, ROW_HEIGHT)
		Point(step, "TOPLEFT", origin, "TOPLEFT", ROW_LEFT, rowsTop)
		step:Show()
		boxTop, boxHeight = rowsTop - ROW_HEIGHT, rowsHeight - ROW_HEIGHT
	elseif step then
		step:Hide()
	end
	-- The ScrollBox's offsets and size are in its own (scaled) units.
	Point(scrollBox, "TOPLEFT", origin, "TOPLEFT", ROW_LEFT / listScale, boxTop / listScale)
	scrollBox:SetSize(ROW_WIDTH / listScale, boxHeight / listScale)

	local scrollBar = frame.ScrollBar
	if scrollBar then
		local x = LIST_LEFT + LIST_WIDTH + 6
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOPLEFT", origin, "TOPLEFT", x, LIST_TOP)
		scrollBar:SetPoint("BOTTOMLEFT", origin, "TOPLEFT", x, listBottom)
	end
	if art.listTroughTop then
		Point(art.listTroughTop, "TOPLEFT", origin, "TOPLEFT", LIST_LEFT + LIST_WIDTH - 3, LIST_TOP + 2)
		Point(art.listTroughBottom, "BOTTOMLEFT", origin, "TOPLEFT", LIST_LEFT + LIST_WIDTH - 3, listBottom - 2)
	end
	if art.barLeft then
		Point(art.barLeft, "TOPLEFT", origin, "TOPLEFT", 15, listBottom + 5)
	end

	local detailTop = listBottom - 8
	local detailHeight = trade and DETAIL_HEIGHT_TRADE or DETAIL_HEIGHT_CLASS
	Point(art.detail, "TOPLEFT", origin, "TOPLEFT", LIST_LEFT, detailTop)
	art.detail:SetSize(LIST_WIDTH, detailHeight)
	if art.detailTroughTop then
		Point(art.detailTroughTop, "TOPLEFT", origin, "TOPLEFT", LIST_LEFT + LIST_WIDTH - 2, detailTop + 5)
		Point(art.detailTroughBottom, "BOTTOMLEFT", origin, "TOPLEFT", LIST_LEFT + LIST_WIDTH - 2, detailTop - detailHeight - 1)
	end

	if art.greeting then
		art.greeting:SetText(GetTrainerGreetingText() or "")
	end
end

---------------------------------------------------------------------------
-- Module
---------------------------------------------------------------------------

local function Skin()
	local frame = ClassTrainerFrame
	if not frame or not frame.ScrollBox or art.topLeft then return end

	artPrefix = ResolveArtPrefix()
	if not artPrefix then
		ns.Print("This client does not ship " .. T.TRAINER_ART .. "*; the trainer window keeps the retail look.")
		return
	end
	highlightFile = ns.HasTexture(T.LISTBOX_HIGHLIGHT) and T.LISTBOX_HIGHLIGHT or T.LISTBOX_HIGHLIGHT1

	ApplyFrameArt(frame)
	SkinFilterDropdown(frame)
	ns.SkinScrollBar(frame.ScrollBar)
	art.listTroughTop, art.listTroughBottom = CreateTrough(frame, 0.0234375)
	art.detailTroughTop, art.detailTroughBottom = CreateTrough(frame, 0)
	CreateDetailPane(frame)

	-- Scaled, never the view's SetElementExtent / SetPadding (see the header).
	local scrollBox = frame.ScrollBox
	local blizzardRowHeight = type(CLASS_TRAINER_SKILL_HEIGHT) == "number" and CLASS_TRAINER_SKILL_HEIGHT or BLIZZARD_ROW_HEIGHT
	listScale = ROW_HEIGHT / blizzardRowHeight
	scrollBox:SetScale(listScale)
	-- Retail fades the list's edges with shadow textures while it scrolls.
	if scrollBox.GetUpperShadowTexture then
		scrollBox:GetUpperShadowTexture():SetAlpha(0)
		scrollBox:GetLowerShadowTexture():SetAlpha(0)
	end
	-- Vanilla hid the list's scroll bar when everything fit.
	if frame.ScrollBar and ScrollUtil and ScrollUtil.AddManagedScrollBarVisibilityBehavior then
		ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, frame.ScrollBar)
	end

	ns.Hook("ClassTrainerFrame_InitServiceButton", OnRowInit)
	ns.Hook("ClassTrainerFrame_InitCategoryButton", OnCategoryInit) -- Forever only
	ns.Hook("ClassTrainerFrame_Update", function()
		LayoutFrame()
		UpdateDetails()
		FadeClippedRows()
	end)
	if scrollBox.RegisterCallback and BaseScrollBoxEvents then
		for _, event in ipairs({ BaseScrollBoxEvents.OnScroll, BaseScrollBoxEvents.OnLayout }) do
			if event then
				scrollBox:RegisterCallback(event, FadeClippedRows, module)
			end
		end
	end
	ns.Hook("ClassTrainer_SetSelection", UpdateDetails)

	if frame:IsShown() then
		LayoutFrame()
		UpdateDetails()
	end
end

-- Blizzard_TrainerUI is load-on-demand: it loads the first time a trainer is
-- talked to.
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(self, _, addon)
	if addon == "Blizzard_TrainerUI" then
		self:UnregisterEvent("ADDON_LOADED")
		xpcall(Skin, geterrorhandler())
	end
end)

function module:Apply()
	if C_AddOns.IsAddOnLoaded("Blizzard_TrainerUI") then
		Skin()
	else
		eventFrame:RegisterEvent("ADDON_LOADED")
	end
end
