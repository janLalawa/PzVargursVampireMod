local Config = require("VargursVampireMod/Infrastructure/Config")
local Constants = require("VargursVampireMod/Infrastructure/Constants")

local TimeOfDayPolicy = {}
local MIN_NORMALIZED_VALUE = 0.0
local MAX_NORMALIZED_VALUE = 1.0
local MIDPOINT_DIVISOR = 2.0
local HALF_CYCLE_RADIANS = math.pi / MIDPOINT_DIVISOR

local function getClimateValues()
    return getClimateManager():getClimateValuesCopy()
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function phaseAtHour(hour, dawn, noon, dusk)
    local morningProgress = clamp((hour - dawn) / (noon - dawn), MIN_NORMALIZED_VALUE, MAX_NORMALIZED_VALUE)
    local eveningProgress = clamp((hour - noon) / (dusk - noon), MIN_NORMALIZED_VALUE, MAX_NORMALIZED_VALUE)
    return (morningProgress + eveningProgress) * HALF_CYCLE_RADIANS
end

local function applyDaylightCurve(intensity)
    local exponent = Config.get().sunDaylightCurveExponent
    return clamp(intensity, MIN_NORMALIZED_VALUE, MAX_NORMALIZED_VALUE) ^ exponent
end

local function noonIntensityBonus(hour, noon)
    local config = Config.get()
    local normalizedOffset = (hour - noon) / config.sunNoonIntensityWidthHours
    local gaussianWeight = math.exp(-(normalizedOffset ^ 2))
    return config.sunNoonIntensityBonus * gaussianWeight
end

local function daylightIntensity(hour, climateValues)
    local dawn = climateValues:getDawn()
    local dusk = climateValues:getDusk()
    local noon = climateValues:getNoon()

    if dawn == dusk then
        return clamp(applyDaylightCurve(climateValues:getDayLightStrength()), MIN_NORMALIZED_VALUE, Constants.MAX_SUN_EXPOSURE_MULTIPLIER)
    end

    if hour <= dawn or hour >= dusk then
        return MIN_NORMALIZED_VALUE
    end

    noon = (noon > dawn and noon < dusk and noon) or (dawn + dusk) / MIDPOINT_DIVISOR
    local baseIntensity = applyDaylightCurve(math.sin(phaseAtHour(hour, dawn, noon, dusk)))
    local intensityWithNoonBonus = baseIntensity + noonIntensityBonus(hour, noon)

    return clamp(intensityWithNoonBonus, MIN_NORMALIZED_VALUE, Constants.MAX_SUN_EXPOSURE_MULTIPLIER)
end

function TimeOfDayPolicy.multiplier()
    local hour = getGameTime():getTimeOfDay()
    return daylightIntensity(hour, getClimateValues())
end

return TimeOfDayPolicy
