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
- Wildcard-aware command search. Examples: `lookup*`, `*spell`, `tele*name`.
- Parameter box that builds the final command before execution.
- Server-side `.help` shortcut for the selected command.
- GM Tools panel for `.lookup item`, `.lookup spell`, `.lookup creature`, `.lookup quest`, `.lookup teleport`, money, and typed item searches.
- Captures recent server lookup responses from chat, filters them by lookup type, and displays them in the GM Tools tab.
- Spell lookup results include **Learn** and **Aura** buttons when a spell ID can be detected.
- Item lookup results include **Add xN** and **Add 1** buttons when an item ID can be detected.
- Item rows display item type, item level, and required level when the ID exists in the local AzerothCore metadata.
- Spell rows display required level and inferred class/profession bucket when the ID exists in trainer metadata.
- Quest and creature lookup results include action buttons when IDs can be detected.
- Money helper converts gold/silver/copper into `.money #copper`.
- Offline container search lists bag ID, name, slots, type, and bag family, with an **Add xN** button.
- Action buttons for `.additem`, `.learn`, `.go creature id`, `.quest add`, and `.teleport`.
- WotLKDB URL helper for ID-based lookups such as `https://wotlkdb.com/?item=40684`.

## Name Search and Wildcards

Use the GM Tools server search to search by names such as:

```text
frostbolt
frost*
*bolt
*greater heal*
```

The addon understands wildcards in its own UI search. AzerothCore lookup commands search by substring, so wildcard lookup terms are converted to the strongest substring before the command is sent. For example, `*greater heal*` is sent as `.lookup spell greater heal`.

ID-only actions such as `Learn Spell`, `Go Creature ID`, and `Add Quest` require a numeric ID. Search by name first, then run the action with the returned ID.

For spell workflows such as Riding, search by name from the GM Tools tab:

```text
Riding
```

Click **Lookup Spell**, then use the **Learn** button next to the captured result you want.

Spell and item server lookups are type-filtered. A spell lookup ignores item-link result lines, and an item lookup ignores spell-link result lines.

For item workflows, set **Count / extra**, search by item name, click **Lookup Item**, then use **Add xN** beside the captured result.

For container workflows, use **Items: Containers** in the **GM Tools** tab. Search `*` for all containers, or search terms like `herb`, `mining`, `soul`, or `16 slots`.

For money, enter gold/silver/copper in the **Money** fields and click **Give**. This runs `.money` against the selected player, or yourself if no valid player target is selected.

## Important Limitation

The WotLK 3.3.5a addon sandbox cannot browse `wotlkdb.com` directly or make arbitrary HTTP requests. To provide true offline database browsing in-game, the next step is to generate Lua data files from the AzerothCore world database tables, such as `item_template`, `creature_template`, `quest_template`, `game_tele`, and DBC-derived spell data.

The current addon uses AzerothCore's own lookup commands as the live in-game search path and provides WotLKDB URLs for external reference.
