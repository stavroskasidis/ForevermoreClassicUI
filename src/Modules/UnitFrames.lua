--[[
	Forevermore Classic UI - Unit Frames

	Restores the pre-Dragonflight frame art and layout of the player, target,
	focus, target-of-target, pet, party and boss frames. Blizzard's frames are
	re-skinned in place (textures, texts and icons are kept), so all of
	Blizzard's behaviour keeps working.

	Layout notes:
	  * The classic player/target frames are 232x100 with the frame art anchored
	    at the top-left. The retail PlayerFrame is also 232x100 but its content
	    is shifted, so classic coordinates are offset by (-19, -4) for the player
	    frame and (+20, -4) for the target/focus frames.
	  * Blizzard's status bars and their containers are protected frames
	    (SecureFrameTemplate) and cannot be moved by an addon in combat, so the
	    classic bars are unprotected "mirror" bars (see Core.lua) placed at the
	    classic positions; Blizzard's own fills are faded out.
	  * Classic bars sit *behind* the frame art: mirrors get the unit button's
	    own frame level while the art container stays one level above.
]]

local _, ns = ...
local T = ns.T

local module = ns:RegisterModule({
	key = "unitframes",
	name = "Unit Frames",
	tooltip = "Restores the classic frame artwork and layout of the player, target, focus, pet, party, target-of-target and boss frames, including the circular portraits with the classic resting/combat indicators, the flat classic health and power bars (texture and colours) and the raid-style frame bars.",
	live = false,
})

local PLAYER_OFFSET_X, PLAYER_OFFSET_Y = -19, -4
local TARGET_OFFSET_X, TARGET_OFFSET_Y = 20, -4

local Point = ns.Point
local SetTexture = ns.SetTexture

local function IsTargetStyleFrame(frame)
	return frame and frame.TargetFrameContainer ~= nil
end

-- Classic circular role icons from UI-LFG-ICON-PORTRAITROLES.
local function ApplyClassicRoleIcon(icon, unit)
	local role = unit and UnitGroupRolesAssignedEnum and UnitGroupRolesAssignedEnum(unit)
	icon:SetSize(19, 19)
	SetTexture(icon, T.ROLE_ICONS)
	if role == Enum.LFGRole.Tank then
		icon:SetTexCoord(0, 19 / 64, 22 / 64, 41 / 64)
		icon:Show()
	elseif role == Enum.LFGRole.Healer then
		icon:SetTexCoord(20 / 64, 39 / 64, 1 / 64, 20 / 64)
		icon:Show()
	elseif role == Enum.LFGRole.Damage then
		icon:SetTexCoord(20 / 64, 39 / 64, 22 / 64, 41 / 64)
		icon:Show()
	else
		icon:Hide()
	end
end

-- Builds the classic health/power mirrors for a Blizzard health bar + power
-- bar pair and moves the unprotected companions (loss bars, prediction
-- segments, feedback glows) onto them.
local function CreateBarMirrors(unitFrame, healthBar, powerBar, extraLossBars)
	local level = unitFrame:GetFrameLevel()
	local healthMirror = ns.CreateMirrorBar(healthBar, level)
	local powerMirror = powerBar and ns.CreateMirrorBar(powerBar, level)

	for _, key in ipairs({ "MyHealPredictionBar", "OtherHealPredictionBar", "HealAbsorbBar", "TotalAbsorbBar" }) do
		ns.AttachToMirror(healthBar[key], healthMirror, level)
	end
	for _, lossBar in ipairs(extraLossBars or {}) do
		ns.AttachToMirror(lossBar, healthMirror, level)
	end
	for _, key in ipairs({ "OverAbsorbGlow", "OverHealAbsorbGlow" }) do
		local glow = healthBar[key]
		if glow then
			glow:SetParent(healthMirror)
			glow:SetDrawLayer("ARTWORK", 1)
		end
	end
	if healthBar.OverAbsorbGlow then
		Point(healthBar.OverAbsorbGlow, "TOPLEFT", healthMirror, "TOPRIGHT", -7, 0)
		healthBar.OverAbsorbGlow:SetPoint("BOTTOMLEFT", healthMirror, "BOTTOMRIGHT", -7, 0)
	end
	if healthBar.OverHealAbsorbGlow then
		Point(healthBar.OverHealAbsorbGlow, "BOTTOMRIGHT", healthMirror, "BOTTOMLEFT", 7, 0)
		healthBar.OverHealAbsorbGlow:SetPoint("TOPRIGHT", healthMirror, "TOPLEFT", 7, 0)
	end

	if powerMirror then
		ns.AttachToMirror(powerBar.FeedbackFrame, powerMirror, level)
		ns.AttachToMirror(powerBar.FullPowerFrame, powerMirror, level)
		ns.AttachToMirror(powerBar.ManaCostPredictionBar, powerMirror, level)
	end

	return healthMirror, powerMirror
end

---------------------------------------------------------------------------
-- Player frame
---------------------------------------------------------------------------

local function LayoutPlayerBars(self, state)
	local health, power = self.CUIR_HealthBar, self.CUIR_ManaBar
	-- UnitFrame_SetUnit (vehicle swaps) may re-anchor the loss bars to Blizzard's bar.
	local hbc = self.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer
	for _, lossBar in ipairs({ hbc.PlayerFrameHealthBarAnimatedLoss, hbc.PlayerFrameTempMaxHealthLoss }) do
		lossBar:ClearAllPoints()
		lossBar:SetAllPoints(health)
	end
	if state == "vehicle" then
		-- Vehicle art has a slightly narrower window.
		health:SetSize(100, 12)
		Point(health, "TOPLEFT", self, "TOPLEFT", 100, -45)
		power:SetSize(100, 12)
		Point(power, "TOPLEFT", self, "TOPLEFT", 100, -56)
	else
		health:SetSize(119, 12)
		Point(health, "TOPLEFT", self, "TOPLEFT", 106 + PLAYER_OFFSET_X, -41 + PLAYER_OFFSET_Y)
		power:SetSize(119, 12)
		Point(power, "TOPLEFT", self, "TOPLEFT", 106 + PLAYER_OFFSET_X, -52 + PLAYER_OFFSET_Y)
	end
end

local function PlayerFrame_ClassicArt(self)
	local container = self.PlayerFrameContainer
	local contextual = self.PlayerFrameContent.PlayerFrameContentContextual
	local main = self.PlayerFrameContent.PlayerFrameContentMain

	for _, texture in ipairs({ container.FrameTexture, container.AlternatePowerFrameTexture }) do
		texture:SetSize(232, 100)
		SetTexture(texture, T.TARGET_FRAME, 1, 0.09375, 0, 0.78125)
		Point(texture, "TOPLEFT", self, "TOPLEFT", PLAYER_OFFSET_X, PLAYER_OFFSET_Y)
	end
	container.FrameTexture:SetDrawLayer("BORDER")
	container.AlternatePowerFrameTexture:SetDrawLayer("BORDER")

	local flash = container.FrameFlash
	flash:SetSize(242, 93)
	SetTexture(flash, T.TARGET_FLASH, 0.9453125, 0, 0, 0.181640625)
	Point(flash, "TOPLEFT", self, "TOPLEFT", 13 + PLAYER_OFFSET_X, 0 + PLAYER_OFFSET_Y)
	flash:SetDrawLayer("BACKGROUND", -7)

	local status = main.StatusTexture
	status:SetSize(190, 66)
	SetTexture(status, T.PLAYER_STATUS, 0, 0.74609375, 0, 0.53125)
	Point(status, "TOPLEFT", self, "TOPLEFT", 35 + PLAYER_OFFSET_X, -8 + PLAYER_OFFSET_Y)
	status:SetBlendMode("ADD")

	LayoutPlayerBars(self, "player")

	self.CUIR_Backdrop:SetSize(119, 41)
	Point(self.CUIR_Backdrop, "TOPLEFT", self, "TOPLEFT", 106 + PLAYER_OFFSET_X, -22 + PLAYER_OFFSET_Y)

	Point(contextual.GroupIndicator, "BOTTOMLEFT", self, "TOPLEFT", 97 + PLAYER_OFFSET_X, -20 + PLAYER_OFFSET_Y)
	Point(contextual.RoleIcon, "TOPLEFT", self, "TOPLEFT", 95 + PLAYER_OFFSET_X, -15 + PLAYER_OFFSET_Y)

	PlayerLevelText:Show()
end

local function PlayerFrame_ClassicVehicleArt(self)
	local container = self.PlayerFrameContainer
	local contextual = self.PlayerFrameContent.PlayerFrameContentContextual
	local main = self.PlayerFrameContent.PlayerFrameContentMain

	local vehicle = container.VehicleFrameTexture
	vehicle:SetSize(240, 120)
	SetTexture(vehicle, T.VEHICLE_FRAME)
	Point(vehicle, "TOPLEFT", self, "TOPLEFT", -3, 6)
	vehicle:SetDrawLayer("BORDER")

	local flash = container.FrameFlash
	flash:SetSize(242, 93)
	SetTexture(flash, T.VEHICLE_FLASH, -0.02, 1, 0.07, 0.86)
	Point(flash, "TOPLEFT", self, "TOPLEFT", -6, -4)
	flash:SetDrawLayer("BACKGROUND", -7)

	local status = main.StatusTexture
	status:SetSize(242, 93)
	SetTexture(status, T.VEHICLE_FLASH, -0.02, 1, 0.07, 0.86)
	Point(status, "TOPLEFT", self, "TOPLEFT", -6, -4)
	status:SetBlendMode("ADD")

	LayoutPlayerBars(self, "vehicle")

	self.CUIR_Backdrop:SetSize(114, 41)
	Point(self.CUIR_Backdrop, "TOPLEFT", self, "TOPLEFT", 106 + PLAYER_OFFSET_X, -22 + PLAYER_OFFSET_Y)

	Point(contextual.GroupIndicator, "BOTTOMLEFT", self, "TOPLEFT", 97 + PLAYER_OFFSET_X, -13 + PLAYER_OFFSET_Y)
	Point(contextual.RoleIcon, "TOPLEFT", self, "TOPLEFT", 95 + PLAYER_OFFSET_X, -15 + PLAYER_OFFSET_Y)

	PlayerLevelText:Hide()
end

local function PlayerFrame_ClassicNameAnchor()
	PlayerName:SetWidth(100)
	PlayerName:SetJustifyH("CENTER")
	-- Classic: 100px wide, centred over the name background (x 97..197).
	if PlayerFrame.state == "vehicle" then
		Point(PlayerName, "TOPLEFT", PlayerFrame, "TOPLEFT", 97, -26)
	else
		Point(PlayerName, "TOPLEFT", PlayerFrame, "TOPLEFT", 97, -30)
	end
end

local function SkinPlayerFrame()
	local frame = PlayerFrame
	local container = frame.PlayerFrameContainer
	local main = frame.PlayerFrameContent.PlayerFrameContentMain
	local contextual = frame.PlayerFrameContent.PlayerFrameContentContextual
	local hbc = main.HealthBarsContainer
	local healthBar = hbc.HealthBar
	local manaBar = main.ManaBarArea.ManaBar
	local level = frame:GetFrameLevel()

	-- The combat flash is a big glow behind the whole frame in classic.
	container.FrameFlash:SetParent(frame)

	-- Rectangular classic bars: get rid of the retail bar-shaped masks.
	ns.StripMask(hbc.HealthBarMask,
		healthBar:GetStatusBarTexture(),
		hbc.PlayerFrameHealthBarAnimatedLoss:GetStatusBarTexture(),
		hbc.PlayerFrameTempMaxHealthLoss:GetStatusBarTexture(),
		healthBar.MyHealPredictionBar and healthBar.MyHealPredictionBar.Fill,
		healthBar.OtherHealPredictionBar and healthBar.OtherHealPredictionBar.Fill,
		healthBar.TotalAbsorbBar and healthBar.TotalAbsorbBar.Fill,
		healthBar.TotalAbsorbBar and healthBar.TotalAbsorbBar.TiledFillOverlay,
		healthBar.HealAbsorbBar and healthBar.HealAbsorbBar.Fill,
		healthBar.HealAbsorbBar and healthBar.HealAbsorbBar.LeftShadow,
		healthBar.HealAbsorbBar and healthBar.HealAbsorbBar.RightShadow,
		healthBar.OverAbsorbGlow,
		healthBar.OverHealAbsorbGlow,
		healthBar.Background)
	ns.StripMask(manaBar.ManaBarMask,
		manaBar:GetStatusBarTexture(),
		manaBar.ManaCostPredictionBar and manaBar.ManaCostPredictionBar.Fill,
		manaBar.Spark,
		manaBar.FeedbackFrame and manaBar.FeedbackFrame.BarTexture,
		manaBar.FeedbackFrame and manaBar.FeedbackFrame.LossGlowTexture,
		manaBar.FeedbackFrame and manaBar.FeedbackFrame.GainGlowTexture)
	if healthBar.Background then
		healthBar.Background:Hide()
	end
	if hbc.TempMaxHealthLossDivider then
		hbc.TempMaxHealthLossDivider:SetAlpha(0)
	end

	-- Classic bars (mirrors of Blizzard's protected bars).
	frame.CUIR_HealthBar, frame.CUIR_ManaBar = CreateBarMirrors(frame, healthBar, manaBar,
		{ hbc.PlayerFrameHealthBarAnimatedLoss, hbc.PlayerFrameTempMaxHealthLoss })
	Point(hbc.HealthBarText, "CENTER", frame.CUIR_HealthBar, "CENTER", 0, 0)
	Point(hbc.LeftText, "LEFT", frame.CUIR_HealthBar, "LEFT", 4, 0)
	Point(hbc.RightText, "RIGHT", frame.CUIR_HealthBar, "RIGHT", -4, 0)
	Point(manaBar.ManaBarText, "CENTER", frame.CUIR_ManaBar, "CENTER", 0, 0)
	Point(manaBar.LeftText, "LEFT", frame.CUIR_ManaBar, "LEFT", 4, 0)
	Point(manaBar.RightText, "RIGHT", frame.CUIR_ManaBar, "RIGHT", -4, 0)

	-- Classic black backdrop behind name/health/power.
	frame.CUIR_Backdrop = ns.CreateBackdrop(frame, 119, 41, "TOPLEFT", frame, "TOPLEFT", 106 + PLAYER_OFFSET_X, -22 + PLAYER_OFFSET_Y)

	-- Portrait geometry (the mask itself is handled by the Portraits module).
	container.PlayerPortrait:SetSize(64, 64)
	Point(container.PlayerPortrait, "TOPLEFT", frame, "TOPLEFT", 42 + PLAYER_OFFSET_X, -12 + PLAYER_OFFSET_Y)
	container.PlayerPortraitMask:ClearAllPoints()
	container.PlayerPortraitMask:SetAllPoints(container.PlayerPortrait)

	-- Level / name.
	Point(PlayerLevelText, "CENTER", frame, "CENTER", -62 + PLAYER_OFFSET_X, -17 + PLAYER_OFFSET_Y)
	PlayerFrame_ClassicNameAnchor()

	-- Hit indicator (damage/heal numbers over the portrait).
	if main.HitIndicator and main.HitIndicator.HitText then
		Point(main.HitIndicator.HitText, "CENTER", frame, "TOPLEFT", 73 + PLAYER_OFFSET_X, -42 + PLAYER_OFFSET_Y)
	end

	-- Group leader / guide icons.
	contextual.LeaderIcon:SetSize(16, 16)
	SetTexture(contextual.LeaderIcon, T.LEADER_ICON)
	Point(contextual.LeaderIcon, "TOPLEFT", frame, "TOPLEFT", 40 + PLAYER_OFFSET_X, -12 + PLAYER_OFFSET_Y)
	contextual.GuideIcon:SetSize(19, 19)
	SetTexture(contextual.GuideIcon, T.ROLE_ICONS, 0, 0.296875, 0.015625, 0.3125)
	Point(contextual.GuideIcon, "TOPLEFT", frame, "TOPLEFT", 40 + PLAYER_OFFSET_X, -12 + PLAYER_OFFSET_Y)

	-- PvP / prestige icons.
	Point(contextual.PrestigePortrait, "TOPLEFT", frame, "TOPLEFT", 15 + PLAYER_OFFSET_X, -13 + PLAYER_OFFSET_Y)
	Point(contextual.PvpTimerText, "CENTER", frame, "TOPLEFT", 38 + PLAYER_OFFSET_X, -8 + PLAYER_OFFSET_Y)

	-- Raid group indicator (classic parchment style).
	local groupIndicator = contextual.GroupIndicator
	if groupIndicator then
		groupIndicator.GroupIndicatorLeft:SetSize(24, 16)
		SetTexture(groupIndicator.GroupIndicatorLeft, T.GROUP_INDICATOR, 0, 0.1875, 0, 1)
		groupIndicator.GroupIndicatorLeft:SetAlpha(0.3)
		groupIndicator.GroupIndicatorRight:SetSize(24, 16)
		SetTexture(groupIndicator.GroupIndicatorRight, T.GROUP_INDICATOR, 0.53125, 0.71875, 0, 1)
		groupIndicator.GroupIndicatorRight:SetAlpha(0.3)
		local middle = groupIndicator:CreateTexture(nil, "BACKGROUND")
		middle:SetHeight(16)
		SetTexture(middle, T.GROUP_INDICATOR, 0.1875, 0.53125, 0, 1)
		middle:SetPoint("LEFT", groupIndicator.GroupIndicatorLeft, "RIGHT")
		middle:SetPoint("RIGHT", groupIndicator.GroupIndicatorRight, "LEFT")
		middle:SetAlpha(0.3)
		groupIndicator.CUIR_Middle = middle
		-- Retail's unnamed middle piece.
		local retailMiddle = select(3, groupIndicator:GetRegions())
		if retailMiddle and retailMiddle ~= PlayerFrameGroupIndicatorText and retailMiddle.SetAlpha then
			retailMiddle:SetAlpha(0)
		end
		Point(PlayerFrameGroupIndicatorText, "LEFT", groupIndicator, "LEFT", 20, -2)
	end

	-- Alternate power bar (e.g. mana for specs whose primary bar is another
	-- resource). It is protected as well, so it gets a mirror too.
	if AlternatePowerBar then
		local alt = AlternatePowerBar
		local altMirror = ns.CreateMirrorBar(alt, level)
		frame.CUIR_AlternatePowerBar = altMirror
		altMirror:SetSize(104, 12)
		Point(altMirror, "BOTTOMLEFT", frame, "BOTTOMLEFT", 76, 15)
		if AlternatePowerBarText then
			Point(AlternatePowerBarText, "CENTER", altMirror, "CENTER", 0, -1)
		end
		if alt.LeftText then Point(alt.LeftText, "LEFT", altMirror, "LEFT", 0, -1) end
		if alt.RightText then Point(alt.RightText, "RIGHT", altMirror, "RIGHT", 0, -1) end

		local background = altMirror:CreateTexture(nil, "BACKGROUND", nil, -8)
		background:SetAllPoints()
		background:SetColorTexture(unpack(ns.C.BACKDROP))

		local border = altMirror:CreateTexture(nil, "OVERLAY")
		border:SetHeight(16)
		SetTexture(border, T.GROUP_INDICATOR, 0.125, 0.250, 1, 0)
		border:SetPoint("TOPLEFT", altMirror, "TOPLEFT", 4, 0)
		border:SetPoint("TOPRIGHT", altMirror, "TOPRIGHT", -4, 0)
		local left = altMirror:CreateTexture(nil, "OVERLAY")
		left:SetSize(16, 16)
		SetTexture(left, T.GROUP_INDICATOR, 0, 0.125, 1, 0)
		left:SetPoint("RIGHT", border, "LEFT")
		local right = altMirror:CreateTexture(nil, "OVERLAY")
		right:SetSize(16, 16)
		SetTexture(right, T.GROUP_INDICATOR, 0.125, 0, 1, 0)
		right:SetPoint("LEFT", border, "RIGHT")
		if alt.PowerBarMask then
			ns.StripMask(alt.PowerBarMask, alt:GetStatusBarTexture(), alt.Spark)
		end
	end

	-- Initial art + hooks that re-apply whenever Blizzard re-lays out the frame.
	if PlayerFrame.state == "vehicle" then
		PlayerFrame_ClassicVehicleArt(frame)
	else
		PlayerFrame_ClassicArt(frame)
	end
	ns.Hook("PlayerFrame_ToPlayerArt", PlayerFrame_ClassicArt)
	ns.Hook("PlayerFrame_ToVehicleArt", PlayerFrame_ClassicVehicleArt)
	ns.Hook("PlayerFrame_UpdatePlayerNameTextAnchor", PlayerFrame_ClassicNameAnchor)
	ns.Hook("PlayerFrame_UpdateLevel", function()
		Point(PlayerLevelText, "CENTER", frame, "CENTER", -62 + PLAYER_OFFSET_X, -17 + PLAYER_OFFSET_Y)
	end)
	ns.Hook("PlayerFrame_UpdatePartyLeader", function()
		Point(contextual.LeaderIcon, "TOPLEFT", frame, "TOPLEFT", 40 + PLAYER_OFFSET_X, -12 + PLAYER_OFFSET_Y)
		Point(contextual.GuideIcon, "TOPLEFT", frame, "TOPLEFT", 40 + PLAYER_OFFSET_X, -12 + PLAYER_OFFSET_Y)
	end)
	ns.Hook("PlayerFrame_UpdatePvPStatus", function()
		local factionGroup = UnitFactionGroup("player")
		if factionGroup == "Alliance" then
			Point(contextual.PVPIcon, "TOPLEFT", frame, "TOPLEFT", 8, -24)
		elseif factionGroup == "Horde" then
			Point(contextual.PVPIcon, "TOPLEFT", frame, "TOPLEFT", -1, -22)
		end
		Point(contextual.PrestigePortrait, "TOPLEFT", frame, "TOPLEFT", 15 + PLAYER_OFFSET_X, -13 + PLAYER_OFFSET_Y)
		Point(contextual.PvpTimerText, "CENTER", frame, "TOPLEFT", 38 + PLAYER_OFFSET_X, -8 + PLAYER_OFFSET_Y)
	end)
	ns.Hook("PlayerFrame_UpdateRolesAssigned", function()
		ApplyClassicRoleIcon(contextual.RoleIcon, "player")
	end)
	ns.Hook("PlayerFrame_UpdateGroupIndicator", function()
		Point(PlayerFrameGroupIndicatorText, "LEFT", contextual.GroupIndicator, "LEFT", 20, -2)
	end)
	ApplyClassicRoleIcon(contextual.RoleIcon, "player")
end

---------------------------------------------------------------------------
-- Target / Focus frames
---------------------------------------------------------------------------

local function TargetFrame_ClassicClassification(self)
	local container = self.TargetFrameContainer
	local main = self.TargetFrameContent.TargetFrameContentMain
	local contextual = self.TargetFrameContent.TargetFrameContentContextual
	local health, power = self.CUIR_HealthBar, self.CUIR_ManaBar
	local classification = UnitClassification(self.unit)

	-- Retail decorations that classic expresses through the frame art itself.
	container.BossPortraitFrameTexture:Hide()
	contextual.BossIcon:Hide()
	main.ReputationColor:Show()

	local texture, flashTexture = T.TARGET_FRAME, T.TARGET_FLASH
	local flashW, flashH, flashCoords, flashX, flashY = 242, 93, { 0, 0.9453125, 0, 0.181640625 }, -4, -4
	self.haveElite = nil

	if classification == "worldboss" or classification == "elite" then
		texture = T.TARGET_ELITE
		flashH, flashCoords, flashX, flashY = 112, { 0, 0.9453125, 0.181640625, 0.400390625 }, -2, 5
		self.haveElite = true
	elseif classification == "rareelite" then
		texture = T.TARGET_RARE_ELITE
		flashH, flashCoords, flashX, flashY = 112, { 0, 0.9453125, 0.181640625, 0.400390625 }, -2, 5
		self.haveElite = true
	elseif classification == "rare" then
		texture = T.TARGET_RARE
		self.haveElite = true
	elseif classification == "minus" then
		texture = T.TARGET_MINUS
		flashTexture, flashW, flashH, flashCoords = T.TARGET_MINUS_FLASH, 256, 128, { 0, 1, 0, 1 }
	end

	container.FrameTexture:SetSize(232, 100)
	SetTexture(container.FrameTexture, texture, 0.09375, 1, 0, 0.78125)
	Point(container.FrameTexture, "TOPLEFT", self, "TOPLEFT", TARGET_OFFSET_X, TARGET_OFFSET_Y)

	container.Flash:SetSize(flashW, flashH)
	SetTexture(container.Flash, flashTexture, unpack(flashCoords))
	Point(container.Flash, "TOPLEFT", self, "TOPLEFT", flashX, flashY)

	-- Bars.
	health:SetSize(119, 12)
	Point(health, "TOPRIGHT", self, "TOPRIGHT", -106 + TARGET_OFFSET_X, -41 + TARGET_OFFSET_Y)
	power:SetSize(119, 12)
	Point(power, "TOPRIGHT", self, "TOPRIGHT", -106 + TARGET_OFFSET_X, -52 + TARGET_OFFSET_Y)

	if classification == "minus" then
		-- Minus mobs have no power bar and a shorter frame.
		self.CUIR_Backdrop:SetSize(119, 12)
		Point(self.CUIR_Backdrop, "TOPRIGHT", self, "TOPRIGHT", -106 + TARGET_OFFSET_X, -41 + TARGET_OFFSET_Y)
		main.ReputationColor:Hide()
	else
		self.CUIR_Backdrop:SetSize(119, 41)
		Point(self.CUIR_Backdrop, "TOPRIGHT", self, "TOPRIGHT", -106 + TARGET_OFFSET_X, -22 + TARGET_OFFSET_Y)
	end
end

local function TargetFrame_ClassicLevel(self)
	local main = self.TargetFrameContent.TargetFrameContentMain
	local contextual = self.TargetFrameContent.TargetFrameContentContextual
	Point(main.LevelText, "CENTER", self, "CENTER", 61 + TARGET_OFFSET_X, -17 + TARGET_OFFSET_Y)
	contextual.HighLevelTexture:SetSize(16, 16)
	SetTexture(contextual.HighLevelTexture, T.SKULL)
	Point(contextual.HighLevelTexture, "CENTER", self, "CENTER", 61 + TARGET_OFFSET_X, -17 + TARGET_OFFSET_Y)
end

local function TargetFrame_ClassicFaction(self)
	local contextual = self.TargetFrameContent.TargetFrameContentContextual
	if self.showPVP then
		local factionGroup = UnitFactionGroup(self.unit)
		if factionGroup == "Alliance" then
			Point(contextual.PvpIcon, "TOPRIGHT", self, "TOPRIGHT", -4, -24)
		elseif factionGroup == "Horde" then
			Point(contextual.PvpIcon, "TOPRIGHT", self, "TOPRIGHT", 3, -22)
		end
		Point(contextual.PrestigePortrait, "TOPRIGHT", self, "TOPRIGHT", -15 + TARGET_OFFSET_X, -13 + TARGET_OFFSET_Y)
	end
end

local function TargetFrame_ClassicPartyLeader(self)
	local contextual = self.TargetFrameContent.TargetFrameContentContextual
	contextual.LeaderIcon:SetSize(16, 16)
	SetTexture(contextual.LeaderIcon, T.LEADER_ICON)
	Point(contextual.LeaderIcon, "TOPRIGHT", self, "TOPRIGHT", -44 + TARGET_OFFSET_X, -10 + TARGET_OFFSET_Y)
	contextual.GuideIcon:SetSize(19, 19)
	SetTexture(contextual.GuideIcon, T.ROLE_ICONS, 0, 0.296875, 0.015625, 0.3125)
	Point(contextual.GuideIcon, "TOPRIGHT", self, "TOPRIGHT", -40 + TARGET_OFFSET_X, -10 + TARGET_OFFSET_Y)
end

local function SkinTargetOfTarget(parent)
	local tot = parent.totFrame
	if not tot then return end

	tot.FrameTexture:SetDrawLayer("ARTWORK", 2)

	ns.StripMask(tot.HealthBar.HealthBarMask, tot.HealthBar:GetStatusBarTexture())
	ns.StripMask(tot.ManaBar.ManaBarMask, tot.ManaBar:GetStatusBarTexture(), tot.ManaBar.Spark)

	tot.CUIR_Backdrop = ns.CreateBackdrop(tot, 46, 15, "BOTTOMLEFT", tot, "BOTTOMLEFT", 45, 20)

	tot.FrameTexture:SetSize(93, 45)
	SetTexture(tot.FrameTexture, T.TOT_FRAME, 0.015625, 0.7265625, 0, 0.703125)
	Point(tot.FrameTexture, "TOPLEFT", tot, "TOPLEFT", 0, 0)

	tot.Portrait:SetSize(35, 35)
	Point(tot.Portrait, "TOPLEFT", tot, "TOPLEFT", 5, -5)
	tot.PortraitMask:ClearAllPoints()
	tot.PortraitMask:SetAllPoints(tot.Portrait)

	tot.Name:SetWidth(100)
	Point(tot.Name, "BOTTOMLEFT", tot, "BOTTOMLEFT", 42, 7)

	-- Mirrors (the art is a region of the button itself at ARTWORK/2, the
	-- mirrors' fills are BACKGROUND, so they draw behind it).
	tot.CUIR_HealthBar, tot.CUIR_ManaBar = CreateBarMirrors(tot, tot.HealthBar, tot.ManaBar)
	tot.CUIR_HealthBar:SetSize(46, 7)
	Point(tot.CUIR_HealthBar, "TOPRIGHT", tot, "TOPRIGHT", -29, -15)
	tot.CUIR_ManaBar:SetSize(46, 7)
	Point(tot.CUIR_ManaBar, "TOPRIGHT", tot, "TOPRIGHT", -29, -23)
	Point(tot.HealthBar.DeadText, "LEFT", tot, "LEFT", 48, 3)
	Point(tot.HealthBar.UnconsciousText, "LEFT", tot, "LEFT", 48, 3)

	local name = tot:GetName()
	local offsets = { { -23, -8 }, { -10, -8 }, { -23, -21 }, { -10, -21 } }
	for i = 1, 4 do
		local debuff = _G[name .. "Debuff" .. i]
		if debuff then
			Point(debuff, "TOPLEFT", tot, "TOPRIGHT", offsets[i][1], offsets[i][2])
		end
	end
end

local function StripTargetStyleMasks(hbc, healthBar, manaBar)
	ns.StripMask(hbc.HealthBarMask,
		healthBar:GetStatusBarTexture(),
		hbc.TempMaxHealthLoss and hbc.TempMaxHealthLoss:GetStatusBarTexture(),
		healthBar.MyHealPredictionBar and healthBar.MyHealPredictionBar.Fill,
		healthBar.OtherHealPredictionBar and healthBar.OtherHealPredictionBar.Fill,
		healthBar.TotalAbsorbBar and healthBar.TotalAbsorbBar.Fill,
		healthBar.TotalAbsorbBar and healthBar.TotalAbsorbBar.TiledFillOverlay,
		healthBar.HealAbsorbBar and healthBar.HealAbsorbBar.Fill,
		healthBar.HealAbsorbBar and healthBar.HealAbsorbBar.LeftShadow,
		healthBar.HealAbsorbBar and healthBar.HealAbsorbBar.RightShadow,
		healthBar.OverAbsorbGlow,
		healthBar.OverHealAbsorbGlow)
	ns.StripMask(manaBar.ManaBarMask, manaBar:GetStatusBarTexture(), manaBar.Spark)
end

local function SkinTargetFrame(frame)
	if not IsTargetStyleFrame(frame) then return end

	local container = frame.TargetFrameContainer
	local main = frame.TargetFrameContent.TargetFrameContentMain
	local contextual = frame.TargetFrameContent.TargetFrameContentContextual
	local hbc = main.HealthBarsContainer
	local healthBar = hbc.HealthBar
	local manaBar = main.ManaBar
	local level = frame:GetFrameLevel()

	-- Art container above the (mirror) bars; flash behind everything.
	container:SetFrameLevel(level + 1)
	container.FrameTexture:SetDrawLayer("BORDER")
	container.Flash:SetParent(frame)
	container.Flash:SetDrawLayer("BACKGROUND", -7)

	StripTargetStyleMasks(hbc, healthBar, manaBar)

	frame.CUIR_Backdrop = ns.CreateBackdrop(frame, 119, 41, "TOPRIGHT", frame, "TOPRIGHT", -106 + TARGET_OFFSET_X, -22 + TARGET_OFFSET_Y)

	-- Mirrors + texts.
	frame.CUIR_HealthBar, frame.CUIR_ManaBar = CreateBarMirrors(frame, healthBar, manaBar, { hbc.TempMaxHealthLoss })
	Point(hbc.HealthBarText, "CENTER", frame.CUIR_HealthBar, "CENTER", 0, 0)
	Point(hbc.LeftText, "LEFT", frame.CUIR_HealthBar, "LEFT", 4, 0)
	Point(hbc.RightText, "RIGHT", frame.CUIR_HealthBar, "RIGHT", -4, 0)
	Point(hbc.DeadText, "CENTER", frame.CUIR_HealthBar, "CENTER", 0, 0)
	Point(hbc.UnconsciousText, "CENTER", frame.CUIR_HealthBar, "CENTER", 0, 0)
	Point(manaBar.ManaBarText, "CENTER", frame.CUIR_ManaBar, "CENTER", 0, 0)
	Point(manaBar.LeftText, "LEFT", frame.CUIR_ManaBar, "LEFT", 4, 0)
	Point(manaBar.RightText, "RIGHT", frame.CUIR_ManaBar, "RIGHT", -4, 0)

	-- Portrait geometry.
	container.Portrait:SetSize(64, 64)
	Point(container.Portrait, "TOPRIGHT", frame, "TOPRIGHT", -42 + TARGET_OFFSET_X, -12 + TARGET_OFFSET_Y)
	container.PortraitMask:ClearAllPoints()
	container.PortraitMask:SetAllPoints(container.Portrait)

	-- Reputation-coloured name background. In classic this sits *under* the
	-- frame art (the art clips its edges), so move it below the art container.
	main.ReputationColor:SetParent(frame)
	main.ReputationColor:SetDrawLayer("BACKGROUND", -6)
	main.ReputationColor:SetSize(119, 19)
	SetTexture(main.ReputationColor, T.LEVEL_BG)
	Point(main.ReputationColor, "TOPRIGHT", frame, "TOPRIGHT", -106 + TARGET_OFFSET_X, -22 + TARGET_OFFSET_Y)

	-- Name.
	main.Name:SetWidth(100)
	main.Name:SetJustifyH("CENTER")
	Point(main.Name, "CENTER", frame, "CENTER", -50 + TARGET_OFFSET_X, 19 + TARGET_OFFSET_Y)

	-- Contextual icons.
	Point(contextual.RaidTargetIcon, "CENTER", frame, "TOPRIGHT", -73 + TARGET_OFFSET_X, -14 + TARGET_OFFSET_Y)
	contextual.QuestIcon:SetSize(32, 32)
	SetTexture(contextual.QuestIcon, T.QUEST_BADGE)
	Point(contextual.QuestIcon, "TOPLEFT", frame, "TOPRIGHT", -120 + TARGET_OFFSET_X, -12 + TARGET_OFFSET_Y)
	contextual.PetBattleIcon:SetSize(32, 32)
	Point(contextual.PetBattleIcon, "CENTER", frame, "RIGHT", -44 + TARGET_OFFSET_X, 10 + TARGET_OFFSET_Y)
	Point(contextual.NumericalThreat, "BOTTOM", frame, "TOP", -50 + TARGET_OFFSET_X, -22 + TARGET_OFFSET_Y)

	TargetFrame_ClassicPartyLeader(frame)
	TargetFrame_ClassicLevel(frame)

	-- Hooks.
	ns.Hook(frame, "CheckClassification", TargetFrame_ClassicClassification)
	ns.Hook(frame, "Update", TargetFrame_ClassicClassification)
	module.reapply[frame] = TargetFrame_ClassicClassification
	ns.Hook(frame, "CheckLevel", TargetFrame_ClassicLevel)
	ns.Hook(frame, "CheckFaction", TargetFrame_ClassicFaction)
	ns.Hook(frame, "CheckPartyLeader", TargetFrame_ClassicPartyLeader)
	ns.Hook(frame, "CheckBattlePet", function(self)
		Point(contextual.PetBattleIcon, "CENTER", self, "RIGHT", -44 + TARGET_OFFSET_X, 10 + TARGET_OFFSET_Y)
	end)
	ns.Hook(frame, "AnchorAuraContainer", function(self)
		local auraContainer = self:GetAuraContainer()
		local mirrored = auraContainer.IsFlowLayoutMirroredVertically and auraContainer:IsFlowLayoutMirroredVertically()
		if not mirrored then
			auraContainer:ClearAllPoints()
			auraContainer:SetPoint("TOPLEFT", self.TargetFrameContainer.FrameTexture, "BOTTOMLEFT", 5, 32)
		end
	end)
	ns.Hook(frame, "UpdateRaidTargetIcon", function(self)
		Point(contextual.RaidTargetIcon, "CENTER", self, "TOPRIGHT", -73 + TARGET_OFFSET_X, -14 + TARGET_OFFSET_Y)
	end)

	-- Lay out once so the frame is right the first time it shows.
	TargetFrame_ClassicClassification(frame)

	-- Target of target.
	SkinTargetOfTarget(frame)
	if frame.totFrame then
		local tot = frame.totFrame
		local function AnchorToT()
			ns:RunOutOfCombat(function()
				if frame == FocusFrame and frame.smallSize then
					Point(tot, "TOPRIGHT", frame, "BOTTOMRIGHT", 20, 29)
				else
					Point(tot, "TOPRIGHT", frame, "BOTTOMRIGHT", 12, 31)
				end
			end)
		end
		AnchorToT()
		if frame == FocusFrame then
			ns.Hook(frame, "SetSmallSize", AnchorToT)
		end
	end
end

---------------------------------------------------------------------------
-- Boss frames
---------------------------------------------------------------------------

local function SkinBossFrame(frame)
	if not IsTargetStyleFrame(frame) then return end

	local container = frame.TargetFrameContainer
	local main = frame.TargetFrameContent.TargetFrameContentMain
	local contextual = frame.TargetFrameContent.TargetFrameContentContextual
	local hbc = main.HealthBarsContainer
	local healthBar = hbc.HealthBar
	local manaBar = main.ManaBar
	local level = frame:GetFrameLevel()

	container:SetFrameLevel(level + 1)
	container.FrameTexture:SetDrawLayer("BORDER")

	StripTargetStyleMasks(hbc, healthBar, manaBar)

	frame.CUIR_Backdrop = ns.CreateBackdrop(frame, 119, 41, "TOPLEFT", frame, "TOPLEFT", 26, -29)

	if frame.threatIndicator then
		local flash = frame.threatIndicator
		flash:SetParent(frame)
		flash:SetDrawLayer("BACKGROUND", -7)
	end
	if frame.threatNumericIndicator then
		Point(frame.threatNumericIndicator, "BOTTOM", frame, "TOP", -65, -28)
	end
	if frame.powerBarAlt then
		Point(frame.powerBarAlt, "RIGHT", frame, "LEFT", 20, -2)
	end

	frame.CUIR_HealthBar, frame.CUIR_ManaBar = CreateBarMirrors(frame, healthBar, manaBar, { hbc.TempMaxHealthLoss })
	Point(hbc.HealthBarText, "CENTER", frame.CUIR_HealthBar, "CENTER", 1, 0)
	Point(hbc.LeftText, "LEFT", frame.CUIR_HealthBar, "LEFT", 2, 0)
	Point(hbc.RightText, "RIGHT", frame.CUIR_HealthBar, "RIGHT", -3, 0)
	Point(hbc.DeadText, "CENTER", frame.CUIR_HealthBar, "CENTER", 1, 0)
	Point(hbc.UnconsciousText, "CENTER", frame.CUIR_HealthBar, "CENTER", 1, 0)
	Point(manaBar.ManaBarText, "CENTER", frame.CUIR_ManaBar, "CENTER", 1, -1)
	Point(manaBar.LeftText, "LEFT", frame.CUIR_ManaBar, "LEFT", 1, -1)
	Point(manaBar.RightText, "RIGHT", frame.CUIR_ManaBar, "RIGHT", -3, -1)

	main.Name:SetWidth(100)
	main.Name:SetJustifyH("CENTER")
	Point(main.Name, "TOPLEFT", container, "TOPLEFT", 36, -33)

	contextual.HighLevelTexture:SetSize(16, 16)
	SetTexture(contextual.HighLevelTexture, T.SKULL)
	Point(contextual.HighLevelTexture, "CENTER", container, "CENTER", 31, -24)
	Point(main.LevelText, "CENTER", container, "CENTER", 31, -24)

	main.ReputationColor:SetParent(frame)
	main.ReputationColor:SetDrawLayer("BACKGROUND", -6)
	main.ReputationColor:SetSize(119, 19)
	SetTexture(main.ReputationColor, T.LEVEL_BG)
	Point(main.ReputationColor, "TOPRIGHT", main, "TOPRIGHT", -88, -29)

	local function ReapplyBoss(self)
		self.TargetFrameContainer.BossPortraitFrameTexture:Hide()
		self.TargetFrameContent.TargetFrameContentContextual.BossIcon:Hide()
		self.TargetFrameContainer.FrameTexture:SetSize(232, 100)
		SetTexture(self.TargetFrameContainer.FrameTexture, T.BOSS_FRAME, 0.09375, 1, 0, 0.78125)
		Point(self.TargetFrameContainer.FrameTexture, "TOPLEFT", self.TargetFrameContainer, "TOPLEFT", 20, -7)
		if self.threatIndicator then
			SetTexture(self.threatIndicator, T.BOSS_FLASH, 0, 0.945, 0, 0.73125)
			self.threatIndicator:SetSize(242, 93)
			Point(self.threatIndicator, "CENTER", self, "CENTER", 1, -3)
		end
		self.CUIR_HealthBar:SetSize(119, 12)
		Point(self.CUIR_HealthBar, "TOPLEFT", self, "TOPLEFT", 26, -48)
		self.CUIR_ManaBar:SetSize(119, 12)
		Point(self.CUIR_ManaBar, "TOPLEFT", self, "TOPLEFT", 26, -58)
	end
	ReapplyBoss(frame)
	ns.Hook(frame, "CheckClassification", ReapplyBoss)
	ns.Hook(frame, "Update", ReapplyBoss)
	module.reapply[frame] = ReapplyBoss
	ns.Hook(frame, "CheckLevel", function()
		Point(main.LevelText, "CENTER", container, "CENTER", 31, -24)
		Point(contextual.HighLevelTexture, "CENTER", container, "CENTER", 31, -24)
	end)
	if frame.spellbar then
		ns.Hook(frame.spellbar, "AdjustPosition", function(self)
			self:ClearAllPoints()
			self:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 44, 4)
		end)
	end
end

---------------------------------------------------------------------------
-- Pet frame (its bars are plain TextStatusBars, not protected)
---------------------------------------------------------------------------

local function SkinPetFrame()
	local frame = PetFrame
	if not frame then return end
	local level = frame:GetFrameLevel()

	ns:RunOutOfCombat(function() frame:SetSize(128, 53) end)

	PetFrameHealthBar:SetFrameLevel(level)
	PetFrameManaBar:SetFrameLevel(level)
	PetFrameTexture:SetDrawLayer("ARTWORK", 1)

	ns.StripMask(PetFrameHealthBarMask,
		PetFrameHealthBar:GetStatusBarTexture(),
		PetFrameMyHealPredictionBar and PetFrameMyHealPredictionBar.Fill,
		PetFrameOtherHealPredictionBar and PetFrameOtherHealPredictionBar.Fill,
		PetFrameTotalAbsorbBar and PetFrameTotalAbsorbBar.Fill,
		PetFrameTotalAbsorbBar and PetFrameTotalAbsorbBar.TiledFillOverlay,
		PetFrameOverAbsorbGlow, PetFrameOverHealAbsorbGlow,
		PetFrameHealAbsorbBar and PetFrameHealAbsorbBar.Fill,
		PetFrameHealAbsorbBar and PetFrameHealAbsorbBar.LeftShadow,
		PetFrameHealAbsorbBar and PetFrameHealAbsorbBar.RightShadow)
	ns.StripMask(PetFrameManaBarMask, PetFrameManaBar:GetStatusBarTexture())

	frame.CUIR_Backdrop = ns.CreateBackdrop(frame, 69, 15, "TOPLEFT", frame, "TOPLEFT", 47, -22)

	PetPortrait:SetSize(37, 37)
	Point(PetPortrait, "TOPLEFT", frame, "TOPLEFT", 7, -6)
	if frame.PortraitMask then
		frame.PortraitMask:ClearAllPoints()
		frame.PortraitMask:SetAllPoints(PetPortrait)
	end

	PetName:SetWidth(0)
	Point(PetName, "BOTTOMLEFT", frame, "BOTTOMLEFT", 52, 33)

	PetFrameTexture:SetSize(128, 64)
	SetTexture(PetFrameTexture, T.SMALL_FRAME)
	Point(PetFrameTexture, "TOPLEFT", frame, "TOPLEFT", 0, -2)

	PetFrameFlash:SetSize(128, 64)
	SetTexture(PetFrameFlash, T.PARTY_FLASH, 0, 1, 1, 0)
	Point(PetFrameFlash, "TOPLEFT", frame, "TOPLEFT", -4, 11)
	PetFrameFlash:SetDrawLayer("BACKGROUND", -7)

	PetFrameHealthBar:SetSize(69, 8)
	Point(PetFrameHealthBar, "TOPLEFT", frame, "TOPLEFT", 47, -22)
	PetFrameManaBar:SetSize(69, 8)
	Point(PetFrameManaBar, "TOPLEFT", frame, "TOPLEFT", 47, -29)

	Point(PetFrameHealthBarText, "CENTER", PetFrameHealthBar, "CENTER", 0, 0)
	Point(PetFrameHealthBarTextLeft, "LEFT", PetFrameHealthBar, "LEFT", 0, 0)
	Point(PetFrameHealthBarTextRight, "RIGHT", PetFrameHealthBar, "RIGHT", 0, 0)
	Point(PetFrameManaBarText, "CENTER", PetFrameManaBar, "CENTER", 0, 0)
	Point(PetFrameManaBarTextLeft, "LEFT", PetFrameManaBar, "LEFT", 0, 0)
	Point(PetFrameManaBarTextRight, "RIGHT", PetFrameManaBar, "RIGHT", 0, 0)

	PetAttackModeTexture:SetSize(76, 64)
	SetTexture(PetAttackModeTexture, T.PET_ATTACK, 0.703125, 1, 0, 1)
	Point(PetAttackModeTexture, "TOPLEFT", frame, "TOPLEFT", 6, -9)

	Point(PetHitIndicator, "CENTER", frame, "TOPLEFT", 28, -27)
end

---------------------------------------------------------------------------
-- Party frames
---------------------------------------------------------------------------

local function SkinPartyMemberFrame(frame)
	local hbc = frame.HealthBarContainer
	local healthBar = hbc.HealthBar
	local manaBar = frame.ManaBar
	local overlay = frame.PartyMemberOverlay

	frame.Texture:SetSize(128, 64)
	SetTexture(frame.Texture, T.PARTY_FRAME)
	Point(frame.Texture, "TOPLEFT", frame, "TOPLEFT", 0, -10)
	frame.Texture:SetDrawLayer("ARTWORK", 7)
	-- The name shares the button's ARTWORK layer with the frame art; keep it on top.
	frame.Name:SetDrawLayer("OVERLAY")

	frame.VehicleTexture:SetSize(128, 64)
	SetTexture(frame.VehicleTexture, T.VEHICLE_PARTY)
	Point(frame.VehicleTexture, "TOPLEFT", frame, "TOPLEFT", -8, -2)
	frame.VehicleTexture:SetDrawLayer("ARTWORK", 7)

	Point(frame.Portrait, "TOPLEFT", frame, "TOPLEFT", 7, -14)
	frame.PortraitMask:ClearAllPoints()
	frame.PortraitMask:SetAllPoints(frame.Portrait)

	local function StripPartyMasks()
		ns.StripMask(hbc.HealthBarMask,
			healthBar:GetStatusBarTexture(),
			hbc.TempMaxHealthLoss and hbc.TempMaxHealthLoss:GetStatusBarTexture(),
			healthBar.MyHealPredictionBar and healthBar.MyHealPredictionBar.Fill,
			healthBar.OtherHealPredictionBar and healthBar.OtherHealPredictionBar.Fill,
			healthBar.TotalAbsorbBar and healthBar.TotalAbsorbBar.Fill,
			healthBar.TotalAbsorbBar and healthBar.TotalAbsorbBar.TiledFillOverlay,
			healthBar.HealAbsorbBar and healthBar.HealAbsorbBar.Fill,
			healthBar.HealAbsorbBar and healthBar.HealAbsorbBar.LeftShadow,
			healthBar.HealAbsorbBar and healthBar.HealAbsorbBar.RightShadow,
			healthBar.OverAbsorbGlow, healthBar.OverHealAbsorbGlow, healthBar.Background)
		ns.StripMask(manaBar.ManaBarMask, manaBar:GetStatusBarTexture())
	end
	StripPartyMasks()
	if healthBar.Background then healthBar.Background:Hide() end

	frame.CUIR_Backdrop = ns.CreateBackdrop(frame, 72, 20, "TOPLEFT", frame, "TOPLEFT", 45, -19)

	-- Mirrors + texts.
	frame.CUIR_HealthBar, frame.CUIR_ManaBar = CreateBarMirrors(frame, healthBar, manaBar, { hbc.TempMaxHealthLoss })
	frame.CUIR_HealthBar:SetSize(70, 8)
	Point(frame.CUIR_HealthBar, "TOPLEFT", frame, "TOPLEFT", 47, -22)
	frame.CUIR_ManaBar:SetSize(70, 8)
	Point(frame.CUIR_ManaBar, "TOPLEFT", frame, "TOPLEFT", 47, -31)
	local function AnchorTexts()
		Point(hbc.CenterText, "CENTER", frame.CUIR_HealthBar, "CENTER", 0, 0)
		Point(hbc.LeftText, "LEFT", frame.CUIR_HealthBar, "LEFT", 0, 0)
		Point(hbc.RightText, "RIGHT", frame.CUIR_HealthBar, "RIGHT", 0, 0)
		Point(manaBar.CenterText, "CENTER", frame.CUIR_ManaBar, "CENTER", 0, 0)
		Point(manaBar.LeftText, "LEFT", frame.CUIR_ManaBar, "LEFT", 0, 0)
		Point(manaBar.RightText, "RIGHT", frame.CUIR_ManaBar, "RIGHT", 0, 0)
	end
	AnchorTexts()

	Point(frame.NotPresentIcon, "LEFT", frame, "RIGHT", 1, -3)

	overlay.LeaderIcon:SetSize(16, 16)
	SetTexture(overlay.LeaderIcon, T.LEADER_ICON)
	Point(overlay.LeaderIcon, "TOPLEFT", frame, "TOPLEFT", 0, -8)
	overlay.GuideIcon:SetSize(19, 19)
	SetTexture(overlay.GuideIcon, T.ROLE_ICONS, 0, 0.296875, 0.015625, 0.3125)
	Point(overlay.GuideIcon, "TOPLEFT", frame, "TOPLEFT", 0, -8)
	Point(overlay.PVPIcon, "TOPLEFT", frame, "TOPLEFT", -9, -23)
	overlay.RoleIcon:SetSize(19, 19)
	Point(overlay.Disconnect, "LEFT", frame, "LEFT", -7, -10)

	-- Blizzard anchors the role icon's TOPRIGHT on every art change (since
	-- Forever 1.60.1 build 70425), which would stretch it from our TOPLEFT.
	local function AnchorRoleIcon()
		Point(overlay.RoleIcon, "TOPLEFT", frame, "TOPLEFT", 7, -41)
	end
	AnchorRoleIcon()

	local function ClassicPlayerArt(self)
		SetTexture(self.Texture, T.PARTY_FRAME)
		self.Texture:SetSize(128, 64)
		Point(self.Texture, "TOPLEFT", self, "TOPLEFT", 0, -10)

		self.Flash:SetSize(128, 64)
		SetTexture(self.Flash, T.PARTY_FLASH)
		Point(self.Flash, "TOPLEFT", self, "TOPLEFT", -3, -6)
		self.Flash:SetDrawLayer("BACKGROUND", -7)

		overlay.Status:SetSize(36, 36)
		SetTexture(overlay.Status, "Interface\\Buttons\\UI-Debuff-Overlays", 0, 0.2734375, 0, 0.5625)
		Point(overlay.Status, "CENTER", self.Portrait, "CENTER", 0, 0)
		overlay.Status:SetDrawLayer("ARTWORK", 0)
		AnchorTexts()
		AnchorRoleIcon()
	end
	local function ClassicVehicleArt(self)
		self.VehicleTexture:SetSize(128, 64)
		SetTexture(self.VehicleTexture, T.VEHICLE_PARTY)
		Point(self.VehicleTexture, "TOPLEFT", self, "TOPLEFT", -8, -2)
		AnchorTexts()
		AnchorRoleIcon()
	end

	ns.Hook(frame, "ToPlayerArt", ClassicPlayerArt)
	ns.Hook(frame, "ToVehicleArt", ClassicVehicleArt)
	-- Setup() runs every time the party frame is shown and re-adds the masks.
	ns.Hook(frame, "Setup", StripPartyMasks)
	ns.Hook(frame, "UpdateHealthBarTextAnchors", AnchorTexts)
	ns.Hook(frame, "UpdateManaBarTextAnchors", AnchorTexts)
	ns.Hook(frame, "UpdateNameTextAnchors", function(self)
		self.Name:SetWidth(0)
		Point(self.Name, "TOPLEFT", self, "TOPLEFT", 49, -7)
	end)
	ns.Hook(frame, "UpdateAssignedRoles", function(self)
		ApplyClassicRoleIcon(overlay.RoleIcon, self:GetUnit())
	end)
	ns.Hook(frame, "UpdateNotPresentIcon", function(self)
		if self.NotPresentIcon.texture and UnitInOtherParty(self:GetUnit()) then
			SetTexture(self.NotPresentIcon.texture, T.LFG_EYE, 0.125, 0.25, 0.25, 0.5)
		end
	end)

	-- Party pet frames (plain, unprotected bars).
	local pet = frame.PetFrame
	if pet then
		local petLevel = pet:GetFrameLevel()
		pet.HealthBar:SetFrameLevel(petLevel)
		-- Retail draws the pet art and bar at half scale; classic uses plain sizes.
		pet.Texture:SetScale(1)
		pet.Texture:SetSize(64, 32)
		SetTexture(pet.Texture, T.PARTY_FRAME)
		Point(pet.Texture, "TOPLEFT", pet, "TOPLEFT", 0, -1)
		pet.Texture:SetDrawLayer("ARTWORK", 7)
		pet.Flash:SetScale(1)
		pet.Flash:SetSize(64, 32)
		SetTexture(pet.Flash, T.PARTY_FLASH)
		Point(pet.Flash, "TOPLEFT", pet, "TOPLEFT", -1, 1)
		pet.Flash:SetDrawLayer("BACKGROUND", -7)
		Point(pet.Portrait, "TOPLEFT", pet, "TOPLEFT", 3, -3)
		pet.PortraitMask:ClearAllPoints()
		pet.PortraitMask:SetAllPoints(pet.Portrait)
		Point(pet.Name, "BOTTOMLEFT", pet, "BOTTOMLEFT", 25, 21)
		pet.HealthBar:SetScale(1)
		pet.HealthBar:SetSize(35, 4)
		Point(pet.HealthBar, "TOPLEFT", pet, "TOPLEFT", 23, -6)
		if pet.HealthBar.HealthBarMask then
			ns.StripMask(pet.HealthBar.HealthBarMask, pet.HealthBar:GetStatusBarTexture())
		end
	end

	if frame.state == "vehicle" then
		ClassicVehicleArt(frame)
	else
		ClassicPlayerArt(frame)
	end
end

local function SkinPartyFrames()
	if not PartyFrame or not PartyFrame.PartyMemberFramePool then return end
	for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
		if not frame.CUIR_Skinned then
			frame.CUIR_Skinned = true
			SkinPartyMemberFrame(frame)
		end
	end
end

---------------------------------------------------------------------------
-- Spell bars follow the classic frame geometry
---------------------------------------------------------------------------

local function AdjustTargetSpellBar(self)
	local parent = self:GetParent()
	local _, relativeTo = self:GetPoint()
	if relativeTo == parent then
		if parent.haveToT then
			self:AdjustPointsOffset(2, 22)
		elseif parent.haveElite then
			self:AdjustPointsOffset(2, -14)
		else
			self:AdjustPointsOffset(2, -2)
		end
	else
		self:AdjustPointsOffset(2, -5)
	end
end

---------------------------------------------------------------------------
-- Module entry point
---------------------------------------------------------------------------

-- Target-style frames re-layout on target changes through hooks on
-- CheckClassification/Update; this event frame re-applies the classic layout
-- as well, independently of Blizzard's call chain.
module.reapply = {}
local function ReapplyTargetFrames()
	for frame, fn in pairs(module.reapply) do
		if frame:IsShown() then
			xpcall(fn, geterrorhandler(), frame)
		end
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, unit)
	if event == "UNIT_CLASSIFICATION_CHANGED" and unit ~= "target" and unit ~= "focus" and not (type(unit) == "string" and unit:match("^boss%d")) then
		return
	end
	ReapplyTargetFrames()
end)

function module:Apply()
	for _, event in ipairs({ "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "UNIT_CLASSIFICATION_CHANGED", "INSTANCE_ENCOUNTER_ENGAGE_UNIT", "PLAYER_ENTERING_WORLD" }) do
		eventFrame:RegisterEvent(event)
	end

	SkinPlayerFrame()
	SkinTargetFrame(TargetFrame)
	SkinTargetFrame(FocusFrame)

	if TargetFrame and TargetFrame.spellbar then
		ns.Hook(TargetFrame.spellbar, "AdjustPosition", AdjustTargetSpellBar)
	end
	if FocusFrame and FocusFrame.spellbar then
		ns.Hook(FocusFrame.spellbar, "AdjustPosition", AdjustTargetSpellBar)
	end

	if BossTargetFrameContainer and BossTargetFrameContainer.BossTargetFrames then
		for _, frame in pairs(BossTargetFrameContainer.BossTargetFrames) do
			SkinBossFrame(frame)
		end
	end

	SkinPetFrame()

	SkinPartyFrames()
	if PartyFrame then
		ns.Hook(PartyFrame, "UpdateMemberFrames", SkinPartyFrames)
		ns.Hook(PartyFrame, "InitializePartyMemberFrames", SkinPartyFrames)
	end
end
