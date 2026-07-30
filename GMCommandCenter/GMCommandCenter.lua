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
    browserType = nil,
    mountPage = 1,
    mountRows = {},
    commandDetailControls = {},
}

local categories = { "All", "GM", "Items", "Spells", "Character", "Teleport", "NPCs", "Quests", "Server" }

-- Mount spell data derived from the WotLKDB Mounts spell category (cat -5, skill 777).
-- Generated for offline in-game browsing because the WotLK addon sandbox cannot make HTTP requests.
GMCC_MOUNT_SPELLS = GMCC_MOUNT_SPELLS or {
    { id = 458, name = "Brown Horse", icon = "ability_mount_ridinghorse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 459, name = "Gray Wolf", icon = "ability_mount_whitedirewolf", speed = "+60%", movement = "Ground", level = 1 },
    { id = 468, name = "White Stallion", icon = "ability_mount_ridinghorse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 470, name = "Black Stallion", icon = "ability_mount_ridinghorse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 471, name = "Palamino", icon = "ability_mount_ridinghorse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 472, name = "Pinto", icon = "ability_mount_ridinghorse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 578, name = "Black Wolf", icon = "ability_mount_blackdirewolf", speed = "+60%", movement = "Ground", level = 1 },
    { id = 579, name = "Red Wolf", icon = "ability_mount_blackdirewolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 580, name = "Timber Wolf", icon = "ability_mount_blackdirewolf", speed = "+60%", movement = "Ground", level = 1 },
    { id = 581, name = "Winter Wolf", icon = "ability_mount_whitedirewolf", speed = "+60%", movement = "Ground", level = 1 },
    { id = 3363, name = "Nether Drake", icon = "ability_mount_netherdrakepurple", speed = "+310%", movement = "Flying", level = 1 },
    { id = 5784, name = "Felsteed", icon = "spell_nature_swiftness", speed = "+60%", movement = "Ground", level = 20, class = "Warlock" },
    { id = 6648, name = "Chestnut Mare", icon = "ability_mount_ridinghorse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 6653, name = "Dire Wolf", icon = "ability_mount_whitedirewolf", speed = "+60%", movement = "Ground", level = 1 },
    { id = 6654, name = "Brown Wolf", icon = "ability_mount_blackdirewolf", speed = "+60%", movement = "Ground", level = 1 },
    { id = 6777, name = "Gray Ram", icon = "ability_mount_mountainram", speed = "+60%", movement = "Ground", level = 1 },
    { id = 6896, name = "Black Ram", icon = "ability_mount_mountainram", speed = "+60%", movement = "Ground", level = 1 },
    { id = 6897, name = "Blue Ram", icon = "ability_mount_mountainram", speed = "+60%", movement = "Ground", level = 1 },
    { id = 6898, name = "White Ram", icon = "ability_mount_mountainram", speed = "+60%", movement = "Ground", level = 1 },
    { id = 6899, name = "Brown Ram", icon = "ability_mount_mountainram", speed = "+60%", movement = "Ground", level = 1 },
    { id = 8394, name = "Striped Frostsaber", icon = "ability_mount_whitetiger", speed = "+60%", movement = "Ground", level = 1 },
    { id = 8395, name = "Emerald Raptor", icon = "ability_mount_raptor", speed = "+60%", movement = "Ground", level = 1 },
    { id = 8980, name = "Skeletal Horse", icon = "ability_mount_undeadhorse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10789, name = "Spotted Frostsaber", icon = "ability_mount_whitetiger", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10793, name = "Striped Nightsaber", icon = "ability_mount_blackpanther", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10795, name = "Ivory Raptor", icon = "ability_mount_raptor", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10796, name = "Turquoise Raptor", icon = "ability_mount_raptor", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10798, name = "Obsidian Raptor", icon = "ability_mount_raptor", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10799, name = "Violet Raptor", icon = "ability_mount_raptor", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10873, name = "Red Mechanostrider", icon = "ability_mount_mechastrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 10969, name = "Blue Mechanostrider", icon = "ability_mount_mechastrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 13819, name = "Warhorse", icon = "spell_nature_swiftness", speed = "+60%", movement = "Ground", level = 20, class = "Paladin" },
    { id = 15779, name = "White Mechanostrider Mod B", icon = "ability_mount_mechastrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 15780, name = "Green Mechanostrider", icon = "ability_mount_mechastrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 15781, name = "Steel Mechanostrider", icon = "ability_mount_mechastrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 16055, name = "Black Nightsaber", icon = "ability_mount_blackpanther", speed = "+100%", movement = "Ground", level = 1 },
    { id = 16056, name = "Ancient Frostsaber", icon = "ability_mount_whitetiger", speed = "+100%", movement = "Ground", level = 1 },
    { id = 16058, name = "Primal Leopard", icon = "ability_mount_jungletiger", speed = "+60%", movement = "Ground", level = 1 },
    { id = 16059, name = "Tawny Sabercat", icon = "ability_mount_jungletiger", speed = "+60%", movement = "Ground", level = 1 },
    { id = 16060, name = "Golden Sabercat", icon = "ability_mount_jungletiger", speed = "+60%", movement = "Ground", level = 1 },
    { id = 16080, name = "Red Wolf", icon = "ability_mount_blackdirewolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 16081, name = "Winter Wolf", icon = "ability_mount_whitedirewolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 16082, name = "Palomino", icon = "ability_mount_ridinghorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 16083, name = "White Stallion", icon = "ability_mount_ridinghorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 16084, name = "Mottled Red Raptor", icon = "ability_mount_raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 17229, name = "Winterspring Frostsaber", icon = "ability_mount_pinktiger", speed = "+100%", movement = "Ground", level = 1 },
    { id = 17450, name = "Ivory Raptor", icon = "ability_mount_raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 17453, name = "Green Mechanostrider", icon = "ability_mount_mechastrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17454, name = "Unpainted Mechanostrider", icon = "ability_mount_mechastrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17455, name = "Purple Mechanostrider", icon = "ability_mount_mechastrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17456, name = "Red and Blue Mechanostrider", icon = "ability_mount_mechastrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17458, name = "Fluorescent Green Mechanostrider", icon = "ability_mount_mechastrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17459, name = "Icy Blue Mechanostrider Mod A", icon = "ability_mount_mechastrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 17460, name = "Frost Ram", icon = "ability_mount_mountainram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 17461, name = "Black Ram", icon = "ability_mount_mountainram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 17462, name = "Red Skeletal Horse", icon = "ability_mount_undeadhorse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17463, name = "Blue Skeletal Horse", icon = "ability_mount_undeadhorse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17464, name = "Brown Skeletal Horse", icon = "ability_mount_undeadhorse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 17465, name = "Green Skeletal Warhorse", icon = "ability_mount_undeadhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 17481, name = "Rivendare's Deathcharger", icon = "ability_mount_undeadhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 18363, name = "Riding Kodo", icon = "inv_misc_head_tauren_02", speed = "+60%", movement = "Ground", level = 1 },
    { id = 18989, name = "Gray Kodo", icon = "ability_mount_kodo_01", speed = "+60%", movement = "Ground", level = 1 },
    { id = 18990, name = "Brown Kodo", icon = "ability_mount_kodo_03", speed = "+60%", movement = "Ground", level = 1 },
    { id = 18991, name = "Green Kodo", icon = "ability_mount_kodo_02", speed = "+100%", movement = "Ground", level = 1 },
    { id = 18992, name = "Teal Kodo", icon = "ability_mount_kodo_02", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23161, name = "Dreadsteed", icon = "ability_mount_dreadsteed", speed = "+100%", movement = "Ground", level = 40, class = "Warlock" },
    { id = 23214, name = "Charger", icon = "ability_mount_charger", speed = "+100%", movement = "Ground", level = 40, class = "Paladin" },
    { id = 23219, name = "Swift Mistsaber", icon = "ability_mount_blackpanther", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23220, name = "Swift Dawnsaber", icon = "ability_mount_jungletiger", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23221, name = "Swift Frostsaber", icon = "ability_mount_whitetiger", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23222, name = "Swift Yellow Mechanostrider", icon = "ability_mount_mechastrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23223, name = "Swift White Mechanostrider", icon = "ability_mount_mechastrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23225, name = "Swift Green Mechanostrider", icon = "ability_mount_mechastrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23227, name = "Swift Palomino", icon = "ability_mount_ridinghorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23228, name = "Swift White Steed", icon = "ability_mount_ridinghorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23229, name = "Swift Brown Steed", icon = "ability_mount_ridinghorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23238, name = "Swift Brown Ram", icon = "ability_mount_mountainram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23239, name = "Swift Gray Ram", icon = "ability_mount_mountainram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23240, name = "Swift White Ram", icon = "ability_mount_mountainram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23241, name = "Swift Blue Raptor", icon = "ability_mount_raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23242, name = "Swift Olive Raptor", icon = "ability_mount_raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23243, name = "Swift Orange Raptor", icon = "ability_mount_raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23246, name = "Purple Skeletal Warhorse", icon = "ability_mount_undeadhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23247, name = "Great White Kodo", icon = "ability_mount_kodo_01", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23248, name = "Great Gray Kodo", icon = "ability_mount_kodo_01", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23249, name = "Great Brown Kodo", icon = "ability_mount_kodo_03", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23250, name = "Swift Brown Wolf", icon = "ability_mount_blackdirewolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23251, name = "Swift Timber Wolf", icon = "ability_mount_whitedirewolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23252, name = "Swift Gray Wolf", icon = "ability_mount_whitedirewolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 23338, name = "Swift Stormsaber", icon = "ability_mount_blackpanther", speed = "+100%", movement = "Ground", level = 1 },
    { id = 24242, name = "Swift Razzashi Raptor", icon = "ability_mount_raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 24252, name = "Swift Zulian Tiger", icon = "ability_mount_jungletiger", speed = "+100%", movement = "Ground", level = 1 },
    { id = 25953, name = "Blue Qiraji Battle Tank", icon = "inv_misc_qirajicrystal_04", speed = "+100%", movement = "Ground", level = 1 },
    { id = 26054, name = "Red Qiraji Battle Tank", icon = "inv_misc_qirajicrystal_02", speed = "+100%", movement = "Ground", level = 1 },
    { id = 26055, name = "Yellow Qiraji Battle Tank", icon = "inv_misc_qirajicrystal_01", speed = "+100%", movement = "Ground", level = 1 },
    { id = 26056, name = "Green Qiraji Battle Tank", icon = "inv_misc_qirajicrystal_03", speed = "+100%", movement = "Ground", level = 1 },
    { id = 26656, name = "Black Qiraji Battle Tank", icon = "inv_misc_qirajicrystal_05", speed = "+100%", movement = "Ground", level = 1 },
    { id = 28828, name = "Nether Drake", icon = "ability_mount_netherdrakepurple", speed = "+300%", movement = "Flying", level = 1 },
    { id = 29059, name = "Naxxramas Deathcharger", icon = "ability_mount_undeadhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 30174, name = "Riding Turtle", icon = "ability_hunter_pet_turtle", speed = "+0%", movement = "Unknown", level = 1 },
    { id = 32235, name = "Golden Gryphon", icon = "ability_mount_goldengryphon", speed = "+150%", movement = "Flying", level = 1 },
    { id = 32239, name = "Ebon Gryphon", icon = "ability_mount_ebongryphon", speed = "+150%", movement = "Flying", level = 1 },
    { id = 32240, name = "Snowy Gryphon", icon = "ability_mount_snowygryphon", speed = "+150%", movement = "Flying", level = 1 },
    { id = 32242, name = "Swift Blue Gryphon", icon = "ability_mount_gryphon_01", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32243, name = "Tawny Wind Rider", icon = "ability_mount_tawnywindrider", speed = "+150%", movement = "Flying", level = 1 },
    { id = 32244, name = "Blue Wind Rider", icon = "ability_mount_bluewindrider", speed = "+150%", movement = "Flying", level = 1 },
    { id = 32245, name = "Green Wind Rider", icon = "ability_mount_greenwindrider", speed = "+150%", movement = "Flying", level = 1 },
    { id = 32246, name = "Swift Red Wind Rider", icon = "ability_mount_swiftredwindrider", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32289, name = "Swift Red Gryphon", icon = "ability_mount_gryphon_01", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32290, name = "Swift Green Gryphon", icon = "ability_mount_gryphon_01", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32292, name = "Swift Purple Gryphon", icon = "ability_mount_gryphon_01", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32295, name = "Swift Green Wind Rider", icon = "ability_mount_swiftgreenwindrider", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32296, name = "Swift Yellow Wind Rider", icon = "ability_mount_swiftyellowwindrider", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32297, name = "Swift Purple Wind Rider", icon = "ability_mount_swiftpurplewindrider", speed = "+280%", movement = "Flying", level = 1 },
    { id = 32345, name = "Peep the Phoenix Mount", icon = "spell_fireresistancetotem_01", speed = "+310%", movement = "Flying", level = 1 },
    { id = 33630, name = "Blue Mechanostrider", icon = "ability_mount_mechastrider", speed = "+60%", movement = "Ground", level = 1 },
    { id = 33660, name = "Swift Pink Hawkstrider", icon = "ability_mount_cockatricemountelite", speed = "+100%", movement = "Ground", level = 1 },
    { id = 34406, name = "Brown Elekk", icon = "ability_mount_ridingelekk", speed = "+60%", movement = "Ground", level = 1 },
    { id = 34407, name = "Great Elite Elekk", icon = "ability_mount_ridingelekkelite", speed = "+100%", movement = "Ground", level = 1 },
    { id = 34767, name = "Summon Charger", icon = "ability_mount_charger", speed = "+100%", movement = "Ground", level = 40, class = "Paladin" },
    { id = 34769, name = "Summon Warhorse", icon = "spell_nature_swiftness", speed = "+60%", movement = "Ground", level = 20, class = "Paladin" },
    { id = 34790, name = "Dark War Talbuk", icon = "inv_misc_foot_centaur", speed = "+100%", movement = "Ground", level = 1 },
    { id = 34795, name = "Red Hawkstrider", icon = "ability_mount_cockatricemount", speed = "+60%", movement = "Ground", level = 1 },
    { id = 34896, name = "Cobalt War Talbuk", icon = "inv_misc_foot_centaur", speed = "+100%", movement = "Ground", level = 1 },
    { id = 34897, name = "White War Talbuk", icon = "inv_misc_foot_centaur", speed = "+100%", movement = "Ground", level = 1 },
    { id = 34898, name = "Silver War Talbuk", icon = "inv_misc_foot_centaur", speed = "+100%", movement = "Ground", level = 1 },
    { id = 34899, name = "Tan War Talbuk", icon = "inv_misc_foot_centaur", speed = "+100%", movement = "Ground", level = 1 },
    { id = 35018, name = "Purple Hawkstrider", icon = "ability_mount_cockatricemount_purple", speed = "+60%", movement = "Ground", level = 1 },
    { id = 35020, name = "Blue Hawkstrider", icon = "ability_mount_cockatricemount_blue", speed = "+60%", movement = "Ground", level = 1 },
    { id = 35022, name = "Black Hawkstrider", icon = "ability_mount_cockatricemount_black", speed = "+60%", movement = "Ground", level = 1 },
    { id = 35025, name = "Swift Green Hawkstrider", icon = "ability_mount_cockatricemountelite_green", speed = "+100%", movement = "Ground", level = 1 },
    { id = 35027, name = "Swift Purple Hawkstrider", icon = "ability_mount_cockatricemountelite_purple", speed = "+100%", movement = "Ground", level = 1 },
    { id = 35710, name = "Gray Elekk", icon = "ability_mount_ridingelekk_grey", speed = "+60%", movement = "Ground", level = 1 },
    { id = 35711, name = "Purple Elekk", icon = "ability_mount_ridingelekk_purple", speed = "+60%", movement = "Ground", level = 1 },
    { id = 35712, name = "Great Green Elekk", icon = "ability_mount_ridingelekkelite_green", speed = "+100%", movement = "Ground", level = 1 },
    { id = 35713, name = "Great Blue Elekk", icon = "ability_mount_ridingelekkelite_blue", speed = "+100%", movement = "Ground", level = 1 },
    { id = 35714, name = "Great Purple Elekk", icon = "ability_mount_ridingelekkelite_purple", speed = "+100%", movement = "Ground", level = 1 },
    { id = 36702, name = "Fiery Warhorse", icon = "ability_mount_dreadsteed", speed = "+100%", movement = "Ground", level = 1 },
    { id = 37015, name = "Swift Nether Drake", icon = "ability_mount_netherdrakeelite", speed = "+310%", movement = "Flying", level = 1 },
    { id = 39315, name = "Cobalt Riding Talbuk", icon = "inv_misc_foot_centaur", speed = "+100%", movement = "Ground", level = 1 },
    { id = 39316, name = "Dark Riding Talbuk", icon = "inv_misc_foot_centaur", speed = "+100%", movement = "Ground", level = 1 },
    { id = 39317, name = "Silver Riding Talbuk", icon = "inv_misc_foot_centaur", speed = "+100%", movement = "Ground", level = 1 },
    { id = 39318, name = "Tan Riding Talbuk", icon = "inv_misc_foot_centaur", speed = "+100%", movement = "Ground", level = 1 },
    { id = 39319, name = "White Riding Talbuk", icon = "inv_misc_foot_centaur", speed = "+100%", movement = "Ground", level = 1 },
    { id = 39798, name = "Green Riding Nether Ray", icon = "ability_hunter_pet_netherray", speed = "+280%", movement = "Flying", level = 1 },
    { id = 39800, name = "Red Riding Nether Ray", icon = "ability_hunter_pet_netherray", speed = "+280%", movement = "Flying", level = 1 },
    { id = 39801, name = "Purple Riding Nether Ray", icon = "ability_hunter_pet_netherray", speed = "+280%", movement = "Flying", level = 1 },
    { id = 39802, name = "Silver Riding Nether Ray", icon = "ability_hunter_pet_netherray", speed = "+280%", movement = "Flying", level = 1 },
    { id = 39803, name = "Blue Riding Nether Ray", icon = "ability_hunter_pet_netherray", speed = "+280%", movement = "Flying", level = 1 },
    { id = 40192, name = "Ashes of Al'ar", icon = "inv_misc_summerfest_brazierorange", speed = "+310%", movement = "Flying", level = 1 },
    { id = 41252, name = "Raven Lord", icon = "inv-mount_raven_54", speed = "+100%", movement = "Ground", level = 1 },
    { id = 41513, name = "Onyx Netherwing Drake", icon = "ability_mount_netherdrakepurple", speed = "+280%", movement = "Flying", level = 1 },
    { id = 41514, name = "Azure Netherwing Drake", icon = "ability_mount_netherdrakepurple", speed = "+280%", movement = "Flying", level = 1 },
    { id = 41515, name = "Cobalt Netherwing Drake", icon = "ability_mount_netherdrakepurple", speed = "+280%", movement = "Flying", level = 1 },
    { id = 41516, name = "Purple Netherwing Drake", icon = "ability_mount_netherdrakepurple", speed = "+280%", movement = "Flying", level = 1 },
    { id = 41517, name = "Veridian Netherwing Drake", icon = "ability_mount_netherdrakepurple", speed = "+280%", movement = "Flying", level = 1 },
    { id = 41518, name = "Violet Netherwing Drake", icon = "ability_mount_netherdrakepurple", speed = "+280%", movement = "Flying", level = 1 },
    { id = 42776, name = "Spectral Tiger", icon = "ability_mount_spectraltiger", speed = "+60%", movement = "Ground", level = 1 },
    { id = 42777, name = "Swift Spectral Tiger", icon = "ability_mount_spectraltiger", speed = "+100%", movement = "Ground", level = 1 },
    { id = 43688, name = "Amani War Bear", icon = "ability_druid_challangingroar", speed = "+100%", movement = "Ground", level = 1 },
    { id = 43810, name = "Frost Wyrm", icon = "inv_misc_head_dragon_blue", speed = "+280%", movement = "Flying", level = 1 },
    { id = 43899, name = "Brewfest Ram", icon = "ability_mount_mountainram", speed = "+60%", movement = "Ground", level = 1 },
    { id = 43900, name = "Swift Brewfest Ram", icon = "ability_mount_mountainram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 43927, name = "Cenarion War Hippogryph", icon = "ability_mount_warhippogryph", speed = "+280%", movement = "Flying", level = 1 },
    { id = 44151, name = "Turbo-Charged Flying Machine", icon = "ability_mount_gyrocoptorelite", speed = "+280%", movement = "Flying", level = 1 },
    { id = 44153, name = "Flying Machine", icon = "ability_mount_gyrocoptor", speed = "+150%", movement = "Flying", level = 1 },
    { id = 44317, name = "Merciless Nether Drake", icon = "ability_mount_netherdrakeelite", speed = "+310%", movement = "Flying", level = 1 },
    { id = 44744, name = "Merciless Nether Drake", icon = "ability_mount_netherdrakeelite", speed = "+310%", movement = "Flying", level = 1 },
    { id = 46197, name = "X-51 Nether-Rocket", icon = "inv_misc_missilesmall_blue", speed = "+150%", movement = "Flying", level = 1 },
    { id = 46199, name = "X-51 Nether-Rocket X-TREME", icon = "inv_misc_missilesmall_red", speed = "+280%", movement = "Flying", level = 1 },
    { id = 46628, name = "Swift White Hawkstrider", icon = "ability_mount_cockatricemountelite_white", speed = "+100%", movement = "Ground", level = 1 },
    { id = 47037, name = "Swift War  Elekk", icon = "ability_mount_ridingelekkelite_blue", speed = "+100%", movement = "Ground", level = 1 },
    { id = 48025, name = "Headless Horseman's Mount", icon = "ability_mount_nightmarehorse", speed = "?", movement = "Unknown", level = 0 },
    { id = 48778, name = "Acherus Deathcharger", icon = "spell_deathknight_summondeathcharger", speed = "+100%", movement = "Ground", level = 55, class = "Death Knight" },
    { id = 48954, name = "Swift Zhevra", icon = "ability_mount_charger", speed = "+100%", movement = "Ground", level = 1 },
    { id = 49193, name = "Vengeful Nether Drake", icon = "ability_mount_netherdrakeelite", speed = "+310%", movement = "Flying", level = 1 },
    { id = 49322, name = "Swift Zhevra", icon = "ability_mount_charger", speed = "+100%", movement = "Ground", level = 1 },
    { id = 49378, name = "Brewfest Riding Kodo", icon = "ability_mount_kotobrewfest", speed = "+60%", movement = "Ground", level = 1 },
    { id = 49379, name = "Great Brewfest Kodo", icon = "ability_mount_kotobrewfest", speed = "+100%", movement = "Ground", level = 1 },
    { id = 50869, name = "Brewfest Kodo", icon = "ability_mount_kotobrewfest", speed = "+60%", movement = "Ground", level = 1 },
    { id = 50870, name = "Brewfest Ram", icon = "ability_mount_mountainram", speed = "+60%", movement = "Ground", level = 1 },
    { id = 51412, name = "Big Battle Bear", icon = "ability_druid_challangingroar", speed = "+100%", movement = "Ground", level = 1 },
    { id = 51960, name = "Frost Wyrm Mount", icon = "inv_misc_gem_sapphire_01", speed = "+280%", movement = "Flying", level = 1 },
    { id = 54729, name = "Winged Steed of the Ebon Blade", icon = "ability_mount_ebonblade", speed = "?", movement = "Unknown", level = 1 },
    { id = 54753, name = "White Polar Bear", icon = "ability_mount_polarbear_white", speed = "+100%", movement = "Ground", level = 1 },
    { id = 55531, name = "Mechano-hog", icon = "inv_misc_key_14", speed = "+100%", movement = "Ground", level = 1 },
    { id = 58615, name = "Brutal Nether Drake", icon = "ability_mount_netherdrakeelite", speed = "+310%", movement = "Flying", level = 1 },
    { id = 58983, name = "Big Blizzard Bear", icon = "ability_mount_bigblizzardbear", speed = "?", movement = "Unknown", level = 0 },
    { id = 59567, name = "Azure Drake", icon = "ability_mount_drake_azure", speed = "+280%", movement = "Flying", level = 1 },
    { id = 59568, name = "Blue Drake", icon = "ability_mount_drake_azure", speed = "+280%", movement = "Flying", level = 1 },
    { id = 59569, name = "Bronze Drake", icon = "ability_mount_drake_bronze", speed = "+280%", movement = "Flying", level = 1 },
    { id = 59570, name = "Red Drake", icon = "ability_mount_drake_red", speed = "+280%", movement = "Flying", level = 1 },
    { id = 59571, name = "Twilight Drake", icon = "ability_mount_drake_twilight", speed = "+280%", movement = "Flying", level = 1 },
    { id = 59572, name = "Black Polar Bear", icon = "ability_mount_polarbear_black", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59573, name = "Brown Polar Bear", icon = "ability_mount_polarbear_brown", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59650, name = "Black Drake", icon = "ability_mount_drake_twilight", speed = "+280%", movement = "Flying", level = 1 },
    { id = 59785, name = "Black War Mammoth", icon = "ability_mount_mammoth_black", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59788, name = "Black War Mammoth", icon = "ability_mount_mammoth_black", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59791, name = "Wooly Mammoth", icon = "ability_mount_mammoth_brown", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59793, name = "Wooly Mammoth", icon = "ability_mount_mammoth_brown", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59797, name = "Ice Mammoth", icon = "ability_mount_mammoth_white", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59799, name = "Ice Mammoth", icon = "ability_mount_mammoth_white", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59802, name = "Grand Ice Mammoth", icon = "ability_mount_mammoth_white", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59804, name = "Grand Ice Mammoth", icon = "ability_mount_mammoth_white", speed = "+100%", movement = "Ground", level = 1 },
    { id = 59961, name = "Red Proto-Drake", icon = "ability_mount_drake_proto", speed = "+280%", movement = "Flying", level = 1 },
    { id = 59976, name = "Black Proto-Drake", icon = "ability_mount_drake_proto", speed = "+310%", movement = "Flying", level = 1 },
    { id = 59996, name = "Blue Proto-Drake", icon = "ability_mount_drake_proto", speed = "+280%", movement = "Flying", level = 1 },
    { id = 60002, name = "Time-Lost Proto-Drake", icon = "ability_mount_drake_proto", speed = "+280%", movement = "Flying", level = 1 },
    { id = 60021, name = "Plagued Proto-Drake", icon = "ability_mount_drake_proto", speed = "+310%", movement = "Flying", level = 1 },
    { id = 60024, name = "Violet Proto-Drake", icon = "ability_mount_drake_proto", speed = "+310%", movement = "Flying", level = 1 },
    { id = 60025, name = "Albino Drake", icon = "ability_mount_drake_blue", speed = "+280%", movement = "Flying", level = 1 },
    { id = 60114, name = "Armored Brown Bear", icon = "ability_mount_polarbear_brown", speed = "+100%", movement = "Ground", level = 1 },
    { id = 60116, name = "Armored Brown Bear", icon = "ability_mount_polarbear_brown", speed = "+100%", movement = "Ground", level = 1 },
    { id = 60118, name = "Black War Bear", icon = "ability_mount_polarbear_black", speed = "+100%", movement = "Ground", level = 1 },
    { id = 60119, name = "Black War Bear", icon = "ability_mount_polarbear_black", speed = "+100%", movement = "Ground", level = 1 },
    { id = 60136, name = "Grand Caravan Mammoth", icon = "ability_mount_mammoth_brown", speed = "+100%", movement = "Ground", level = 1 },
    { id = 60140, name = "Grand Caravan Mammoth", icon = "ability_mount_mammoth_brown", speed = "+100%", movement = "Ground", level = 1 },
    { id = 60424, name = "Mekgineer's Chopper", icon = "inv_misc_key_14", speed = "+100%", movement = "Ground", level = 1 },
    { id = 61229, name = "Armored Snowy Gryphon", icon = "ability_mount_gryphon_01", speed = "+280%", movement = "Flying", level = 1 },
    { id = 61230, name = "Armored Blue Wind Rider", icon = "ability_mount_swiftpurplewindrider", speed = "+280%", movement = "Flying", level = 1 },
    { id = 61294, name = "Green Proto-Drake", icon = "ability_mount_drake_proto", speed = "+280%", movement = "Flying", level = 1 },
    { id = 61309, name = "Magnificent Flying Carpet", icon = "ability_mount_magnificentflyingcarpet", speed = "+280%", movement = "Flying", level = 0 },
    { id = 61425, name = "Traveler's Tundra Mammoth", icon = "ability_mount_mammoth_brown_3seater", speed = "+100%", movement = "Ground", level = 1 },
    { id = 61442, name = "Swift Mooncloth Carpet", icon = "inv_fabric_moonrag_primal", speed = "+0%", movement = "Unknown", level = 0 },
    { id = 61444, name = "Swift Shadoweave Carpet", icon = "inv_fabric_felcloth_ebon", speed = "+0%", movement = "Unknown", level = 0 },
    { id = 61446, name = "Swift Spellfire Carpet", icon = "inv_fabric_spellfire", speed = "+0%", movement = "Unknown", level = 0 },
    { id = 61447, name = "Traveler's Tundra Mammoth", icon = "ability_mount_mammoth_brown_3seater", speed = "+100%", movement = "Ground", level = 1 },
    { id = 61451, name = "Flying Carpet", icon = "ability_mount_flyingcarpet", speed = "+150%", movement = "Flying", level = 0 },
    { id = 61465, name = "Grand Black War Mammoth", icon = "ability_mount_mammoth_black_3seater", speed = "+100%", movement = "Ground", level = 1 },
    { id = 61467, name = "Grand Black War Mammoth", icon = "ability_mount_mammoth_black_3seater", speed = "+100%", movement = "Ground", level = 1 },
    { id = 61469, name = "Grand Ice Mammoth", icon = "ability_mount_mammoth_white_3seater", speed = "+100%", movement = "Ground", level = 1 },
    { id = 61470, name = "Grand Ice Mammoth", icon = "ability_mount_mammoth_white_3seater", speed = "+100%", movement = "Ground", level = 1 },
    { id = 61996, name = "Blue Dragonhawk", icon = "ability_hunter_pet_dragonhawk", speed = "+280%", movement = "Flying", level = 1 },
    { id = 61997, name = "Red Dragonhawk", icon = "ability_hunter_pet_dragonhawk", speed = "+280%", movement = "Flying", level = 1 },
    { id = 62048, name = "Black Dragonhawk Mount", icon = "ability_hunter_pet_dragonhawk", speed = "+280%", movement = "Flying", level = 1 },
    { id = 63232, name = "Stormwind Steed", icon = "ability_mount_ridinghorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63635, name = "Darkspear Raptor", icon = "ability_mount_raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63636, name = "Ironforge Ram", icon = "ability_mount_mountainram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63637, name = "Darnassian Nightsaber", icon = "ability_mount_whitetiger", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63638, name = "Gnomeregan Mechanostrider", icon = "ability_mount_mechastrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63639, name = "Exodar Elekk", icon = "ability_mount_ridingelekkelite", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63640, name = "Orgrimmar Wolf", icon = "ability_mount_blackdirewolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63641, name = "Thunder Bluff Kodo", icon = "ability_mount_kodo_01", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63642, name = "Silvermoon Hawkstrider", icon = "ability_mount_cockatricemountelite_purple", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63643, name = "Forsaken Warhorse", icon = "ability_mount_undeadhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 63796, name = "Mimiron's Head", icon = "inv_misc_enggizmos_03", speed = "+310%", movement = "Flying", level = 1 },
    { id = 63844, name = "Argent Hippogryph", icon = "ability_mount_warhippogryph", speed = "+280%", movement = "Flying", level = 1 },
    { id = 63956, name = "Ironbound Proto-Drake", icon = "ability_mount_razorscale", speed = "+310%", movement = "Flying", level = 1 },
    { id = 63963, name = "Rusted Proto-Drake", icon = "ability_mount_razorscale", speed = "+310%", movement = "Flying", level = 1 },
    { id = 64656, name = "Blue Skeletal Warhorse", icon = "ability_mount_undeadhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 64657, name = "White Kodo", icon = "ability_mount_kodo_01", speed = "+60%", movement = "Ground", level = 1 },
    { id = 64658, name = "Black Wolf", icon = "ability_mount_blackdirewolf", speed = "+60%", movement = "Ground", level = 1 },
    { id = 64659, name = "Venomhide Ravasaur", icon = "ability_mount_raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 64731, name = "Sea Turtle", icon = "inv_misc_fish_turtle_02", speed = "+60%", movement = "Aquatic", level = 1 },
    { id = 64927, name = "Deadly Gladiator's Frost Wyrm", icon = "ability_mount_redfrostwyrm_01", speed = "+310%", movement = "Flying", level = 1 },
    { id = 64977, name = "Black Skeletal Horse", icon = "ability_mount_undeadhorse", speed = "+60%", movement = "Ground", level = 1 },
    { id = 65439, name = "Furious Gladiator's Frost Wyrm", icon = "ability_mount_redfrostwyrm_01", speed = "+310%", movement = "Flying", level = 1 },
    { id = 65637, name = "Great Red Elekk", icon = "ability_mount_ridingelekkelite", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65638, name = "Swift Moonsaber", icon = "ability_mount_whitetiger", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65639, name = "Swift Red Hawkstrider", icon = "ability_mount_cockatricemountelite_purple", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65640, name = "Swift Gray Steed", icon = "ability_mount_ridinghorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65641, name = "Great Golden Kodo", icon = "ability_mount_kodo_01", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65642, name = "Turbostrider", icon = "ability_mount_mechastrider", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65643, name = "Swift Violet Ram", icon = "ability_mount_mountainram", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65644, name = "Swift Purple Raptor", icon = "ability_mount_raptor", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65645, name = "White Skeletal Warhorse", icon = "ability_mount_undeadhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65646, name = "Swift Burgundy Wolf", icon = "ability_mount_blackdirewolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 65917, name = "Magic Rooster", icon = "inv_egg_03", speed = "?", movement = "Unknown", level = 1 },
    { id = 66087, name = "Silver Covenant Hippogryph", icon = "ability_mount_warhippogryph", speed = "+280%", movement = "Flying", level = 1 },
    { id = 66088, name = "Sunreaver Dragonhawk", icon = "ability_hunter_pet_dragonhawk", speed = "+280%", movement = "Flying", level = 1 },
    { id = 66090, name = "Quel'dorei Steed", icon = "ability_mount_ridinghorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 66091, name = "Sunreaver Hawkstrider", icon = "ability_mount_cockatricemountelite_purple", speed = "+100%", movement = "Ground", level = 1 },
    { id = 66122, name = "Magic Rooster", icon = "spell_magic_polymorphchicken", speed = "+100%", movement = "Ground", level = 1 },
    { id = 66123, name = "Magic Rooster", icon = "spell_magic_polymorphchicken", speed = "+100%", movement = "Ground", level = 1 },
    { id = 66124, name = "Magic Rooster", icon = "spell_magic_polymorphchicken", speed = "+100%", movement = "Ground", level = 1 },
    { id = 66846, name = "Ochre Skeletal Warhorse", icon = "ability_mount_undeadhorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 66847, name = "Striped Dawnsaber", icon = "ability_mount_whitetiger", speed = "+60%", movement = "Ground", level = 1 },
    { id = 66906, name = "Argent Charger", icon = "ability_mount_charger", speed = "+100%", movement = "Ground", level = 40 },
    { id = 66907, name = "Argent Warhorse", icon = "spell_nature_swiftness", speed = "+60%", movement = "Ground", level = 20 },
    { id = 67336, name = "Relentless Gladiator's Frost Wyrm", icon = "ability_mount_redfrostwyrm_01", speed = "+310%", movement = "Flying", level = 1 },
    { id = 67466, name = "Argent Warhorse", icon = "ability_mount_ridinghorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 68056, name = "Swift Horde Wolf", icon = "ability_mount_blackdirewolf", speed = "+100%", movement = "Ground", level = 1 },
    { id = 68057, name = "Swift Alliance Steed", icon = "ability_mount_ridinghorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 68187, name = "Crusader's White Warhorse", icon = "ability_mount_ridinghorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 68188, name = "Crusader's Black Warhorse", icon = "ability_mount_nightmarehorse", speed = "+100%", movement = "Ground", level = 1 },
    { id = 69395, name = "Onyxian Drake", icon = "achievement_boss_onyxia", speed = "+310%", movement = "Flying", level = 1 },
    { id = 71342, name = "Big Love Rocket", icon = "inv_valentinepinkrocket", speed = "?", movement = "Unknown", level = 0 },
    { id = 71810, name = "Wrathful Gladiator's Frost Wyrm", icon = "ability_mount_redfrostwyrm_01", speed = "+310%", movement = "Flying", level = 1 },
}
-- Heirloom item data derived from the WotLKDB item filter qu=7;minle=1;maxle=1.
GMCC_HEIRLOOM_ITEMS = GMCC_HEIRLOOM_ITEMS or {
    { id = 38691, name = "Ancestral Claymore", icon = "inv_sword_92", type = "Weapon", subtype = "Two-Handed Sword", slot = "Two-Hand", faction = "Both", level = 1, reqLevel = 1 },
    { id = 42943, name = "Bloodied Arcanite Reaper", icon = "inv_axe_09", type = "Weapon", subtype = "Axe", slot = "Two-Hand", faction = "Both", level = 1, reqLevel = 1 },
    { id = 42944, name = "Balanced Heartseeker", icon = "inv_sword_17", type = "Weapon", subtype = "Dagger", slot = "One-Hand", faction = "Both", level = 1, reqLevel = 1 },
    { id = 42945, name = "Venerable Dal'Rend's Sacred Charge", icon = "inv_sword_43", type = "Weapon", subtype = "Sword", slot = "Main Hand", faction = "Both", level = 1, reqLevel = 1 },
    { id = 42946, name = "Charmed Ancient Bone Bow", icon = "inv_weapon_bow_08", type = "Weapon", subtype = "Bow", slot = "Ranged", faction = "Both", level = 1, reqLevel = 1 },
    { id = 42947, name = "Dignified Headmaster's Charge", icon = "inv_jewelry_talisman_12", type = "Weapon", subtype = "Staff", slot = "Two-Hand", faction = "Both", level = 1, reqLevel = 1 },
    { id = 42948, name = "Devout Aurastone Hammer", icon = "inv_hammer_05", type = "Weapon", subtype = "Mace", slot = "Main Hand", faction = "Both", level = 1, reqLevel = 1 },
    { id = 42949, name = "Polished Spaulders of Valor", icon = "inv_shoulder_30", type = "Armor", subtype = "Plate", slot = "Shoulder", faction = "Both", level = 1, reqLevel = 1 },
    { id = 42950, name = "Champion Herod's Shoulder", icon = "inv_shoulder_01", type = "Armor", subtype = "Mail", slot = "Shoulder", faction = "Both", level = 1, reqLevel = 1 },
    { id = 42951, name = "Mystical Pauldrons of Elements", icon = "inv_shoulder_29", type = "Armor", subtype = "Mail", slot = "Shoulder", faction = "Both", level = 1, reqLevel = 1 },
    { id = 42952, name = "Stained Shadowcraft Spaulders", icon = "inv_shoulder_07", type = "Armor", subtype = "Leather", slot = "Shoulder", faction = "Both", level = 1, reqLevel = 1 },
    { id = 42984, name = "Preened Ironfeather Shoulders", icon = "inv_shoulder_06", type = "Armor", subtype = "Leather", slot = "Shoulder", faction = "Both", level = 1, reqLevel = 1 },
    { id = 42985, name = "Tattered Dreadmist Mantle", icon = "inv_misc_bone_taurenskull_01", type = "Armor", subtype = "Cloth", slot = "Shoulder", faction = "Both", level = 1, reqLevel = 1 },
    { id = 42991, name = "Swift Hand of Justice", icon = "inv_jewelry_talisman_01", type = "Armor", subtype = "Trinket", slot = "Trinket", faction = "Both", level = 1, reqLevel = 1 },
    { id = 42992, name = "Discerning Eye of the Beast", icon = "inv_jewelry_talisman_08", type = "Armor", subtype = "Trinket", slot = "Trinket", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44090, name = "Test Mail Shoulder 2", icon = "inv_shoulder_01", type = "Armor", subtype = "Mail", slot = "Shoulder", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44091, name = "Sharpened Scarlet Kris", icon = "inv_weapon_shortblade_03", type = "Weapon", subtype = "Dagger", slot = "One-Hand", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44092, name = "Reforged Truesilver Champion", icon = "inv_sword_19", type = "Weapon", subtype = "Two-Handed Sword", slot = "Two-Hand", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44093, name = "Upgraded Dwarven Hand Cannon", icon = "inv_weapon_rifle_09", type = "Weapon", subtype = "Gun", slot = "Ranged", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44094, name = "The Blessed Hammer of Grace", icon = "inv_hammer_07", type = "Weapon", subtype = "Mace", slot = "Main Hand", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44095, name = "Grand Staff of Jordan", icon = "inv_staff_13", type = "Weapon", subtype = "Staff", slot = "Two-Hand", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44096, name = "Battleworn Thrash Blade", icon = "inv_sword_36", type = "Weapon", subtype = "Sword", slot = "One-Hand", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44097, name = "Inherited Insignia of the Horde", icon = "inv_jewelry_trinketpvp_02", type = "Armor", subtype = "Trinket", slot = "Trinket", faction = "Horde", level = 1, reqLevel = 1 },
    { id = 44098, name = "Inherited Insignia of the Alliance", icon = "inv_jewelry_trinketpvp_01", type = "Armor", subtype = "Trinket", slot = "Trinket", faction = "Alliance", level = 1, reqLevel = 1 },
    { id = 44099, name = "Strengthened Stockade Pauldrons", icon = "inv_shoulder_20", type = "Armor", subtype = "Plate", slot = "Shoulder", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44100, name = "Pristine Lightforge Spaulders", icon = "inv_shoulder_10", type = "Armor", subtype = "Plate", slot = "Shoulder", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44101, name = "Prized Beastmaster's Mantle", icon = "inv_shoulder_10", type = "Armor", subtype = "Mail", slot = "Shoulder", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44102, name = "Aged Pauldrons of The Five Thunders", icon = "inv_shoulder_29", type = "Armor", subtype = "Mail", slot = "Shoulder", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44103, name = "Exceptional Stormshroud Shoulders", icon = "inv_shoulder_05", type = "Armor", subtype = "Leather", slot = "Shoulder", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44105, name = "Lasting Feralheart Spaulders", icon = "inv_shoulder_01", type = "Armor", subtype = "Leather", slot = "Shoulder", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44107, name = "Exquisite Sunderseer Mantle", icon = "inv_shoulder_02", type = "Armor", subtype = "Cloth", slot = "Shoulder", faction = "Both", level = 1, reqLevel = 1 },
    { id = 44115, name = "Wintergrasp Commendation", icon = "spell_frost_wizardmark", type = "Misc", subtype = "Misc", slot = "None", faction = "Both", level = 1, reqLevel = 1 },
    { id = 48677, name = "Champion's Deathdealer Breastplate", icon = "inv_chest_chain_07", type = "Armor", subtype = "Mail", slot = "Chest", faction = "Both", level = 1, reqLevel = 1 },
    { id = 48683, name = "Mystical Vest of Elements", icon = "inv_chest_chain_11", type = "Armor", subtype = "Mail", slot = "Chest", faction = "Both", level = 1, reqLevel = 1 },
    { id = 48685, name = "Polished Breastplate of Valor", icon = "inv_chest_plate03", type = "Armor", subtype = "Plate", slot = "Chest", faction = "Both", level = 1, reqLevel = 1 },
    { id = 48687, name = "Preened Ironfeather Breastplate", icon = "inv_chest_leather_06", type = "Armor", subtype = "Leather", slot = "Chest", faction = "Both", level = 1, reqLevel = 1 },
    { id = 48689, name = "Stained Shadowcraft Tunic", icon = "inv_chest_leather_07", type = "Armor", subtype = "Leather", slot = "Chest", faction = "Both", level = 1, reqLevel = 1 },
    { id = 48691, name = "Tattered Dreadmist Robe", icon = "inv_chest_cloth_49", type = "Armor", subtype = "Cloth", slot = "Chest", faction = "Both", level = 1, reqLevel = 1 },
    { id = 48716, name = "Venerable Mass of McGowan", icon = "inv_hammer_17", type = "Weapon", subtype = "Mace", slot = "One-Hand", faction = "Both", level = 1, reqLevel = 1 },
    { id = 48718, name = "Repurposed Lava Dredger", icon = "inv_gizmo_02", type = "Weapon", subtype = "Two-Handed Mace", slot = "Two-Hand", faction = "Both", level = 1, reqLevel = 1 },
    { id = 50255, name = "Dread Pirate Ring", icon = "inv_jewelry_ring_39", type = "Armor", subtype = "Ring", slot = "Finger", faction = "Both", level = 1, reqLevel = 1 },
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
    state.browserType = nil
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

local function MatchesBrowserEntry(entry)
    local needle = state.filter or ""
    if needle == "" then
        return true
    end

    local haystack = entry.id .. " " .. entry.name .. " "
        .. (entry.speed or "") .. " " .. (entry.movement or "") .. " " .. (entry.class or "") .. " "
        .. (entry.type or "") .. " " .. (entry.subtype or "") .. " " .. (entry.slot or "") .. " "
        .. (entry.faction or "")
    return WildcardMatch(haystack, needle)
end

local function GetBrowserData()
    if state.browserType == "heirlooms" then
        return GMCC_HEIRLOOM_ITEMS
    end
    return GMCC_MOUNT_SPELLS
end

local function FilterBrowserEntries()
    local results = {}
    local data = GetBrowserData()
    if not data then
        return results
    end

    for _, entry in ipairs(data) do
        if MatchesBrowserEntry(entry) then
            table.insert(results, entry)
        end
    end
    return results
end

local function FormatBrowserRow(entry)
    if state.browserType == "heirlooms" then
        return entry.id .. " - " .. entry.name .. " | " .. entry.slot .. " | " .. entry.subtype .. " | " .. entry.faction .. " | lvl " .. entry.reqLevel
    end

    local classText = ""
    if entry.class and entry.class ~= "" then
        classText = " | " .. entry.class
    end
    return entry.id .. " - " .. entry.name .. " | " .. entry.speed .. " | " .. entry.movement .. " | lvl " .. entry.level .. classText
end

local function ShowBrowserTooltip(owner, entry)
    if not entry then
        return
    end

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if state.browserType == "heirlooms" then
        GameTooltip:SetHyperlink("item:" .. entry.id .. ":0:0:0:0:0:0:0")
    else
        GameTooltip:SetHyperlink("spell:" .. entry.id)
    end
    GameTooltip:Show()
end

local function RefreshMountRows()
    if not state.mountMode then
        return
    end

    local entries = FilterBrowserEntries()
    local total = table.getn(entries)
    local hasBrowserData = GetBrowserData() ~= nil
    local noun = "mount spells"
    if state.browserType == "heirlooms" then
        noun = "heirloom items"
    end
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
            GMCC_MountStatus:SetText("Showing " .. startIndex .. "-" .. endIndex .. " of " .. total .. " " .. noun .. ".")
        elseif not hasBrowserData then
            GMCC_MountStatus:SetText("Offline data did not initialize. Recopy the updated GMCommandCenter addon folder.")
        else
            GMCC_MountStatus:SetText("No " .. noun .. " match this filter.")
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
        local entry = entries[startIndex + i - 1]
        if row and entry then
            row.entry = entry
            row.action:SetText(state.browserType == "heirlooms" and "Add" or "Learn")
            row.label:SetText(FormatBrowserRow(entry))
            row.label:ClearAllPoints()
            if entry.icon and entry.icon ~= "" then
                row.icon:SetTexture("Interface\\Icons\\" .. entry.icon)
                row.icon:Show()
                row.label:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
                row.label:SetWidth(260)
            else
                row.icon:Hide()
                row.label:SetPoint("LEFT", 0, 0)
                row.label:SetWidth(285)
            end
            row:Show()
        elseif row then
            row.entry = nil
            row:Hide()
        end
    end
end

local function ShowMountBrowser()
    state.mountMode = true
    state.browserType = "mounts"
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

local function ShowHeirloomBrowser()
    state.mountMode = true
    state.browserType = "heirlooms"
    state.mountPage = 1
    state.selected = nil
    state.filter = ""
    SetCommandControlsShown(false)
    if GMCC_FilterBox and GMCC_FilterBox:GetText() ~= "" then
        GMCC_FilterBox:SetText("")
    end

    GMCC_TitleText:SetText("Heirloom Items")
    GMCC_MetaText:SetText("WotLKDB Heirloom quality")
    GMCC_SyntaxText:SetText(".additem <itemId> 1")
    GMCC_HelpText:SetText("Heirloom results are embedded offline item data. Use the top search box for item names, IDs, slots like Shoulder or Trinket, armor types like Plate, or faction.")
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
        elseif cat == "Items" then
            local heirloomButton = CreateButton(panel, nil, "Heirloom", 78, 22)
            heirloomButton:SetPoint("LEFT", lastButton, "RIGHT", 4, 0)
            heirloomButton:SetScript("OnClick", function()
                ShowHeirloomBrowser()
            end)
            lastButton = heirloomButton
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
        row:EnableMouse(true)
        if i == 1 then
            row:SetPoint("TOPLEFT", GMCC_MountStatus, "BOTTOMLEFT", 0, -8)
        else
            row:SetPoint("TOPLEFT", state.mountRows[i - 1], "BOTTOMLEFT", 0, -2)
        end

        row.label = CreateLabel(row, nil, "", "small")
        row.label:SetPoint("LEFT", 0, 0)
        row.label:SetWidth(285)

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(20)
        row.icon:SetHeight(20)
        row.icon:SetPoint("LEFT", 0, 0)
        row.icon:Hide()

        row.action = CreateButton(row, nil, "Learn", 62, 22)
        row.action:SetPoint("RIGHT", 0, 0)
        row.action:SetScript("OnClick", function(self)
            local parent = self:GetParent()
            if parent.entry and state.browserType == "heirlooms" then
                RunCommand(".additem " .. parent.entry.id .. " 1")
            elseif parent.entry then
                RunCommand(".learn " .. parent.entry.id)
            end
        end)
        row:SetScript("OnEnter", function(self)
            if self.entry then
                ShowBrowserTooltip(self, self.entry)
            end
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
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






