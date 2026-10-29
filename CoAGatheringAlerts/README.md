# CoA Gathering Alerts

Local minimap pulses and the familiar MapPing sound for nearby active herbs and minerals.
Enable **Find Minerals** or **Find Herbs** normally. Alerts are enabled by default and never send
a minimap ping to other players. No historical spawn database is included.

- `/gatherping status` shows the current settings.
- `/gatherping on` or `/gatherping off` enables or disables alerts for this character.
- `/gatherping sound` toggles the sound.

Copy this entire folder into `<CoA client>/Interface/AddOns/` while the client is closed, or use
the root installer. Restart the client after installation. Saved variables are per character in
`CoAGatheringAlertsDB`; uninstalling the addon does not remove those settings.

## Matching server and client

Requires the [coa-local-server](https://github.com/AzerothLabWorks/coa-local-server) **g1-20261029**
gathering component, `COAGATHER` protocol 1. A standalone addon cannot discover these nodes on
servers without that component. This version uses CoA's `Minimap:GetViewRadius()`,
`GetCurrentPlayerPosition()` and `GetActiveMapID()` APIs. Stock WotLK, Legion and Retail are not
verified targets even when an addon loader accepts the TOC.

The client requests only its own tracked nodes using private addon self-whispers. Snapshots must
match the current request and map, expire after 2.5 seconds, and contain at most 12 nodes. The
server filters live, visible, correctly phased nodes and excludes bots from this query path.
The addon pulses up to three new nearby nodes at a time, with an eight-second batch cooldown.
A node must be absent for 60 seconds to become new again. Death, map changes and tracking changes
discard stale state. Tracking does not imply that your skill is high enough to harvest a node.

## Evidence and scope

The original G1 build passed server and Lua 5.1 tests, and the player confirmed visual pings on
live nodes. The 58-check mocked-client suite is included in `tools/coa-gathering-tests/cases.lua`.
Automated checks cannot establish real sound output or rendered alignment on another client.
During acceptance, test stationary/rotating minimaps, tracking changes and harvesting a node.

## License

Copyright (C) 2026 AzerothLabWorks. This authored addon code is GPL-2.0-or-later, without warranty;
see `COPYING`. Game texture and sound references use the user's existing client; no assets are bundled.
