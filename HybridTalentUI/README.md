# Hybrid Talent UI

Hybrid Talent UI is a WotLK 3.3.5a addon for the AzerothCore Hybrid Lab development branch. It provides an addon-first interface for cross-class spell and talent browsing, learning, and unlearning.

This addon is designed for:

```text
AzerothLabWorks/azerothcore-hybrid-lab
branch: codex/hybrid-race-class-qa
```

## Install

Copy the `HybridTalentUI` folder into your WoW 3.3.5a client:

```text
World of Warcraft 3.3.5a\Interface\AddOns\HybridTalentUI
```

Example Windows path:

```text
C:\Games\WoW-3.3.5a-HD-Test\Interface\AddOns\HybridTalentUI
```

Then restart WoW, or reload the UI, and enable `Hybrid Talent UI` from the AddOns button on the character select screen.

## Server Requirement

The addon requires the Hybrid Talent System server module from the Hybrid Lab dev branch. It will not work on a normal AzerothCore server unless that server has the matching module, SQL, and core patches installed.

Recommended dev setup repo:

```text
https://github.com/AzerothLabWorks/azerothcore-hybrid-lab/tree/codex/hybrid-race-class-qa
```

## Use

Open it in game with:

```text
/hybridui
```

The addon also creates a movable Hybrid launcher button near the microbar. Left-click it to open or close the Hybrid Training window.

## Current Features

- Spell and talent tabs in one interface.
- Class browsing for Warrior, Paladin, Hunter, Rogue, Priest, Death Knight, Shaman, Mage, Warlock, and Druid.
- Spell and talent icons with native tooltip descriptions.
- Search and availability filters.
- Left-click to learn supported hybrid spells and talents.
- Right-click to unlearn supported hybrid spells and talents.
- Known filter support for learned hybrid spells/talents.
- Action-bar preservation for learned hybrid spells and talent-granted spells.
- Shaman weapon imbue reminders for main-hand and off-hand temporary weapon enchants.

## Weapon Imbue Reminder

The QA addon can remember the last supported shaman weapon imbue the player cast and show separate movable `MH` and `OH` reminder buttons when the main-hand or off-hand temporary enchant is missing or close to expiring. The buttons use client-side `GetWeaponEnchantInfo()` state and do not change server spell validation.

Tested shaman imbues:

- Rockbiter Weapon
- Flametongue Weapon
- Frostbrand Weapon
- Windfury Weapon
- Earthliving Weapon

Useful commands:

- `/hyui imbue` shows reminder status.
- `/hyui imbue on` enables reminders.
- `/hyui imbue off` disables reminders.
- `/hyui imbue reset` clears remembered imbues and saved reminder positions.
- `/hyui imbue threshold <seconds>` changes the low-duration reminder threshold.

Rogue poison reminders are not implemented yet. Follow-up QA targets include Rogue poisons and other temporary weapon effects once those characters are being tested.

## Spell Descriptions

The addon prefers curated server descriptions when available. If the server sends an imported trainer fallback such as `Paladin - Trainer` or `Priest - Trainer`, the addon displays the native client spell tooltip description instead so broad trainer imports still read cleanly in the Hybrid Training list.

## Notes

Hybrid point totals, spell availability, talent availability, dependency checks, learning, unlearning, refunds, and persistence are handled server-side by the Hybrid Talent System module. The addon is the client interface for that server support.
