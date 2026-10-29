local A = CoAGM
local ADDON = "GMCommandCenter_CoA"
local MAX_ROWS, MAX_LOG, TIMEOUT = 100, 80, 8

local function trim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function uint(value, maximum)
    local text = tostring(value or "")
    if not text:match("^%d+$") or #text > 10 then return end
    local number = tonumber(text)
    if number and number >= 1 and number <= maximum then return number end
end

local function plain(text)
    return tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|H.-|h(.-)|h", "%1")
end

local function validName(name)
    return type(name) == "string" and name ~= "" and not name:find("[%s%c|%[%];]")
end

local function copyRows(rows)
    local copy = {}
    for _, row in ipairs(rows or {}) do
        copy[#copy + 1] = { id = row.id, name = row.name, link = row.link }
    end
    return copy
end

function A:Notify(kind, message, append)
    self.state.statusKind, self.state.status = kind, message
    if append ~= false then
        table.insert(self.state.log, { time = date("%H:%M:%S"), kind = kind, text = plain(message) })
        while #self.state.log > MAX_LOG do table.remove(self.state.log, 1) end
    end
    if self.RefreshUI then self:RefreshUI() end
end

function A:Fail(message)
    self:Notify("failed", message)
    return false, message
end

function A:Initialize()
    local realm, player = GetRealmName() or "", UnitName("player") or ""
    if type(CoAGMCCDB) ~= "table" then CoAGMCCDB = {} end
    CoAGMCCDB.version = 1
    if type(CoAGMCCDB.realms) ~= "table" then CoAGMCCDB.realms = {} end
    local realms = CoAGMCCDB.realms
    if type(realms[realm]) ~= "table" then realms[realm] = {} end
    if type(realms[realm].characters) ~= "table" then realms[realm].characters = {} end
    local characters = realms[realm].characters
    if type(characters[player]) ~= "table" then characters[player] = {} end
    self.db = characters[player]
    if type(self.db.ui) ~= "table" then self.db.ui = {} end
    if type(self.db.favorites) ~= "table" then self.db.favorites = {} end
    for _, kind in ipairs({ "item", "teleport" }) do
        if type(self.db.favorites[kind]) ~= "table" then self.db.favorites[kind] = {} end
    end
    if type(self.db.recentItems) ~= "table" then self.db.recentItems = {} end
    self.state = {
        realm = realm, player = player, target = UnitName("target") or "None",
        enabled = self.db.enabled == true and self.db.approvedRealm == realm and realm ~= "",
        status = "Ready. Confirm this realm and enable commands for this character before using a tool.",
        statusKind = "info", items = {}, teleports = {}, log = {}, busy = false,
    }
    self.pending, self.nextAllowed = nil, 0
    self.initialized = true
end

function A:EnableRealm(enabled, confirmedRealm)
    local realm = GetRealmName() or ""
    if realm ~= self.state.realm or UnitName("player") ~= self.state.player then
        return self:Fail("Character or realm changed. Reload before confirming this character.")
    end
    if enabled and (realm == "" or confirmedRealm ~= realm) then
        return self:Fail("Confirm the current realm before enabling this character. No command was sent.")
    end
    if enabled then self.db.approvedRealm = realm end
    self.db.enabled, self.state.enabled = enabled == true, enabled == true
    if not enabled then
        self.pending, self.state.busy, self.state.queryKind = nil, false, nil
        self.nextAllowed = GetTime() + 1
    end
    self:Notify("info", enabled and "Commands enabled for this character and realm. Server GM permissions still apply."
        or "Commands disabled. No pending action will be retried.")
    return true
end

function A:Guard(mutating, selfTarget)
    if not self.initialized then return self:Fail("The addon is still loading.") end
    if GetRealmName() ~= self.state.realm or UnitName("player") ~= self.state.player then
        return self:Fail("Character or realm changed. Reload the UI before sending commands.")
    end
    if not self.state.enabled or self.db.approvedRealm ~= self.state.realm or self.state.realm == "" then
        return self:Fail("Confirm the realm and enable commands for this character first.")
    end
    if not validName(self.state.player) then return self:Fail("Cannot safely identify your character.") end
    if self.pending or GetTime() < (self.nextAllowed or 0) then
        return self:Fail("Please wait for the current request and its brief cooldown to finish.")
    end
    if mutating and InCombatLockdown and InCombatLockdown() then
        return self:Fail("Wait until combat ends before using this convenience action.")
    end
    if selfTarget and UnitExists("target") and not UnitIsUnit("target", "player") then
        return self:Fail("Clear your target or select yourself first. No command was sent.")
    end
    return true
end

function A:Send(command, channel, kind, extra)
    local pending = extra or {}
    pending.command, pending.kind = command, kind
    pending.started, pending.expires = GetTime(), GetTime() + TIMEOUT
    pending.seen = {}
    self.pending = pending
    self.state.busy, self.state.queryKind = true, kind
    local ok, err = pcall(SendChatMessage, command, channel or "SAY")
    if not ok then
        self.pending, self.state.busy, self.state.queryKind = nil, false, nil
        return self:Fail("Client could not send command: " .. tostring(err))
    end
    self:Notify("sent", "Sent: " .. command .. " (awaiting evidence; not yet confirmed)")
    return true
end

function A:Finish(kind, text)
    self.pending, self.state.busy, self.state.queryKind = nil, false, nil
    self.nextAllowed = GetTime() + 1
    self:Notify(kind, text)
end

local function searchTerm(text)
    text = trim(text)
    if #text < 2 or #text > 80 or text:find("[%c|;]") or text:match("^[./]") then return end
    return text
end

function A:SearchItems(text)
    local term = searchTerm(text)
    if not term then return self:Fail("Use 2-80 characters for a name search; no commands, links or control characters.") end
    if not self:Guard(false) then return false end
    self.state.items = {}
    return self:Send(".lookup item " .. term, "SAY", "item", { term = term })
end

function A:SearchTravel(text)
    local term = searchTerm(text)
    if not term then return self:Fail("Use 2-80 characters of a destination name, without commands or links.") end
    if not self:Guard(false) then return false end
    self.state.teleports = {}
    return self:Send(".lookup teleport " .. term, "SAY", "teleport_search", { term = term })
end

function A:FindRecord(kind, id)
    local live = kind == "item" and self.state.items or self.state.teleports
    for _, rows in ipairs({ live, self.db.favorites[kind] or {}, kind == "item" and self.db.recentItems or {} }) do
        for _, row in ipairs(rows) do
            if tonumber(row.id) == id then return row end
        end
    end
end

function A:GiveItem(itemId, quantity)
    local id, count = uint(itemId, 2147483647), uint(quantity, 200)
    if not id or not count then return self:Fail("Item ID must be a positive integer; quantity must be 1-200. Nothing was sent.") end
    if not self:Guard(true) then return false end
    local row = self:FindRecord("item", id)
    local name = row and row.name or (GetItemInfo and GetItemInfo(id)) or ("Item #" .. id)
    local recent = self.db.recentItems
    for index = #recent, 1, -1 do
        if tonumber(recent[index].id) == id then table.remove(recent, index) end
    end
    table.insert(recent, 1, { id = id, name = name, link = row and row.link })
    while #recent > 20 do table.remove(recent) end
    return self:Send(".additem " .. self.state.player .. " " .. id .. " " .. count, "SAY", "give", { id = id, count = count })
end

function A:Teleport(destinationId)
    local id = uint(destinationId, 2147483647)
    if not id then return self:Fail("Choose a valid destination from search results or favourites.") end
    if not self:Guard(true) then return false end
    local row = self:FindRecord("teleport", id)
    if not row or type(row.link) ~= "string" then
        return self:Fail("Search for the destination first. A number alone is not a CoA teleport ID.")
    end
    local linkId = row.link:match("^|c%x%x%x%x%x%x%x%x|Htele:(%d+)|h%[[^|%c%[%]]+%]|h|r$")
    if tonumber(linkId) ~= id then return self:Fail("Destination link is invalid. Search for it again.") end
    return self:Send(".teleport " .. row.link, "SAY", "travel", { id = id })
end

function A:Execute(actionId, args)
    args = args or {}
    local readOnly = actionId == "server_info" or actionId == "npc_info" or actionId == "gps" or actionId == "quest_status"
    local selfTarget = actionId == "sickness" or actionId == "save"
    if not self:Guard(not readOnly, selfTarget) then return false end
    local name = self.state.player
    local commands = {
        repair = ".gear repair " .. name, revive = ".revive " .. name,
        sickness = ".unaura 15007", save = ".save", server_info = ".server info",
        npc_info = ".npc info", gps = ".gps",
        bot_tank = ".playerbots coa tank", bot_heal = ".playerbots coa heal", bot_dps = ".playerbots coa dps",
        follow = "follow", stay = "stay", summon = "summon",
    }
    if actionId == "quest_status" then
        local id = uint(args.questId, 2147483647)
        if not id then return self:Fail("Enter a positive numeric quest ID.") end
        return self:Send(".quest status " .. id .. " " .. name, "SAY", actionId, { id = id })
    end
    local command = commands[actionId]
    if not command then return self:Fail("Unknown action. Arbitrary commands are not accepted.") end
    if actionId == "npc_info" and (not UnitExists("target") or UnitIsPlayer("target")) then
        return self:Fail("Select an NPC first. No command was sent.")
    end
    if actionId:match("^bot_") then
        if GetNumRaidMembers() > 0 or GetNumPartyMembers() >= 4 then
            return self:Fail("Recruitment requires a free slot in a normal five-person party.")
        end
    end
    local party = actionId == "follow" or actionId == "stay" or actionId == "summon"
    if party and (GetNumPartyMembers() < 1 or GetNumRaidMembers() > 0) then
        return self:Fail("Join a normal party with your bots first. Raid-wide commands are not sent.")
    end
    return self:Send(command, party and "PARTY" or "SAY", actionId)
end

function A:GetFavorites(kind)
    return copyRows(self.db and self.db.favorites[kind])
end

function A:GetRecentItems()
    return copyRows(self.db and self.db.recentItems)
end

function A:ToggleFavorite(kind, id, name)
    if kind ~= "item" and kind ~= "teleport" then return self:Fail("Unknown favourite type.") end
    id = uint(id, 2147483647)
    if not id then return self:Fail("Choose an item or destination first.") end
    local favorites = self.db.favorites[kind]
    for index, row in ipairs(favorites) do
        if tonumber(row.id) == id then
            table.remove(favorites, index)
            self:Notify("info", "Favourite removed.")
            return true
        end
    end
    if #favorites >= 50 then return self:Fail("Favourites are limited to 50 per category.") end
    local row = self:FindRecord(kind, id)
    if kind == "teleport" and not row then return self:Fail("Search for this destination first.") end
    local displayName = row and row.name or trim(name)
    if displayName == "" then displayName = "Item #" .. id end
    table.insert(favorites, { id = id, name = displayName, link = row and row.link })
    self:Notify("info", "Favourite saved for this character on this realm.")
    return true
end

local failures = {
    "No free bot able to play", "Player not found!", "Invalid item id",
    "Cannot create item", "Cannot do that while fighting", "You cannot teleport",
    "You have low security level", "### USAGE:", "Syntax:",
    "You do not have permission", "You don't have permission",
}

local function isFailure(clean)
    for _, prefix in ipairs(failures) do
        if clean:sub(1, #prefix):lower() == prefix:lower() then return true end
    end
    return clean:match("^Item ID %d+ does not exist")
        or clean:match("^Command '.-' does not exist")
        or clean:match("^Character '.-' does not exist")
        or clean:match("^Teleport location .- does not exist")
        or clean:match("^'.-' is not a valid character name")
end

function A:OnSystemMessage(message)
    local p = self.pending
    if not p or type(message) ~= "string" then return end
    if GetTime() >= p.expires then self:Tick(); return end
    local clean = plain(message)
    if p.kind == "item" or p.kind == "teleport_search" then
        local kind = p.kind == "item" and "item" or "tele"
        local rows = p.kind == "item" and self.state.items or self.state.teleports
        local link, rawId, name = message:match("(|c%x%x%x%x%x%x%x%x|H" .. kind .. ":(%d+)[^|]*|h%[([^|]+)%]|h|r)")
        local id = uint(rawId, 2147483647)
        if id and link then
            if not p.seen[id] and #rows < MAX_ROWS then
                p.seen[id] = true
                table.insert(rows, { id = id, name = name, link = link })
            elseif #rows >= MAX_ROWS then p.limited = true end
            p.lastResult = GetTime()
            self:Notify("sent", "Receiving " .. #rows .. " search result(s)...", false)
        elseif clean:find("Result limit reached", 1, true) then
            p.limited, p.lastResult = true, GetTime()
        elseif clean == "No items found!" or clean == "There are no teleport locations matching your request." then
            self:Finish("confirmed", "Search completed: no matches. Try a different name fragment.")
        elseif isFailure(clean) then
            self:Finish("failed", clean)
        end
        return
    end
    if isFailure(clean) then
        self:Finish("failed", clean .. (p.kind == "give" and " Check your bags: a partial grant may have occurred; no retry was sent." or ""))
        return
    end
    self:Notify("sent", "Server: " .. clean)
    local repairedPlayer = clean:match("^You repair all (.-)'s items%.$")
    if repairedPlayer then repairedPlayer = repairedPlayer:gsub("^%[", ""):gsub("%]$", "") end
    if p.kind == "repair" and repairedPlayer == self.state.player then
        self:Finish("confirmed", "Server confirmed your equipment repair.")
    elseif p.kind == "save" and clean == "Player saved." then
        self:Finish("confirmed", "Server confirmed the character save.")
    elseif p.kind == "quest_status" then
        if tonumber(clean:match("^Quest: .-%((%d+)%)")) == p.id then p.questMatched = true end
        if p.questMatched and clean:match("^Status:") then
            p.hasEvidence, p.lastResult = true, GetTime()
        elseif p.questMatched then p.lastResult = GetTime() end
    elseif p.kind == "server_info" and clean:match("^Connected players:") then
        p.hasEvidence, p.lastResult = true, GetTime()
    elseif p.hasEvidence then p.lastResult = GetTime() end
end

function A:Tick()
    local p = self.pending
    if not p then return end
    local now = GetTime()
    if (p.kind == "item" or p.kind == "teleport_search") and p.lastResult and now - p.lastResult >= 1 then
        local rows = p.kind == "item" and self.state.items or self.state.teleports
        self:Finish("confirmed", "Received " .. #rows .. " search result(s)."
            .. (p.limited and " Results limited; refine your search." or ""))
    elseif p.hasEvidence and p.lastResult and now - p.lastResult >= 1 then
        self:Finish("confirmed", "Server response received. See the report for details.")
    elseif now >= p.expires then
        self:Finish("unknown", "Sent; no conclusive confirmation received. Check chat, bags or the game state. Nothing was retried.")
    end
end

function A:ClearLog()
    self.state.log = {}
    self:Notify("info", "Session report cleared.")
end

function A:BuildReport()
    local zone = GetRealZoneText and GetRealZoneText() or "Unknown"
    local subzone = GetSubZoneText and GetSubZoneText() or ""
    local instanceName, instanceType, difficulty = GetInstanceInfo()
    local lines = {
        "GM Command Center - CoA " .. self.version,
        "Captured: " .. date("%Y-%m-%d %H:%M:%S"),
        "Realm: " .. self.state.realm, "Character: " .. self.state.player .. " (level " .. tostring(UnitLevel("player")) .. ")",
        "Zone: " .. tostring(zone) .. " / " .. tostring(subzone),
        "Instance: " .. tostring(instanceName) .. " / " .. tostring(instanceType) .. " / difficulty " .. tostring(difficulty),
        "Selected target: " .. tostring(UnitName("target") or "None"),
        "Target GUID: " .. tostring(UnitGUID and UnitGUID("target") or "None"),
        "Commands below are observations, not proof every requested action succeeded.", "",
    }
    for _, entry in ipairs(self.state.log) do
        lines[#lines + 1] = entry.time .. " [" .. entry.kind .. "] " .. entry.text
    end
    return table.concat(lines, "\n")
end

function A:OpenUnBot()
    if SlashCmdList and SlashCmdList.UNBOT then
        SlashCmdList.UNBOT("")
        return true
    end
    return self:Fail("UnBot is not loaded. Enable UnBot CoA on the character selection AddOns screen.")
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        A:Initialize()
        if A.BuildUI then A:BuildUI() end
        DEFAULT_CHAT_FRAME:AddMessage("|cff58d6c7CoA GM tools loaded.|r Open with /coagm or /cgm. Commands start disabled for new characters.")
    elseif not A.initialized then return
    elseif event == "CHAT_MSG_SYSTEM" then A:OnSystemMessage(...)
    elseif event == "PLAYER_ENTERING_WORLD" then
        if A.pending then A:Finish("unknown", "World changed. Check the result in game; no command was repeated.") end
        A.state.target = UnitName("target") or "None"
        if A.RefreshUI then A:RefreshUI() end
    elseif event == "PLAYER_TARGET_CHANGED" then
        A.state.target = UnitName("target") or "None"
        if A.RefreshUI then A:RefreshUI() end
    end
end)
local elapsed = 0
eventFrame:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.2 then
        elapsed = 0
        if A.initialized then A:Tick() end
    end
end)
SLASH_COAGMCOMMANDCENTER1 = "/coagm"
SLASH_COAGMCOMMANDCENTER2 = "/cgm"
SlashCmdList.COAGMCOMMANDCENTER = function()
    if A.initialized and A.Toggle then A:Toggle() end
end
