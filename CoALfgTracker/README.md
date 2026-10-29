# CoA LFG objective tracker

This ordinary addon supplements only the existing `LFGObjectiveTracker` objective callback. It does not patch
MPQs, native functions, the shared boss tracker, Manastorm, Mythic+, loot rolling, rewards, or gameplay state.
Install its three runtime files in `Interface/AddOns/CoALfgTracker/` only after the corresponding server status
bridge has been qualified. A full client restart discovers the addon; installation is a separate step.

## Authoritative status

The client asks the server for the current player's own LFG status through a self-whisper addon message:

```text
Prefix: COA_LFG_STATUS
Request: Q|1|nonce
Response: S|1|nonce|map|difficulty|instance|group|dungeon|encounter|creditType|creditEntry|completed
Unsupported/no current status: N|1|nonce
```

`difficulty` is zero-based (0 normal, 1 heroic). `group` is the decimal raw 64-bit group GUID and is retained
as a string, never converted to a Lua number. Other numeric fields are unsigned 32-bit integers; `completed`
is 0 or 1. A response is accepted only for the outstanding nonce, from the self-whisper identity, in the
current supported map/difficulty, and when all encounter metadata matches the packaged reviewed table.

The server must derive status from the requester's actual group, current instance and selected LFG dungeon.
It must not trust client-supplied completion, grant rewards, change encounter state, complete quests, or
accept another player's request as this player's status. An ambiguous or missing final-encounter mapping
must return `N`, not guess from another wing on the same map.

Polling occurs every five seconds only inside a supported LFG dungeon. Death and reward events can request
a refresh, but never mark an objective complete themselves. Map/dungeon/party changes invalidate outstanding
requests and the previous snapshot. No completion state is saved across UI reloads; a fresh server snapshot
restores it. Specific-queue completion therefore does not depend on receiving a random-dungeon reward.

## Data provenance and compatibility

`CoALfgTrackerData.lua` records are keyed by encounter ID. Each row is:

```text
{ mapId, difficulty, finalDungeonId, creditType, creditEntry, EnglishFallbackName }
```

The 131 rows were joined read-only from the G1 `instance_encounters` table and its accepted
`DungeonEncounter.dbc` / `LFGDungeons.dbc` data on 2026-10-18. Included rows have matching map/difficulty,
an existing encounter and dungeon record, dungeon type 1, expansion 0–2, and difficulty 0–1. There are
64 BC/Wrath mappings (16 normal and 16 heroic for each expansion); the remaining rows cover Classic and
its supported wings. The name from the client's valid `GetEncounterInfo(encounterId)` takes precedence
over the packaged English fallback.

Accepted `DungeonEncounter.dbc` SHA-256:
`f02642f3a02302f8b6d965a2ab3c0adb4f5b73117c6e0ece04bbb2c0facdded9`.
The table is a validation/fallback catalog, not a declaration that all listed dungeons have been play-tested.
Legacy queue aliases without a unique own final encounter, unsupported maps, raids, and custom/mythic modes
retain the original tracker behavior. The addon does not alter existing native boss lookup globals.

## Qualification

The community suite `python tools/coa-release/test.py` executes the packaged Lua with Lupa's Lua 5.1
backend. For the optional read-only accepted-data check, run
`python tools/coa-release/test_lfg.py --dbc-dir <your-matching-dbc-directory>` after installing the
test requirements. Without those external files, the DBC check is explicitly skipped. No game data
is included in the packages. The matching server release must qualify its status bridge and completion
behavior separately; the client test does not prove rewards or server-side encounter completion.

This package requires the `g1-20261029` server profile with `COA_LFG_STATUS` protocol 1. Copy the entire
folder to `<CoA client>/Interface/AddOns/` while the client is closed, or use the root installer.

## License

Copyright (C) 2026 AzerothLabWorks. The authored Lua code is GPL-2.0-or-later, without warranty;
see `COPYING`. Catalog provenance is stated above; this grant makes no claim over underlying
game data, names or third-party assets. No DBC or client assets are bundled.

Coverage includes all 131 catalog rows, localized/fallback names, normal/heroic separation, authoritative
completion after reload, same-map new runs, spell-credit encounters, stale responses, malformed messages,
wrong senders, throttling, and preservation of unsupported/native paths. A live client check remains necessary
for rendered objective updates and the separate random-reward/completion-banner behavior.
