# GM Command Center

GM Command Center is a WotLK 3.3.5a addon for AzerothCore GM workflows. It gives you an in-game panel for common GM commands, command search, quick actions, and class-aware lookup helpers.

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
- Wildcard-aware command search. Examples: `lookup*`, `*spell`, `tele*name`.
- Parameter box that builds the final command before execution.
- Server-side `.help` shortcut for the selected command.
- Class-aware spell search with one-click `.learn` actions.
- Class-aware item search with one-click `.additem` actions and level/faction usability filtering.
- Mount-only item search with one-click `.additem` actions.
- Quick action buttons for common GM commands.

## Name Search and Wildcards

Use the command search to find GM commands by name or text:

```text
frostbolt
frost*
*bolt
*greater heal*
```

The addon understands wildcards in its command search.

For money commands, use the command browser's **Character** category and select `modify money`.

## Class Search

Use **Class Search** on the command page to filter spells and items by class.

Examples:

```text
Class: Mage
Search: frost
Spells

Class: Priest
Search: heal
Spells

Class: Paladin
Search: plate
Items

Class: All
Search: swift
Mounts
```

Supported class names are `Warrior`, `Paladin`, `Hunter`, `Rogue`, `Priest`, `Death Knight`, `Shaman`, `Mage`, `Warlock`, and `Druid`. The class field defaults to your current character's class. You can also use `me` or `player` for your current class, or `All` / `*` to search without a class filter.

For item and mount searches, **Use my level** is enabled by default. When it is checked, the addon only returns items whose required level is less than or equal to your current character level. Uncheck it and enter a manual level to search for items suitable for another level range. Item and mount searches also filter by class and by your current faction when the item has race/faction restrictions.

## Important Limitation

The WotLK 3.3.5a addon sandbox cannot browse websites directly or make arbitrary HTTP requests. Search/result tooling should either use AzerothCore GM commands or a carefully scoped offline data file.
