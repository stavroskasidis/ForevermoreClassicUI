--[[
	Forevermore Classic UI - Minimap

	Restores the pre-Dragonflight minimap: the 140px map inside the
	UI-Minimap-Border ring with the zone text bar on top, the round tracking
	button on the left, the always-visible zoom buttons at the bottom right,
	the calendar page at the top right, the letter icon for new mail, the
	square world map button and the compass ring / north tag. The classic
	group finder eye is a separate, live option in this file (see "Group
	Finder Eye" below), so the modern eye can be kept with the classic map.

	The retail cluster (Blizzard_Minimap\Mainline\Minimap.xml) keeps every
	element the classic one had, so Blizzard's frames are re-skinned in place
	and all of Blizzard's behaviour (tracking menu, tooltips, mail/crafting
	order notifications, calendar, Edit Mode) keeps working. Layout notes:

	  * MinimapCluster is a ResizeLayoutFrame: it sizes itself to its shown
	    children. All classic pieces are therefore placed inside
	    MinimapContainer (192x212 at the cluster's top right), which is also
	    the frame Edit Mode scales with the "Size" slider, so the classic art
	    scales as one piece. Children that Blizzard parents to the cluster
	    (zone text, tracking, mail/crafting indicators, calendar, addon
	    compartment, instance difficulty) are re-parented into it.
	  * Blizzard re-anchors the container, the indicator frame and the
	    difficulty banner from SetHeaderUnderneath (Edit Mode), the indicator
	    children from HorizontalLayoutFrame:Layout, the landing page button
	    from UpdateIcon and the calendar art from GameTimeFrame_SetDate; each
	    of those is hooked to re-apply the classic layout afterwards. The Edit
	    Mode "header underneath" option has no classic equivalent and is
	    ignored (the header is part of the ring art).
	  * MinimapCompassTexture is the region the client rotates together with
	    the map when "rotate minimap" is on, so it carries the classic compass
	    ring (shown only in that mode) and the static ring border is a texture
	    of our own; the north tag is shown in the fixed mode, like classic.
	  * WoW Forever's cluster (since build 70425; retail may follow) has no
	    BorderTop header: its zone text, tracking, calendar and addon
	    compartment buttons draw a StateTexture (+ AddTexture for mouseover)
	    that ButtonStateBehaviorMixin re-sets on every state change. Those two
	    regions are moved into a hidden frame, so the classic textures set on
	    the buttons show instead. Its calendar refreshes the day through the
	    button's SetDate method rather than the GameTimeFrame_SetDate global.
	  * Everything touched is widget state; no Lua fields are written on
	    Blizzard's frames.

	Applied once at login; a UI reload restores the retail look.

	Group Finder Eye (its own option, live): the animated LFG-Eye (30px)
	inside the tracking ring of a 33px button (QueueStatusMinimapButton in
	9.2) instead of the retail 45px flipbook eye. Blizzard's QueueStatusButton
	is kept (tooltip, menu, Edit Mode); its eye is faded out, but its state
	machine keeps running and still reports whether the queue is searching.
	The classic ring and eye live on a child frame of the button, so they can
	be hidden again and scaled on their own. Where the button sits is left to
	Edit Mode (next to the micro menu on retail; on WoW Forever the Minimap
	option moves its default spot onto the ring). Only widget state is
	touched, so turning it off fades Blizzard's eye back in and restores the
	button's retail size.
]]

local _, ns = ...
local T = ns.T
local Point, SetTexture = ns.Point, ns.SetTexture

local module = ns:RegisterModule({
	key = "minimap",
	name = "Minimap",
	tooltip = "Restores the classic minimap: the round border with the zone text bar, the tracking button, the always-visible zoom buttons, the calendar page, the clock at the bottom of the map, the square world map button, the letter icon for new mail and the compass ring / north tag.",
	live = false,
})

-- Classic geometry (9.2.x Minimap.xml). The classic cluster is 192x192; the
-- ring backdrop sits 20px lower, so the container that holds everything is
-- 192x212 with the header strip at its top.
local WIDTH, HEIGHT = 192, 212
local HEADER_HEIGHT = 32
local BACKDROP_SIZE = 192
local BACKDROP_Y = -116            -- ring backdrop centre from the cluster's top centre (20px below the cluster centre)
local MINIMAP_SIZE = 140
local MINIMAP_X, MINIMAP_Y = 9, -92 -- map centre from the cluster's top centre
local ZONE_TEXT_Y = -13            -- zone text button centre from the cluster's top centre

-- Round minimap button (tracking, mail, crafting orders, addon compartment):
-- a 25px dark background and a 20px icon under the 54px ring texture, whose
-- ring sits in the texture's top-left corner (the rest is drop shadow).
local BUTTON_SIZE = 32
local RING_SIZE = 54
local ICON_SIZE = 20
local ICON_X, ICON_Y = 6, -6
local BACKGROUND_SIZE = 25
local BACKGROUND_X, BACKGROUND_Y = 2, -4

-- Hidden frame that retail-only FX regions are parked in.
local parkingLot = CreateFrame("Frame", nil, UIParent)
parkingLot:Hide()

local art = {} -- textures/frames created by this module

-- Parks the state art of a ButtonStateBehaviorMixin button (WoW Forever),
-- which Blizzard re-applies on every mouseover / press.
local function HideStateTextures(button)
	if not button then return end
	for _, key in ipairs({ "StateTexture", "AddTexture" }) do
		local texture = button[key]
		if texture and texture.SetParent then
			texture:SetParent(parkingLot)
		end
	end
end

---------------------------------------------------------------------------
-- Cluster geometry
---------------------------------------------------------------------------

-- Places the container, the map, the ring backdrop and the zone text at the
-- classic positions. Re-run after Blizzard re-anchors any of them.
local function LayoutCluster()
	local cluster = MinimapCluster
	local container = cluster.MinimapContainer

	container:SetSize(WIDTH, HEIGHT)
	Point(container, "TOPRIGHT", cluster, "TOPRIGHT", 0, 0)

	Minimap:SetSize(MINIMAP_SIZE, MINIMAP_SIZE)
	Point(Minimap, "CENTER", container, "TOP", MINIMAP_X, MINIMAP_Y)

	MinimapBackdrop:SetSize(BACKDROP_SIZE, BACKDROP_SIZE)
	Point(MinimapBackdrop, "CENTER", container, "TOP", 0, BACKDROP_Y)

	local zoneButton = cluster.ZoneTextButton
	zoneButton:SetSize(140, 12)
	Point(zoneButton, "CENTER", container, "TOP", 0, ZONE_TEXT_Y)

	if cluster.InstanceDifficulty then
		Point(cluster.InstanceDifficulty, "TOPLEFT", container, "TOPLEFT", 22, -25)
	end
end

-- Classic compass: the rotating CompassRing while the map rotates, the static
-- north tag otherwise (Minimap_UpdateRotationSetting in 9.2).
local function UpdateCompass()
	local rotate = GetCVarBool("rotateMinimap")
	MinimapCompassTexture:SetShown(rotate)
	art.northTag:SetShown(not rotate)
end

-- Header strip, ring border, compass ring and north tag.
local function ApplyFrameArt()
	local container = MinimapCluster.MinimapContainer

	if not art.header then
		art.header = container:CreateTexture(nil, "ARTWORK")
	end
	SetTexture(art.header, T.MINIMAP_BORDER, 0.25, 1, 0, 0.125)
	art.header:SetSize(WIDTH, HEADER_HEIGHT)
	Point(art.header, "TOPRIGHT", container, "TOPRIGHT", 0, 0)

	if not art.border then
		art.border = MinimapBackdrop:CreateTexture(nil, "ARTWORK")
	end
	SetTexture(art.border, T.MINIMAP_BORDER, 0.25, 1, 0.125, 0.875)
	art.border:SetAllPoints(MinimapBackdrop)

	if not art.northTag then
		art.northTag = MinimapBackdrop:CreateTexture(nil, "OVERLAY", nil, 2)
	end
	SetTexture(art.northTag, T.MINIMAP_NORTH_TAG)
	art.northTag:SetSize(16, 16)
	Point(art.northTag, "CENTER", Minimap, "CENTER", 0, 67)

	-- Retail draws its frame art on this region; classic had the compass
	-- ring here (365px at scale 0.7).
	SetTexture(MinimapCompassTexture, T.MINIMAP_COMPASS)
	MinimapCompassTexture:SetSize(365 * 0.7, 365 * 0.7)
	Point(MinimapCompassTexture, "CENTER", Minimap, "CENTER", -2, 0)
	UpdateCompass()

	-- Housing interiors show a static overlay sized to the retail map.
	local overlay = MinimapBackdrop.StaticOverlayTexture
	if overlay then
		overlay:SetSize(MINIMAP_SIZE + 13, MINIMAP_SIZE + 13)
		Point(overlay, "CENTER", Minimap, "CENTER", 0, 0)
	end

	-- The retail header nine-slice (gone on WoW Forever); everything anchored
	-- to it is re-anchored.
	if MinimapCluster.BorderTop then
		MinimapCluster.BorderTop:Hide()
	end
end

-- Re-applies what Blizzard resets from outside of the cluster's own layout
-- code (used by the Forever module after its camelot skin runs).
function module:ReapplyArt()
	LayoutCluster()
	ApplyFrameArt()
end

---------------------------------------------------------------------------
-- Zone text
---------------------------------------------------------------------------

local function ApplyZoneText()
	local button = MinimapCluster.ZoneTextButton
	button:SetParent(MinimapCluster.MinimapContainer)
	HideStateTextures(button)
	MinimapZoneText:SetSize(140, 12)
	MinimapZoneText:SetJustifyH("CENTER")
	Point(MinimapZoneText, "CENTER", button, "TOP", 0, -6)
end

---------------------------------------------------------------------------
-- Round minimap buttons
---------------------------------------------------------------------------

-- Ring texture drawn over a button's icon (the ring covers the icon's
-- square corners, so it goes on the OVERLAY layer).
local function CreateRing(parent, size)
	local ring = parent:CreateTexture(nil, "OVERLAY", nil, 1)
	SetTexture(ring, T.MINIMAP_RING)
	ring:SetSize(size, size)
	Point(ring, "TOPLEFT", parent, "TOPLEFT", 0, 0)
	return ring
end

local function CreateButtonBackground(parent)
	local background = parent:CreateTexture(nil, "BACKGROUND")
	SetTexture(background, T.MINIMAP_BACKGROUND)
	background:SetSize(BACKGROUND_SIZE, BACKGROUND_SIZE)
	Point(background, "TOPLEFT", parent, "TOPLEFT", BACKGROUND_X, BACKGROUND_Y)
	background:SetAlpha(0.6)
	return background
end

-- Tracking: the classic 32x32 button with the magnifying glass icon on the
-- left side of the ring. Retail draws a small round button with the same
-- icon; the dropdown menu itself is untouched.
local function ApplyTracking()
	local tracking = MinimapCluster.Tracking
	if not tracking or not tracking.Button then return end

	tracking:SetParent(MinimapBackdrop)
	tracking:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	Point(tracking, "TOPLEFT", MinimapBackdrop, "TOPLEFT", 9, -45)

	local background = tracking.Background
	if background then
		SetTexture(background, T.MINIMAP_BACKGROUND)
		background:SetSize(BACKGROUND_SIZE, BACKGROUND_SIZE)
		Point(background, "TOPLEFT", tracking, "TOPLEFT", BACKGROUND_X, BACKGROUND_Y)
		background:SetAlpha(0.6)
	end

	local button = tracking.Button
	HideStateTextures(button)
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	Point(button, "TOPLEFT", tracking, "TOPLEFT", 0, 0)

	button:SetNormalTexture(T.MINIMAP_TRACKING)
	local normal = button:GetNormalTexture()
	normal:SetTexCoord(0, 1, 0, 1)
	normal:SetSize(ICON_SIZE, ICON_SIZE)
	Point(normal, "TOPLEFT", button, "TOPLEFT", ICON_X, ICON_Y)

	-- Classic darkened the icon and nudged it while pressed.
	button:SetPushedTexture(T.MINIMAP_TRACKING)
	local pushed = button:GetPushedTexture()
	pushed:SetTexCoord(0, 1, 0, 1)
	pushed:SetSize(ICON_SIZE, ICON_SIZE)
	pushed:SetVertexColor(0.5, 0.5, 0.5)
	Point(pushed, "TOPLEFT", button, "TOPLEFT", ICON_X + 2, ICON_Y - 2)

	button:SetHighlightTexture(T.MINIMAP_HIGHLIGHT, "ADD")
	local highlight = button:GetHighlightTexture()
	highlight:SetTexCoord(0, 1, 0, 1)
	highlight:SetAllPoints(button)

	if not art.trackingRing then
		art.trackingRing = CreateRing(button, RING_SIZE)
	end
end

-- New mail / crafting order indicators: classic showed the letter icon in a
-- ring at the top right of the map. Blizzard lays the two indicators out
-- horizontally from a HorizontalLayoutFrame; after each layout the shown
-- ones are stacked at the classic spot instead.
local function LayoutIndicators()
	local indicators = MinimapCluster.IndicatorFrame
	if not indicators then return end
	local previous
	for _, frame in ipairs({ indicators.MailFrame, indicators.CraftingOrderFrame }) do
		if frame and frame:IsShown() then
			if previous then
				Point(frame, "TOP", previous, "BOTTOM", 0, -2)
			else
				Point(frame, "TOPRIGHT", Minimap, "TOPRIGHT", 24, -37)
			end
			previous = frame
		end
	end
end

local function ApplyIndicators()
	local indicators = MinimapCluster.IndicatorFrame
	if not indicators then return end
	indicators:SetParent(MinimapBackdrop)

	local mail = indicators.MailFrame
	if mail then
		mail:SetSize(33, 33)
		local icon = mail.MailIcon or MiniMapMailIcon
		if icon then
			SetTexture(icon, T.MAIL_ICON)
			icon:SetSize(18, 18)
			Point(icon, "TOPLEFT", mail, "TOPLEFT", 7, -6)
		end
		-- Retail plays an envelope flipbook instead of showing the icon;
		-- keep the static classic icon.
		for _, key in ipairs({ "NewMailFlipbook", "MailReminderFlipbook" }) do
			local flipbook = mail[key]
			if flipbook and flipbook.SetParent then
				flipbook:SetParent(parkingLot)
			end
		end
		ns.Hook(mail, "TryPlayMailNotification", function(self)
			if self.NewMailAnim then self.NewMailAnim:Stop() end
			if self.MailReminderAnim then self.MailReminderAnim:Stop() end
			if self.MailIcon then self.MailIcon:Show() end
		end)
		if not art.mailRing then
			art.mailRing = CreateRing(mail, 52)
		end
	end

	local crafting = indicators.CraftingOrderFrame
	if crafting then
		crafting:SetSize(33, 33)
		local icon = MiniMapCraftingOrderIcon
		if icon then
			Point(icon, "CENTER", crafting, "TOPLEFT", ICON_X + ICON_SIZE / 2, ICON_Y - ICON_SIZE / 2)
		end
		if not art.craftingRing then
			art.craftingBackground = CreateButtonBackground(crafting)
			art.craftingRing = CreateRing(crafting, 52)
		end
	end

	LayoutIndicators()
	ns.Hook(indicators, "Layout", LayoutIndicators)
	ns.Hook("MiniMapIndicatorFrame_UpdatePosition", LayoutIndicators)
end

-- Addon compartment: styled like a classic minimap button on the left side
-- of the ring, below the tracking button. WoW Forever's SetHeaderUnderneath
-- anchors it to the calendar, so it is re-anchored after that too.
local function AnchorAddonCompartment()
	local button = AddonCompartmentFrame
	if not button then return end
	Point(button, "TOPLEFT", MinimapBackdrop, "TOPLEFT", 4, -82)
end

local function ApplyAddonCompartment()
	local button = AddonCompartmentFrame
	if not button then return end

	button:SetParent(MinimapBackdrop)
	HideStateTextures(button)
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	AnchorAddonCompartment()

	button:SetNormalTexture(T.MINIMAP_BACKGROUND)
	local normal = button:GetNormalTexture()
	normal:SetTexCoord(0, 1, 0, 1)
	normal:SetSize(BACKGROUND_SIZE, BACKGROUND_SIZE)
	Point(normal, "TOPLEFT", button, "TOPLEFT", BACKGROUND_X, BACKGROUND_Y)

	button:SetPushedTexture(T.MINIMAP_BACKGROUND)
	local pushed = button:GetPushedTexture()
	pushed:SetTexCoord(0, 1, 0, 1)
	pushed:SetSize(BACKGROUND_SIZE, BACKGROUND_SIZE)
	pushed:SetVertexColor(0.5, 0.5, 0.5)
	Point(pushed, "TOPLEFT", button, "TOPLEFT", BACKGROUND_X, BACKGROUND_Y)

	button:SetHighlightTexture(T.MINIMAP_HIGHLIGHT, "ADD")
	local highlight = button:GetHighlightTexture()
	highlight:SetTexCoord(0, 1, 0, 1)
	highlight:SetAllPoints(button)

	if button.Text then
		Point(button.Text, "CENTER", button, "TOPLEFT", ICON_X + ICON_SIZE / 2, ICON_Y - ICON_SIZE / 2)
	end
	if not art.compartmentRing then
		art.compartmentRing = CreateRing(button, RING_SIZE)
	end
end

---------------------------------------------------------------------------
-- Zoom buttons
---------------------------------------------------------------------------

local function ApplyZoomButton(button, file, x, y)
	button:SetParent(MinimapBackdrop)
	button:SetSize(32, 32)
	Point(button, "CENTER", MinimapBackdrop, "CENTER", x, y)
	button:SetHitRectInsets(4, 4, 2, 6)
	button:SetNormalTexture(file .. "Up")
	button:SetPushedTexture(file .. "Down")
	button:SetDisabledTexture(file .. "Disabled")
	button:SetHighlightTexture(T.MINIMAP_HIGHLIGHT, "ADD")
	for _, texture in ipairs({ button:GetNormalTexture(), button:GetPushedTexture(), button:GetDisabledTexture(), button:GetHighlightTexture() }) do
		texture:SetTexCoord(0, 1, 0, 1)
		texture:SetDesaturated(false)
		texture:SetAllPoints(button)
	end
	button:Show()
end

local function ShowZoomButtons()
	Minimap.ZoomIn:Show()
	Minimap.ZoomOut:Show()
end

-- Retail shows the zoom buttons only while the mouse is over the map;
-- classic always showed them.
local function ApplyZoomButtons()
	if not Minimap.ZoomIn or not Minimap.ZoomOut then return end
	ApplyZoomButton(Minimap.ZoomIn, T.MINIMAP_ZOOM_IN, 72, -25)
	ApplyZoomButton(Minimap.ZoomOut, T.MINIMAP_ZOOM_OUT, 50, -43)
	Minimap:HookScript("OnLeave", ShowZoomButtons)
end

---------------------------------------------------------------------------
-- Calendar
---------------------------------------------------------------------------

-- Retail swaps in a "ui-hud-calendar-<day>-*" atlas for the current day;
-- classic drew the page and printed the day on it.
local function ApplyCalendarArt()
	local button = GameTimeFrame
	button:SetNormalTexture(T.CALENDAR_BUTTON)
	local normal = button:GetNormalTexture()
	normal:SetTexCoord(0, 0.390625, 0, 0.78125)
	normal:SetAllPoints(button)

	button:SetPushedTexture(T.CALENDAR_BUTTON)
	local pushed = button:GetPushedTexture()
	pushed:SetTexCoord(0.5, 0.890625, 0, 0.78125)
	pushed:SetAllPoints(button)

	button:SetHighlightTexture(T.MINIMAP_HIGHLIGHT, "ADD")
	local highlight = button:GetHighlightTexture()
	highlight:SetTexCoord(0, 1, 0, 1)
	highlight:SetAllPoints(button)

	local calendarTime = C_DateAndTime.GetCurrentCalendarTime()
	if calendarTime then
		button:SetText(calendarTime.monthDay)
	end
end

local function ApplyCalendar()
	local button = GameTimeFrame
	if not button then return end

	button:SetParent(MinimapBackdrop)
	HideStateTextures(button)
	button:SetSize(40, 40)
	Point(button, "TOPRIGHT", Minimap, "TOPRIGHT", 20, -2)
	button:SetHitRectInsets(6, 0, 5, 10)

	-- The retail button has no text region; the day is printed on the page.
	local font = GameFontBlack or GameFontNormalSmall
	if not button:GetFontString() then
		local text = button:CreateFontString(nil, "OVERLAY")
		text:SetFontObject(font)
		button:SetFontString(text)
	end
	button:SetNormalFontObject(font)
	button:SetHighlightFontObject(font)
	button:SetDisabledFontObject(GameFontDisable or font)
	Point(button:GetFontString(), "CENTER", button, "CENTER", -1, -1)

	ApplyCalendarArt()
	if button.SetDate then
		ns.Hook(button, "SetDate", ApplyCalendarArt)
	else
		ns.Hook("GameTimeFrame_SetDate", ApplyCalendarArt)
	end
end

---------------------------------------------------------------------------
-- Clock
---------------------------------------------------------------------------

-- Blizzard_TimeManager (load-on-demand) hangs its clock off the retail
-- header; classic drew it on a plate at the bottom of the map.
local function ApplyClock()
	local button = TimeManagerClockButton
	if not button or art.clockBackground then return end

	button:SetParent(MinimapBackdrop)
	button:SetSize(60, 28)
	Point(button, "CENTER", Minimap, "CENTER", 0, -75)

	art.clockBackground = button:CreateTexture(nil, "BORDER")
	SetTexture(art.clockBackground, T.CLOCK_BACKGROUND, 0.015625, 0.8125, 0.015625, 0.390625)
	art.clockBackground:SetAllPoints(button)
end

---------------------------------------------------------------------------
-- World map button
---------------------------------------------------------------------------

-- Retail opens the map from the zone text; classic had a square button at
-- the right end of the header (kept in addition to the zone text click).
local function CreateWorldMapButton()
	if art.worldMap then return end
	if C_GameRules and Enum.GameRule and Enum.GameRule.WorldMapDisabled
		and C_GameRules.IsGameRuleActive(Enum.GameRule.WorldMapDisabled) then
		return
	end

	local button = CreateFrame("Button", nil, MinimapBackdrop)
	art.worldMap = button
	button:SetSize(32, 32)
	Point(button, "TOPRIGHT", MinimapBackdrop, "TOPRIGHT", -2, 23)
	button:SetNormalTexture(T.MINIMAP_WORLD_MAP)
	button:GetNormalTexture():SetTexCoord(0, 1, 0, 0.5)
	button:SetPushedTexture(T.MINIMAP_WORLD_MAP)
	button:GetPushedTexture():SetTexCoord(0, 1, 0.5, 1)
	button:SetHighlightTexture(T.MOUSE_HIGHLIGHT, "ADD")
	local highlight = button:GetHighlightTexture()
	highlight:SetSize(28, 28)
	Point(highlight, "TOPRIGHT", button, "TOPRIGHT", 2, -2)

	button:SetScript("OnClick", function()
		ToggleWorldMap()
	end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText(MicroButtonTooltipText(WORLDMAP_BUTTON, "TOGGLEWORLDMAP"), 1, 1, 1)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", GameTooltip_Hide)
end

---------------------------------------------------------------------------
-- Expansion landing page / garrison button
---------------------------------------------------------------------------

-- Classic anchored the garrison button to the bottom left of the ring
-- (53x53 at TOPLEFT 32,-118 of the 192px backdrop); anchored by centre so
-- the differently sized expansion icons land in the same spot.
local function AnchorLandingPageButton()
	local button = ExpansionLandingPageMinimapButton
	if not button then return end
	Point(button, "CENTER", Minimap, "CENTER", -46, -72)
end

local function ApplyLandingPageButton()
	local button = ExpansionLandingPageMinimapButton
	if not button then return end
	AnchorLandingPageButton()
	ns.Hook(button, "SetLandingPageIconOffset", AnchorLandingPageButton)
	ns.Hook(button, "UpdateIconForGarrison", AnchorLandingPageButton)
end

---------------------------------------------------------------------------
-- Module entry point
---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
	if event == "CVAR_UPDATE" and arg1 == "rotateMinimap" then
		UpdateCompass()
	elseif event == "ADDON_LOADED" and arg1 == "Blizzard_TimeManager" then
		xpcall(ApplyClock, geterrorhandler())
	end
end)

function module:Apply()
	if not MinimapCluster or not MinimapCluster.MinimapContainer or not MinimapBackdrop then return end

	if MinimapCluster.InstanceDifficulty then
		MinimapCluster.InstanceDifficulty:SetParent(MinimapCluster.MinimapContainer)
	end

	LayoutCluster()
	ApplyFrameArt()
	ApplyZoneText()
	ApplyTracking()
	ApplyIndicators()
	ApplyAddonCompartment()
	ApplyZoomButtons()
	ApplyCalendar()
	ApplyClock()
	CreateWorldMapButton()
	ApplyLandingPageButton()

	-- Edit Mode re-anchors the container, the indicators and the difficulty
	-- banner for its "header underneath" option (also on every size change).
	ns.Hook(MinimapCluster, "SetHeaderUnderneath", function(self, headerUnderneath)
		LayoutCluster()
		LayoutIndicators()
		AnchorAddonCompartment()
		if headerUnderneath and self.InstanceDifficulty and self.InstanceDifficulty.SetFlipped then
			self.InstanceDifficulty:SetFlipped(false)
		end
	end)

	eventFrame:RegisterEvent("CVAR_UPDATE")
	eventFrame:RegisterEvent("ADDON_LOADED")

	-- Size the cluster (and its Edit Mode selection box) to the classic art.
	if MinimapCluster.Layout then
		MinimapCluster:Layout()
	end
end

---------------------------------------------------------------------------
-- Group Finder Eye (separate option, live; see the header)
---------------------------------------------------------------------------

local eyeModule = ns:RegisterModule({
	key = "groupfindereye",
	name = "Group Finder Eye",
	tooltip = "Restores the classic group finder eye: the animated eye in a round minimap button ring, instead of the modern eye.",
	live = true,
})

local QUEUE_BUTTON_SIZE = 33
local EYE_SIZE = 30

-- LFG-Eye: 29 cells of 64x64 on a 512x256 sheet, 0.1s each
-- (LFG_EYE_TEXTURES.default in 9.2).
local EYE_FRAMES, EYE_COLUMNS, EYE_DELAY = 29, 8, 0.1
local EYE_CELL_WIDTH, EYE_CELL_HEIGHT = 64 / 512, 64 / 256

local eyeEnabled = false
local eyeScale = 1
local retailWidth, retailHeight -- the button's size before the first enable
local eyeArt, eyeTexture, eyeHighlight
local eyeFrame, eyeElapsed = 1, 0

local function SetEyeFrame(frame)
	eyeFrame = frame
	local column = (frame - 1) % EYE_COLUMNS
	local row = math.floor((frame - 1) / EYE_COLUMNS)
	eyeTexture:SetTexCoord(column * EYE_CELL_WIDTH, (column + 1) * EYE_CELL_WIDTH,
		row * EYE_CELL_HEIGHT, (row + 1) * EYE_CELL_HEIGHT)
end

-- Classic animated the eye while searching and showed the first cell
-- otherwise, which is what retail's static mode means (e.g. a listed group).
local function AnimateEye(_, elapsed)
	local eye = QueueStatusButton.Eye
	if eye.IsStaticMode and eye:IsStaticMode() then
		if eyeFrame ~= 1 then
			SetEyeFrame(1)
		end
		eyeElapsed = 0
		return
	end
	eyeElapsed = eyeElapsed + elapsed
	if eyeElapsed < EYE_DELAY then return end
	local steps = math.floor(eyeElapsed / EYE_DELAY)
	eyeElapsed = eyeElapsed - steps * EYE_DELAY
	SetEyeFrame((eyeFrame - 1 + steps) % EYE_FRAMES + 1)
end

-- Classic nudged the eye while the button was held down.
local function PlaceEye(pressed)
	local offset = pressed and 1 or 0
	Point(eyeTexture, "CENTER", eyeArt, "CENTER", offset, -offset)
end

local function ApplyEyeSize()
	eyeArt:SetScale(eyeScale)
	QueueStatusButton:SetSize(QUEUE_BUTTON_SIZE * eyeScale, QUEUE_BUTTON_SIZE * eyeScale)
end

-- Ring, highlight and eye on a child frame of the button, drawn in classic's
-- order (border, button highlight, eye frame on top). The frame animates
-- only while the button is shown.
local function CreateEyeArt(button)
	eyeArt = CreateFrame("Frame", nil, button)
	eyeArt:SetSize(QUEUE_BUTTON_SIZE, QUEUE_BUTTON_SIZE)
	Point(eyeArt, "CENTER", button, "CENTER", 0, 0)

	local ring = eyeArt:CreateTexture(nil, "BORDER")
	SetTexture(ring, T.MINIMAP_RING)
	ring:SetSize(52, 52)
	Point(ring, "TOPLEFT", eyeArt, "TOPLEFT", 1, -1)

	-- Classic's button highlight, shown by hand so that nothing on
	-- Blizzard's button has to be undone when the option is turned off.
	eyeHighlight = eyeArt:CreateTexture(nil, "ARTWORK", nil, -1)
	SetTexture(eyeHighlight, T.MINIMAP_HIGHLIGHT)
	eyeHighlight:SetBlendMode("ADD")
	eyeHighlight:SetAllPoints(eyeArt)
	eyeHighlight:Hide()

	eyeTexture = eyeArt:CreateTexture(nil, "ARTWORK", nil, 1)
	eyeTexture:SetTexture(T.LFG_EYE)
	eyeTexture:SetSize(EYE_SIZE, EYE_SIZE)
	SetEyeFrame(1)
	PlaceEye(false)
	eyeArt:SetScript("OnUpdate", AnimateEye)

	button:HookScript("OnEnter", function() eyeHighlight:Show() end)
	button:HookScript("OnLeave", function() eyeHighlight:Hide() end)
	button:HookScript("OnMouseDown", function() PlaceEye(true) end)
	button:HookScript("OnMouseUp", function() PlaceEye(false) end)
	button:HookScript("OnHide", function()
		PlaceEye(false)
		eyeHighlight:Hide()
	end)
end

function eyeModule:Enable()
	local button = QueueStatusButton
	if not button or not button.Eye then return end
	if not eyeArt then
		retailWidth, retailHeight = button:GetSize()
		CreateEyeArt(button)
	end
	eyeEnabled = true
	button.Eye:SetAlpha(0)
	eyeArt:Show()
	ApplyEyeSize()
end

function eyeModule:Disable()
	eyeEnabled = false
	if not eyeArt then return end
	eyeArt:Hide()
	QueueStatusButton.Eye:SetAlpha(1)
	QueueStatusButton:SetSize(retailWidth, retailHeight)
end

-- Draws the classic eye (and sizes the button's hit area) at a multiple of
-- the button's own scale, which belongs to Edit Mode's Size setting. The
-- Forever module matches the minimap's scale with it while the eye sits on
-- the ring; the retail eye keeps Blizzard's size.
function eyeModule:SetEyeScale(scale)
	eyeScale = scale
	if eyeEnabled then
		ApplyEyeSize()
	end
end
