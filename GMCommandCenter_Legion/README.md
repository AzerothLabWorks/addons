# GM Command Center - Legion

A separate GM helper for World of Warcraft Legion 7.3.5 build 26365 and the AzerothLabWorks Legion server. It does not replace or share settings with the WoTLK `GMCommandCenter` addon.

## Install

Copy the complete `GMCommandCenter_Legion` directory into:

```text
World of Warcraft 7.3.5\Interface\AddOns\GMCommandCenter_Legion
```

At character selection, open **AddOns** and enable **GM Command Center - Legion**. Enable **Load out of date AddOns** only if the client reports it as out of date; its interface number is already pinned to `70300`.

## Open the panel

```text
/lgmcc
/lgm
```

The movable **LGMCC** button also opens the panel. Drag it to reposition it or right-click it to reset its position.

## Legion mount browser

Select the **Spells** category and click **Mount**. The browser reads the client’s live 7.3.5 Mount Journal, including mounts that have not yet been collected.

- Search by mount name or spell ID.
- Search `Collected`, `Not collected`, or `Favorite`.
- Hover a row for the normal spell tooltip.
- Click **Learn** to run `.learn <spellID>`.

Close and reopen the mount browser after learning mounts to refresh collection status.

## Commands

Commands and quick actions are tailored to the LegionCore command table, including `.tele`, `.repairitems`, `.addmythickey`, Legion lookups, character controls, NPC tools, quests, and server management.

The addon sends commands through in-game chat. Your account must have the required GM security level, and commands acting on another unit follow normal targeting rules.

The WoTLK addon remains in `GMCommandCenter` with its original `/gmcc` and `/agm` commands and `GMCommandCenterDB` settings. This Legion version uses `/lgmcc`, `/lgm`, and `GMCommandCenterLegionDB`.
