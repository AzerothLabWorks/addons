# WeakAuras for CoA

Use the **Ascension-adapted WeakAuras 5.21.2** package for the reviewed G1 client. The addon identifies
itself as interface 30300 / 3.3.5 and displays a Beta version label. A current Retail or Classic WeakAuras
download is not interchangeable with this fork.

The [5.21.2-alw.1 download](https://github.com/AzerothLabWorks/addons/releases/tag/weakauras-coa-5.21.2-alw.1)
is a separate compatibility package. The four original G1 addon downloads and their installer are unchanged.
This package is optional; playerbots and the other G1 addons do not require WeakAuras.

## What is included

- The six addon folders from the public [Ascension WeakAuras source](https://github.com/Thinato/WeakAuras-Ascension/tree/5741c0cd6ee021a954b83ea6c69edf8bd0bba196), pinned to that exact commit.
- One small local fix: an icon without an expiration time skips cooldown arithmetic instead of raising a Lua error.
- Original source, attribution and component licenses, plus package provenance and checksums.

The installed reference package was compared against this public source. Apart from line endings, the only
addon-content difference found was that cooldown guard. The source package uses normal upstream line endings
and a dated change notice; it is not a byte-for-byte export of a personal installation. No personal aura
definitions, action bars, account settings, `WTF`, `SavedVariables`, game executable or client archive is copied.

## Two parts of compatibility

WeakAuras supplies the display and trigger engine. **Our CoA range enhancement lives in the client's shared
`LibRangeCheck-2.0` library**, which discovers suitable learned CoA spells. Installing the WeakAuras ZIP alone
does not install that client-library repair.

The current package already has the standard `WeakAuras.GetRange` wrapper. The separate repair removes an
older local Lichfrost-only wrapper only when its exact fingerprint is detected. Do not install the retired
`COAWeakAurasRange` helper. See the [range repair and acceptance record](https://github.com/AzerothLabWorks/coa-local-server/blob/main/client-patches/coa-range/README.md).

Use the updated [G1 client setup guide](https://github.com/AzerothLabWorks/coa-local-server/blob/main/docs/client-setup.md)
and its accompanying repository files for the range repair. The updated tool recognizes this package's
unmodified `Prototypes.lua` as well as the older accepted local variants. The original October 29 tool does
not recognize every line-ending variant in this newer source package. Downloading just `client-patches.py`
without its manifest and patch directory is insufficient.

The native repair still accepts only the documented executable, Extensions and archive fingerprints. A matching
WeakAuras version alone does not qualify an unfamiliar client. If preparation refuses a file, retain the report
and request compatibility review; do not bypass the checks or overwrite the client with an older archive.

## Install the addon package

1. Download the WeakAuras ZIP and `SHA256SUMS.txt` from its release page. Verify the ZIP with PowerShell
   `Get-FileHash -Algorithm SHA256 'path\to\the-downloaded.zip'` against the listed checksum.
2. Fully close the game. Back up any existing six WeakAuras addon folders listed below and your own `WTF`
   folder to a separate location. Keep the existing `WTF` in place; it contains your saved auras.
3. Extract the ZIP into a temporary directory. Move the existing six addon folders out of `Interface/AddOns`
   into your backup before copying these six new folders into `Interface/AddOns`. Replace them as a set;
   do not merge new files over old folders, which can leave incompatible leftovers:

   ```text
   WeakAuras
   WeakAurasArchive
   WeakAurasModelPaths
   WeakAurasOptions
   WeakAurasStopMotion
   WeakAurasTemplates
   ```

   Each folder's `.toc` belongs directly inside that folder. Keep the package's provenance and license files
   with your downloaded copy. Do not copy an extra ZIP-parent directory into `AddOns`.
4. If the matching native range repair is needed, follow the server repository's preparation/install procedure
   while the client is closed. It has its own backup and rollback receipt; it is separate from these addon files.
5. Start the client, enable WeakAuras, and open `/wa`. Your existing aura definitions should remain available.
   No example auras or character-specific presets are imported automatically.

The four-addon `Install-CoAAddons.ps1` does **not** accept this six-folder package. Manual addon installation
above is intentional for this release. To undo it, close the client and restore the six backed-up addon folders.
If there were no previous WeakAuras folders, remove only the six folders installed by this package and retain
your `WTF` settings. If only some folders previously existed, restore those and remove only the new ones.
Restore saved aura settings only if needed from your own backup; do not routinely replace newer `WTF` data.
Undo a native range repair with its own receipt rather than an unrelated old client archive.

## Verify in game

Check an existing aura's icon and cooldown, then a range trigger while moving toward and away from a target.
Range is an estimate based on the spells/items available to that character: a successful 20-yard check alone
does not prove a target is within 5 yards. Confirm auras still load after logout/login. This package does not
claim to fix every aura, action-bar icon problem or client crash.

The local reference client has prior player acceptance for its range repair and ordinary WeakAuras use. Source
comparison and packaging checks are separate from a new user's in-game acceptance. Report the package version,
client version, class/spec, affected trigger and a short error excerpt when reporting problems; do not upload
your entire SavedVariables or account folders.

For this release, all nine source/packaging checks passed. The package contains 745 entries, retains all 12
required license/attribution files byte-for-byte, and changes only `WeakAuras/RegionTypes/Icon.lua` among
upstream addon files. The separate client-repair suite passed 27 checks with the exact public `Prototypes.lua`.
These checks build archives and use disposable fixtures; no client was deployed or gameplay session run to
qualify this new ZIP. `build-report.json` on the release records every source/package hash and the build tools.

## Licensing and source

WeakAuras code is distributed under [GPLv2](https://github.com/Thinato/WeakAuras-Ascension/blob/5741c0cd6ee021a954b83ea6c69edf8bd0bba196/LICENSE).
Modified GPL-covered source can be shared while keeping the license, notices, corresponding source and dated
change notices. Libraries and media also have their own terms: for example, font notices use SIL Open Font
License and sound notices include Creative Commons licenses, some with noncommercial conditions. The package
preserves them; it does not claim that every included component is GPL-licensed or unrestricted for commercial
redistribution. Credit remains with the WeakAuras team, Ascension contributors and the original component authors.

Our [source lock](../third-party/weakauras-coa.json), compatibility patch and packaging script make the package
reviewable. The builder reads a pinned public Git checkout, not an installed client. The Git tree is used
because upstream ZIP-export rules omit some license files. See `tools/weakauras-coa/` for rebuilding and tests.

The public server release remains **g1-20261029**. Publishing this addon compatibility package and its guide does
not deploy a server update or change the source revision frozen by that server release.
