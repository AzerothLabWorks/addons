local ADDON = "GMCommandCenter"
local ROWS = 13
local MOUNT_ROWS = 8
local state = {
    selected = nil,
    filter = "",
    category = "All",
    tab = "commands",
    rows = {},
    mountMode = false,
    mountPage = 1,
    mountRows = {},
    commandDetailControls = {},
}

local categories = { "All", "GM", "Items", "Spells", "Character", "Teleport", "NPCs", "Quests", "Server" }

-- Mount spell data derived from the WotLKDB Mounts spell category (cat -5, skill 777).
-- Generated for offline in-game browsing because the WotLK addon sandbox cannot make HTTP requests.
GMCC_MOUNT_SPELLS = GMCC_MOUNT_SPELLS or {
    { id = 458, name = "Brown Horse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 459, name = "Gray Wolf", speed = "+60%", movement = "Ground", level = 1 },
    { id = 468, name = "White Stallion", speed = "+60%", movement = "Ground", level = 1 },
    { id = 470, name = "Black Stallion", speed = "+60%", movement = "Ground", level = 1 },
    { id = 471, name = "Palamino", speed = "+60%", movement = "Ground", level = 1 },
    { id = 472, name = "Pinto", speed = "+60%", movement = "Ground", level = 1 },
    { id = 578, name = "Black Wolf", speed = "+60%", movement = "Ground", level = 1 },
    { id = 579, name = "Red Wolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 580, name = "Timber Wolf", speed = "+60%", movement = "Ground", level = 1 },
    { id = 581, name = "Winter Wolf", speed = "+60%", movement = "Ground", level = 1 },
    { id = 3363, name = "Nether Drake", speed = "+310%", movement = "Flying", level = 1 },
    { id = 5784, name = "Felsteed", speed = "+60%", movement = "Ground", level = 20, class = "Warlock" },
    { id = 6648, name = "Chestnut Mare", speed = "+60%", movement = "Ground", level = 1 },
    { id = 6653, name = "Dire Wolf", speed = "+60%", movement = "Ground", level = 1 },
    { id = 6654, name = "Brown Wolf", speed = "+60%", movement = "Ground", level = 1 },
    { id = 6777, name = "Gray Ram", speed = "+60%", movement = "Ground", level = 1 },
    { id = 6896, name = "Black Ram", speed = "+60%", movement = "Ground", level = 1 },
    { id = 6897, name = "Blue Ram", speed = "+60%", movement = "Ground", level = 1 },
    { id = 6898, name = "White Ram", speed = "+60%", movement = "Ground", level = 1 },
    { id = 6899, name = "Brown Ram", speed = "+60%", movement = "Ground", level = 1 },
    { id = 8394, name = "Striped Frostsaber", speed = "+60%", movement = "Ground", level = 1 },
    { id = 8395, name = "Emerald Raptor", speed = "+60%", movement = "Ground", level = 1 },
    { id = 8980, name = "Skeletal Horse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10789, name = "Spotted Frostsaber", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10793, name = "Striped Nightsaber", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10795, name = "Ivory Raptor", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10796, name = "Turquoise Raptor", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10798, name = "Obsidian Raptor", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10799, name = "Violet Raptor", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10873, name = "Red Mechanostrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10969, name = "Blue Mechanostrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 13819, name = "Warhorse", speed = "+60%", movement = "Ground", level = 20, class = "Paladin" },
    { id = 15779, name = "White Mechanostrider Mod B", speed = "+100%", movement = "Ground", level = 1 },
    { id = 15780, name = "Green Mechanostrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 15781, name = "Steel Mechanostrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 16055, name = "Black Nightsaber", speed = "+100%", movement = "Ground", level = 1 },
    { id = 16056, name = "Ancient Frostsaber", speed = "+100%", movement = "Ground", level = 1 },
    { id = 16058, name = "Primal Leopard", speed = "+60%", movement = "Ground", level = 1 },
    { id = 16059, name = "Tawny Sabercat", speed = "+60%", movement = "Ground", level = 1 },
    { id = 16060, name = "Golden Sabercat", speed = "+60%", movement = "Ground", level = 1 },
    { id = 16080, name = "Red Wolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 16081, name = "Winter Wolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 16082, name = "Palomino", speed = "+100%", movement = "Ground", level = 1 },
    { id = 16083, name = "White Stallion", speed = "+100%", movement = "Ground", level = 1 },
    { id = 16084, name = "Mottled Red Raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 17229, name = "Winterspring Frostsaber", speed = "+100%", movement = "Ground", level = 1 },
    { id = 17450, name = "Ivory Raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 17453, name = "Green Mechanostrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17454, name = "Unpainted Mechanostrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17455, name = "Purple Mechanostrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17456, name = "Red and Blue Mechanostrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17458, name = "Fluorescent Green Mechanostrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17459, name = "Icy Blue Mechanostrider Mod A", speed = "+100%", movement = "Ground", level = 1 },
    { id = 17460, name = "Frost Ram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 17461, name = "Black Ram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 17462, name = "Red Skeletal Horse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17463, name = "Blue Skeletal Horse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17464, name = "Brown Skeletal Horse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17465, name = "Green Skeletal Warhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 17481, name = "Rivendare's Deathcharger", speed = "+100%", movement = "Ground", level = 1 },
    { id = 18363, name = "Riding Kodo", speed = "+60%", movement = "Ground", level = 1 },
    { id = 18989, name = "Gray Kodo", speed = "+60%", movement = "Ground", level = 1 },
    { id = 18990, name = "Brown Kodo", speed = "+60%", movement = "Ground", level = 1 },
    { id = 18991, name = "Green Kodo", speed = "+100%", movement = "Ground", level = 1 },
    { id = 18992, name = "Teal Kodo", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23161, name = "Dreadsteed", speed = "+100%", movement = "Ground", level = 40, class = "Warlock" },
    { id = 23214, name = "Charger", speed = "+100%", movement = "Ground", level = 40, class = "Paladin" },
    { id = 23219, name = "Swift Mistsaber", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23220, name = "Swift Dawnsaber", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23221, name = "Swift Frostsaber", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23222, name = "Swift Yellow Mechanostrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23223, name = "Swift White Mechanostrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23225, name = "Swift Green Mechanostrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23227, name = "Swift Palomino", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23228, name = "Swift White Steed", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23229, name = "Swift Brown Steed", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23238, name = "Swift Brown Ram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23239, name = "Swift Gray Ram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23240, name = "Swift White Ram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23241, name = "Swift Blue Raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23242, name = "Swift Olive Raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23243, name = "Swift Orange Raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23246, name = "Purple Skeletal Warhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23247, name = "Great White Kodo", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23248, name = "Great Gray Kodo", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23249, name = "Great Brown Kodo", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23250, name = "Swift Brown Wolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23251, name = "Swift Timber Wolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23252, name = "Swift Gray Wolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23338, name = "Swift Stormsaber", speed = "+100%", movement = "Ground", level = 1 },
    { id = 24242, name = "Swift Razzashi Raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 24252, name = "Swift Zulian Tiger", speed = "+100%", movement = "Ground", level = 1 },
    { id = 25953, name = "Blue Qiraji Battle Tank", speed = "+100%", movement = "Ground", level = 1 },
    { id = 26054, name = "Red Qiraji Battle Tank", speed = "+100%", movement = "Ground", level = 1 },
    { id = 26055, name = "Yellow Qiraji Battle Tank", speed = "+100%", movement = "Ground", level = 1 },
    { id = 26056, name = "Green Qiraji Battle Tank", speed = "+100%", movement = "Ground", level = 1 },
    { id = 26656, name = "Black Qiraji Battle Tank", speed = "+100%", movement = "Ground", level = 1 },
    { id = 28828, name = "Nether Drake", speed = "+300%", movement = "Unknown", level = 1 },
    { id = 29059, name = "Naxxramas Deathcharger", speed = "+100%", movement = "Ground", level = 1 },
    { id = 30174, name = "Riding Turtle", speed = "+0%", movement = "Unknown", level = 1 },
    { id = 32235, name = "Golden Gryphon", speed = "+150%", movement = "Flying", level = 1 },
    { id = 32239, name = "Ebon Gryphon", speed = "+150%", movement = "Flying", level = 1 },
    { id = 32240, name = "Snowy Gryphon", speed = "+150%", movement = "Flying", level = 1 },
    { id = 32242, name = "Swift Blue Gryphon", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32243, name = "Tawny Wind Rider", speed = "+150%", movement = "Flying", level = 1 },
    { id = 32244, name = "Blue Wind Rider", speed = "+150%", movement = "Flying", level = 1 },
    { id = 32245, name = "Green Wind Rider", speed = "+150%", movement = "Flying", level = 1 },
    { id = 32246, name = "Swift Red Wind Rider", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32289, name = "Swift Red Gryphon", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32290, name = "Swift Green Gryphon", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32292, name = "Swift Purple Gryphon", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32295, name = "Swift Green Wind Rider", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32296, name = "Swift Yellow Wind Rider", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32297, name = "Swift Purple Wind Rider", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32345, name = "Peep the Phoenix Mount", speed = "+310%", movement = "Flying", level = 1 },
    { id = 33630, name = "Blue Mechanostrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 33660, name = "Swift Pink Hawkstrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 34406, name = "Brown Elekk", speed = "+60%", movement = "Ground", level = 1 },
    { id = 34407, name = "Great Elite Elekk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 34767, name = "Summon Charger", speed = "+100%", movement = "Ground", level = 40, class = "Paladin" },
    { id = 34769, name = "Summon Warhorse", speed = "+60%", movement = "Ground", level = 20, class = "Paladin" },
    { id = 34790, name = "Dark War Talbuk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 34795, name = "Red Hawkstrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 34896, name = "Cobalt War Talbuk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 34897, name = "White War Talbuk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 34898, name = "Silver War Talbuk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 34899, name = "Tan War Talbuk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 35018, name = "Purple Hawkstrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 35020, name = "Blue Hawkstrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 35022, name = "Black Hawkstrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 35025, name = "Swift Green Hawkstrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 35027, name = "Swift Purple Hawkstrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 35710, name = "Gray Elekk", speed = "+60%", movement = "Ground", level = 1 },
    { id = 35711, name = "Purple Elekk", speed = "+60%", movement = "Ground", level = 1 },
    { id = 35712, name = "Great Green Elekk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 35713, name = "Great Blue Elekk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 35714, name = "Great Purple Elekk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 36702, name = "Fiery Warhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 37015, name = "Swift Nether Drake", speed = "+310%", movement = "Flying", level = 1 },
    { id = 39315, name = "Cobalt Riding Talbuk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 39316, name = "Dark Riding Talbuk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 39317, name = "Silver Riding Talbuk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 39318, name = "Tan Riding Talbuk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 39319, name = "White Riding Talbuk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 39798, name = "Green Riding Nether Ray", speed = "+280%", movement = "Flying", level = 1 },
    { id = 39800, name = "Red Riding Nether Ray", speed = "+280%", movement = "Flying", level = 1 },
    { id = 39801, name = "Purple Riding Nether Ray", speed = "+280%", movement = "Flying", level = 1 },
    { id = 39802, name = "Silver Riding Nether Ray", speed = "+280%", movement = "Flying", level = 1 },
    { id = 39803, name = "Blue Riding Nether Ray", speed = "+280%", movement = "Flying", level = 1 },
    { id = 40192, name = "Ashes of Al'ar", speed = "+310%", movement = "Flying", level = 1 },
    { id = 41252, name = "Raven Lord", speed = "+100%", movement = "Ground", level = 1 },
    { id = 41513, name = "Onyx Netherwing Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 41514, name = "Azure Netherwing Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 41515, name = "Cobalt Netherwing Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 41516, name = "Purple Netherwing Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 41517, name = "Veridian Netherwing Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 41518, name = "Violet Netherwing Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 42776, name = "Spectral Tiger", speed = "+60%", movement = "Ground", level = 1 },
    { id = 42777, name = "Swift Spectral Tiger", speed = "+100%", movement = "Ground", level = 1 },
    { id = 43688, name = "Amani War Bear", speed = "+100%", movement = "Ground", level = 1 },
    { id = 43810, name = "Frost Wyrm", speed = "+280%", movement = "Flying", level = 1 },
    { id = 43899, name = "Brewfest Ram", speed = "+60%", movement = "Ground", level = 1 },
    { id = 43900, name = "Swift Brewfest Ram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 43927, name = "Cenarion War Hippogryph", speed = "+280%", movement = "Flying", level = 1 },
    { id = 44151, name = "Turbo-Charged Flying Machine", speed = "+280%", movement = "Flying", level = 1 },
    { id = 44153, name = "Flying Machine", speed = "+150%", movement = "Flying", level = 1 },
    { id = 44317, name = "Merciless Nether Drake", speed = "+310%", movement = "Flying", level = 1 },
    { id = 44744, name = "Merciless Nether Drake", speed = "+310%", movement = "Flying", level = 1 },
    { id = 46197, name = "X-51 Nether-Rocket", speed = "+150%", movement = "Flying", level = 1 },
    { id = 46199, name = "X-51 Nether-Rocket X-TREME", speed = "+280%", movement = "Flying", level = 1 },
    { id = 46628, name = "Swift White Hawkstrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 47037, name = "Swift War  Elekk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 48025, name = "Headless Horseman's Mount", speed = "?", movement = "Unknown", level = 0 },
    { id = 48778, name = "Acherus Deathcharger", speed = "+100%", movement = "Ground", level = 55, class = "Death Knight" },
    { id = 48954, name = "Swift Zhevra", speed = "+100%", movement = "Ground", level = 1 },
    { id = 49193, name = "Vengeful Nether Drake", speed = "+310%", movement = "Flying", level = 1 },
    { id = 49322, name = "Swift Zhevra", speed = "+100%", movement = "Ground", level = 1 },
    { id = 49378, name = "Brewfest Riding Kodo", speed = "+60%", movement = "Ground", level = 1 },
    { id = 49379, name = "Great Brewfest Kodo", speed = "+100%", movement = "Ground", level = 1 },
    { id = 50869, name = "Brewfest Kodo", speed = "+60%", movement = "Ground", level = 1 },
    { id = 50870, name = "Brewfest Ram", speed = "+60%", movement = "Ground", level = 1 },
    { id = 51412, name = "Big Battle Bear", speed = "+100%", movement = "Ground", level = 1 },
    { id = 51960, name = "Frost Wyrm Mount", speed = "+280%", movement = "Flying", level = 1 },
    { id = 54729, name = "Winged Steed of the Ebon Blade", speed = "?", movement = "Unknown", level = 1 },
    { id = 54753, name = "White Polar Bear", speed = "+100%", movement = "Ground", level = 1 },
    { id = 55531, name = "Mechano-hog", speed = "+100%", movement = "Ground", level = 1 },
    { id = 58615, name = "Brutal Nether Drake", speed = "+310%", movement = "Flying", level = 1 },
    { id = 58983, name = "Big Blizzard Bear", speed = "?", movement = "Unknown", level = 0 },
    { id = 59567, name = "Azure Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 59568, name = "Blue Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 59569, name = "Bronze Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 59570, name = "Red Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 59571, name = "Twilight Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 59572, name = "Black Polar Bear", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59573, name = "Brown Polar Bear", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59650, name = "Black Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 59785, name = "Black War Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59788, name = "Black War Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59791, name = "Wooly Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59793, name = "Wooly Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59797, name = "Ice Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59799, name = "Ice Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59802, name = "Grand Ice Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59804, name = "Grand Ice Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59961, name = "Red Proto-Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 59976, name = "Black Proto-Drake", speed = "+310%", movement = "Flying", level = 1 },
    { id = 59996, name = "Blue Proto-Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 60002, name = "Time-Lost Proto-Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 60021, name = "Plagued Proto-Drake", speed = "+310%", movement = "Flying", level = 1 },
    { id = 60024, name = "Violet Proto-Drake", speed = "+310%", movement = "Flying", level = 1 },
    { id = 60025, name = "Albino Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 60114, name = "Armored Brown Bear", speed = "+100%", movement = "Ground", level = 1 },
    { id = 60116, name = "Armored Brown Bear", speed = "+100%", movement = "Ground", level = 1 },
    { id = 60118, name = "Black War Bear", speed = "+100%", movement = "Ground", level = 1 },
    { id = 60119, name = "Black War Bear", speed = "+100%", movement = "Ground", level = 1 },
    { id = 60136, name = "Grand Caravan Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 60140, name = "Grand Caravan Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 60424, name = "Mekgineer's Chopper", speed = "+100%", movement = "Ground", level = 1 },
    { id = 61229, name = "Armored Snowy Gryphon", speed = "+280%", movement = "Flying", level = 1 },
    { id = 61230, name = "Armored Blue Wind Rider", speed = "+280%", movement = "Flying", level = 1 },
    { id = 61294, name = "Green Proto-Drake", speed = "+280%", movement = "Flying", level = 1 },
    { id = 61309, name = "Magnificent Flying Carpet", speed = "+280%", movement = "Flying", level = 0 },
    { id = 61425, name = "Traveler's Tundra Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 61442, name = "Swift Mooncloth Carpet", speed = "+0%", movement = "Unknown", level = 0 },
    { id = 61444, name = "Swift Shadoweave Carpet", speed = "+0%", movement = "Unknown", level = 0 },
    { id = 61446, name = "Swift Spellfire Carpet", speed = "+0%", movement = "Unknown", level = 0 },
    { id = 61447, name = "Traveler's Tundra Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 61451, name = "Flying Carpet", speed = "+150%", movement = "Flying", level = 0 },
    { id = 61465, name = "Grand Black War Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 61467, name = "Grand Black War Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 61469, name = "Grand Ice Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 61470, name = "Grand Ice Mammoth", speed = "+100%", movement = "Ground", level = 1 },
    { id = 61996, name = "Blue Dragonhawk", speed = "+280%", movement = "Flying", level = 1 },
    { id = 61997, name = "Red Dragonhawk", speed = "+280%", movement = "Flying", level = 1 },
    { id = 62048, name = "Black Dragonhawk Mount", speed = "+280%", movement = "Flying", level = 1 },
    { id = 63232, name = "Stormwind Steed", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63635, name = "Darkspear Raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63636, name = "Ironforge Ram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63637, name = "Darnassian Nightsaber", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63638, name = "Gnomeregan Mechanostrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63639, name = "Exodar Elekk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63640, name = "Orgrimmar Wolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63641, name = "Thunder Bluff Kodo", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63642, name = "Silvermoon Hawkstrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63643, name = "Forsaken Warhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63796, name = "Mimiron's Head", speed = "+310%", movement = "Flying", level = 1 },
    { id = 63844, name = "Argent Hippogryph", speed = "+280%", movement = "Flying", level = 1 },
    { id = 63956, name = "Ironbound Proto-Drake", speed = "+310%", movement = "Flying", level = 1 },
    { id = 63963, name = "Rusted Proto-Drake", speed = "+310%", movement = "Flying", level = 1 },
    { id = 64656, name = "Blue Skeletal Warhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 64657, name = "White Kodo", speed = "+60%", movement = "Ground", level = 1 },
    { id = 64658, name = "Black Wolf", speed = "+60%", movement = "Ground", level = 1 },
    { id = 64659, name = "Venomhide Ravasaur", speed = "+100%", movement = "Ground", level = 1 },
    { id = 64731, name = "Sea Turtle", speed = "+60%", movement = "Aquatic", level = 1 },
    { id = 64927, name = "Deadly Gladiator's Frost Wyrm", speed = "+310%", movement = "Flying", level = 1 },
    { id = 64977, name = "Black Skeletal Horse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 65439, name = "Furious Gladiator's Frost Wyrm", speed = "+310%", movement = "Flying", level = 1 },
    { id = 65637, name = "Great Red Elekk", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65638, name = "Swift Moonsaber", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65639, name = "Swift Red Hawkstrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65640, name = "Swift Gray Steed", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65641, name = "Great Golden Kodo", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65642, name = "Turbostrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65643, name = "Swift Violet Ram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65644, name = "Swift Purple Raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65645, name = "White Skeletal Warhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65646, name = "Swift Burgundy Wolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65917, name = "Magic Rooster", speed = "?", movement = "Unknown", level = 1 },
    { id = 66087, name = "Silver Covenant Hippogryph", speed = "+280%", movement = "Flying", level = 1 },
    { id = 66088, name = "Sunreaver Dragonhawk", speed = "+280%", movement = "Flying", level = 1 },
    { id = 66090, name = "Quel'dorei Steed", speed = "+100%", movement = "Ground", level = 1 },
    { id = 66091, name = "Sunreaver Hawkstrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 66122, name = "Magic Rooster", speed = "+100%", movement = "Ground", level = 1 },
    { id = 66123, name = "Magic Rooster", speed = "+100%", movement = "Ground", level = 1 },
    { id = 66124, name = "Magic Rooster", speed = "+100%", movement = "Ground", level = 1 },
    { id = 66846, name = "Ochre Skeletal Warhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 66847, name = "Striped Dawnsaber", speed = "+60%", movement = "Ground", level = 1 },
    { id = 66906, name = "Argent Charger", speed = "+100%", movement = "Ground", level = 40 },
    { id = 66907, name = "Argent Warhorse", speed = "+60%", movement = "Ground", level = 20 },
    { id = 67336, name = "Relentless Gladiator's Frost Wyrm", speed = "+310%", movement = "Flying", level = 1 },
    { id = 67466, name = "Argent Warhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 68056, name = "Swift Horde Wolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 68057, name = "Swift Alliance Steed", speed = "+100%", movement = "Ground", level = 1 },
    { id = 68187, name = "Crusader's White Warhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 68188, name = "Crusader's Black Warhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 69395, name = "Onyxian Drake", speed = "+310%", movement = "Flying", level = 1 },
    { id = 71342, name = "Big Love Rocket", speed = "?", movement = "Unknown", level = 0 },
    { id = 71810, name = "Wrathful Gladiator's Frost Wyrm", speed = "+310%", movement = "Flying", level = 1 },
}
local ResetCommandScroll

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99GMCC|r " .. tostring(message))
end

local function Trim(value)
    value = value or ""
    return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

local function EscapePattern(value)
    value = tostring(value or "")
    return string.gsub(value, "([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1")
end

local function WildcardMatch(haystack, needle)
    haystack = string.lower(tostring(haystack or ""))
    needle = string.lower(Trim(needle))
    if needle == "" then
        return true
    end

    if not string.find(needle, "*", 1, true) then
        return string.find(haystack, needle, 1, true) ~= nil
    end

    local pattern = EscapePattern(needle)
    pattern = string.gsub(pattern, "%*", ".*")
    if string.sub(pattern, 1, 2) ~= ".*" then
        pattern = ".*" .. pattern
    end
    if string.sub(pattern, -2) ~= ".*" then
        pattern = pattern .. ".*"
    end
    return string.find(haystack, "^" .. pattern .. "$") ~= nil
end

local function RunCommand(command)
    command = Trim(command)
    if command == "" then
        Print("No command to run.")
        return
    end

    if string.sub(command, 1, 1) ~= "." then
        command = "." .. command
    end

    SendChatMessage(command, "SAY")
    Print("Ran: " .. command)
    GMCommandCenterDB = GMCommandCenterDB or {}
    GMCommandCenterDB.lastCommand = command
end

local function SaveLauncherPosition(button)
    GMCommandCenterDB = GMCommandCenterDB or {}
    GMCommandCenterDB.launcher = GMCommandCenterDB.launcher or {}

    local x, y = button:GetCenter()
    local centerX, centerY = UIParent:GetCenter()

    GMCommandCenterDB.launcher.x = (x or centerX) - centerX
    GMCommandCenterDB.launcher.y = (y or centerY) - centerY
end

local function PositionLauncherButton(button)
    local launcher = GMCommandCenterDB and GMCommandCenterDB.launcher
    button:ClearAllPoints()
    if launcher and launcher.x and launcher.y then
        button:SetPoint("CENTER", UIParent, "CENTER", launcher.x, launcher.y)
    else
        button:SetPoint("CENTER", UIParent, "CENTER", 390, -175)
    end
end

local function ResetLauncherButton(button)
    GMCommandCenterDB = GMCommandCenterDB or {}
    GMCommandCenterDB.launcher = nil
    button:ClearAllPoints()
    button:SetPoint("CENTER", UIParent, "CENTER", 390, -175)
end

local function ToggleMainFrame(text)
    text = Trim(text)
    if text ~= "" then
        state.filter = text
        if GMCC_FilterBox then
            ResetCommandScroll()
            GMCC_FilterBox:SetText(text)
        end
    end

    if not GMCommandCenterFrame then
        Print("UI is still loading. Try /reload, then /gmcc.")
        return
    end

    if GMCommandCenterFrame:IsShown() then
        GMCommandCenterFrame:Hide()
    else
        GMCommandCenterFrame:Show()
    end
end

local function BuildCommand(entry, args)
    local command = "." .. entry.name
    args = Trim(args)
    if args ~= "" then
        command = command .. " " .. args
    end
    return command
end

local function Matches(entry)
    if state.category ~= "All" and entry.cat ~= state.category then
        return false
    end

    local needle = state.filter or ""
    if needle == "" then
        return true
    end

    local haystack = entry.cat .. " " .. entry.name .. " " .. entry.syntax .. " " .. entry.help
    return WildcardMatch(haystack, needle)
end

local function FilterCommands()
    local results = {}
    for _, entry in ipairs(GMCC_COMMANDS) do
        if Matches(entry) then
            table.insert(results, entry)
        end
    end
    return results
end

local function SetEditBoxText(box, text)
    box:SetText(text or "")
    box:SetCursorPosition(0)
end

local function HideMountRows()
    state.mountMode = false
    if GMCC_MountStatus then
        GMCC_MountStatus:Hide()
    end
    if GMCC_MountPrev then
        GMCC_MountPrev:Hide()
    end
    if GMCC_MountNext then
        GMCC_MountNext:Hide()
    end
    for _, row in ipairs(state.mountRows) do
        row:Hide()
    end
end

local function SetCommandControlsShown(isShown)
    for _, control in ipairs(state.commandDetailControls) do
        if isShown then
            control:Show()
        else
            control:Hide()
        end
    end
end

local function MatchesMount(mount)
    local needle = state.filter or ""
    if needle == "" then
        return true
    end

    local haystack = mount.id .. " " .. mount.name .. " " .. mount.speed .. " " .. mount.movement .. " " .. (mount.class or "")
    return WildcardMatch(haystack, needle)
end

local function FilterMounts()
    local results = {}
    if not GMCC_MOUNT_SPELLS then
        return results
    end

    for _, mount in ipairs(GMCC_MOUNT_SPELLS) do
        if MatchesMount(mount) then
            table.insert(results, mount)
        end
    end
    return results
end

local function RefreshMountRows()
    if not state.mountMode then
        return
    end

    local mounts = FilterMounts()
    local total = table.getn(mounts)
    local hasMountData = GMCC_MOUNT_SPELLS ~= nil
    local maxPage = math.max(1, math.ceil(total / MOUNT_ROWS))
    if state.mountPage > maxPage then
        state.mountPage = maxPage
    elseif state.mountPage < 1 then
        state.mountPage = 1
    end

    local startIndex = ((state.mountPage - 1) * MOUNT_ROWS) + 1
    local endIndex = math.min(startIndex + MOUNT_ROWS - 1, total)
    if GMCC_MountStatus then
        if total > 0 then
            GMCC_MountStatus:SetText("Showing " .. startIndex .. "-" .. endIndex .. " of " .. total .. " mount spells.")
        elseif not hasMountData then
            GMCC_MountStatus:SetText("Mount data did not initialize. Recopy the updated GMCommandCenter addon folder.")
        else
            GMCC_MountStatus:SetText("No mount spells match this filter.")
        end
        GMCC_MountStatus:Show()
    end
    if GMCC_MountPrev then
        if state.mountPage > 1 then
            GMCC_MountPrev:Show()
        else
            GMCC_MountPrev:Hide()
        end
    end
    if GMCC_MountNext then
        if state.mountPage < maxPage then
            GMCC_MountNext:Show()
        else
            GMCC_MountNext:Hide()
        end
    end

    for i = 1, MOUNT_ROWS do
        local row = state.mountRows[i]
        local mount = mounts[startIndex + i - 1]
        if row and mount then
            local classText = ""
            if mount.class and mount.class ~= "" then
                classText = " | " .. mount.class
            end
            row.mount = mount
            row.label:SetText(mount.id .. " - " .. mount.name .. " | " .. mount.speed .. " | " .. mount.movement .. " | lvl " .. mount.level .. classText)
            row:Show()
        elseif row then
            row.mount = nil
            row:Hide()
        end
    end
end

local function ShowMountBrowser()
    state.mountMode = true
    state.mountPage = 1
    state.selected = nil
    state.filter = ""
    SetCommandControlsShown(false)
    if GMCC_FilterBox and GMCC_FilterBox:GetText() ~= "" then
        GMCC_FilterBox:SetText("")
    end

    GMCC_TitleText:SetText("Mount Spells")
    GMCC_MetaText:SetText("WotLKDB Mounts skill 777")
    GMCC_SyntaxText:SetText(".learn <spellId>")
    GMCC_HelpText:SetText("Mount results are offline spell data from the Mounts category. Use the top search box for names, speed values like 310, or movement types like Ground and Flying.")
    SetEditBoxText(GMCC_CommandBox, "")
    SetEditBoxText(GMCC_ArgsBox, "")
    RefreshMountRows()
end

local function SelectCommand(entry)
    HideMountRows()
    SetCommandControlsShown(true)
    state.selected = entry
    GMCC_TitleText:SetText(entry.name)
    GMCC_MetaText:SetText(entry.cat .. "   Security " .. entry.sec)
    GMCC_SyntaxText:SetText(entry.syntax)
    GMCC_HelpText:SetText(entry.help)
    SetEditBoxText(GMCC_CommandBox, BuildCommand(entry, ""))
    SetEditBoxText(GMCC_ArgsBox, entry.args or "")
end

local function RefreshCommandRows()
    local commands = FilterCommands()
    local offset = FauxScrollFrame_GetOffset(GMCC_CommandScroll)

    for i = 1, ROWS do
        local row = state.rows[i]
        local entry = commands[offset + i]
        if entry then
            row.entry = entry
            row.name:SetText(entry.name)
            row.meta:SetText(entry.cat .. " / sec " .. entry.sec)
            row:Show()
            if state.selected == entry then
                row.bg:SetVertexColor(0.25, 0.45, 0.75, 0.55)
                row.bg:Show()
            else
                row.bg:Hide()
            end
        else
            row.entry = nil
            row:Hide()
        end
    end

    FauxScrollFrame_Update(GMCC_CommandScroll, table.getn(commands), ROWS, 24)
    GMCC_CountText:SetText(table.getn(commands) .. " commands")
end

ResetCommandScroll = function()
    if GMCC_CommandScroll then
        GMCC_CommandScroll.offset = 0
        if GMCC_CommandScrollScrollBar then
            GMCC_CommandScrollScrollBar:SetValue(0)
        end
    end
end

local function CreateLabel(parent, name, text, size)
    local label = parent:CreateFontString(name, "ARTWORK", "GameFontNormal")
    label:SetText(text or "")
    label:SetJustifyH("LEFT")
    if size == "small" then
        label:SetFontObject(GameFontHighlightSmall)
    elseif size == "large" then
        label:SetFontObject(GameFontNormalLarge)
    end
    return label
end

local function CreateEditBox(parent, name, width, height)
    local box = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
    box:SetWidth(width)
    box:SetHeight(height or 24)
    box:SetAutoFocus(false)
    box:SetFontObject(ChatFontNormal)
    return box
end

local function CreateButton(parent, name, text, width, height)
    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetWidth(width)
    button:SetHeight(height or 24)
    button:SetText(text)
    return button
end

local function BuildCommandsPanel(parent)
    local panel = CreateFrame("Frame", "GMCC_CommandPanel", parent)
    panel:SetPoint("TOPLEFT", 16, -72)
    panel:SetPoint("BOTTOMRIGHT", -16, 16)

    GMCC_FilterBox = CreateEditBox(panel, "GMCC_FilterBox", 210, 24)
    GMCC_FilterBox:SetPoint("TOPLEFT", 2, -2)
    GMCC_FilterBox:SetScript("OnTextChanged", function(self)
        state.filter = self:GetText() or ""
        ResetCommandScroll()
        RefreshCommandRows()
        state.mountPage = 1
        RefreshMountRows()
    end)

    GMCC_CountText = CreateLabel(panel, "GMCC_CountText", "", "small")
    GMCC_CountText:SetPoint("LEFT", GMCC_FilterBox, "RIGHT", 14, 0)

    local lastButton
    for i, cat in ipairs(categories) do
        local button = CreateButton(panel, "GMCC_Cat" .. i, cat, 70, 22)
        if i == 1 then
            button:SetPoint("TOPLEFT", 2, -32)
        elseif i == 6 then
            button:SetPoint("TOPLEFT", 2, -58)
        else
            button:SetPoint("LEFT", lastButton, "RIGHT", 4, 0)
        end
        button:SetScript("OnClick", function()
            HideMountRows()
            SetCommandControlsShown(true)
            state.category = cat
            ResetCommandScroll()
            RefreshCommandRows()
        end)
        lastButton = button

        if cat == "Spells" then
            local mountButton = CreateButton(panel, nil, "Mount", 70, 22)
            mountButton:SetPoint("LEFT", lastButton, "RIGHT", 4, 0)
            mountButton:SetScript("OnClick", function()
                ShowMountBrowser()
            end)
            lastButton = mountButton
        end
    end

    local listFrame = CreateFrame("Frame", nil, panel)
    listFrame:SetPoint("TOPLEFT", 0, -90)
    listFrame:SetWidth(250)
    listFrame:SetHeight(315)

    GMCC_CommandScroll = CreateFrame("ScrollFrame", "GMCC_CommandScroll", listFrame, "FauxScrollFrameTemplate")
    GMCC_CommandScroll:SetPoint("TOPLEFT", 0, -2)
    GMCC_CommandScroll:SetPoint("BOTTOMRIGHT", -28, 2)
    GMCC_CommandScroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, 24, RefreshCommandRows)
    end)

    for i = 1, ROWS do
        local row = CreateFrame("Button", "GMCC_CommandRow" .. i, listFrame)
        row:SetWidth(222)
        row:SetHeight(24)
        if i == 1 then
            row:SetPoint("TOPLEFT", 0, -2)
        else
            row:SetPoint("TOPLEFT", state.rows[i - 1], "BOTTOMLEFT", 0, 0)
        end

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints(row)
        row.bg:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.bg:SetBlendMode("ADD")
        row.bg:Hide()

        row.name = CreateLabel(row, nil, "", "small")
        row.name:SetPoint("LEFT", 6, 5)
        row.meta = CreateLabel(row, nil, "", "small")
        row.meta:SetPoint("LEFT", 6, -7)
        row.meta:SetTextColor(0.65, 0.65, 0.65)
        row:SetScript("OnClick", function(self)
            SelectCommand(self.entry)
            RefreshCommandRows()
        end)
        state.rows[i] = row
    end

    GMCC_TitleText = CreateLabel(panel, "GMCC_TitleText", "Select a command", "large")
    GMCC_TitleText:SetPoint("TOPLEFT", 282, -90)
    GMCC_MetaText = CreateLabel(panel, "GMCC_MetaText", "", "small")
    GMCC_MetaText:SetPoint("TOPLEFT", GMCC_TitleText, "BOTTOMLEFT", 0, -4)
    GMCC_SyntaxText = CreateLabel(panel, "GMCC_SyntaxText", "", "small")
    GMCC_SyntaxText:SetPoint("TOPLEFT", GMCC_MetaText, "BOTTOMLEFT", 0, -12)
    GMCC_SyntaxText:SetWidth(360)
    GMCC_SyntaxText:SetTextColor(1.0, 0.82, 0.0)
    GMCC_HelpText = CreateLabel(panel, "GMCC_HelpText", "", "small")
    GMCC_HelpText:SetPoint("TOPLEFT", GMCC_SyntaxText, "BOTTOMLEFT", 0, -12)
    GMCC_HelpText:SetWidth(360)
    GMCC_HelpText:SetHeight(82)

    local argsLabel = CreateLabel(panel, nil, "Arguments", "small")
    argsLabel:SetPoint("TOPLEFT", 282, -250)
    GMCC_ArgsBox = CreateEditBox(panel, "GMCC_ArgsBox", 330, 24)
    GMCC_ArgsBox:SetPoint("TOPLEFT", argsLabel, "BOTTOMLEFT", 0, -4)
    GMCC_ArgsBox:SetScript("OnTextChanged", function(self)
        if state.selected then
            SetEditBoxText(GMCC_CommandBox, BuildCommand(state.selected, self:GetText()))
        end
    end)

    local commandLabel = CreateLabel(panel, nil, "Command", "small")
    commandLabel:SetPoint("TOPLEFT", GMCC_ArgsBox, "BOTTOMLEFT", 0, -12)
    GMCC_CommandBox = CreateEditBox(panel, "GMCC_CommandBox", 330, 24)
    GMCC_CommandBox:SetPoint("TOPLEFT", commandLabel, "BOTTOMLEFT", 0, -4)

    local run = CreateButton(panel, nil, "Run", 82, 24)
    run:SetPoint("TOPLEFT", GMCC_CommandBox, "BOTTOMLEFT", 0, -10)
    run:SetScript("OnClick", function()
        RunCommand(GMCC_CommandBox:GetText())
    end)

    local help = CreateButton(panel, nil, "Help", 82, 24)
    help:SetPoint("LEFT", run, "RIGHT", 8, 0)
    help:SetScript("OnClick", function()
        if state.selected then
            RunCommand(".help " .. state.selected.name)
        end
    end)

    local last = CreateButton(panel, nil, "Last", 82, 24)
    last:SetPoint("LEFT", help, "RIGHT", 8, 0)
    last:SetScript("OnClick", function()
        if GMCommandCenterDB and GMCommandCenterDB.lastCommand then
            SetEditBoxText(GMCC_CommandBox, GMCommandCenterDB.lastCommand)
        end
    end)

    table.insert(state.commandDetailControls, argsLabel)
    table.insert(state.commandDetailControls, GMCC_ArgsBox)
    table.insert(state.commandDetailControls, commandLabel)
    table.insert(state.commandDetailControls, GMCC_CommandBox)
    table.insert(state.commandDetailControls, run)
    table.insert(state.commandDetailControls, help)
    table.insert(state.commandDetailControls, last)

    GMCC_MountStatus = CreateLabel(panel, "GMCC_MountStatus", "", "small")
    GMCC_MountStatus:SetPoint("TOPLEFT", 282, -222)
    GMCC_MountStatus:SetWidth(225)
    GMCC_MountStatus:Hide()

    GMCC_MountPrev = CreateButton(panel, "GMCC_MountPrev", "Prev", 54, 22)
    GMCC_MountPrev:SetPoint("LEFT", GMCC_MountStatus, "RIGHT", 8, 0)
    GMCC_MountPrev:SetScript("OnClick", function()
        state.mountPage = state.mountPage - 1
        RefreshMountRows()
    end)
    GMCC_MountPrev:Hide()

    GMCC_MountNext = CreateButton(panel, "GMCC_MountNext", "Next", 54, 22)
    GMCC_MountNext:SetPoint("LEFT", GMCC_MountPrev, "RIGHT", 4, 0)
    GMCC_MountNext:SetScript("OnClick", function()
        state.mountPage = state.mountPage + 1
        RefreshMountRows()
    end)
    GMCC_MountNext:Hide()

    for i = 1, MOUNT_ROWS do
        local row = CreateFrame("Frame", "GMCC_MountRow" .. i, panel)
        row:SetWidth(360)
        row:SetHeight(24)
        if i == 1 then
            row:SetPoint("TOPLEFT", GMCC_MountStatus, "BOTTOMLEFT", 0, -8)
        else
            row:SetPoint("TOPLEFT", state.mountRows[i - 1], "BOTTOMLEFT", 0, -2)
        end

        row.label = CreateLabel(row, nil, "", "small")
        row.label:SetPoint("LEFT", 0, 0)
        row.label:SetWidth(285)

        row.learn = CreateButton(row, nil, "Learn", 62, 22)
        row.learn:SetPoint("RIGHT", 0, 0)
        row.learn:SetScript("OnClick", function(self)
            local parent = self:GetParent()
            if parent.mount then
                RunCommand(".learn " .. parent.mount.id)
            end
        end)

        row:Hide()
        state.mountRows[i] = row
    end
end

local function BuildFrame()
    local frame = CreateFrame("Frame", "GMCommandCenterFrame", UIParent)
    frame:SetWidth(680)
    frame:SetHeight(540)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:Hide()

    local title = CreateLabel(frame, nil, "GM Command Center", "large")
    title:SetPoint("TOPLEFT", 22, -18)

    local close = CreateButton(frame, nil, "X", 24, 22)
    close:SetPoint("TOPRIGHT", -18, -16)
    close:SetScript("OnClick", function() frame:Hide() end)

    GMCC_CommandsTab = CreateButton(frame, "GMCC_CommandsTab", "Commands", 92, 24)
    GMCC_CommandsTab:SetPoint("TOPLEFT", 18, -44)
    GMCC_CommandsTab:Disable()

    BuildCommandsPanel(frame)
    GMCC_CommandPanel:Show()
    RefreshCommandRows()
    SelectCommand(GMCC_COMMANDS[1])

    return frame
end

local function BuildLauncherButton()
    local button = CreateButton(UIParent, "GMCC_LauncherButton", "GMCC", 48, 24)
    button:SetFrameStrata("MEDIUM")
    button:SetMovable(true)
    button:EnableMouse(true)
    button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    PositionLauncherButton(button)

    button:SetScript("OnDragStart", function(self)
        state.launcherMoved = true
        self:StartMoving()
    end)
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveLauncherPosition(self)
    end)
    button:SetScript("OnClick", function(self, mouseButton)
        if state.launcherMoved then
            state.launcherMoved = false
            return
        end

        if mouseButton == "RightButton" then
            ResetLauncherButton(self)
            Print("launcher position reset.")
            return
        end

        ToggleMainFrame("")
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("GM Command Center")
        GameTooltip:AddLine("Left-click to open or close.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move. Right-click to reset.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

SLASH_GMCOMMANDCENTER1 = "/gmcc"
SLASH_GMCOMMANDCENTER2 = "/agm"
SlashCmdList["GMCOMMANDCENTER"] = ToggleMainFrame

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, arg1)
    if arg1 ~= ADDON then
        return
    end

    GMCommandCenterDB = GMCommandCenterDB or {}
    BuildFrame()
    BuildLauncherButton()
    Print("loaded. Type /gmcc or /agm.")
end)


