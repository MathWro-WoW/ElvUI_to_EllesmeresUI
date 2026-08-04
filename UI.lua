local addonName, ns = ...
local floor = math.floor


local UI = {}
ns.UI = UI

local COLORS = {
    ink = { 0.055, 0.071, 0.086, 0.98 },
    panel = { 0.082, 0.102, 0.122, 0.98 },
    line = { 0.20, 0.25, 0.29, 1 },
    muted = { 0.62, 0.68, 0.72, 1 },
    white = { 0.94, 0.97, 0.98, 1 },
    elv = { 0.09, 0.52, 0.82, 1 },
    eui = { 0.047, 0.824, 0.624, 1 },
    error = { 0.94, 0.35, 0.31, 1 },
    warning = { 0.96, 0.72, 0.28, 1 },
}

local function color(texture, value)
    texture:SetColorTexture(value[1], value[2], value[3], value[4])
end

local function fontPath()
    local suite = _G.EllesmereUI
    return suite and suite.GetFontPath and suite.GetFontPath("extras")
        or "Interface\\AddOns\\EllesmereUI\\media\\fonts\\Expressway.TTF"
end

local function makeText(parent, size, value, justify)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont(fontPath(), size, "")
    text:SetTextColor(value[1], value[2], value[3], value[4])
    text:SetJustifyH(justify or "LEFT")
    return text
end

local function makeBackdrop(frame, bg, border)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
end

local function savedDB()
    if type(_G.ElvUIToEllesmereDB) ~= "table" then _G.ElvUIToEllesmereDB = {} end
    local db = _G.ElvUIToEllesmereDB
    if type(db.components) ~= "table" then db.components = {} end
    for _, component in ipairs(ns.Components) do
        if db.components[component.key] == nil then db.components[component.key] = true end
    end
    return db
end

local function makeCheck(parent, x, y, component)
    local button = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    button:SetSize(18, 18)
    button:SetPoint("TOPLEFT", x, y)
    makeBackdrop(button, COLORS.ink, COLORS.line)

    local mark = button:CreateTexture(nil, "ARTWORK")
    mark:SetPoint("TOPLEFT", 4, -4)
    mark:SetPoint("BOTTOMRIGHT", -4, 4)
    color(mark, COLORS.eui)
    button._mark = mark

    local label = makeText(parent, 13, COLORS.white)
    label:SetPoint("TOPLEFT", button, "TOPRIGHT", 9, 1)
    label:SetText(component.label)

    local description = makeText(parent, 10, COLORS.muted)
    description:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
    description:SetWidth(232)
    description:SetText(component.description)
    button._label = label
    button._description = description

    function button:SetCheckedVisual(checked)
        self.checked = checked and true or false
        self._mark:SetShown(self.checked)
        if self.checked then
            self:SetBackdropBorderColor(COLORS.eui[1], COLORS.eui[2], COLORS.eui[3], 0.9)
        else
            self:SetBackdropBorderColor(COLORS.line[1], COLORS.line[2], COLORS.line[3], 1)
        end
    end

    button:SetScript("OnClick", function(self)
        self:SetCheckedVisual(not self.checked)
        savedDB().components[component.key] = self.checked
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(component.label, 1, 1, 1)
        GameTooltip:AddLine(component.description, 0.75, 0.8, 0.84, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetCheckedVisual(savedDB().components[component.key])
    button._component = component
    return button
end

local function setButtonEnabled(button, enabled)
    button:SetEnabled(enabled)
    if enabled then
        button:SetAlpha(1)
        button._label:SetTextColor(COLORS.ink[1], COLORS.ink[2], COLORS.ink[3], 1)
    else
        button:SetAlpha(0.45)
        button._label:SetTextColor(COLORS.muted[1], COLORS.muted[2], COLORS.muted[3], 1)
    end
end

local function makeButton(parent, width, label)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, 34)
    makeBackdrop(button, COLORS.eui, COLORS.eui)
    local text = makeText(button, 12, COLORS.ink, "CENTER")
    text:SetPoint("CENTER", 0, 0)
    text:SetText(label)
    button._label = text
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.92, 0.70, 1)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(COLORS.eui[1], COLORS.eui[2], COLORS.eui[3], 1)
    end)
    return button
end

local function createFrame()
    local frame = CreateFrame("Frame", "ElvUIToEllesmereMigrationFrame", UIParent, "BackdropTemplate")
    frame:SetSize(620, 732)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    frame._migrationBusy = false
    frame._migrationComplete = false
    makeBackdrop(frame, COLORS.ink, COLORS.line)

    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetHeight(3)
    color(accent, COLORS.eui)

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(28, 28)
    close:SetPoint("TOPRIGHT", -12, -12)
    local closeText = makeText(close, 18, COLORS.muted, "CENTER")
    closeText:SetPoint("CENTER")
    closeText:SetText("×")
    close:SetScript("OnClick", function() frame:Hide() end)
    close:SetScript("OnEnter", function() closeText:SetTextColor(1, 1, 1, 1) end)
    close:SetScript("OnLeave", function() closeText:SetTextColor(COLORS.muted[1], COLORS.muted[2], COLORS.muted[3], 1) end)

    local eyebrow = makeText(frame, 10, COLORS.muted)
    eyebrow:SetPoint("TOPLEFT", 28, -24)
    eyebrow:SetText("PROFILE TRANSFER")

    local title = makeText(frame, 22, COLORS.white)
    title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -5)
    title:SetText("Move the layout, not the guesswork")

    local subtitle = makeText(frame, 11, COLORS.muted)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText("Creates a new EllesmereUI profile. Your ElvUI profile is never changed.")

    local rail = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    rail:SetSize(564, 48)
    rail:SetPoint("TOPLEFT", 28, -91)
    makeBackdrop(rail, COLORS.panel, COLORS.line)

    local left = makeText(rail, 13, COLORS.elv)
    left:SetPoint("LEFT", 18, 0)
    left:SetText("ElvUI")
    local right = makeText(rail, 13, COLORS.eui, "RIGHT")
    right:SetPoint("RIGHT", -18, 0)
    right:SetText("EllesmereUI")
    local sourceTrack = rail:CreateTexture(nil, "ARTWORK")
    sourceTrack:SetSize(72, 1)
    sourceTrack:SetPoint("RIGHT", rail, "CENTER", -10, 0)
    sourceTrack:SetColorTexture(COLORS.elv[1], COLORS.elv[2], COLORS.elv[3], 0.65)
    local destinationTrack = rail:CreateTexture(nil, "ARTWORK")
    destinationTrack:SetSize(72, 1)
    destinationTrack:SetPoint("LEFT", rail, "CENTER", 10, 0)
    destinationTrack:SetColorTexture(COLORS.eui[1], COLORS.eui[2], COLORS.eui[3], 0.65)
    local arrow = makeText(rail, 14, COLORS.white, "CENTER")
    arrow:SetPoint("CENTER", 0, 1)
    arrow:SetText(">")

    local sourceLabel = makeText(frame, 10, COLORS.muted)
    sourceLabel:SetPoint("TOPLEFT", 28, -158)
    sourceLabel:SetText("SOURCE PROFILE")
    local sourceValue = makeText(frame, 12, COLORS.white)
    sourceValue:SetPoint("TOPLEFT", sourceLabel, "BOTTOMLEFT", 0, -5)
    sourceValue:SetText("Checking ElvUI…")
    frame._sourceValue = sourceValue

    local nameLabel = makeText(frame, 10, COLORS.muted)
    nameLabel:SetPoint("TOPLEFT", 315, -158)
    nameLabel:SetText("NEW ELLESMEREUI PROFILE")
    local nameBox = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    nameBox:SetSize(277, 30)
    nameBox:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -2)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(48)
    nameBox:SetFont(fontPath(), 12, "")
    nameBox:SetTextInsets(9, 9, 0, 0)
    nameBox:SetTextColor(COLORS.white[1], COLORS.white[2], COLORS.white[3], 1)
    makeBackdrop(nameBox, COLORS.panel, COLORS.line)
    nameBox:SetScript("OnEscapePressed", nameBox.ClearFocus)
    nameBox:SetScript("OnEnterPressed", nameBox.ClearFocus)
    frame._nameBox = nameBox

    local section = makeText(frame, 10, COLORS.muted)
    section:SetPoint("TOPLEFT", 28, -223)
    section:SetText("CHOOSE WHAT TO MIGRATE")

    local all = CreateFrame("Button", nil, frame)
    all:SetSize(65, 20)
    all:SetPoint("TOPRIGHT", -87, -216)
    local allText = makeText(all, 10, COLORS.eui, "CENTER")
    allText:SetPoint("CENTER")
    allText:SetText("Select all")
    local none = CreateFrame("Button", nil, frame)
    none:SetSize(55, 20)
    none:SetPoint("LEFT", all, "RIGHT", 4, 0)
    local noneText = makeText(none, 10, COLORS.muted, "CENTER")
    noneText:SetPoint("CENTER")
    noneText:SetText("Clear")

    frame._checks = {}
    for index, component in ipairs(ns.Components) do
        local column = (index - 1) % 2
        local row = floor((index - 1) / 2)
        local check = makeCheck(frame, 31 + column * 287, -252 - row * 62, component)
        frame._checks[#frame._checks + 1] = check
    end

    local function setAll(value)
        local db = savedDB()
        for _, check in ipairs(frame._checks) do
            check:SetCheckedVisual(value)
            db.components[check._component.key] = value
        end
    end
    all:SetScript("OnClick", function() setAll(true) end)
    none:SetScript("OnClick", function() setAll(false) end)
    frame._all = all
    frame._none = none

    local disable = makeCheck(frame, 31, -562, {
        key = "disableElvUI",
        label = "Disable ElvUI when reloading",
        description = "Optional. Keeps the source profile intact and only disables the ElvUI addon.",
    })
    disable:SetCheckedVisual(savedDB().disableElvUI == true)
    disable:SetScript("OnClick", function(self)
        self:SetCheckedVisual(not self.checked)
        savedDB().disableElvUI = self.checked
    end)
    frame._disableCheck = disable

    local disableSelf = makeCheck(frame, 318, -562, {
        key = "disableSelf",
        label = "Disable this addon when reloading",
        description = "Optional. Re-enable it from the AddOns list to run another migration.",
    })
    disableSelf:SetCheckedVisual(savedDB().disableSelf == true)
    disableSelf:SetScript("OnClick", function(self)
        self:SetCheckedVisual(not self.checked)
        savedDB().disableSelf = self.checked
    end)
    frame._disableSelfCheck = disableSelf

    local progress = CreateFrame("StatusBar", nil, frame, "BackdropTemplate")
    progress:SetSize(564, 24)
    progress:SetPoint("BOTTOMLEFT", 28, 84)
    progress:SetMinMaxValues(0, 1)
    progress:SetValue(0)
    progress:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    progress:SetStatusBarColor(COLORS.eui[1], COLORS.eui[2], COLORS.eui[3], 0.9)
    makeBackdrop(progress, COLORS.panel, COLORS.line)
    progress:Hide()

    local progressLabel = makeText(progress, 10, COLORS.white)
    progressLabel:SetPoint("LEFT", 9, 0)
    local progressPercent = makeText(progress, 10, COLORS.white, "RIGHT")
    progressPercent:SetPoint("RIGHT", -9, 0)
    frame._progress = progress
    frame._progressLabel = progressLabel
    frame._progressPercent = progressPercent

    local status = makeText(frame, 10, COLORS.muted)
    status:SetPoint("BOTTOMLEFT", 28, 24)
    status:SetWidth(390)
    status:SetHeight(42)
    status:SetJustifyV("BOTTOM")
    status:SetText("Ready after both addons finish loading.")
    frame._status = status

    local migrate = makeButton(frame, 164, "Create profile")
    migrate:SetPoint("BOTTOMRIGHT", -28, 24)
    frame._migrate = migrate

    function frame:SetStatus(message, value)
        value = value or COLORS.muted
        self._status:SetTextColor(value[1], value[2], value[3], value[4])
        self._status:SetText(message)
    end

    function frame:SetProgress(completed, total, message)
        total = math.max(1, tonumber(total) or 1)
        completed = math.max(0, math.min(total, tonumber(completed) or 0))
        self._progress:SetMinMaxValues(0, total)
        self._progress:SetValue(completed)
        self._progressLabel:SetText(message or "")
        self._progressPercent:SetText(floor(completed / total * 100 + 0.5) .. "%")
        self._progress:SetStatusBarColor(COLORS.eui[1], COLORS.eui[2], COLORS.eui[3], 0.9)
        self._progress:Show()
        self._progressValue = completed
        self._progressTotal = total
    end

    function frame:RefreshSource()
        if self._migrationBusy or self._migrationComplete then return end
        self._progress:Hide()
        local source, err = ns.GetSourceInfo()
        if not source then
            self._sourceValue:SetText("Not available")
            self._sourceValue:SetTextColor(COLORS.error[1], COLORS.error[2], COLORS.error[3], 1)
            self:SetStatus(err, COLORS.error)
            setButtonEnabled(self._migrate, false)
            return
        end
        self._sourceValue:SetText(source.name)
        self._sourceValue:SetTextColor(COLORS.elv[1], COLORS.elv[2], COLORS.elv[3], 1)
        if self._nameBox:GetText() == "" then
            local suggested = "ElvUI - " .. source.name
            self._nameBox:SetText(suggested:sub(1, 48))
        end
        self:SetStatus("Review the components, then create the new profile.", COLORS.muted)
        setButtonEnabled(self._migrate, true)
    end

    local function setCheckEnabled(check, enabled)
        check:SetEnabled(enabled)
        check:SetAlpha(enabled and 1 or 0.5)
        check._label:SetAlpha(enabled and 1 or 0.5)
        check._description:SetAlpha(enabled and 1 or 0.5)
    end

    function frame:SetBusy(busy)
        self._migrationBusy = busy and true or false
        self._nameBox:EnableMouse(not busy)
        self._nameBox:SetAlpha(busy and 0.55 or 1)
        for _, check in ipairs(self._checks) do setCheckEnabled(check, not busy) end
        setCheckEnabled(self._disableCheck, not busy)
        setCheckEnabled(self._disableSelfCheck, not busy)
        self._all:SetEnabled(not busy)
        self._all:SetAlpha(busy and 0.45 or 1)
        self._none:SetEnabled(not busy)
        self._none:SetAlpha(busy and 0.45 or 1)
        setButtonEnabled(self._migrate, not busy)
        if busy then self._nameBox:ClearFocus() end
    end

    migrate:SetScript("OnClick", function(self)
        if frame._migrationComplete then
            if savedDB().disableElvUI and C_AddOns and C_AddOns.DisableAddOn then
                C_AddOns.DisableAddOn("ElvUI")
            end
            if savedDB().disableSelf and C_AddOns and C_AddOns.DisableAddOn then
                C_AddOns.DisableAddOn(addonName)
            end
            ReloadUI()
            return
        end
        if frame._migrationBusy then return end
        if InCombatLockdown and InCombatLockdown() then
            frame:SetStatus("Leave combat before creating the profile.", COLORS.error)
            return
        end

        local selected = {}
        for _, check in ipairs(frame._checks) do selected[check._component.key] = check.checked end
        frame:SetBusy(true)

        local started, startError = ns.StartMigration(
            frame._nameBox:GetText(),
            selected,
            function(completed, total, message)
                frame:SetProgress(completed, total, message)
                frame:SetStatus("Migration in progress — " .. completed .. " of " .. total .. " steps complete.", COLORS.warning)
            end,
            function(ok, result)
                if not ok then
                    frame:SetBusy(false)
                    frame._progressLabel:SetText("Migration stopped")
                    frame._progress:SetStatusBarColor(COLORS.error[1], COLORS.error[2], COLORS.error[3], 0.9)
                    frame:SetStatus(result, COLORS.error)
                    return
                end

                savedDB().completed = true
                savedDB().lastProfile = result.profileName
                frame._migrationBusy = false
                frame._migrationComplete = true
                frame._nameBox:ClearFocus()
                frame._nameBox:EnableMouse(false)
                frame._nameBox:SetAlpha(0.55)
                setCheckEnabled(frame._disableCheck, true)
                setCheckEnabled(frame._disableSelfCheck, true)

                local warningText = ""
                if #result.warnings > 0 then
                    warningText = " " .. #result.warnings .. " warning" .. (#result.warnings == 1 and "" or "s") .. "; see chat."
                    print("|cff0cd29fElvUI → EllesmereUI:|r migration warnings")
                    for _, warning in ipairs(result.warnings) do print("  |cffffb84d•|r " .. warning) end
                end
                frame:SetStatus("Created '" .. result.profileName .. "' with " .. result.copied .. " copied settings." .. warningText, COLORS.eui)
                self._label:SetText("Reload UI to apply")
                setButtonEnabled(self, true)
                print("|cff0cd29fElvUI → EllesmereUI:|r created profile |cffffffff" .. result.profileName .. "|r. Reload the UI to apply it.")
            end
        )

        if not started then
            frame:SetBusy(false)
            frame._progress:Hide()
            frame:SetStatus(startError, COLORS.error)
        end
    end)

    frame:SetScript("OnShow", function(self) self:RefreshSource() end)
    return frame
end

function UI:GetFrame()
    if not self.frame then self.frame = createFrame() end
    return self.frame
end

function UI:Show()
    local frame = self:GetFrame()
    frame:Show()
    frame:Raise()
end

function UI:Toggle()
    local frame = self:GetFrame()
    if frame:IsShown() then frame:Hide() else self:Show() end
end
