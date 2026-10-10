--[[
	Forevermore Classic UI - Quest Log

	The vanilla (1.x) quest log window. The modern client has no quest log
	window: the quest log key and micro button open the world map with the
	quest list in its side panel (QuestMapFrame), so unlike the addon's other
	options this is a window of the addon's own, not a Blizzard frame
	re-skinned. It is the 1.x QuestLogFrame (Classic Era's
	Vanilla\QuestLogFrame.xml) in the pre-Dragonflight window frame of the
	Window Frames option (ns.CreateClassicBorder, on the rock background,
	with the quest log book in the portrait ring; the client's own
	UI-QuestLog-* art is a later all-dark redraw with no parchment): a dark
	box for the list and a parchment box (QuestBG-Parchment) for the
	details, filled from Blizzard's quest log API. Everything it does goes
	through Blizzard's own functions:

	  * the list: every quest log entry but hidden ones and world / bonus
	    (task) quests; the zone headers as +/- rows, all expanded at first
	    (the window keeps its own collapsed headers, see BuildEntries), with
	    the "All" tab over the list to collapse or expand them all; the
	    titles in their difficulty colour with the
	    (Complete) / (Failed) / elite tag, the party members on the quest and
	    the tracked check, the selected one on the tinted highlight bar. A
	    click selects, a shift-click links it into an open chat box or tracks
	    / untracks it,
	  * the details: Blizzard's own renderer, QuestInfo_Display with the quest
	    log template (as its QuestLogPopupDetailFrame does), on the parchment
	    pane. Its elements are shared with the quest giver window, the map's
	    quest details and the popup, so they are only drawn here while none
	    of those is shown and drawn again when they close,
	  * Abandon Quest / Share Quest / Track Quest call Blizzard's
	    QuestMapQuestOptions_* (the map's own quest menu).

	It opens from the quest log key (override bindings on the key's keys
	click a named button: a binding can only click a button by name, the one
	global this file adds; they are set out of combat) and from the micro
	button (a button over it; the micro button's own click would open the
	map). The world map keeps its quest panel. It is not a UI panel (addon
	code may not show one in combat): it opens at the left panel spot, can
	be dragged, and closes on Esc through its own keyboard handler, as the
	setup wizard does (in combat Esc also opens the game menu).

	Like the game's own quest log, it shares the screen with no other
	window. Any Blizzard UI panel that opens (ShowUIPanel) closes it, and
	opening it closes every open one: addon code may not hide a UI panel,
	so the quest log key's button and the micro button's are secure macro
	buttons that /click the standard close button of every panel Blizzard's
	panel manager knows (UIPanelWindows; clicking a closed panel's close
	button does nothing), rebuilt out of combat as Blizzard's addons load,
	and toggle the log after that (PostClick). The map's close button has no
	name, so a named secure proxy clicks it. All the /click lines are in the
	one macro: a macro /clicking another macro button does not run it. The
	interaction
	windows are also ended through the game's own call (CloseQuest,
	CloseLoot, ...), which covers the loot window, whose close button runs
	a callback of its own.
	Applied at login (reload to switch off).
]]

local _, ns = ...
local T = ns.T
local Point, SetTexture = ns.Point, ns.SetTexture

T.ROCK_BACKGROUND    = "Interface\\FrameGeneral\\UI-Background-Rock"
T.QUESTLOG_ICON      = "Interface\\QuestFrame\\UI-QuestLog-BookIcon"
T.QUESTLOG_SORT_TAB  = "Interface\\QuestFrame\\UI-QuestLogSortTab-" -- + Left / Middle / Right
T.QUESTLOG_HIGHLIGHT = "Interface\\QuestFrame\\UI-QuestLogTitleHighlight"
T.PLUS_BUTTON        = "Interface\\Buttons\\UI-PlusButton-"          -- + Up / Down / Hilight
T.MINUS_BUTTON       = "Interface\\Buttons\\UI-MinusButton-"         -- + Up / Down
T.CHECK_MARK         = "Interface\\Buttons\\UI-CheckBox-Check"
T.RADIO_BUTTON       = "Interface\\Buttons\\UI-RadioButton"
T.INPUT_BORDER       = "Interface\\Common\\Common-Input-Border"

local module = ns:RegisterModule({
	key = "questlog",
	name = "Quest Log",
	tooltip = "Restores the vanilla quest log window: the quest list with the collapsible zone headers and the difficulty colours on top, the quest's objectives, description and rewards on the parchment below, and the Abandon / Share / Track buttons. It opens from the quest log key and the micro button; the world map keeps its own quest list.",
	live = false,
})

local TOGGLE_BUTTON_NAME = "ForevermoreClassicUIQuestLogButton"

-- The window: the title bar and a band for the "All" tab, the Track radio
-- and the quest count, then the list box (six 1.12 title rows: 16px rows
-- 15px apart), the details box and the button row, in the metal frame's
-- 6px side margins. The details' scroll child fits QuestInfo's 285px log
-- template; each box has its scroll bar inside its right edge.
local FRAME_WIDTH, FRAME_HEIGHT = 338, 452
local BOX_LEFT, BOX_RIGHT = 6, -6
local LIST_TOP, LIST_HEIGHT = -58, 98
local DETAIL_TOP, DETAIL_BOTTOM = LIST_TOP - LIST_HEIGHT - 4, 28
local BOX_INSET, SCROLL_BAR_ROOM = 4, 22
local ROW_HEIGHT = 15
local TITLE_WIDTH = 275 -- a title with its tag
local HIGHLIGHT_WIDTH = 293

local frame, list, detail
local Update -- defined with the list
local Place, UpdateMicroButton, CloseInteractions -- defined with the window
local art = {}
local entries = {}  -- the shown log entries (C_QuestLog.GetInfo tables)
local collapsedHeaders = {} -- [header title] = true, collapsed in the window
local selectedQuestID

---------------------------------------------------------------------------
-- Quest data
---------------------------------------------------------------------------

local function IsListed(info)
	return info and not info.isHidden and (info.isHeader or not (info.isTask or info.isBounty))
end

-- The game's collapsed headers (isCollapsed, ExpandQuestHeader /
-- CollapseQuestHeader) are the world map's: its quest list collapses every
-- header not on the map it shows whenever it refreshes
-- (QuestMapFrame_ResetFilters), so read from there the log opened with
-- every zone collapsed (seen 2026-10-10). The window keeps its own for the
-- session instead, every header expanded at first like 1.12's.
local function IsCollapsed(info)
	return collapsedHeaders[info.title] == true
end

-- The entries shown, without headers left empty by the quests skipped. A
-- collapsed header's quests stay in the log (the 12.x API only flags the
-- header), so they are skipped here.
local function BuildEntries()
	wipe(entries)
	local numEntries = C_QuestLog.GetNumQuestLogEntries()
	local pending, collapsed
	for index = 1, numEntries do
		local info = C_QuestLog.GetInfo(index)
		if IsListed(info) then
			if info.isHeader then
				pending = info
				collapsed = IsCollapsed(info)
				if collapsed then
					table.insert(entries, info)
					pending = nil
				end
			elseif not collapsed then
				if pending then
					table.insert(entries, pending)
					pending = nil
				end
				table.insert(entries, info)
			end
		end
	end
end

local function FirstQuestID()
	for _, info in ipairs(entries) do
		if not info.isHeader then return info.questID end
	end
	return nil
end

local function IsInList(questID)
	for _, info in ipairs(entries) do
		if not info.isHeader and info.questID == questID then return true end
	end
	return false
end

local function QuestTag(info)
	local questID = info.questID
	if C_QuestLog.IsFailed and C_QuestLog.IsFailed(questID) then
		return FAILED
	elseif C_QuestLog.IsComplete(questID) then
		return COMPLETE
	end
	local tagInfo = C_QuestLog.GetQuestTagInfo(questID)
	return tagInfo and tagInfo.tagName or nil
end

-- 1.x listed the titles two spaces in, without a level. The level goes in
-- front when the game shows it on the map's quest list too (its Show Quest
-- Levels filter, or colour blind mode: QuestMapFrameOverrides.GetQuestTitlePrefix).
local LEVEL_CVARS = { showquestlevel = true, colorblindmode = true }

local function TitleText(info)
	local title = info.title or ""
	if GetCVarBool("showQuestLevel") or GetCVarBool("colorblindMode") then
		local level = info.difficultyLevel or info.level
		if level then title = "[" .. level .. "] " .. title end
	end
	return "  " .. title
end

local function DifficultyColor(info)
	if info.isHeader then
		return QuestDifficultyColors.header
	end
	return GetQuestDifficultyColor(info.difficultyLevel or info.level)
end

local function PartyMembersOnQuest(questID)
	local count = 0
	if C_QuestLog.IsUnitOnQuest then
		for i = 1, GetNumSubgroupMembers() do
			if C_QuestLog.IsUnitOnQuest("party" .. i, questID) then
				count = count + 1
			end
		end
	end
	return count
end

---------------------------------------------------------------------------
-- Details (Blizzard's QuestInfo)
---------------------------------------------------------------------------

-- The frames that draw QuestInfo's shared elements themselves.
local function QuestInfoInUse()
	if QuestFrame and QuestFrame:IsShown() then return true end
	if QuestLogPopupDetailFrame and QuestLogPopupDetailFrame:IsShown() then return true end
	local mapDetails = QuestMapFrame and QuestMapFrame.DetailsFrame
	return mapDetails ~= nil and mapDetails:IsVisible()
end

-- While another window draws them, the elements it took are gone from the
-- pane and the ones it does not use (the objectives list) would be left
-- behind, so the pane's content is hidden and a note shown instead.
local function UpdateDetails(resetScroll)
	if not frame:IsShown() or not selectedQuestID then return end
	local busy = QuestInfoInUse()
	detail.child:SetShown(not busy)
	art.detailBusy:SetShown(busy)
	if busy then return end
	C_QuestLog.SetSelectedQuest(selectedQuestID)
	-- QuestInfo reads the quest and its seal background from the scroll
	-- child's grandparent (this window).
	frame.questID = selectedQuestID
	QuestInfo_Display(QUEST_TEMPLATE_LOG, detail.child)
	if resetScroll then
		detail:SetVerticalScroll(0)
	end
end

---------------------------------------------------------------------------
-- The list
---------------------------------------------------------------------------

local function UpdateButtons()
	local questID = selectedQuestID
	art.abandon:SetEnabled(questID ~= nil and C_QuestLog.CanAbandonQuest(questID))
	art.share:SetEnabled(questID ~= nil and C_QuestLog.IsPushableQuest(questID) and IsInGroup())
	local watched = questID ~= nil and QuestUtils_IsQuestWatched and QuestUtils_IsQuestWatched(questID)
	art.trackCheck:SetShown(watched == true)
	art.track:SetEnabled(questID ~= nil)
end

local function SetRowTextColor(row, color)
	row.tag:SetTextColor(color.r, color.g, color.b)
	row.party:SetTextColor(color.r, color.g, color.b)
end

local function InitRow(row, info)
	row.info = info
	local color = DifficultyColor(info)
	row.color = color
	local font = color.font and _G[color.font]
	if font then row:SetNormalFontObject(font) end

	row.party:SetText("")
	row.check:Hide()
	row.selected:Hide()
	if info.isHeader then
		row:SetText(info.title or "")
		row.tag:SetText("")
		local file = (IsCollapsed(info) and T.PLUS_BUTTON or T.MINUS_BUTTON) .. "Up"
		row.expand:SetTexture(file)
		row.expand:Show()
		row.expandHighlight:Show()
		row.text:SetWidth(TITLE_WIDTH)
	else
		row.expand:Hide()
		row.expandHighlight:Hide()
		row:SetText(TitleText(info))
		local tag = QuestTag(info)
		row.tag:SetText(tag and ("(" .. tag .. ")") or "")
		-- The title gives way to the tag (1.12 shrank it the same way).
		local room = TITLE_WIDTH - 15 - (tag and row.tag:GetStringWidth() or 0)
		local textWidth = math.min(row.text:GetUnboundedStringWidth(), room)
		row.text:SetWidth(textWidth)
		local members = PartyMembersOnQuest(info.questID)
		if members > 0 then
			row.party:SetText("[" .. members .. "]")
		end
		if QuestUtils_IsQuestWatched and QuestUtils_IsQuestWatched(info.questID) then
			Point(row.check, "LEFT", row, "LEFT", 20 + textWidth + 4, 0)
			row.check:Show()
		end
	end

	SetRowTextColor(row, color)
	if not info.isHeader and info.questID == selectedQuestID then
		row.selected:SetVertexColor(color.r, color.g, color.b)
		row.selected:Show()
		row.tag:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
		row.party:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
		row:LockHighlight()
	else
		row:UnlockHighlight()
	end
end

local function Select(questID)
	selectedQuestID = questID
	list.ScrollBox:ForEachFrame(function(row) InitRow(row, row.info) end)
	UpdateButtons()
	UpdateDetails(true)
end

local function OnRowClick(row)
	local info = row.info
	if not info then return end
	if info.isHeader then
		collapsedHeaders[info.title] = not IsCollapsed(info) or nil
		Update()
		return
	end
	local chat = ChatFrameUtil and ChatFrameUtil.GetActiveWindow and ChatFrameUtil.GetActiveWindow()
	if IsModifiedClick("CHATLINK") and chat then
		ChatFrameUtil.InsertLink(GetQuestLink(info.questID))
	elseif IsShiftKeyDown() and QuestMapQuestOptions_TrackQuest then
		QuestMapQuestOptions_TrackQuest(info.questID)
	end
	Select(info.questID)
end

-- A 1.12 QuestLogTitleButton: the +/- box for headers, the title 20px in,
-- the tag at the right end, the party count in the indent and the check
-- after the title. The hovered title turns white (its highlight font).
local function CreateRow(row)
	row:SetHeight(16)
	row:RegisterForClicks("LeftButtonUp")
	local text = row:CreateFontString(nil, "ARTWORK", "GameFontNormalLeft")
	text:SetPoint("LEFT", row, "LEFT", 20, 0)
	text:SetHeight(10)
	text:SetWordWrap(false)
	row:SetFontString(text)
	row:SetHighlightFontObject(GameFontHighlightLeft)
	row.text = text

	row.tag = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	row.tag:SetJustifyH("RIGHT")
	row.tag:SetPoint("RIGHT", row, "RIGHT", -2, 0)
	row.party = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	row.party:SetJustifyH("RIGHT")
	row.party:SetPoint("LEFT", row, "LEFT", 8, 0)
	row.check = row:CreateTexture(nil, "ARTWORK")
	row.check:SetTexture(T.CHECK_MARK)
	row.check:SetSize(16, 16)

	row.expand = row:CreateTexture(nil, "ARTWORK")
	row.expand:SetSize(16, 16)
	row.expand:SetPoint("LEFT", row, "LEFT", 3, 0)
	row.expandHighlight = row:CreateTexture(nil, "HIGHLIGHT")
	SetTexture(row.expandHighlight, T.PLUS_BUTTON .. "Hilight")
	row.expandHighlight:SetBlendMode("ADD")
	row.expandHighlight:SetSize(16, 16)
	row.expandHighlight:SetPoint("LEFT", row, "LEFT", 3, 0)

	row.selected = row:CreateTexture(nil, "BACKGROUND")
	row.selected:SetTexture(T.QUESTLOG_HIGHLIGHT)
	row.selected:SetBlendMode("ADD")
	row.selected:SetSize(HIGHLIGHT_WIDTH, 16)
	row.selected:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)

	row:SetScript("OnClick", OnRowClick)
	row:SetScript("OnEnter", function(self)
		self.tag:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
		self.party:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
	end)
	row:SetScript("OnLeave", function(self)
		if self.info and (self.info.isHeader or self.info.questID ~= selectedQuestID) and self.color then
			SetRowTextColor(self, self.color)
		end
	end)
end

local function UpdateCollapseAll()
	local anyExpanded = false
	for _, info in ipairs(entries) do
		if info.isHeader and not IsCollapsed(info) then
			anyExpanded = true
			break
		end
	end
	SetTexture(art.collapseAllIcon, (anyExpanded and T.MINUS_BUTTON or T.PLUS_BUTTON) .. "Up")
	art.collapseAll.anyExpanded = anyExpanded
end

local function ToggleAllHeaders()
	if art.collapseAll.anyExpanded then
		for _, info in ipairs(entries) do
			if info.isHeader then collapsedHeaders[info.title] = true end
		end
	else
		wipe(collapsedHeaders)
	end
	Update()
end

local function UpdateCount()
	local _, numQuests = C_QuestLog.GetNumQuestLogEntries()
	local maxQuests = C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept() or 0
	local color = (maxQuests > 0 and numQuests >= maxQuests) and RED_FONT_COLOR_CODE or "|cffffffff"
	art.count:SetFormattedText("%s: %s%d|r/%d", QUESTS_LABEL or "Quests", color, numQuests, maxQuests)
	return numQuests
end

function Update()
	if not frame:IsShown() then return end
	BuildEntries()
	local numQuests = UpdateCount()
	local empty = numQuests == 0
	art.empty:SetShown(empty)
	list.ScrollBox:SetShown(not empty)
	detail:SetShown(not empty)

	if not IsInList(selectedQuestID) then
		local current = C_QuestLog.GetSelectedQuest()
		selectedQuestID = IsInList(current) and current or FirstQuestID()
	end
	local provider = CreateDataProvider(entries)
	list.ScrollBox:SetDataProvider(provider, ScrollBoxConstants.RetainScrollPosition)
	UpdateCollapseAll()
	UpdateButtons()
	UpdateDetails(false)
end

---------------------------------------------------------------------------
-- The window
---------------------------------------------------------------------------

local function PanelButton(text)
	local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	button:SetHeight(22)
	button:SetText(text)
	return button
end

-- A box of the window: the classic inset (its legacy UI-Frame-Inner
-- border) spanning the frame from `top`, down to `bottom` above the frame's
-- bottom edge (or as tall as the caller makes it).
local function Box(top, bottom)
	local box = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
	box:SetPoint("TOPLEFT", frame, "TOPLEFT", BOX_LEFT, top)
	if bottom then
		box:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", BOX_RIGHT, bottom)
	else
		box:SetPoint("TOPRIGHT", frame, "TOPRIGHT", BOX_RIGHT, top)
	end
	return box
end

-- A classic knob scroll bar inside a box's right edge.
local function PlaceScrollBar(scrollBar, box)
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("TOPRIGHT", box, "TOPRIGHT", -BOX_INSET, -BOX_INSET)
	scrollBar:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -BOX_INSET, BOX_INSET)
	ns.SkinScrollBar(scrollBar)
end

local function CreateList()
	list = Box(LIST_TOP)
	list:SetHeight(LIST_HEIGHT)
	list.Bg:SetColorTexture(0, 0, 0, 0.75)
	list.ScrollBox = CreateFrame("Frame", nil, list, "WowScrollBoxList")
	list.ScrollBox:SetPoint("TOPLEFT", list, "TOPLEFT", BOX_INSET, -BOX_INSET)
	list.ScrollBox:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -SCROLL_BAR_ROOM, BOX_INSET)
	list.ScrollBar = CreateFrame("EventFrame", nil, list, "MinimalScrollBar")
	list.ScrollBar:SetHideIfUnscrollable(true)
	local view = CreateScrollBoxListLinearView()
	view:SetElementExtent(ROW_HEIGHT)
	view:SetElementInitializer("Button", function(row, info)
		if not row.text then CreateRow(row) end
		InitRow(row, info)
	end)
	ScrollUtil.InitScrollBoxListWithScrollBar(list.ScrollBox, list.ScrollBar, view)
	PlaceScrollBar(list.ScrollBar, list)

	-- 1.12 scrolled the list a whole row at a time and always showed six
	-- whole rows. The ScrollBox scrolls by a percentage of its range (the
	-- bar's drag, a list growing or shrinking under a kept position), so the
	-- wheel steps one row and every scroll is rounded to a row.
	local scrollBox = list.ScrollBox
	scrollBox:SetPanExtent(ROW_HEIGHT)
	local snapping = false
	scrollBox:RegisterCallback(BaseScrollBoxEvents.OnScroll, function()
		if snapping then return end
		local offset = scrollBox:GetDerivedScrollOffset()
		local snapped = math.floor(offset / ROW_HEIGHT + 0.5) * ROW_HEIGHT
		if math.abs(snapped - offset) > 0.5 then
			snapping = true
			scrollBox:ScrollToOffset(math.min(snapped, scrollBox:GetDerivedScrollRange()), true)
			snapping = false
		end
	end, list)

	art.empty = list:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	art.empty:SetPoint("CENTER", list, "CENTER", 0, 0)
	art.empty:SetText(QUESTLOG_NO_QUESTS_TEXT or "No Active Quests")
end

local function CreateDetail()
	local box = Box(DETAIL_TOP, DETAIL_BOTTOM)
	-- The parchment of Blizzard's quest and book windows.
	box.Bg:SetHorizTile(false)
	box.Bg:SetVertTile(false)
	if not ns.SetAtlas(box.Bg, "QuestBG-Parchment") then
		box.Bg:SetColorTexture(0.85, 0.75, 0.55)
	end
	art.detailBox = box

	detail = CreateFrame("ScrollFrame", nil, frame, "ScrollFrameTemplate")
	detail:SetPoint("TOPLEFT", box, "TOPLEFT", BOX_INSET + 2, -BOX_INSET - 2)
	detail:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -SCROLL_BAR_ROOM - 2, BOX_INSET)
	detail.child = CreateFrame("Frame", nil, detail)
	detail.child:SetSize(FRAME_WIDTH + 2 * BOX_RIGHT - 2 * BOX_INSET - SCROLL_BAR_ROOM - 4, 100)
	detail:SetScrollChild(detail.child)
	detail:HookScript("OnSizeChanged", function(self, _, height)
		self.child:SetHeight(height)
	end)
	if detail.ScrollBar then
		detail.ScrollBar:SetParent(box)
		PlaceScrollBar(detail.ScrollBar, box)
	end
	-- QuestInfo themes campaign quests with a parchment of their own; the
	-- vanilla pane keeps its parchment.
	frame.SealMaterialBG = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
	frame.SealMaterialBG:SetAllPoints(box)
	frame.SealMaterialBG:SetAlpha(0)

	art.detailBusy = box:CreateFontString(nil, "OVERLAY", "QuestFont")
	art.detailBusy:SetWidth(240)
	art.detailBusy:SetPoint("CENTER", box, "CENTER", 0, 0)
	art.detailBusy:SetText("The quest's details show here again once the quest window is closed.")
	art.detailBusy:Hide()
end

local function CreateHeaderControls()
	-- The "All" tab on the list box: collapses or expands every header.
	local all = CreateFrame("Button", nil, frame)
	all:SetSize(40, 22)
	all:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 60, LIST_TOP + 2)
	local tabLeft = all:CreateTexture(nil, "BACKGROUND")
	tabLeft:SetTexture(T.QUESTLOG_SORT_TAB .. "Left")
	tabLeft:SetSize(8, 32)
	tabLeft:SetPoint("TOPLEFT", all, "TOPLEFT", -6, 8)
	local tabMiddle = all:CreateTexture(nil, "BACKGROUND")
	tabMiddle:SetTexture(T.QUESTLOG_SORT_TAB .. "Middle")
	tabMiddle:SetSize(38, 32)
	tabMiddle:SetPoint("LEFT", tabLeft, "RIGHT", 0, 0)
	local tabRight = all:CreateTexture(nil, "BACKGROUND")
	tabRight:SetTexture(T.QUESTLOG_SORT_TAB .. "Right")
	tabRight:SetSize(8, 32)
	tabRight:SetPoint("LEFT", tabMiddle, "RIGHT", 0, 0)
	art.collapseAllIcon = all:CreateTexture(nil, "ARTWORK")
	art.collapseAllIcon:SetSize(16, 16)
	art.collapseAllIcon:SetPoint("LEFT", all, "LEFT", 3, 0)
	local highlight = all:CreateTexture(nil, "HIGHLIGHT")
	SetTexture(highlight, T.PLUS_BUTTON .. "Hilight")
	highlight:SetBlendMode("ADD")
	highlight:SetSize(16, 16)
	highlight:SetPoint("LEFT", all, "LEFT", 3, 0)
	local text = all:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetPoint("LEFT", all, "LEFT", 20, 0)
	text:SetText(ALL or "All")
	all:SetScript("OnClick", ToggleAllHeaders)
	art.collapseAll = all

	-- Track: the selected quest's watch (Classic Era's radio).
	local track = CreateFrame("Button", nil, frame)
	track:SetSize(16, 16)
	track:SetPoint("LEFT", all, "RIGHT", 26, 2)
	local radio = track:CreateTexture(nil, "ARTWORK")
	SetTexture(radio, T.RADIO_BUTTON, 0, 0.25, 0, 1)
	radio:SetAllPoints(track)
	art.trackCheck = track:CreateTexture(nil, "OVERLAY")
	SetTexture(art.trackCheck, T.RADIO_BUTTON, 0.25, 0.5, 0, 1)
	art.trackCheck:SetAllPoints(track)
	local trackText = track:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	trackText:SetPoint("LEFT", track, "RIGHT", 2, 0)
	trackText:SetText(TRACK_QUEST or "Track Quest")
	track:SetHitRectInsets(0, -trackText:GetStringWidth() - 2, 0, 0)
	track:SetScript("OnClick", function()
		if selectedQuestID and QuestMapQuestOptions_TrackQuest then
			QuestMapQuestOptions_TrackQuest(selectedQuestID)
		end
	end)
	art.track = track

	-- The quest count in its input box at the band's right end.
	local right = frame:CreateTexture(nil, "ARTWORK")
	SetTexture(right, T.INPUT_BORDER, 0.9375, 1, 0, 0.625)
	right:SetSize(8, 20)
	right:SetPoint("RIGHT", frame, "TOPRIGHT", -10, (LIST_TOP - 21) / 2 - 2)
	local middle = frame:CreateTexture(nil, "ARTWORK")
	SetTexture(middle, T.INPUT_BORDER, 0.0625, 0.9375, 0, 0.625)
	middle:SetSize(84, 20)
	middle:SetPoint("RIGHT", right, "LEFT", 0, 0)
	local left = frame:CreateTexture(nil, "ARTWORK")
	SetTexture(left, T.INPUT_BORDER, 0, 0.0625, 0, 0.625)
	left:SetSize(8, 20)
	left:SetPoint("RIGHT", middle, "LEFT", 0, 0)
	art.count = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	art.count:SetPoint("CENTER", middle, "CENTER", 0, 0)
end

-- Esc closes the window. Keyboard propagation cannot be changed in combat,
-- so it stays on there (Esc then also opens the game menu) and is switched
-- off only for the Esc press itself (see the setup wizard).
local function SetUpEscape()
	ns:RunOutOfCombat(function()
		frame:EnableKeyboard(true)
		frame:SetPropagateKeyboardInput(true)
	end)
	frame:SetScript("OnKeyDown", function(self, key)
		if key ~= "ESCAPE" then return end
		if not InCombatLockdown() then
			self:SetPropagateKeyboardInput(false)
			C_Timer.After(0, function()
				if not InCombatLockdown() then self:SetPropagateKeyboardInput(true) end
			end)
		end
		self:Hide()
	end)
end

-- The interaction windows the log replaces (see the header), with the call
-- that ends each interaction.
local INTERACTION_CLOSERS = {
	QuestFrame = { "CloseQuest" },
	GossipFrame = { "C_GossipInfo", "CloseGossip" },
	MerchantFrame = { "CloseMerchant" },
	MailFrame = { "CloseMail" },
	TradeFrame = { "CloseTrade" },
	TaxiFrame = { "CloseTaxiMap" },
	LootFrame = { "CloseLoot" },
	ItemTextFrame = { "CloseItemText" },
	TabardFrame = { "CloseTabardCreation" },
	PetitionFrame = { "ClosePetition" },
	GuildRegistrarFrame = { "CloseGuildRegistrar" },
	ItemSocketingFrame = { "C_ItemSocketInfo", "CloseSocketInfo" },
}

local function Closer(path)
	local fn = _G[path[1]]
	if path[2] then
		fn = type(fn) == "table" and fn[path[2]] or nil
	end
	return type(fn) == "function" and fn or nil
end

function CloseInteractions()
	for name, path in pairs(INTERACTION_CLOSERS) do
		local window, close = _G[name], Closer(path)
		if window and close and window:IsShown() then
			close()
		end
	end
end

-- A Blizzard UI panel shown (it has the panel manager's layout attributes).
local function IsShownPanel(panel)
	return type(panel) == "table" and panel ~= frame and panel.GetAttribute ~= nil and panel:IsShown()
		and panel:GetAttribute("UIPanelLayout-area") ~= nil
end

-- The window opens at the left panel spot (it replaces the panel there),
-- where the manager would put a panel of its size, like the vendor or the
-- mailbox window; a window the player dragged stays where it was put.
function Place()
	if frame.CUIR_placed then return end
	Point(frame, "TOPLEFT", UIParent, "TOPLEFT", ns.PanelLeft(), ns.PanelTop(0, FRAME_HEIGHT))
end

-- The micro button looks pressed while the window is open. Blizzard sets it
-- back to normal on every UpdateMicroButton (it follows the world map).
function UpdateMicroButton()
	local micro = QuestLogMicroButton
	if micro then
		micro:SetButtonState(frame:IsShown() and "PUSHED" or "NORMAL", frame:IsShown())
	end
end

-- A child frame over the window's content, `levels` above it.
local function Layer(levels)
	local layer = CreateFrame("Frame", nil, frame)
	layer:SetAllPoints(frame)
	layer:SetFrameLevel(frame:GetFrameLevel() + levels)
	return layer
end

local function CreateWindow()
	frame = CreateFrame("Frame", nil, UIParent)
	frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	Place()
	frame:SetFrameStrata("MEDIUM")
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		self.CUIR_placed = true -- dragged: keep the player's spot
	end)
	frame:Hide()

	-- ButtonFrameTemplate's rock background, in Window Frames' metal frame
	-- with the quest log book in its portrait ring.
	local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -6)
	bg:SetTexture(T.ROCK_BACKGROUND, "REPEAT", "REPEAT")
	bg:SetHorizTile(true)
	bg:SetVertTile(true)
	bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -21)
	bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
	local portraitLayer = Layer(20)
	local portrait = portraitLayer:CreateTexture(nil, "ARTWORK")
	portrait:SetTexture(T.QUESTLOG_ICON)
	portrait:SetSize(62, 62)
	portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", -5, 7)
	local mask = portraitLayer:CreateMaskTexture()
	mask:SetTexture(T.PORTRAIT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(portrait)
	portrait:AddMaskTexture(mask)
	ns.CreateClassicBorder(Layer(30), frame, true)

	local top = Layer(40)
	art.title = top:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	art.title:SetPoint("TOP", frame, "TOP", 17, -5)
	art.title:SetText(QUEST_LOG or "Quest Log")
	-- A plain close button: UIPanelCloseButton's script hides its parent as
	-- a UI panel, which addon code may not do in combat.
	local close = CreateFrame("Button", nil, top, "UIPanelCloseButtonNoScripts")
	ns.SkinCloseButton(close)
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 4, 5)
	close:SetScript("OnClick", function() frame:Hide() end)

	CreateList()
	CreateDetail()
	CreateHeaderControls()

	art.abandon = PanelButton(ABANDON_QUEST or "Abandon Quest")
	art.abandon:SetWidth(120)
	art.abandon:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 4)
	art.abandon:SetScript("OnClick", function()
		if selectedQuestID and QuestMapQuestOptions_AbandonQuest then
			QuestMapQuestOptions_AbandonQuest(selectedQuestID)
		end
	end)
	local exit = PanelButton(EXIT or "Exit")
	exit:SetWidth(90)
	exit:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 4)
	exit:SetScript("OnClick", function() frame:Hide() end)
	art.share = PanelButton(SHARE_QUEST or "Share Quest")
	art.share:SetPoint("LEFT", art.abandon, "RIGHT", 2, 0)
	art.share:SetPoint("RIGHT", exit, "LEFT", -2, 0)
	art.share:SetScript("OnClick", function()
		if selectedQuestID and QuestMapQuestOptions_ShareQuest then
			QuestMapQuestOptions_ShareQuest(selectedQuestID)
		end
	end)

	SetUpEscape()
	frame:SetScript("OnShow", function()
		PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN)
		CloseInteractions()
		Place()
		UpdateMicroButton()
		Update()
		detail:SetVerticalScroll(0)
	end)
	frame:SetScript("OnHide", function()
		PlaySound(SOUNDKIT.IG_QUEST_LOG_CLOSE)
		UpdateMicroButton()
	end)
	for _, event in ipairs({ "QUEST_LOG_UPDATE", "QUEST_WATCH_LIST_CHANGED", "GROUP_ROSTER_UPDATE", "CVAR_UPDATE" }) do
		frame:RegisterEvent(event)
	end
	frame:SetScript("OnEvent", function(_, event, name)
		if event == "CVAR_UPDATE" and not LEVEL_CVARS[tostring(name):lower()] then return end
		Update()
	end)

	-- Redraw the details once another user of QuestInfo lets go of it.
	for _, other in ipairs({ QuestFrame, QuestLogPopupDetailFrame, QuestMapFrame and QuestMapFrame.DetailsFrame }) do
		if other then
			other:HookScript("OnShow", function() UpdateDetails(false) end)
			other:HookScript("OnHide", function() UpdateDetails(false) end)
		end
	end
end

---------------------------------------------------------------------------
-- Opening it
---------------------------------------------------------------------------

local function Toggle()
	frame:SetShown(not frame:IsShown())
end

-- The quest log key: an override binding per key bound to TOGGLEQUESTLOG,
-- clicking the named toggle button. Override bindings cannot be changed in
-- combat; they are re-set when the key's bindings change.
local boundKeys
local function UpdateBindings()
	local keys = table.concat({ GetBindingKey("TOGGLEQUESTLOG") }, " ")
	if keys == boundKeys then return end
	ns:RunOutOfCombat(function()
		boundKeys = keys
		ClearOverrideBindings(frame)
		for _, key in ipairs({ GetBindingKey("TOGGLEQUESTLOG") }) do
			SetOverrideBindingClick(frame, false, key, TOGGLE_BUTTON_NAME)
		end
	end)
end

-- The map's close button (its click hides the map as a UI panel, securely
-- when a secure button clicks it; nothing while it is closed).
local function MapCloseButton()
	local border = WorldMapFrame and WorldMapFrame.BorderFrame
	return border and border.CloseButton or nil
end

local MAP_PROXY_NAME = TOGGLE_BUTTON_NAME .. "Map"
local secureToggles = {}
local mapProxy

-- A panel's close button if it is the standard one (UIPanelCloseButton:
-- HideUIPanel of its panel, nothing while that is closed), i.e. its panel
-- has no close callback of its own, with a name /click can reach. (Its
-- handler is not compared with UIPanelCloseButton_OnClick: a hook on that
-- global makes the global a different function from the script.)
local function StandardCloseButtonName(panel)
	local close = panel.CloseButton
	if not close and panel.GetName and panel:GetName() then
		close = _G[panel:GetName() .. "CloseButton"]
	end
	if type(close) ~= "table" or not close.IsObjectType or not close:IsObjectType("Button") then return nil end
	local parent = close:GetParent()
	if parent and parent.onCloseCallback then return nil end
	return close:GetName()
end

-- The windows clicked first, should the game cut a long macro short: the
-- map (through its proxy), then Blizzard's main windows and the NPC
-- interaction windows; the other panels follow in name order.
local FIRST_PANELS = {
	"CharacterFrame", "PlayerSpellsFrame", "ProfessionsFrame", "ProfessionsBookFrame", "FriendsFrame",
	"CommunitiesFrame", "PVEFrame", "EncounterJournal", "CollectionsJournal", "AchievementFrame", "PVPUIFrame",
	"QuestFrame", "GossipFrame", "MerchantFrame", "MailFrame", "TradeFrame", "TaxiFrame", "ClassTrainerFrame",
	"AuctionHouseFrame", "BankFrame", "DressUpFrame", "MacroFrame", "ItemTextFrame", "QuestLogPopupDetailFrame",
}

-- The key's macro: one /click line per close button. A macro started from
-- another macro does not run (a /click on a macro button from a macro is
-- ignored, seen in game 2026-09-29), so every line is in this one macro.
local function CloseMacroText()
	local lines, listed = {}, {}
	local function Add(name)
		local panel = _G[name]
		if listed[name] or type(panel) ~= "table" or panel == frame or type(UIPanelWindows[name]) ~= "table" then return end
		listed[name] = true
		local closeName = StandardCloseButtonName(panel)
		if closeName then
			lines[#lines + 1] = "/click " .. closeName
		end
	end
	if mapProxy then
		lines[1] = "/click " .. MAP_PROXY_NAME
	end
	for _, name in ipairs(FIRST_PANELS) do
		Add(name)
	end
	local others = {}
	for name in pairs(UIPanelWindows) do
		others[#others + 1] = name
	end
	table.sort(others)
	for _, name in ipairs(others) do
		Add(name)
	end
	return table.concat(lines, "\n")
end

-- A /click is an up click; with "cast on key down" (ActionButtonUseKeyDown,
-- on by default) a secure action button acts only on the down click unless
-- told otherwise, so the proxy /click reaches is set to act on the up.
local function SecureClickTarget(name)
	local button = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
	button:SetAttribute("useOnKeyDown", false)
	return button
end

-- Rebuilds the toggles' macro (out of combat).
local function RebuildCloseMacros()
	ns:RunOutOfCombat(function()
		local mapClose = MapCloseButton()
		if mapClose and not mapProxy then
			mapProxy = SecureClickTarget(MAP_PROXY_NAME)
			mapProxy:SetAttribute("type", "click")
		end
		if mapProxy then
			mapProxy:SetAttribute("clickbutton", mapClose)
		end
		local text = CloseMacroText()
		for _, button in ipairs(secureToggles) do
			button:SetAttribute("macrotext", text)
		end
	end)
end

-- A secure button that closes every open panel (its macro) and then
-- (PostClick, as addon code) toggles the log. Created out of combat.
local function CreateSecureToggle(name, parent)
	local button = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
	button:RegisterForClicks("AnyUp")
	button:SetAttribute("useOnKeyDown", false)
	button:SetAttribute("type", "macro")
	button:HookScript("PostClick", function()
		if KeybindFrames_InQuickKeybindMode and KeybindFrames_InQuickKeybindMode() then return end
		Toggle()
	end)
	table.insert(secureToggles, button)
	return button
end

-- The micro button's click opens the map; a secure toggle over it (on
-- UIParent, so the micro button does not become protected) opens the log
-- instead and passes the hover on for the tooltip and highlight.
local function CoverMicroButton()
	local micro = QuestLogMicroButton
	if not micro then return end
	local cover = CreateSecureToggle(nil, UIParent)
	cover:SetAllPoints(micro)
	cover:SetFrameStrata(micro:GetFrameStrata())
	cover:SetFrameLevel(micro:GetFrameLevel() + 5)
	-- Blizzard's tooltip only shows while the micro button itself has the
	-- mouse; the cover shows the same one (its name and key).
	cover:SetScript("OnEnter", function()
		micro:LockHighlight()
		GameTooltip:SetOwner(micro, "ANCHOR_RIGHT")
		local text = micro.tooltipText or MicroButtonTooltipText(QUESTLOG_BUTTON or QUEST_LOG, "TOGGLEQUESTLOG")
		GameTooltip_SetTitle(GameTooltip, text)
		GameTooltip:Show()
	end)
	cover:SetScript("OnLeave", function()
		micro:UnlockHighlight()
		GameTooltip:Hide()
	end)
	cover:SetScript("OnMouseDown", function() micro:SetButtonState("PUSHED") end)
	cover:SetScript("OnMouseUp", function() UpdateMicroButton() end)
	ns.Hook(micro, "UpdateMicroButton", UpdateMicroButton)
end

---------------------------------------------------------------------------
-- Module entry point
---------------------------------------------------------------------------

function module:Apply()
	if not ns.HasClassicBorderArt() or not QuestInfo_Display or not QUEST_TEMPLATE_LOG then
		ns.Print("This client does not ship the classic window art; the quest log stays on the world map.")
		return
	end
	CreateWindow()
	ns.Hook("ShowUIPanel", function(panel)
		if frame:IsShown() and IsShownPanel(panel) then
			frame:Hide()
		end
	end)

	-- Secure buttons cannot be made or set up in combat (a reload in combat).
	ns:RunOutOfCombat(function()
		CreateSecureToggle(TOGGLE_BUTTON_NAME, UIParent)
		CoverMicroButton()
		UpdateBindings()
	end)
	RebuildCloseMacros()

	local events = CreateFrame("Frame")
	events:RegisterEvent("UPDATE_BINDINGS")
	events:RegisterEvent("ADDON_LOADED")
	events:SetScript("OnEvent", function(_, event, addon)
		if event == "UPDATE_BINDINGS" then
			UpdateBindings()
		else
			RebuildCloseMacros() -- its panels
		end
	end)
end
