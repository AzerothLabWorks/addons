CoAGM = { version = "0.1.0-coa" }

CoAGM.actions = {
    { id = "repair", label = "Repair Me", tab = "quick", help = "Repair your character's equipment. Always names you explicitly." },
    { id = "revive", label = "Revive Me", tab = "quick", help = "Revive your character. This does not remove resurrection sickness." },
    { id = "sickness", label = "Remove Rez Sickness", tab = "quick", help = "Remove only Resurrection Sickness (15007). Clear your target or select yourself first." },
    { id = "save", label = "Save My Character", tab = "quick", help = "Save your character. Clear your target or select yourself first." },
    { id = "bot_tank", label = "Add Tank", tab = "bots", help = "Ask the CoA server to recruit a suitable free tank, invite it and bring it to you. Requires GM permission." },
    { id = "bot_heal", label = "Add Healer", tab = "bots", help = "Ask the CoA server to recruit a suitable free healer, invite it and bring it to you. Requires GM permission." },
    { id = "bot_dps", label = "Add DPS", tab = "bots", help = "Ask the CoA server to recruit one suitable free damage bot. Repeat only when another slot is needed." },
    { id = "follow", label = "Group: Follow", tab = "bots", help = "Send follow to your party. Only controlled bots that accept the command respond." },
    { id = "stay", label = "Group: Stay", tab = "bots", help = "Send stay to your party's controlled bots." },
    { id = "summon", label = "Group: Summon", tab = "bots", help = "Ask your party's controlled bots to come to you. Their normal security and teleport checks still apply." },
    { id = "server_info", label = "Server Information", tab = "diagnostics", help = "Request the server build, population, uptime and update-time statistics." },
    { id = "npc_info", label = "Selected NPC Info", tab = "diagnostics", help = "Read information about the selected NPC. Does not move or modify it." },
    { id = "gps", label = "Position / Target Info", tab = "diagnostics", help = "Report the selected unit's location, or your own location when nothing is selected." },
    { id = "quest_status", label = "Check My Quest", tab = "diagnostics", help = "Enter a quest ID to inspect your status and eligibility. Does not complete or grant the quest." },
}
