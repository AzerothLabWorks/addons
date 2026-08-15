#include "Common.h"
#include "DB2LoadInfo.h"
#include "DB2Store.h"
#include "DB2Structure.h"

#include <algorithm>
#include <cctype>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

namespace
{
struct CatalogEntry
{
    uint32 Id;
    std::string Name;
    uint8 ClassId;
    uint8 SubclassId;
    uint8 InventoryType;
    uint16 ItemLevel;
    int8 RequiredLevel;
    uint8 Quality;
};

bool IsEquipmentInventoryType(uint8 inventoryType)
{
    switch (inventoryType)
    {
        case 1:  // Head
        case 2:  // Neck
        case 3:  // Shoulder
        case 5:  // Chest
        case 6:  // Waist
        case 7:  // Legs
        case 8:  // Feet
        case 9:  // Wrist
        case 10: // Hands
        case 11: // Finger
        case 12: // Trinket
        case 13: // One-hand weapon
        case 14: // Shield
        case 15: // Ranged weapon
        case 16: // Cloak
        case 17: // Two-hand weapon
        case 20: // Robe
        case 21: // Main-hand weapon
        case 22: // Off-hand weapon
        case 23: // Held in off-hand
        case 25: // Thrown
        case 26: // Ranged right
            return true;
        default:
            return false;
    }
}

bool StartsWithInsensitive(std::string const& value, std::string const& prefix)
{
    if (value.size() < prefix.size())
        return false;

    for (std::size_t i = 0; i < prefix.size(); ++i)
        if (std::tolower(static_cast<unsigned char>(value[i])) !=
            std::tolower(static_cast<unsigned char>(prefix[i])))
            return false;

    return true;
}

bool IsUsefulName(std::string const& name)
{
    if (name.empty())
        return false;

    static std::vector<std::string> const excludedPrefixes =
    {
        "deprecated", "zzold", "test ", "test_", "qa ", "monster -",
        "[dnd]", "[ph]", "[qa]", "dnd ", "debug ", "internal "
    };

    // Blizzard's obsolete records commonly use an all-uppercase OLD prefix;
    // retain legitimate names beginning with the ordinary word "Old".
    if (name.compare(0, 3, "OLD") == 0)
        return false;

    for (std::string const& prefix : excludedPrefixes)
        if (StartsWithInsensitive(name, prefix))
            return false;

    return true;
}

std::string SanitizeField(std::string value)
{
    std::replace(value.begin(), value.end(), '\t', ' ');
    std::replace(value.begin(), value.end(), '\n', ' ');
    value.erase(std::remove(value.begin(), value.end(), '\r'), value.end());
    if (value.find("]=]") != std::string::npos)
        throw std::runtime_error("Item name contains the Lua chunk delimiter: " + value);
    return value;
}

void WriteCatalogChunk(std::string const& outputPath, std::string const& catalogName,
    std::vector<CatalogEntry const*> const& entries, std::size_t begin, std::size_t end)
{
    std::ofstream output(outputPath, std::ios::binary | std::ios::trunc);
    if (!output)
        throw std::runtime_error("Unable to open output file: " + outputPath);

    output << "-- Generated from the enUS build-26365 Item.db2 and ItemSparse.db2 files.\n"
              "-- Compact text is decoded only when the equipment browser is opened.\n"
              "LGMCC_EQUIPMENT_CHUNKS = LGMCC_EQUIPMENT_CHUNKS or { armor = {}, weapons = {} }\n"
              "table.insert(LGMCC_EQUIPMENT_CHUNKS." << catalogName << ", [=[\n";

    for (std::size_t index = begin; index < end; ++index)
    {
        CatalogEntry const& entry = *entries[index];
        output << entry.Id << '\t' << SanitizeField(entry.Name) << '\t' << unsigned(entry.SubclassId)
               << '\t' << unsigned(entry.InventoryType) << '\t' << entry.ItemLevel << '\t'
               << int(entry.RequiredLevel) << '\t' << unsigned(entry.Quality) << '\n';
    }

    output << "]=])\n";
}

std::size_t WriteCatalog(std::string const& outputDirectory, std::string const& catalogName,
    std::vector<CatalogEntry const*> const& entries)
{
    constexpr std::size_t RecordsPerChunk = 4000;
    std::size_t fileCount = (entries.size() + RecordsPerChunk - 1) / RecordsPerChunk;
    for (std::size_t fileIndex = 0; fileIndex < fileCount; ++fileIndex)
    {
        std::ostringstream fileName;
        fileName << outputDirectory << '/' << catalogName << '_' << std::setw(2) << std::setfill('0')
                 << (fileIndex + 1) << ".lua";
        std::size_t begin = fileIndex * RecordsPerChunk;
        std::size_t end = std::min(begin + RecordsPerChunk, entries.size());
        WriteCatalogChunk(fileName.str(), catalogName, entries, begin, end);
    }
    return fileCount;
}
}

int main(int argc, char** argv)
{
    if (argc != 3)
    {
        std::cerr << "Usage: legion-item-catalog <path-to-enUS-dbc-directory> <output-directory>\n";
        return 2;
    }

    try
    {
        std::string dataPath = argv[1];
        if (dataPath.back() != '/')
            dataPath += '/';

        DB2Storage<ItemEntry> itemStore("Item.db2", ItemLoadInfo::Instance());
        DB2Storage<ItemSparseEntry> sparseStore("ItemSparse.db2", ItemSparseLoadInfo::Instance());
        if (!itemStore.Load(dataPath, LOCALE_enUS))
            throw std::runtime_error("Unable to load Item.db2 from " + dataPath);
        if (!sparseStore.Load(dataPath, LOCALE_enUS))
            throw std::runtime_error("Unable to load ItemSparse.db2 from " + dataPath);

        std::vector<CatalogEntry> entries;
        entries.reserve(30000);
        for (ItemEntry const* item : itemStore)
        {
            if (!item || (item->ClassID != 2 && item->ClassID != 4) || !IsEquipmentInventoryType(item->InventoryType))
                continue;

            ItemSparseEntry const* sparse = sparseStore.LookupEntry(item->ID);
            if (!sparse || sparse->OverallQualityID < 1 || sparse->OverallQualityID > 7 || sparse->ItemLevel == 0)
                continue;

            char const* rawName = sparse->Display ? sparse->Display->Get(LOCALE_enUS) : nullptr;
            std::string name = rawName ? rawName : "";
            if (!IsUsefulName(name))
                continue;

            entries.push_back({
                uint32(item->ID), name, item->ClassID, item->SubclassID, item->InventoryType,
                sparse->ItemLevel, sparse->RequiredLevel, sparse->OverallQualityID
            });
        }

        std::sort(entries.begin(), entries.end(), [](CatalogEntry const& left, CatalogEntry const& right)
        {
            if (left.Name != right.Name)
                return left.Name < right.Name;
            return left.Id < right.Id;
        });

        std::vector<CatalogEntry const*> armor;
        std::vector<CatalogEntry const*> weapons;
        armor.reserve(entries.size());
        weapons.reserve(entries.size());
        for (CatalogEntry const& entry : entries)
            (entry.ClassId == 2 ? weapons : armor).push_back(&entry);

        std::size_t armorFiles = WriteCatalog(argv[2], "armor", armor);
        std::size_t weaponFiles = WriteCatalog(argv[2], "weapons", weapons);
        std::cout << "Wrote " << armor.size() << " armor and " << weapons.size() << " weapon records across "
                  << (armorFiles + weaponFiles) << " compact Lua files in " << argv[2] << '\n';
    }
    catch (std::exception const& error)
    {
        std::cerr << error.what() << '\n';
        return 1;
    }

    return 0;
}
