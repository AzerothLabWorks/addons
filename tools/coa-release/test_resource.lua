assert(_VERSION == "Lua 5.1")
local frames, values, maxima = {}, {[0]=80,[1]=250,[3]=40}, {[0]=100,[1]=1000,[3]=100}
local env = setmetatable({SlashCmdList = {}, COAResourceMonitorDB = nil}, {__index=_G})
env.UIParent = {}
env.UnitHealth = function() return 75 end
env.UnitHealthMax = function() return 100 end
env.UnitPower = function(_, kind) return values[kind] end
env.UnitPowerMax = function(_, kind) return maxima[kind] end
env.print = function() end
env.CreateFrame = function(kind)
    local f = {kind=kind,scripts={},events={}}
    function f:SetScript(name, fn) self.scripts[name]=fn end
    function f:RegisterEvent(name) self.events[name]=true end
    function f:SetMinMaxValues(a,b) self.minimum,self.maximum=a,b end
    function f:SetValue(value) self.value=value end
    function f:SetText(value) self.text=value end
    function f:SetPoint(...) self.point={...} end
    function f:GetPoint() return 'CENTER',env.UIParent,'CENTER',12,34 end
    function f:EnableMouse(value) self.mouse=value end
    for _, name in ipairs({'SetWidth','SetHeight','SetClampedToScreen','SetMovable','RegisterForDrag',
        'SetAllPoints','SetTexture','SetBackdrop','SetBackdropBorderColor','SetStatusBarTexture',
        'SetStatusBarColor','SetTextColor','ClearAllPoints','StartMoving','StopMovingOrSizing'}) do f[name]=function() end end
    function f:CreateTexture() return env.CreateFrame('Texture') end
    function f:CreateFontString() return env.CreateFrame('Font') end
    frames[#frames+1]=f
    return f
end
local chunk = assert(loadfile(arg[1] .. '/COAResourceMonitor.lua'))
setfenv(chunk, env)
chunk('COAResourceMonitor')
local monitor = frames[1]
monitor.scripts.OnEvent(monitor,'ADDON_LOADED','COAResourceMonitor')
assert(#monitor.bars==4)
assert(monitor.bars[1].valueText.text=='75 / 100')
assert(monitor.bars[2].valueText.text=='80 / 100')
assert(monitor.bars[3].valueText.text=='25.0 / 100.0')
assert(monitor.bars[4].valueText.text=='40 / 100')
values[3]=70
monitor.scripts.OnUpdate(nil,0.05)
assert(monitor.bars[4].value==40)
monitor.scripts.OnUpdate(nil,0.05)
assert(monitor.bars[4].value==70)
maxima[1]=0
monitor.scripts.OnEvent(monitor,'UNIT_RAGE','player')
assert(monitor.bars[3].maximum==1000)
env.SlashCmdList.COARESMON('lock')
assert(env.COAResourceMonitorDB.locked and not monitor.mouse)
env.SlashCmdList.COARESMON('unlock')
assert(not env.COAResourceMonitorDB.locked and monitor.mouse)
monitor.scripts.OnDragStop(monitor)
assert(env.COAResourceMonitorDB.x==12 and env.COAResourceMonitorDB.y==34)
env.SlashCmdList.COARESMON('reset')
assert(env.COAResourceMonitorDB.x==0 and env.COAResourceMonitorDB.y==-235)
print('RESOURCE TESTS PASSED: four resource values, rage units, zero maximum, bounded refresh, lock and position')
