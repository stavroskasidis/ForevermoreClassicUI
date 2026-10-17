--[[
	Forevermore Classic UI - Swing Timers (WoW Forever only)

	Forever adds weapon swing timers (Blizzard_SwingTimer, camelot only): a
	bar per weapon (SwingTimerMainHandFrame, ...OffHandFrame, ...RangedFrame)
	that fills between auto attacks. Vanilla never had one, so the classic
	look is the classic cast bar's: the UI-StatusBar fill in a solid colour
	per weapon on the half black backdrop, the UI-CastingBar-Border frame and
	the cast bar's spark.

	Each bar is an Edit Mode system whose width (213-852) and height (15-60)
	the player sets, so the border cannot be drawn at its file size. It is cut
	into three slices (the end caps and the stretched middle) of the art's
	frame (texels 26-230 x 21-44 of the 256x64 file, shadow trimmed), scaled
	with the bar's height to fill the frame exactly, as Blizzard's frame atlas
	does; Blizzard's StatusBar is re-anchored into the border's opening. The
	layout follows the frame's size from an OnSizeChanged hook.

	The border lives on a frame of the addon's own, a child of Blizzard's
	StatusBar, so it is dimmed with it when the target is out of swing range
	(SwingTimerMixin:ApplyRangePresentation fades the StatusBar). The labels
	and the spark (Blizzard's pip) are moved onto that frame to draw over the
	border, as on the classic cast bar. Blizzard only sets the fill, pip and
	anchors when a bar loads, and never shows its Background / Border again
	after a Hide, so the look is set once. The bars are plain frames and only
	widget state is touched (no Lua fields are written on Blizzard's frames),
	so the module can be toggled live, in combat too.
]]

local _, ns = ...
if not ns.IS_FOREVER then return end
local T = ns.T

local module = ns:RegisterModule({
	key = "swingtimers",
	name = "Swing Timers",
	tooltip = "Gives the weapon swing timer bars the classic cast bar look: the cast bar border, spark and a solid colour per weapon.",
	live = true,
})

-- Classic colours in the hues of Blizzard's fills (warm main hand, cool off
-- hand, green ranged); the main hand's is the classic cast bar yellow.
local BARS = {
	{ name = "SwingTimerMainHandFrame", color = { 1.0, 0.7, 0.0 } },
	{ name = "SwingTimerOffHandFrame", color = { 0.4, 0.6, 1.0 } },
	{ name = "SwingTimerRangedFrame", color = { 0.2, 0.8, 0.2 } },
}

---------------------------------------------------------------------------
-- The classic border, sliced (shared with the preview)
---------------------------------------------------------------------------

-- Texels of Interface\CastingBar\UI-CastingBar-Border (256x64) that are kept
-- (the frame without its outer shadow), the opening inside it, and the end
-- caps drawn unstretched (the inner corner shading included).
local ART_LEFT, ART_RIGHT, ART_TOP, ART_BOTTOM = 26, 230, 21, 44
local HOLE_LEFT, HOLE_RIGHT, HOLE_TOP, HOLE_BOTTOM = 34, 222, 28, 37
local CAP = 14
local FILE_WIDTH, FILE_HEIGHT = 256, 64
local SPARK_SIZE = 32 -- the classic spark on the 1:1 border

local function CreateBorder(parent)
	local border = {}
	for i, key in ipairs({ "left", "middle", "right" }) do
		local texture = parent:CreateTexture(nil, "ARTWORK")
		texture:SetTexture(T.CAST_BORDER)
		local left = (i == 1 and ART_LEFT) or (i == 2 and ART_LEFT + CAP) or (ART_RIGHT - CAP)
		local right = (i == 1 and ART_LEFT + CAP) or (i == 2 and ART_RIGHT - CAP) or ART_RIGHT
		texture:SetTexCoord(left / FILE_WIDTH, right / FILE_WIDTH, ART_TOP / FILE_HEIGHT, ART_BOTTOM / FILE_HEIGHT)
		border[key] = texture
	end
	return border
end

-- Fits the border to `frame` (its art spans the frame top to bottom) and
-- returns the scale and the opening's insets (left, right, top, bottom).
local function LayoutBorder(border, frame, height)
	local scale = height / (ART_BOTTOM - ART_TOP)
	local cap = CAP * scale
	local left, middle, right = border.left, border.middle, border.right
	left:ClearAllPoints()
	left:SetPoint("TOPLEFT", frame, "TOPLEFT")
	left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
	left:SetWidth(cap)
	right:ClearAllPoints()
	right:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
	right:SetWidth(cap)
	middle:ClearAllPoints()
	middle:SetPoint("TOPLEFT", left, "TOPRIGHT")
	middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
	return scale, (HOLE_LEFT - ART_LEFT) * scale, (ART_RIGHT - HOLE_RIGHT) * scale,
		(HOLE_TOP - ART_TOP) * scale, (ART_BOTTOM - HOLE_BOTTOM) * scale
end

ns.SwingTimerArt = {
	CreateBorder = CreateBorder,
	LayoutBorder = LayoutBorder,
	SPARK_SIZE = SPARK_SIZE,
	COLORS = { BARS[1].color, BARS[2].color, BARS[3].color },
}

---------------------------------------------------------------------------
-- Classic look
---------------------------------------------------------------------------

local enabled = false
local hooked = setmetatable({}, { __mode = "k" }) -- swing frame -> true
local own = setmetatable({}, { __mode = "k" })    -- swing frame -> { frame, border, backdrop }

local function GetOwn(frame)
	local parts = own[frame]
	if not parts then
		local bar = frame.StatusBar
		local holder = CreateFrame("Frame", nil, bar)
		holder:SetAllPoints(frame)
		parts = { frame = holder, border = CreateBorder(holder) }
		parts.backdrop = bar:CreateTexture(nil, "BACKGROUND")
		parts.backdrop:SetColorTexture(0, 0, 0, 0.5)
		parts.backdrop:SetAllPoints(bar)
		own[frame] = parts
	end
	return parts
end

local function Layout(frame)
	local parts = own[frame]
	local bar = frame.StatusBar
	local height = frame:GetHeight()
	if not parts or not height or height <= 0 then return end
	local scale, left, right, top, bottom = LayoutBorder(parts.border, frame, height)
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", frame, "TOPLEFT", left, -top)
	bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -right, bottom)
	if bar.Pip then
		bar.Pip:SetSize(SPARK_SIZE * scale, SPARK_SIZE * scale)
	end
end

local function ApplyClassic(frame, color)
	local bar = frame.StatusBar
	if not bar then return end
	local parts = GetOwn(frame)
	parts.frame:Show()
	parts.backdrop:Show()
	if frame.Background then frame.Background:Hide() end
	if frame.Border then frame.Border:Hide() end

	bar:SetStatusBarTexture(T.STATUS_BAR)
	bar:SetStatusBarColor(color[1], color[2], color[3])

	-- Blizzard shows / hides the pip with the timer; only its art changes.
	local pip = bar.Pip
	if pip then
		pip:SetParent(parts.frame)
		pip:SetTexture(T.CAST_SPARK)
		pip:SetTexCoord(0, 1, 0, 1)
		pip:SetBlendMode("ADD")
		pip:ClearAllPoints()
		pip:SetPoint("CENTER", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
	end
	-- Blizzard shows the title's shadow with the title (Show Bar Title).
	if bar.TypeLabelShadow then bar.TypeLabelShadow:SetAlpha(0) end
	if bar.TypeLabel then bar.TypeLabel:SetParent(parts.frame) end
	if bar.TimeLabel then bar.TimeLabel:SetParent(parts.frame) end

	Layout(frame)
end

---------------------------------------------------------------------------
-- Retail look (restored when the module is disabled); see Blizzard_SwingTimer.xml.
---------------------------------------------------------------------------

local function RestoreRetail(frame)
	local bar = frame.StatusBar
	local parts = own[frame]
	if not bar or not parts then return end
	parts.frame:Hide()
	parts.backdrop:Hide()
	if frame.Background then frame.Background:Show() end
	if frame.Border then frame.Border:Show() end

	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -4)
	bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 4)
	bar:SetStatusBarTexture(frame.barTexture) -- reading Blizzard's field is fine
	bar:SetStatusBarColor(1, 1, 1)

	local pip = bar.Pip
	if pip then
		pip:SetParent(bar)
		pip:SetBlendMode("BLEND")
		pip:SetAtlas("ui-swingtimerbar-pip", true)
		pip:ClearAllPoints()
		pip:SetPoint("RIGHT", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
	end
	if bar.TypeLabelShadow then bar.TypeLabelShadow:SetAlpha(1) end
	if bar.TypeLabel then bar.TypeLabel:SetParent(bar) end
	if bar.TimeLabel then bar.TimeLabel:SetParent(bar) end
end

---------------------------------------------------------------------------
-- Module entry points
---------------------------------------------------------------------------

local function ApplyAll()
	for _, info in ipairs(BARS) do
		local frame = _G[info.name]
		if frame and frame.StatusBar then
			if not hooked[frame] then
				hooked[frame] = true
				-- Edit Mode's Width / Height settings.
				frame:HookScript("OnSizeChanged", function(self)
					if enabled then Layout(self) end
				end)
			end
			xpcall(ApplyClassic, geterrorhandler(), frame, info.color)
		end
	end
end

-- Blizzard_SwingTimer loads with the client's own addons, before this one;
-- should it ever load later, the bars are skinned when it does.
local loader

function module:Enable()
	enabled = true
	if _G[BARS[1].name] then
		ApplyAll()
	elseif not loader then
		loader = CreateFrame("Frame")
		loader:RegisterEvent("ADDON_LOADED")
		loader:SetScript("OnEvent", function(self, _, name)
			if name == "Blizzard_SwingTimer" then
				self:UnregisterEvent("ADDON_LOADED")
				if enabled then ApplyAll() end
			end
		end)
	end
end

function module:Disable()
	enabled = false
	for _, info in ipairs(BARS) do
		local frame = _G[info.name]
		if frame then
			xpcall(RestoreRetail, geterrorhandler(), frame)
		end
	end
end
