local addonName = ...

local defaults = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = -235,
    locked = false,
}

local resources = {
    { key = "health", label = "Health", color = { 0.18, 0.78, 0.24 } },
    { key = "mana",   label = "Mana",   power = 0, color = { 0.15, 0.42, 1.00 } },
    { key = "rage",   label = "Rage",   power = 1, color = { 0.90, 0.12, 0.12 } },
    { key = "energy", label = "Energy", power = 3, color = { 0.95, 0.82, 0.16 } },
}

local frame = CreateFrame("Frame", "COAResourceMonitorFrame", UIParent)
frame:SetWidth(270)
frame:SetHeight(92)
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

local background = frame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints(frame)
background:SetTexture(0, 0, 0, 0.58)

local border = CreateFrame("Frame", nil, frame)
border:SetPoint("TOPLEFT", -1, 1)
border:SetPoint("BOTTOMRIGHT", 1, -1)
border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
})
border:SetBackdropBorderColor(0.45, 0.45, 0.45, 0.9)

frame.bars = {}

local function FormatValue(resource, value, maximum)
    if resource.key == "rage" and maximum > 100 then
        return string.format("%.1f / %.1f", value / 10, maximum / 10)
    end
    return string.format("%d / %d", value, maximum)
end

local function CreateResourceBar(resource, index)
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(resource.color[1], resource.color[2], resource.color[3])
    bar:SetPoint("TOPLEFT", 5, -5 - ((index - 1) * 21))
    bar:SetPoint("TOPRIGHT", -5, -5 - ((index - 1) * 21))
    bar:SetHeight(18)
    bar:SetMinMaxValues(0, 1)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetTexture(resource.color[1] * 0.22, resource.color[2] * 0.22, resource.color[3] * 0.22, 0.9)

    local label = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", 5, 0)
    label:SetText(resource.label)
    label:SetTextColor(1, 1, 1)

    local value = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    value:SetPoint("RIGHT", -5, 0)

    bar.resource = resource
    bar.valueText = value
    frame.bars[index] = bar
end

for index, resource in ipairs(resources) do
    CreateResourceBar(resource, index)
end

local function UpdateBar(bar)
    local resource = bar.resource
    local value, maximum
    if resource.key == "health" then
        value = UnitHealth("player") or 0
        maximum = UnitHealthMax("player") or 0
    else
        value = UnitPower("player", resource.power) or 0
        maximum = UnitPowerMax("player", resource.power) or 0
    end

    -- Some custom classes report a zero maximum until the resource is first
    -- generated. Keep the resource visible so that transition can be observed.
    if maximum <= 0 then
        maximum = resource.key == "rage" and 1000 or 100
    end
    if value < 0 then value = 0 end
    if value > maximum then maximum = value end

    bar:SetMinMaxValues(0, maximum)
    bar:SetValue(value)
    bar.valueText:SetText(FormatValue(resource, value, maximum))
end

local function UpdateAll()
    for _, bar in ipairs(frame.bars) do
        UpdateBar(bar)
    end
end

local function ApplyPosition()
    frame:ClearAllPoints()
    frame:SetPoint(
        COAResourceMonitorDB.point,
        UIParent,
        COAResourceMonitorDB.relativePoint,
        COAResourceMonitorDB.x,
        COAResourceMonitorDB.y
    )
end

local function ApplyLockState()
    frame:EnableMouse(not COAResourceMonitorDB.locked)
    border:SetBackdropBorderColor(
        COAResourceMonitorDB.locked and 0.2 or 0.65,
        COAResourceMonitorDB.locked and 0.2 or 0.65,
        COAResourceMonitorDB.locked and 0.2 or 0.65,
        COAResourceMonitorDB.locked and 0.45 or 0.95
    )
end

frame:SetScript("OnDragStart", function(self)
    if not COAResourceMonitorDB.locked then
        self:StartMoving()
    end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint(1)
    COAResourceMonitorDB.point = point
    COAResourceMonitorDB.relativePoint = relativePoint
    COAResourceMonitorDB.x = x
    COAResourceMonitorDB.y = y
end)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("UNIT_MAXHEALTH")
frame:RegisterEvent("UNIT_MANA")
frame:RegisterEvent("UNIT_MAXMANA")
frame:RegisterEvent("UNIT_RAGE")
frame:RegisterEvent("UNIT_MAXRAGE")
frame:RegisterEvent("UNIT_ENERGY")
frame:RegisterEvent("UNIT_MAXENERGY")
frame:RegisterEvent("UNIT_DISPLAYPOWER")

frame:SetScript("OnEvent", function(self, event, unit)
    if event == "ADDON_LOADED" then
        if unit ~= addonName then return end
        COAResourceMonitorDB = COAResourceMonitorDB or {}
        for key, value in pairs(defaults) do
            if COAResourceMonitorDB[key] == nil then
                COAResourceMonitorDB[key] = value
            end
        end
        ApplyPosition()
        ApplyLockState()
        UpdateAll()
        return
    end
    if unit and unit ~= "player" then return end
    UpdateAll()
end)

local elapsed = 0
frame:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.10 then
        elapsed = 0
        UpdateAll()
    end
end)

SLASH_COARESMON1 = "/crm"
SlashCmdList.COARESMON = function(message)
    message = string.lower((message or ""):match("^%s*(.-)%s*$"))
    if message == "lock" then
        COAResourceMonitorDB.locked = true
        ApplyLockState()
        print("|cff66ccffCOA Resource Monitor:|r locked")
    elseif message == "unlock" then
        COAResourceMonitorDB.locked = false
        ApplyLockState()
        print("|cff66ccffCOA Resource Monitor:|r unlocked; drag with the left mouse button")
    elseif message == "reset" then
        COAResourceMonitorDB.point = defaults.point
        COAResourceMonitorDB.relativePoint = defaults.relativePoint
        COAResourceMonitorDB.x = defaults.x
        COAResourceMonitorDB.y = defaults.y
        ApplyPosition()
        print("|cff66ccffCOA Resource Monitor:|r position reset")
    else
        print("|cff66ccffCOA Resource Monitor:|r /crm lock, /crm unlock, /crm reset")
    end
end
