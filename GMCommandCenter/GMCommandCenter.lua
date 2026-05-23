local ADDON = "GMCommandCenter"
local ROWS = 13
local state = {
    selected = nil,
    filter = "",
    category = "All",
    tab = "commands",
    rows = {},
    lookupResults = {},
    lookupCaptureUntil = 0,
    lookupStatus = "No captured lookup results yet.",
    lookupKind = nil,
    lookupResultLines = {},
    lookupResultButtons = {},
}

local categories = { "All", "GM", "Items", "Spells", "Character", "Teleport", "NPCs", "Quests", "Server" }
local ResetCommandScroll

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99GMCC|r " .. tostring(message))
end

local function Trim(value)
    value = value or ""
    return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

local function EncodeUrl(value)
    value = tostring(value or "")
    value = string.gsub(value, " ", "+")
    return value
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

local function LookupSearchTerm(value)
    value = Trim(value)
    if not string.find(value, "*", 1, true) then
        return value, false
    end

    local best = ""
    for part in string.gmatch(value, "[^%*]+") do
        part = Trim(part)
        if string.len(part) > string.len(best) then
            best = part
        end
    end

    if best == "" then
        best = string.gsub(value, "%*", "")
        best = Trim(best)
    end

    return best, true
end

local function IsNumber(value)
    value = Trim(value)
    return value ~= "" and string.find(value, "^%-?%d+$") ~= nil
end

local function ExtractSpellId(message)
    message = tostring(message or "")
    local id = string.match(message, "|Hspell:(%d+)")
    if id then
        return id
    end

    id = string.match(message, "^[^%d]*(%d%d%d+)")
    if id then
        return id
    end

    id = string.match(message, "%f[%d](%d%d%d+)%f[^%d]")
    return id
end

local function RefreshLookupResults()
    if not GMCC_LookupResultStatus then
        return
    end

    local count = table.getn(state.lookupResults)
    if count == 0 then
        GMCC_LookupResultStatus:SetText(state.lookupStatus)
    else
        GMCC_LookupResultStatus:SetText(count .. " captured result lines")
    end

    for i = 1, 8 do
        local line = state.lookupResultLines[i]
        local button = state.lookupResultButtons[i]
        local result = state.lookupResults[i]
        if line then
            line:SetText(result and result.text or "")
        end
        if button then
            if result and result.spellId then
                button.spellId = result.spellId
                button:SetText("Learn " .. result.spellId)
                button:Show()
            else
                button.spellId = nil
                button:Hide()
            end
        end
    end
end

local function ClearLookupResults(status)
    state.lookupResults = {}
    state.lookupStatus = status or "No captured lookup results yet."
    RefreshLookupResults()
end

local function StartLookupCapture(command)
    if string.find(command, "^%.lookup%s") then
        state.lookupKind = string.match(command, "^%.lookup%s+(%S+)") or nil
        state.lookupCaptureUntil = GetTime() + 8
        ClearLookupResults("Waiting for server lookup results...")
    end
end

local function CaptureLookupResult(message)
    if state.lookupCaptureUntil <= 0 or GetTime() > state.lookupCaptureUntil then
        return
    end

    message = Trim(message)
    if message == "" then
        return
    end

    table.insert(state.lookupResults, {
        text = message,
        spellId = state.lookupKind == "spell" and ExtractSpellId(message) or nil,
    })
    while table.getn(state.lookupResults) > 8 do
        table.remove(state.lookupResults, 1)
    end
    RefreshLookupResults()
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

    StartLookupCapture(command)
    SendChatMessage(command, "SAY")
    Print("Ran: " .. command)
    GMCommandCenterDB = GMCommandCenterDB or {}
    GMCommandCenterDB.lastCommand = command
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

local function SelectCommand(entry)
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

local function SetTab(tab)
    state.tab = tab
    if tab == "commands" then
        GMCC_CommandPanel:Show()
        GMCC_LookupPanel:Hide()
        GMCC_CommandsTab:Disable()
        GMCC_LookupsTab:Enable()
    else
        GMCC_CommandPanel:Hide()
        GMCC_LookupPanel:Show()
        GMCC_CommandsTab:Enable()
        GMCC_LookupsTab:Disable()
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
            state.category = cat
            ResetCommandScroll()
            RefreshCommandRows()
        end)
        lastButton = button
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
end

local function BuildLookupPanel(parent)
    local panel = CreateFrame("Frame", "GMCC_LookupPanel", parent)
    panel:SetPoint("TOPLEFT", 16, -72)
    panel:SetPoint("BOTTOMRIGHT", -16, 16)

    local queryLabel = CreateLabel(panel, nil, "Name or ID", "small")
    queryLabel:SetPoint("TOPLEFT", 2, -4)
    GMCC_LookupQuery = CreateEditBox(panel, "GMCC_LookupQuery", 260, 24)
    GMCC_LookupQuery:SetPoint("TOPLEFT", queryLabel, "BOTTOMLEFT", 0, -4)
    local wildcardHelp = CreateLabel(panel, nil, "Wildcards allowed for UI search. Server lookups use the strongest substring.", "small")
    wildcardHelp:SetPoint("TOPLEFT", GMCC_LookupQuery, "BOTTOMLEFT", 0, -8)
    wildcardHelp:SetTextColor(0.72, 0.72, 0.72)

    local amountLabel = CreateLabel(panel, nil, "Count / extra", "small")
    amountLabel:SetPoint("LEFT", queryLabel, "RIGHT", 220, 0)
    GMCC_LookupAmount = CreateEditBox(panel, "GMCC_LookupAmount", 110, 24)
    GMCC_LookupAmount:SetPoint("TOPLEFT", amountLabel, "BOTTOMLEFT", 0, -4)
    GMCC_LookupAmount:SetText("1")

    GMCC_UrlBox = CreateEditBox(panel, "GMCC_UrlBox", 420, 24)
    GMCC_UrlBox:SetPoint("TOPLEFT", 2, -90)
    GMCC_UrlBox:SetText("WotLKDB URL appears here for ID-based actions.")

    local function MakeLookupButton(def, index)
        local button = CreateButton(panel, nil, def.label, 132, 24)
        local col = math.mod(index - 1, 4)
        local row = math.floor((index - 1) / 4)
        button:SetPoint("TOPLEFT", 2 + (col * 140), -128 - (row * 30))
        button:SetScript("OnClick", function()
            local rawQuery = Trim(GMCC_LookupQuery:GetText())
            local amount = Trim(GMCC_LookupAmount:GetText())
            if rawQuery == "" then
                Print("Enter a name or ID first.")
                return
            end
            local query, usedWildcard = LookupSearchTerm(rawQuery)
            if query == "" then
                Print("Wildcard search needs at least one letter or number.")
                return
            end
            if def.idOnly and not IsNumber(query) then
                Print(def.label .. " needs a numeric ID. Run a lookup by name first, then use the returned ID.")
                return
            end

            local command
            if string.find(def.command, "%s %s", 1, true) then
                command = string.format(def.command, query, amount ~= "" and amount or "1")
            else
                command = string.format(def.command, query)
            end
            RunCommand(command)
            if usedWildcard then
                Print("Wildcard lookup sent as substring: " .. query)
            end

            if def.url then
                SetEditBoxText(GMCC_UrlBox, string.format(def.url, EncodeUrl(query)))
                GMCC_UrlBox:HighlightText()
            else
                SetEditBoxText(GMCC_UrlBox, "")
            end
        end)
    end

    for i, def in ipairs(GMCC_LOOKUPS) do
        MakeLookupButton(def, i)
    end

    local resultsLabel = CreateLabel(panel, nil, "Server lookup results", "large")
    resultsLabel:SetPoint("TOPLEFT", 2, -210)
    GMCC_LookupResultStatus = CreateLabel(panel, "GMCC_LookupResultStatus", "No captured lookup results yet.", "small")
    GMCC_LookupResultStatus:SetPoint("TOPLEFT", resultsLabel, "BOTTOMLEFT", 0, -4)
    GMCC_LookupResultStatus:SetTextColor(0.72, 0.72, 0.72)

    local clearResults = CreateButton(panel, nil, "Clear", 70, 22)
    clearResults:SetPoint("LEFT", GMCC_LookupResultStatus, "RIGHT", 16, 0)
    clearResults:SetScript("OnClick", function()
        ClearLookupResults()
    end)

    for i = 1, 8 do
        local line = CreateLabel(panel, nil, "", "small")
        if i == 1 then
            line:SetPoint("TOPLEFT", GMCC_LookupResultStatus, "BOTTOMLEFT", 0, -8)
        else
            line:SetPoint("TOPLEFT", state.lookupResultLines[i - 1], "BOTTOMLEFT", 0, -3)
        end
        line:SetWidth(500)
        line:SetTextColor(0.9, 0.9, 0.9)
        state.lookupResultLines[i] = line

        local learn = CreateButton(panel, nil, "Learn", 88, 20)
        learn:SetPoint("LEFT", line, "RIGHT", 10, 0)
        learn:SetScript("OnClick", function(self)
            if self.spellId then
                RunCommand(".learn " .. self.spellId)
            end
        end)
        learn:Hide()
        state.lookupResultButtons[i] = learn
    end

    local quickLabel = CreateLabel(panel, nil, "Quick actions", "large")
    quickLabel:SetPoint("TOPLEFT", 2, -390)
    for i, action in ipairs(GMCC_QUICK_ACTIONS) do
        local button = CreateButton(panel, nil, action.label, 88, 24)
        local col = math.mod(i - 1, 6)
        local row = math.floor((i - 1) / 6)
        button:SetPoint("TOPLEFT", 2 + (col * 94), -418 - (row * 30))
        button:SetScript("OnClick", function()
            RunCommand(action.command)
        end)
    end

    panel:Hide()
end

local function BuildFrame()
    local frame = CreateFrame("Frame", "GMCommandCenterFrame", UIParent)
    frame:SetWidth(680)
    frame:SetHeight(620)
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
    GMCC_CommandsTab:SetScript("OnClick", function() SetTab("commands") end)

    GMCC_LookupsTab = CreateButton(frame, "GMCC_LookupsTab", "Lookups", 92, 24)
    GMCC_LookupsTab:SetPoint("LEFT", GMCC_CommandsTab, "RIGHT", 8, 0)
    GMCC_LookupsTab:SetScript("OnClick", function() SetTab("lookups") end)

    BuildCommandsPanel(frame)
    BuildLookupPanel(frame)
    SetTab("commands")
    RefreshCommandRows()
    SelectCommand(GMCC_COMMANDS[1])

    return frame
end

SLASH_GMCOMMANDCENTER1 = "/gmcc"
SLASH_GMCOMMANDCENTER2 = "/agm"
SlashCmdList["GMCOMMANDCENTER"] = ToggleMainFrame

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, arg1)
    if event == "CHAT_MSG_SYSTEM" then
        CaptureLookupResult(arg1)
        return
    end

    if arg1 ~= ADDON then
        return
    end

    GMCommandCenterDB = GMCommandCenterDB or {}
    BuildFrame()
    loader:RegisterEvent("CHAT_MSG_SYSTEM")
    Print("loaded. Type /gmcc or /agm.")
end)
loader:SetScript("OnUpdate", function()
    if state.lookupCaptureUntil > 0 and GetTime() > state.lookupCaptureUntil then
        state.lookupCaptureUntil = 0
        if table.getn(state.lookupResults) == 0 then
            state.lookupStatus = "No lookup results captured. Check the chat window for server output."
            RefreshLookupResults()
        end
    end
end)
