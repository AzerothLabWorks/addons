# Legion equipment catalog generator

This utility reads the enUS `Item.db2` and `ItemSparse.db2` files extracted
from the Legion 7.3.5 build-26365 client and generates the compact Lua catalog
used by `GMCommandCenter_Legion`.

It intentionally keeps only equippable armor and weapons with a usable item
name, quality, and item level. The addon uses the item ID to show the native
client tooltip, which remains the source of truth for complete stats and
requirements.

The source is compiled against the matching LegionCore headers and static
libraries. Regenerate the checked-in catalog whenever the server's DB2 data is
replaced with a different client build.
