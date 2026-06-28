# GM Command Center

GM Command Center is a WotLK 3.3.5a addon for AzerothCore GM workflows. It gives you an in-game panel for common GM commands, command search, quick actions, and server-side lookup helpers.

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
- **Mount** button next to **Spells** that opens an offline Mounts spell browser with speed/type details and Learn buttons.
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

## Mount Browser

Use the **Mount** button next to **Spells** to browse offline mount spell data from the WotLKDB Mounts spell category.

```text
.learn <spellId>
```

The top search box filters mount names, spell IDs, speed values, movement types such as `Ground`, `Flying`, or `Aquatic`, and class requirements when present. Use **Prev** and **Next** to browse broader result sets, then click **Learn** on a result to run `.learn <spellId>`.

## Important Limitation

The WotLK 3.3.5a addon sandbox cannot browse websites directly or make arbitrary HTTP requests. Search/result tooling should use AzerothCore GM commands or carefully scoped offline data.
