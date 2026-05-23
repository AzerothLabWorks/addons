# GM Command Center

GM Command Center is a WotLK 3.3.5a addon for AzerothCore GM workflows. It gives you an in-game panel for common GM commands, command search, quick actions, and lookup/action helpers for items, spells, creatures, quests, and teleports.

## Install

Copy the `GMCommandCenter` folder into:

```text
World of Warcraft 3.3.5a\Interface\AddOns\GMCommandCenter
```

Then enable `GM Command Center` from the AddOns button on the character select screen.

## Use

Open it in game with:

```text
/gmcc
/agm
```

The addon sends AzerothCore GM commands through chat, so your account still needs the correct GM security level. Commands that act on a player, NPC, or object still follow normal AzerothCore targeting rules.

## Current Features

- Searchable command browser with categories and security levels.
- Parameter box that builds the final command before execution.
- Server-side `.help` shortcut for the selected command.
- Lookup panel for `.lookup item`, `.lookup spell`, `.lookup creature`, `.lookup quest`, and `.lookup teleport`.
- Action buttons for `.additem`, `.learn`, `.go creature id`, `.quest add`, and `.teleport`.
- WotLKDB URL helper for ID-based lookups such as `https://wotlkdb.com/?item=40684`.

## Important Limitation

The WotLK 3.3.5a addon sandbox cannot browse `wotlkdb.com` directly or make arbitrary HTTP requests. To provide true offline database browsing in-game, the next step is to generate Lua data files from the AzerothCore world database tables, such as `item_template`, `creature_template`, `quest_template`, `game_tele`, and DBC-derived spell data.

The current addon uses AzerothCore's own lookup commands as the live in-game search path and provides WotLKDB URLs for external reference.
