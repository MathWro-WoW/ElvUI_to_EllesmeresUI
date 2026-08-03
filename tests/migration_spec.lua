local ns = {}
assert(loadfile("Migration.lua"))("ElvUI_to_EllesmeresUI", ns)

local function color(r, g, b, a) return { r = r, g = g, b = b, a = a or 1 } end
local function aura(enabled, point, size, perrow)
    return {
        enable = enabled, anchorPoint = point, height = size, perrow = perrow, numrows = 1,
        xOffset = 2, yOffset = -3, durationFontSize = 9, spacing = 1,
    }
end
local function unit(width, height, enabled)
    return {
        enable = enabled ~= false,
        width = width, height = height,
        power = { enable = true, height = 6, reverseFill = true, smoothbars = true },
        health = { reverseFill = true, smoothbars = true, text_format = "[perhp]", xOffset = -2, yOffset = 1 },
        portrait = { enable = true, style = "3D", width = 42, xOffset = 1, yOffset = 2 },
        name = { position = "TOPLEFT", xOffset = 3, yOffset = -2 },
        buffs = aura(true, "TOPLEFT", 22, 4),
        debuffs = aura(true, "BOTTOMLEFT", 24, 5),
        castbar = {
            enable = true, icon = true, width = width, height = 16, displayTarget = true,
            reverse = true, customColor = { enable = true, color = color(0.4, 0.5, 0.6), useClassColor = false },
        },
        fader = { enable = true, combat = true, minAlpha = 0.4 },
    }
end
local function group(width, height, growth)
    local value = unit(width, height, true)
    value.growthDirection = growth
    value.horizontalSpacing = 3
    value.verticalSpacing = 2
    value.groupSpacing = 5
    value.spacing = 5
    value.groupBy = "ROLE"
    value.sortDir = "ASC"
    value.showPlayer = true
    value.numGroups = 6
    value.raidicon = { enable = true, size = 18, attachTo = "TOPRIGHT" }
    return value
end
local function bar(enabled, buttons, perrow, size)
    return {
        enabled = enabled, buttons = buttons, buttonsPerRow = perrow,
        buttonSize = size, buttonHeight = size + 1, buttonSpacing = 3,
        visibility = "[vehicleui] hide; show", mouseover = false, clickThrough = false,
        backdrop = true, hotkeytext = true, hotkeyFontSize = 11, hotkeyColor = color(1, 1, 1),
        macrotext = true, macroFontSize = 10, macroColor = color(0.8, 0.8, 0.8),
        countFontSize = 9, countColor = color(1, 0.9, 0.6),
    }
end

local function expectVisibility(source, expectedMode, expectedModes, intrinsicPet, intrinsicHides)
    local result = ns._Test.visibilitySettings(source, intrinsicPet, intrinsicHides)
    assert(result.mode == expectedMode, result.mode .. " ~= " .. expectedMode)
    if expectedModes then
        assert(type(result.modes) == "table")
        for key, expected in pairs(expectedModes) do assert(result.modes[key] == expected, key) end
        for key in pairs(result.modes) do assert(expectedModes[key] == true, "unexpected mode " .. key) end
    else
        assert(result.modes == nil)
    end
    return result
end

expectVisibility({ enabled = true, visibility = "show" }, "always")
expectVisibility({ enabled = false, visibility = "show", mouseover = true }, "never")
expectVisibility({ enabled = true, visibility = "[petbattle] hide; show", mouseover = true }, "mouseover")
local unsupportedMainGuard = expectVisibility(
    { enabled = true, visibility = "[vehicleui] hide; show" },
    "always",
    nil,
    false,
    { petbattle = true }
)
assert(unsupportedMainGuard.unsupported == true)
expectVisibility({ enabled = true, visibility = "[combat] show; hide" }, "in_combat")
expectVisibility({ enabled = true, visibility = "[nocombat] show; hide" }, "out_of_combat")
expectVisibility({ enabled = true, visibility = "[group:raid] show; hide" }, "in_raid")
expectVisibility({ enabled = true, visibility = "[group:party,nogroup:raid] show; hide" }, "in_party")
expectVisibility({ enabled = true, visibility = "[group] show; hide" }, "in_raid", { in_raid = true, in_party = true })
expectVisibility({ enabled = true, visibility = "[nogroup] show; hide" }, "solo")
expectVisibility({ enabled = true, visibility = "[advflyable,flying] show; hide" }, "show_dragonriding")
expectVisibility({ enabled = true, visibility = "[advflyable,flying] hide; show" }, "show_not_dragonriding")
expectVisibility(
    { enabled = true, visibility = "[combat,group:party] show; hide", mouseover = true },
    "mouseover",
    { in_combat = true, in_party = true, mouseover = true }
)
local hideOptions = expectVisibility(
    { enabled = true, visibility = "[mounted] hide; [noexists] hide; [noharm] hide; show" },
    "always"
)
assert(hideOptions.visHideMounted and hideOptions.visHideNoTarget and hideOptions.visHideNoEnemy)
local unsupportedVisibility = expectVisibility(
    { enabled = true, visibility = "[mod:shift] show; hide" },
    "always"
)
assert(unsupportedVisibility.unsupported == true)
expectVisibility(
    { enabled = true, visibility = "[petbattle] hide; [novehicleui,pet,nooverridebar,nopossessbar] show; hide" },
    "always",
    nil,
    true
)

local sourceProfile = {
    general = {
        font = "Homespun", fontOutline = "MONOCHROMEOUTLINE",
        minimap = {
            size = 180, scale = 0.9, circle = true, rotate = true,
            locationText = "MOUSEOVER", locationFontSize = 14, timeFontSize = 12,
            icons = { tracking = { hide = true }, calendar = { hide = false } },
        },
    },
    unitframe = {
        statusbar = "ElvUI Norm", font = "Homespun", fontSize = 12, fontOutline = "OUTLINE",
        colors = {
            healthclass = true, classbackdrop = false,
            health = color(0.2, 0.3, 0.4), health_backdrop = color(0.05, 0.06, 0.07),
        },
        units = {
            player = unit(260, 56), target = unit(250, 54), focus = unit(180, 40),
            pet = unit(130, 34), targettarget = unit(125, 32), focustarget = unit(120, 30, false),
            boss = group(210, 45, "DOWN_RIGHT"), party = group(180, 52, "UP_RIGHT"),
            raid1 = group(88, 44, "RIGHT_DOWN"), raid2 = group(82, 30, "RIGHT_DOWN"),
        },
    },
    actionbar = {
        fontSize = 10, fontColor = color(1, 1, 1), noRangeColor = color(0.8, 0.1, 0.1),
        useRangeColorText = false, desaturateOnCooldown = true,
        bar1 = bar(true, 12, 12, 32), bar2 = bar(true, 10, 5, 30),
        bar3 = bar(true, 12, 1, 28), bar6 = bar(false, 12, 12, 31),
        stanceBar = bar(true, 8, 8, 26), barPet = bar(true, 10, 10, 27),
    },
    bags = {
        bagBar = { mouseover = false, visibility = "[noexists] hide; show" },
    },
    movers = {
        ElvUF_PlayerMover = "BOTTOM,ElvUIParent,BOTTOM,-330,140",
        ElvUF_TargetMover = "BOTTOM,ElvUIParent,BOTTOM,330,140",
        ElvUF_FocusMover = "CENTER,ElvUIParent,CENTER,0,-240",
        ElvUF_PetMover = "BOTTOM,ElvUIParent,BOTTOM,-330,100",
        ElvUF_TargetTargetMover = "BOTTOM,ElvUIParent,BOTTOM,330,100",
        BossHeaderMover = "RIGHT,ElvUIParent,RIGHT,-100,100",
        ElvUF_PartyMover = "LEFT,ElvUIParent,LEFT,200,0",
        ElvUF_Raid1Mover = "LEFT,ElvUIParent,LEFT,300,0",
        ElvAB_1 = "BOTTOM,ElvUIParent,BOTTOM,0,180",
        ElvAB_2 = "BOTTOM,ElvUIParent,BOTTOM,0,140",
        ElvAB_3 = "RIGHT,ElvUIParent,RIGHT,-40,0",
        ElvAB_6 = "BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-20,260",
        ShiftAB = "BOTTOM,ElvUIParent,BOTTOM,0,80",
        PetAB = "RIGHT,ElvUIParent,RIGHT,-20,0",
        MinimapMover = "TOPRIGHT,ElvUIParent,TOPRIGHT,-12,-12",
    },
}
sourceProfile.actionbar.bar1.visibility = "[petbattle] hide; show"

sourceProfile.actionbar.bar1.mouseover = true
sourceProfile.actionbar.bar1.alpha = 0.72
sourceProfile.actionbar.bar2.visibility = "[combat] show; hide"
sourceProfile.actionbar.bar3.visibility = "[group:raid] show; hide"
sourceProfile.actionbar.stanceBar.visibility = "[mounted] hide; show"
sourceProfile.actionbar.barPet.visibility = "[petbattle] hide; [novehicleui,pet,nooverridebar,nopossessbar] show; hide"
sourceProfile.actionbar.microbar = {
    enabled = true,
    mouseover = true,
    alpha = 0.6,
    visibility = "[nocombat] show; hide",
}

ElvUI = {
    {
        db = sourceProfile,
        data = { keys = { profile = "Fixture Healer" } },
        mynameRealm = "Tester - Realm",
    },
}

EllesmereUIDB = {
    activeProfile = "Default",
    profileOrder = { "Default" },
    fonts = { global = "Expressway", outlineMode = "none" },
    profiles = {
        Default = {
            fonts = { global = "Expressway", outlineMode = "none" },
            addons = {
                EllesmereUIUnitFrames = { player = { frameWidth = 181 } },
                EllesmereUIRaidFrames = {}, EllesmereUIActionBars = {}, EllesmereUIMinimap = {},
            },
        },
    },
}

EllesmereUI = {}
function EllesmereUI.GetProfilesDB() return EllesmereUIDB end
function EllesmereUI.GetFontsDB() return EllesmereUIDB.fonts end
function EllesmereUI.SaveCurrentAsProfile(name)
    local source = EllesmereUIDB.profiles[EllesmereUIDB.activeProfile]
    EllesmereUIDB.profiles[name] = ns._Test.deepCopy(source)
    table.insert(EllesmereUIDB.profileOrder, 1, name)
    EllesmereUIDB.activeProfile = name
end

local selected = {}
for _, component in ipairs(ns.Components) do selected[component.key] = true end
local ok, result = ns.RunMigration("Imported Fixture", selected)
assert(ok, result)
assert(result.profileName == "Imported Fixture")
assert(result.sourceName == "Fixture Healer")
assert(result.copied > 100)

local profile = assert(EllesmereUIDB.profiles["Imported Fixture"])
assert(EllesmereUIDB.activeProfile == "Imported Fixture")
assert(profile.fonts.global == "Homespun")
assert(EllesmereUIDB.fonts.global == "Homespun")
assert(EllesmereUIDB.fonts.outlineMode == "outline")
assert(profile.fonts.outlineMode == "outline")

local uf = assert(profile.addons.EllesmereUIUnitFrames)
assert(uf.healthBarTexture == "melli")
assert(uf.player.frameWidth == 260)
assert(uf.player.healthHeight == 50)
assert(uf.player.powerHeight == 6)
assert(uf.player.showPlayerCastbar == true)
assert(uf.player.playerCastbarHeight == 16)
assert(uf.frameSource.focustarget == "hidden")
assert(uf.positions.player.point == "BOTTOM")
assert(uf.positions.player.x == -330)
assert(uf.bossSpacing == 5)

local rf = assert(profile.addons.EllesmereUIRaidFrames)
assert(rf.frameWidth == 88 and rf.frameHeight == 44)
assert(rf.unitGrowth == "RIGHT" and rf.groupGrowth == "DOWN")
assert(rf.visibleGroups[6] == true and rf.visibleGroups[7] == false)
assert(rf.partyFrameWidth == 180 and rf.partyFrameHeight == 52)
assert(rf.partyHorizontal == false and rf.partyFlipGrowth == true)
assert(rf.partyCellSpacing == 3)
assert(rf.partySyncSections.healthBar == false)
assert(rf.party_healthBarTexture == "melli")
assert(rf.raidSizeOverrides[25].width == 82)
assert(rf.raidSizeOverrides[30].height == 30)

local ab = assert(profile.addons.EllesmereUIActionBars)
assert(ab.bars.MainBar.overrideNumIcons == 12)
assert(ab.bars.Bar9.overrideNumIcons == 10)
assert(ab.bars.Bar9.overrideNumRows == 2)
assert(ab.bars.Bar4.orientation == "vertical")
assert(ab.bars.Bar2.alwaysHidden == true)
assert(ab.bars.MainBar.barVisibility == "mouseover")
assert(ab.bars.MainBar.mouseoverEnabled == true and ab.bars.MainBar.mouseoverAlpha == 0)
assert(ab.bars.MainBar._savedBarAlpha == 0.72)
assert(ab.bars.Bar9.barVisibility == "in_combat" and ab.bars.Bar9.combatShowEnabled == true)
assert(ab.bars.Bar4.barVisibility == "in_raid")
assert(ab.bars.Bar2.barVisibility == "never")
assert(ab.bars.StanceBar.visHideMounted == true)
assert(ab.bars.PetBar.barVisibility == "always")
assert(ab.bars.MicroBar.barVisibility == "mouseover")
assert(ab.bars.MicroBar.visibilityModes.out_of_combat == true)
assert(ab.bars.MicroBar.visibilityModes.mouseover == true)
assert(ab.bars.MicroBar.combatHideEnabled == true)
assert(ab.bars.MicroBar._savedBarAlpha == 0.6)
assert(ab.bars.BagBar.barVisibility == "always")
assert(ab.bars.BagBar.visHideNoTarget == true)
assert(ab.barPositions.MainBar.y == 180)
assert(ab.desaturateOnCooldown == true)

local mm = assert(profile.addons.EllesmereUIMinimap.minimap)
assert(mm.mapSize == 162)
assert(mm.shape == "circle" and mm.rotateMinimap == true)
assert(mm.position.point == "TOPRIGHT")
assert(mm.hideTrackingButton == true)

assert(sourceProfile.unitframe.units.player.width == 260)
local duplicate, duplicateError = ns.RunMigration("Imported Fixture", selected)
assert(duplicate == false and duplicateError:find("already exists", 1, true))
local empty, emptyError = ns.RunMigration("Empty Selection", {})
assert(empty == false and emptyError:find("Select at least one", 1, true))

local supportedVisibility = sourceProfile.actionbar.bar1.visibility
sourceProfile.actionbar.bar1.visibility = "[mod:shift] show; hide"
local fallbackOK, visibilityFallback = ns.RunMigration("Visibility Fallback", { actionBars = true })
assert(fallbackOK)
assert(#visibilityFallback.warnings == 1)
assert(visibilityFallback.warnings[1]:find("without a direct EllesmereUI equivalent", 1, true))
assert(EllesmereUIDB.profiles["Visibility Fallback"].addons.EllesmereUIActionBars.bars.MainBar.barVisibility == "mouseover")
sourceProfile.actionbar.bar1.visibility = supportedVisibility

local timerQueue = {}
C_Timer = {
    After = function(_, callback)
        timerQueue[#timerQueue + 1] = callback
    end,
}
local progressEvents = {}
local stagedResult
local stagedStarted, stagedError = ns.StartMigration(
    "Staged Fixture",
    { appearance = true, player = true },
    function(completed, total, message)
        progressEvents[#progressEvents + 1] = {
            completed = completed,
            total = total,
            message = message,
        }
    end,
    function(ok, value)
        stagedResult = { ok = ok, value = value }
    end
)
assert(stagedStarted, stagedError)
assert(#progressEvents == 1 and progressEvents[1].completed == 0)
assert(EllesmereUIDB.profiles["Staged Fixture"] == nil)
assert(#timerQueue == 1)

table.remove(timerQueue, 1)()
assert(progressEvents[2].message:find("Copying", 1, true))
assert(EllesmereUIDB.profiles["Staged Fixture"] == nil)
while #timerQueue > 0 do table.remove(timerQueue, 1)() end

assert(stagedResult and stagedResult.ok == true)
assert(stagedResult.value.profileName == "Staged Fixture")
assert(progressEvents[#progressEvents].completed == progressEvents[#progressEvents].total)
assert(progressEvents[#progressEvents].message == "Profile ready")

local oldElv = ElvUI
ElvUI = nil
local missing, missingError = ns.RunMigration("No Source", selected)
assert(missing == false and missingError:find("not loaded", 1, true))
ElvUI = oldElv

print(("migration fixture passed: %d settings, %d warnings"):format(result.copied, #result.warnings))
