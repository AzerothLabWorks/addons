# AzerothLabWorks changes

## 5.21.2-alw.1 — 2026-10-30

- Preserve the six Ascension-compatible WeakAuras folders from commit
  `5741c0cd6ee021a954b83ea6c69edf8bd0bba196`, including committed licenses and
  original source/media notices omitted by upstream Git archive export rules.
- Add the existing G1 cooldown expiration-time nil guard to
  `WeakAuras/RegionTypes/Icon.lua`, with a dated source comment.
- Include reproducible source provenance, the exact patch and file hashes.

The local G1 comparison found 538 byte-identical files, 195 files differing only
in line endings, and this one Icon.lua code change across the 734 files in the
public GitHub export. Four additional installed notice/readme files are present
in the committed Git tree. The public source retains its original LF line
endings; it is not copied from the user's client or saved variables.

The shared native CoA range-library repair remains a separate server-repository
client patch. The upstream WeakAuras GetRange wrapper already delegates to that
library, so no additional wrapper change is necessary in this source bundle.
