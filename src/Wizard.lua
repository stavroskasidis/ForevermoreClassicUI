--[[
	Forevermore Classic UI - Setup wizard

	Shown when the login loading screen goes away until it has been closed once (new
	installs, and existing users after updating), and on demand with "/fmcui setup" or the options page's Setup Wizard button:
	  * a welcome page with three one-click presets (everything classic,
	    classic HUD with modern windows, the reverse; see UI.PRESETS, the
	    windows are the WINDOWS options) and a "Custom" tile;
	  * one page per group of options (at most three a page), each option
	    with a Modern and a Classic picture (ns.Previews): the look clicked
	    is the one used;
	  * a summary page, with a reload button when a reload-type option
	    changed.

	Choices are saved as they are made (ns:SetModuleEnabled), like on the
	options page: live modules switch at once, the others wait for the reload
	offered at the end. Closing the wizard at any point keeps what was chosen
	so far and marks the setup as done (db.setupDone).

	The wizard is the addon's own frame, not a UI panel: it is never shown or
	hidden through ShowUIPanel / HideUIPanel, and Esc is caught on the frame
	itself instead of through UISpecialFrames, whose entries Blizzard's
	secure ToggleGameMenu reads.

	The widgets shared with the options page (classic buttons, the Modern /
	Classic switch, preview cards, the option groups) are in ns.UI.
]]

local _, ns = ...

local UI = {}
ns.UI = UI

UI.ICON = "Interface\\AddOns\\" .. ns.ADDON_NAME .. "\\Icon.png"

---------------------------------------------------------------------------
-- Option groups and short descriptions
---------------------------------------------------------------------------

local GROUPS = {
	{ title = "Unit Frames", text = "The frames of you, your target, your party and bosses, the bars that go with them and your buffs.",
		keys = { "unitframes", "combopoints", "castbars", "buffs" } },
	{ title = "Nameplates & Timers", text = "The bars over the heads of the creatures around you, and the breath and fatigue timers.",
		keys = { "nameplates", "mirrortimers" } },
	{ title = "Action Bars", text = "The bars your spells live on, their gryphons, the XP bar over them and the bags next to them.",
		keys = { "actionbars", "endcaps", "xpbar", "bags" } },
	{ title = "Menus", text = "The micro menu buttons and the menu that opens with Esc.",
		keys = { "micromenu", "gamemenu" } },
	{ title = "Minimap", text = "The minimap cluster and the group finder eye.",
		keys = { "minimap", "groupfindereye" } },
	{ title = "Your Character", text = "Your character window, spellbook, talents, quest log and the quests you track.",
		keys = { "characterframe", "spellbook", "talents", "questlog", "questtracker" } },
	{ title = "Out in the World", text = "Looting and rolling on loot, training, the bank, finding a group, your friends, and the vendor, mail, quest and other windows.",
		keys = { "lootframe", "lootroll", "windows", "trainer", "bank", "lfgframe", "socialframe" } },
	{ title = "Trade", text = "The auction house and your professions.",
		keys = { "auctionhouse", "professions" } },
}

local SUMMARIES = {
	unitframes = "The classic player, target, focus, party and boss frames, with round portraits and flat health and power bars.",
	combopoints = "Combo points down the side of the target's portrait instead of in an arc over its top.",
	castbars = "The classic cast bar: its border, spark and colours.",
	buffs = "Your buffs without the modern arrow that folds them away: every buff shows, as in classic.",
	nameplates = "The classic nameplate: its border, a flat health bar and the level in its bubble.",
	mirrortimers = "The classic breath, fatigue and feign death bars.",
	actionbars = "Square button borders and the embossed vanilla bar behind the main bar's buttons.",
	endcaps = "The vanilla stone gryphons at both ends of the main action bar.",
	xpbar = "The segmented vanilla XP bar, purple or blue while rested, and the reputation bar in its standing's colour.",
	bags = "Square bag slots with the vanilla backpack, and the vanilla bag windows.",
	micromenu = "The classic micro menu buttons.",
	gamemenu = "The vanilla Esc menu: the dialog box with the small red buttons.",
	minimap = "The round classic minimap with its zone bar, zoom buttons, clock and compass ring.",
	groupfindereye = "The animated classic eye in a round minimap button.",
	characterframe = "The vanilla character window: the paperdoll, resistances and stat boxes, with the tabs under it, and the matching inspect window.",
	spellbook = "The vanilla spellbook: twelve spells a page, with the skill line tabs down its side.",
	talents = "The vanilla talent frame: one painted tree at a time, with square talents and rank boxes.",
	questlog = "The vanilla quest log window: the quest list with zone headers over the quest's details, opened with the quest log key.",
	questtracker = "The vanilla quest watch: compact gold titles and objectives, without the modern header plates, quest markers, glows and check marks.",
	lootframe = "The vanilla loot panel with the skull and the classic item rows.",
	lootroll = "The vanilla need / greed box: dice, coin and close buttons, gold for bind on pickup items.",
	windows = "The pre-Dragonflight metal frame, round close button and classic tabs on the vendor, mail, quest, trade and other windows.",
	trainer = "The vanilla trainer window with the colour-coded skill list.",
	lfgframe = "The classic Looking For Group window: the LFG panel with the eye in its ring, the classic role icons and the tabs under it.",
	socialframe = "The classic social window: the friends list frame with the Battle.net bar in its stone band and the tabs under it.",
	bank = "The vanilla bank window: the stone panel with its riveted slot wells, the bag slot row and the money bar.",
	auctionhouse = "The vanilla auction house: the classic panel, filter column and Bid / Buyout buttons.",
	professions = "The vanilla trade skill window: the rank bar, the compact recipe list and the reagents below it.",
}

function UI.GetSummary(module)
	return SUMMARIES[module.key] or module.tooltip or ""
end

-- The groups with the top-level options this client has, in order; options
-- no group lists end up in "Other".
function UI.GetGroups()
	local groups, listed = {}, {}
	for _, group in ipairs(GROUPS) do
		local modules = {}
		for _, key in ipairs(group.keys) do
			local module = ns.moduleByKey[key]
			if module and not module.parent then
				table.insert(modules, module)
				listed[key] = true
			end
		end
		if #modules > 0 then
			table.insert(groups, { title = group.title, text = group.text, modules = modules })
		end
	end
	local others = {}
	for _, module in ipairs(ns.modules) do
		if not module.parent and not listed[module.key] then
			table.insert(others, module)
		end
	end
	if #others > 0 then
		table.insert(groups, { title = "Other", text = "More classic elements.", modules = others })
	end
	return groups
end

function UI.GetTopLevelModules()
	local modules = {}
	for _, group in ipairs(UI.GetGroups()) do
		for _, module in ipairs(group.modules) do
			table.insert(modules, module)
		end
	end
	return modules
end

function UI.SetAll(enabled)
	for _, module in ipairs(UI.GetTopLevelModules()) do
		ns:SetModuleEnabled(module.key, enabled)
	end
end

-- The options that restyle a window (everything else is part of the HUD),
-- for the presets.
local WINDOWS = {
	gamemenu = true, characterframe = true, spellbook = true, talents = true, questlog = true, lootframe = true, lootroll = true,
	windows = true, trainer = true, auctionhouse = true, professions = true, lfgframe = true,
	socialframe = true,
}

function UI.IsWindow(module)
	return WINDOWS[module.key] == true
end

-- The welcome page's presets: which looks the HUD and the windows get.
UI.PRESETS = {
	{ title = "Everything classic", text = "Every element in its classic look (recommended).", hud = true, windows = true },
	{ title = "Classic HUD, modern windows", text = "Classic frames, bars and minimap; the windows keep their modern look.", hud = true, windows = false },
	{ title = "Classic windows, modern HUD", text = "Classic character, spellbook, trade and other windows; a modern HUD.", hud = false, windows = true },
	-- Not a preset: opens the page-by-page choice.
	{ title = "Custom", text = "Pick and choose which parts of the UI to convert to Classic.", choose = true },
}

local function PresetLook(preset, module)
	if UI.IsWindow(module) then
		return preset.windows
	end
	return preset.hud
end

function UI.ApplyPreset(preset)
	for _, module in ipairs(UI.GetTopLevelModules()) do
		ns:SetModuleEnabled(module.key, PresetLook(preset, module))
	end
end

-- True when the options are set exactly as the preset sets them.
function UI.IsPresetActive(preset)
	for _, module in ipairs(UI.GetTopLevelModules()) do
		if ns:IsEnabled(module.key) ~= PresetLook(preset, module) then
			return false
		end
	end
	return true
end

function UI.ApplyNote(module)
	if module.live then
		return "|cff33ff99Applies at once|r"
	end
	return "|cffffd200Applies after a UI reload|r"
end

-- The option's full description, for tooltips.
function UI.ShowModuleTooltip(owner, module)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetText(module.name, 1, 0.82, 0)
	GameTooltip:AddLine(module.tooltip or UI.GetSummary(module), 1, 1, 1, true)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(UI.ApplyNote(module), 1, 1, 1, true)
	GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Widgets
---------------------------------------------------------------------------

UI.DIALOG_BACKDROP = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

UI.CARD_BACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 14,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
local CARD_BACKDROP = UI.CARD_BACKDROP

local GOLD = { 1, 0.82, 0 }
local DIM = { 0.45, 0.45, 0.45 }

-- A classic red panel button of any size.
function UI.CreateButton(parent, text, width, height, onClick)
	local button = CreateFrame("Button", nil, parent)
	ns.SkinPanelTextButton(button, text)
	button:SetSize(width or 120, height or 22)
	if onClick then
		button:SetScript("OnClick", onClick)
	end
	return button
end

-- The vanilla dialog header plate (UI-DialogBox-Header) sized to its text:
-- the plate's ends at 1:1 with its middle stretched between them.
function UI.CreateHeader(frame, text)
	local header = CreateFrame("Frame", nil, frame)
	header:SetFrameLevel(frame:GetFrameLevel() + 30)
	local label = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetText(text)
	label:SetPoint("TOP", header, "TOP", 0, -14)
	local width = math.max(label:GetStringWidth() + 70, 132)
	header:SetSize(width, 64)
	header:SetPoint("TOP", frame, "TOP", 0, 12)
	local file = "Interface\\DialogFrame\\UI-DialogBox-Header"
	local left = header:CreateTexture(nil, "ARTWORK")
	left:SetTexture(file)
	left:SetTexCoord(0.2421875, 0.390625, 0, 1)
	left:SetSize(38, 64)
	left:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 0)
	local right = header:CreateTexture(nil, "ARTWORK")
	right:SetTexture(file)
	right:SetTexCoord(0.609375, 0.7578125, 0, 1)
	right:SetSize(38, 64)
	right:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, 0)
	local middle = header:CreateTexture(nil, "ARTWORK")
	middle:SetTexture(file)
	middle:SetTexCoord(0.390625, 0.609375, 0, 1)
	middle:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
	middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT", 0, 0)
	return header
end

-- The classic round close button; hides `frame` (a plain frame, never a UI panel).
function UI.CreateCloseButton(frame)
	local close = CreateFrame("Button", nil, frame)
	ns.SkinCloseButton(close)
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
	close:SetFrameLevel(frame:GetFrameLevel() + 30)
	close:SetScript("OnClick", function() frame:Hide() end)
	return close
end

-- A two-way switch: [Modern][Classic]. The active side is a lit red button,
-- the other a greyed one. onChange(classic) runs on clicks.
function UI.CreateSwitch(parent, onChange)
	local switch = CreateFrame("Frame", nil, parent)
	switch:SetSize(144, 22)
	local sides = {}
	for i, look in ipairs({ "modern", "classic" }) do
		local side = CreateFrame("Button", nil, switch)
		side:SetSize(72, 22)
		side:SetPoint("LEFT", switch, "LEFT", (i - 1) * 72, 0)
		local art = side:CreateTexture(nil, "BACKGROUND")
		art:SetAllPoints(side)
		art:SetTexCoord(0, 0.625, 0, 0.6875)
		side.art = art
		side:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
		side:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)
		local text = side:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		text:SetPoint("CENTER", side, "CENTER", 0, 1)
		text:SetText(look == "classic" and "Classic" or "Modern")
		side.text = text
		side:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			onChange(look == "classic")
		end)
		sides[look] = side
	end
	function switch:SetValue(classic)
		for look, side in pairs(sides) do
			local active = (look == "classic") == classic
			side.art:SetTexture("Interface\\Buttons\\UI-Panel-Button-" .. (active and "Up" or "Disabled"))
			side.text:SetFontObject(active and GameFontHighlightSmall or GameFontDisableSmall)
		end
	end
	return switch
end

-- A clickable picture of one look of an option, framed like a tooltip. The
-- selected card gets a gold border and a check mark, the other one dims.
function UI.CreatePreviewCard(parent, key, look, width, height)
	local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
	card:SetSize(width, height)
	card:SetBackdrop(CARD_BACKDROP)
	card:SetBackdropColor(0, 0, 0, 0.8)

	local label = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -6)
	label:SetText(look == "classic" and "Classic" or "Modern")

	local area = CreateFrame("Frame", nil, card)
	area:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -20)
	area:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -5, 5)
	area:SetClipsChildren(true)
	local canvas = ns.CreatePreview(area, key, look)
	if canvas then
		ns.FitPreview(canvas, width - 10, height - 25)
	else
		local none = area:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		none:SetPoint("CENTER", area, "CENTER", 0, 0)
		none:SetText("No preview")
	end

	local overlay = CreateFrame("Frame", nil, card)
	overlay:SetAllPoints(card)
	overlay:SetFrameLevel(card:GetFrameLevel() + 100)
	local check = overlay:CreateTexture(nil, "OVERLAY")
	check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	check:SetSize(22, 22)
	check:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -3, 0)

	local selected, hovered = false, false
	local function Update()
		local color = selected and GOLD or (hovered and { 0.8, 0.8, 0.8 } or DIM)
		card:SetBackdropBorderColor(color[1], color[2], color[3])
		label:SetTextColor(selected and GOLD[1] or 0.7, selected and GOLD[2] or 0.7, selected and GOLD[3] or 0.7)
		check:SetShown(selected)
		area:SetAlpha((selected or hovered) and 1 or 0.55)
	end
	card:SetScript("OnEnter", function() hovered = true Update() end)
	card:SetScript("OnLeave", function() hovered = false Update() end)
	function card:SetSelected(value)
		selected = value
		Update()
	end
	Update()
	return card
end

---------------------------------------------------------------------------
-- Wizard
---------------------------------------------------------------------------

local WIDTH, HEIGHT = 780, 600
local ROWS_PER_PAGE = 3
local TEXT_WIDTH = 250
local CARD_WIDTH, CARD_HEIGHT = 226, 128
local ROW_HEIGHT = 140

local wizard, content
local pages, current
local footer = {}

local function BuildPageList()
	local list = { { kind = "welcome" } }
	for _, group in ipairs(UI.GetGroups()) do
		local parts = math.ceil(#group.modules / ROWS_PER_PAGE)
		for part = 1, parts do
			local modules = {}
			for i = (part - 1) * ROWS_PER_PAGE + 1, math.min(part * ROWS_PER_PAGE, #group.modules) do
				table.insert(modules, group.modules[i])
			end
			local title = parts > 1 and string.format("%s (%d/%d)", group.title, part, parts) or group.title
			table.insert(list, { kind = "group", title = title, text = group.text, modules = modules })
		end
	end
	table.insert(list, { kind = "done" })
	return list
end

local function PageFrame()
	local frame = CreateFrame("Frame", nil, content)
	frame:SetAllPoints(content)
	return frame
end

local function WrappedText(parent, font, width, justify)
	local text = parent:CreateFontString(nil, "OVERLAY", font)
	text:SetWidth(width)
	text:SetJustifyH(justify or "LEFT")
	text:SetJustifyV("TOP")
	return text
end

local ShowPage

local TILE_WIDTH, TILE_HEIGHT = 356, 146
local SAMPLE_WIDTH, SAMPLE_HEIGHT = 160, 70

-- The window each preset tile pictures: the first this client has.
local function SampleWindowKey()
	for _, key in ipairs({ "spellbook", "characterframe", "lootframe", "gamemenu" }) do
		if ns.moduleByKey[key] then return key end
	end
end

-- A preset: its name, what it does, and pictures of a HUD element (the unit
-- frames) and a window in the looks it gives them. The preset the options
-- currently match is marked.
local function CreatePresetTile(parent, preset)
	local tile = CreateFrame("Button", nil, parent, "BackdropTemplate")
	tile:SetSize(TILE_WIDTH, TILE_HEIGHT)
	tile:SetBackdrop(CARD_BACKDROP)
	tile:SetBackdropColor(0.12, 0.08, 0.02, 0.9)

	local name = tile:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	name:SetPoint("TOPLEFT", tile, "TOPLEFT", 12, -10)
	name:SetText(preset.title)
	local text = WrappedText(tile, "GameFontHighlightSmall", TILE_WIDTH - 24)
	text:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -5)
	text:SetText(preset.text)

	-- The choose tile shows both looks of the unit frames instead.
	local samples = preset.choose and { { "unitframes", false }, { "unitframes", true } }
		or { { "unitframes", preset.hud }, { SampleWindowKey(), preset.windows } }
	for i, sample in ipairs(samples) do
		if sample[1] then
			local area = CreateFrame("Frame", nil, tile)
			area:SetSize(SAMPLE_WIDTH, SAMPLE_HEIGHT)
			area:SetPoint("BOTTOMLEFT", tile, "BOTTOMLEFT", 12 + (i - 1) * (SAMPLE_WIDTH + 12), 10)
			area:SetClipsChildren(true)
			local canvas = ns.CreatePreview(area, sample[1], sample[2] and "classic" or "modern")
			if canvas then
				ns.FitPreview(canvas, SAMPLE_WIDTH, SAMPLE_HEIGHT)
			end
		end
	end

	local overlay = CreateFrame("Frame", nil, tile)
	overlay:SetAllPoints(tile)
	overlay:SetFrameLevel(tile:GetFrameLevel() + 100)
	local check = overlay:CreateTexture(nil, "OVERLAY")
	check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	check:SetSize(22, 22)
	check:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", -4, -2)
	local current = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	current:SetPoint("RIGHT", check, "LEFT", 0, 0)
	current:SetText("Current")

	local active, hovered = false, false
	local function Update()
		local color = (active or hovered) and GOLD or { 0.8, 0.65, 0.2 }
		if hovered and not active then color = { 1, 1, 1 } end
		tile:SetBackdropBorderColor(color[1], color[2], color[3])
		check:SetShown(active)
		current:SetShown(active)
	end
	tile:SetScript("OnEnter", function() hovered = true Update() end)
	tile:SetScript("OnLeave", function() hovered = false Update() end)
	tile:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
		if preset.choose then
			ShowPage(2)
			return
		end
		UI.ApplyPreset(preset)
		ShowPage(#pages)
	end)
	function tile:Refresh()
		active = not preset.choose and UI.IsPresetActive(preset)
		Update()
	end
	return tile
end

local function BuildWelcome(page)
	local frame = PageFrame()

	local icon = frame:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(UI.ICON)
	icon:SetSize(48, 48)
	icon:SetPoint("TOP", frame, "TOP", 0, -2)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	title:SetPoint("TOP", icon, "BOTTOM", 0, -6)
	title:SetText("Welcome to " .. ns.TITLE)

	local text = WrappedText(frame, "GameFontHighlight", 680, "CENTER")
	text:SetPoint("TOP", title, "BOTTOM", 0, -8)
	text:SetText("The classic look on Blizzard's own frames: every feature and Edit Mode keep working.")

	-- "Choose a preset" between two gold rules as wide as the tiles.
	local heading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	heading:SetPoint("TOP", frame, "TOP", 0, -108)
	heading:SetText("Choose a preset")
	for _, side in ipairs({ -1, 1 }) do
		local rule = frame:CreateTexture(nil, "ARTWORK")
		rule:SetColorTexture(1, 0.82, 0, 0.35)
		rule:SetHeight(1)
		if side < 0 then
			rule:SetPoint("LEFT", frame, "TOP", -(TILE_WIDTH + 5), -116)
			rule:SetPoint("RIGHT", heading, "LEFT", -10, 0)
		else
			rule:SetPoint("LEFT", heading, "RIGHT", 10, 0)
			rule:SetPoint("RIGHT", frame, "TOP", TILE_WIDTH + 5, -116)
		end
	end

	-- The presets, two by two.
	page.tiles = {}
	for i, preset in ipairs(UI.PRESETS) do
		local column, row = (i - 1) % 2, math.floor((i - 1) / 2)
		local tile = CreatePresetTile(frame, preset)
		local y = -134 - row * (TILE_HEIGHT + 10)
		if column == 0 then
			tile:SetPoint("TOPRIGHT", frame, "TOP", -5, y)
		else
			tile:SetPoint("TOPLEFT", frame, "TOP", 5, y)
		end
		table.insert(page.tiles, tile)
	end

	local skip = CreateFrame("Button", nil, frame)
	skip:SetSize(220, 24)
	skip:SetPoint("TOP", frame, "TOP", 0, -134 - 2 * (TILE_HEIGHT + 10) - 6)
	local skipText = skip:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	skipText:SetPoint("CENTER", skip, "CENTER", 0, 0)
	skipText:SetText("Skip for now")
	skip:SetScript("OnEnter", function() skipText:SetFontObject(GameFontHighlight) end)
	skip:SetScript("OnLeave", function() skipText:SetFontObject(GameFontDisable) end)
	skip:SetScript("OnClick", function() wizard:Hide() end)

	local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetPoint("BOTTOM", frame, "BOTTOM", 0, 2)
	hint:SetText("Type /fmcui setup to come back here, or /fmcui for the options.")

	function page:Refresh()
		for _, tile in ipairs(self.tiles) do
			tile:Refresh()
		end
	end

	page.frame = frame
end

local function BuildGroupPage(page)
	local frame = PageFrame()

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	title:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
	title:SetText(page.title)
	local text = WrappedText(frame, "GameFontHighlight", WIDTH - 60)
	text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	text:SetText(page.text .. " Click the look you want.")

	page.cards = {}
	for i, module in ipairs(page.modules) do
		local y = -64 - (i - 1) * ROW_HEIGHT

		local info = CreateFrame("Frame", nil, frame)
		info:SetSize(TEXT_WIDTH, CARD_HEIGHT)
		info:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, y)
		info:EnableMouse(true)
		info:SetScript("OnEnter", function(self) UI.ShowModuleTooltip(self, module) end)
		info:SetScript("OnLeave", GameTooltip_Hide)
		local name = info:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		name:SetPoint("TOPLEFT", info, "TOPLEFT", 0, -4)
		name:SetText(module.name)
		local note = info:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		note:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
		note:SetText(UI.ApplyNote(module))
		local summary = WrappedText(info, "GameFontHighlightSmall", TEXT_WIDTH)
		summary:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -8)
		summary:SetText(UI.GetSummary(module))

		for column, look in ipairs({ "modern", "classic" }) do
			local card = UI.CreatePreviewCard(frame, module.key, look, CARD_WIDTH, CARD_HEIGHT)
			card:SetPoint("TOPLEFT", frame, "TOPLEFT", TEXT_WIDTH + 20 + (column - 1) * (CARD_WIDTH + 12), y)
			card:SetScript("OnClick", function()
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
				ns:SetModuleEnabled(module.key, look == "classic")
			end)
			card.module, card.look = module, look
			table.insert(page.cards, card)
		end
	end

	function page:Refresh()
		for _, card in ipairs(self.cards) do
			card:SetSelected(ns:IsEnabled(card.module.key) == (card.look == "classic"))
		end
	end

	page.frame = frame
end

local function BuildDone(page)
	local frame = PageFrame()

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	title:SetPoint("TOP", frame, "TOP", 0, -8)
	title:SetText("All set!")
	local count = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	count:SetPoint("TOP", title, "BOTTOM", 0, -8)

	-- Every option with its look, in two columns.
	local modules = UI.GetTopLevelModules()
	local perColumn = math.ceil(#modules / 2)
	local rows = {}
	for i, module in ipairs(modules) do
		local column, row = math.floor((i - 1) / perColumn), (i - 1) % perColumn
		local x, y = 90 + column * 320, -70 - row * 20
		local name = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		name:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
		name:SetText(module.name)
		local look = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		look:SetPoint("TOPRIGHT", frame, "TOPLEFT", x + 260, y)
		rows[module] = look
	end

	local listBottom = -70 - perColumn * 20
	local reloadText = WrappedText(frame, "GameFontHighlight", 560, "CENTER")
	reloadText:SetPoint("TOP", frame, "TOP", 0, listBottom - 18)
	local reload = UI.CreateButton(frame, RELOADUI or "Reload UI", 180, 28, function() ReloadUI() end)
	reload:SetPoint("TOP", reloadText, "BOTTOM", 0, -12)

	local hint = WrappedText(frame, "GameFontDisableSmall", 600, "CENTER")
	hint:SetPoint("BOTTOM", frame, "BOTTOM", 0, 4)
	hint:SetText("Change any of this in the options (Esc > Options > AddOns > " .. ns.TITLE .. ", or /fmcui), or run this setup again with /fmcui setup.")

	function page:Refresh()
		local classic = 0
		for module, look in pairs(rows) do
			local enabled = ns:IsEnabled(module.key)
			if enabled then classic = classic + 1 end
			look:SetText(enabled and "Classic" or "Modern")
			look:SetTextColor(enabled and GOLD[1] or DIM[1], enabled and GOLD[2] or DIM[2], enabled and GOLD[3] or DIM[3])
		end
		count:SetText(string.format("%d of %d elements use the classic look.", classic, #modules))
		if ns:NeedsReload() then
			reloadText:SetText("Some of your choices change frames that are set up when the interface loads. Reload the interface to see them.")
			reload:Show()
		else
			reloadText:SetText("Everything you chose is already on screen.")
			reload:Hide()
		end
	end

	page.frame = frame
end

local BUILDERS = { welcome = BuildWelcome, group = BuildGroupPage, done = BuildDone }

local function UpdateFooter()
	local page = pages[current]
	local groupPages = #pages - 2
	footer.back:SetShown(page.kind ~= "welcome")
	footer.step:SetShown(page.kind == "group")
	footer.step:SetText(string.format("Step %d of %d", current - 1, groupPages))
	if page.kind == "welcome" then
		footer.next:Hide()
	elseif page.kind == "done" then
		footer.next:SetText("Options")
		footer.next:Show()
	else
		footer.next:SetText(current == #pages - 1 and "Finish" or "Next")
		footer.next:Show()
	end
	footer.close:SetShown(page.kind == "done")
end

function ShowPage(index)
	current = index
	for i, page in ipairs(pages) do
		if i == index and not page.frame then
			BUILDERS[page.kind](page)
		end
		if page.frame then
			page.frame:SetShown(i == index)
		end
	end
	local page = pages[index]
	if page.Refresh then page:Refresh() end
	UpdateFooter()
end

local function RefreshCurrent()
	local page = wizard and wizard:IsShown() and pages[current]
	if page and page.Refresh then page:Refresh() end
end

local function CreateWizard()
	wizard = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	wizard:SetSize(WIDTH, HEIGHT)
	wizard:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
	-- Above the settings panel it can be opened from.
	wizard:SetFrameStrata("FULLSCREEN_DIALOG")
	wizard:SetToplevel(true)
	wizard:SetClampedToScreen(true)
	wizard:EnableMouse(true)
	wizard:SetMovable(true)
	wizard:RegisterForDrag("LeftButton")
	wizard:SetScript("OnDragStart", wizard.StartMoving)
	wizard:SetScript("OnDragStop", wizard.StopMovingOrSizing)
	wizard:SetBackdrop(UI.DIALOG_BACKDROP)
	-- The dark dialog background is see-through; a solid layer under it keeps
	-- the game (and any menu) behind the wizard from showing through.
	local solid = wizard:CreateTexture(nil, "BACKGROUND", nil, -8)
	solid:SetColorTexture(0.03, 0.03, 0.03, 0.96)
	solid:SetPoint("TOPLEFT", wizard, "TOPLEFT", 11, -12)
	solid:SetPoint("BOTTOMRIGHT", wizard, "BOTTOMRIGHT", -12, 11)
	-- The rest of the screen is dimmed while it is open (a picture only: it
	-- takes no mouse input).
	local dimmer = CreateFrame("Frame", nil, UIParent)
	dimmer:SetAllPoints(UIParent)
	dimmer:SetFrameStrata("FULLSCREEN_DIALOG")
	dimmer:SetFrameLevel(math.max(wizard:GetFrameLevel() - 1, 0))
	dimmer:Hide()
	local shade = dimmer:CreateTexture(nil, "BACKGROUND")
	shade:SetAllPoints(dimmer)
	shade:SetColorTexture(0, 0, 0, 0.5)
	wizard:HookScript("OnShow", function() dimmer:Show() end)
	wizard:HookScript("OnHide", function() dimmer:Hide() end)
	UI.CreateHeader(wizard, ns.TITLE .. " Setup")
	UI.CreateCloseButton(wizard)

	-- Esc closes it. Keyboard propagation cannot be changed in combat, so it
	-- is left on there (Esc then also opens the game menu) and switched off
	-- only for the Esc press itself.
	ns:RunOutOfCombat(function()
		wizard:EnableKeyboard(true)
		wizard:SetPropagateKeyboardInput(true)
	end)
	wizard:SetScript("OnKeyDown", function(self, key)
		if key ~= "ESCAPE" then return end
		if not InCombatLockdown() then
			self:SetPropagateKeyboardInput(false)
			C_Timer.After(0, function()
				if not InCombatLockdown() then self:SetPropagateKeyboardInput(true) end
			end)
		end
		self:Hide()
	end)
	wizard:HookScript("OnHide", function()
		ns.db.setupDone = true
		PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
	end)

	content = CreateFrame("Frame", nil, wizard)
	content:SetPoint("TOPLEFT", wizard, "TOPLEFT", 20, -30)
	content:SetPoint("BOTTOMRIGHT", wizard, "BOTTOMRIGHT", -20, 52)

	footer.back = UI.CreateButton(wizard, "Back", 110, 24, function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
		ShowPage(math.max(1, current - 1))
	end)
	footer.back:SetPoint("BOTTOMLEFT", wizard, "BOTTOMLEFT", 22, 20)
	footer.next = UI.CreateButton(wizard, "Next", 110, 24, function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
		if pages[current].kind == "done" then
			wizard:Hide()
			ns:OpenOptions()
		else
			ShowPage(current + 1)
		end
	end)
	footer.next:SetPoint("BOTTOMRIGHT", wizard, "BOTTOMRIGHT", -22, 20)
	footer.close = UI.CreateButton(wizard, CLOSE or "Close", 110, 24, function() wizard:Hide() end)
	footer.close:SetPoint("RIGHT", footer.next, "LEFT", -8, 0)
	footer.step = wizard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	footer.step:SetPoint("BOTTOM", wizard, "BOTTOM", 0, 26)

	ns:OnSettingsChanged(RefreshCurrent)
end

function ns:OpenSetup()
	if not wizard then
		CreateWizard()
	end
	if not pages then
		pages = BuildPageList()
	end
	ShowPage(1)
	wizard:Show()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
end
