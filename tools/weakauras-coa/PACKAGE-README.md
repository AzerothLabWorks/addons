# WeakAuras CoA 5.21.2 — AzerothLabWorks compatibility bundle

This optional package contains the six matching Ascension WeakAuras addon folders
and their Lua source. It is separate from the four AzerothLabWorks CoA addons and
their installer. It contains no game client, personal auras or saved settings.

The source is pinned to `Thinato/WeakAuras-Ascension` commit
`5741c0cd6ee021a954b83ea6c69edf8bd0bba196`, a preserved public mirror of the
Ascension backport by Bunny67, NoM0Re and the Ascension contributors. This is not
the ordinary retail or Wrath Classic WeakAuras release. Upstream identifies this
version as 5.21.2 Beta for interface 30300. See `ALW-PROVENANCE.json` for exact
source URLs, fingerprints and the limits of the provenance comparison.

Our only change to upstream code is a dated nil check in
`WeakAuras/RegionTypes/Icon.lua`, avoiding cooldown arithmetic before an expiration
time is available. `ALW-PATCHES/` records the full change. No personal aura is
created, imported, replaced or enabled by this package.

## Manual installation

1. Fully exit the game. Back up any existing six WeakAuras addon folders, then
   move those old folders out of `Interface/AddOns` before copying the new ones.
   This avoids retaining obsolete files from a different version.
2. Copy these six folders into your compatible CoA client's `Interface/AddOns`:
   `WeakAuras`, `WeakAurasArchive`, `WeakAurasModelPaths`, `WeakAurasOptions`,
   `WeakAurasStopMotion`, `WeakAurasTemplates`.
3. Keep this package's original license and attribution files, including the
   top-level `LICENSE`, `ALW-*` files and all nested media/library notices.
4. Leave `WTF` and SavedVariables untouched. Start the client and use `/wa`.

For CoA spell-range compatibility, also follow the current instructions in
https://github.com/AzerothLabWorks/coa-local-server/blob/main/docs/client-setup.md .
That separate, fingerprint-checked repair updates the client's shared
LibRangeCheck. Installing this addon alone does not change that native library.
The retired `COAWeakAurasRange` helper is not part of this package.

Rollback: exit the client, remove only the six newly installed addon folders,
and restore those six folders from your backup. If this was a fresh installation
with no old addon folders, remove only the six new folders. Do not restore or
delete your `WTF` folder as part of an addon rollback. Other client versions and
upstream auto-updates have not been qualified with this bundle.

## Credits, licenses and source

WeakAuras authors, the backport authors and all original third-party credits are
retained. `LICENSE` contains the upstream GPL version 2 license text. The package
is not uniformly GPL: Archivist carries CC0; its LibDeflate copy carries LGPLv3;
Fira and PT Sans fonts carry SIL OFL 1.1; sound notices identify CC0, CC BY 3.0,
Sampling Plus 1.0 and include CC BY-NC 3.0 terms. Preserve those notices and their
conditions. Do not relabel the bundled media as your own or as unrestricted
commercial assets. See `WeakAuras/Media/Provided by.txt` and adjacent license
files for the original sound attributions.

Lua files are the preferred source form and are included. The pinned Git source
is https://github.com/Thinato/WeakAuras-Ascension/tree/5741c0cd6ee021a954b83ea6c69edf8bd0bba196 .
The original `Ascension-Addons/WeakAuras-Ascension` URL returned 404 during the
2026-10-30 audit; the mirror is identified as a mirror, not an official current
download. The source archive's export-ignore rules omit some licenses, so our
builder reads committed Git files and preserves them instead of repackaging that
archive. The preserved upstream README is `UPSTREAM-README.md`.

`ALW-FILE-HASHES.json` inventories every package entry except itself. The external
`SHA256SUMS.txt` identifies the complete ZIP. The deterministic builder and the
reviewed patch are published in https://github.com/AzerothLabWorks/addons .
There is no warranty. This community package is not endorsed by the WeakAuras
team, Ascension or Blizzard.
