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

## Legion heirloom browser

Select **Items**, then click **Heirloom**. The browser reads the canonical
heirloom catalog from the 7.3.5 client's `C_Heirloom` collection API instead of
using the WoTLK heirloom-quality item list.

- Search by item name, item ID, equipment slot, armor or weapon type, or
  `Collected` / `Not collected`.
- Hover a row for the normal item tooltip.
- Click **Add** to run `.additem <itemID> 1`.

The list is rebuilt when the browser opens so collection state remains current.

## Legion armor and weapon browser

Select **Items**, then click **Armor** or **Weapons**. These browsers use the
69,088 equippable item records extracted from the server's enUS build-26365
`Item.db2` and `ItemSparse.db2` files, rather than a modern retail database.

- Search by item name or item ID.
- Filter required level by **At/Below My Level**, **No Requirement**, or
  ten-level ranges through level 110.
- Filter armor by material (Cloth, Leather, Mail, Plate, Shields, Cosmetic, or
  Miscellaneous) and weapons by family (Axes, Maces, Swords, Daggers, Staves,
  Warglaives, ranged families, and more).
- Search by slot or subtype, such as `Head`, `Plate`, `Dagger`, or `Two-Hand`.
- Search by quality, such as `Epic`, `Legendary`, or `Artifact`.
- Search item level with terms such as `ilvl 910`.
- Search required level with terms such as `req 110`.
- Hover a row to see the client's complete native item tooltip, including all
  stats and requirements.
- Click **Add** to run `.additem <itemID> 1`.

The browser caches the current search results for fast paging. Any change to
the search field rebuilds that cache. Its catalog is stored as compact text
chunks and decoded only when Armor or Weapons is opened, keeping normal login
and reload times close to the earlier addon version.

## Commands

Commands and quick actions are tailored to the LegionCore command table, including `.tele`, `.repairitems`, `.addmythickey`, Legion lookups, character controls, NPC tools, quests, and server management.

The addon sends commands through in-game chat. Your account must have the required GM security level, and commands acting on another unit follow normal targeting rules.

The WoTLK addon remains in `GMCommandCenter` with its original `/gmcc` and `/agm` commands and `GMCommandCenterDB` settings. This Legion version uses `/lgmcc`, `/lgm`, and `GMCommandCenterLegionDB`.
