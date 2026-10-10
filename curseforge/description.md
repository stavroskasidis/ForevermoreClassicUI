# CurseForge project text

Copy-paste material for the CurseForge project page. `logo.png` (400x400) is
the project avatar; `logo-1024.png` is the same at a larger size if a bigger
image is ever needed. Regenerate both with `python curseforge\make_logo.py`.

## Project name

Forevermore Classic UI - Forever & Retail

(The in-game title, `## Title:` in the `.toc`, is the short "Forevermore Classic
UI"; the addon folder is `ForevermoreClassicUI`.)

## Summary (short field, under 256 characters)

The best Classic UI addon. Make the UI as Classic as you want. Reskins the UI, does not replace it, so everything keeps working. Classic unit frames, action bars, minimap, nameplates and many more, each switchable. Controller UI also supported.

## Categories

- Unit Frames (primary)
- Miscellaneous

## Game versions

One file for both: upload `build\ForevermoreClassicUI-<version>.zip` and tick
every supported version in the file's Game Version field:

- WoW Retail: 12.1.x
- WoW Forever: 1.60.x

# Description

**The classic look for WoW Forever and Retail, without breaking the modern UI.**

- **Reskin, not replacement:** Blizzard's own frames with the vanilla art. Every new Blizzard feature keep working.
- **Pick what you want:** every element has its own Modern / Classic switch.
- **User Fiendly:** setup wizard on first login: one-click presets, or choose element by element.
- **Controller support:** works with WoW Forever's controller UI.

## What it changes

- **HUD:** Unit Frames, Combo Points\*, Cast Bars, Buffs, Nameplates, Breath & Fatigue Bars, Quest Tracker
- **Action bars:** Bar Art, Gryphons, XP & Reputation Bars, Bags, Micro Menu
- **Minimap:** Minimap, Group Finder Eye
- **Windows:** Window Frames (vendor, mail, quests, trade, social,
  inspect and more), Quest Log, Game Menu, Loot, Loot Rolls, Trainer, Bank, Auction House,
  Character\*, Spellbook\*, Talents\*, Professions\*, Looking For Group\*, Social\*

\* _WoW Forever only_

## Options

`/fmcui` or **Options > AddOns > Forevermore Classic UI**.
`/fmcui setup` reopens the wizard.

## Known limitations

- Friendly nameplates in dungeons and raids stay modern (Blizzard locks them).

## Upgrading from Classic UI Restoration

This addon used to be called **Classic UI Restoration**. If its old
`ClassicUIRestoration` folder is still in `Interface\AddOns`, the first login
copies its settings over and disables it; delete that folder afterwards.
Without the old folder the options start from their defaults.

## Feedback

Use the issues option above to open a Github Issue for bugs and requests.