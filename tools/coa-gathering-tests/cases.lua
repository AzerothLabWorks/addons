local addon = assert(arg[1])
local checks = 0
local function check(value, message)
    checks = checks + 1
    assert(value, message)
end
local function near(value, expected, message)
    check(value and math.abs(value - expected) < 0.001, message)
end
dofile(addon .. "/Core.lua")
local Core = CoAGatheringAlertsCore

local function pending()
    return {nonce = "token", expires = 10}
end
local p = pending()
check(not Core.Receive(p, "N|1|token|f110000100000001|M|5|6|7", 1, 0), "node without start")
check(not Core.Receive(p, "S|1|wrong|0|0|1", 1, 0) and not p.started, "wrong nonce")
check(not Core.Receive(p, "S|2|token|0|0|1", 1, 0) and not p.started, "wrong version")
check(not Core.Receive(p, "S|1|token|0|0|13", 1, 0) and not p.started, "oversized snapshot")
check(not Core.Receive(p, "S|1|token|1|0|1", 1, 0) and not p.started, "wrong map")
check(not Core.Receive(p, "S|1|token|0|0|1", 11, 0) and not p.started, "expired nonce")
Core.Receive(p, "S|1|token|0|0|2", 1, 0)
Core.Receive(p, "N|1|token|f110000100000001|M|5|6|7", 1, 0)
Core.Receive(p, "N|1|token|f110000100000001|M|5|6|7", 1, 0)
check(#p.nodes == 1, "duplicate nodes rejected")
check(not Core.Receive(p, "E|1|token", 1, 0), "partial snapshot withheld")
for _, bad in ipairs({"nan", "inf", "1e99", "100001", "-100001", "1|2", "--2"}) do
    Core.Receive(p, "N|1|token|f110000100000002|H|" .. bad .. "|6|7", 1, 0)
end
check(#p.nodes == 1, "malformed coordinates rejected")
Core.Receive(p, "N|1|token|0000000000000000|H|5|6|7", 1, 0)
Core.Receive(p, "N|1|token|f110000100000002|B|5|6|7", 1, 0)
check(#p.nodes == 1, "invalid GUID and kind rejected")
Core.Receive(p, "N|1|token|f110000100000002|H|-5.25|6.20|7.00", 1, 0)
local result = Core.Receive(p, "E|1|token", 1, 0)
check(result and #result.nodes == 2 and result.nodes[2].x == -5.25, "atomic complete snapshot accepted")
local zero = pending()
Core.Receive(zero, "S|1|token|0|0|0", 1, 0)
check(#Core.Receive(zero, "E|1|token", 1, 0).nodes == 0, "empty snapshot accepted")

local x, y = Core.Project({x = 110, y = 200}, 100, 200, 100, 200, 200)
near(x, 0, "north aligned x")
near(y, 10, "north aligned y")
x, y = Core.Project({x = 100, y = 190}, 100, 200, 100, 200, 200)
near(x, 10, "east aligned x")
near(y, 0, "east aligned y")
x, y = Core.Project({x = 100, y = 190}, 100, 200, 50, 200, 200)
near(x, 20, "zoom changes scale")
x, y = Core.Project({x = 110, y = 200}, 100, 200, 100, 200, 200, math.pi / 2)
near(x, 10, "west-facing north appears right")
near(y, 0, "west-facing north horizontal")
check(not Core.Project({x = 200, y = 200}, 100, 200, 100, 200, 200), "off-map not clamped into false location")
check(not Core.Project({x = 110, y = 200}, nil, 200, 100, 200, 200), "missing player position")

local memory = {}
local observation = {map = 0, instance = 0, nodes = {{guid = "f110000100000001"}}}
Core.Observe(memory, observation, 1)
local seen = memory[observation.nodes[1].key]
seen.alerted, seen.lastAlert = true, 1
Core.Observe(memory, observation, 31)
check(seen.alerted, "boundary bounce does not rearm")
Core.Observe(memory, observation, 61)
check(seen.alerted, "continuously nearby node does not repeat")
Core.Observe(memory, observation, 122)
check(not seen.alerted, "full absence rearms")
for i = 1, 300 do memory[tostring(i)] = {lastSeen = i, alerted = true} end
Core.Observe(memory, {map = 0, instance = 0, nodes = {}}, 301)
local count = 0
for _ in pairs(memory) do count = count + 1 end
check(count <= 256, "memory bounded")
Core.Observe(memory, {map = 0, instance = 0, nodes = {}}, 1000)
check(next(memory) == nil, "old observations expire")

local now, map, dead = 0, 0, false
local playerX, playerY = 1000, 1000
local radius, facing, rotation = 100, 0, "0"
local minerals, herbs = true, false
local sends, sounds, frames = {}, {}, {}
local methods = {}
function methods:SetScript(kind, callback) self[kind] = callback end
function methods:RegisterEvent() end
function methods:SetWidth(value) self.width = value end
function methods:SetHeight(value) self.height = value end
function methods:GetWidth() return self.width or 200 end
function methods:GetHeight() return self.height or 200 end
function methods:SetFrameLevel() end
function methods:GetFrameLevel() return 1 end
function methods:EnableMouse(value) check(not value, "overlay must not intercept clicks") end
function methods:SetTexture(value) self.texture = value end
function methods:SetPoint(_, _, _, px, py) self.x, self.y = px, py end
function methods:ClearAllPoints() end
function methods:SetAlpha(value) self.alpha = value end
function methods:SetRotation(value) self.rotation = value end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsVisible() return self.shown ~= false end
function methods:CreateTexture() return setmetatable({}, {__index = methods}) end
function CreateFrame()
    local value = setmetatable({}, {__index = methods})
    frames[#frames + 1] = value
    return value
end
Minimap = setmetatable({}, {__index = methods})
function Minimap:GetViewRadius() return radius end
function Minimap:PingLocation() error("must not broadcast a group ping") end
function GetTime() return now end
function GetCurrentPlayerPosition() return playerX, playerY end
function GetActiveMapID() return map end
function GetPlayerFacing() return facing end
function GetCVar() return rotation end
function GetSpellInfo(id) return id == 2580 and "Find Minerals" or "Find Herbs" end
function GetNumTrackingTypes() return 2 end
function GetTrackingInfo(index)
    return index == 1 and "Find Minerals" or "Find Herbs", "icon", (index == 1 and minerals) or (index == 2 and herbs)
end
function UnitName() return "Tester" end
function GetRealmName() return "G1 Candidate" end
function UnitIsDeadOrGhost() return dead end
function RegisterAddonMessagePrefix() end
function SendAddonMessage(prefix, message, channel, target)
    check(prefix == "COAGATHER" and channel == "WHISPER" and target == "Tester", "only private self requests")
    sends[#sends + 1] = message
end
function PlaySound(sound) sounds[#sounds + 1] = sound end
DEFAULT_CHAT_FRAME = {AddMessage = function() end}
SlashCmdList = {}
dofile(addon .. "/CoAGatheringAlerts.lua")
local events = frames[1]
local function event(name, ...) events.OnEvent(events, name, ...) end
local function tick(time) now = time; events.OnUpdate(events, 0.05) end
local function deliver(nodes, sender, channel, packetMap)
    local token = Core.Fields(sends[#sends])[3]
    local function receive(text)
        event("CHAT_MSG_ADDON", "COAGATHER", text, channel or "WHISPER", sender or "Tester")
    end
    receive("S|1|" .. token .. "|" .. (packetMap or map) .. "|0|" .. #nodes)
    for _, node in ipairs(nodes) do receive("N|1|" .. token .. "|" .. node) end
    receive("E|1|" .. token)
end
local mine = "f110000100000001|M|1000.00|980.00|50.00"
local herb = "f110000100000002|H|1010.00|1000.00|50.00"
event("ADDON_LOADED", "CoAGatheringAlerts")
event("PLAYER_ENTERING_WORLD")
tick(0)
check(#sends == 1 and sends[1]:match("|100$"), "poll includes actual minimap radius")
deliver({mine}, "OtherPlayer")
tick(0.1)
check(#sounds == 0, "other player cannot inject nodes")
deliver({mine}, nil, "PARTY")
tick(0.2)
check(#sounds == 0, "non-whisper cannot inject nodes")
deliver({mine, herb})
tick(0.3)
check(#sounds == 1 and sounds[1] == "MapPing", "native ping sound once for new visible mineral")
check(#frames == 2 and frames[2].shown, "only tracked mineral gets a local pulse")
near(frames[2].x, 20, "world position projects east")
playerY = 990
tick(0.4)
near(frames[2].x, 10, "pulse follows player movement")
rotation, facing = "1", math.pi / 2
tick(0.5)
near(frames[2].x, 0, "rotation x updated")
near(frames[2].y, -10, "east node moves below west-facing player")
rotation = "0"
tick(1)
deliver({})
tick(1.1)
check(not frames[2].shown, "despawn clears pulse immediately")
tick(2)
deliver({mine})
tick(2.1)
check(#sounds == 1, "brief absence does not reping")
tick(4.7)
check(not frames[2].shown, "stale snapshot cannot remain visible")
minerals = false
event("MINIMAP_UPDATE_TRACKING")
local before = #sends
tick(5)
check(#sends == before, "no polling without resource tracking")
minerals = true
event("MINIMAP_UPDATE_TRACKING")
tick(6)
dead = true
deliver({mine})
tick(6.1)
check(#sounds == 1, "no alerts while dead")
dead = false
event("PLAYER_ALIVE")
tick(7)
map = 1
event("PLAYER_ENTERING_WORLD")
deliver({mine}, nil, nil, 0)
tick(7.1)
check(#sounds == 1, "old-map response discarded")
tick(8)
deliver({mine}, nil, nil, 1)
tick(8.1)
check(#sounds == 1, "global sound cooldown respected across map changes")
tick(8.4)
check(#sounds == 2, "new context alerts after cooldown")
SlashCmdList.COAGATHERINGALERTS("off")
before = #sends
tick(10)
check(#sends == before and not frames[2].shown, "disable clears and stops requests")
SlashCmdList.COAGATHERINGALERTS("on")
SlashCmdList.COAGATHERINGALERTS("sound")
tick(11)
deliver({"f110000100000003|M|1010.00|990.00|50.00"})
tick(16.5)
deliver({"f110000100000003|M|1010.00|990.00|50.00"})
tick(16.6)
check(#sounds == 2 and frames[2].shown, "sound toggle preserves visual pulse")
Minimap:Hide()
tick(17.7)
check(not frames[2].shown, "hidden minimap clears visuals")
Minimap:Show()
event("PLAYER_LEAVING_WORLD")
before = #sends
tick(20)
check(#sends == before, "no scanning during world transfer")
check(CoAGatheringAlertsDB.enabled and not CoAGatheringAlertsDB.sound, "preferences persist per character")
print("Gathering addon Lua 5.1 checks passed: " .. checks)
