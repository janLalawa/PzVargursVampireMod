require("ISUI/ISCollapsableWindow")

local Config = require("VargursVampires/Infrastructure/Config")
local ProtectionValues = require("VargursVampires/Mechanics/Sun/Protection/Clothing/ProtectionValues")
local SunExposure = require("VargursVampires/Mechanics/Sun/SunExposure")
local SunEffectCalculator = require("VargursVampires/Mechanics/Sun/SunEffectCalculator")

local WINDOW_WIDTH = 1180
local WINDOW_HEIGHT = 720
local SAMPLE_INTERVAL_MS = 250
local ROW_HEIGHT = 24
local GAME_MINUTES_PER_DAY = 24 * 60
local FULL_HEALTH = 100.0

---@class VargursSunDebugWindow : ISCollapsableWindow
---@field nextSampleAt number
---@field model PlayerSunModel|nil
local SunDebugWindow = ISCollapsableWindow:derive("VargursSunDebugWindow")
---@type VargursSunDebugWindow|nil
local activeWindow

local regionNames = {}
for regionName in pairs(ProtectionValues.regions) do
    table.insert(regionNames, regionName)
end
table.sort(regionNames)

local function formatFactor(value)
    return string.format("%.2f", value or 0.0)
end

local function formatTime(timeOfDay)
    local hour = math.floor(timeOfDay or 0.0)
    local minute = math.floor(((timeOfDay or 0.0) - hour) * 60.0)
    return string.format("%02d:%02d", hour, minute)
end

function SunDebugWindow:initialise()
    ISCollapsableWindow.initialise(self)
end

function SunDebugWindow:prerender()
    ISCollapsableWindow.prerender(self)
    local now = getTimestampMs()
    if now < self.nextSampleAt then
        return
    end

    self.nextSampleAt = now + SAMPLE_INTERVAL_MS
    self.model = SunExposure.sample(getSpecificPlayer(0), nil, true)
    SunEffectCalculator.calculateRates(self.model, Config.get())
end

local function drawText(window, text, x, y, color)
    color = color or { r = 0.92, g = 0.92, b = 0.92, a = 1.0 }
    window:drawText(text, x, y, color.r, color.g, color.b, color.a, UIFont.Small)
end

function SunDebugWindow:render()
    ISCollapsableWindow.render(self)

    local model = self.model
    if not model then
        drawText(self, "Waiting for the local player...", 12, 32)
        return
    end

    local debug = assert(model.debug, "Sun debug sample expected")
    local environment = debug.environment
    local lineHeight = 23
    local y = 41
    local rightColumnX = math.floor(self.width / 2)
    drawText(self, string.format("Time: %s  |  Daylight: %s",
        formatTime(environment.timeOfDay),
        formatFactor(environment.daylightIntensity)), 12, y)
    drawText(self, string.format("UV env: %s  |  Total weighted: %s",
        formatFactor(debug.environmentalUV),
        formatFactor(model.totalWeightedUV)), rightColumnX, y)
    y = y + lineHeight

    drawText(self, string.format("Weather: cloud %s  |  rain %s  |  fog %s",
        formatFactor(environment.cloudMultiplier),
        formatFactor(environment.rainMultiplier),
        formatFactor(environment.fogMultiplier)), 12, y)
    drawText(self, string.format("Selected shade: %s  |  Indoor/window: %s",
        formatFactor(environment.shadeMultiplier),
        formatFactor(environment.indoorWindowMultiplier)), rightColumnX, y)
    y = y + lineHeight

    drawText(self, string.format("Umbrella: %s  |  Active location: %s",
        formatFactor(environment.umbrellaMultiplier),
        formatFactor(environment.positionMultiplier)), 12, y)
    drawText(self, string.format("Trait: %s  |  Config UV: %s  |  Env x: %s",
        formatFactor(environment.traitMultiplier),
        formatFactor(environment.configuredUVMultiplier),
        formatFactor(environment.protectionMultiplier)), rightColumnX, y)
    y = y + lineHeight

    y = y + lineHeight + 8

    local columns = {
        { label = "Region", width = 145 },
        { label = "Wt", width = 65 },
        { label = "UV env", width = 92 },
        { label = "Dmg/min", width = 90 },
        { label = "UV cloth", width = 90 },
        { label = "Weighted UV", width = 115 },
        { label = "Cloth x", width = 90 },
        { label = "Lyr", width = 50 },
        { label = "Layer x", width = 80 },
        { label = "Wind x", width = 80 },
        { label = "Item x", width = 80 },
    }
    local columnX = {}
    local x = 12
    for index, column in ipairs(columns) do
        columnX[index] = x
        drawText(self, column.label, x, y, { r = 0.85, g = 0.72, b = 0.42, a = 1.0 })
        x = x + column.width + 14
    end
    y = y + lineHeight

    for _, regionName in ipairs(regionNames) do
        local region = model.regions[regionName]
        local regionDebug = assert(region.debug, "Sun region debug sample expected")
        local values = {
            regionName,
            formatFactor(region.weight),
            formatFactor(regionDebug.uvBeforeClothing),
            formatFactor(region.damagePerMinute),
            formatFactor(region.effectiveUV),
            formatFactor(region.weightedUV),
            formatFactor(region.transmission),
            tostring(region.intactLayers),
            formatFactor(regionDebug.layerTransmission),
            formatFactor(regionDebug.windTransmissionMultiplier),
            formatFactor(regionDebug.itemTransmissionMultiplier),
        }
        for index, value in ipairs(values) do
            drawText(self, value, columnX[index], y)
        end
        y = y + ROW_HEIGHT
    end

    y = y + 3
    drawText(self, string.format("Total health damage / game min: %s",
        formatFactor(debug.totalDamagePerGameMinute)), 12, y, { r = 0.85, g = 0.72, b = 0.42, a = 1.0 })
    local realSecondsPerGameMinute = getGameTime():getMinutesPerDay() * 60.0 / GAME_MINUTES_PER_DAY
    local timeToKill = debug.totalDamagePerGameMinute > 0.0
        and string.format("%.2f sec", FULL_HEALTH / debug.totalDamagePerGameMinute * realSecondsPerGameMinute)
        or "n/a"
    drawText(self, "Full-health time to kill: " .. timeToKill, rightColumnX, y, { r = 0.85, g = 0.72, b = 0.42, a = 1.0 })

end

function SunDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if activeWindow == self then
        activeWindow = nil
    end
end

function SunDebugWindow:new(x, y, width, height)
    ---@type VargursSunDebugWindow
    local window = ISCollapsableWindow.new(self, x, y, width, height)
    window.title = "Vargur's Vampires - Sun Debug"
    window.resizable = false
    window.nextSampleAt = 0
    return window
end

local function toggleWindow(key)
    if key ~= Keyboard.KEY_RBRACKET or not getSpecificPlayer(0) then
        return
    end

    if activeWindow then
        activeWindow:close()
        return
    end

    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    local width = math.min(WINDOW_WIDTH, screenWidth - 24)
    local height = math.min(WINDOW_HEIGHT, screenHeight - 24)
    activeWindow = SunDebugWindow:new((screenWidth - width) / 2, (screenHeight - height) / 2, width, height)
    activeWindow:initialise()
    activeWindow:addToUIManager()
    activeWindow:setVisible(true)
end

local function closeWindow()
    if activeWindow then
        activeWindow:close()
    end
end

Events.OnKeyPressed.Add(toggleWindow)
Events.OnMainMenuEnter.Add(closeWindow)
Events.OnDisconnect.Add(closeWindow)

return SunDebugWindow