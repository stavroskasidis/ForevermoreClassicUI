--[[
	Forevermore Classic UI - WoW Forever adjustments

	WoW Forever (client 1.60.x, Interface 16001) runs the retail "mainline" UI
	code with a "camelot" game-type overlay (wow-ui-source branch `forever`:
	Blizzard_UnitFrame\Camelot\* and Blizzard_NamePlates\Camelot\*). Every
	frame, region and function the shared modules hook is the same as on
	retail, so those modules are used unchanged. The overlay only adds a few
	elements the shared modules do not know about; they are handled here:

	  * Player, target, focus and boss frames show the level in a small circle
	    (<ContentMain>.LevelBackgroundCircle, large white font) in the bottom
	    corner of the frame. Classic shows it in the frame art's own circle,
	    where the shared Unit Frames module already anchors the level text.
	  * PvP status is a small faction circle (PvpBackgroundCircle +
	    PvpBackgroundIcon: in PlayerFrameContentMain on the player frame, in
	    TargetFrameContentContextual on target-style frames). The retail
	    PVPIcon/PrestigePortrait regions that the shared module repositions
	    still exist but are never shown on Forever. Classic used the big 64x64
	    "Interface\TargetingFrame\UI-PVP-*" banners; they are used when the
	    client still has them, otherwise Blizzard's small icon is moved to
	    the classic spot.
	  * The minimap frame is re-skinned by MinimapCluster:UpdateMinimapConfig
	    (Blizzard_Minimap\Camelot\Minimap.lua) at load and on every "rotate
	    minimap" change (container/backdrop size, compass atlas, a static ring
	    underlay in the rotated mode); the classic art is re-applied after it.
	    Camelot also adds a day/night indicator
	    (MinimapCluster.DielFrame) at the top right of the map, where classic
	    has the calendar; it is shrunk to the size of the classic round
	    buttons and moved onto the ring left of the clock. Its default
	    Edit Mode layout also puts the group finder eye on the map's edge,
	    which is moved to the classic eye's spot (the classic eye from the
	    Group Finder Eye option is drawn at the map's scale there).

	Everything here runs *after* the shared modules: this file is listed last
	in the .toc, and hooks on the same function fire in installation order.
]]

local _, ns = ...
if not ns.IS_FOREVER then return end
local T = ns.T
local Point, SetTexture = ns.Point, ns.SetTexture

-- Same classic art offsets as the shared UnitFrames module.
local PLAYER_OFFSET_X, PLAYER_OFFSET_Y = -19, -4
local TARGET_OFFSET_X, TARGET_OFFSET_Y = 20, -4

T.PVP_ALLIANCE = "Interface\\TargetingFrame\\UI-PVP-Alliance"
T.PVP_HORDE    = "Interface\\TargetingFrame\\UI-PVP-Horde"
T.PVP_FFA      = "Interface\\TargetingFrame\\UI-PVP-FFA"

-- Camelot PvP atlas (as set by Blizzard right before our hooks run) -> classic banner.
local CLASSIC_PVP_FILES = {
	["ui-hud-unitframe-smallcircle-alliance"] = T.PVP_ALLIANCE,
	["ui-hud-unitframe-smallcircle-horde"]    = T.PVP_HORDE,
	["ui-hud-unitframe-player-pvp-ffaicon"]   = T.PVP_FFA,
}

local module = ns:RegisterModule({
	key = "forever",
	name = "WoW Forever adjustments",
	parent = "unitframes",
	live = false,
})

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

-- The legacy banner files may or may not ship with the Forever client;
-- GetFileIDFromPath answers that without drawing a broken texture.
local fileExists = {}
local function TextureExists(path)
	if fileExists[path] == nil then
		local id = GetFileIDFromPath and GetFileIDFromPath(path)
		fileExists[path] = (type(id) == "number" and id > 0)
	end
	return fileExists[path]
end

-- In instances a unit's identity is secret and Blizzard sets its PvP icon
-- from secret values (UnitFrameUtil: shown state and atlas), so neither can
-- be tested here.
local function IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value)
end

-- Classic banner for the atlas Blizzard just put on a Camelot PvP icon, or
-- nil when the icon is not carrying a Camelot atlas (already classic) or the
-- banner file is missing.
local function ClassicBannerFor(icon)
	local atlas = icon:GetAtlas()
	if IsSecret(atlas) or type(atlas) ~= "string" then return nil, nil end
	local file = CLASSIC_PVP_FILES[atlas:lower()]
	if file and TextureExists(file) then
		return file, atlas
	end
	return nil, atlas
end

-- Level text in the frame art's circle: no Camelot background circle and the
-- classic number font instead of the large white one.
local function ClassicLevelText(text, circle)
	if circle then
		circle:Hide()
	end
	if text and GameNormalNumberFont then
		text:SetFontObject(GameNormalNumberFont)
	end
end

---------------------------------------------------------------------------
-- Player frame
---------------------------------------------------------------------------

-- Camelot colours the player level white; classic is gold (green while scaled).
local function ClassicPlayerLevelColor()
	if UnitExists("player") and UnitEffectiveLevel("player") == UnitLevel("player") then
		PlayerLevelText:SetVertexColor(1.0, 0.82, 0.0, 1.0)
	end
end

local function ClassicPlayerPvPIcon()
	local main = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
	local icon, circle = main.PvpBackgroundIcon, main.PvpBackgroundCircle
	if not icon or not circle then return end

	circle:Hide()
	local shown = icon:IsShown()
	if IsSecret(shown) then
		-- The banner cannot be chosen; Blizzard's small icon, if shown, goes
		-- to the classic spot.
		icon:SetScale(1)
		Point(icon, "CENTER", PlayerFrame, "TOPLEFT", 50 + PLAYER_OFFSET_X, -52 + PLAYER_OFFSET_Y)
		return
	end
	if not shown then return end

	local file, atlas = ClassicBannerFor(icon)
	if not file and not atlas then return end -- already classic

	icon:SetScale(1)
	if file then
		SetTexture(icon, file)
		icon:SetSize(64, 64)
		Point(icon, "TOPLEFT", PlayerFrame, "TOPLEFT", 18 + PLAYER_OFFSET_X, -20 + PLAYER_OFFSET_Y)
	else
		-- Keep Blizzard's small icon, centred where the classic banner sits.
		Point(icon, "CENTER", PlayerFrame, "TOPLEFT", 50 + PLAYER_OFFSET_X, -52 + PLAYER_OFFSET_Y)
	end
	if PlayerPVPTimerText then
		Point(PlayerPVPTimerText, "CENTER", PlayerFrame, "TOPLEFT", 38 + PLAYER_OFFSET_X, -8 + PLAYER_OFFSET_Y)
	end
end

local function SkinPlayerFrame()
	local main = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
	ClassicLevelText(PlayerLevelText, main.LevelBackgroundCircle)
	ns.Hook("PlayerFrame_UpdateLevel", ClassicPlayerLevelColor)
	ClassicPlayerLevelColor()
	ns.Hook("PlayerFrame_UpdatePvPStatus", ClassicPlayerPvPIcon)
	ClassicPlayerPvPIcon()
end

---------------------------------------------------------------------------
-- Target / focus / boss frames
---------------------------------------------------------------------------

local function ClassicTargetPvPIcon(frame)
	local contextual = frame.TargetFrameContent.TargetFrameContentContextual
	local icon, circle = contextual.PvpBackgroundIcon, contextual.PvpBackgroundCircle
	if not icon or not circle then return end

	circle:Hide()
	local shown = icon:IsShown()
	if IsSecret(shown) then
		icon:SetScale(1)
		Point(icon, "CENTER", frame, "TOPRIGHT", -29 + TARGET_OFFSET_X, -52 + TARGET_OFFSET_Y)
		return
	end
	if not shown then return end

	local file, atlas = ClassicBannerFor(icon)
	if not file and not atlas then return end

	icon:SetScale(1)
	if file then
		SetTexture(icon, file)
		icon:SetSize(64, 64)
		Point(icon, "TOPRIGHT", frame, "TOPRIGHT", 3 + TARGET_OFFSET_X, -20 + TARGET_OFFSET_Y)
	else
		Point(icon, "CENTER", frame, "TOPRIGHT", -29 + TARGET_OFFSET_X, -52 + TARGET_OFFSET_Y)
	end
end

local function SkinTargetStyleFrame(frame, hasPvP)
	if not frame or not frame.TargetFrameContent then return end
	local main = frame.TargetFrameContent.TargetFrameContentMain
	ClassicLevelText(main.LevelText, main.LevelBackgroundCircle)
	if hasPvP then
		ns.Hook(frame, "CheckFaction", ClassicTargetPvPIcon)
		ClassicTargetPvPIcon(frame)
	end
end

---------------------------------------------------------------------------
-- Module entry point (unit frame part; follows the Unit Frames option)
---------------------------------------------------------------------------

function module:Apply()
	SkinPlayerFrame()
	SkinTargetStyleFrame(TargetFrame, true)
	SkinTargetStyleFrame(FocusFrame, true)
	if BossTargetFrameContainer and BossTargetFrameContainer.BossTargetFrames then
		for _, frame in pairs(BossTargetFrameContainer.BossTargetFrames) do
			SkinTargetStyleFrame(frame, false)
		end
	end
end

---------------------------------------------------------------------------
-- Minimap part (follows the Minimap option)
---------------------------------------------------------------------------

local minimapPart = ns:RegisterModule({
	key = "forever_minimap",
	name = "WoW Forever minimap adjustments",
	parent = "minimap",
	live = false,
})

-- Puts the classic art back after the camelot skin resized the container and
-- backdrop and swapped the compass atlas; its ring underlay is not part of
-- the classic look.
local function ReapplyClassicMinimap()
	local shared = ns.moduleByKey.minimap
	if shared and shared.ReapplyArt then
		shared:ReapplyArt()
	end
	if MinimapCompassTextureUnderlay then
		MinimapCompassTextureUnderlay:Hide()
	end
end

-- The indicator's ring is 38px of its 42px frame; drawn at the size of the
-- classic round buttons' ~30px rings.
local DIEL_SCALE = 30 / 38

-- Camelot anchors the day/night indicator to the container and undoes the
-- container's scale on it from its own MinimapCluster:SetEditModeScale;
-- inside the backdrop it is scaled with the map instead. It sits on the ring
-- between the group finder eye and the clock, mirroring the zoom-out button
-- (the right of the ring is the screen edge in the default layout). Offsets
-- are in its own (scaled) units.
local function AnchorDielFrame()
	local diel = MinimapCluster.DielFrame
	if not diel then return end
	diel:SetScale(DIEL_SCALE)
	Point(diel, "CENTER", Minimap, "CENTER", -43 / DIEL_SCALE, -66 / DIEL_SCALE)
end

-- Camelot's default Edit Mode position for the group finder eye is the edge
-- of the retail-sized map (Minimap CENTER -68,-68, scaled with the map),
-- which on the classic map is on the ring. While the eye is in its default
-- position it goes to the classic spot instead (the centre of 9.2's 33px
-- QueueStatusMinimapButton at TOPLEFT 22,-100 of MinimapBackdrop), where the
-- classic eye (Group Finder Eye option) is drawn at the map's scale like the
-- other ring buttons and the modern eye keeps Blizzard's size; a position
-- picked in Edit Mode is left alone. The button stays parented to UIParent,
-- where Edit Mode scales and saves it, so the offset is converted into its
-- own scale and the eye's Size setting still applies on top of the map's.
local function AnchorQueueStatusButton()
	local button = QueueStatusButton
	local eye = ns.moduleByKey.groupfindereye
	if not button or not button.IsInDefaultPosition or not eye then return end
	if not button:IsInDefaultPosition() then
		eye:SetEyeScale(1)
		return
	end
	local mapScale = MinimapBackdrop:GetEffectiveScale()
	eye:SetEyeScale(mapScale / button:GetParent():GetEffectiveScale())
	local scale = mapScale / button:GetEffectiveScale()
	Point(button, "CENTER", MinimapBackdrop, "TOPLEFT", 38.5 * scale, -116.5 * scale)
end

-- Blizzard's own minimap scale callback holds the unhooked UpdateDefaultAnchor
-- (registered at load), so the scale change is followed from here.
local function OnMinimapScaleChanged()
	AnchorDielFrame()
	AnchorQueueStatusButton()
end

function minimapPart:Apply()
	if not MinimapCluster or not MinimapBackdrop or not MinimapCompassTexture then return end

	ReapplyClassicMinimap()
	-- The rotate CVar callback calls it as a method of the cluster.
	ns.Hook(MinimapCluster, "UpdateMinimapConfig", ReapplyClassicMinimap)

	if MinimapCluster.DielFrame then
		MinimapCluster.DielFrame:SetParent(MinimapBackdrop)
		AnchorDielFrame()
	end

	if QueueStatusButton then
		AnchorQueueStatusButton()
		-- Edit Mode applies the default position through UpdateDefaultAnchor
		-- (also on reset to default); the eye's Size setting only rescales it.
		ns.Hook(QueueStatusButton, "UpdateDefaultAnchor", AnchorQueueStatusButton)
		ns.Hook(QueueStatusButton, "UpdateSystemSettingSize", AnchorQueueStatusButton)
	end

	ns.Hook(MinimapCluster, "SetEditModeScale", OnMinimapScaleChanged)

	-- Camelot's player coordinates sit right under the map, where the
	-- classic clock plate (Minimap CENTER 0,-75, 28px tall) now is.
	local coords = MinimapCluster.MinimapContainer.PlayerCoords
	if coords then
		Point(coords, "TOP", Minimap, "CENTER", 0, -92)
	end
end
