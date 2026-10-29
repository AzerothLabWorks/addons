local prefix = "COA_LFG_STATUS"
local pollSeconds = 5
local minimumRequestSeconds = 1
local sequence = 0
local session = string.format("%x_%x", math.floor(GetTime() * 1000), math.random(1, 2147483646))
local snapshot
local pending
local contextKey
local nextPoll = 0
local lastRequest = -pollSeconds
local objective
local originalUpdate
local frame = CreateFrame("Frame")

local function Context()
    if not IsPartyLFG() then return end
    local _, instanceType, difficulty = GetInstanceInfo()
    if instanceType ~= "party" or (difficulty ~= 1 and difficulty ~= 2) then return end
    local map = GetActiveMapID()
    local key = tostring(map) .. ":" .. (difficulty - 1)
    if not CoALfgTrackerData.maps[key] then return end
    return key, map, difficulty - 1
end

local function UpdateObjective()
    if objective and objective.updateFunc then objective:updateFunc() end
end

local function ClearContext()
    if snapshot and LFGObjectiveTracker then LFGObjectiveTracker.bossDefeated = false end
    snapshot = nil
    pending = nil
    contextKey = nil
    nextPoll = 0
end

local function EncounterName(encounterID)
    local name = GetEncounterInfo(encounterID)
    if type(name) == "string" and name ~= "" and name ~= UNKNOWNOBJECT then return name end
    return CoALfgTrackerData.encounters[encounterID][6]
end

local function Render(self)
    local key = Context()
    if snapshot and key == snapshot.context and key == contextKey then
        local name = EncounterName(snapshot.encounter)
        self:SetObjective(DEFEAT_S:format(name), snapshot.completed, 1)
    else
        originalUpdate(self)
    end
end

local function Install()
    if objective then return true end
    local tracker = LFGObjectiveTracker
    if not tracker or not tracker.objectives or #tracker.objectives ~= 1 then return false end
    local candidate = tracker.objectives[1]
    if not candidate or type(candidate.updateFunc) ~= "function" then return false end
    objective = candidate
    originalUpdate = candidate.updateFunc
    candidate.updateFunc = Render
    return true
end

local function Request()
    local now = GetTime()
    local key = Context()
    if not key then
        if contextKey then ClearContext(); UpdateObjective() end
        nextPoll = now + pollSeconds
        return
    end
    if key ~= contextKey then
        ClearContext()
        contextKey = key
    end
    if now - lastRequest < minimumRequestSeconds then
        nextPoll = lastRequest + minimumRequestSeconds
        return
    end
    if pending and now < pending.expires then
        nextPoll = pending.expires
        return
    end
    sequence = sequence + 1
    local nonce = session .. "_" .. string.format("%x", sequence)
    if #nonce > 32 then return end
    pending = {nonce = nonce, context = key, expires = now + pollSeconds}
    lastRequest = now
    nextPoll = now + pollSeconds
    SendAddonMessage(prefix, "Q|1|" .. nonce, "WHISPER", UnitName("player"))
end

local function RefreshSoon()
    nextPoll = math.min(nextPoll, GetTime() + minimumRequestSeconds)
end

local function Split(message)
    local fields = {}
    for field in (message .. "|"):gmatch("([^|]*)|") do fields[#fields + 1] = field end
    return fields
end

local function UInt(text)
    if type(text) ~= "string" or not text:match("^%d+$") or #text > 10 then return end
    local value = tonumber(text)
    if value and value <= 4294967295 then return value end
end

local function IsSelf(sender)
    local name, realm = UnitName("player")
    if sender == name then return true end
    realm = realm or GetRealmName()
    return realm and sender == name .. "-" .. realm:gsub("%s", "")
end

local function Receive(messagePrefix, message, channel, sender)
    if messagePrefix ~= prefix or channel ~= "WHISPER" or not IsSelf(sender) then return end
    if type(message) ~= "string" or #message > 240 or not pending then return end
    local fields = Split(message)
    local key, map, difficulty = Context()
    if not key or key ~= contextKey or key ~= pending.context then return end
    if fields[2] ~= "1" or fields[3] ~= pending.nonce or GetTime() > pending.expires then return end
    if fields[1] == "N" and #fields == 3 then
        pending = nil
        if snapshot and LFGObjectiveTracker then LFGObjectiveTracker.bossDefeated = false end
        snapshot = nil
        UpdateObjective()
        return
    end
    if fields[1] ~= "S" or #fields ~= 12 then return end
    local numbers = {}
    for index = 4, 12 do
        if index ~= 7 then
            numbers[index] = UInt(fields[index])
            if not numbers[index] then return end
        end
    end
    local group = fields[7]
    if not group:match("^[1-9]%d*$") or #group > 20
        or (#group == 20 and group > "18446744073709551615") then return end
    if numbers[4] ~= map or numbers[5] ~= difficulty or numbers[6] == 0 then return end
    if numbers[12] > 1 then return end
    local record = CoALfgTrackerData.encounters[numbers[9]]
    if not record or record[1] ~= map or record[2] ~= difficulty or record[3] ~= numbers[8]
        or record[4] ~= numbers[10] or record[5] ~= numbers[11] then return end
    snapshot = {
        context = key,
        instance = numbers[6],
        group = group,
        dungeon = numbers[8],
        encounter = numbers[9],
        completed = numbers[12],
    }
    pending = nil
    UpdateObjective()
end

local contextEvents = {
    PLAYER_ENTERING_WORLD = true,
    CURRENT_LFG_DUNGEON_ID_CHANGED = true,
    PARTY_MEMBERS_CHANGED = true,
}

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        Receive(...)
    elseif contextEvents[event] then
        ClearContext()
        Install()
        UpdateObjective()
        Request()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent = ...
        if subEvent == "UNIT_DIED" then RefreshSoon() end
    else
        Install()
        RefreshSoon()
    end
end)

frame:SetScript("OnUpdate", function()
    Install()
    if GetTime() >= nextPoll then Request() end
end)

for _, event in ipairs({"PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "CURRENT_LFG_DUNGEON_ID_CHANGED",
    "PARTY_MEMBERS_CHANGED", "CHAT_MSG_ADDON", "LFG_COMPLETION_REWARD", "LFG_UPDATE",
    "COMBAT_LOG_EVENT_UNFILTERED"}) do
    frame:RegisterEvent(event)
end

Install()
