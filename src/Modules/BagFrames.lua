--[[
	Forevermore Classic UI - Bag Windows (part of the Bags option)

	Puts the vanilla art on the bag windows, whether the bags open one by one
	or as the combined backpack; the legacy files still ship with the client:

	  * A bag (and the reagent bag, and Forever's key ring) is drawn from
	    UI-Bag-Components (-Keyring) exactly like vanilla's
	    ContainerFrame_GenerateFrame did: a top piece with the portrait ring,
	    name bar, close slot and the first row of slots (the "plus two" top
	    for sizes 4n+2), one or two middle pieces of 41px slot rows and a
	    10px bottom, on the 192px wide vanilla frame.
	  * The backpack is UI-BackpackBackground: the client's copy is the
	    Cataclysm redraw with a band under the name bar for the search box
	    (the slots sit 16px lower than in vanilla's file), which is where
	    the retail search box and sort button go. Its money box holds the
	    money. With more than 16 slots (the authenticator's 4) it is cut
	    into header, slot rows and footer and extra rows are repeated, as
	    Classic Era does; the watched currencies get vanilla's
	    UI-Backpack-TokenFrame strip under the backpack.
	  * The combined backpack has no vanilla counterpart; it is the same
	    backpack art cut into columns as well as rows, so its 10 columns get
	    the backpack's header, slot cells and money box.
	  * The retail frame (NineSlice border and flat background) is faded,
	    the bag icon sits in the vanilla ring, the name is the vanilla
	    white label and the close button the round classic one. Empty item
	    slots drop the modern empty-slot art so the embossed slot of the
	    frame art shows through, as it did.

	Blizzard sizes a window in UpdateFrameSize, lays its slots out on a
	42px grid (5px apart both ways) in UpdateItemLayout and places the money,
	currencies and search box in UpdateCurrencyFrames / UpdateSearchBox;
	those are hooked. The slots keep Blizzard's order: each slot's column and
	row are read back from Blizzard's anchor and it is re-anchored on the
	vanilla grid (41px rows). Container item buttons use their bag through
	a secure attribute to stay untainted, so nothing here writes a Lua field
	on the frames or buttons or calls a Blizzard method that could; only
	widget API is used. Blizzard's frames cannot be restored at runtime, so
	this needs a reload to switch off.
]]

local _, ns = ...
local T = ns.T
local SetTexture = ns.SetTexture

T.BAG_COMPONENTS         = "Interface\\ContainerFrame\\UI-Bag-Components"
T.BAG_COMPONENTS_KEYRING = "Interface\\ContainerFrame\\UI-Bag-Components-Keyring"
T.BACKPACK_BACKGROUND    = "Interface\\ContainerFrame\\UI-BackpackBackground"
T.BACKPACK_TOKEN_FRAME   = "Interface\\ContainerFrame\\UI-Backpack-TokenFrame"
T.KEYRING_BAG_ICON       = "Interface\\ContainerFrame\\KeyRing-Bag-Icon"

local module = ns:RegisterModule({
	key = "bagframes",
	name = "Bag Windows",
	parent = "bags",
	live = false,
})

-- Vanilla's slots: 37px, 5px apart across and 4px apart down, the first one
-- 12px in from the frame's right edge. Blizzard's grid is 5px apart both
-- ways, i.e. 42px per column and row.
local PITCH_X, PITCH_Y = 42, 41
local BLIZZARD_PITCH = 42
local SLOT_RIGHT = 12
local COLUMNS = 4

-- The bag icon in the ring (the ring's hole is 30px across, 24px in and 22px
-- down; the backpack art draws its own backpack there, 2px lower).
local PORTRAIT_SIZE = 32
local PORTRAIT_X, PORTRAIT_Y = 24, -22
local BACKPACK_PORTRAIT_Y = -24

---------------------------------------------------------------------------
-- Bag art (UI-Bag-Components, 256x512; the frame is its right 192 columns)
---------------------------------------------------------------------------

local BAG_WIDTH = 192
local BAG_SLOT_BOTTOM = 9  -- the bottom row's offset from the frame's bottom
-- Vanilla put the slots 12px in from the right like the backpack's, but in
-- game this art's wells are drawn a pixel further left than that, so the
-- items stood a pixel right of them.
local BAG_SLOT_RIGHT = 13
local BAG_ROWS_PER_MIDDLE = 6
local BAG_MIDDLE_TOP = 181 -- file row where the middle piece's first slot row starts
local BAG_TEXTURE_HEIGHT = 512

-- Vanilla's own numbers (ContainerFrame_GenerateFrame): the first row is in
-- the top piece; each further row adds 41px, the last one 9px less as the
-- 10px bottom piece closes it.
local function ShowBagArt(art, slots, file)
	local rows = math.max(1, math.ceil(slots / COLUMNS))
	local top, bottom = art[1], art[4]
	for _, texture in ipairs(art) do
		texture:SetTexture(file)
		texture:ClearAllPoints()
		texture:Hide()
	end

	local height
	if slots % COLUMNS == 2 then
		top:SetTexCoord(0, 1, 0.189453125, 0.330078125)
		height = 72
	elseif rows == 1 then
		top:SetTexCoord(0, 1, 0.00390625, 0.16796875)
		height = 86
	else
		top:SetTexCoord(0, 1, 0.00390625, 0.18359375)
		height = 94
	end
	top:SetHeight(height)
	top:SetPoint("TOPRIGHT", art.frame, "TOPRIGHT", 0, 0)
	top:Show()

	local previous = top
	local remaining = rows - 1
	for i = 2, 3 do
		if remaining <= 0 then break end
		local middle = art[i]
		local middleHeight
		if remaining > BAG_ROWS_PER_MIDDLE then
			middleHeight = BAG_ROWS_PER_MIDDLE * PITCH_Y
			remaining = remaining - BAG_ROWS_PER_MIDDLE
		else
			middleHeight = remaining * PITCH_Y - 9
			remaining = 0
		end
		middle:SetTexCoord(0, 1, BAG_MIDDLE_TOP / BAG_TEXTURE_HEIGHT, (BAG_MIDDLE_TOP + middleHeight) / BAG_TEXTURE_HEIGHT)
		middle:SetHeight(middleHeight)
		middle:SetPoint("TOP", previous, "BOTTOM", 0, 0)
		middle:Show()
		previous = middle
		height = height + middleHeight
	end

	bottom:SetTexCoord(0, 1, 0.330078125, 0.349609375)
	bottom:SetHeight(10)
	bottom:SetPoint("TOP", previous, "BOTTOM", 0, 0)
	bottom:Show()
	return height + 10
end

---------------------------------------------------------------------------
-- Backpack art (UI-BackpackBackground, 256x256: a 192x256 backpack of 4x4
-- slots in its right 192 columns)
--
-- The file is cut at the middle of the metal between slots: across into the
-- first column with the left border (64-121), two inner columns (121-163,
-- 163-205) and the last column with the right border (205-256); down into
-- the header with the first row (0-103), two inner rows (103-144, 144-185)
-- and the last row with the money box (185-256). Any number of columns and
-- rows is the first and last piece with the inner ones alternating in
-- between; neighbouring pieces that are neighbours in the file too are
-- drawn as one texture, so 4x4 is the file itself.
---------------------------------------------------------------------------

local GRID_X = { first = { 64, 121 }, inner = { { 121, 163 }, { 163, 205 } }, last = { 205, 256 } }
local GRID_Y = { first = { 0, 103 }, inner = { { 103, 144 }, { 144, 185 } }, last = { 185, 256 } }
local GRID_TEXTURE_SIZE = 256
local GRID_SLOT_BOTTOM = 31 -- the bottom row's offset from the art's bottom (its 35px well is rows 189-223)
local GRID_MONEY_Y = 19     -- the money box's middle, from the art's bottom

local function Slices(spec, count)
	local slices = { { spec.first[1], spec.first[2] } }
	local function Add(piece)
		local last = slices[#slices]
		if last[2] == piece[1] then
			last[2] = piece[2]
		else
			slices[#slices + 1] = { piece[1], piece[2] }
		end
	end
	for k = 1, count - 2 do
		Add(spec.inner[(k - 1) % 2 + 1])
	end
	Add(spec.last)
	return slices
end

local function ShowGridArt(art, columns, rows)
	local xs, ys = Slices(GRID_X, columns), Slices(GRID_Y, rows)
	local index, y, width = 0, 0, 0
	for _, sliceY in ipairs(ys) do
		local x = 0
		for _, sliceX in ipairs(xs) do
			index = index + 1
			local texture = art[index]
			if not texture then
				texture = art.frame:CreateTexture(nil, "ARTWORK")
				art[index] = texture
			end
			local w, h = sliceX[2] - sliceX[1], sliceY[2] - sliceY[1]
			SetTexture(texture, T.BACKPACK_BACKGROUND,
				sliceX[1] / GRID_TEXTURE_SIZE, sliceX[2] / GRID_TEXTURE_SIZE,
				sliceY[1] / GRID_TEXTURE_SIZE, sliceY[2] / GRID_TEXTURE_SIZE)
			texture:ClearAllPoints()
			texture:SetSize(w, h)
			texture:SetPoint("TOPLEFT", art.frame, "TOPLEFT", x, -y)
			texture:Show()
			x = x + w
		end
		width = x
		y = y + sliceY[2] - sliceY[1]
	end
	for i = index + 1, #art do
		art[i]:Hide()
	end
	return width, y
end

-- Blizzard fills the grid from the bottom right, so a top row that is not
-- full (the combined window's slot count is rarely a multiple of 10) has no
-- slots on its left. Like vanilla's "plus two" bag top, the plain band
-- under the name runs down over those cells, up to the metal on the left
-- of the first slot; it is tiled from a patch of the band clear of the
-- ring's shadow.
local SLOT_SIZE = 37
local COVER_PATCH = { 128, 236, 40, 60 } -- file x1, x2, y1, y2
local COVER_LEFT, COVER_TOP, COVER_BOTTOM = 17, 60, 101

local function ShowCover(art, width, columns, slots)
	local index = 0
	local filled = slots % columns
	if filled > 0 and slots > columns then
		local right = width - SLOT_RIGHT - (filled - 1) * PITCH_X - SLOT_SIZE - (PITCH_X - SLOT_SIZE)
		local patchX, patchRight, patchY, patchBottom = unpack(COVER_PATCH)
		local y = COVER_TOP
		while y < COVER_BOTTOM do
			local h = math.min(patchBottom - patchY, COVER_BOTTOM - y)
			local x = COVER_LEFT
			while x < right do
				local w = math.min(patchRight - patchX, right - x)
				index = index + 1
				local texture = art[index]
				if not texture then
					texture = art.frame:CreateTexture(nil, "ARTWORK", nil, 1)
					art[index] = texture
				end
				SetTexture(texture, T.BACKPACK_BACKGROUND,
					patchX / GRID_TEXTURE_SIZE, (patchX + w) / GRID_TEXTURE_SIZE,
					patchY / GRID_TEXTURE_SIZE, (patchY + h) / GRID_TEXTURE_SIZE)
				texture:ClearAllPoints()
				texture:SetSize(w, h)
				texture:SetPoint("TOPLEFT", art.frame, "TOPLEFT", x, -y)
				texture:Show()
				x = x + w
			end
			y = y + h
		end
	end
	for i = index + 1, #art do
		art[i]:Hide()
	end
end

---------------------------------------------------------------------------
-- Watched currencies: vanilla's UI-Backpack-TokenFrame strip (the 183px
-- art in the left of a 256x32 file) under the backpack, which it overlaps
-- by 10px. Wider frames stretch its plain middle.
---------------------------------------------------------------------------

local STRIP_X, STRIP_HEIGHT, STRIP_EXTRA = 9, 32, 22
local STRIP_LEFT, STRIP_MIDDLE, STRIP_RIGHT = { 0, 56 }, { 56, 128 }, { 128, 184 }
local TRACKER_LEFT, TRACKER_RIGHT, TRACKER_BOTTOM = 17, 12, 8 -- the strip's inner box

local function ShowStrip(strip, frame, width, shown)
	if not shown then
		for _, texture in ipairs(strip) do texture:Hide() end
		return 0
	end
	local total = width - STRIP_X
	local pieces = {
		{ STRIP_LEFT, STRIP_LEFT[2] - STRIP_LEFT[1], 0 },
		{ STRIP_MIDDLE, total - (STRIP_LEFT[2] - STRIP_LEFT[1]) - (STRIP_RIGHT[2] - STRIP_RIGHT[1]), STRIP_LEFT[2] - STRIP_LEFT[1] },
		{ STRIP_RIGHT, STRIP_RIGHT[2] - STRIP_RIGHT[1], total - (STRIP_RIGHT[2] - STRIP_RIGHT[1]) },
	}
	for i, piece in ipairs(pieces) do
		local texture = strip[i]
		if not texture then
			-- Over the backpack's bottom border, which it tucks under.
			texture = frame:CreateTexture(nil, "ARTWORK", nil, 2)
			strip[i] = texture
		end
		SetTexture(texture, T.BACKPACK_TOKEN_FRAME, piece[1][1] / 256, piece[1][2] / 256, 0, 1)
		texture:ClearAllPoints()
		texture:SetSize(piece[2], STRIP_HEIGHT)
		texture:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", STRIP_X + piece[3], 0)
		texture:Show()
	end
	return STRIP_EXTRA
end

---------------------------------------------------------------------------
-- Layout
---------------------------------------------------------------------------

local arts = setmetatable({}, { __mode = "k" })    -- frame -> { bag = {...}, grid = {...}, strip = {...} }
local layouts = setmetatable({}, { __mode = "k" }) -- frame -> the art last drawn

local function GetArt(frame)
	local art = arts[frame]
	if not art then
		art = { bag = { frame = frame }, grid = { frame = frame }, cover = { frame = frame }, strip = {} }
		for i = 1, 4 do
			local texture = frame:CreateTexture(nil, "ARTWORK")
			texture:SetWidth(256)
			art.bag[i] = texture
		end
		arts[frame] = art
	end
	return art
end

-- The watched currencies only show in the backpack or combined window.
local function ShownTracker(frame)
	local tracker = _G.BackpackTokenFrame
	if tracker and tracker:GetParent() == frame and tracker:IsShown() then
		return tracker
	end
end

local function IsKeyRing(frame)
	local keyring = Enum.BagIndex and Enum.BagIndex.Keyring
	return keyring ~= nil and frame:GetID() == keyring
end

-- The controller UI's focus glow (ns.SetGamepadBox) goes round the art's
-- border: the frame is sized to the art, whose files have transparent
-- margins round the border (left, top, right, bottom; measured in game, the
-- left one under the portrait ring's overhang).
local BOX_INSETS_GRID = { 10, 9, 6, 6 }
local BOX_INSETS_BAG = { 9, 7, 6, 4 }
local boxes = setmetatable({}, { __mode = "k" }) -- frame -> its box

local function PlaceBox(frame, grid)
	local box = boxes[frame]
	if not box then return end
	local left, top, right, bottom = unpack(grid and BOX_INSETS_GRID or BOX_INSETS_BAG)
	box:ClearAllPoints()
	box:SetPoint("TOPLEFT", frame, "TOPLEFT", left, -top)
	box:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -right, bottom)
end

-- Draws the frame's art for its current slots and sizes the frame to it.
-- Runs after Blizzard's UpdateFrameSize and UpdateCurrencyFrames, which
-- size it for the retail layout.
local function UpdateArt(frame)
	local art = GetArt(frame)
	local slots = frame.Items and #frame.Items or 0
	local layout = {}
	if frame == ContainerFrame1 or frame == ContainerFrameCombinedBags then
		layout.grid = true
		layout.columns = frame == ContainerFrameCombinedBags and frame.GetColumns and frame:GetColumns() or COLUMNS
		local rows = math.max(2, math.ceil(slots / layout.columns))
		for _, texture in ipairs(art.bag) do texture:Hide() end
		layout.width, layout.height = ShowGridArt(art.grid, layout.columns, rows)
		ShowCover(art.cover, layout.width, layout.columns, slots)
	else
		for _, texture in ipairs(art.grid) do texture:Hide() end
		for _, texture in ipairs(art.cover) do texture:Hide() end
		layout.width = BAG_WIDTH
		layout.height = ShowBagArt(art.bag, slots, IsKeyRing(frame) and T.BAG_COMPONENTS_KEYRING or T.BAG_COMPONENTS)
	end
	local extra = ShowStrip(art.strip, frame, layout.width, layout.grid and ShownTracker(frame) ~= nil)
	frame:SetSize(layout.width, layout.height + extra)
	PlaceBox(frame, layout.grid)
	layouts[frame] = layout
	return layout
end

local skinnedItems = setmetatable({}, { __mode = "k" })

-- Blizzard gives an empty slot a modern empty-slot atlas as its icon; the
-- embossed slot of the frame art shows through instead.
local function HideEmptySlotArt(item, texture)
	if not texture and item.icon then
		item.icon:Hide()
	end
end

-- The quality border's line is drawn a pixel inside its 37px texture, so it
-- stood a pixel inside the slot's metal ring, while the gold quest border
-- sits on the ring; it is grown a pixel each way to sit there too.
local QUALITY_BORDER_SIZE = 39

local function SkinItem(item)
	-- The combined window's own per-slot backdrop (a cut of the vanilla art).
	if item.ItemSlotBackground then item.ItemSlotBackground:SetAlpha(0) end
	if skinnedItems[item] then return end
	skinnedItems[item] = true
	if item.IconBorder then item.IconBorder:SetSize(QUALITY_BORDER_SIZE, QUALITY_BORDER_SIZE) end
	ns.Hook(item, "SetItemButtonTexture", HideEmptySlotArt)
end

-- Runs after Blizzard's UpdateItemLayout: every slot is anchored by its
-- BOTTOMRIGHT to one point with a 42px step per column and row, so its
-- column and row are read back from that and it is moved onto the
-- vanilla grid. This keeps Blizzard's order (which the combined window
-- sorts) without reproducing it.
local function PlaceItems(frame)
	local items = frame.Items
	if not items or #items == 0 then return end
	local layout = layouts[frame] or UpdateArt(frame)

	local maxX, minY
	for _, item in ipairs(items) do
		local _, _, _, x, y = item:GetPoint(1)
		if x and y then
			maxX = maxX and math.max(maxX, x) or x
			minY = minY and math.min(minY, y) or y
		end
	end
	if not maxX then return end

	for _, item in ipairs(items) do
		local _, _, _, x, y = item:GetPoint(1)
		if x and y then
			local column = math.floor((maxX - x) / BLIZZARD_PITCH + 0.5)
			local row = math.floor((y - minY) / BLIZZARD_PITCH + 0.5)
			item:ClearAllPoints()
			if layout.grid then
				item:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -SLOT_RIGHT - column * PITCH_X, -(layout.height - GRID_SLOT_BOTTOM) + row * PITCH_Y)
			else
				item:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -BAG_SLOT_RIGHT - column * PITCH_X, BAG_SLOT_BOTTOM + row * PITCH_Y)
			end
		end
		SkinItem(item)
	end
end

-- Runs after UpdateCurrencyFrames (backpack and combined window), which
-- stacks the money over the currencies at the bottom of the retail frame.
local function PlaceCurrencies(frame)
	local layout = UpdateArt(frame)
	local money = frame.MoneyFrame
	if money then
		if money.Border then money.Border:SetAlpha(0) end
		money:ClearAllPoints()
		money:SetPoint("LEFT", frame, "TOPLEFT", 24, -(layout.height - GRID_MONEY_Y))
		money:SetPoint("RIGHT", frame, "TOPRIGHT", -2, -(layout.height - GRID_MONEY_Y))
	end
	local tracker = ShownTracker(frame)
	if tracker then
		if tracker.Border then tracker.Border:SetAlpha(0) end
		tracker:ClearAllPoints()
		tracker:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", TRACKER_LEFT, TRACKER_BOTTOM)
		tracker:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -TRACKER_RIGHT, TRACKER_BOTTOM)
	end
end

-- Runs after UpdateSearchBox: the search box and sort button go into the
-- band under the backpack's name bar. The portrait ring hangs into the
-- band's top left, so the box starts clear of it (its left cap is drawn 5px
-- outside the box).
local SEARCH_LEFT, SEARCH_TOP = 52, -36
local SORT_RIGHT, SORT_TOP, SORT_WIDTH, SORT_GAP = -13, -32, 28, 6

local function PlaceSearchBox(frame)
	local layout = layouts[frame]
	if not layout or not layout.grid then return end
	local searchBox, sortButton = _G.BagItemSearchBox, _G.BagItemAutoSortButton
	if sortButton and sortButton:GetParent() == frame then
		sortButton:ClearAllPoints()
		sortButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", SORT_RIGHT, SORT_TOP)
	end
	if searchBox and searchBox:GetParent() == frame then
		searchBox:ClearAllPoints()
		searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", SEARCH_LEFT, SEARCH_TOP)
		searchBox:SetWidth(layout.width + SORT_RIGHT - SORT_WIDTH - SORT_GAP - SEARCH_LEFT)
	end
end

-- Runs after UpdateMiscellaneousFrames, which sets the bag icon; Forever's
-- key ring gets vanilla's key ring icon.
local function UpdatePortrait(frame)
	if IsKeyRing(frame) then
		local portrait = frame.PortraitContainer and frame.PortraitContainer.portrait
		if portrait then portrait:SetTexture(T.KEYRING_BAG_ICON) end
	end
end

---------------------------------------------------------------------------
-- Frames
---------------------------------------------------------------------------

local function SkinFrame(frame)
	local backpackArt = frame == ContainerFrame1 or frame == ContainerFrameCombinedBags
	local portraitY = backpackArt and BACKPACK_PORTRAIT_Y or PORTRAIT_Y

	if frame.NineSlice then frame.NineSlice:SetAlpha(0) end
	if frame.Bg then frame.Bg:SetAlpha(0) end

	local title = frame.TitleContainer
	if title then
		title:ClearAllPoints()
		title:SetPoint("TOPLEFT", frame, "TOPLEFT", 47, -5)
		title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -33, -5)
		if title.TitleText then title.TitleText:SetFontObject(GameFontHighlight) end
	end

	if frame.CloseButton then
		ns.SkinCloseButton(frame.CloseButton)
		frame.CloseButton:ClearAllPoints()
		frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -1)
	end

	-- The icon sits in the ring's hole (it draws over the art); the backpack
	-- art has its backpack there already, so its icon is only kept in place
	-- for what is anchored to it (the bag filter icon).
	local container = frame.PortraitContainer
	local portrait = container and container.portrait
	if portrait then
		portrait:ClearAllPoints()
		portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
		portrait:SetPoint("CENTER", frame, "TOPLEFT", PORTRAIT_X, portraitY)
		if container.CircleMask then
			container.CircleMask:ClearAllPoints()
			container.CircleMask:SetAllPoints(portrait)
		end
		if backpackArt then portrait:SetAlpha(0) end
	end

	local portraitButton = frame.PortraitButton
	if portraitButton then
		portraitButton:ClearAllPoints()
		portraitButton:SetSize(40, 40)
		portraitButton:SetPoint("CENTER", frame, "TOPLEFT", PORTRAIT_X, portraitY)
		if portraitButton.Highlight then
			portraitButton.Highlight:ClearAllPoints()
			portraitButton.Highlight:SetAllPoints(portraitButton)
		end
	end

	boxes[frame] = CreateFrame("Frame", nil, frame)
	PlaceBox(frame, backpackArt)
	ns.SetGamepadBox(frame, boxes[frame])

	ns.Hook(frame, "UpdateFrameSize", UpdateArt)
	ns.Hook(frame, "UpdateItemLayout", PlaceItems)
	ns.Hook(frame, "UpdateCurrencyFrames", PlaceCurrencies)
	ns.Hook(frame, "UpdateSearchBox", PlaceSearchBox)
	ns.Hook(frame, "UpdateMiscellaneousFrames", UpdatePortrait)

	if frame:IsShown() then
		UpdateArt(frame)
		PlaceItems(frame)
		if frame.MoneyFrame then PlaceCurrencies(frame) end
		PlaceSearchBox(frame)
		UpdatePortrait(frame)
	end
end

---------------------------------------------------------------------------
-- Module entry point
---------------------------------------------------------------------------

function module:Apply()
	if not ContainerFrame1 then return end
	if not ns.HasTexture(T.BAG_COMPONENTS) or not ns.HasTexture(T.BACKPACK_BACKGROUND) then
		ns.Print("This client does not ship the vanilla bag art; the modern bag windows are kept.")
		return
	end
	local i = 1
	while _G["ContainerFrame" .. i] do
		SkinFrame(_G["ContainerFrame" .. i])
		i = i + 1
	end
	if ContainerFrameCombinedBags then
		SkinFrame(ContainerFrameCombinedBags)
	end
end
