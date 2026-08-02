local createdFrames = {}
local methods = {}
local objectMeta = {
    __index = function(_, key)
        return methods[key] or function() end
    end,
}

local function object(parent)
    return setmetatable({ _shown = false, _text = "", _width = 100, _height = 30, _parent = parent }, objectMeta)
end

function methods:SetSize(width, height) self._width, self._height = width, height end
function methods:SetWidth(width) self._width = width end
function methods:SetHeight(height) self._height = height end
function methods:GetWidth() return self._width end
function methods:GetHeight() return self._height end
function methods:GetEffectiveScale() return 1 end
function methods:GetCenter() return 960, 540 end
function methods:SetText(text) self._text = tostring(text or "") end
function methods:GetText() return self._text end
function methods:SetShown(shown) self._shown = shown and true or false end
function methods:IsShown() return self._shown end
function methods:Show()
    local wasShown = self._shown
    self._shown = true
    if not wasShown then
        local scripts = rawget(self, "_scripts")
        if scripts and scripts.OnShow then scripts.OnShow(self) end
    end
end
function methods:Hide() self._shown = false end
function methods:SetScript(script, callback)
    local scripts = rawget(self, "_scripts")
    if not scripts then scripts = {}; rawset(self, "_scripts", scripts) end
    scripts[script] = callback
end
function methods:GetScript(script)
    local scripts = rawget(self, "_scripts")
    return scripts and scripts[script]
end
function methods:CreateTexture() return object(self) end
function methods:CreateFontString() return object(self) end
function methods:SetEnabled(enabled) self._enabled = enabled and true or false end
function methods:IsEnabled() return self._enabled end
function methods:EnableMouse(enabled) self._mouse = enabled end
function methods:Raise() self._raised = true end

UIParent = object(nil)
UIParent:SetSize(1920, 1080)
function CreateFrame(_, name, parent)
    local frame = object(parent or UIParent)
    frame._name = name
    createdFrames[#createdFrames + 1] = frame
    if name then _G[name] = frame end
    return frame
end

GameTooltip = object(UIParent)
C_AddOns = {
    DisableAddOn = function(name) _G.__disabledAddon = name end,
}
C_Timer = { After = function(_, callback) callback() end }
SlashCmdList = {}
function InCombatLockdown() return false end
function ReloadUI() _G.__reloaded = true end

ElvUI = {
    {
        db = { general = {}, unitframe = { units = {} }, actionbar = {}, movers = {} },
        data = { keys = { profile = "Load Smoke" } },
    },
}
EllesmereUIDB = { activeProfile = "Default", profileOrder = { "Default" }, profiles = { Default = { addons = {} } } }
EllesmereUI = {
    GetFontPath = function() return "Fonts\\FRIZQT__.TTF" end,
    RegisterExternalInstaller = function(name) _G.__installer = name end,
    GetProfilesDB = function() return EllesmereUIDB end,
    SaveCurrentAsProfile = function(name)
        EllesmereUIDB.profiles[name] = { addons = {} }
        EllesmereUIDB.activeProfile = name
    end,
}

local tocFiles = {}
local metadata = {}
for line in io.lines("ElvUI_to_EllesmeresUI.toc") do
    local key, value = line:match("^## ([^:]+):%s*(.+)$")
    if key then
        metadata[key] = value
    elseif line:match("%.lua%s*$") then
        tocFiles[#tocFiles + 1] = line:match("^%s*(.-)%s*$")
    end
end
assert(metadata.Interface:find("120000", 1, true))
assert(metadata.Dependencies == "EllesmereUI")
assert(metadata.OptionalDeps:find("ElvUI", 1, true))
assert(metadata.SavedVariables == "ElvUIToEllesmereDB")
assert(metadata.AddonCompartmentFunc == "ElvUIToEllesmere_Open")
assert(table.concat(tocFiles, ",") == "Migration.lua,UI.lua,Core.lua")

local ns = {}
for _, file in ipairs(tocFiles) do
    assert(loadfile(file))("ElvUI_to_EllesmeresUI", ns)
end
assert(type(ns.RunMigration) == "function")
assert(type(ns.UI) == "table")
assert(type(ElvUIToEllesmere_Open) == "function")
assert(type(SlashCmdList.ELVUITOELLESMERE) == "function")
assert(SLASH_ELVUITOELLESMERE3 == "/e2e")

local eventFrame = createdFrames[1]
local onEvent = assert(eventFrame:GetScript("OnEvent"))
onEvent(eventFrame, "ADDON_LOADED", "ElvUI_to_EllesmeresUI")
assert(type(ElvUIToEllesmereDB) == "table")
assert(__installer == "ElvUI to EllesmereUI")
onEvent(eventFrame, "PLAYER_LOGIN")
local menu = assert(ns.UI.frame)
assert(menu:IsShown())
assert(menu._sourceValue:GetText() == "Load Smoke", menu._sourceValue:GetText())
assert(menu._nameBox:GetText() == "ElvUI - Load Smoke")
assert(menu._migrate._enabled == true)

for _, check in ipairs(menu._checks) do check:SetCheckedVisual(false) end
menu._checks[1]:SetCheckedVisual(true)
local uiTimers = {}
C_Timer.After = function(_, callback) uiTimers[#uiTimers + 1] = callback end
menu._migrate:GetScript("OnClick")(menu._migrate)
assert(menu._migrationBusy == true)
assert(menu._progress:IsShown())
assert(menu._progressValue == 0 and menu._progressPercent:GetText() == "0%")
assert(menu._migrate:IsEnabled() == false)
assert(menu._checks[1]:IsEnabled() == false)
assert(#uiTimers == 1)

table.remove(uiTimers, 1)()
assert(menu._progressLabel:GetText():find("Copying", 1, true))
while #uiTimers > 0 do table.remove(uiTimers, 1)() end

assert(menu._migrationComplete == true)
assert(menu._progressValue == menu._progressTotal)
assert(menu._progressPercent:GetText() == "100%")
assert(menu._migrate:IsEnabled() == true)
assert(menu._disableCheck:IsEnabled() == true)
assert(menu._checks[1]:IsEnabled() == false)

SlashCmdList.ELVUITOELLESMERE()
assert(menu:IsShown() == false)
ElvUIToEllesmere_Open()
assert(menu:IsShown() == true)

local noSourceNS = { GetSourceInfo = function() return nil end }
local noSourceStart = #createdFrames
__installer = nil
ElvUIToEllesmereDB = {}
assert(loadfile("Core.lua"))("ElvUI_to_EllesmeresUI", noSourceNS)
local noSourceFrame = assert(createdFrames[noSourceStart + 1])
noSourceFrame:GetScript("OnEvent")(noSourceFrame, "ADDON_LOADED", "ElvUI_to_EllesmeresUI")
assert(__installer == nil)

print("addon load smoke passed: metadata, load order, menu, slash command, compartment")
