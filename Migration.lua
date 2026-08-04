local addonName, ns = ...

local floor, ceil, max, min, abs = math.floor, math.ceil, math.max, math.min, math.abs
local type, pairs, ipairs, tonumber, tostring = type, pairs, ipairs, tonumber, tostring

ns.Components = {
    { key = "appearance", label = "Fonts & textures", description = "Global font, outline, and status-bar texture" },
    { key = "player", label = "Player frame", description = "Size, position, bars, cast bar, portrait, auras, and visibility" },
    { key = "target", label = "Target frame", description = "Size, position, bars, cast bar, portrait, auras, and visibility" },
    { key = "otherUnits", label = "Other unit frames", description = "Focus, pet, target-of-target, focus-target, and boss frames" },
    { key = "party", label = "Party frames", description = "Size, position, growth, sorting, power, text, and debuffs" },
    { key = "raid", label = "Raid frames", description = "Size tiers, position, groups, growth, power, text, and debuffs" },
    { key = "actionBars", label = "Action bars", description = "Bars and utility menus: layout, text, direct visibility modes, and position" },
    { key = "minimap", label = "Minimap", description = "Shape, size, rotation, text scale, buttons, and position" },
    { key = "tooltips", label = "Tooltips", description = "Static or cursor placement, offsets, and spell/item IDs" },
}

local function deepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        copy[deepCopy(key, seen)] = deepCopy(child, seen)
    end
    return copy
end

local function syncTable(dst, src)
    for key in pairs(dst) do
        if src[key] == nil then dst[key] = nil end
    end
    for key, value in pairs(src) do
        if type(value) == "table" and type(dst[key]) == "table" then
            syncTable(dst[key], value)
        else
            dst[key] = deepCopy(value)
        end
    end
end

local function ensure(parent, key)
    if type(parent[key]) ~= "table" then parent[key] = {} end
    return parent[key]
end

local function set(ctx, target, key, value)
    if value == nil then return end
    target[key] = deepCopy(value)
    ctx.copied = ctx.copied + 1
end

local function copyColor(color)
    if type(color) ~= "table" then return nil end
    local r, g, b = tonumber(color.r), tonumber(color.g), tonumber(color.b)
    if not r or not g or not b then return nil end
    return { r = r, g = g, b = b, a = tonumber(color.a) }
end

local function trim(text)
    return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function addWarning(ctx, message)
    if not ctx.warningSet[message] then
        ctx.warningSet[message] = true
        ctx.warnings[#ctx.warnings + 1] = message
    end
end

local function textureKey(ctx, name)
    name = trim(name)
    if name == "" then return "none" end
    local lower = name:lower()
    local builtins = {
        ["elvui norm"] = "melli", ["elvui norm1"] = "melli", ["melli"] = "melli",
        ["elvui blank"] = "none", ["blizzard"] = "none", ["none"] = "none",
        ["atrocity"] = "atrocity", ["beautiful"] = "beautiful", ["plating"] = "plating",
        ["divide"] = "divide", ["glass"] = "glass", ["matte"] = "matte", ["sheer"] = "sheer",
    }
    if builtins[lower] then return builtins[lower] end
    addWarning(ctx, "Texture '" .. name .. "' was saved as SharedMedia; keep its media provider enabled if EllesmereUI cannot find it.")
    return "sm:" .. name
end
local BUNDLED_FONTS = {
    ["Expressway"] = true, ["Expressway Bold"] = true, ["Homespun"] = true,
    ["Arial"] = true, ["Arial Bold"] = true, ["Arial Narrow"] = true,
    ["Friz Quadrata"] = true, ["Morpheus"] = true, ["Skurri"] = true,
    ["Avant Garde"] = true, ["Poppins"] = true, ["Ubuntu"] = true,
}

local function fontKey(ctx, name)
    name = trim(name)
    if name == "" then return "Expressway" end
    if not BUNDLED_FONTS[name] then
        addWarning(ctx, "Font '" .. name .. "' was saved as SharedMedia; keep its media provider enabled if EllesmereUI cannot find it.")
    end
    return name
end


local function outlineMode(value)
    value = tostring(value or ""):upper()
    if value:find("THICK", 1, true) then return "thick" end
    if value:find("OUTLINE", 1, true) then return "outline" end
    return "none"
end

local function anchorName(value, fallback)
    value = tostring(value or ""):lower():gsub("_", "")
    local valid = {
        topleft = true, top = true, topright = true, left = true, center = true,
        right = true, bottomleft = true, bottom = true, bottomright = true,
    }
    return valid[value] and value or fallback
end

local function capturedCenter(frame)
    local parent = _G.UIParent
    if not frame or not parent or not frame.GetCenter or not parent.GetWidth then return nil end
    local x, y = frame:GetCenter()
    if not x or not y then return nil end
    local frameScale = frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
    local parentScale = parent.GetEffectiveScale and parent:GetEffectiveScale() or 1
    return {
        point = "CENTER", relPoint = "CENTER",
        x = x * frameScale / parentScale - parent:GetWidth() / 2,
        y = y * frameScale / parentScale - parent:GetHeight() / 2,
    }
end

local function parseMover(value)
    if type(value) ~= "string" then return nil end
    local fields = {}
    for field in value:gmatch("([^,]+)") do fields[#fields + 1] = trim(field) end
    if #fields < 5 then return nil end
    local relative = fields[2]
    if relative ~= "ElvUIParent" and relative ~= "UIParent" then return nil end
    local x, y = tonumber(fields[4]), tonumber(fields[5])
    if not x or not y then return nil end
    return { point = fields[1], relPoint = fields[3], x = x, y = y }
end

local function moverPosition(ctx, moverName)
    local live = capturedCenter(_G[moverName])
    if live then return live end
    local saved = ctx.source.movers and ctx.source.movers[moverName]
    local parsed = parseMover(saved)
    if not parsed and saved then
        addWarning(ctx, moverName .. " uses a relative ElvUI anchor that could not be converted; EllesmereUI kept its current position.")
    end
    return parsed
end

local function pointOffset(point, width, height)
    point = tostring(point or ""):upper()
    local x = point:find("LEFT", 1, true) and -width / 2
        or (point:find("RIGHT", 1, true) and width / 2 or 0)
    local y = point:find("BOTTOM", 1, true) and -height / 2
        or (point:find("TOP", 1, true) and height / 2 or 0)
    return x, y
end

local function oppositePoint(point)
    point = tostring(point or ""):upper()
    local vertical = point:find("TOP", 1, true) and "BOTTOM"
        or (point:find("BOTTOM", 1, true) and "TOP" or "")
    local horizontal = point:find("LEFT", 1, true) and "RIGHT"
        or (point:find("RIGHT", 1, true) and "LEFT" or "")
    return vertical .. horizontal
end

local function tooltipMoverGeometry(ctx)
    local parent = _G.UIParent
    if not parent or not parent.GetWidth or not parent.GetHeight then return nil end
    local parentWidth, parentHeight = parent:GetWidth(), parent:GetHeight()
    if not parentWidth or not parentHeight then return nil end

    local frame = _G.TooltipMover
    if frame and frame.GetCenter then
        local x, y = frame:GetCenter()
        if x and y then
            local parentScale = parent.GetEffectiveScale and parent:GetEffectiveScale() or 1
            local frameScale = frame.GetEffectiveScale and frame:GetEffectiveScale() or parentScale
            local ratio = frameScale / parentScale
            return x * ratio - parentWidth / 2, y * ratio - parentHeight / 2,
                (frame.GetWidth and frame:GetWidth() or 130) * ratio,
                (frame.GetHeight and frame:GetHeight() or 20) * ratio,
                parentWidth, parentHeight
        end
    end

    local saved = ctx.source.movers and ctx.source.movers.TooltipMover
    local position = parseMover(saved)
    if not position then
        if saved then
            addWarning(ctx, "TooltipMover uses a relative ElvUI anchor that could not be converted; EllesmereUI kept its inherited static tooltip position.")
        end
        return nil
    end

    local width, height = 130, 20
    local relX, relY = pointOffset(position.relPoint, parentWidth, parentHeight)
    local frameX, frameY = pointOffset(position.point, width, height)
    return relX + position.x - frameX, relY + position.y - frameY,
        width, height, parentWidth, parentHeight
end

local function tooltipQuadrant(x, y, width, height)
    local left, right = -width / 6, width / 6
    local bottom, top = -height / 6, height / 6
    if x > left and x < right and y > top then return "TOP" end
    if x < left and y > top then return "TOPLEFT" end
    if x > right and y > top then return "TOPRIGHT" end
    if x > left and x < right and y < bottom then return "BOTTOM" end
    if x < left and y < bottom then return "BOTTOMLEFT" end
    if x > right and y < bottom then return "BOTTOMRIGHT" end
    if x < left and y > bottom and y < top then return "LEFT" end
    if x > right and y > bottom and y < top then return "RIGHT" end
    return "CENTER"
end

local function tooltipStaticPosition(ctx, src)
    local x, y, width, height, parentWidth, parentHeight = tooltipMoverGeometry(ctx)
    if not x then
        addWarning(ctx, "ElvUI's static tooltip position was unavailable; EllesmereUI kept the inherited position.")
        return nil
    end

    local point = tooltipQuadrant(x, y, parentWidth, parentHeight)
    if point == "LEFT" then point = "BOTTOMLEFT"
    elseif point == "RIGHT" or point == "CENTER" then point = "BOTTOMRIGHT" end

    local anchorX, anchorY = pointOffset(oppositePoint(point), width, height)
    anchorX = x + anchorX + (tonumber(src.xOffset) or 0)
    anchorY = y + anchorY + (tonumber(src.yOffset) or 0)

    local targetHalfWidth, targetHalfHeight = 140, 82.5
    local leftSide = anchorX < 0
    local centerX = anchorX + (leftSide and targetHalfWidth or -targetHalfWidth)
    if leftSide and centerX >= 0 then centerX = -0.001
    elseif not leftSide and centerX < 0 then centerX = 0 end
    local growsDown = point:find("TOP", 1, true) ~= nil
    local centerY = anchorY + (growsDown and -targetHalfHeight or targetHalfHeight)

    if abs(anchorX) < targetHalfWidth then
        addWarning(ctx, "ElvUI's centered tooltip anchor cannot be represented exactly by EllesmereUI's corner-based fixed anchor; the nearest static position was used.")
    end
    return { centerX = centerX, centerY = centerY }, growsDown and "down" or "up"
end

local function targetModule(work, folder)
    local addons = ensure(work, "addons")
    return ensure(addons, folder)
end

local function sourceInfo()
    local container = _G.ElvUI
    local engine = type(container) == "table" and container[1]
    if type(engine) ~= "table" or type(engine.db) ~= "table" then
        return nil, "ElvUI is not loaded. Enable ElvUI for one login, reload, then run this migrator."
    end
    local profileName = engine.data and engine.data.keys and engine.data.keys.profile
    if not profileName and type(_G.ElvDB) == "table" and type(_G.ElvDB.profileKeys) == "table" then
        local charKey = engine.mynameRealm
        profileName = charKey and _G.ElvDB.profileKeys[charKey]
    end
    return { engine = engine, profile = engine.db, name = profileName or "Current" }
end
ns.GetSourceInfo = sourceInfo

local function sourceAuraSize(aura)
    if type(aura) ~= "table" then return nil end
    local override = tonumber(aura.sizeOverride)
    if override and override > 0 then return override end
    return tonumber(aura.height)
end

local function sourceAuraCount(aura)
    if type(aura) ~= "table" then return nil end
    return max(1, tonumber(aura.perrow) or 1) * max(1, tonumber(aura.numrows) or 1)
end

local function applyUnit(ctx, srcKey, dstKey, moverName, kind)
    local uf = ctx.source.unitframe
    local src = uf and uf.units and uf.units[srcKey]
    if type(src) ~= "table" then
        addWarning(ctx, "ElvUI has no " .. srcKey .. " frame settings to migrate.")
        return
    end

    local profile = targetModule(ctx.work, "EllesmereUIUnitFrames")
    local dst = ensure(profile, dstKey)
    local enabled = src.enable ~= false
    set(ctx, ensure(profile, "enabledFrames"), dstKey, enabled)
    set(ctx, ensure(profile, "frameSource"), dstKey, enabled and "eui" or "hidden")
    set(ctx, dst, "frameWidth", tonumber(src.width))

    local power = type(src.power) == "table" and src.power or {}
    local powerShown = power.enable ~= false and not power.detachFromFrame
    local powerHeight = powerShown and (tonumber(power.height) or 0) or 0
    local totalHeight = tonumber(src.height)
    set(ctx, dst, "healthHeight", totalHeight and max(1, totalHeight - powerHeight) or nil)
    set(ctx, dst, "powerHeight", powerHeight)
    set(ctx, dst, "powerPosition", powerShown and "below" or "none")
    set(ctx, dst, "powerReverseFill", power.reverseFill == true)
    set(ctx, dst, "smoothBars", src.health and src.health.smoothbars == true)
    set(ctx, dst, "healthReverseFill", src.health and src.health.reverseFill == true)

    local colors = uf and uf.colors or {}
    set(ctx, dst, "healthClassColored", colors.healthclass == true)
    set(ctx, dst, "bgClassColored", colors.classbackdrop == true)
    set(ctx, dst, "customBgColor", copyColor(colors.health_backdrop))

    local portrait = type(src.portrait) == "table" and src.portrait or {}
    set(ctx, dst, "showPortrait", portrait.enable == true)
    set(ctx, dst, "portraitMode", tostring(portrait.style or "3D"):upper() == "3D" and "3d" or "2d")
    set(ctx, dst, "portraitSize", tonumber(portrait.width))
    set(ctx, dst, "portraitX", tonumber(portrait.xOffset))
    set(ctx, dst, "portraitY", tonumber(portrait.yOffset))

    local fontSize = tonumber(uf and uf.fontSize)
    set(ctx, dst, "textSize", fontSize)
    set(ctx, dst, "leftTextSize", fontSize)
    set(ctx, dst, "rightTextSize", fontSize)
    if type(src.name) == "table" then
        set(ctx, dst, "leftTextX", tonumber(src.name.xOffset))
        set(ctx, dst, "leftTextY", tonumber(src.name.yOffset))
    end
    if type(src.health) == "table" then
        set(ctx, dst, "rightTextX", tonumber(src.health.xOffset))
        set(ctx, dst, "rightTextY", tonumber(src.health.yOffset))
    end

    local buffs, debuffs = src.buffs, src.debuffs
    if type(buffs) == "table" then
        set(ctx, dst, "showBuffs", buffs.enable == true)
        set(ctx, dst, "maxBuffs", sourceAuraCount(buffs))
        set(ctx, dst, "buffSize", sourceAuraSize(buffs))
        set(ctx, dst, "buffAnchor", anchorName(buffs.anchorPoint, "topleft"))
        set(ctx, dst, "buffOffsetX", tonumber(buffs.xOffset))
        set(ctx, dst, "buffOffsetY", tonumber(buffs.yOffset))
        set(ctx, dst, "buffCooldownTextSize", tonumber(buffs.durationFontSize))
    end
    if type(debuffs) == "table" then
        set(ctx, dst, "maxDebuffs", sourceAuraCount(debuffs))
        set(ctx, dst, "debuffSize", sourceAuraSize(debuffs))
        set(ctx, dst, "debuffAnchor", debuffs.enable == false and "none" or anchorName(debuffs.anchorPoint, "bottomleft"))
        set(ctx, dst, "debuffOffsetX", tonumber(debuffs.xOffset))
        set(ctx, dst, "debuffOffsetY", tonumber(debuffs.yOffset))
        set(ctx, dst, "onlyPlayerDebuffs", tostring(debuffs.priority or ""):find("Personal", 1, true) ~= nil)
    end

    local castbar = src.castbar
    if type(castbar) == "table" then
        if kind == "player" then
            set(ctx, dst, "showPlayerCastbar", castbar.enable ~= false)
            set(ctx, dst, "showPlayerCastIcon", castbar.icon ~= false)
            set(ctx, dst, "playerCastbarWidth", tonumber(castbar.width))
            set(ctx, dst, "playerCastbarHeight", tonumber(castbar.height))
        else
            set(ctx, dst, "showCastbar", castbar.enable ~= false)
            set(ctx, dst, "showCastIcon", castbar.icon ~= false)
            set(ctx, dst, "castbarWidth", tonumber(castbar.width))
            set(ctx, dst, "castbarHeight", tonumber(castbar.height))
            set(ctx, dst, "showCastTarget", castbar.displayTarget == true)
        end
        set(ctx, dst, "castReverseFill", castbar.reverse == true)
        if type(castbar.customColor) == "table" and castbar.customColor.enable then
            set(ctx, dst, "castbarFillColor", copyColor(castbar.customColor.color))
            set(ctx, dst, "castbarClassColored", castbar.customColor.useClassColor == true)
        end
    end

    local fader = src.fader
    if type(fader) == "table" then
        set(ctx, dst, "oocFadeEnabled", fader.enable == true and fader.combat == true)
        set(ctx, dst, "oocAlpha", tonumber(fader.minAlpha))
    end

    local position = moverPosition(ctx, moverName)
    if position then set(ctx, ensure(profile, "positions"), dstKey, position) end
end

local function migrateAppearance(ctx)
    local source = ctx.source
    local uf = source.unitframe or {}
    local general = source.general or {}
    local fontName = fontKey(ctx, general.font or uf.font)
    ctx.work.fonts = ctx.work.fonts or {}
    set(ctx, ctx.work.fonts, "global", fontName)
    set(ctx, ctx.work.fonts, "outlineMode", outlineMode(general.fontOutline or uf.fontOutline))

    local texture = textureKey(ctx, uf.statusbar)
    set(ctx, targetModule(ctx.work, "EllesmereUIUnitFrames"), "healthBarTexture", texture)
    set(ctx, targetModule(ctx.work, "EllesmereUIRaidFrames"), "healthBarTexture", texture)
end

local function migratePlayer(ctx)
    applyUnit(ctx, "player", "player", "ElvUF_PlayerMover", "player")
end

local function migrateTarget(ctx)
    applyUnit(ctx, "target", "target", "ElvUF_TargetMover", "target")
end

local function migrateOtherUnits(ctx)
    applyUnit(ctx, "focus", "focus", "ElvUF_FocusMover", "focus")
    applyUnit(ctx, "pet", "pet", "ElvUF_PetMover", "pet")
    applyUnit(ctx, "targettarget", "targettarget", "ElvUF_TargetTargetMover", "targettarget")
    applyUnit(ctx, "focustarget", "focustarget", "ElvUF_FocusTargetMover", "focustarget")
    applyUnit(ctx, "boss", "boss", "BossHeaderMover", "boss")
    local sourceBoss = ctx.source.unitframe and ctx.source.unitframe.units and ctx.source.unitframe.units.boss
    if sourceBoss then
        set(ctx, targetModule(ctx.work, "EllesmereUIUnitFrames"), "bossSpacing", tonumber(sourceBoss.spacing))
    end
end

local function healthTextMode(text)
    text = tostring(text or ""):lower()
    if text == "" then return "none" end
    if text:find("perhp", 1, true) or text:find("percent", 1, true) then return "percent" end
    return "number"
end

local function growthPair(value)
    value = tostring(value or "RIGHT_DOWN"):upper()
    local first, second = value:match("^(%a+)_(%a+)$")
    first, second = first or "RIGHT", second or "DOWN"
    return first, second
end

local function applyGroupVisuals(ctx, src, dst, prefix)
    prefix = prefix or ""
    local uf = ctx.source.unitframe or {}
    local colors = uf.colors or {}
    local texture = textureKey(ctx, uf.statusbar)
    set(ctx, dst, prefix .. "healthBarTexture", texture)
    set(ctx, dst, prefix .. "healthColorMode", colors.healthclass and "class" or "custom")
    set(ctx, dst, prefix .. "customFillColor", copyColor(colors.health))
    set(ctx, dst, prefix .. "customBgColor", copyColor(colors.health_backdrop))
    set(ctx, dst, prefix .. "bgClassColored", colors.classbackdrop == true)
    set(ctx, dst, prefix .. "smoothBars", src.health and src.health.smoothbars == true)
    set(ctx, dst, prefix .. "healthVerticalFill", src.health and tostring(src.health.orientation):upper() == "VERTICAL")

    local power = type(src.power) == "table" and src.power or {}
    set(ctx, dst, prefix .. "showPowerBar", power.enable ~= false)
    set(ctx, dst, prefix .. "powerHeight", tonumber(power.height))
    set(ctx, dst, prefix .. "smoothPowerBars", power.smoothbars == true)

    local name = type(src.name) == "table" and src.name or {}
    set(ctx, dst, prefix .. "nameSize", tonumber(name.fontSize) or tonumber(uf.fontSize))
    set(ctx, dst, prefix .. "namePosition", anchorName(name.position, "center"))
    set(ctx, dst, prefix .. "nameOffsetX", tonumber(name.xOffset))
    set(ctx, dst, prefix .. "nameOffsetY", tonumber(name.yOffset))
    set(ctx, dst, prefix .. "healthTextMode", healthTextMode(src.health and src.health.text_format))
    set(ctx, dst, prefix .. "healthTextSize", tonumber(src.health and src.health.fontSize) or tonumber(uf.fontSize))
    set(ctx, dst, prefix .. "healthTextPosition", anchorName(src.health and src.health.position, "center"))

    local debuffs = type(src.debuffs) == "table" and src.debuffs or {}
    set(ctx, dst, prefix .. "debuffFilter", debuffs.enable == false and "none" or "all")
    set(ctx, dst, prefix .. "debuffSize", sourceAuraSize(debuffs))
    set(ctx, dst, prefix .. "debuffCap", sourceAuraCount(debuffs))
    set(ctx, dst, prefix .. "debuffPosition", anchorName(debuffs.anchorPoint, "bottomright"))
    set(ctx, dst, prefix .. "debuffOffsetX", tonumber(debuffs.xOffset))
    set(ctx, dst, prefix .. "debuffOffsetY", tonumber(debuffs.yOffset))
    set(ctx, dst, prefix .. "debuffSpacing", tonumber(debuffs.spacing))

    local raidIcon = type(src.raidicon) == "table" and src.raidicon or {}
    set(ctx, dst, prefix .. "showRaidMarker", raidIcon.enable ~= false)
    set(ctx, dst, prefix .. "raidMarkerSize", tonumber(raidIcon.size))
    set(ctx, dst, prefix .. "raidMarkerPosition", anchorName(raidIcon.attachTo, "center"))
end

local function migrateParty(ctx)
    local src = ctx.source.unitframe and ctx.source.unitframe.units and ctx.source.unitframe.units.party
    if type(src) ~= "table" then addWarning(ctx, "ElvUI party frame settings were not available."); return end
    local dst = targetModule(ctx.work, "EllesmereUIRaidFrames")
    set(ctx, dst, "partyFrameWidth", tonumber(src.width))
    set(ctx, dst, "partyFrameHeight", tonumber(src.height))
    set(ctx, dst, "partyShowWhenSolo", tostring(src.visibility or ""):find("@party1,noexists", 1, true) == nil)
    set(ctx, dst, "partySortMode", tostring(src.groupBy or src.sortMethod):upper():find("ROLE", 1, true) and "ROLE" or "INDEX")
    set(ctx, dst, "partyShowSelfFirst", src.showPlayer ~= false and src.sortDir ~= "DESC")
    set(ctx, dst, "partySelfLast", src.showPlayer ~= false and src.sortDir == "DESC")
    local unitGrowth = growthPair(src.growthDirection)
    set(ctx, dst, "partyHorizontal", unitGrowth == "RIGHT" or unitGrowth == "LEFT")
    set(ctx, dst, "partyFlipGrowth", unitGrowth == "UP" or unitGrowth == "LEFT")
    set(ctx, dst, "partyCellSpacing", max(tonumber(src.horizontalSpacing) or 0, tonumber(src.verticalSpacing) or 0))
    set(ctx, dst, "partyUnlockPos", moverPosition(ctx, "ElvUF_PartyMover"))

    dst.partySyncSections = dst.partySyncSections or {}
    for _, section in ipairs({ "healthBar", "powerBar", "textDisplay", "indicators", "debuffDisplay", "debuffStyle" }) do
        dst.partySyncSections[section] = false
    end
    applyGroupVisuals(ctx, src, dst, "party_")
end

local function visibleGroups(count)
    local groups = {}
    count = max(1, tonumber(count) or 8)
    for index = 1, 8 do groups[index] = index <= count end
    return groups
end

local function migrateRaid(ctx)
    local units = ctx.source.unitframe and ctx.source.unitframe.units
    local src = units and units.raid1
    if type(src) ~= "table" then addWarning(ctx, "ElvUI raid frame settings were not available."); return end
    local dst = targetModule(ctx.work, "EllesmereUIRaidFrames")
    set(ctx, dst, "frameWidth", tonumber(src.width))
    set(ctx, dst, "frameHeight", tonumber(src.height))
    set(ctx, dst, "showWhenRaid", src.enable ~= false)
    set(ctx, dst, "visibleGroups", visibleGroups(src.numGroups))
    set(ctx, dst, "sortMode", tostring(src.groupBy or src.sortMethod):upper():find("ROLE", 1, true) and "ROLE" or "INDEX")
    set(ctx, dst, "showSelfFirst", src.showPlayer ~= false and src.sortDir ~= "DESC")
    set(ctx, dst, "showSelfLast", src.showPlayer ~= false and src.sortDir == "DESC")
    set(ctx, dst, "cellSpacing", max(tonumber(src.horizontalSpacing) or 0, tonumber(src.verticalSpacing) or 0))
    set(ctx, dst, "groupSpacing", tonumber(src.groupSpacing))
    local unitGrowth, groupGrowth = growthPair(src.growthDirection)
    set(ctx, dst, "unitGrowth", unitGrowth)
    set(ctx, dst, "groupGrowth", groupGrowth)
    set(ctx, dst, "unlockPos", moverPosition(ctx, "ElvUF_Raid1Mover"))
    applyGroupVisuals(ctx, src, dst)

    local medium = units and units.raid2
    if type(medium) == "table" then
        dst.raidSizeOverrides = dst.raidSizeOverrides or { _topLeftAnchored = true, _cornerAnchored = true }
        local mUnit, mGroup = growthPair(medium.growthDirection)
        local override = {
            width = tonumber(medium.width), height = tonumber(medium.height),
            unitGrowth = mUnit, groupGrowth = mGroup,
        }
        dst.raidSizeOverrides[25] = deepCopy(override)
        dst.raidSizeOverrides[30] = deepCopy(override)
        ctx.copied = ctx.copied + 2
    end
end

local BAR_MAP = {
    bar1 = { target = "MainBar", mover = "ElvAB_1" },
    bar2 = { target = "Bar9", mover = "ElvAB_2" },
    bar3 = { target = "Bar4", mover = "ElvAB_3" },
    bar4 = { target = "Bar5", mover = "ElvAB_4" },
    bar5 = { target = "Bar3", mover = "ElvAB_5" },
    bar6 = { target = "Bar2", mover = "ElvAB_6" },
    bar10 = { target = "Bar10", mover = "ElvAB_10" },
    bar13 = { target = "Bar6", mover = "ElvAB_13" },
    bar14 = { target = "Bar7", mover = "ElvAB_14" },
    bar15 = { target = "Bar8", mover = "ElvAB_15" },
}

local VISIBILITY_MODE_ORDER = {
    "in_combat", "out_of_combat", "in_raid", "in_party", "solo",
    "show_dragonriding", "show_not_dragonriding",
}

local REGULAR_BAR_INTRINSIC_HIDES = { vehicleui = true, petbattle = true, overridebar = true }
local MAIN_BAR_INTRINSIC_HIDES = { petbattle = true }
local STANCE_BAR_INTRINSIC_HIDES = { vehicleui = true, petbattle = true }
local PET_BAR_INTRINSIC_HIDES = {
    vehicleui = true, petbattle = true, overridebar = true, possessbar = true,
}
local UTILITY_BAR_INTRINSIC_HIDES = { petbattle = true }

local HIDE_OPTION_KEYS = {
    mounted = "visHideMounted",
    noexists = "visHideNoTarget",
    noharm = "visHideNoEnemy",
}

local function visibilityGroups(prefix)
    if prefix == "" then return {} end
    local groups = {}
    for group in prefix:gmatch("%[([^%]]+)%]") do groups[#groups + 1] = group end
    if #groups == 0 or prefix:gsub("%[[^%]]+%]", "") ~= "" then return nil end
    return groups
end

local function visibilityTerms(group)
    local terms = {}
    for term in group:gmatch("([^,]+)") do terms[#terms + 1] = term end
    return terms
end

local function parseVisibilityClause(value)
    local action
    if value:sub(-4) == "show" then action = "show"
    elseif value:sub(-4) == "hide" then action = "hide"
    else return nil end
    local prefix = value:sub(1, #value - 4)
    local groups = visibilityGroups(prefix)
    if not groups then return nil end
    return { action = action, groups = groups }
end

local function groupsContainOnly(groups, allowed)
    if #groups == 0 then return false end
    for _, group in ipairs(groups) do
        local terms = visibilityTerms(group)
        if #terms ~= 1 or not allowed[terms[1]] then return false end
    end
    return true
end

local function collectHideOptions(groups, result)
    if #groups == 0 then return false end
    for _, group in ipairs(groups) do
        local terms = visibilityTerms(group)
        local key = #terms == 1 and HIDE_OPTION_KEYS[terms[1]]
        if not key then return false end
        result[key] = true
    end
    return true
end

local function parseVisibilityModes(groups, intrinsicPet)
    if #groups ~= 1 then return nil end
    local terms = visibilityTerms(groups[1])
    local modes = {}
    local sawAdvFlyable, sawFlying, sawAnyGroup, sawExplicitParty, sawExplicitRaid
    local intrinsicPetTerms = {
        pet = true, novehicleui = true, nopetbattle = true,
        nooverridebar = true, nopossessbar = true,
    }
    local onlyIntrinsicPet = intrinsicPet and #terms > 0

    for _, term in ipairs(terms) do
        if not intrinsicPetTerms[term] then onlyIntrinsicPet = false end
        if term == "combat" then
            if modes.out_of_combat then return nil end
            modes.in_combat = true
        elseif term == "nocombat" then
            if modes.in_combat then return nil end
            modes.out_of_combat = true
        elseif term == "group:raid" then
            if modes.solo or sawExplicitParty then return nil end
            modes.in_raid, sawExplicitRaid = true, true
        elseif term == "group:party" then
            if modes.solo or sawExplicitRaid then return nil end
            modes.in_party, sawExplicitParty = true, true
        elseif term == "group" then
            if modes.solo or sawExplicitParty or sawExplicitRaid then return nil end
            modes.in_party, modes.in_raid, sawAnyGroup = true, true, true
        elseif term == "nogroup" then
            if modes.in_party or modes.in_raid then return nil end
            modes.solo = true
        elseif term == "nogroup:raid" and modes.in_party then
            -- EllesmereUI's in_party mode already excludes raid groups.
        elseif term == "advflyable" then
            sawAdvFlyable = true
        elseif term == "flying" then
            sawFlying = true
        elseif not intrinsicPetTerms[term] then
            return nil
        end
    end

    if onlyIntrinsicPet and intrinsicPet then return {}, true end
    if sawAnyGroup and (sawExplicitParty or sawExplicitRaid) then return nil end
    if sawAdvFlyable ~= sawFlying then return nil end
    if sawAdvFlyable then modes.show_dragonriding = true end
    if not next(modes) then return nil end
    return modes, false
end

local function sameModes(left, right)
    if not left or not right then return false end
    for key, value in pairs(left) do if value ~= right[key] then return false end end
    for key, value in pairs(right) do if value ~= left[key] then return false end end
    return true
end

local function complementVisibilityModes(modes)
    local count, only
    for key in pairs(modes) do count, only = (count or 0) + 1, key end
    if count == 1 then
        local inverse = {
            in_combat = "out_of_combat", out_of_combat = "in_combat",
            in_raid = "solo_or_party", in_party = "solo_or_raid", solo = "group",
            show_dragonriding = "show_not_dragonriding",
        }
        local value = inverse[only]
        if value == "group" then return { in_party = true, in_raid = true } end
        if value == "solo_or_party" then return { solo = true, in_party = true } end
        if value == "solo_or_raid" then return { solo = true, in_raid = true } end
        return value and { [value] = true } or nil
    end
    if count == 2 and modes.in_party and modes.in_raid then return { solo = true } end
    return nil
end

local function visibilityRepresentative(modes)
    if modes.mouseover then return "mouseover" end
    for _, mode in ipairs(VISIBILITY_MODE_ORDER) do
        if modes[mode] then return mode end
    end
    return "always"
end

local function visibilityModeCount(modes)
    local count = 0
    for _ in pairs(modes) do count = count + 1 end
    return count
end

local function visibilitySettings(src, intrinsicPet, intrinsicHides)
    local result = {
        mode = "always",
        visHideMounted = false,
        visHideNoTarget = false,
        visHideNoEnemy = false,
    }
    if src.enabled == false then result.mode = "never"; return result end

    local value = tostring(src.visibility or ""):lower():gsub("[%s\r\n]+", "")
    local clauses = {}
    if value ~= "" then
        for text in value:gmatch("([^;]+)") do
            local clause = parseVisibilityClause(text)
            if not clause then result.unsupported = true; break end
            if clause.action == "hide"
                and groupsContainOnly(clause.groups, intrinsicHides or REGULAR_BAR_INTRINSIC_HIDES) then
                -- The destination bar applies these guards intrinsically.
            elseif clause.action == "hide" and collectHideOptions(clause.groups, result) then
                -- These have direct EllesmereUI visibility-option flags.
            else
                clauses[#clauses + 1] = clause
            end
        end
    end

    local modes
    if not result.unsupported and #clauses == 0 then
        result.mode = "always"
    elseif not result.unsupported and #clauses == 1 and #clauses[1].groups == 0 then
        result.mode = clauses[1].action == "hide" and "never" or "always"
    elseif not result.unsupported and #clauses == 2 then
        local first, second = clauses[1], clauses[2]
        if first.action == "show" and #second.groups == 0 and second.action == "hide" then
            local intrinsic
            modes, intrinsic = parseVisibilityModes(first.groups, intrinsicPet)
            if intrinsic then result.mode = "always"
            elseif not modes then result.unsupported = true end
        elseif first.action == "hide" and #second.groups == 0 and second.action == "show" then
            local hidden = parseVisibilityModes(first.groups, false)
            modes = hidden and complementVisibilityModes(hidden)
            if not modes then result.unsupported = true end
        elseif first.action ~= second.action then
            local showClause = first.action == "show" and first or second
            local hideClause = first.action == "hide" and first or second
            local shown = parseVisibilityModes(showClause.groups, intrinsicPet)
            local hidden = parseVisibilityModes(hideClause.groups, false)
            local inverse = hidden and complementVisibilityModes(hidden)
            if shown and inverse and sameModes(shown, inverse) then modes = shown
            else result.unsupported = true end
        else
            result.unsupported = true
        end
    elseif not result.unsupported then
        result.unsupported = true
    end

    if result.unsupported then
        modes = nil
        result.mode = "always"
    elseif modes and next(modes) then
        result.mode = visibilityRepresentative(modes)
    end

    if src.mouseover == true and result.mode ~= "never" then
        if result.mode == "always" and not modes then
            result.mode = "mouseover"
        else
            modes = modes or { [result.mode] = true }
            modes.mouseover = true
            result.mode = visibilityRepresentative(modes)
        end
    end
    if modes and visibilityModeCount(modes) > 1 then result.modes = modes end
    return result
end

local function barVisibility(src)
    return visibilitySettings(src, false).mode
end

local function applyBarVisibility(ctx, dst, src, label, intrinsicPet, intrinsicHides)
    local visibility = visibilitySettings(src, intrinsicPet, intrinsicHides)
    local mouseover = visibility.mode == "mouseover"
        or (visibility.modes and visibility.modes.mouseover) or false

    dst.visibilityModes = nil
    dst._savedBarAlpha = nil
    set(ctx, dst, "barVisibility", visibility.mode)
    set(ctx, dst, "alwaysHidden", visibility.mode == "never")
    set(ctx, dst, "mouseoverEnabled", mouseover)
    set(ctx, dst, "mouseoverAlpha", mouseover and 0 or 1)
    if mouseover then set(ctx, dst, "_savedBarAlpha", tonumber(src.alpha) or 1) end
    set(ctx, dst, "combatShowEnabled", visibility.mode == "in_combat"
        or (visibility.modes and visibility.modes.in_combat) or false)
    set(ctx, dst, "combatHideEnabled", visibility.mode == "out_of_combat"
        or (visibility.modes and visibility.modes.out_of_combat) or false)
    set(ctx, dst, "visHideMounted", visibility.visHideMounted)
    set(ctx, dst, "visHideNoTarget", visibility.visHideNoTarget)
    set(ctx, dst, "visHideNoEnemy", visibility.visHideNoEnemy)
    if visibility.modes then set(ctx, dst, "visibilityModes", visibility.modes) end

    if visibility.unsupported then
        addWarning(ctx, label .. " uses an ElvUI visibility condition without a direct EllesmereUI equivalent; it was migrated as "
            .. (mouseover and "Mouseover." or "Always shown."))
    end
end

local function migrateBar(ctx, sourceKey, map)
    local sourceAB = ctx.source.actionbar or {}
    local src = sourceAB[sourceKey]
    if type(src) ~= "table" then return end
    local profile = targetModule(ctx.work, "EllesmereUIActionBars")
    local dst = ensure(ensure(profile, "bars"), map.target)
    local enabled = src.enabled ~= false
    set(ctx, dst, "enabled", enabled)
    local intrinsicHides = REGULAR_BAR_INTRINSIC_HIDES
    if map.target == "MainBar" then intrinsicHides = MAIN_BAR_INTRINSIC_HIDES
    elseif map.target == "StanceBar" then intrinsicHides = STANCE_BAR_INTRINSIC_HIDES
    elseif map.target == "PetBar" then intrinsicHides = PET_BAR_INTRINSIC_HIDES end
    applyBarVisibility(ctx, dst, src, map.label or ("ElvUI " .. sourceKey), sourceKey == "barPet", intrinsicHides)
    set(ctx, dst, "clickThrough", src.clickThrough == true)

    local buttons = max(1, tonumber(src.buttons) or 12)
    local perRow = max(1, tonumber(src.buttonsPerRow) or buttons)
    set(ctx, dst, "overrideNumIcons", buttons)
    set(ctx, dst, "overrideNumRows", ceil(buttons / perRow))
    set(ctx, dst, "orientation", perRow <= 1 and "vertical" or "horizontal")
    set(ctx, dst, "buttonPadding", tonumber(src.buttonSpacing))
    set(ctx, dst, "buttonWidth", tonumber(src.buttonSize))
    set(ctx, dst, "buttonHeight", tonumber(src.buttonHeight) or tonumber(src.buttonSize))
    set(ctx, dst, "bgEnabled", src.backdrop == true)

    set(ctx, dst, "hideKeybind", src.hotkeytext == false)
    set(ctx, dst, "keybindFontSize", tonumber(src.hotkeyFontSize) or tonumber(sourceAB.fontSize))
    set(ctx, dst, "keybindFontColor", copyColor(src.hotkeyColor or sourceAB.fontColor))
    set(ctx, dst, "keybindOffsetX", tonumber(src.hotkeyTextXOffset))
    set(ctx, dst, "keybindOffsetY", tonumber(src.hotkeyTextYOffset))
    set(ctx, dst, "hideMacroText", src.macrotext == false)
    set(ctx, dst, "macroFontSize", tonumber(src.macroFontSize) or tonumber(sourceAB.fontSize))
    set(ctx, dst, "macroFontColor", copyColor(src.macroColor or sourceAB.fontColor))
    set(ctx, dst, "macroOffsetX", tonumber(src.macroTextXOffset))
    set(ctx, dst, "macroOffsetY", tonumber(src.macroTextYOffset))
    set(ctx, dst, "countFontSize", tonumber(src.countFontSize) or tonumber(sourceAB.fontSize))
    set(ctx, dst, "countFontColor", copyColor(src.countColor or sourceAB.fontColor))
    set(ctx, dst, "countOffsetX", tonumber(src.countFontXOffset))
    set(ctx, dst, "countOffsetY", tonumber(src.countFontYOffset))
    set(ctx, dst, "outOfRangeColoring", sourceAB.useRangeColorText ~= true)
    set(ctx, dst, "outOfRangeColor", copyColor(sourceAB.noRangeColor))

    local position = moverPosition(ctx, map.mover)
    if position then set(ctx, ensure(profile, "barPositions"), map.target, position) end
end

local function migrateActionBars(ctx)
    for sourceKey, map in pairs(BAR_MAP) do migrateBar(ctx, sourceKey, map) end
    local ab = ctx.source.actionbar or {}
    local unsupported = {}
    for _, sourceKey in ipairs({ "bar7", "bar8", "bar9" }) do
        if type(ab[sourceKey]) == "table" and ab[sourceKey].enabled ~= false then
            unsupported[#unsupported + 1] = sourceKey:gsub("bar", "Bar ")
        end
    end
    if #unsupported > 0 then
        addWarning(ctx, table.concat(unsupported, ", ") .. " use action pages that EllesmereUI does not expose; those bars were not migrated.")
    end
    migrateBar(ctx, "stanceBar", { target = "StanceBar", mover = "ShiftAB", label = "ElvUI Stance Bar" })
    migrateBar(ctx, "barPet", { target = "PetBar", mover = "PetAB", label = "ElvUI Pet Bar" })
    local dst = targetModule(ctx.work, "EllesmereUIActionBars")
    if type(ab.microbar) == "table" then
        local micro = ensure(ensure(dst, "bars"), "MicroBar")
        applyBarVisibility(ctx, micro, ab.microbar, "ElvUI Micro Bar", false, UTILITY_BAR_INTRINSIC_HIDES)
    end
    local bagBar = ctx.source.bags and ctx.source.bags.bagBar
    if type(bagBar) == "table" then
        local bags = ensure(ensure(dst, "bars"), "BagBar")
        applyBarVisibility(ctx, bags, bagBar, "ElvUI Bag Bar", false, UTILITY_BAR_INTRINSIC_HIDES)
    end
    set(ctx, dst, "desaturateOnCooldown", ab.desaturateOnCooldown == true)
end

local function migrateMinimap(ctx)
    local src = ctx.source.general and ctx.source.general.minimap
    if type(src) ~= "table" then addWarning(ctx, "ElvUI minimap settings were not available."); return end
    local module = targetModule(ctx.work, "EllesmereUIMinimap")
    local dst = ensure(module, "minimap")
    set(ctx, dst, "enabled", true)
    set(ctx, dst, "mapSize", floor((tonumber(src.size) or 140) * (tonumber(src.scale) or 1) + 0.5))
    set(ctx, dst, "shape", src.circle and "circle" or "square")
    set(ctx, dst, "rotateMinimap", src.rotate == true)
    set(ctx, dst, "locationMode", src.locationText == "HIDE" and "none" or "inside")
    set(ctx, dst, "locationScale", (tonumber(src.locationFontSize) or 14) / 14)
    set(ctx, dst, "clockScale", (tonumber(src.timeFontSize) or 14) / 14)
    local icons = src.icons or {}
    set(ctx, dst, "hideTrackingButton", icons.tracking and icons.tracking.hide == true)
    set(ctx, dst, "hideGameTime", icons.calendar and icons.calendar.hide == true)
    set(ctx, dst, "position", moverPosition(ctx, "MinimapMover"))
end

local function migrateTooltips(ctx)
    local src = ctx.source.tooltip
    if type(src) ~= "table" then
        addWarning(ctx, "ElvUI tooltip settings were not available.")
        return
    end

    local global = ctx.globalWork
    set(ctx, global, "customTooltips", true)
    set(ctx, global, "tooltipAnchorCursor", src.cursorAnchor == true)

    local cursorPositions = {
        ANCHOR_CURSOR = "top",
        ANCHOR_CURSOR_LEFT = "left",
        ANCHOR_CURSOR_RIGHT = "right",
    }
    local cursorType = tostring(src.cursorAnchorType or "ANCHOR_CURSOR"):upper()
    local cursorPosition = cursorPositions[cursorType]
    if not cursorPosition then
        cursorPosition = "top"
        addWarning(ctx, "ElvUI's cursor tooltip anchor type '" .. cursorType
            .. "' has no direct EllesmereUI equivalent; Top was used.")
    end
    set(ctx, global, "tooltipCursorPosition", cursorPosition)

    local cursorX = tonumber(src.cursorAnchorX) or 0
    local cursorY = tonumber(src.cursorAnchorY) or 0
    local targetX, targetY = max(-100, min(100, cursorX)), max(-100, min(100, cursorY))
    set(ctx, global, "tooltipCursorOffsetX", targetX)
    set(ctx, global, "tooltipCursorOffsetY", targetY)
    if targetX ~= cursorX or targetY ~= cursorY then
        addWarning(ctx, "ElvUI's tooltip cursor offsets exceeded EllesmereUI's ±100 range and were clamped.")
    end

    local fixedPosition, growth = tooltipStaticPosition(ctx, src)
    if fixedPosition then set(ctx, ctx.work, "tooltipFixedPos", fixedPosition) end
    if growth then set(ctx, global, "tooltipGrowthDirection", growth) end
    if not src.cursorAnchor and src.anchorToBags and src.anchorToBags ~= "DISABLED" then
        addWarning(ctx, "ElvUI's dynamic Anchor to Bags behavior has no EllesmereUI equivalent; the fixed placement was migrated.")
    end

    local modifiers = {
        SHOW = "none",
        SHIFT = "shift",
        CTRL = "control",
        ALT = "alt",
    }
    local sourceModifier = tostring(src.modifierID or "HIDE"):upper()
    local targetModifier = modifiers[sourceModifier]
    local showIDs = targetModifier ~= nil
    if sourceModifier ~= "HIDE" and not targetModifier then
        addWarning(ctx, "ElvUI's tooltip ID modifier '" .. sourceModifier
            .. "' has no direct EllesmereUI equivalent; spell and item IDs were disabled.")
    end
    set(ctx, global, "showSpellID", showIDs)
    set(ctx, global, "showItemID", showIDs)
    set(ctx, global, "showIconID", false)
    set(ctx, global, "spellIDModifier", targetModifier or "none")
end

local MIGRATORS = {
    appearance = migrateAppearance,
    player = migratePlayer,
    target = migrateTarget,
    otherUnits = migrateOtherUnits,
    party = migrateParty,
    raid = migrateRaid,
    actionBars = migrateActionBars,
    minimap = migrateMinimap,
    tooltips = migrateTooltips,
}

local function validateProfileName(name)
    name = trim(name)
    if name == "" then return nil, "Enter a name for the new EllesmereUI profile." end
    if #name > 48 then return nil, "Profile names must be 48 characters or fewer." end
    if name:find("[%c]") then return nil, "Profile names cannot contain control characters." end
    return name
end

local function beginMigration(profileName, selected)
    local validName, nameError = validateProfileName(profileName)
    if not validName then return nil, nameError end
    if type(selected) ~= "table" then return nil, "No migration components were selected." end

    local source, sourceError = sourceInfo()
    if not source then return nil, sourceError end
    local suite = _G.EllesmereUI
    if type(suite) ~= "table" or type(suite.GetProfilesDB) ~= "function" or type(suite.SaveCurrentAsProfile) ~= "function" then
        return nil, "EllesmereUI 8.7.3 or newer is required."
    end

    local profilesDB = suite.GetProfilesDB()
    if type(profilesDB.profiles) == "table" and profilesDB.profiles[validName] then
        return nil, "An EllesmereUI profile named '" .. validName .. "' already exists. Choose a new name."
    end

    local components = {}
    for _, component in ipairs(ns.Components) do
        if selected[component.key] then components[#components + 1] = component end
    end
    if #components == 0 then return nil, "Select at least one component to migrate." end

    local currentName = profilesDB.activeProfile or "Default"
    local current = profilesDB.profiles and profilesDB.profiles[currentName] or {}
    return {
        profileName = validName,
        suite = suite,
        profilesDB = profilesDB,
        components = components,
        ctx = {
            source = source.profile,
            sourceName = source.name,
            work = deepCopy(current),
            globalWork = {},
            copied = 0,
            warnings = {},
            warningSet = {},
            migrated = {},
        },
    }
end

local function migrateComponent(state, component)
    local ok, migrationError = pcall(MIGRATORS[component.key], state.ctx)
    if not ok then return false, "Migration preparation failed: " .. tostring(migrationError) end
    state.ctx.migrated[#state.ctx.migrated + 1] = component.label
    return true
end

local function commitMigration(state)
    local suite, profilesDB, validName = state.suite, state.profilesDB, state.profileName
    local createdOk, createError = pcall(suite.SaveCurrentAsProfile, validName)
    if not createdOk then return false, "EllesmereUI could not create the profile: " .. tostring(createError) end
    local created = profilesDB.profiles and profilesDB.profiles[validName]
    if type(created) ~= "table" then return false, "EllesmereUI did not create the requested profile." end

    local commitOk, commitError = pcall(function()
        syncTable(created, state.ctx.work)
        for key, value in pairs(state.ctx.globalWork) do
            profilesDB[key] = deepCopy(value)
        end
        -- SaveCurrentAsProfile switches to the new profile before we apply the
        -- converted font snapshot. Keep EllesmereUI's live font table aligned,
        -- otherwise its logout hook would copy the old font back over this one.
        if type(created.fonts) == "table" and type(suite.GetFontsDB) == "function" then
            syncTable(suite.GetFontsDB(), created.fonts)
            if suite.InvalidateFontCache then suite.InvalidateFontCache() end
        end
    end)
    if not commitOk then
        return false, "The new profile was created, but settings could not be committed: " .. tostring(commitError)
    end

    profilesDB.activeProfile = validName
    if type(_G.EllesmereUIDB) == "table" then
        _G.EllesmereUIDB.firstInstallPopupShown = true
    end

    return true, {
        profileName = validName,
        sourceName = state.ctx.sourceName,
        copied = state.ctx.copied,
        warnings = state.ctx.warnings,
        components = state.ctx.migrated,
    }
end

function ns.RunMigration(profileName, selected)
    local state, startError = beginMigration(profileName, selected)
    if not state then return false, startError end
    for _, component in ipairs(state.components) do
        local ok, migrationError = migrateComponent(state, component)
        if not ok then return false, migrationError end
    end
    return commitMigration(state)
end

function ns.StartMigration(profileName, selected, onProgress, onComplete)
    local state, startError = beginMigration(profileName, selected)
    if not state then return false, startError end

    local defer = C_Timer and C_Timer.After
    -- Give the client a short render beat before each unit of work so the
    -- current phase is visible even when every conversion itself is quick.
    local function nextFrame(callback)
        if defer then defer(0.03, callback) else callback() end
    end
    local function progress(completed, total, message)
        if onProgress then onProgress(completed, total, message) end
    end
    local function finish(ok, result)
        if onComplete then onComplete(ok, result) end
    end

    local componentIndex = 1
    local componentCount = #state.components
    local totalSteps = componentCount + 1

    local announceNext
    announceNext = function()
        local component = state.components[componentIndex]
        if not component then
            progress(componentCount, totalSteps, "Creating the EllesmereUI profile…")
            nextFrame(function()
                local ok, result = commitMigration(state)
                if ok then progress(totalSteps, totalSteps, "Profile ready") end
                finish(ok, result)
            end)
            return
        end

        progress(componentIndex - 1, totalSteps, "Copying " .. component.label:lower() .. "…")
        nextFrame(function()
            local ok, migrationError = migrateComponent(state, component)
            if not ok then finish(false, migrationError); return end
            progress(componentIndex, totalSteps, component.label .. " copied")
            componentIndex = componentIndex + 1
            nextFrame(announceNext)
        end)
    end

    progress(0, totalSteps, "Preparing migration…")
    nextFrame(announceNext)
    return true
end

ns._Test = {
    deepCopy = deepCopy,
    parseMover = parseMover,
    outlineMode = outlineMode,
    textureKey = textureKey,
    syncTable = syncTable,
    barVisibility = barVisibility,
    visibilitySettings = visibilitySettings,
    growthPair = growthPair,
}
