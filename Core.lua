local addonName, ns = ...

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, loadedName)
    if event == "ADDON_LOADED" then
        if loadedName ~= addonName then return end
        if type(_G.ElvUIToEllesmereDB) ~= "table" then _G.ElvUIToEllesmereDB = {} end
        local source = ns.GetSourceInfo and ns.GetSourceInfo()
        if source and _G.EllesmereUI and _G.EllesmereUI.RegisterExternalInstaller
            and not _G.ElvUIToEllesmereDB.completed then
            _G.EllesmereUI.RegisterExternalInstaller("ElvUI to EllesmereUI")
        end
        return
    end

    self:UnregisterEvent("PLAYER_LOGIN")
    local db = _G.ElvUIToEllesmereDB or {}
    if not db.completed and ns.GetSourceInfo and ns.GetSourceInfo() then
        C_Timer.After(0.2, function()
            if ns.UI then ns.UI:Show() end
        end)
    end
end)

SLASH_ELVUITOELLESMERE1 = "/e2eui"
SLASH_ELVUITOELLESMERE2 = "/elvtoeui"
SLASH_ELVUITOELLESMERE3 = "/e2e"
SlashCmdList.ELVUITOELLESMERE = function()
    if ns.UI then ns.UI:Toggle() end
end

function _G.ElvUIToEllesmere_Open()
    if ns.UI then ns.UI:Toggle() end
end
