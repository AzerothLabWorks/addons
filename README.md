# AzerothLabWorks addons

Small in-game tools for local WoW server projects. Choose the package for your client and server;
the WotLK, Legion and CoA variants are separate addons with separate settings.

| Addon | Target | Server requirement | Purpose |
|---|---|---|---|
| [GMCommandCenter](GMCommandCenter/) | WotLK 3.3.5a, interface 30300 | Compatible AzerothCore GM commands and account permission | GM command browser, items and mounts |
| [GMCommandCenter_Legion](GMCommandCenter_Legion/) | Legion 7.3.5 build 26365, interface 70300 | Matching Legion server commands and GM permission | Legion GM tools and collection browsers |
| [GMCommandCenter_CoA](GMCommandCenter_CoA/) | CoA client, interface 30300 | Reviewed CoA command profile; bot integration for bot buttons | Target-safe items, travel, bot roles and diagnostics |
| [CoAGatheringAlerts](CoAGatheringAlerts/) | CoA client with world-position/minimap APIs | g1-20261029 gathering component, protocol 1 | Live herb/mineral minimap pulses and sound |
| [CoALfgTracker](CoALfgTracker/) | CoA LFG objective tracker | g1-20261029 LFG status bridge, protocol 1 | Authoritative normal/heroic dungeon objective display |
| [COAResourceMonitor](COAResourceMonitor/) | CoA client, interface 30300 | None | Simultaneous health, mana, rage and energy |

The CoA packages are tied to the [coa-local-server](https://github.com/AzerothLabWorks/coa-local-server)
**g1-20261029** source profile. They do not include a game client, game assets, credentials,
character databases, premium collections, or the environmental enhancement packages. A 30300
TOC alone is not evidence of stock WotLK compatibility.

**Looking for WeakAuras?** Use the separate [WeakAuras for CoA guide](docs/weakauras-coa.md) and
[5.21.2-alw.1 compatibility download](https://github.com/AzerothLabWorks/addons/releases/tag/weakauras-coa-5.21.2-alw.1).
It identifies the reviewed Ascension fork, our small cooldown fix, the separate shared range-library repair for CoA range checks,
and the original component licenses. It is separate from the four packages below and is not installed by
`Install-CoAAddons.ps1`. Retail WeakAuras is not a substitute.

## Install CoA addons

Download the [G1 addon release](https://github.com/AzerothLabWorks/addons/releases/tag/g1-20261029) for
ready-made ZIPs, `release.json` and `SHA256SUMS`. Keep all four ZIPs and `release.json` together when using
the verified installer below. The installer script is included in the tagged source download.

For downloaded ZIPs, save the [tagged installer](https://raw.githubusercontent.com/AzerothLabWorks/addons/g1-20261029/scripts/Install-CoAAddons.ps1)
alongside them and run it with PowerShell 7; no Python build is needed:

```powershell
pwsh ./Install-CoAAddons.ps1 -ClientPath 'C:\Games\MyCoAClient' -PackageDirectory . -Action Check
pwsh ./Install-CoAAddons.ps1 -ClientPath 'C:\Games\MyCoAClient' -PackageDirectory . -Action Install
```

With the game closed, copy the selected addon folders into your existing client's
`Interface/AddOns` folder. The TOC must be immediately inside each addon folder; avoid an extra
`addons-main` or version-directory layer. Restart the client and enable the addon at character
selection. Keep the two server-dependent addons paired with the matching server profile.

To build those same four ZIPs from source instead, use Python 3.10+:

```powershell
python tools/coa-release/package.py --output dist/coa-g1-20261029
pwsh scripts/Install-CoAAddons.ps1 -ClientPath 'C:\Games\MyCoAClient' -PackageDirectory dist/coa-g1-20261029 -Action Check
pwsh scripts/Install-CoAAddons.ps1 -ClientPath 'C:\Games\MyCoAClient' -PackageDirectory dist/coa-g1-20261029 -Addons CoAGatheringAlerts,COAResourceMonitor -Action Install
```

`Check` is the default and writes nothing. The PowerShell 7 installer validates release/package
hashes and the complete archive inventory before installing. Installation requires all game
clients/launchers closed. Each run backs up only the selected addon folders beside the client,
records an installation receipt, and preserves `WTF` and unrelated addons. Use the printed receipt:

```powershell
pwsh scripts/Install-CoAAddons.ps1 -ClientPath 'C:\Games\MyCoAClient' -Action Rollback -ReceiptPath '<printed path>\installed.json'
```

Rollback refuses to overwrite addon files modified after installation. It restores the previous
folders, or removes only newly installed folders into the backup. No server commands are run by
this installer. Server installation, data extraction and matching server configuration belong in
the server repository. Use a new output directory when rebuilding packages.

## What is verified

The G1 versions of all four CoA addons have been used in the local CoA project. Gathering visual
pings and LFG objective/completion behavior received player confirmation. The community GM realm
confirmation UI and portable installer are changes tested offline; rendered acceptance and a
fresh community installation remain separate acceptance tasks. No other WoW versions are claimed.

```powershell
python -m pip install -r tools/coa-release/requirements.txt
python tools/coa-release/test.py
pwsh tools/coa-release/test-installer.ps1
```

Tests use Lua 5.1 with mocked WoW APIs, generated packages and disposable fake client directories.
They never connect to a server or modify an installed game. CI runs these checks. Optional accepted
DBC validation for the LFG catalog is documented separately; game data is not committed here.

## Roadmap

- First community acceptance: install on a fresh local CoA server/client from the matching source profile.
- Validate realm opt-in, target-safe GM commands, resource formatting, tracker completion and gathering sound/alignment.
- Maintain versioned ZIP assets and checksums with the matching server release.
- Add a capability/status display for missing or mismatched server components.
- Consider configurable gathering sound, cooldown and visual styling after real-world feedback.
- Keep environmental patches and third-party addon downloads optional, credited and independently versioned.
- Keep the separate Ascension WeakAuras package pinned, with source provenance, component notices and the matching client range repair.
- Keep WotLK/Legion improvements on their own reviewed release tracks; they are unchanged by this CoA import.

The [full server/gameplay roadmap](https://github.com/AzerothLabWorks/coa-local-server/blob/main/docs/roadmap.md)
tracks the wider project. Broad gameplay feature expansion is paused in favor of regular reviewed
upstream updates, playerbot improvements and dungeon acceptance. Conversational LLM bots remain
backlog work. Bot population increases are separate measured changes, never part of an addon or
upstream update. This community release preserves that focus while making the existing work reproducible.

See [PROVENANCE.md](PROVENANCE.md) for source origins and [NOTICE-CoA.md](NOTICE-CoA.md) for the
GPL-2.0-or-later scope of the authored CoA additions. Existing WotLK/Legion components are not
silently relicensed by this packaging work and are excluded from the generated CoA ZIP releases.
