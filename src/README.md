# Forevermore Classic UI

Brings the classic (vanilla / pre-Dragonflight) look to the modern default UI,
one element at a time, without breaking it. The addon is a reskin, not a
replacement: it keeps Blizzard's own frames and only changes their art, layout
and colours, so no functionality is lost. Edit Mode, heal prediction, absorbs,
auras, vehicles, the search boxes and sort buttons, the modern auction house,
staged talent changes and casting from the spellbook all keep working. Every
element has its own option and can be switched back to the modern look.
On WoW Forever it also works with the controller UI: the focus glow,
button prompts and tab prompts follow the classic windows.

Ships for retail 12.1 (`## Interface: 120100`) and for World of Warcraft:
Forever 1.60 (`## Interface: 16001`). No external libraries.

## Setup wizard

The first time you log in with this version (a new install or an update), a
setup wizard opens as the loading screen goes away. Pick one of three presets
(**Everything classic**, **Classic HUD, modern windows** or **Classic windows,
modern HUD**), or **Custom** to go
through the elements a few at a time: each one shows
a picture of its modern and its classic look side by side, and the look you
click is the one used. The last page lists your choices and offers a reload
when one of them needs it. Open the wizard again at any time with
`/fmcui setup` or the **Setup Wizard** button on the options page. Closing it
keeps what you chose so far.

The pictures are drawn from the game's own art (the classic files the addon
puts on Blizzard's frames, and the modern atlases and templates those frames
use; on WoW Forever, the art of its own versions of those frames), with your
own portrait, name, zone map, action bar icons, bags and gear where the frame
shows them. On WoW Forever the windows (character, spellbook, talents,
trainer, auction house, professions, loot, Looking For Group, social) are shown as screenshots.

## Options

Open with `/fmcui` (or `/forevermore`, `/cuir`, `/classicui`), or via **Game Menu > Options > AddOns >
Forevermore Classic UI**. The page lists the options by group, each with a
picture of the look it is set to, a short description (hover it for the full one)
and a **Modern / Classic** switch; **All Classic** / **All Modern** set every
option at once, and a banner with a Reload button appears while a change is
waiting for a reload.

| Option | What it does | Toggle |
| --- | --- | --- |
| **Unit Frames** | Classic frame artwork and layout for the player, target, focus, target-of-target, pet, party and boss frames (elite/rare/minus dragons, level background, classic icon positions, black backdrop behind the bars), the classic circular portraits with the "Zzz" resting bubble and crossed-swords combat indicator on the player portrait, and the flat classic health bars (green, incl. heal prediction / absorb overlays) and power bars (solid classic colours, no end-cap spark). The raid-style frame bars get the classic textures as well. | UI reload |
| **Combo Points** (WoW Forever only) | The classic combo point layout on the target frame: the points run down the right side of the target's portrait (as in vanilla) instead of in an arc over its top. Works with or without the Unit Frames option. | Immediate |
| **Cast Bars** | Classic cast bar art (border, spark, flash, yellow/green/red fill colours) for the player, pet, target, focus and boss cast bars. Works with the "lock to player frame" Edit Mode option. | Immediate |
| **Breath & Fatigue Bars** | Classic look for the mirror timers (breath, fatigue, feign death): the flat bar on a black backdrop with the label on the bar, the large classic cast bar border and the classic colours (blue breath, yellow fatigue, orange death / feign death). Edit Mode's position and size settings keep working. | Immediate |
| **Buffs** | Your buffs without the modern arrow that folds long and permanent buffs away behind it (vanilla had none): the arrow is taken away while the buffs are expanded, so every buff always shows; turned on while they are collapsed, the arrow stays until you expand them with it. The buffs keep their place, 15px in from the buff frame's edge, as with the game's own collapse setting off. Everything else is Blizzard's: right-click to cancel, tooltips, Edit Mode's layout settings. | Immediate |
| **Nameplates** | The classic nameplate: the classic border (`Nameplate-Border`) with the level in its bubble (coloured by difficulty, a skull when it is unknown or far above yours), the flat classic health bar on a dark background, the name centred above it and a flat cast bar in the classic cast bar border with the spell icon in its box (yellow casts, green channels, grey when it cannot be interrupted), without the modern spark, glows and target borders. The game's nameplate style is left as it is (normally Modern): friendly nameplates inside dungeons and raids are locked by Blizzard, no addon can change them, and they keep that modern look. The game's nameplate size setting keeps working. | UI reload |
| **Minimap** | Classic minimap: the 140px map in the round `UI-Minimap-Border` ring with the zone text bar on top, the round tracking button on the left, always-visible classic zoom buttons, the calendar page with the day printed on it, the clock on its plate at the bottom of the map, the square world map button, the letter icon (in a ring) for new mail and crafting orders, the compass ring while "rotate minimap" is on and the north tag otherwise. The addon compartment button gets the same round classic button look, below the tracking button. Edit Mode's size slider and the icon scale still work; its "header underneath" option has no classic equivalent and is ignored. | UI reload |
| **Group Finder Eye** | The classic group finder eye: the animated eye (`LFG-Eye`) in a round minimap button ring instead of the modern eye. The button keeps Blizzard's tooltip, menu and Edit Mode position (next to the micro menu on retail; on WoW Forever the Minimap option puts its default spot at the classic place on the ring). Turn it off to keep the modern eye. | Immediate |
| **Loot Window** | The vanilla loot panel: the classic `UI-LootPanel` artwork with the skull (fishing bobber for fishing loot) in its ring, the round close button, one classic name plate per item and the Prev / Next arrows; four items fit, with more the panel shows three per page like the original (the mouse wheel steps one row). Blizzard's looting, tooltips, quest markers and the "open loot window at mouse" option keep working. | UI reload |
| **Loot Rolls** | The vanilla need / greed roll box: the classic dialog box (the gold one with the gold dragon over the item for a bind on pickup item), the item in the empty slot with its name on the classic label plate, the dice (Need) and coin (Greed) buttons, the round close button in the corner as Pass and the time left as a yellow skill bar under the item. The boxes and their buttons are Blizzard's, so rolling, the bind on pickup question, the tooltips (with why a roll is not allowed), shift-click links and the need roll animation keep working; an item that can be rolled on for its appearance keeps the modern transmog button in the Greed button's place. | Immediate |
| **Trainer Window** | The vanilla class / profession trainer window: the classic `UI-ClassTrainer-*` panel with the trainer's portrait in its ring, a compact list of 16px skill rows coloured by state (green = can learn, red = requirements not met, grey = already known) with the selected row on a tinted highlight bar, and a detail pane below it with the selected skill's icon, name, requirements, cost and description (from the skill's tooltip). Train / Exit buttons, the player's money, the filter in the classic dropdown box and the classic knob scroll bars complete the panel; the profession rank bar sits where vanilla had its "All" tab. Blizzard's selection, training, filters and tooltips keep working. On Forever the collapsible skill categories become the vanilla +/- header rows. | UI reload |
| **Auction House** | The vanilla auction house window: the classic `UI-AuctionFrame-*` panel (the Browse art with the filter column for the Buy and Auctions tabs, the Auction art with the Create Auction panel for the Sell tab) with the auctioneer's portrait in its ring, the round close button, the classic Browse-style tabs under the frame, the classic column headers and sort arrow, the filter buttons on their classic plates with the tree lines, the classic knob scroll bars in their troughs, the classic dropdown boxes, the player's money in the outlined box and 80px Bid / Buyout / Close buttons in the slots at the bottom right. The Sell tab's controls are restacked into the narrow classic panel (label over input, classic input boxes) with the Post button as the classic Create Auction button. Blizzard's searching, filters, favourites, buying, posting, sorting and tooltips keep working; the retail commodity market view, item headers and dialogs keep their inset borders on the classic marble. | UI reload |
| **Action Bar Gryphons** | The vanilla stone gryphons (`UI-MainMenuBar-EndCap-Dwarf`) at both ends of the main action bar instead of the modern gryphon/wyvern art. Classic showed the gryphon to both factions, so Horde characters get it too. Edit Mode's "hide bar art" option and the bar's scale keep working. | Immediate |
| **XP & Reputation Bars** | The vanilla experience and reputation bars: the segmented classic XP bar frame (`UI-MainMenuBar-Dwarf`) over a black background, the flat purple XP fill (blue while rested) with the rested stretch shown faintly past it and the diamond rest marker (`UI-ExhaustionTick`), and the reputation bar in its standing's classic colour (red, orange, yellow, green; blue for renown). While the XP bar is shown too, the reputation bar gets the thinner `UI-ReputationWatchBar` frame, as vanilla drew it over the XP bar; at max level it takes the XP bar's frame. Edit Mode's position and size settings keep working (the frame is fitted to the bars); the retail-only honor, artifact, azerite and house favor bars keep their modern fill in the classic frame. | Immediate |
| **Window Frames** | The pre-Dragonflight frame on the vendor, mail (inbox and open letter), quest, gossip, trade, dressing room, tabard, guild registrar and charter, book / letter, flight map, macro, social (friends) and inspect windows (on WoW Forever the inspect window is the Character Window option's): the silver metal border (`UI-Frame-*`, as retail drew it from Cataclysm to Shadowlands and Classic Era still does) with the portrait ring and the dark title bar in place of the modern metal (Forever's bronze on WoW Forever), the round close button (with the classic bigger / smaller buttons beside it on the dressing room) and the vanilla character window tabs under the vendor, mail, social and (on retail) inspect windows. The stone background, the insets and the red buttons were never redrawn and stay as they are. In the vendor window it also puts back the classic hammer / anvil / gold anvil repair buttons (`UI-Merchant-RepairIcons`), a matching classic-style icon for the retail Sell All Junk button and the plain buyback item slot without the modern undo arrow. The windows other options redraw in full (character, spellbook, talents, professions, trainer, auction house, loot, bags, bank, game menu) are left to those options. | UI reload |
| **Bank** | The vanilla bank window (`UI-BankFrame`): the stone panel with the NPC's portrait in its ring, the slot wells on their riveted metal lattice, "Item Slots" / "Bag Slots" labels and the money bar at the bottom, with the round close button. The art holds a fixed grid, so it is cut between the wells and repeated to the bank's size at vanilla's spacing: 14 columns by 7 rows for a retail bank tab, 8 columns and as many rows as the page needs on WoW Forever (wells without a slot at the end of the last row are covered with stone). On retail the Bank / Warband Bank tabs become the vanilla tabs, the tab's name sits over the wells and the Include Reagents box is the classic check box; the bank tabs down the side are the classic ones already. On WoW Forever the bank bags sit in the bag slot wells (a slot not bought yet is the empty bag slot tinted red, as vanilla showed it, instead of the padlock), vanilla's purchase question, cost and Purchase button are under them and the page tabs down the side are the classic skill line tabs. The slots keep Blizzard's order (retail's runs down its columns, Forever's across its rows), paging, searching, sorting and depositing. | UI reload |
| **Action Bar Art** | The vanilla action bar art: the square `UI-Quickslot2` border with square icons on every action button (main bar, extra bars, pet / stance / possess bars), the `UI-Quickslot` empty-slot look while the grid is shown, the classic pushed / highlight / checked glows, red attack flash and green equipped border; the embossed gryphon slots of the vanilla `UI-MainMenuBar-Dwarf` strip behind the main bar's buttons in place of the modern plate and dividers; and the vanilla page arrows. Edit Mode's bar settings (rows, padding, orientation, icon size, "hide bar art") keep working. | UI reload |
| **Bags** | The vanilla bags. On the bags bar: the backpack, bag and reagent bag slots as equal square buttons (instead of the modern round ones) with square icons in the classic `UI-Quickslot2` item frame, the classic pushed / highlight art and the checked glow while a bag is open, the vanilla backpack icon (`Button-Backpack-Up`) and empty bag slot icon, and an embossed gryphon slot of the vanilla bar strip behind each one, like the right end of the vanilla main bar (on Forever the modern plate and dividers behind the bags are removed and the key ring gets the vanilla key ring art on its own narrow bar slot; the retail arrow that collapses the bags is kept). The bag windows: each bag in the vanilla `UI-Bag-Components` frame (4 columns, the bag icon in the ring, white name, round close button, the key ring's gold frame on Forever), the backpack in the `UI-BackpackBackground` frame with the search box and sort button in the band under its name, the money in its money box, extra rows for the authenticator's slots and the watched currencies on the vanilla strip under it; the combined backpack gets the same backpack art widened to its 10 columns (a partly filled top row shows plain stone where it has no slots, as vanilla's bags did). Empty slots show the embossed slot of the art. Edit Mode's orientation, direction, size and padding of the bags bar keep working. | UI reload |
| **Micro Menu** | The classic micro buttons (`UI-MicroButton-*`) instead of the modern ones: the player's portrait in the classic character button, the classic spellbook, talents, achievements, quest log, socials (guild), group finder eye, mounts (collections), dungeon journal, shop, help and main menu buttons, with the classic highlight glow and the classic alert flash. Professions and housing, which never had a micro button, get the empty classic portrait frame with an icon in it. The client only ships the Cataclysm versions of the main menu, quest log and socials pictures, so the vanilla ones (the computer, the goblet and the speech bubble) are bundled with the addon. The buttons sit on the flat stone panel of the vanilla bar strip (`UI-MainMenuBar-Dwarf`), closed by its metal column at both ends, in place of Forever's modern plate; the panel is hidden while a vehicle or pet battle bar shows the menu. Edit Mode's orientation, order and size settings keep working. | UI reload |
| **Game Menu** | The vanilla game menu (Esc): the classic dialog box (`UI-DialogBox-Border` with its see-through background) with the `UI-DialogBox-Header` plate and "Main Menu" in the small gold font, and the small red classic buttons (`UI-Panel-Button-*`, white text) stacked in their groups as in vanilla. The buttons are still Blizzard's, so every entry the modern menu has (Options, Shop, AddOns, Edit Mode, Support, ...) is there and works. | UI reload |
| **Spellbook** (WoW Forever only) | The vanilla spellbook: the classic `UI-SpellbookPanel-*` book with the spellbook icon in its ring and the round close button, twelve spells per page (1-6 down the left column, 7-12 down the right) in the classic square `UI-Quickslot2` frame on the dark slot, the name in yellow with the rank in brown beside it (passives in the black frame, like 1.12), the school tabs (and the pet's) down the right edge of the book as the classic skill line tabs, "Page N" between the classic Prev / Next arrows, and the search box and settings button in the band under the title. The book opens where the character window opens, level with the other windows (beside another open window, it opens next to it); the talents have their own option (Talents). Casting, dragging spells to the bars, flyouts, tooltips, the search and the settings keep working, in combat too. Uses the spellbook's single-page mode (the `spellBookMinimize` setting is switched on, and back when the option is turned off). | UI reload |
| **Talents** (WoW Forever only) | The vanilla talent frame: the classic frame with your portrait in its ring, one tree at a time on that tree's classic painted background (`Interface\TalentFrame\<tree>-*`), picked with the classic tabs under the frame, the talents on the classic four-column grid in the square slot that is green while a point can go in, gold when maxed and grey when out of reach, the rank in the classic box on its corner, the classic branches and arrows between prerequisites, a classic scroll bar for the lower tiers, the tree's spent points in the box under the title and the unspent points in the bar at the bottom. The frame opens where the classic spellbook opens, at the same size. With a second specialization the Primary / Secondary tabs become 3.x's spec tabs down the right edge of the frame (the active one gilded, "Activate" in the box under the title for the other one). Blizzard's staged changes keep working: "Apply Changes" is 3.x's **Learn** button in the box at the bottom right, and the undo / reset button sits at the end of the box under the title; the search box is in the bottom bar (its results drop down below it). Tooltips, right-click refunds and inspecting keep working. | UI reload |
| **Quest Log** | The vanilla quest log window, in the pre-Dragonflight window frame (as the Window Frames option draws it) with the quest log book in its portrait ring (the client's own `UI-QuestLog-*` art is a later, all-dark redraw): the quest list in a dark box on top, with the zone headers as +/- rows, the "All" tab to collapse or expand them all, the titles in their difficulty colour with the (Complete) / (Failed) / elite tag, the number of party members on the quest and a check on tracked quests, the selected quest on the tinted highlight bar; under it the quest's objectives, description and rewards in a parchment box, and the Abandon Quest / Share Quest / Exit buttons with the Track Quest radio and the quest count at the top. Click selects a quest, shift-click links it into an open chat box or tracks it. With the map's Show Quest Levels filter on (or colour blind mode), the titles get the quest's level in front, as on the map's quest list. The modern client has no quest log window (its quest list lives in the world map), so this one is the addon's own window, filled from Blizzard's quest log and drawn with Blizzard's own quest details; the quest log key and the micro button open it, the world map keeps its quest list. Like the game's own quest log it shares the screen with no other window: any of Blizzard's windows (the world map, the character window, the spellbook, professions, a vendor, the game menu, ...) closes it when it opens, and opening it closes whatever window is open (a quest giver, vendor, trade or mailbox interaction ends, as the game did). It opens at the left window spot, where the vendor and mailbox windows open, can be dragged, and Esc closes it (in combat Esc also opens the game menu). | UI reload |
| **Quest Tracker** | The vanilla quest watch look on the objective tracker: the quest titles in plain dark gold (bright gold once the quest is complete, unless WoW Forever's quest difficulty colours are on) over their " - objective" lines, a met objective in white with its dash as in vanilla instead of dimmed grey behind a check mark, the section names ("All Objectives", "Quests", ...) as plain gold text without the modern header plates, no glow sweeps, the classic +/- collapse buttons and the square `UI-Quickslot2` slot around quest items (as the 3.x watch frame drew them). The quests get vanilla's layout: no POI button before the title (supertrack a quest from the map instead), the titles at the left edge in line with the section name, the objectives on vanilla's 13px rows under the title, and 4px between quests. The tracker is still Blizzard's: its sections, clicks, right-click menu, quest items, Edit Mode position, height and text size keep working; it makes room for as many quests as the retail spacing would fit, so it may end in some empty space. | Immediate |
| **Character Window** (WoW Forever only) | The vanilla character window: the classic frame with your portrait in its ring, your name on the title bar and the level and guild lines under it, the round close button and the classic tabs under the frame (Character, Reputation, Skills, Honor, Currency, Statistics). The Character tab is the vanilla paperdoll (`UI-Character-CharacterTab-*`): the equipment slots in the classic `UI-Quickslot2` frames down both sides and along the bottom with the ammo slot, the model between them on the dark page, the five resistances down the model's right edge and two classic stat boxes under it, each with a classic dropdown to pick base stats, melee, ranged, spell or defenses (2.x's boxes, with Blizzard's own stat values and tooltips). With the details pane's pet tab picked, the page becomes the vanilla pet page (`UI-PetPaperDollFrame-*`): your pet's portrait and name, the pet across the whole page, its resistances and stats in the classic boxes and, for pets that gain experience, the classic purple XP bar. The Reputation tab is the vanilla reputation page: the Faction / Standing labels, one row per faction in the classic `UI-Character-ReputationBar` art with the standing on the classic bar (the progress on mouse over), the classic row highlight, the faction groups as +/- header rows and the classic scroll bar in its trough; a faction you are at war with has its name in red. The client only ships a later redraw of that row art, so the vanilla file is bundled with the addon. The Skills tab is the vanilla skills page: one classic bar per skill in the `UI-Character-Skills-BarBorder` frame with the name and rank on it (blue, or grey and full for a proficiency), the border lit while hovered or selected, the skill groups as +/- header rows, and under the list the selected skill's bar and description, as 1.12 showed it. The other tabs keep Blizzard's content inside the plain classic frame (`UI-Character-General-*`) for now. The details pane (stats, gear sets, titles, pet, and the details of reputation, skills and currency) is still there: the arrow in the band under the title docks it to the window's right side in the classic dialog border. The window opens with the pane closed. Equipping, gear sets, the flyouts, tooltips and turning the model keep working. The inspect window gets the same vanilla frame and paperdoll (1.12's inspect window): the inspected player's portrait in the ring, name and level line, the slots in the classic frames round the model, which fills the whole page, the Talents button in the band under the title, and the Character / Guild tabs under the frame (the guild page in the plain frame). | UI reload |
| **Looking For Group** (WoW Forever only) | The classic Looking For Group window (Classic Era's group finder, in the `UI-LFG-FRAME` panel it reuses from 3.3): the eye (`UI-LFG-PORTRAIT`) in the panel's ring, which comes alive while you are listed, "Looking For Group" on the title bar and the round close button; on the listing page the classic role icons (`UI-LFG-ICON-ROLES`) with their check boxes in the dark band under the title, the new player friendly guide icon beside them, the categories and activities in the panel's window with the classic bar over the comment box, and Back / List Self in the band under it; the browse and who pages under the raid browser's top (`UI-LFR-FRAME-MAIN`), as Classic Era's browse page, with their search boxes and dropdowns in the top band and their lists in the window with the classic knob scroll bar; the page tabs under the frame as the vanilla tabs. The window's pages, buttons, lists, tooltips and menus are Blizzard's, so listing, searching, inviting and whispering keep working. | UI reload |
| **Social Window** (WoW Forever only) | The classic social window (the O key): the friends list frame as Wrath of the Lich King drew it once Battle.net friends arrived (3.3.5): the vanilla friends frame with Battle.net's stone band under the title (`UI-FriendsFrame-*-bnet`), with vanilla's scroll portrait (`FriendsFrameScrollIcon`) in its ring, the tab's name on the title bar and the round close button. The band holds the Battle.net bar (your status, your BattleTag and the Battle.net menu) and, on the friends and recent allies tabs, the search box and the filter in the classic dropdown box; the list sits in the frame's dark well with the classic knob scroll bar in the trough beside it (Blizzard's friend cards, drawn smaller to fit), and the tab's button (Add Friend, ...) is the classic red button in the band under the well. On the raid tab the all-assist box, the role counts and Raid Info go into the band, Convert to Raid into the bottom band and the raid groups, drawn smaller, into the well. The ignore list, broadcast and raid info windows open at the frame's right edge, and the tabs (friends, recent allies, friend requests, raid, ...) are the vanilla tabs under the frame. The window, its cards, menus, tooltips and the raid's player buttons are Blizzard's, so whispering, inviting, adding and removing friends and moving raid members keep working. | UI reload |
| **Professions Window** (WoW Forever only) | The vanilla trade skill window: the classic panel (`UI-ClassTrainer-*` with the trade skill's `UI-TradeSkill-BotLeft`) with your portrait in its ring, the profession's rank on the classic skill bar under the title, the search box and the filter in the classic dropdown box, a compact list of 16px recipe rows coloured by difficulty (orange, yellow, green, grey) with the craftable count after the name and the selected row on a tinted highlight bar, the categories as +/- header rows with no gaps between them and the classic "All" tab above the list to collapse or expand them all, and under the list the selected recipe's icon (with the number made), name, required tools (missing ones in red), cooldown and reagents in the classic item buttons with "have / need" (greyed out while you are short); a recipe that makes no item (an enchant) shows its description there, as 1.12's craft window did. Create All, the - n + quantity box, Create and Exit sit along the bottom, with the classic knob scroll bars. The recipe list is Blizzard's own, so selecting, collapsing categories, favourites (right click), links and tracking keep working; Create and Create All craft through Blizzard's own code. The professions overview page (the book icon among the side tabs) keeps its modern look, and the side tabs stay on the window's right edge. The window opens where the vendor and mailbox windows do (Blizzard's modern window opens a little further right). | UI reload |

The "UI reload" options are applied while the interface loads because
Blizzard's frames cannot be safely un-skinned at runtime; after changing
them, reload with the button on the options page's banner or the wizard's last
page, or with `/fmcui reload`.

## How it works

The 12.x client still ships the legacy textures
(`Interface\TargetingFrame\UI-TargetingFrame`, `UI-StatusBar`,
`Interface\CastingBar\UI-CastingBar-*`, ...), so the addon re-skins Blizzard's
own frames in place: the retail bars, texts and icons are kept and only
re-textured and re-anchored. Blizzard's layout functions are hooked with
`hooksecurefunc` so the classic layout survives target changes, vehicle
swapping, party roster updates and Edit Mode.

Every window opens at the same spot as the modern ones (vendor, mailbox):
its frame border where the game puts a window's edge. The vanilla art
(trainer, auction house and, on WoW Forever, spellbook, talents, character
and trade skill windows) has a transparent margin around its border, so it
is drawn that much up and to the left of Blizzard's frame, and the offsets
Blizzard gives some windows (the auction house, professions) are taken back
out.
With WoW Forever's controller UI on, the gold focus glow, the button prompt
bar under a window and the L1 / R1 tab prompts follow the vanilla art
instead of Blizzard's (now invisible) modern frame.

Cast bars are re-textured from script hooks on the bars themselves (their
cast methods must not be hooked on 12.x, see `Modules\CastBars.lua`), the
breath/fatigue timers are Blizzard's own timer frames re-textured in place,
and nameplates keep the game's own (modern) style: after Blizzard lays a
plate out, its bars are given the classic sizes, the modern art is faded and
the classic border, background, level and cast bar border are drawn on it.
The game's built-in classic nameplate style is not used, because it is one
setting for every plate and the friendly plates inside dungeons and raids,
which no addon can touch, would show Blizzard's broken version of it. The minimap keeps
Blizzard's cluster (so Edit Mode, the tracking menu and the notifications keep
working) and re-parents its pieces into the scaled map container at the
classic positions.
The loot window keeps Blizzard's scroll-box list of items and only re-skins
the panel and the rows; the classic page arrows scroll that list a page at
a time. The trainer window does the same with Blizzard's skill list (its rows
shrunk to the vanilla 16px text rows) and adds its own detail pane, filled
from the service tooltip data since the vanilla description API is gone.
The auction house keeps Blizzard's whole modern frame (search bar,
categories, table-built result lists, sell layout, auctions sub-tabs) and
resizes it to the vanilla 832x447 panel, drawing the classic art per tab
and re-anchoring every sub-frame into the art's insets; the Sell tab's
layout frame is re-stacked from a hook on its Layout, and the item headers'
round item buttons are squared off.
The action bar gryphons are Blizzard's own end cap textures with the
vanilla file (cropped to its art and scaled to the modern 45px buttons) in
place of the modern atlas; on Forever, where each end cap is a movable Edit
Mode frame, only the texture inside it is swapped.
The XP and reputation bars stay Blizzard's (their containers are Edit Mode
systems): the classic frame is drawn over each bar at its width, the modern
frame and fill are faded, and the classic fill is a plain status bar
following the value of Blizzard's animated one; Blizzard's rested stretch and
tick are re-textured, and the colours follow the bars' own texture updates.
The window frames keep Blizzard's windows whole: on each one the modern
metal border (its nine-slice pieces) is faded and the legacy `UI-Frame-*`
border drawn on the same frame, following Blizzard's switches between the
portrait and no-portrait layouts from a hook on `NineSliceUtil.ApplyLayout`;
the close button gets the classic textures and the tabs the vanilla tab
art. The vendor window's repair / junk button icons and buyback slot are
re-textured as well.
The action bar art re-textures Blizzard's action buttons in place and draws
one cell of the vanilla bar strip behind each main bar button (like the
modern per-button slot art), so Edit Mode's layout settings still apply;
the Blizzard functions that re-apply the modern atlases (`UpdateButtonArt`,
the buttons' `Update`, `UpdateDividers`) are hooked to put the vanilla art
back.
The bags bar does the same for Blizzard's bag buttons: they are resized to
one square slot size (they are not protected frames), re-textured after each
`UpdateTextures`, and given a strip cell each that follows the bar's
`Layout`. The bag windows keep Blizzard's container frames and item buttons:
the modern border is faded and the vanilla art drawn in, the frame resized
to it after `UpdateFrameSize`, and after `UpdateItemLayout` every slot is
moved from Blizzard's grid (read back from its anchor, so Blizzard's order
is kept) onto the vanilla one. The combined backpack is the backpack art cut
at the metal between slots and repeated across and down.
The bank keeps Blizzard's window and its pooled slot buttons: after each
`GenerateItemSlotsForSelectedTab` every slot's column and row are worked
out from the anchors Blizzard chained it with, the vanilla art is drawn for
that grid (its file cut through the lattice bars and repeated) and the
window sized to it, and each slot is moved onto its well. Forever's bag
slots and page tabs are placed again after Blizzard's `RefreshBagButtons` /
`RefreshPageTabs`, retail's bank tabs after their tab bar's `Layout`.
The micro menu keeps Blizzard's buttons and Edit Mode layout; the buttons'
`Set*Atlas` methods, through which Blizzard sets every piece of their art,
are hooked to put the classic files back (scaled so neighbouring buttons
overlap like vanilla's).
The quest log is the exception to "reskin, not replacement": the modern
client's quest log is the world map's side panel, so the vanilla window is
the addon's own, built from Blizzard's quest log API; the quest details in
it are drawn by Blizzard's `QuestInfo_Display` (the renderer its quest popup
window uses) and its buttons call the map's own abandon / share / track
functions. The quest log key is taken over with override bindings that
click the window's toggle button, and a transparent button over the micro
button opens it instead of the map.
The quest tracker is Blizzard's objective tracker restyled after each of
its sections lays itself out (a hook on each section's `EndLayout`): the
plates, glows and quest POI buttons are hidden, met objectives re-coloured,
the item buttons re-textured, and the quests' block and line anchors that
Blizzard set are read back and given vanilla's offsets; the collapse buttons
get the +/- again after every `SetCollapsed`. The addon never runs the
tracker's own code, so the quest item buttons stay usable in combat.
The game menu keeps Blizzard's button list, rebuilt on every show; its
`Layout` is hooked to give the buttons the vanilla size and art and
re-stack them the vanilla way, and the vanilla dialog box and header plate
are drawn behind them in place of the faded metal border.

## WoW Forever

Forever's UI is the retail 12.x UI with a small "camelot" game-type overlay
(`Blizzard_UnitFrame\Camelot\*`, `Blizzard_NamePlates\Camelot\*` in Blizzard's
UI source, branch `forever`), so the addon runs the same code on both, plus
extra modules that only load on Forever.

`Modules/ComboPoints.lua` is the Combo Points option. Forever keeps vanilla's
combo points on the target, shown on the target frame with the classic art,
but the overlay lays them out in an arc over the top of the portrait. The
option moves Blizzard's points back to the classic arc down the right side
of the portrait (the offsets of retail's own, unused, target frame combo
points), centred on the portrait so it also fits the overlay's frame art.
Retail shows its combo points on the player frame, since they stay with the
character there, so it has no such option.

`Modules/SpellBook.lua` is the Spellbook option. Forever's spellbook is the
retail one laid out like the classic book (one tab per school, no
specialization / talents tabs on it), which is what the vanilla book fits
onto. It keeps Blizzard's spellbook page and its spell buttons (casting from
them only works while Blizzard's own code drives the list, so the addon never
changes the list's settings): the vanilla book is drawn at the left edge of
the panel while that page is shown (the panel keeps Blizzard's compact size,
so the book opens where Blizzard's compact spellbook does), the list's page
frame is given a height that makes Blizzard's own paging put exactly twelve
spells on each page, and after each layout the spells are moved into the
vanilla two-column page.

`Modules/TalentFrame.lua` is the Talents option. Forever's talents are the
retail talent tree showing the class's three trees side by side, with
staged changes that "Apply Changes" commits. The addon keeps Blizzard's
talent buttons (their clicks, tooltips and staging stay Blizzard's) and
moves them out of the retail canvas into the vanilla frame's scroll frame:
each node's tree, tier and column are read from its coordinates, the
selected tree's buttons go onto the vanilla grid after each time Blizzard
positions them, the other trees' buttons wait out of sight, and the
branches and arrows are drawn from the nodes' prerequisites with 1.12's
own line-drawing rules.

`Modules/PlayerSpellsPanel.lua` is shared by the two: the spellbook and the
talents are pages of one Blizzard panel, and while either classic page is
shown the panel's border, portrait, title and mouse are taken out of the
way and its close button becomes the round classic one on the page's frame.

`Modules/CharacterFrame.lua` is the Character Window option. Forever's
character window is its own: a wide frame with icon tabs down its side, a
left pane that every tab anchors its content to and a collapsible right
pane with the stats, gear sets, titles, pet view and the tabs' details.
The addon draws the vanilla frame at its top left and moves the left pane
into the vanilla content area (so every tab's content moves with it), puts
the paperdoll's slots and model on the 1.12 spots, docks the right pane to
the vanilla frame's side in the 1.12 dialog border, and turns Blizzard's
own tab frames into the vanilla tabs under the frame, so clicks stay
Blizzard's. The stat boxes and resistances are the addon's frames, filled
by Blizzard's own stat functions whenever Blizzard updates its stats.
When Blizzard's pet view hides the slots, the page switches to 1.12's pet
page: its art, the model moved over the page's width, the pet's stats,
resistances, portrait and name, and an XP bar of the addon's own.
`Modules/CharacterReputation.lua` (part of the same option) re-skins the
reputation page's rows after Blizzard initializes them: the bar is resized
to the vanilla bar and its fill redrawn from the bar's own fill updates,
in the vanilla row art. The list's layout settings stay Blizzard's (clicking
a row opens the character window's details pane, which must stay
untainted), so the rows are brought to 1.12's spacing by scaling the whole
list down and each row's content back up.
`Modules/CharacterSkills.lua` does the same for the skills page (its
rows' name moved onto the vanilla bar) and adds 1.12's detail pane under
the list, filled from the skill data whenever Blizzard refreshes its own.
`Modules/CharacterInspect.lua` (part of the same option) puts the same art,
slots, name lines and tab row on Forever's inspect window (a
ButtonFrameTemplate panel with side tabs, like its character window) when
Blizzard_InspectUI loads; Window Frames then leaves that window alone.

`Modules/ProfessionsFrame.lua` is the Professions Window option. Forever's
professions window is the retail one without specializations, crafting
orders or quality: a crafting page (recipe list, recipe details, create
buttons) and an overview page, switched by icon tabs down its right side.
While the crafting page is shown the addon draws the vanilla trade skill
window where the other windows open (Blizzard registers the frame further
right and, on small screens, higher), keeps Blizzard's recipe list (so its clicks
stay Blizzard's; the list is scaled down, every row, category rows too, is
given 1.12's 16px with Blizzard's spacer rows between the categories taken
out, and each row's text is enlarged back and re-coloured by difficulty),
adds 1.12's "All" tab to collapse or expand every category, and moves Blizzard's recipe details, rank bar,
tool slots and create buttons out of sight. The vanilla detail pane, rank
bar and buttons are the addon's, filled from the recipe Blizzard's details
hold whenever Blizzard checks its create buttons; the buttons call
Blizzard's own Create / Create All.

`Modules/GroupFinder.lua` is the Looking For Group option. Forever's
Looking For Group window is Classic Era's premade group finder
(`Blizzard_GroupFinder_VanillaStyle`) loaded with its Mainline layout: a
larger PortraitFrame with modern role icons, big category buttons and icon
tabs down its right side, plus a who list page. The addon sizes the window
to the art Classic Era's layout draws (`UI-LFG-FRAME`), draws that art on it
and moves Blizzard's pages, buttons and lists onto Classic Era's spots. The
browse list is placed through the page it belongs to, since Blizzard
re-anchors it to that page's corners whenever its scroll bar shows or hides;
the browse and who lists are scaled down so their rows fit the classic
window. The tabs are Blizzard's own, drawn as the vanilla tabs under the
frame (the character window's tab skin).

`Modules/SocialFrame.lua` is the Social Window option. Forever's social
window is not the old friends frame but the new Social UI
(`Blizzard_SocialUI`): a tall PortraitFrame with the Battle.net bar under
its title, one page per tab (friends, recent allies, quick join, friend
requests, recruit a friend, raid) and icon tabs down its right side, pooled
and laid out again whenever the window shows. The addon sizes the window to
the classic friends frame art, draws that art on it and anchors the pages'
pieces onto it: the search bars into the stone band, the lists (scaled down,
Blizzard's cards are made for a wider window) into the well, their buttons
into the band under it. The raid page's player buttons are secure, which
makes the window protected once a raid has been shown, so the window and the
raid page are laid out once at load, out of combat. The tabs are Blizzard's
own, drawn as the vanilla tabs under the frame (the character window's tab
skin).

`Modules/Forever.lua` handles what the overlay adds to the other elements:

- the level is shown in a small circle in the bottom corner of the
  player/target/focus/boss frames (`LevelBackgroundCircle`, large white font):
  hidden, and the classic level font/colour is restored in the frame art's
  own circle,
- PvP status is a small faction circle (`PvpBackgroundCircle` +
  `PvpBackgroundIcon`): the circle is hidden and the icon is placed where
  classic had its PvP banner (using the legacy
  `Interface\TargetingFrame\UI-PVP-*` art when the client has it, otherwise
  Blizzard's small icon),
- nameplates get a level indicator box (`PlayerLevelDiffFrame`) next to
  every health bar: hidden by the Nameplates option, whose level is in the
  classic border's bubble (the shared module fades it wherever it exists),
- the hunter pet happiness indicator next to the pet frame is left as is,
- the minimap frame is re-skinned by the overlay on every "rotate minimap"
  change (`Blizzard_Minimap\Camelot\Skin.lua`); the classic art is put back
  afterwards, and the overlay's day/night indicator (`MinimapCluster.DielFrame`),
  which sits where classic has the calendar, is shrunk to the size of the
  classic round buttons and moved to the bottom left of the ring, left of
  the clock, and its player coordinates are moved below the classic clock.
  The overlay's default Edit Mode spot for the group finder eye (on the edge
  of the map) is replaced by the classic eye's spot at the bottom left of the
  ring (the classic eye of the Group Finder Eye option is drawn at the map's
  scale there); an eye moved in Edit Mode stays where it was put.

## Files

```
ForevermoreClassicUI.toc Interface versions (retail and Forever), file list
Core.lua                 saved variables, module registry, helpers
Previews.lua             the modern / classic pictures of every option (wizard and options page)
PreviewsForever.lua      Forever only: its own modern pictures and window screenshots
Textures/Previews/       screenshots of the windows in both looks (Forever)
Wizard.lua               setup wizard; widgets and option groups shared with the options page
Options.lua              Settings panel page (canvas)
Modules/UnitFrames.lua   frame art & layout
Modules/Portraits.lua    portrait masks, rest/combat indicators
Modules/HealthBars.lua   health bar textures/colours
Modules/PowerBars.lua    power bar textures/colours
Modules/CastBars.lua     classic cast bars (live toggle)
Modules/MirrorTimers.lua classic breath/fatigue timer bars (live toggle)
Modules/BuffFrame.lua    buffs without the collapse arrow (live toggle)
Modules/Nameplates.lua   classic nameplates drawn on the modern style (reload)
Modules/Minimap.lua      classic minimap cluster; Group Finder Eye (live toggle)
Modules/LootFrame.lua    classic loot window
Modules/LootRoll.lua     vanilla need / greed roll boxes (live toggle)
Modules/TrainerFrame.lua classic trainer window
Modules/AuctionHouse.lua classic auction house
Modules/EndCaps.lua      vanilla action bar gryphons (live toggle)
Modules/ExperienceBar.lua vanilla XP and reputation bars (live toggle)
Modules/Windows.lua      pre-Dragonflight frame, close button and tabs on the other windows
Modules/MerchantFrame.lua vanilla vendor window icons (part of Window Frames)
Modules/ActionBars.lua   vanilla action bar art (button borders, slot strip, page arrows)
Modules/BagsBar.lua      vanilla bag slots (square slots, backpack icon, slot strip)
Modules/BagFrames.lua    vanilla bag / backpack windows (part of Bags)
Modules/BankFrame.lua    vanilla bank window (art repeated to the bank's grid, tabs; Forever's bag slots)
Modules/MicroMenu.lua    classic micro menu buttons
Modules/GameMenu.lua     vanilla game menu (Esc)
Modules/QuestLog.lua     vanilla quest log window (the addon's own)
Modules/QuestTracker.lua vanilla quest watch look on the objective tracker (live toggle)
Textures/                bundled art: the Sell All Junk icon (vanilla style), the vanilla main menu / quest log / socials micro buttons, the vanilla reputation row art
Modules/ComboPoints.lua  Forever only: classic combo point layout (live toggle)
Modules/PlayerSpellsPanel.lua Forever only: the spellbook / talents panel's chrome for the classic pages
Modules/SpellBook.lua    Forever only: vanilla spellbook
Modules/TalentFrame.lua  Forever only: vanilla talent frame
Modules/CharacterFrame.lua Forever only: vanilla character window
Modules/CharacterReputation.lua Forever only: its Reputation tab (part of Character Window)
Modules/CharacterSkills.lua Forever only: its Skills tab (part of Character Window)
Modules/CharacterInspect.lua Forever only: the vanilla inspect window (part of Character Window)
Modules/ProfessionsFrame.lua Forever only: vanilla trade skill window
Modules/GroupFinder.lua  Forever only: classic Looking For Group window
Modules/SocialFrame.lua  Forever only: classic social window
Modules/Forever.lua      Forever only: adjustments for the "camelot" overlay
```
