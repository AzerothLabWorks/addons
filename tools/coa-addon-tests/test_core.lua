-- Lua 5.1 regression tests. All WoW APIs are mocked: no game/server interaction.
-- Usage: lua tools/coa-addon-tests/test_core.lua [path/to/GMCommandCenter_CoA]
local addonPath = (arg and arg[1]) or "GMCommandCenter_CoA"
local passed, failed = 0, 0

local function check(value, message)
    if not value then error(message or "assertion failed", 2) end
end

local function equal(actual, expected, message)
    check(actual == expected, (message or "values differ") .. ": expected " .. tostring(expected)
        .. ", got " .. tostring(actual))
end

local function test(name, callback)
    local ok, message = pcall(callback)
    if ok then
        passed = passed + 1
        print("PASS " .. name)
    else
        failed = failed + 1
        print("FAIL " .. name .. ": " .. tostring(message))
    end
end

local function newClient(options)
    options = options or {}
    local client = {
        realm = options.realm or "COA G1 CANDIDATE", player = options.player or "Thada",
        target = options.target, now = 100, dead = false, sickness = false,
        counts = {}, sent = {}, frames = {}, messages = {}, retargets = 0,
    }
    local env = setmetatable({}, {__index = _G})
    env._G = env
    env.CoAGM = nil
    env.CoAGMCCDB = options.saved
    env.SlashCmdList = {}
    env.DEFAULT_CHAT_FRAME = {AddMessage = function(_, value) table.insert(client.messages, value) end}
    env.UIErrorsFrame = {AddMessage = function(_, value) table.insert(client.messages, value) end}
    env.GetRealmName = function() return client.realm end
    env.UnitName = function(unit)
        if unit == "player" then return client.player end
        if unit == "target" then return client.target end
    end
    env.UnitExists = function(unit) return unit == "player" or unit == "target" and client.target ~= nil end
    env.UnitIsPlayer = function(unit) return env.UnitExists(unit) end
    env.UnitIsUnit = function(a, b) return env.UnitName(a) ~= nil and env.UnitName(a) == env.UnitName(b) end
    env.UnitGUID = function(unit)
        if not env.UnitExists(unit) then return nil end
        return env.UnitIsUnit(unit, "player") and "0x0000000000000001" or "0x0000000000000002"
    end
    env.UnitLevel = function() return 64 end
    env.UnitClass = function() return "Sun Cleric", "SUNCLERIC" end
    env.UnitIsDeadOrGhost = function() return client.dead end
    env.UnitIsDead = function() return client.dead end
    env.UnitAffectingCombat = function() return client.combat or false end
    env.InCombatLockdown = function() return client.combat or false end
    env.IsMounted = function() return false end
    env.IsLoggedIn = function() return true end
    env.GetTime = function() return client.now end
    env.time = function() return math.floor(client.now) end
    env.date = function() return "2026-10-24" end
    env.GetLocale = function() return "enUS" end
    env.GetBuildInfo = function() return "3.3.5", "12340", "Jun 24 2010", 30300 end
    env.GetNumRaidMembers = function() return client.raid or 0 end
    env.GetNumPartyMembers = function() return client.party or 0 end
    env.GetInstanceInfo = function() return "Mock Zone", "none", 0 end
    env.GetItemCount = function(id) return client.counts[tonumber(id)] or 0 end
    env.GetSpellInfo = function(id)
        return tonumber(id) == 15007 and "Resurrection Sickness" or "Mock Spell " .. tostring(id)
    end
    local function aura(_, index)
        if client.sickness and index == 1 then
            return "Resurrection Sickness", "", "mock", 1, nil, 600, client.now + 600,
                "player", false, false, 15007
        end
    end
    env.UnitBuff, env.UnitDebuff, env.UnitAura = aura, aura, aura
    env.GetItemInfo = function(id)
        return "Mock Item " .. tostring(id), "|Hitem:" .. tostring(id) .. ":0:0:0:0:0:0:0|h[Mock Item]|h"
    end
    env.IsAddOnLoaded = function() return false end
    env.LoadAddOn = function() return nil, "MISSING" end
    env.GetAddOnInfo = function() return nil end
    env.SendChatMessage = function(text, channel, language, target)
        check(type(text) == "string", "chat command must be a string")
        table.insert(client.sent, {text = text, channel = channel, language = language, target = target})
    end
    env.ClearTarget = function() client.retargets = client.retargets + 1; error("Core must not clear a target") end
    env.TargetUnit = function() client.retargets = client.retargets + 1; error("Core must not change a target") end
    env.CreateFrame = function(kind, name, parent)
        local frame = {kind = kind, name = name, parent = parent, scripts = {}, events = {},
            shown = true, enabled = true, text = "", points = {}, children = {}}
        function frame:SetScript(event, callback) self.scripts[event] = callback end
        function frame:GetScript(event) return self.scripts[event] end
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterEvent(event) self.events[event] = nil end
        function frame:UnregisterAllEvents() self.events = {} end
        function frame:Hide()
            local wasShown = self.shown
            self.shown = false
            if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
        end
        function frame:Show()
            local wasShown = self.shown
            self.shown = true
            if not wasShown and self.scripts.OnShow then self.scripts.OnShow(self) end
        end
        function frame:IsShown() return self.shown or false end
        function frame:SetShown(value) self.shown = value end
        function frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
        function frame:GetParent() return self.parent end
        function frame:SetSize(w, h) self.width, self.height = w, h end
        function frame:SetWidth(value) self.width = value end
        function frame:SetHeight(value) self.height = value end
        function frame:SetText(value) self.text = tostring(value or "") end
        function frame:GetText() return self.text end
        function frame:SetPoint(...) self.points[#self.points + 1] = {...} end
        function frame:ClearAllPoints() self.points = {} end
        function frame:GetCenter() return self.centerX or 960, self.centerY or 540 end
        function frame:Enable() self.enabled = true end
        function frame:Disable() self.enabled = false end
        function frame:IsEnabled() return self.enabled end
        function frame:SetChecked(value) self.checked = value end
        function frame:GetChecked() return self.checked end
        function frame:SetFocus() self.focused = true end
        function frame:ClearFocus() self.focused = false end
        function frame:SetScrollChild(value) self.scrollChild = value end
        function frame:SetVerticalScroll(value) self.verticalScroll = value end
        function frame:LockHighlight() self.highlightLocked = true end
        function frame:UnlockHighlight() self.highlightLocked = false end
        function frame:StartMoving() self.moving = true end
        function frame:StopMovingOrSizing() self.moving = false end
        -- Explicit known 3.3.5 widget methods only. An unknown API remains nil and fails the test.
        for _, method in ipairs({"SetJustifyH", "SetFontObject", "SetAutoFocus", "SetNumeric",
            "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetMaxLetters",
            "SetTextColor", "SetAllPoints", "SetTexture", "EnableMouse", "SetFrameStrata",
            "SetMultiLine", "SetTextInsets", "HighlightText", "SetMovable", "SetClampedToScreen",
            "RegisterForClicks", "RegisterForDrag", "SetOwner", "AddLine", "SetHyperlink"}) do
            frame[method] = function() end
        end
        function frame:CreateFontString(name) return env.CreateFrame("FontString", name, self) end
        function frame:CreateTexture(name) return env.CreateFrame("Texture", name, self) end
        table.insert(client.frames, frame)
        if parent then parent.children[#parent.children + 1] = frame end
        if name then env[name] = frame end
        return frame
    end
    env.UIParent = env.CreateFrame("Frame", "UIParent")
    env.GameTooltip = env.CreateFrame("GameTooltip", "GameTooltip")
    env.ChatFontNormal = {}
    env.UISpecialFrames = {}
    env.StaticPopupDialogs = {}
    env.StaticPopup_Show = function(id, realm, player, data)
        client.popup = {dialog = env.StaticPopupDialogs[id], data = data}
    end
    local function loadAddon(filename)
        local chunk, message = loadfile(addonPath .. "/" .. filename)
        check(chunk, message)
        setfenv(chunk, env)
        chunk("GMCommandCenter_CoA")
    end
    loadAddon("Data.lua")
    loadAddon("Core.lua")
    if options.ui then loadAddon("UI.lua") end
    check(type(env.CoAGM) == "table", "CoAGM namespace missing")
    client.env, client.core = env, env.CoAGM
    client.core:Initialize()
    if options.ui then client.core:BuildUI() end
    function client:tick(seconds)
        self.now = self.now + seconds
        self.core:Tick(seconds)
    end
    function client:message(text) self.core:OnSystemMessage(text) end
    function client:enable() self.core:EnableRealm(true, self.realm) end
    function client:find(text, parent)
        for _, frame in ipairs(self.frames) do
            if frame.text == text and (not parent or frame.parent == parent) then return frame end
        end
        error("Mock widget not found: " .. text)
    end
    function client:click(frame, button)
        check(frame:IsVisible(), "cannot click a hidden widget")
        check(frame.enabled, "cannot click a disabled widget")
        check(frame.scripts.OnClick, "widget has no OnClick handler")
        frame.scripts.OnClick(frame, button or "LeftButton")
    end
    function client:fire(event, ...)
        for _, frame in ipairs(self.frames) do
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
        end
    end
    return client
end

local function noCommand(client, callback)
    local count = #client.sent
    callback()
    equal(#client.sent, count, "operation must not send a command")
end

local function notConfirmed(client)
    check(client.core.state.statusKind ~= "success" and client.core.state.statusKind ~= "confirmed",
        "sending a command must not falsely confirm success")
end

local function firstText(client) return client.sent[1] and client.sent[1].text end

test("initialization/events never grant items or execute gameplay commands", function()
    local c = newClient()
    equal(#c.sent, 0)
    c:fire("PLAYER_LOGIN")
    c:fire("PLAYER_ENTERING_WORLD")
    c:fire("BAG_UPDATE", 0)
    c:fire("UNIT_AURA", "player")
    c:fire("PLAYER_TARGET_CHANGED")
    c:tick(90)
    equal(#c.sent, 0)
end)

test("realm starts disabled and explicit opt-in is required", function()
    local c = newClient()
    check(not c.core.state.enabled)
    noCommand(c, function() c.core:GiveItem(2672, 5) end)
    noCommand(c, function() c.core:SearchItems("meat") end)
    c:enable()
    check(c.core.state.enabled)
    c.core:GiveItem(2672, 5)
    equal(#c.sent, 1)
    notConfirmed(c)
end)

test("item grant with no target is a validated self-directed command", function()
    local c = newClient()
    c:enable()
    c.core:GiveItem(2672, 5)
    equal(#c.sent, 1)
    check(firstText(c):match("2672") and firstText(c):match("5"), "validated item/count missing")
    check(not firstText(c):find("[\r\n;]"), "command injection delimiter")
    equal(c.retargets, 0)
    notConfirmed(c)
end)

test("selected bot cannot redirect an explicitly named item recipient", function()
    local c = newClient({target = "Pablo"})
    c:enable()
    c.core:GiveItem(2672, 5)
    equal(#c.sent, 1)
    equal(firstText(c), ".additem Thada 2672 5")
    equal(c.retargets, 0)
end)

test("selected bot blocks implicit-target self commands", function()
    local c = newClient({target = "Pablo"})
    c:enable()
    noCommand(c, function() c.core:Execute("save", {}); c.core:Execute("sickness", {}) end)
    equal(c.retargets, 0)
end)

test("selected self remains a permitted item recipient", function()
    local c = newClient({target = "Thada"})
    c:enable()
    c.core:GiveItem(2672, 1)
    equal(#c.sent, 1)
    equal(c.retargets, 0)
end)

test("invalid item IDs and counts never produce commands", function()
    for _, value in ipairs({0, -1, 1.5, "abc", "2672\n.revive", "1; .save", 1e30}) do
        local c = newClient()
        c:enable()
        noCommand(c, function() c.core:GiveItem(value, 1) end)
        noCommand(c, function() c.core:GiveItem(2672, value) end)
    end
    local c = newClient()
    c:enable()
    noCommand(c, function() c.core:GiveItem(nil, 1) end)
end)

test("disabling the realm blocks actions and cancels outstanding searches", function()
    local c = newClient()
    c:enable()
    c.core:SearchItems("meat")
    c.core:EnableRealm(false)
    check(not c.core.state.enabled)
    noCommand(c, function() c.core:GiveItem(2672, 5); c.core:Execute("repair", {}) end)
    c:message("2672 - |cffffffff|Hitem:2672:0:0:0:0:0:0:0|h[Stringy Wolf Meat]|h|r")
    check(not c.core.state.busy)
end)

test("item search results require a matching outstanding request", function()
    local c = newClient()
    c:enable()
    local line = "2672 - |cffffffff|Hitem:2672:0:0:0:0:0:0:0|h[Stringy Wolf Meat]|h|r"
    c:message(line)
    equal(#c.core.state.items, 0)
    c.core:SearchItems("wolf")
    equal(#c.sent, 1)
    c:message(line)
    equal(#c.core.state.items, 1)
    equal(tonumber(c.core.state.items[1].id), 2672)
    c:message(line)
    equal(#c.core.state.items, 1, "duplicate results must be deduplicated")
    c:message("bad - |Hitem:notanid|h[Broken]|h")
    equal(#c.core.state.items, 1)
end)

test("searches cannot overlap and timeout clears pending attribution", function()
    local c = newClient()
    c:enable()
    c.core:SearchItems("meat")
    noCommand(c, function() c.core:SearchTravel("Stormwind") end)
    c:tick(90)
    check(not c.core.state.busy)
    c:message("2672 - |Hitem:2672:0:0:0:0:0:0:0|h[Stringy Wolf Meat]|h")
    equal(#c.core.state.items, 0, "late result must not be attributed after timeout")
    c:tick(1.1)
    c.core:SearchTravel("Stormwind")
    equal(#c.sent, 2)
end)

test("malformed search inputs cannot inject commands or hyperlinks", function()
    for _, value in ipairs({"", "   ", "meat\n.save", "x\r.revive", "|Htele:1|h[x]|h", string.rep("a", 1000)}) do
        local c = newClient()
        c:enable()
        noCommand(c, function() c.core:SearchItems(value) end)
        noCommand(c, function() c.core:SearchTravel(value) end)
    end
end)

test("teleport requires a validated server lookup entry, never a bare number", function()
    local c = newClient()
    c:enable()
    noCommand(c, function() c.core:Teleport(1) end)
    c.core:SearchTravel("Stormwind")
    c:message("1 - |cffffffff|Htele:1|h[Stormwind]|h|r")
    equal(#c.core.state.teleports, 1)
    c:tick(90)
    c:tick(1.1)
    c.core:Teleport(1)
    equal(#c.sent, 2)
    check(c.sent[2].text:find("|Htele:1", 1, true), "teleport must use server-provided validated hyperlink")
    notConfirmed(c)
end)

test("repair confirms only the exact requested recipient", function()
    local c = newClient({target = "Pablo"})
    c:enable()
    check(c.core:Execute("repair"))
    equal(firstText(c), ".gear repair Thada")
    c:message("You repair all [ThadaTwo]'s items.")
    notConfirmed(c)
    check(c.core.state.busy)
    c:message("You repair all [Thada]'s items.")
    equal(c.core.state.statusKind, "confirmed")
    check(not c.core.state.busy)
    equal(#c.sent, 1)
end)

test("save and sickness permit no target or self without changing targets", function()
    for _, options in ipairs({{}, {target = "Thada"}}) do
        for _, id in ipairs({"save", "sickness"}) do
            local c = newClient(options)
            c:enable()
            check(c.core:Execute(id))
            equal(firstText(c), id == "save" and ".save" or ".unaura 15007")
            equal(c.retargets, 0)
            notConfirmed(c)
        end
    end
end)

test("tampered teleport favorite links fail closed", function()
    for _, link in ipairs({"1", "|cffffffff|Htele:2|h[Wrong ID]|h|r",
        "|cffffffff|Htele:1|h[Stormwind]|h|r\n.save", "|Htele:1|h[Missing Color]|h",
        "|cffffffff|Htele:1|h[Unsafe\rName]|h|r", "|cffffffff|Htele:1|h[Bad|Hitem:1]|h|r"}) do
        local c = newClient()
        c:enable()
        c.core.db.favorites.teleport = {{id = 1, name = "Stormwind", link = link}}
        noCommand(c, function() c.core:Teleport(1) end)
        equal(c.core.state.statusKind, "failed")
    end
end)

test("unrelated system text cannot confirm a pending item grant", function()
    local c = newClient()
    c:enable()
    c.core:GiveItem(2672, 5)
    c:message("You repair all items.")
    c:message("Player Other receives loot: |Hitem:2672|h[Stringy Wolf Meat]|h x5.")
    c:tick(0.5)
    notConfirmed(c)
    equal(c.counts[2672], nil)
end)

test("inventory changes never automatically repeat an item grant", function()
    local c = newClient()
    c:enable()
    c.counts[2672] = 7
    c.core:GiveItem(2672, 5)
    c.counts[9999] = 99
    c:tick(0.1)
    notConfirmed(c)
    c.counts[2672] = 12
    c:fire("BAG_UPDATE", 0)
    c:tick(0.1)
    equal(#c.sent, 1)
    c:tick(90)
    equal(#c.sent, 1)
end)

test("unknown actions and invalid quest arguments fail closed", function()
    local c = newClient()
    c:enable()
    noCommand(c, function() c.core:Execute(".additem 2672 5", {}) end)
    noCommand(c, function() c.core:Execute("quest_status", {questId = "1\n.save"}) end)
    noCommand(c, function() c.core:Execute("quest_status", {questId = -1}) end)
end)

test("favorites and recent items remain realm and character scoped", function()
    local c = newClient()
    c:enable()
    c.core:ToggleFavorite("item", 2672, "Stringy Wolf Meat")
    equal(#c.core:GetFavorites("item"), 1)
    c.core:GiveItem(2672, 5)
    c.counts[2672] = 5
    c:tick(0.5)
    local saved = c.env.CoAGMCCDB
    local same = newClient({saved = saved})
    equal(#same.core:GetFavorites("item"), 1)
    check(#same.core:GetRecentItems() > 0)
    equal(#same.sent, 0, "reload must not repeat a historical grant")
    local otherPlayer = newClient({saved = saved, player = "Alexis"})
    equal(#otherPlayer.core:GetFavorites("item"), 0)
    equal(#otherPlayer.core:GetRecentItems(), 0)
    local otherRealm = newClient({saved = saved, realm = "Unreviewed Realm"})
    equal(#otherRealm.core:GetFavorites("item"), 0)
    equal(#otherRealm.core:GetRecentItems(), 0)
    check(not otherRealm.core.state.enabled, "realm opt-in must not leak")
    equal(#otherRealm.sent, 0)
end)

test("favorites toggle locally and reports/unbot never grant items", function()
    local c = newClient()
    c:enable()
    c.core:ToggleFavorite("item", 2672, "Stringy Wolf Meat")
    c.core:ToggleFavorite("item", 2672, "Stringy Wolf Meat")
    equal(#c.core:GetFavorites("item"), 0)
    noCommand(c, function()
        check(type(c.core:BuildReport()) == "string")
        c.core:OpenUnBot()
    end)
end)

test("realm opt-in needs an exact current-realm confirmation", function()
    local c = newClient({realm = "My CoA Server"})
    c.core:EnableRealm(true)
    check(not c.core.state.enabled)
    c.core:EnableRealm(true, "Another Server")
    check(not c.core.state.enabled)
    noCommand(c, function() c.core:GiveItem(2672, 1); c.core:Execute("save", {}) end)
    c:enable()
    check(c.core.state.enabled)
    local reloaded = newClient({realm = c.realm, saved = c.env.CoAGMCCDB})
    check(reloaded.core.state.enabled, "confirmed realm should persist for this character")
    check(not newClient({realm = c.realm, player = "Other", saved = c.env.CoAGMCCDB}).core.state.enabled)
end)

test("legacy enable flags without realm confirmation remain disabled", function()
    local c = newClient({saved = {realms = {["COA G1 CANDIDATE"] = {characters = {Thada = {enabled = true}}}}}})
    check(not c.core.state.enabled)
end)

test("realm confirmation UI does not enable until accepted", function()
    local c = newClient({ui = true, realm = "My CoA Server"})
    c.core:Toggle()
    local toggle = c.env.CoAGM_EnableRealm
    toggle:SetChecked(true)
    c:click(toggle)
    check(c.popup and not c.core.state.enabled)
    c.popup.dialog.OnAccept(nil, c.popup.data)
    check(c.core.state.enabled)
    equal(#c.sent, 0)
    toggle:SetChecked(false)
    c:click(toggle)
    check(not c.core.state.enabled)
end)

test("realm changes invalidate pending confirmation", function()
    local c = newClient({ui = true})
    c.core:Toggle()
    c.env.CoAGM_EnableRealm:SetChecked(true)
    c:click(c.env.CoAGM_EnableRealm)
    c.realm = "Another Realm"
    c.popup.dialog.OnAccept(nil, c.popup.data)
    check(not c.core.state.enabled)
    equal(#c.sent, 0)
end)

test("dedicated slash aliases do not overwrite the existing GM addon aliases", function()
    local c = newClient()
    local aliases = {}
    for key, value in pairs(c.env) do
        if type(key) == "string" and key:match("^SLASH_") then aliases[value] = true end
    end
    check(aliases["/coagm"] and aliases["/cgm"], "CoA aliases missing")
    check(not aliases["/gmcc"] and not aliases["/agm"], "existing addon alias was overwritten")
    equal(#c.sent, 0)
end)

test("legitimate lookup names containing failure-like text remain valid results", function()
    local c = newClient()
    c:enable()
    c.core:SearchItems("permission")
    c:message("2672 - |cffffffff|Hitem:2672:0|h[Permission to Hunt]|h|r")
    c:message("2673 - |cffffffff|Hitem:2673:0|h[This does not exist here]|h|r")
    equal(#c.core.state.items, 2)
    check(c.core.state.busy, "item name must not close the search as an error")
    c:tick(1.1)
    equal(c.core.state.statusKind, "confirmed")
    c:tick(1.1)
    c.core:SearchTravel("permission")
    c:message("1 - |cffffffff|Htele:1|h[Permission Terrace]|h|r")
    c:message("2 - |cffffffff|Htele:2|h[does not exist Plaza]|h|r")
    equal(#c.core.state.teleports, 2)
    check(c.core.state.busy)
end)

test("explicit server failures terminate the request without retrying", function()
    for _, response in ipairs({"Player not found!", "Item ID 2672 does not exist",
        "You do not have permission to execute this command.", "Cannot create item 2672"}) do
        local c = newClient()
        c:enable()
        c.core:GiveItem(2672, 5)
        c:message(response)
        equal(c.core.state.statusKind, "failed")
        check(not c.core.state.busy)
        check(c.core.state.status:find("partial grant", 1, true), "failure needs partial-grant caution")
        c:tick(90)
        equal(#c.sent, 1)
    end
end)

test("action mappings retain correct recipient and channel", function()
    local expected = {
        repair = ".gear repair Thada", revive = ".revive Thada", sickness = ".unaura 15007",
        save = ".save", bot_tank = ".playerbots coa tank", bot_heal = ".playerbots coa heal",
        bot_dps = ".playerbots coa dps", follow = "follow", stay = "stay", summon = "summon",
        server_info = ".server info", gps = ".gps", quest_status = ".quest status 123 Thada",
    }
    for id, command in pairs(expected) do
        local c = newClient()
        c.party = 1
        c:enable()
        check(c.core:Execute(id, {questId = 123}))
        equal(firstText(c), command)
        equal(c.sent[1].channel, (id == "follow" or id == "stay" or id == "summon") and "PARTY" or "SAY")
        notConfirmed(c)
    end
end)

test("party commands and recruitment honor party boundaries", function()
    for _, id in ipairs({"follow", "stay", "summon"}) do
        local c = newClient()
        c:enable()
        noCommand(c, function() c.core:Execute(id) end)
        c.party, c.raid = 4, 10
        noCommand(c, function() c.core:Execute(id) end)
    end
    for _, id in ipairs({"bot_tank", "bot_heal", "bot_dps"}) do
        local c = newClient()
        c:enable()
        c.party = 4
        noCommand(c, function() c.core:Execute(id) end)
        c.party, c.raid = 0, 10
        noCommand(c, function() c.core:Execute(id) end)
    end
end)

test("combat blocks mutations but permits a read-only search", function()
    local c = newClient()
    c:enable()
    c.combat = true
    noCommand(c, function() c.core:GiveItem(2672, 1); c.core:Execute("repair"); c.core:Execute("bot_tank") end)
    check(c.core:SearchItems("meat"))
    equal(firstText(c), ".lookup item meat")
end)

test("silent commands remain unknown after timeout", function()
    for _, id in ipairs({"revive", "sickness", "bot_tank"}) do
        local c = newClient()
        c:enable()
        c.core:Execute(id)
        c:tick(8)
        equal(c.core.state.statusKind, "unknown")
        check(not c.core.state.busy)
        equal(#c.sent, 1)
    end
end)

test("bounded searches, history and logs cannot grow indefinitely", function()
    local c = newClient()
    c:enable()
    c.core:SearchItems("item")
    for id = 1, 110 do c:message(id .. " - |cffffffff|Hitem:" .. id .. ":0|h[Item " .. id .. "]|h|r") end
    equal(#c.core.state.items, 100)
    c:tick(1.1)
    check(c.core.state.status:find("limited", 1, true))
    for id = 1, 25 do c:tick(1.1); c.core:GiveItem(id, 1); c:tick(8) end
    equal(#c.core:GetRecentItems(), 20)
    for id = 1, 55 do c.core:ToggleFavorite("item", id, "Item " .. id) end
    equal(#c.core:GetFavorites("item"), 50)
    check(#c.core.state.log <= 80)
end)

test("UI builds and navigates without sending commands or needing retail APIs", function()
    local c = newClient({ui = true})
    check(not c.env.CoAGM_Frame:IsShown())
    check(c:find("CoA GM"):IsVisible())
    c:click(c:find("CoA GM"))
    check(c.env.CoAGM_Frame:IsShown())
    for _, text in ipairs({"Items", "Travel", "Bots", "Diagnostics", "Quick Tools"}) do c:click(c:find(text)) end
    c:fire("PLAYER_TARGET_CHANGED")
    c:fire("PLAYER_ENTERING_WORLD")
    equal(#c.sent, 0)
    c.env.SlashCmdList.COAGMCOMMANDCENTER("")
    check(not c.env.CoAGM_Frame:IsShown())
    equal(#c.sent, 0)
end)

test("UI item search, favorites and giving require deliberate separate actions", function()
    local c = newClient({ui = true, target = "Pablo"})
    c.core:Toggle()
    c:click(c:find("Items"))
    local panel
    for _, frame in ipairs(c.frames) do if frame.itemID then panel = frame end end
    check(panel)
    check(not panel.searchButton:IsEnabled())
    c.env.CoAGM_EnableRealm:SetChecked(true)
    c:click(c.env.CoAGM_EnableRealm)
    panel.search:SetText("wolf")
    equal(#c.sent, 0, "typing must not send a lookup")
    c.popup.dialog.OnAccept(nil, c.popup.data)
    c:click(panel.searchButton)
    equal(firstText(c), ".lookup item wolf")
    check(not panel.searchButton:IsEnabled())
    c:message("2672 - |cffffffff|Hitem:2672:0|h[Stringy Wolf Meat]|h|r")
    c:tick(1.1)
    c:tick(1.1)
    check(panel.rows[1].action:IsEnabled())
    c:click(panel.rows[1].favorite)
    equal(#c.sent, 1, "favorite must remain a local change")
    equal(#c.core:GetFavorites("item"), 1)
    panel.quantity:SetText("5")
    c:click(panel.rows[1].action)
    equal(c.sent[2].text, ".additem Thada 2672 5")
    check(not panel.giveID:IsEnabled())
    notConfirmed(c)
end)

test("UI rejects invalid quantity and paginates without commands", function()
    local c = newClient({ui = true})
    c:enable()
    c.core:Toggle()
    c:click(c:find("Items"))
    local panel
    for _, frame in ipairs(c.frames) do if frame.itemID then panel = frame end end
    panel.itemID:SetText("2672")
    panel.quantity:SetText("0")
    c:click(panel.giveID)
    equal(#c.sent, 0)
    equal(c.core.state.statusKind, "failed")
    for id = 1, 17 do c.core.state.items[id] = {id = id, name = "Result " .. id} end
    c.core:RefreshUI()
    equal(panel.rows[1].entry.id, 1)
    c:click(panel.pager.next)
    equal(panel.rows[1].entry.id, 9)
    c:click(panel.pager.next)
    equal(panel.rows[1].entry.id, 17)
    check(not panel.pager.next:IsEnabled())
    c:click(panel.pager.previous)
    equal(panel.rows[1].entry.id, 9)
    equal(#c.sent, 0)
end)

test("UI report, tooltip and UnBot integration do not send server commands", function()
    local c = newClient({ui = true})
    c.core:Toggle()
    c:click(c:find("Diagnostics"))
    c:click(c:find("Copy report"))
    check(c.env.CoAGM_Report:IsShown())
    check(c.env.CoAGM_Report.box:GetText():find("not proof", 1, true))
    c:click(c:find("Close", c.env.CoAGM_Report))
    c:click(c:find("Bots"))
    local opened = 0
    c.env.SlashCmdList.UNBOT = function() opened = opened + 1 end
    c:click(c:find("Open UnBot"))
    equal(opened, 1)
    local launcher = c:find("CoA GM")
    launcher.scripts.OnEnter(launcher)
    launcher.scripts.OnLeave(launcher)
    equal(#c.sent, 0)
end)

print(string.format("CoA core regression tests: %d passed, %d failed", passed, failed))
if failed > 0 then os.exit(1) end
