# CoA package provenance

This import was prepared on 2026-10-29 from the user's tested G1 project, on top of public addon
commit `9ba27c4fa742be7af3a0ff7196db314fbd8e7ccb`. Existing WotLK/Legion directories remain unchanged.

| Component | Source and changes |
|---|---|
| GMCommandCenter_CoA 0.2.0-coa | Authored AzerothLabWorks CoA 0.1.0 source and its Lua 5.1 tests; original files matched deployed G1. Community change replaces hardcoded G1 realm exclusivity with explicit per-character/current-realm confirmation. |
| CoAGatheringAlerts 1.0.0 | Qualified gathering server-module client source; all three runtime files matched deployed G1. Protocol 1. No runtime edits in this import. |
| CoALfgTracker 1.0.0 | Local `coa-local-server/client-patches/coa-lfg-tracker` source and tests. The README records the accepted encounter table provenance and its limitations. No runtime edits in this import. |
| COAResourceMonitor 1.0.0 | Installed two-file G1 source, TOC credit AzerothLabWorks. Initial authoring receipt not found in targeted inventory; runtime files preserved unchanged. |
| Community packaging | New release manifest, deterministic ZIP builder, portable installer, documentation and offline tests. |

The reviewed public addon snapshot did not contain a repository license. The newly authored CoA code
and tooling are offered under GPL-2.0-or-later as scoped in [NOTICE-CoA.md](NOTICE-CoA.md). This import
does not infer redistribution permissions for pre-existing WotLK/Legion code, underlying client data
or third-party assets, and does not add a blanket license over them. Their licensing is a separate
review before any combined release that includes them.
No client executables, MPQs, screenshots, DBC files, saved variables or third-party addon binaries
are included. The package hashes provide integrity checks, not an independent publisher signature.
