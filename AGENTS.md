# Agent instructions for Forevermore Classic UI

This repository contains *Forevermore Classic UI* (published as "Forevermore
Classic UI - Forever & Retail"), a World of Warcraft addon that reskins the
modern UI with the pre-Dragonflight look (unit frames, cast bars, nameplates,
minimap, loot window, vendor window, ...) on the modern client, with each
element individually switchable back to the retail look. It is a reskin, not
a replacement: Blizzard's frames keep all their functionality, and the docs
stress that.

The addon was renamed from *Classic UI Restoration* (folder
`ClassicUIRestoration`, saved variables `ClassicUIRestorationDB` /
`ClassicUIRestorationCharDB`) on 2026-09-27. `MigrateFromOldName` in
`Core.lua` copies the old settings over and disables the old addon when the
old folder is still installed; it is temporary (remove it once the beta
testers have moved over). Still named after the old name: the `CUIR_` prefix
of addon-private keys (internal) and the `/cuir` and `/classicui` slash
aliases next to `/fmcui` / `/forevermore` (never `/fcui`: other addons use it).

## Repository layout

```
src/                    the addon folder, one build for every flavor (copied as is into build\ForevermoreClassicUI\)
  ForevermoreClassicUI.toc  the one .toc for every flavor (## Interface: 120100, 16001)
  Core.lua              namespace, textures/colours, module registry, mirror bars, lifecycle, /fmcui
  Options.lua           Settings panel page (canvas: every top-level module by group, with a picture of its set look
                        and a Modern / Classic switch; reload banner)
  Wizard.lua            setup wizard (first login, "/fmcui setup"); ns.UI: widgets, option groups
                        (GROUPS) and short descriptions (SUMMARIES) shared with Options.lua
  Previews.lua          ns.Previews: the modern / classic picture of each option, drawn from the client's art;
                        ns.PreviewImages: screenshots used instead for whole windows
  PreviewsForever.lua   Forever only: its modern pictures (camelot art) and its window screenshots
  Textures/Previews/    the window screenshots (made by tools/make_previews.py)
  Modules/UnitFrames.lua   classic frame art & layout (player/target/focus/ToT/pet/party/boss)
  Modules/Portraits.lua    portrait masks, rest/combat indicators   (part of Unit Frames)
  Modules/HealthBars.lua   health bar textures/colours              (part of Unit Frames)
  Modules/PowerBars.lua    power bar textures/colours               (part of Unit Frames)
  Modules/CastBars.lua     classic cast bars (live toggle)
  Modules/MirrorTimers.lua classic breath/fatigue (mirror timer) bars (live toggle)
  Modules/Nameplates.lua   classic nameplates drawn on the modern style (reload; forbidden plates skipped)
  Modules/Minimap.lua      classic minimap cluster (reload; keeps Blizzard's cluster, re-parents its pieces into MinimapContainer)
                           + the Group Finder Eye option (live; classic eye drawn on a child frame of QueueStatusButton)
  Modules/LootFrame.lua    vanilla loot panel (reload; re-skins the ScrollingFlatPanel loot frame in place, pages its scroll box)
  Modules/TrainerFrame.lua vanilla trainer window (reload; re-skins Blizzard_TrainerUI in place)
  Modules/AuctionHouse.lua vanilla auction house (reload; resizes Blizzard_AuctionHouseUI to 832x447, classic art per tab, sub-frames re-anchored into it)
  Modules/EndCaps.lua      vanilla action bar gryphons (live toggle)
  Modules/ExperienceBar.lua vanilla XP / reputation bars (live toggle; classic frame over Blizzard's status tracking bars, mirror fill)
  Modules/Windows.lua      "Window Frames" (reload; the other ButtonFrameTemplate windows: modern NineSlice faded, the
                           legacy UI-Frame-* border drawn on it and switched from a NineSliceUtil.ApplyLayout hook,
                           classic close button, tabs through ns.SkinPanelTab in Core.lua)
  Modules/MerchantFrame.lua vanilla vendor window icons: repair/junk buttons, buyback slot (part of Window Frames)
  Modules/ActionBars.lua   vanilla action bar art (reload; button borders, per-button strip cells, page arrows)
  Modules/BagsBar.lua      "Bags" option, bags bar (reload; square equal-size slots, backpack icon, strip cells, Forever key ring)
  Modules/BagFrames.lua    vanilla bag / backpack / combined windows   (part of Bags; slots re-anchored from Blizzard's grid)
  Modules/BankFrame.lua    vanilla bank (reload; UI-BankFrame cut through its lattice bars and repeated to the bank's grid,
                           Blizzard's window sized to it and its pooled slots moved onto the wells after
                           GenerateItemSlotsForSelectedTab; classic tabs; Forever's bag slots and page tabs)
  Modules/MicroMenu.lua    classic micro buttons (reload; UI-MicroButton-* files re-applied from hooks on the buttons' Set*Atlas)
  Modules/GameMenu.lua     vanilla game menu / Esc menu (reload; dialog box drawn behind GameMenuFrame, pooled buttons re-skinned and re-stacked after its Layout)
  Modules/QuestLog.lua     vanilla quest log (reload; the addon's own window, since the modern quest log is the world map's
                           side panel: list from C_QuestLog, details by QuestInfo_Display, opened by override bindings and a
                           button over the micro button)
  Modules/QuestTracker.lua vanilla quest watch look on the objective tracker (live; header plates, glows, check marks and
                           quest POI buttons hidden, +/- collapse buttons, met objectives white, quest blocks / lines
                           re-anchored to vanilla spacing, all from hooks on each module's EndLayout)
  Textures/                bundled art (UI-Merchant-SellJunk.tga, the vanilla-style Sell All Junk icon;
                           UI-Character-ReputationBar.tga, the 1.12 reputation row art;
                           UI-MicroButton-MainMenu/Quest/Socials-*.tga, the vanilla micro buttons from the
                           Classic Era client, which retail/Forever only ship as Cataclysm redraws)
  Modules/ComboPoints.lua classic combo point layout on the target frame, Forever only (live toggle; retail's combo points are on the player frame)
  Modules/PlayerSpellsPanel.lua PlayerSpellsFrame chrome / close button / mouse for the classic spellbook and talents pages (not a module)
  Modules/SpellBook.lua vanilla spellbook, Forever only (reload; re-skins PlayerSpellsFrame's spellbook page in place, 12 spells per page)
  Modules/TalentFrame.lua vanilla talent frame, Forever only (reload; Blizzard's talent buttons moved onto the 1.12 grid, one tree per tab)
  Modules/CharacterFrame.lua vanilla character window, Forever only (reload; vanilla art on CharacterFrame, left pane moved into it, right pane docked, mode tabs as bottom tabs)
  Modules/CharacterReputation.lua its Reputation tab, Forever only   (part of Character Window; rows re-skinned after Blizzard initializes them)
  Modules/CharacterSkills.lua its Skills tab, Forever only           (part of Character Window; same row skinning, own 1.12 detail pane)
  Modules/CharacterInspect.lua the vanilla inspect window, Forever only (part of Character Window; its art, slots and tab row
                           through ns.CharacterWindow; Window Frames skips the window through ns.windowOwners)
  Modules/ProfessionsFrame.lua vanilla trade skill window, Forever only (reload; crafting page re-skinned in place, Blizzard's recipe list scaled with its row heights overridden (not with the controller UI on), own detail pane / rank bar / "All" tab / proxy create buttons)
  Modules/GroupFinder.lua classic Looking For Group window, Forever only (reload; Blizzard_GroupFinder_VanillaStyle's Mainline
                           frame sized to Classic Era's UI-LFG-FRAME art, pages / lists re-anchored, side tabs as bottom tabs)
  Modules/SocialFrame.lua classic social window, Forever only (reload; Blizzard_SocialUI's SocialUIFrame sized to the
                           UI-FriendsFrame-*-bnet art, tab pages re-anchored / lists scaled, pooled side tabs as bottom tabs)
  Modules/Forever.lua   Forever-only adjustments for the "camelot" UI overlay (loaded last)
  README.md             user-facing description of every option (both flavors)
addon.json              addon name, version (single source; the .toc carries @project-version@),
                        the CurseForge project id ("curseforge") and the flavors with the game
                        folder each deploys to ("gameDir")
build.ps1               copies src\ into build\ForevermoreClassicUI\ and zips it as
                        build\ForevermoreClassicUI-<version>.zip (CurseForge layout, one file for every flavor)
build/                  build output (git-ignored); what deploy.ps1 copies into the game
deploy.ps1              builds once + mirrors the build into every installed flavor (-Flavor X for one)
deploy.config.json      machine-specific WoW path (git-ignored, never commit)
publish.ps1             build + changelog (build\CHANGELOG.md) + CurseForge upload (API token from
                        CURSEFORGE_API_TOKEN; -DryRun uploads nothing); run by CI
CHANGELOG.md            release notes, a "## <version>" section per release (else commit subjects)
.github/workflows/build.yml  CI, master only: Lua 5.1 syntax + .toc file list + build on every push;
                        a push that changes addon.json's version runs publish.ps1 and creates the
                        GitHub release v<version>
tools/make_previews.py  crops in-game screenshots into src/Textures/Previews (see its header)
curseforge/             project page material: logo.png, logo_alt.png, logo_large.png (rendered from
                        logo-src\*.html by make_logo.ps1, headless Chrome / Edge), description.md
```

Flavors: `Retail` -> `_retail_`, `Forever` -> `_classic_beta_` (declared in
`addon.json`; Forever currently ships as the `wow_classic_beta` product and
will need a new `gameDir` once it gets its own). One build, one `.toc` and one
CurseForge zip serve every flavor: the `.toc`'s `## Interface:` line lists each
flavor's Interface version, and the zip is uploaded once, tagged with every
game version. Forever-only code lives in its own files (`Modules/Forever.lua`,
which hooks the same Blizzard functions *after* the other modules, and
`Modules/ComboPoints.lua` / `Modules/SpellBook.lua` / `Modules/TalentFrame.lua` /
`Modules/CharacterFrame.lua` / `Modules/CharacterReputation.lua` / `Modules/CharacterSkills.lua` /
`Modules/CharacterInspect.lua` /
`Modules/ProfessionsFrame.lua` / `Modules/GroupFinder.lua` / `Modules/SocialFrame.lua`, options only Forever has, with
`Modules/PlayerSpellsPanel.lua` shared by the spellbook and talents), each starting with `if not ns.IS_FOREVER then return end` right
after `local _, ns = ...`, so on retail they register nothing.
`ns.IS_FOREVER` (set in `Core.lua` from the Interface version) is the only
flavor check: never branch on it inside the modules both flavors run (they
stay flavor-agnostic by hooking whatever exists), and do not rely on
`[AllowLoadGameType ...]` on `.toc` file lines, which the client ignores for
addons (tested 2026-09-27: retail loaded `camelot`-tagged files). Never edit
anything under `build/`.

## Workflow

- Edit files under `src/` only. `build/` and the copies inside the game
  folders are outputs; never edit them directly and never touch anything else
  in the game install.
- Deploy with `.\deploy.ps1` (PowerShell): it runs `build.ps1` once and
  mirrors `build\ForevermoreClassicUI\` into
  `<WoW>\<gameDir>\Interface\AddOns\ForevermoreClassicUI\` of every flavor
  whose game folder exists (skipping uninstalled clients); `-Flavor X`
  deploys to one flavor. The user then runs `/reload` in game; the addon
  cannot be tested outside the game client. A change outside the
  Forever-only files affects both flavors: say so, since the user will
  typically test one of them.
- There is no automated test suite in the repo. Before handing over, at least
  check Lua syntax (e.g. with a Lua parser) and re-read the changed code for
  the taint rules below. In-game verification is done by the user; ask for a
  `/reload` and, when useful, a screenshot or the output of `/fmcui`.
- Keep every user-facing description in sync with the options and behaviour
  whenever a module is added, removed or renamed: `src/README.md` (the
  option table, "How it works" and the file list), the `## Notes:` line of
  the `.toc`, and `curseforge/description.md` (the "What it restores" list and the summary,
  which must stay under 250 characters). A new top-level module also goes
  into a group of `GROUPS` and gets a line in `SUMMARIES` (`Wizard.lua`; a
  module no group lists lands in "Other") and a picture in `Previews.lua`
  (`classic` / `modern` builders drawing the same files, coordinates and
  atlases the module and Blizzard's frame use).
- The version lives only in `addon.json`, and a version bump pushed to
  `master` is a public release (see "Releasing to CurseForge" below): only
  bump it when the user asks for a release. Never write a literal version into the `.toc` — it contains
  `## Version: @project-version@`, which `build.ps1` replaces (in `.toc`,
  `.lua` and `.md` files) and uses for the zip name. `ns.VERSION` in
  `Core.lua` reads it back from the TOC.
- Do not commit unless asked. Never commit `deploy.config.json`.

## Releasing to CurseForge

"Deploy" on its own means `.\deploy.ps1` (copy into the local game). When the
user asks to *release*, *publish*, or *deploy to CurseForge* (or to "ship" /
"push a new version"), the release is done by CI
(`.github/workflows/build.yml`, details in the root `README.md`): a push to
`master` that changes `"version"` in `addon.json` uploads the zip to
CurseForge and creates the GitHub release `v<version>`. If it is unclear
which of the two the user means, ask. A release request authorizes the
commit and push below (and only those); it is public and cannot be taken
back, so follow the steps in order:

1. **Check the tree.** `git fetch --tags origin`, then `git status`: be on
   `master`, not behind `origin/master`. Uncommitted changes: ask whether
   they belong in the release (commit them first, as their own commit with a
   normal message) or stay out (then leave them uncommitted and out of the
   release commit). Run the Lua syntax check (as in CI: `luac5.1 -p` on every
   file under `src/`, or another Lua 5.1 parser) and `.\publish.ps1 -DryRun`;
   stop and report on any failure.
2. **Pick the version.** The previous release is the newest `v*` tag (or,
   before the first tag, the version in `addon.json` of `origin/master`). Use
   the version the user named; otherwise bump the minor version when the
   release adds a feature or option (1.20.1 -> 1.21.0) and the patch version
   for fixes only (1.21.0 -> 1.21.1). "beta" / "alpha" releases get
   `-beta1` / `-alpha1` (next number if that one is tagged). State the
   version you chose in the reply.
3. **Write the changelog.** Read the commits since the previous release
   (`git log --no-merges v<previous>..HEAD`, and their diffs when the
   subjects are terse) and add a `## <version>` section at the top of the
   version list in `CHANGELOG.md`: one bullet per player-visible change, in
   players' words (option names as the options page shows them, which
   flavor when only one is affected), no internal refactors, file names or
   commit hashes. Keep it compact: a bullet is one or two short lines that
   say what changed or was fixed, not a tour of every piece of art, anchor
   or behaviour kept from Blizzard (a new option: its name, the flavor and
   what it restores, e.g. "New Loot Rolls option: the vanilla need / greed
   roll box."). Small related fixes share one bullet.
4. **Commit and push.** Change `"version"` in `addon.json` and add the
   `CHANGELOG.md` section in one commit, message `Release <version>` (plus
   the attribution lines), nothing else in it. `git push origin master`.
   Never create or push the `v<version>` tag yourself: the workflow skips a
   version that is already tagged, and the GitHub release creates the tag.
5. **Follow the run.** With `gh` available: `gh run list --workflow build.yml
   --branch master --limit 1`, then `gh run watch <id> --exit-status`. Without
   it, give the user the Actions link
   (https://github.com/stavroskasidis/ForevermoreClassicUI/actions) instead of
   polling. Report the outcome: the CurseForge file and the GitHub release on
   success, the failing step's log on failure.
6. **If it failed:** fix the cause (never by bumping the version again) and
   re-run it on the user's go-ahead with `gh workflow run build.yml --ref master`
   (or *Run workflow* in the Actions tab), which releases the current version
   while it has no `v<version>` tag. If the CurseForge upload succeeded but the
   GitHub release step failed, do not re-run (it would upload to CurseForge a
   second time): create the release by hand
   (`gh release create v<version> build/ForevermoreClassicUI-<version>.zip
   --target <release commit> --notes-file build/CHANGELOG.md`, plus
   `--prerelease` for a beta / alpha, after a local `.\publish.ps1 -DryRun`
   on that commit).

The CI needs the repository secret `CURSEFORGE_API_TOKEN`; a run failing with
"Set CURSEFORGE_API_TOKEN" means the user has to add or renew it (never ask
for the token in chat or put it in a file).

## Client facts (retail 12.x) that shape the code

- `## Interface: 120100` (12.1.0). Blizzard's UI source is
  https://github.com/Gethe/wow-ui-source (branch `live`); use the 9.2.x tag for
  classic coordinates/texture coords. Read the real source before hooking or
  re-anchoring anything — names and hierarchies change between patches.
- **WoW Forever** (`ns.IS_FOREVER`): `## Interface: 16001` (client 1.60.1, product
  `wow_classic_beta`, exe `WowB.exe`; interface version = `%d%02d%02d` of the
  client version, so 1.60.1 -> 16001). Its UI is the *mainline* (12.x) code
  loaded with game type `camelot`: Blizzard's source is the `forever` branch of
  wow-ui-source, where `.toc` lines tagged `[AllowLoadGameType camelot]` and the
  `Camelot\` sub-folders override the Mainline files. Everything in the retail
  rules below (secrets, taint, protected frames, mirror bars) applies to
  Forever unchanged. Known overlay differences: level shown in
  `<ContentMain>.LevelBackgroundCircle`, PvP status in
  `PvpBackgroundCircle/PvpBackgroundIcon` (retail `PVPIcon`/`PrestigePortrait`
  never shown), nameplate `PlayerLevelDiffFrame` level box next to the health
  bar, `PetFrameHappiness`, `ComboFrame_ApplyOverrides`, minimap `DielFrame`
  (day/night) and `MinimapContainer.PlayerCoords`. To find the installed
  client's interface version in game: `/run print((select(4, GetBuildInfo())))`.
  An early 1.60.1 beta client wrote SavedVariables but never loaded them back
  (options reset every session); Blizzard fixed it (confirmed 2026-09-28), so
  saved options and `setupDone` persist on Forever like on retail.
  Taint logging is unusable on the 1.60.1 client: with `/console taintLog 2`
  every call of a method this addon hooks with `hooksecurefunc` (micro buttons'
  `SetNormalAtlas`, action buttons' `Update`, ...) fails with "attempt to call
  a nil value" in Blizzard's code (seen 2026-09-27). Test taint questions in
  game instead (e.g. open protected panels in combat) and turn it back off.
- The legacy textures (`Interface\TargetingFrame\UI-TargetingFrame`,
  `UI-StatusBar`, `Interface\CastingBar\*`, `Interface\Tooltips\Nameplate-Border`
  etc.) still ship with the retail client, so the addon references them by path
  and does not bundle copies (exception: files the client only ships redrawn,
  like the three vanilla micro buttons and Forever's redrawn
  `UI-Character-ReputationBar` in `Textures/`). Note the retail `Nameplate-Border` is 256x32 with
  the art in the left 136 px.
- **Secrets:** unit health/power/cast values may be "secret" (12.x). Addon code
  must not compare, do arithmetic on, or format them. They may be passed
  straight through to `StatusBar:SetValue/SetMinMaxValues` (allowed when
  tainted) but not to `SetPoint/SetSize/SetParent` (offset math is not allowed).
  `GetPoint/GetSize` on nameplate regions are restricted; wrap diagnostics in
  `pcall`. Region state that Blizzard set from secret values reads back
  secret too: in instances the unit frames' PvP icons are set with
  `SetShown/SetAtlas(secret)`, so their `IsShown()`/`GetAtlas()` must be
  checked with `issecretvalue` before any test. On Forever the player's stats
  and resistances are secret in combat too: Blizzard's stat functions
  (`PAPERDOLL_STATINFO[...].updateFunc`) fail when addon code calls them
  then, so the character window's stat boxes keep their values through
  combat and refresh after it.
- **Taint:** never write a Lua field on a Blizzard frame that Blizzard code
  later reads (e.g. cast bar `barType`, `casting`, `unit`). Writing such a field
  taints Blizzard's execution and produces "action blocked" / secret-value
  errors far from the write. Prefer widget API calls (`SetTexture`, `SetPoint`,
  `SetAlpha`, ...) and keep addon state in the `ns` table or in weak tables keyed
  by frame. Addon-private keys on Blizzard frames use the `CUIR_` prefix and
  must only ever be read by this addon.
- **Protected frames:** Blizzard's unit frame status bars and their containers
  inherit `SecureFrameTemplate`. `SetPoint/SetSize/ClearAllPoints/SetParent` on
  them are blocked in combat (silently) and Blizzard restores the retail
  geometry on every target change. The classic bars are therefore unprotected
  *mirror* StatusBars (`ns.CreateMirrorBar` in `Core.lua`) driven by
  `OnValueChanged/OnMinMaxChanged` hooks on Blizzard's bar; Blizzard's own fill
  is faded to alpha 0. Overlays (heal prediction, absorb, loss bars, glows) are
  re-parented onto the mirror with `ns.AttachToMirror`. Do not add code that
  moves or resizes a protected frame.
- Anything that must touch a protected frame outside combat goes through
  `ns:RunOutOfCombat`.
- Closing Blizzard's UI panels without `HideUIPanel` (see `Modules/QuestLog.lua`):
  a secure button (`SecureActionButtonTemplate`, type "macro") whose
  macrotext `/click`s the panels' own close buttons does it, in combat too.
  Two traps, seen in game 2026-09-29: `/click` sends an up click, and a
  secure action button acts only on the down click while "cast on key down"
  (`ActionButtonUseKeyDown`, on by default) is on unless it has the
  `useOnKeyDown` attribute set to false; and a macro that `/click`s another
  macro button does not run that button's macro (keep every line in one
  macro; `/click` on a "click"-type secure button from a macro works).
- Never call `ShowUIPanel` / `HideUIPanel` from addon code: in combat the
  panel manager refuses tainted calls ("Interface action failed because of
  an AddOn"). A template's script on a button the addon created runs as
  addon code too, so `ns.CreatePanelCloseTextButton` (a `UIPanelCloseButton`
  on the panel) still only closes out of combat. A close button that must
  work in combat is a `SecureActionButtonTemplate` with `type` "click" and
  `clickbutton` the panel's own `CloseButton` (created out of combat; it is
  protected and makes its parent protected): see the professions window.
- A panel with a secure descendant is protected: no `SetSize` / `SetPoint`
  / `EnableMouse` / `SetHitRectInsets` on it in combat, and hooks that run
  when it shows (a keybinding can show it in combat) must defer those with
  `ns:RunOutOfCombat`. Forever's `ProfessionsFrame` is one (its overview
  page's profession spell buttons are secure): setting its hit rect on show
  made the K binding fail in combat ("Interface action failed", 2026-09-27).
- Hooks go through `ns.Hook(global, fn)` / `ns.Hook(frame, "Method", fn)`: a
  guarded `hooksecurefunc` whose callback runs in `xpcall`, because an error in
  one hook silently drops every later hook in the chain. Use `HookScript` for
  frame scripts. Never replace Blizzard functions.
- `StatusBar:SetStatusBarTexture(file)` resets the fill's draw layer; use
  `ns.SetBarTexture` for mirrors. Atlases are applied with
  `texture:SetAtlas(name)`, never by passing an atlas name as a file path.
- Nameplates: the built-in classic style (`nameplateStyle` CVar =
  `Enum.NamePlateStyle.Classic`) is *not* used. The CVar is one setting for
  every plate, and friendly plates inside dungeons and raids are forbidden
  frames (`ForbiddenNamePlate*`, same `NamePlateUnitFrameMixin`, so its hooks
  run for them: skip anything `IsForbidden()`) that would show Blizzard's broken
  classic border. The module leaves the player's style (normally Modern) and
  lays the classic look out itself after `UpdateAnchors` on the plates addon
  code can reach; forbidden plates keep the modern look. Blizzard lays a
  plate out before setting its unit, so unit-dependent parts (the level) are
  updated from a hook on `NamePlateDriverFrame:OnNamePlateAdded`.
- Spellbook (Forever only; dropped for retail on 2026-09-26, whose spellbook
  with its Class / General / Pet text tabs and Specialization / Talents bar
  did not fit the vanilla book): the spell buttons of
  `PlayerSpellsFrame.SpellBookFrame` cast
  through the protected `C_SpellBook.CastSpellBookItem`, so the paged list
  must only ever be driven by Blizzard's code: never call its
  `SetViewsPerPage`/`SetDataProvider`/`SetMinimized`/`SetTab` or write its
  fields (the item frames it builds afterwards carry the taint and casting is
  blocked). Items per page are controlled only through the view frame's
  height (see the header of `Modules/SpellBook.lua`); single-page mode comes
  from the `spellBookMinimize` CVar, read when `Blizzard_PlayerSpells` loads.
  Tab clicks reach `PlayerSpellsFrame:SetTab` through a closure taken at load,
  so hooking `SetTab` misses them. The page holds a secure button (the
  assisted combat spell, `UIPanelSpellButtonFrameTemplate`), so the page and
  `PlayerSpellsFrame` are protected: no `SetSize`/`SetPoint`/`EnableMouse`/
  `SetHitRectInsets` on them (or on that button) in combat. The module never
  resizes the panel (the book is drawn at its left edge, lowered to the other
  panels' line, and the panel manager positions the panel by Blizzard's
  compact size); its mouse and that button's anchor are only changed out of
  combat. Forever has no panel tab system and one icon category tab per skill
  line. The panel's chrome, close button and mouse are owned by
  `Modules/PlayerSpellsPanel.lua` (shared with the talents page), which sets
  them from the pages' shown state, never from the page that triggered it.
- Talents (Forever only): `PlayerSpellsFrame.TalentsFrame` is the retail
  trait-tree frame (`Blizzard_SharedTalentUI`) with the camelot overlay: one
  C_Traits tree holding the class's three trees side by side (node groups
  from `C_Traits.GetGroupDisplayInfoByTreeID`), a Primary / Secondary tab per
  spec group, staged changes committed by "Apply Changes". Its panel area is
  "center" (it closes every other panel when opened). The node grid is 600
  node units (60px) in both directions; a few nodes sit far off the grid in
  the data (out of Blizzard's view) and a few edges point upwards. The
  module reparents Blizzard's talent buttons into its own scroll frame:
  `ClassTalentsFrameMixin:UpdateTalentButtonPosition` reparents a button to
  `ButtonsParent` every time it positions it, so the module re-places it in a
  hook on that method; edges (`AcquireEdge` parents them to the start
  button's parent) and gates are reparented to a hidden frame. Button alpha
  is Blizzard's (its "Invisible" state), so trees are hidden by parent, never
  by alpha. The spec tabs reach `SetTab` through a closure taken at load
  (hook the tab buttons' `SetTabSelected`, not `SetTab`).
- Character window (Forever only): `CharacterFrame` is Forever's own
  (`Blizzard_UIPanels_Game\Camelot\CharacterFrame.*`), not retail's: a
  631x484 PortraitFrame (398 wide with the right pane collapsed), six
  `LargeSideTabButtonTemplate` mode tabs (Frames; clicks arrive through
  `OnMouseUp`, selection through the mixin's `SetChecked`), and every page
  (paperdoll, reputation, skills, PvP rank, currency) anchors its content to
  `CharacterFrame.LeftPaneHost`; the stats, gear sets, titles, pet view and
  the pages' detail panes live in `RightPaneHost`. Blizzard re-sizes the
  frame in `UpdateSize` on every refresh and reads the collapsed state from
  the `characterFrameCollapsed` CVar at load only (it never writes it). The
  frame holds no secure widgets, so it can be re-anchored in combat, but
  never change its collapsed state from addon code (the state feeds the
  panel manager's width attribute). Retail's character frame is a different
  frame (`Mainline\CharacterFrame.*`, three bottom tabs).
  The pages' lists are ScrollBoxes: never change their view's extents or
  padding (Lua fields; a row click reaches `SetRightPaneCollapsed`), scale
  the list instead (`ns.CharacterList` in `CharacterFrame.lua`). A ScrollBox's
  acquired-frame callback runs before the row's first Initialize, the
  initialized-frame callback after every one.
- Trainer: on Forever a skill row click selects through the row's
  `displayIndex` Lua field, written by the list's layout, and the Train
  button passes the selection to `BuyTrainerService` (protected for pet
  training). A tainted layout (from writing the view's extent or padding)
  gets pet training blocked (2026-09-29), so the trainer list is scaled
  down, never re-extented. Retail rows select through `GetID()`.
  The professions recipe list keeps its extent calculator (and the "All"
  tab its node collapsing) only without the controller UI (2026-10-01):
  they make every layout tainted, and the controller UI lays the list out
  from Blizzard's code and then sets override bindings, which are
  Blizzard-only ("only available to the Blizzard UI"; clicking either
  button of that popup crashed the 1.60.1 client). The choice is made when
  the window is skinned (`ns.IsControllerUI()`); a later switch asks for a
  reload.
- Looking For Group (Forever only): `Blizzard_GroupFinder_VanillaStyle`
  (load-on-demand) ships a `Classic\` layout (Classic Era's, drawn with
  `UI-LFG-FRAME`) and the `Mainline\` one Forever loads
  (`LFGVANILLA_SETTING_MODERN_STYLE`): `LFGParentFrame` with three
  PortraitFrameTemplate pages (listing, browse, Forever's who list) and
  LargeSideTabButtonTemplate tabs. Its bottom tabs `Tab1`-`Tab3` are hidden
  on every `UpdateTabs`, and their click handler calls a global
  `LFGParentFrame_SetActiveTab` that is local to another file: use the side
  tabs. The browse list's anchors come from a
  `ScrollUtil.AddManagedScrollBarVisibilityBehavior` (offsets from the page's
  corners, re-applied when its scroll bar shows or hides): move the page,
  not the list.
- Social window (Forever only): the O key opens the 12.x Social UI
  (`Blizzard_SocialUI`, `SocialUIFrame`; retail 12.1's source has it too),
  not `FriendsFrame`, while `C_SocialUI.IsSystemEnabled()` (server-side):
  `ToggleFriendsFrame` forwards to `SocialUIControl`. A PortraitFrameTemplate
  with one content frame per tab (`tabDefinitions[type].contentFrame`,
  created at load, anchored once; most are `SocialUIContactsFrameTemplate`:
  `FilterBar`, `ScrollBox`, `ActionButton`) and `LargeSideTabButtonTemplate`
  tabs from a pool, released on every hide and laid out again by
  `RefreshTabs` on every show. Side windows (ignore list, broadcast, raid
  info) are anchored once at load right of the tab column, and the panel's
  `extraWidthFunc` adds that column's width. The raid tab's player buttons
  are `SecureUnitButtonTemplate`: once a raid has been shown, the window
  and the raid page are protected (no size, anchor or scale changes in
  combat). Many of its widgets are `UserScaled*` (re-sized by the text size
  setting), so size them where Blizzard does not, or scale their parent.
- Controller UI (Forever only: `Blizzard_Gamepad*`, game type `camelot`):
  the focused window gets a gold glow (`FrameGlow`, from
  `PortraitFrameBaseTemplate` / `DefaultPanelBaseTemplate`, anchored round
  its `NineSlice` once at load), jump hints (`LeftJumpHint` / `RightJumpHint`
  / `FocusJumpHint`, centred on its bottom edge) and footers of button
  prompts (`GamepadSharedUtility.CreatePromptedBindingFooter`; the legend is
  a child of the window built on the footer's first show, anchored under the
  window's bottom edge). Windows with tabs have a `TabIndicators` frame (L1 /
  R1 prompts, placed in `UpdateTabVisibility` beside or, with `isVertical`,
  above and under the tab list). A window whose vanilla art is smaller than
  (or offset from) Blizzard's frame registers a box round the art
  (`ns.CreateArtBox`: border corner to the border's right edge and the
  bottom of the tab row) with `ns.SetGamepadBox` (`Core.lua`), which moves
  the glow, hints and footers onto it; windows switching between a vanilla
  and a modern page (spells panel, professions) switch the box with the
  page (nil: back to Blizzard's frame). Windows sized to their art (bags,
  bank, loot, game menu) and the Window Frames ones (same frame) need none.
  A module that lays bottom tabs out of a side tab column re-places the
  `TabIndicators` buttons (see `CharacterFrame.lua`). Blizzard hides some
  windows' close buttons in that mode (B closes them).
- A texture's `SetAlpha` is its vertex alpha: `GetVertexColor()` on a faded
  texture returns alpha 0, so copy only r, g, b from it.
- Minimap: `MinimapCluster` is a `ResizeLayoutFrame` (sizes itself to its shown
  children) and an Edit Mode system; `MinimapContainer` is what the Size slider
  scales, so every classic piece lives inside it. `MinimapCompassTexture` is
  the region the engine rotates with the map ("rotate minimap"), so it carries
  the CompassRing and the static ring border is the addon's own texture.
  `Blizzard_TimeManager` (clock) is load-on-demand: skin it on `ADDON_LOADED`.
  Forever (since build 70425, 2026-10-16) re-sizes the container/backdrop and
  swaps the compass atlas in `MinimapCluster:UpdateMinimapConfig`
  (`Blizzard_Minimap\Camelot\Minimap.lua`, at load and on every rotate change);
  its cluster has no `BorderTop` (the header is the `ZoneTextButton`), and the
  zone text, tracking, calendar and addon compartment buttons draw a
  `StateTexture` / `AddTexture` pair from `ButtonStateBehaviorMixin` (the module
  parks them in a hidden frame). `Diel.lua` adds a day/night frame
  (`MinimapCluster.DielFrame`, on the container) and replaces
  `MinimapCluster.SetEditModeScale`.
- Bank: `BankFrame` (Blizzard_UIPanels_Game) differs per flavor. Retail
  (`Mainline\BankFrame.*`): one bank tab (98 slots, 7 rows filled column by
  column in pairs of columns) at a time, the Bank / Warband Bank tabs a
  `TabSystem` under the frame, the bank tabs (`BankPanelTabTemplate`, already
  the SpellBook-SkillLineTab art) down its side. Forever
  (`Camelot\BankFrame.*` over the Mainline `BankFrameTemplates.*`,
  `C_Bank.ShouldUsePlayerBagsInBank()` true): every slot of the bank and its
  bags on 8 columns, 88 a page (the frame grows 47px a row past six), the
  bag slots (`itemButtonBagPool`, 3/4 scale) under `BagText`, and one
  `LargeSideTabButtonTemplate` page tab per page (`bankPageTabPool`). Both
  build the slots from `BankPanel.itemButtonPool`, chaining each slot's
  anchor to the one before it; the bank holds no secure widgets.
- XP / reputation bars: `StatusTrackingBarManager` holds two containers
  (`MainStatusTrackingBarContainer`, `SecondaryStatusTrackingBarContainer`,
  Edit Mode systems), each with one bar per kind (`container.bars[barIndex]`,
  created at load) of which it shows one. Retail 12.1 has them in
  `Blizzard_ActionBar`, Forever in its own `Blizzard_StatusTrackingBar`
  (1192px containers with 20 segment dividers; XP has the lowest priority
  there, so reputation takes the main container). Their fill is a
  `GradualAnimatedStatusBar` (animated values, flipbook flares, atlases
  re-applied on every rest / standing change).

## Module conventions

- Every file registers itself with `ns:RegisterModule{ key, name, tooltip, live, parent }`.
  `live = true` modules implement `Enable()`/`Disable()` and can be toggled at
  runtime (cast bars, breath timers). `live = false` modules implement `Apply()`
  once at login and need a `/reload` to switch off, because Blizzard frames
  cannot be safely un-skinned.
- `parent = "unitframes"` marks a module as part of the Unit Frames option: no
  checkbox, no saved variable, follows the parent's state. Portraits, Health
  Bars and Power Bars are such parts — the user wants the unit frames to be
  all-or-nothing. Do not re-introduce separate options for them.
- Options are changed only through `ns:SetModuleEnabled(key, value)` (Core.lua):
  it saves the value, enables / disables a live module and notifies the
  listeners registered with `ns:OnSettingsChanged` (the options page and the
  wizard refresh from it). The options page is a canvas category
  (`Settings.RegisterCanvasLayoutCategory`, built on its first show); a
  reload-type change shows its reload banner (no popup). The setup wizard
  opens at login until it has been closed once (`db.setupDone`, set when it
  closes), for new installs and existing users alike (not in the session that
  shows the rename migration popup), and is the addon's own frame, never a UI panel:
  it closes on Esc through its own keyboard handler, not `UISpecialFrames`.
- Every window opens where the modern ones (vendor, mailbox) do: frame
  border on the panel spot. Vanilla art (384x512 files) has a 15px / 14px
  transparent margin (`ns.CLASSIC_ART_X/Y`, measured 2026-09-29), so a
  module drawing it on a Blizzard panel places everything from
  `ns.ArtOrigin(panel)` (the art's corner, which also undoes the panel's
  registered `xoffset`) and sets its hit rect with `ns.SetArtHitRect`; art
  the addon places itself uses `ns.ClassicArtLeft/Top`. Never anchor a
  secure widget to an origin frame (it would become protected).
- Previews never touch Blizzard's frames: they are drawn with the addon's
  own textures and frames. Only instantiate Blizzard templates without
  `$parent`-named children (they would create globals) and without secure
  or event-registering behaviour.
- Match the existing style: tabs, `local _, ns = ...` header, a doc comment
  block at the top of each file explaining *why*, short comments on non-obvious
  client behaviour, no globals except the saved variables (`ForevermoreClassicUIDB`
  account-wide, mirrored into `ForevermoreClassicUICharDB` per character; both
  globals reference the same table, see `InitializeDB` in `Core.lua`) and the
  slash command tables (and the quest log's secure buttons,
  `ForevermoreClassicUIQuestLogButton` and `...Map`: an override binding
  and a macro's /click can only click a button by name).
- Diagnostic slash sub-commands are temporary: remove them once the issue they
  were added for is fixed.
