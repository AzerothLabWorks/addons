# Legion equipment catalog generator

This utility reads the enUS `Item.db2` and `ItemSparse.db2` files extracted
from the Legion 7.3.5 build-26365 client and generates the compact, chunked Lua
catalog used by `GMCommandCenter_Legion`.

It intentionally keeps only equippable armor and weapons with a usable item
name, quality, and item level. The addon uses the item ID to show the native
client tooltip, which remains the source of truth for complete stats and
requirements.

The generated files store tab-delimited text rather than tens of thousands of
Lua table constructors. The client therefore performs very little work at
login and decodes records only when the Armor or Weapons browser is opened.

The source is compiled against the matching LegionCore headers and static
libraries. Regenerate the checked-in catalog whenever the server's DB2 data is
replaced with a different client build.
