# GM Command Center - CoA

A focused companion for the AzerothLabWorks **CoA g1-20261029** command profile. Uses the existing
3.3.5a/30300 addon interface and CoA commands; no addon-specific server module, HTTP service, credentials,
character migration, or client patch archive is required.

## Open and enable

Open `/coagm` or `/cgm`, or click the movable **CoA GM** launcher. Enable commands using the
checkbox after checking the realm and character shown in the header, then accept the realm confirmation.
Commands start disabled for every new character and realm. Confirmation is saved only for that character
on that exact realm; existing settings without confirmation start disabled. Server permissions remain
authoritative: the addon does not grant GM access. Right-click the launcher to reset its position.

## Tools

- **Quick Tools:** repair yourself, revive yourself, remove only resurrection sickness, save.
- **Items:** explicitly search the server by name, inspect native item tooltips, choose a quantity
  from 1 to 200, and give an item to your own named character. An item-ID field is also available.
  Results, favourites and the last 20 requested items are separate views. Recent means requested,
  not proof that a grant succeeded. Up to 50 favourites are kept per category.
- **Travel:** search CoA teleport destinations and teleport using their server-returned links.
  Saved favourites retain those links. Plain numbers are not passed as teleport destinations:
  this CoA command interprets those as names. Removed destinations may need a new search.
- **Bots:** recruit one tank, healer or DPS, or send follow/stay/summon to an existing normal party.
  Bot recruitment uses the server's existing role preparation and teleport behaviour. Bot command security
  still applies. Detailed settings remain in **UnBot**, accessible from a shortcut.
- **Diagnostics:** server information, selected-NPC information, selected-unit/self position,
  and your status for a quest ID. A local, bounded session log can be copied manually as a report.
  Reports include character, realm, zone and target context; review before sharing. Nothing uploads.

Item grants, repairs and revives explicitly name your character even when a bot is selected.
**Save and Remove Rez Sickness require either no target or yourself selected.** These commands
do not accept a named recipient, so the addon refuses to send them with another target selected.
It never changes your target automatically. Mutation shortcuts are blocked during combat.

## Status and limitations

Only one request is outstanding at a time; there is no command queue or automatic retry.
Lookups collect at most 100 rows, finish after one second without new matching results, and time
out after eight seconds. A one-second cooldown separates requests. Refine broad searches if
results are limited. Typing in the search field alone sends nothing.

The current command protocol has no request IDs or response terminator. The addon collects only
`CHAT_MSG_SYSTEM` during the pending request, matches item/teleport links, and recognises the
current English server messages. Avoid issuing other GM commands while a request is pending.
Late or unrelated messages cannot reliably be attributed by this protocol. Other localisations
may result in an unconfirmed status rather than a recognised response.

- **Sent:** the client sent the request; success is not yet established.
- **Confirmed:** matching search results or a recognised repair/save/diagnostic response arrived.
- **Failed:** the client rejected unsafe input or the server reported an error.
- **Unknown:** there was no conclusive response, or the world changed during the request.

Item grants, resurrection, sickness removal, bot orders and teleportation do not always return
an acknowledgement through system chat. Inspect the result in game rather than interpreting
silence as success or failure. A bag-space failure can follow a partial item grant: always inspect
your bags before repeating it. The addon does not automatically repeat a request on reload,
login, timeout or zone changes. Check normal chat for messages not recognised by this tool.

The first release deliberately excludes bulk spell/recipe learning, character resets, item
removal, quest completion/rewards, NPC/world edits, bot re-gearing, and server restart/shutdown.
Vanity, Wardrobe and the Book of Artisans remain the existing interfaces for their functions.

## Installation and removal

With the client fully closed, copy this entire folder to:

`<your CoA client>\Interface\AddOns\GMCommandCenter_CoA`

Enable **GM Command Center - CoA** on the character-selection AddOns screen. Restart the client
after a new installation. No server restart is needed. Disable the addon on that screen to roll
back; the addon has no server-side install or automatic startup changes. Settings are held in
`CoAGMCCDB`, separately from the WoTLK/Legion GM tools and existing UnBot settings.

## Qualification

The repository test harness in `tools/coa-addon-tests/` checks the Lua command logic with mocked
WoW APIs under Lua 5.1. Run the complete community suite with `python tools/coa-release/test.py`.
Those tests do not replace rendered-client or live-server acceptance. The community realm confirmation
UI has automated coverage; its rendered acceptance on additional realms remains pending.

Suggested acceptance checks:

1. Open the panel, verify the realm/name, and opt in. Confirm other characters start disabled.
2. Search `overcharged capacitor`; give one to yourself while a bot is selected. Inspect your bag.
3. Confirm Save and Remove Rez Sickness refuse an unrelated target; clear the target and retry.
4. Favourite an item/destination; close/reopen the UI and later relog to check persistence.
5. Search a familiar safe destination and teleport out of combat.
6. Use a role recruitment button with a free party slot, then follow/stay; open UnBot as needed.
7. Check a quest's status and copy a report. Confirm no quest state was changed.

The UI conventions reuse the existing WoTLK GM Command Center approach. Legion's catalogue
and collection APIs are intentionally not copied into this CoA package.

This addon does not translate arbitrary AzerothCore/TrinityCore command dialects. The item and travel
commands, target rules, response parsing and `.playerbots coa` commands must match the documented
CoA server profile. An interface number of 30300 does not establish server compatibility. English
system messages are currently required for recognised responses. See the root compatibility table.

## License

Copyright (C) 2026 AzerothLabWorks. This authored CoA addon code is GPL-2.0-or-later, without warranty;
see `COPYING`. This does not relicense the separate pre-existing WotLK/Legion addons or game assets.
