local ADDON = "GMCommandCenter_Legion"
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

-- Legion mounts are loaded from the client Mount Journal at runtime. This keeps
-- the browser aligned with build 7.3.5.26365 and avoids WotLK-only spell data.
local legionMountSpells

local function GetLegionMountSpells()
    if legionMountSpells then
        return legionMountSpells
    end

    legionMountSpells = {}
    if not C_MountJournal or not C_MountJournal.GetMountIDs or not C_MountJournal.GetMountInfoByID then
        return legionMountSpells
    end

    local mountIDs = C_MountJournal.GetMountIDs() or {}
    for _, mountID in ipairs(mountIDs) do
        local name, spellID, icon, _, _, _, favorite, _, collected = C_MountJournal.GetMountInfoByID(mountID)
        if name and spellID then
            table.insert(legionMountSpells, {
                id = spellID,
                mountID = mountID,
                name = name,
                icon = icon,
                speed = collected and "Collected" or "Not collected",
                movement = favorite and "Favorite" or "Mount Journal",
                level = 1,
                collected = collected,
            })
        end
    end

    table.sort(legionMountSpells, function(a, b)
        if a.name == b.name then
            return a.id < b.id
        end
        return a.name < b.name
    end)
    return legionMountSpells
end

-- Legion exposes its canonical heirloom catalog through the Heirloom
-- Collection API. Building this list at runtime avoids WotLK-only, obsolete,
-- and test records that merely share the old heirloom item quality.
local legionHeirloomItems

local function GetLegionHeirloomItems()
    if legionHeirloomItems then
        return legionHeirloomItems
    end
    if not C_Heirloom or not C_Heirloom.GetHeirloomItemIDs or not C_Heirloom.GetHeirloomInfo then
        return nil
    end

    legionHeirloomItems = {}
    local itemIDs = C_Heirloom.GetHeirloomItemIDs() or {}
    for _, itemID in ipairs(itemIDs) do
        local name, itemEquipLoc, isPvP, itemTexture, upgradeLevel, _, _, _, minLevel, maxLevel = C_Heirloom.GetHeirloomInfo(itemID)
        if name then
            local _, itemType, itemSubtype, instantEquipLoc, instantTexture
            if GetItemInfoInstant then
                _, itemType, itemSubtype, instantEquipLoc, instantTexture = GetItemInfoInstant(itemID)
            end
            if not itemType then
                _, _, _, _, _, itemType, itemSubtype, _, instantEquipLoc, instantTexture = GetItemInfo(itemID)
            end
            local collected = C_Heirloom.PlayerHasHeirloom and C_Heirloom.PlayerHasHeirloom(itemID)
            table.insert(legionHeirloomItems, {
                id = itemID,
                name = name,
                icon = itemTexture or instantTexture,
                type = itemType or "Heirloom",
                subtype = itemSubtype or "Heirloom",
                slot = _G[itemEquipLoc or instantEquipLoc or ""] or itemEquipLoc or instantEquipLoc or "Other",
                pvp = isPvP,
                collected = collected,
                upgradeLevel = upgradeLevel or 0,
                minLevel = minLevel or 1,
                maxLevel = maxLevel or 110,
            })
        end
    end

    table.sort(legionHeirloomItems, function(a, b)
        if a.name == b.name then
            return a.id < b.id
        end
        return a.name < b.name
    end)
    return legionHeirloomItems
end
local ResetCommandScroll

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99LGMCC|r " .. tostring(message))
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
    GMCommandCenterLegionDB = GMCommandCenterLegionDB or {}
    GMCommandCenterLegionDB.lastCommand = command
end

local function SaveLauncherPosition(button)
    GMCommandCenterLegionDB = GMCommandCenterLegionDB or {}
    GMCommandCenterLegionDB.launcher = GMCommandCenterLegionDB.launcher or {}

    local x, y = button:GetCenter()
    local centerX, centerY = UIParent:GetCenter()

    GMCommandCenterLegionDB.launcher.x = (x or centerX) - centerX
    GMCommandCenterLegionDB.launcher.y = (y or centerY) - centerY
end

local function PositionLauncherButton(button)
    local launcher = GMCommandCenterLegionDB and GMCommandCenterLegionDB.launcher
    button:ClearAllPoints()
    if launcher and launcher.x and launcher.y then
        button:SetPoint("CENTER", UIParent, "CENTER", launcher.x, launcher.y)
    else
        button:SetPoint("CENTER", UIParent, "CENTER", 390, -175)
    end
end

local function ResetLauncherButton(button)
    GMCommandCenterLegionDB = GMCommandCenterLegionDB or {}
    GMCommandCenterLegionDB.launcher = nil
    button:ClearAllPoints()
    button:SetPoint("CENTER", UIParent, "CENTER", 390, -175)
end

local function ToggleMainFrame(text)
    text = Trim(text)
    if text ~= "" then
        state.filter = text
        if LGMCC_FilterBox then
            ResetCommandScroll()
            LGMCC_FilterBox:SetText(text)
        end
    end

    if not GMCommandCenter_LegionFrame then
        Print("UI is still loading. Try /reload, then /lgmcc.")
        return
    end

    if GMCommandCenter_LegionFrame:IsShown() then
        GMCommandCenter_LegionFrame:Hide()
    else
        GMCommandCenter_LegionFrame:Show()
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
    for _, entry in ipairs(LGMCC_COMMANDS) do
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
    if LGMCC_MountStatus then
        LGMCC_MountStatus:Hide()
    end
    if LGMCC_MountPrev then
        LGMCC_MountPrev:Hide()
    end
    if LGMCC_MountNext then
        LGMCC_MountNext:Hide()
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
        .. (entry.faction or "") .. " " .. (entry.collected and "Collected" or "Not collected")
    return WildcardMatch(haystack, needle)
end

local function GetBrowserData()
    if state.browserType == "heirlooms" then
        return GetLegionHeirloomItems()
    end
    return GetLegionMountSpells()
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
        local collectionState = entry.collected and "Collected" or "Not collected"
        return entry.id .. " - " .. entry.name .. " | " .. entry.slot .. " | " .. entry.subtype
            .. " | " .. collectionState .. " | lvl " .. entry.minLevel .. "-" .. entry.maxLevel
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
    if LGMCC_MountStatus then
        if total > 0 then
            LGMCC_MountStatus:SetText("Showing " .. startIndex .. "-" .. endIndex .. " of " .. total .. " " .. noun .. ".")
        elseif not hasBrowserData then
            if state.browserType == "heirlooms" then
                LGMCC_MountStatus:SetText("The Legion Heirloom Collection API is unavailable.")
            else
                LGMCC_MountStatus:SetText("The Legion Mount Journal API is unavailable.")
            end
        else
            LGMCC_MountStatus:SetText("No " .. noun .. " match this filter.")
        end
        LGMCC_MountStatus:Show()
    end
    if LGMCC_MountPrev then
        if state.mountPage > 1 then
            LGMCC_MountPrev:Show()
        else
            LGMCC_MountPrev:Hide()
        end
    end
    if LGMCC_MountNext then
        if state.mountPage < maxPage then
            LGMCC_MountNext:Show()
        else
            LGMCC_MountNext:Hide()
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
                if type(entry.icon) == "number" then
                    row.icon:SetTexture(entry.icon)
                else
                    row.icon:SetTexture("Interface\\Icons\\" .. entry.icon)
                end
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
    legionMountSpells = nil
    state.mountMode = true
    state.browserType = "mounts"
    state.mountPage = 1
    state.selected = nil
    state.filter = ""
    SetCommandControlsShown(false)
    if LGMCC_FilterBox and LGMCC_FilterBox:GetText() ~= "" then
        LGMCC_FilterBox:SetText("")
    end

    LGMCC_TitleText:SetText("Legion Mounts")
    LGMCC_MetaText:SetText("Live 7.3.5 Mount Journal")
    LGMCC_SyntaxText:SetText(".learn <spellId>")
    LGMCC_HelpText:SetText("Browse every mount known to this Legion client. Search by name, spell ID, Collected, Not collected, or Favorite, then click Learn.")
    SetEditBoxText(LGMCC_CommandBox, "")
    SetEditBoxText(LGMCC_ArgsBox, "")
    RefreshMountRows()
end

local function ShowHeirloomBrowser()
    legionHeirloomItems = nil
    state.mountMode = true
    state.browserType = "heirlooms"
    state.mountPage = 1
    state.selected = nil
    state.filter = ""
    SetCommandControlsShown(false)
    if LGMCC_FilterBox and LGMCC_FilterBox:GetText() ~= "" then
        LGMCC_FilterBox:SetText("")
    end

    LGMCC_TitleText:SetText("Heirloom Items")
    LGMCC_MetaText:SetText("Live 7.3.5 Heirloom Collection")
    LGMCC_SyntaxText:SetText(".additem <itemId> 1")
    LGMCC_HelpText:SetText("Browse the heirlooms defined by this Legion client. Search by name, item ID, slot, armor or weapon type, Collected, or Not collected, then click Add.")
    SetEditBoxText(LGMCC_CommandBox, "")
    SetEditBoxText(LGMCC_ArgsBox, "")
    RefreshMountRows()
end

local function SelectCommand(entry)
    HideMountRows()
    SetCommandControlsShown(true)
    state.selected = entry
    LGMCC_TitleText:SetText(entry.name)
    LGMCC_MetaText:SetText(entry.cat .. "   Security " .. entry.sec)
    LGMCC_SyntaxText:SetText(entry.syntax)
    LGMCC_HelpText:SetText(entry.help)
    SetEditBoxText(LGMCC_CommandBox, BuildCommand(entry, ""))
    SetEditBoxText(LGMCC_ArgsBox, entry.args or "")
end

local function RefreshCommandRows()
    local commands = FilterCommands()
    local offset = FauxScrollFrame_GetOffset(LGMCC_CommandScroll)

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

    FauxScrollFrame_Update(LGMCC_CommandScroll, table.getn(commands), ROWS, 24)
    LGMCC_CountText:SetText(table.getn(commands) .. " commands")
end

ResetCommandScroll = function()
    if LGMCC_CommandScroll then
        LGMCC_CommandScroll.offset = 0
        if LGMCC_CommandScrollScrollBar then
            LGMCC_CommandScrollScrollBar:SetValue(0)
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
    local panel = CreateFrame("Frame", "LGMCC_CommandPanel", parent)
    panel:SetPoint("TOPLEFT", 16, -72)
    panel:SetPoint("BOTTOMRIGHT", -16, 16)

    LGMCC_FilterBox = CreateEditBox(panel, "LGMCC_FilterBox", 210, 24)
    LGMCC_FilterBox:SetPoint("TOPLEFT", 2, -2)
    LGMCC_FilterBox:SetScript("OnTextChanged", function(self)
        state.filter = self:GetText() or ""
        ResetCommandScroll()
        RefreshCommandRows()
        state.mountPage = 1
        RefreshMountRows()
    end)

    LGMCC_CountText = CreateLabel(panel, "LGMCC_CountText", "", "small")
    LGMCC_CountText:SetPoint("LEFT", LGMCC_FilterBox, "RIGHT", 14, 0)

    local lastButton
    for i, cat in ipairs(categories) do
        local button = CreateButton(panel, "LGMCC_Cat" .. i, cat, 70, 22)
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

    LGMCC_CommandScroll = CreateFrame("ScrollFrame", "LGMCC_CommandScroll", listFrame, "FauxScrollFrameTemplate")
    LGMCC_CommandScroll:SetPoint("TOPLEFT", 0, -2)
    LGMCC_CommandScroll:SetPoint("BOTTOMRIGHT", -28, 2)
    LGMCC_CommandScroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, 24, RefreshCommandRows)
    end)

    for i = 1, ROWS do
        local row = CreateFrame("Button", "LGMCC_CommandRow" .. i, listFrame)
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

    LGMCC_TitleText = CreateLabel(panel, "LGMCC_TitleText", "Select a command", "large")
    LGMCC_TitleText:SetPoint("TOPLEFT", 282, -90)
    LGMCC_MetaText = CreateLabel(panel, "LGMCC_MetaText", "", "small")
    LGMCC_MetaText:SetPoint("TOPLEFT", LGMCC_TitleText, "BOTTOMLEFT", 0, -4)
    LGMCC_SyntaxText = CreateLabel(panel, "LGMCC_SyntaxText", "", "small")
    LGMCC_SyntaxText:SetPoint("TOPLEFT", LGMCC_MetaText, "BOTTOMLEFT", 0, -12)
    LGMCC_SyntaxText:SetWidth(360)
    LGMCC_SyntaxText:SetTextColor(1.0, 0.82, 0.0)
    LGMCC_HelpText = CreateLabel(panel, "LGMCC_HelpText", "", "small")
    LGMCC_HelpText:SetPoint("TOPLEFT", LGMCC_SyntaxText, "BOTTOMLEFT", 0, -12)
    LGMCC_HelpText:SetWidth(360)
    LGMCC_HelpText:SetHeight(82)

    local argsLabel = CreateLabel(panel, nil, "Arguments", "small")
    argsLabel:SetPoint("TOPLEFT", 282, -250)
    LGMCC_ArgsBox = CreateEditBox(panel, "LGMCC_ArgsBox", 330, 24)
    LGMCC_ArgsBox:SetPoint("TOPLEFT", argsLabel, "BOTTOMLEFT", 0, -4)
    LGMCC_ArgsBox:SetScript("OnTextChanged", function(self)
        if state.selected then
            SetEditBoxText(LGMCC_CommandBox, BuildCommand(state.selected, self:GetText()))
        end
    end)

    local commandLabel = CreateLabel(panel, nil, "Command", "small")
    commandLabel:SetPoint("TOPLEFT", LGMCC_ArgsBox, "BOTTOMLEFT", 0, -12)
    LGMCC_CommandBox = CreateEditBox(panel, "LGMCC_CommandBox", 330, 24)
    LGMCC_CommandBox:SetPoint("TOPLEFT", commandLabel, "BOTTOMLEFT", 0, -4)

    local run = CreateButton(panel, nil, "Run", 82, 24)
    run:SetPoint("TOPLEFT", LGMCC_CommandBox, "BOTTOMLEFT", 0, -10)
    run:SetScript("OnClick", function()
        RunCommand(LGMCC_CommandBox:GetText())
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
        if GMCommandCenterLegionDB and GMCommandCenterLegionDB.lastCommand then
            SetEditBoxText(LGMCC_CommandBox, GMCommandCenterLegionDB.lastCommand)
        end
    end)

    table.insert(state.commandDetailControls, argsLabel)
    table.insert(state.commandDetailControls, LGMCC_ArgsBox)
    table.insert(state.commandDetailControls, commandLabel)
    table.insert(state.commandDetailControls, LGMCC_CommandBox)
    table.insert(state.commandDetailControls, run)
    table.insert(state.commandDetailControls, help)
    table.insert(state.commandDetailControls, last)

    LGMCC_MountStatus = CreateLabel(panel, "LGMCC_MountStatus", "", "small")
    LGMCC_MountStatus:SetPoint("TOPLEFT", 282, -222)
    LGMCC_MountStatus:SetWidth(225)
    LGMCC_MountStatus:Hide()

    LGMCC_MountPrev = CreateButton(panel, "LGMCC_MountPrev", "Prev", 54, 22)
    LGMCC_MountPrev:SetPoint("LEFT", LGMCC_MountStatus, "RIGHT", 8, 0)
    LGMCC_MountPrev:SetScript("OnClick", function()
        state.mountPage = state.mountPage - 1
        RefreshMountRows()
    end)
    LGMCC_MountPrev:Hide()

    LGMCC_MountNext = CreateButton(panel, "LGMCC_MountNext", "Next", 54, 22)
    LGMCC_MountNext:SetPoint("LEFT", LGMCC_MountPrev, "RIGHT", 4, 0)
    LGMCC_MountNext:SetScript("OnClick", function()
        state.mountPage = state.mountPage + 1
        RefreshMountRows()
    end)
    LGMCC_MountNext:Hide()

    for i = 1, MOUNT_ROWS do
        local row = CreateFrame("Frame", "LGMCC_MountRow" .. i, panel)
        row:SetWidth(360)
        row:SetHeight(24)
        row:EnableMouse(true)
        if i == 1 then
            row:SetPoint("TOPLEFT", LGMCC_MountStatus, "BOTTOMLEFT", 0, -8)
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
    local frame = CreateFrame("Frame", "GMCommandCenter_LegionFrame", UIParent)
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

    local title = CreateLabel(frame, nil, "GM Command Center - Legion", "large")
    title:SetPoint("TOPLEFT", 22, -18)

    local close = CreateButton(frame, nil, "X", 24, 22)
    close:SetPoint("TOPRIGHT", -18, -16)
    close:SetScript("OnClick", function() frame:Hide() end)

    LGMCC_CommandsTab = CreateButton(frame, "LGMCC_CommandsTab", "Commands", 92, 24)
    LGMCC_CommandsTab:SetPoint("TOPLEFT", 18, -44)
    LGMCC_CommandsTab:Disable()

    BuildCommandsPanel(frame)
    LGMCC_CommandPanel:Show()
    RefreshCommandRows()
    SelectCommand(LGMCC_COMMANDS[1])

    return frame
end

local function BuildLauncherButton()
    local button = CreateButton(UIParent, "LGMCC_LauncherButton", "LGMCC", 48, 24)
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
        GameTooltip:SetText("GM Command Center - Legion")
        GameTooltip:AddLine("Left-click to open or close.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move. Right-click to reset.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

SLASH_GMCOMMANDCENTERLEGION1 = "/lgmcc"
SLASH_GMCOMMANDCENTERLEGION2 = "/lgm"
SlashCmdList["GMCOMMANDCENTERLEGION"] = ToggleMainFrame

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, arg1)
    if arg1 ~= ADDON then
        return
    end

    GMCommandCenterLegionDB = GMCommandCenterLegionDB or {}
    BuildFrame()
    BuildLauncherButton()
    Print("loaded for Legion 7.3.5. Type /lgmcc or /lgm.")
end)






