local ADDON = "GMCommandCenter"
local ROWS = 13
local state = {
    selected = nil,
    filter = "",
    category = "All",
    tab = "commands",
    rows = {},
    classResults = {},
    classResultLines = {},
    classResultButtons = {},
    classStatusText = nil,
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

local function RunAfter(delay, callback)
    local frame = CreateFrame("Frame")
    local elapsed = 0
    frame:SetScript("OnUpdate", function(self, elapsedArg)
        elapsed = elapsed + (elapsedArg or arg1 or 0)
        if elapsed >= delay then
            self:SetScript("OnUpdate", nil)
            callback()
        end
    end)
end

local function NormalizeClassName(value)
    value = string.lower(Trim(value))
    if value == "dk" or value == "deathknight" or value == "death knight" then
        return "Death Knight"
    end

    local names = { "Warrior", "Paladin", "Hunter", "Rogue", "Priest", "Shaman", "Mage", "Warlock", "Druid" }
    for _, name in ipairs(names) do
        if string.lower(name) == value then
            return name
        end
    end

    if value == "all" or value == "*" or value == "" then
        return "All"
    end

    return nil
end

local function ItemAllowedForClass(item, className)
    if className == "All" then
        return true
    end

    local mask = GMCC_CLASS_MASKS and GMCC_CLASS_MASKS[className]
    if not mask then
        return false
    end

    if item.mask == -1 then
        return true
    end

    if bit and bit.band then
        return bit.band(item.mask, mask) ~= 0
    end

    return math.mod(math.floor(item.mask / mask), 2) == 1
end

local function GetItemLevelFilter()
    if GMCC_UsePlayerLevelCheck and GMCC_UsePlayerLevelCheck:GetChecked() then
        return UnitLevel("player") or 0
    end

    local value = tonumber(Trim(GMCC_ClassLevelBox and GMCC_ClassLevelBox:GetText() or ""))
    if not value or value < 1 then
        return nil
    end

    return math.floor(value)
end

local function ItemAllowedForLevel(item, level)
    if not level then
        return true
    end

    return (tonumber(item.rl) or 0) <= level
end

local function RefreshClassResults()
    if not GMCC_ClassStatus then
        return
    end

    local count = table.getn(state.classResults)
    if count == 0 then
        GMCC_ClassStatus:SetText(state.classStatusText or "No class results yet.")
    else
        GMCC_ClassStatus:SetText(count .. " results")
    end

    for i = 1, 5 do
        local result = state.classResults[i]
        local line = state.classResultLines[i]
        local button = state.classResultButtons[i]
        if line then
            line:SetText(result and result.text or "")
        end
        if button then
            if result then
                button.command = result.command
                button:SetText(result.action)
                button:Show()
            else
                button.command = nil
                button:Hide()
            end
        end
    end
end

local function SearchClassSpells()
    state.classResults = {}
    state.classStatusText = nil
    local className = NormalizeClassName(GMCC_ClassBox and GMCC_ClassBox:GetText() or "")
    if not className then
        state.classStatusText = "Unknown class."
        RefreshClassResults()
        return
    end

    local query = GMCC_ClassSearchBox and GMCC_ClassSearchBox:GetText() or ""
    query = Trim(query)
    if query == "" then
        query = "*"
    end

    for _, spell in ipairs(GMCC_CLASS_SPELLS or {}) do
        if className == "All" or spell.class == className or spell.class == "General" then
            local spellName = GetSpellInfo(spell.id) or ("Spell " .. spell.id)
            if WildcardMatch(spellName, query) or WildcardMatch(tostring(spell.id), query) then
                table.insert(state.classResults, {
                    text = spell.id .. " - " .. spellName .. " | " .. spell.class .. " | req " .. spell.req,
                    action = "Learn",
                    command = ".learn " .. spell.id,
                })
                if table.getn(state.classResults) >= 5 then
                    break
                end
            end
        end
    end
    RefreshClassResults()
end

local function SearchClassItems()
    state.classResults = {}
    state.classStatusText = nil
    local className = NormalizeClassName(GMCC_ClassBox and GMCC_ClassBox:GetText() or "")
    if not className then
        state.classStatusText = "Unknown class."
        RefreshClassResults()
        return
    end

    local level = GetItemLevelFilter()

    local query = GMCC_ClassSearchBox and GMCC_ClassSearchBox:GetText() or ""
    query = Trim(query)
    if query == "" then
        query = "*"
    end

    for _, item in ipairs(GMCC_CLASS_ITEMS or {}) do
        if ItemAllowedForClass(item, className) and ItemAllowedForLevel(item, level) then
            local haystack = item.name .. " " .. item.type .. " " .. item.id
            if WildcardMatch(haystack, query) then
                table.insert(state.classResults, {
                    text = item.id .. " - " .. item.name .. " | " .. item.type .. " | ilvl " .. item.il .. " | req " .. item.rl,
                    action = "Add",
                    command = ".additem " .. item.id .. " 1",
                })
                if table.getn(state.classResults) >= 5 then
                    break
                end
            end
        end
    end
    RefreshClassResults()
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

local function GiveMoney()
    local money = tonumber(Trim(GMCC_MoneyBox and GMCC_MoneyBox:GetText() or ""))
    if not money or money == 0 then
        Print("Enter a #money copper amount first.")
        return
    end

    money = math.floor(money)
    local command = ".modify money " .. money
    if UnitIsPlayer("target") then
        Print("Giving money to selected player: " .. (UnitName("target") or "target"))
        RunCommand(command)
        return
    end

    Print("No player selected; targeting yourself first.")
    TargetUnit("player")
    RunAfter(0.25, function()
        if not UnitIsPlayer("target") then
            Print("No player target found. Select your character or another player and try again.")
            return
        end

        Print("Giving money to selected player: " .. (UnitName("target") or "target"))
        RunCommand(command)
    end)
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

    local moneyLabel = CreateLabel(panel, nil, "Money", "large")
    moneyLabel:SetPoint("TOPLEFT", run, "BOTTOMLEFT", 0, -22)

    local moneyArgLabel = CreateLabel(panel, nil, "#money", "small")
    moneyArgLabel:SetPoint("TOPLEFT", moneyLabel, "BOTTOMLEFT", 0, -6)
    GMCC_MoneyBox = CreateEditBox(panel, "GMCC_MoneyBox", 110, 24)
    GMCC_MoneyBox:SetPoint("TOPLEFT", moneyArgLabel, "BOTTOMLEFT", 0, -4)
    GMCC_MoneyBox:SetText("10000")

    local giveMoney = CreateButton(panel, nil, "Give Money", 110, 24)
    giveMoney:SetPoint("LEFT", GMCC_MoneyBox, "RIGHT", 12, 0)
    giveMoney:SetScript("OnClick", GiveMoney)

    local classLabel = CreateLabel(panel, nil, "Class Search", "large")
    classLabel:SetPoint("TOPLEFT", moneyLabel, "BOTTOMLEFT", 0, -44)

    local classNameLabel = CreateLabel(panel, nil, "Class", "small")
    classNameLabel:SetPoint("TOPLEFT", classLabel, "BOTTOMLEFT", 0, -6)
    GMCC_ClassBox = CreateEditBox(panel, "GMCC_ClassBox", 110, 24)
    GMCC_ClassBox:SetPoint("TOPLEFT", classNameLabel, "BOTTOMLEFT", 0, -4)
    GMCC_ClassBox:SetText("Mage")

    local searchLabel = CreateLabel(panel, nil, "Name or ID", "small")
    searchLabel:SetPoint("LEFT", classNameLabel, "RIGHT", 84, 0)
    GMCC_ClassSearchBox = CreateEditBox(panel, "GMCC_ClassSearchBox", 170, 24)
    GMCC_ClassSearchBox:SetPoint("TOPLEFT", searchLabel, "BOTTOMLEFT", 0, -4)
    GMCC_ClassSearchBox:SetText("*")

    local levelLabel = CreateLabel(panel, nil, "Level", "small")
    levelLabel:SetPoint("LEFT", searchLabel, "RIGHT", 156, 0)
    GMCC_ClassLevelBox = CreateEditBox(panel, "GMCC_ClassLevelBox", 46, 24)
    GMCC_ClassLevelBox:SetPoint("TOPLEFT", levelLabel, "BOTTOMLEFT", 0, -4)
    GMCC_ClassLevelBox:SetText(tostring(UnitLevel("player") or 80))

    GMCC_UsePlayerLevelCheck = CreateFrame("CheckButton", "GMCC_UsePlayerLevelCheck", panel, "UICheckButtonTemplate")
    GMCC_UsePlayerLevelCheck:SetWidth(24)
    GMCC_UsePlayerLevelCheck:SetHeight(24)
    GMCC_UsePlayerLevelCheck:SetPoint("LEFT", GMCC_ClassLevelBox, "RIGHT", 6, 0)
    GMCC_UsePlayerLevelCheck:SetChecked(true)
    GMCC_UsePlayerLevelCheck:SetScript("OnClick", function(self)
        if self:GetChecked() and GMCC_ClassLevelBox then
            GMCC_ClassLevelBox:SetText(tostring(UnitLevel("player") or 80))
        end
    end)
    local useLevelText = CreateLabel(panel, nil, "Use my level", "small")
    useLevelText:SetPoint("LEFT", GMCC_UsePlayerLevelCheck, "RIGHT", 0, 0)

    local spellSearch = CreateButton(panel, nil, "Spells", 72, 24)
    spellSearch:SetPoint("TOPLEFT", GMCC_ClassBox, "BOTTOMLEFT", 0, -8)
    spellSearch:SetScript("OnClick", SearchClassSpells)

    local itemSearch = CreateButton(panel, nil, "Items", 72, 24)
    itemSearch:SetPoint("LEFT", spellSearch, "RIGHT", 8, 0)
    itemSearch:SetScript("OnClick", SearchClassItems)

    GMCC_ClassStatus = CreateLabel(panel, "GMCC_ClassStatus", "No class results yet.", "small")
    GMCC_ClassStatus:SetPoint("LEFT", itemSearch, "RIGHT", 12, 0)
    GMCC_ClassStatus:SetTextColor(0.72, 0.72, 0.72)

    for i = 1, 5 do
        local line = CreateLabel(panel, nil, "", "small")
        if i == 1 then
            line:SetPoint("TOPLEFT", spellSearch, "BOTTOMLEFT", 0, -10)
        else
            line:SetPoint("TOPLEFT", state.classResultLines[i - 1], "BOTTOMLEFT", 0, -3)
        end
        line:SetWidth(270)
        state.classResultLines[i] = line

        local action = CreateButton(panel, nil, "Run", 62, 20)
        action:SetPoint("LEFT", line, "RIGHT", 8, 0)
        action:SetScript("OnClick", function(self)
            if self.command then
                RunCommand(self.command)
            end
        end)
        action:Hide()
        state.classResultButtons[i] = action
    end
end

local function BuildFrame()
    local frame = CreateFrame("Frame", "GMCommandCenterFrame", UIParent)
    frame:SetWidth(680)
    frame:SetHeight(660)
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
    Print("loaded. Type /gmcc or /agm.")
end)

