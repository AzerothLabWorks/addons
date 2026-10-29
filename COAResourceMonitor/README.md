# CoA Resource Monitor

Displays your health, mana, rage and energy together, useful for CoA classes that use multiple
resources. It reads client values only; no server module or GM permission is required.

Copy this folder into `<CoA client>/Interface/AddOns/` with the client closed, then restart.
Drag the panel with the left mouse button. `/crm lock`, `/crm unlock` and `/crm reset` control
movement and restore the default position. Position and lock are stored in `COAResourceMonitorDB`.

The monitor listens to resource events and refreshes at most ten times per second. A resource
whose reported maximum is initially zero remains visible with a placeholder maximum until the
client reports its real value. Rage values above a 100-point maximum are displayed in tenths.

This is the two-file v1.0.0 source recovered from the deployed AzerothLabWorks G1 client on
2026-10-29; its TOC credits AzerothLabWorks. The initial authoring receipt was not found during
the targeted inventory. The files are preserved unchanged in this release. CoA gameplay use
is established; other client versions have not been qualified.

## License

Copyright (C) 2026 AzerothLabWorks. This authored addon code is GPL-2.0-or-later, without warranty;
see `COPYING`. No game texture assets are bundled.
