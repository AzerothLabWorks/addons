# GM Command Center

GM Command Center is a WotLK 3.3.5a addon for AzerothCore GM workflows. It gives you an in-game panel for common GM commands, command search, quick actions, and a simple money helper.

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
- Money helper on the command page converts gold/silver/copper input to copper and runs `.modify money`.
- Class-aware spell search with one-click `.learn` actions.
- Class-aware item search with one-click `.additem` actions.
- Optional item filtering by the current player level or a manual level.
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

For money, enter gold/silver/copper in the **Money** fields and click **Give Money**. The addon converts that amount to copper and runs `.modify money #copper` against the selected player. If you do not have a player selected, the addon targets your own character first, waits briefly for selection to update, then sends the command.

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
```

Supported class names are `Warrior`, `Paladin`, `Hunter`, `Rogue`, `Priest`, `Death Knight`, `Shaman`, `Mage`, `Warlock`, and `Druid`. You can also use `All` or `*` to search without a class filter.

For item searches, **Use my level** is enabled by default. When it is checked, the addon only returns items whose required level is less than or equal to your current character level. Uncheck it and enter a manual level to search for items suitable for another level range.

## Important Limitation

The WotLK 3.3.5a addon sandbox cannot browse websites directly or make arbitrary HTTP requests. Search/result tooling should either use AzerothCore GM commands or a carefully scoped offline data file.
