local Config = require("VargursVampireMod/Infrastructure/Config")
local State = require("VargursVampireMod/PlayerState/State")
---@type VargursSunExposurePolicy
local SunExposure = require("VargursVampireMod/Mechanics/Sun/SunExposure")
local SunEffects = require("VargursVampireMod/Mechanics/Sun/SunEffects")
---@type VargursSunPainPolicy
local SunPain = require("VargursVampireMod/Mechanics/Sun/SunPain")
local OVERLAY_MARGIN = 20
local ROW_PADDING = 2
local COLUMN_PADDING = 14
local SECONDS_PER_MINUTE = 60.0
---@type table<integer, string>
local PAIN_LABELS = { "Minor", "Pain", "Severe", "Agony" }

local function drawLine(manager, font, x, y, text)
    manager:DrawString(font, x, y, text, 1, 1, 1, 1)
end

local function regionStatus(region)
    if region.transmission == 0.0 then
        return "Blocked"
    end
    if region.rawUV > 0.0 and region.effectiveUV == 0.0 then
        return "Cutoff"
    end
    return PAIN_LABELS[SunPain.severity(region.effectiveUV)] or "No sun"
end

local function regionRows(diagnostics)
    local regionNames = {}
    for regionName in pairs(diagnostics.regions) do
        regionNames[#regionNames + 1] = regionName
    end
    table.sort(regionNames)

    local rows = { { "Region", "Layers", "Wind bonus %", "Pass %", "Raw UV", "Final UV", "Dmg/min", "UV / State" } }
    for _, regionName in ipairs(regionNames) do
        local region = diagnostics.regions[regionName]
        local damagePerMinute = SunEffects.damage(region.weightedUV, 1.0, Config.get())
        rows[#rows + 1] = {
            regionName,
            tostring(region.intactLayers),
            string.format("%.1f", region.windProtectionBonus * 100.0),
            string.format("%.1f", region.transmission * 100.0),
            string.format("%.4f", region.rawUV),
            string.format("%.4f", region.effectiveUV),
            string.format("%.3f", damagePerMinute),
            regionStatus(region),
        }
    end
    return rows
end

local function drawRegionTable(manager, font, x, y, rowHeight, diagnostics)
    local rows = regionRows(diagnostics)
    local columnWidths = {}
    for _, row in ipairs(rows) do
        for columnIndex, text in ipairs(row) do
            local textWidth = manager:MeasureStringX(font, text)
            columnWidths[columnIndex] = math.max(columnWidths[columnIndex] or 0, textWidth)
        end
    end

    for _, row in ipairs(rows) do
        local columnX = x
        for columnIndex, text in ipairs(row) do
            drawLine(manager, font, columnX, y, text)
            columnX = columnX + columnWidths[columnIndex] + COLUMN_PADDING
        end
        y = y + rowHeight
    end
end

local function onPostUIDraw()
    if not Config.get().enabled then
        return
    end

    local player = getPlayer()
    if not player or not State.isVampire(player) then
        return
    end

    local state = State.get(player)
    if not state then
        return
    end

    local manager = getTextManager()
    local font = UIFont.Small

    local diagnostics = SunExposure.sample(player)
    local directUV = diagnostics.directUV
    local damageMultiplier = SunEffects.damageMultiplier(directUV)
    local timeOfDay = getGameTime():getTimeOfDay()
    local hour = math.floor(timeOfDay)
    local minute = math.floor((timeOfDay - hour) * SECONDS_PER_MINUTE)
    local daylightIntensity = diagnostics.environment.daylightIntensity
    local weatherMultiplier = diagnostics.environment.weatherMultiplier
    local totalDamagePerMinute = SunEffects.damage(directUV, 1.0, Config.get())
    local summary = {
        string.format("Time: %02d:%02d | Sun stress: %.1f%%", hour, minute, state.sunStress * 100.0),
        string.format("Daylight intensity: %.3f | Weather multiplier: %.3f", daylightIntensity, weatherMultiplier),
        string.format("Environmental UV: %.4f", diagnostics.environmentalUV),
        string.format("Clothing transmission (before cutoff): %.4f", diagnostics.clothingMultiplier),
        string.format("Minimum effective local UV: %.4f", diagnostics.minimumEffectiveUV),
        string.format("Direct UV: %.4f | Sun damage multiplier: %.4f", directUV, damageMultiplier),
        string.format("Total sun damage/min: %.3f", totalDamagePerMinute),
    }
    local rowHeight = manager:getFontHeight(font) + ROW_PADDING
    local x, y = OVERLAY_MARGIN, OVERLAY_MARGIN
    for _, text in ipairs(summary) do
        drawLine(manager, font, x, y, text)
        y = y + rowHeight
    end
    drawRegionTable(manager, font, x, y + rowHeight, rowHeight, diagnostics)
end

Events.OnPostUIDraw.Add(onPostUIDraw)
