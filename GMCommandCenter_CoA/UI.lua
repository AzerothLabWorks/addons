CoAGM = CoAGM or {}

local Addon = CoAGM
local UI = { activeTab = "quick", pages = {}, modes = {} }
local LIST_ROWS = 8
local ACTION_ROWS = 8
local COLORS = {
    info = { 0.65, 0.80, 0.95 },
    queued = { 0.95, 0.78, 0.35 },
    sent = { 0.95, 0.78, 0.35 },
    confirmed = { 0.40, 0.90, 0.60 },
    failed = { 1.00, 0.40, 0.35 },
    unknown = { 0.75, 0.77, 0.82 },
}
local TABS = {
    { id = "quick", label = "Quick Tools" },
    { id = "items", label = "Items" },
    { id = "travel", label = "Travel" },
    { id = "bots", label = "Bots" },
    { id = "diagnostics", label = "Diagnostics" },
}

local function Label(parent, text, width, font)
    local label = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlightSmall")
    label:SetText(text or "")
    label:SetJustifyH("LEFT")
    if width then label:SetWidth(width) end
    return label
end

local function Button(parent, text, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(width or 100)
    button:SetHeight(24)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    return button
end

local function EditBox(parent, width, numeric)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetWidth(width)
    box:SetHeight(24)
    box:SetAutoFocus(false)
    box:SetFontObject(ChatFontNormal)
    if numeric then box:SetNumeric(true) end
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

local function Backdrop(frame, alpha)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.035, 0.045, 0.055, alpha or 0.92)
    frame:SetBackdropBorderColor(0.35, 0.40, 0.45, 0.9)
end

local function Tooltip(widget, title, body)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title)
        if body then GameTooltip:AddLine(body, 0.9, 0.9, 0.9, true) end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function SetEnabled(button, enabled)
    if enabled then button:Enable() else button:Disable() end
end

local function CanSend()
    local state = Addon.state or {}
    return state.enabled and not state.busy
end

local function Fail(message)
    Addon.state = Addon.state or {}
    Addon.state.status = message
    Addon.state.statusKind = "failed"
    Addon:RefreshUI()
end

local function Call(method, ...)
    if type(Addon[method]) ~= "function" then
        Fail("This control is unavailable: " .. tostring(method))
        return
    end
    local ok, message = Addon[method](Addon, ...)
    if ok == false and message then
        Addon.state.status = tostring(message)
        Addon.state.statusKind = "failed"
    end
    Addon:RefreshUI()
end

local function Profile()
    if not Addon.db then return nil end
    Addon.db.ui = Addon.db.ui or {}
    return Addon.db.ui
end

local function SavePosition(frame, prefix)
    local profile = Profile()
    if not profile then return end
    local x, y = frame:GetCenter()
    local centerX, centerY = UIParent:GetCenter()
    if x and y and centerX and centerY then
        profile[prefix .. "X"] = x - centerX
        profile[prefix .. "Y"] = y - centerY
    end
end

local function RestorePosition(frame, prefix, fallbackX, fallbackY)
    local profile = Profile()
    local x = profile and tonumber(profile[prefix .. "X"])
    local y = profile and tonumber(profile[prefix .. "Y"])
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x or fallbackX, y or fallbackY)
end

local function ViewData(kind)
    local mode = UI.modes[kind] or "results"
    if mode == "favorites" then return Addon:GetFavorites(kind) or {} end
    if mode == "recent" then return Addon:GetRecentItems() or {} end
    local state = Addon.state or {}
    return kind == "item" and (state.items or {}) or (state.teleports or {})
end

local function Favorites(kind)
    local found = {}
    for _, entry in ipairs(Addon:GetFavorites(kind) or {}) do
        found[tostring(entry.id)] = true
    end
    return found
end

local function DisplayName(value, fallback)
    if type(value) == "table" then
        return tostring(value.name or value.player or fallback)
    end
    if value == nil or value == "" or value == false then return fallback end
    return tostring(value)
end

local function PageInfo(key, total, rows)
    local maxPage = math.max(1, math.ceil(total / rows))
    local page = math.max(1, math.min(UI.pages[key] or 1, maxPage))
    UI.pages[key] = page
    return page, maxPage, (page - 1) * rows
end

local function SelectTab(id)
    UI.activeTab = id
    Addon:RefreshUI()
end

local function MakePanel()
    local panel = CreateFrame("Frame", nil, UI.frame)
    panel:SetPoint("TOPLEFT", 24, -170)
    panel:SetPoint("BOTTOMRIGHT", -24, 82)
    panel:Hide()
    return panel
end

local function MakePager(panel, key, bottom)
    local pager = {}
    pager.label = Label(panel, "", 330)
    pager.label:SetPoint("BOTTOMLEFT", 0, bottom or 0)
    pager.previous = Button(panel, "Previous", 80, function()
        UI.pages[key] = math.max(1, (UI.pages[key] or 1) - 1)
        Addon:RefreshUI()
    end)
    pager.previous:SetPoint("BOTTOMRIGHT", -86, (bottom or 0) - 4)
    pager.next = Button(panel, "Next", 80, function()
        UI.pages[key] = (UI.pages[key] or 1) + 1
        Addon:RefreshUI()
    end)
    pager.next:SetPoint("LEFT", pager.previous, "RIGHT", 6, 0)
    return pager
end

local function RefreshPager(pager, page, maxPage, total, noun)
    pager.label:SetText(total .. " " .. noun .. "  |  Page " .. page .. " / " .. maxPage)
    SetEnabled(pager.previous, page > 1)
    SetEnabled(pager.next, page < maxPage)
end

local function ActionsFor(tab)
    local results = {}
    for _, action in ipairs(Addon.actions or {}) do
        if action.tab == tab then results[#results + 1] = action end
    end
    return results
end

local function MakeActionsPanel(tab, guidance)
    local panel = MakePanel()
    panel.guidance = Label(panel, guidance, 760)
    panel.guidance:SetPoint("TOPLEFT", 0, 0)
    panel.guidance:SetHeight(38)
    panel.buttons = {}
    for index = 1, ACTION_ROWS do
        local row = CreateFrame("Frame", nil, panel)
        row:SetWidth(372)
        row:SetHeight(61)
        row:SetPoint("TOPLEFT", ((index - 1) % 2) * 386, -48 - math.floor((index - 1) / 2) * 68)
        row.button = Button(row, "", 370, function(self)
            local action = self:GetParent().action
            if action then Call("Execute", action.id, {}) end
        end)
        row.button:SetPoint("TOPLEFT", 0, 0)
        row.help = Label(row, "", 362)
        row.help:SetPoint("TOPLEFT", 4, -28)
        row.help:SetHeight(31)
        row.help:SetTextColor(0.70, 0.74, 0.78)
        panel.buttons[index] = row
    end
    panel.pager = MakePager(panel, tab)
    return panel
end

local function RefreshActions(panel, tab)
    local actions = ActionsFor(tab)
    local page, maxPage, offset = PageInfo(tab, #actions, ACTION_ROWS)
    for index, row in ipairs(panel.buttons) do
        local action = actions[offset + index]
        row.action = action
        if action then
            row.button:SetText(action.label or action.id)
            row.help:SetText(action.help or "")
            Tooltip(row.button, action.label or action.id, action.help)
            SetEnabled(row.button, CanSend())
            row:Show()
        else
            row:Hide()
        end
    end
    RefreshPager(panel.pager, page, maxPage, #actions, "tools")
end

local function Search(panel, kind)
    panel.search:ClearFocus()
    UI.modes[kind] = "results"
    UI.pages[kind] = 1
    Call(kind == "item" and "SearchItems" or "SearchTravel", panel.search:GetText())
end

local function Give(panel, id)
    local count = tonumber(panel.quantity:GetText())
    id = tonumber(id)
    if not id or id < 1 or id ~= math.floor(id) then
        Fail("Enter a valid positive item ID, or choose a search result.")
        return
    end
    if not count or count < 1 or count > 200 or count ~= math.floor(count) then
        Fail("Quantity must be a whole number from 1 to 200.")
        return
    end
    Call("GiveItem", id, count)
end

local function MakeBrowser(kind)
    local panel = MakePanel()
    panel.search = EditBox(panel, 395)
    panel.search:SetPoint("TOPLEFT", 6, -5)
    panel.search:SetMaxLetters(100)
    panel.search:SetScript("OnEnterPressed", function() Search(panel, kind) end)
    panel.searchButton = Button(panel, "Search", 90, function() Search(panel, kind) end)
    panel.searchButton:SetPoint("LEFT", panel.search, "RIGHT", 12, 0)
    panel.note = Label(panel, "", 740)
    panel.note:SetPoint("TOPLEFT", 0, -36)
    if kind == "item" then
        panel.note:SetText("Search your server's item catalog. Enter a name, or use an item ID below.")
        local idLabel = Label(panel, "Item ID", 50)
        idLabel:SetPoint("TOPLEFT", 0, -61)
        panel.itemID = EditBox(panel, 100, true)
        panel.itemID:SetMaxLetters(10)
        panel.itemID:SetPoint("LEFT", idLabel, "RIGHT", 8, 0)
        local countLabel = Label(panel, "Quantity", 58)
        countLabel:SetPoint("LEFT", panel.itemID, "RIGHT", 20, 0)
        panel.quantity = EditBox(panel, 55, true)
        panel.quantity:SetMaxLetters(3)
        panel.quantity:SetText("1")
        panel.quantity:SetPoint("LEFT", countLabel, "RIGHT", 8, 0)
        panel.giveID = Button(panel, "Give to yourself", 140, function() Give(panel, panel.itemID:GetText()) end)
        panel.giveID:SetPoint("LEFT", panel.quantity, "RIGHT", 14, 0)
        panel.itemID:SetScript("OnEnterPressed", function() Give(panel, panel.itemID:GetText()) end)
        Tooltip(panel.giveID, "Give an item to yourself",
            "Items are addressed to your character by name, regardless of your selected target. "
                .. "Quantity applies to this button and every result below.")
    else
        panel.note:SetText("Search saved server destinations. Teleport sends a travel request; check the destination first.")
        local travelHint = Label(panel, "Favorites retain server destination links; there is no automatic travel.", 740)
        travelHint:SetPoint("TOPLEFT", 0, -61)
        travelHint:SetTextColor(0.70, 0.74, 0.78)
    end
    panel.modeButtons = {}
    local modes = kind == "item" and { "results", "favorites", "recent" } or { "results", "favorites" }
    local names = { results = "Results", favorites = "Favorites", recent = "Recent" }
    for index, mode in ipairs(modes) do
        local selectedMode = mode
        local button = Button(panel, names[mode], 104, function()
            UI.modes[kind] = selectedMode
            UI.pages[kind] = 1
            Addon:RefreshUI()
        end)
        button:SetPoint("TOPLEFT", (index - 1) * 112, -94)
        panel.modeButtons[mode] = button
    end
    panel.rows = {}
    for index = 1, LIST_ROWS do
        local row = CreateFrame("Frame", nil, panel)
        row:SetWidth(760)
        row:SetHeight(25)
        row:SetPoint("TOPLEFT", 0, -125 - (index - 1) * 26)
        row:EnableMouse(true)
        row.highlight = row:CreateTexture(nil, "BACKGROUND")
        row.highlight:SetAllPoints(row)
        row.highlight:SetTexture(0.14, 0.22, 0.26, index % 2 == 0 and 0.5 or 0.2)
        row.name = Label(row, "", 516)
        row.name:SetPoint("LEFT", 7, 0)
        row.name:SetHeight(22)
        row.id = Label(row, "", 82)
        row.id:SetJustifyH("RIGHT")
        row.id:SetPoint("RIGHT", -143, 0)
        row.id:SetTextColor(0.64, 0.68, 0.72)
        row.action = Button(row, kind == "item" and "Give" or "Teleport", 88, function(self)
            local entry = self:GetParent().entry
            if not entry then return end
            if kind == "item" then Give(panel, entry.id) else Call("Teleport", entry.id) end
        end)
        row.action:SetPoint("RIGHT", -43, 0)
        row.favorite = Button(row, "+", 35, function(self)
            local entry = self:GetParent().entry
            if entry then Call("ToggleFavorite", kind, entry.id, entry.name) end
        end)
        row.favorite:SetPoint("RIGHT", 0, 0)
        Tooltip(row.favorite, "Favorite", "Add or remove this entry from your character's favorites.")
        row:SetScript("OnEnter", function(self)
            local entry = self.entry
            if not entry then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if kind == "item" then
                GameTooltip:SetHyperlink(entry.link or ("item:" .. tostring(entry.id) .. ":0:0:0:0:0:0:0"))
            else
                GameTooltip:SetText(entry.name or ("Destination " .. tostring(entry.id)))
                GameTooltip:AddLine("Destination ID: " .. tostring(entry.id), 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        panel.rows[index] = row
    end
    panel.empty = Label(panel, "", 735)
    panel.empty:SetPoint("TOPLEFT", 10, -156)
    panel.empty:SetHeight(75)
    panel.empty:SetTextColor(0.7, 0.74, 0.78)
    panel.pager = MakePager(panel, kind)
    return panel
end

local function RefreshBrowser(panel, kind)
    local data = ViewData(kind)
    local mode = UI.modes[kind] or "results"
    local page, maxPage, offset = PageInfo(kind, #data, LIST_ROWS)
    local favorites = Favorites(kind)
    for id, button in pairs(panel.modeButtons) do
        if id == mode then button:LockHighlight() else button:UnlockHighlight() end
    end
    for index, row in ipairs(panel.rows) do
        local entry = data[offset + index]
        row.entry = entry
        if entry then
            row.name:SetText(entry.link or entry.name or ("ID " .. tostring(entry.id)))
            row.id:SetText(tostring(entry.id))
            row.favorite:SetText(favorites[tostring(entry.id)] and "*" or "+")
            SetEnabled(row.action, CanSend())
            row:Show()
        else
            row:Hide()
        end
    end
    if #data == 0 then
        if mode == "favorites" then
            panel.empty:SetText("No favorites yet. Use + beside a result to keep it here.")
        elseif mode == "recent" then
            panel.empty:SetText("No recent items yet. Items you use will appear here.")
        elseif (Addon.state or {}).busy then
            panel.empty:SetText("Waiting for the current request. Results are not assumed until the server responds.")
        else
            panel.empty:SetText("No results to display. Enter a search above and click Search.\n"
                .. "Searching is explicit; typing does not send commands.")
        end
        panel.empty:Show()
    else
        panel.empty:Hide()
    end
    SetEnabled(panel.searchButton, CanSend())
    if panel.giveID then
        panel.giveID:SetText("Give to " .. DisplayName((Addon.state or {}).player, "yourself"))
        SetEnabled(panel.giveID, CanSend())
    end
    RefreshPager(panel.pager, page, maxPage, #data, kind == "item" and "items" or "destinations")
end

local function OpenReport()
    local text = Addon:BuildReport() or "No diagnostic report is available."
    local report = UI.report
    report.box:SetText(text)
    local lines = 1
    for line in string.gmatch(text .. "\n", "([^\n]*)\n") do
        lines = lines + math.max(1, math.ceil(string.len(line) / 86))
    end
    report.box:SetHeight(math.max(340, lines * 16))
    report.scroll:SetVerticalScroll(0)
    report:Show()
    report.box:SetFocus()
    report.box:HighlightText()
end

local function MakeReport()
    local report = CreateFrame("Frame", "CoAGM_Report", UI.frame)
    report:SetWidth(744)
    report:SetHeight(470)
    report:SetPoint("CENTER")
    report:SetFrameStrata("DIALOG")
    report:EnableMouse(true)
    Backdrop(report, 1)
    local title = Label(report, "Copy diagnostic report", 560, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    local note = Label(report, "Press Ctrl+A, then Ctrl+C to copy. Nothing is sent or uploaded automatically.", 690)
    note:SetPoint("TOPLEFT", 20, -48)
    local close = Button(report, "Close", 80, function() report:Hide() end)
    close:SetPoint("TOPRIGHT", -16, -16)
    local scroll = CreateFrame("ScrollFrame", "CoAGM_ReportScroll", report, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 22, -78)
    scroll:SetPoint("BOTTOMRIGHT", -42, 22)
    local box = CreateFrame("EditBox", nil, scroll)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetFontObject(ChatFontNormal)
    box:SetWidth(666)
    box:SetHeight(340)
    box:SetTextInsets(4, 4, 4, 4)
    box:SetScript("OnEscapePressed", function() report:Hide() end)
    scroll:SetScrollChild(box)
    report.box = box
    report.scroll = scroll
    report:SetScript("OnHide", function() box:ClearFocus() end)
    report:Hide()
    return report
end

local function MakeDiagnostics()
    local panel = MakePanel()
    local hint = Label(panel, "Read-only checks and a local activity log. Copy a report when sharing a problem.", 760)
    hint:SetPoint("TOPLEFT", 0, 0)
    panel.actions = {}
    for index = 1, 4 do
        local button = Button(panel, "", 174, function(self)
            local action = self.action
            if not action then return end
            local args = {}
            if action.id == "quest_status" then args.questId = tonumber(panel.quest:GetText()) end
            Call("Execute", action.id, args)
        end)
        button:SetPoint("TOPLEFT", (index - 1) * 190, -31)
        panel.actions[index] = button
    end
    local questLabel = Label(panel, "Quest ID (for quest status)", 180)
    questLabel:SetPoint("TOPLEFT", 0, -76)
    panel.quest = EditBox(panel, 115, true)
    panel.quest:SetMaxLetters(10)
    panel.quest:SetPoint("LEFT", questLabel, "RIGHT", 8, 0)
    local copy = Button(panel, "Copy report", 112, OpenReport)
    copy:SetPoint("TOPLEFT", 526, -66)
    local clear = Button(panel, "Clear log", 112, function() Call("ClearLog") end)
    clear:SetPoint("LEFT", copy, "RIGHT", 10, 0)
    local logTitle = Label(panel, "Recent activity", 300, "GameFontNormal")
    logTitle:SetPoint("TOPLEFT", 0, -113)
    panel.logLines = {}
    for index = 1, 10 do
        local line = Label(panel, "", 760)
        line:SetPoint("TOPLEFT", 0, -137 - (index - 1) * 20)
        line:SetHeight(19)
        panel.logLines[index] = line
    end
    panel.pager = MakePager(panel, "diagnostics")
    return panel
end

local function RefreshDiagnostics(panel)
    local actions = ActionsFor("diagnostics")
    local page, maxPage, offset = PageInfo("diagnostics", #actions, 4)
    for index, button in ipairs(panel.actions) do
        button.action = actions[offset + index]
        if button.action then
            button:SetText(button.action.label or button.action.id)
            Tooltip(button, button.action.label or button.action.id, button.action.help)
            SetEnabled(button, CanSend())
            button:Show()
        else
            button:Hide()
        end
    end
    local log = (Addon.state or {}).log or {}
    for index, line in ipairs(panel.logLines) do
        local entry = log[#log - index + 1]
        if entry then
            local text = type(entry) == "table" and entry.text or entry
            local kind = type(entry) == "table" and entry.kind or "unknown"
            local stamp = type(entry) == "table" and entry.time or nil
            local color = COLORS[kind] or COLORS.unknown
            line:SetText((stamp and (tostring(stamp) .. "  ") or "")
                .. "[" .. tostring(kind or "unknown") .. "] " .. tostring(text or ""))
            line:SetTextColor(color[1], color[2], color[3])
        else
            line:SetText(index == 1 and "No activity yet." or "")
            line:SetTextColor(0.7, 0.74, 0.78)
        end
    end
    RefreshPager(panel.pager, page, maxPage, #actions, "checks")
end

local function MakeLauncher()
    local launcher = Button(UIParent, "CoA GM", 72, function(self, button)
        if self.wasDragged then
            self.wasDragged = false
            return
        end
        if button == "RightButton" then
            local profile = Profile()
            if profile then profile.launcherX, profile.launcherY = nil, nil end
            RestorePosition(self, "launcher", 390, -175)
        else
            Addon:Toggle()
        end
    end)
    launcher:SetFrameStrata("MEDIUM")
    launcher:SetMovable(true)
    launcher:SetClampedToScreen(true)
    launcher:EnableMouse(true)
    launcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    launcher:RegisterForDrag("LeftButton")
    launcher:SetScript("OnDragStart", function(self)
        self.wasDragged = true
        self:StartMoving()
    end)
    launcher:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self, "launcher")
    end)
    Tooltip(launcher, "CoA GM Command Center", "Click to open. Drag to move. Right-click to reset its position.")
    RestorePosition(launcher, "launcher", 390, -175)
    return launcher
end

function Addon:BuildUI()
    if UI.frame then return end
    local frame = CreateFrame("Frame", "CoAGM_Frame", UIParent)
    UI.frame = frame
    frame:SetWidth(820)
    frame:SetHeight(620)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self, "frame")
    end)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    RestorePosition(frame, "frame", 0, 0)
    local title = Label(frame, "CoA GM Command Center", 600, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 24, -23)
    local close = Button(frame, "X", 25, function() frame:Hide() end)
    close:SetPoint("TOPRIGHT", -20, -18)
    UI.realm = Label(frame, "", 592)
    UI.realm:SetPoint("TOPLEFT", 24, -54)
    UI.character = Label(frame, "", 365)
    UI.character:SetPoint("TOPLEFT", 24, -76)
    UI.target = Label(frame, "", 380)
    UI.target:SetPoint("TOPLEFT", 410, -76)
    UI.enable = CreateFrame("CheckButton", "CoAGM_EnableRealm", frame, "UICheckButtonTemplate")
    UI.enable:SetWidth(26)
    UI.enable:SetHeight(26)
    UI.enable:SetPoint("TOPRIGHT", -167, -43)
    StaticPopupDialogs.COAGM_CONFIRM_REALM = {
        text = "Enable CoA GM commands on %s for %s? Use only with a compatible CoA server. Server GM permissions still apply.",
        button1 = "Enable", button2 = "Cancel", timeout = 0, whileDead = true, hideOnEscape = true,
        OnAccept = function(_, data)
            if data and UnitName("player") == data.player then Call("EnableRealm", true, data.realm) end
        end,
    }
    UI.enable:SetScript("OnClick", function(self)
        local enable = self:GetChecked() and true or false
        self:SetChecked(Addon.state.enabled)
        if enable then
            StaticPopup_Show("COAGM_CONFIRM_REALM", Addon.state.realm, Addon.state.player,
                {realm = Addon.state.realm, player = Addon.state.player})
        else
            Call("EnableRealm", false)
        end
    end)
    local enableLabel = Label(frame, "Enable this character", 145)
    enableLabel:SetPoint("LEFT", UI.enable, "RIGHT", 3, 0)
    Tooltip(UI.enable, "Character and realm opt-in",
        "Confirm the realm shown in this panel before enabling this character. "
            .. "Other characters and realms start disabled. Server permissions still apply.")
    UI.guidance = Label(frame, "", 768)
    UI.guidance:SetPoint("TOPLEFT", 24, -100)
    UI.guidance:SetHeight(30)
    UI.guidance:SetTextColor(0.75, 0.78, 0.82)
    UI.tabs = {}
    UI.panels = {}
    for index, tab in ipairs(TABS) do
        local tabID = tab.id
        local button = Button(frame, tab.label, 145, function() SelectTab(tabID) end)
        button:SetPoint("TOPLEFT", 24 + (index - 1) * 154, -136)
        UI.tabs[tabID] = button
    end
    UI.panels.quick = MakeActionsPanel("quick",
        "Repair and revive explicitly target you. Clear other targets for Save and Remove Rez Sickness. "
            .. "Hover over a button for its full description.")
    UI.panels.items = MakeBrowser("item")
    UI.panels.travel = MakeBrowser("teleport")
    UI.panels.bots = MakeActionsPanel("bots",
        "Request group roles here. Use the existing UnBot addon for detailed bot controls and AI settings.")
    local unbot = Button(UI.panels.bots, "Open UnBot", 116, function() Call("OpenUnBot") end)
    unbot:SetPoint("TOPRIGHT", -2, 0)
    UI.panels.bots.guidance:SetWidth(625)
    UI.panels.diagnostics = MakeDiagnostics()
    UI.report = MakeReport()
    local status = CreateFrame("Frame", nil, frame)
    status:SetPoint("BOTTOMLEFT", 22, 21)
    status:SetPoint("BOTTOMRIGHT", -22, 21)
    status:SetHeight(48)
    Backdrop(status, 0.85)
    UI.status = Label(status, "", 747)
    UI.status:SetPoint("TOPLEFT", 11, -9)
    UI.status:SetHeight(30)
    UI.launcher = MakeLauncher()
    frame:SetScript("OnHide", function()
        UI.report:Hide()
        for _, panel in pairs(UI.panels) do
            if panel.search then panel.search:ClearFocus() end
            if panel.quantity then panel.quantity:ClearFocus() end
            if panel.itemID then panel.itemID:ClearFocus() end
            if panel.quest then panel.quest:ClearFocus() end
        end
    end)
    if UISpecialFrames then table.insert(UISpecialFrames, "CoAGM_Frame") end
    frame:Hide()
    self:RefreshUI()
end

function Addon:RefreshUI()
    if not UI.frame then return end
    local state = self.state or {}
    UI.realm:SetText("Realm: " .. DisplayName(state.realm, "Not connected")
        .. (state.enabled and "  |cff66dd99[enabled]|r" or "  |cffaaaaaa[disabled]|r"))
    UI.character:SetText("Character: " .. DisplayName(state.player, "Unknown"))
    UI.target:SetText("Selected target: " .. DisplayName(state.target, "None"))
    UI.enable:SetChecked(state.enabled and true or false)
    UI.guidance:SetText(state.enabled
        and "Repair/revive/items explicitly target you. Clear other targets for Save/Rez Sickness."
        or "Commands are disabled. Confirm this realm and character to enable; saved entries remain viewable.")
    local kind = state.statusKind or "unknown"
    local color = COLORS[kind] or COLORS.unknown
    UI.status:SetText((state.busy and "[BUSY] " or "") .. string.upper(tostring(kind))
        .. "  " .. tostring(state.status or "Choose a tool. No command has been sent."))
    UI.status:SetTextColor(color[1], color[2], color[3])
    for id, panel in pairs(UI.panels) do
        if id == UI.activeTab then panel:Show() else panel:Hide() end
        if id == UI.activeTab then UI.tabs[id]:LockHighlight() else UI.tabs[id]:UnlockHighlight() end
    end
    RefreshActions(UI.panels.quick, "quick")
    RefreshActions(UI.panels.bots, "bots")
    RefreshBrowser(UI.panels.items, "item")
    RefreshBrowser(UI.panels.travel, "teleport")
    RefreshDiagnostics(UI.panels.diagnostics)
end

function Addon:Toggle()
    if not UI.frame then self:BuildUI() end
    if UI.frame:IsShown() then
        UI.frame:Hide()
    else
        self:RefreshUI()
        UI.frame:Show()
    end
end
