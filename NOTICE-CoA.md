# License scope for the CoA community additions

Copyright (C) 2026 AzerothLabWorks.

The authored CoA addon code and community tooling added for this release are available under
the GNU General Public License, version 2 or (at your option) any later version
(`GPL-2.0-or-later`). They are provided without warranty. See `COPYING-CoA` in this repository
and `COPYING` in each addon package for the full GPL version 2 text.

This grant covers these new directories and release files:

- `GMCommandCenter_CoA/`, `CoAGatheringAlerts/`, `CoALfgTracker/`, `COAResourceMonitor/`
- `scripts/Install-CoAAddons.ps1`, `tools/coa-addon-tests/`, `tools/coa-gathering-tests/`, `tools/coa-release/`
- The CoA release manifest, documentation and CoA CI workflow.

It does **not** change the license of the pre-existing `GMCommandCenter/`,
`GMCommandCenter_Legion/` or `tools/legion-*` content. Their missing or inherited licensing
information must be resolved separately before a combined release that redistributes them.

The CoALfgTracker catalog's data sources and accepted hashes are recorded in its README. This
notice does not claim ownership of game names, underlying client data, or third-party assets.
No game executable, DBC, MPQ, texture or sound file is included. References to textures and the
MapPing sound use resources already present in the user's compatible client. Test dependencies
such as Lupa are installed separately and keep their own licenses.
