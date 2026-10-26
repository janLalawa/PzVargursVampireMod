local defaults = {
    enabled = true,
    startAsVampire = false,
    sunDamageEnabled = true,
    sunEnvironmentalUVMultiplier = 1.1,
    sunDaylightCurveExponent = 0.7,
    sunNoonIntensityBonus = 0.3,
    sunNoonIntensityWidthHours = 0.559,
    sunStressGainFractionPerMinute = 0.24,
    sunStressRecoveryFractionPerMinute = 0.04,
    sunDamagePerMinute = 4.0,
}

local bounds = {
    sunEnvironmentalUVMultiplier = { 0.0, 3.0 },
    sunStressGainFractionPerMinute = { 0.0, 1.0 },
    sunStressRecoveryFractionPerMinute = { 0.0, 1.0 },
    sunDaylightCurveExponent = { 0.1, 1.0 },
    sunNoonIntensityBonus = { 0.0, 1.0 },
    sunNoonIntensityWidthHours = { 0.1, 3.0 },
    sunDamagePerMinute = { 0.0, 100.0 },
}

local Config = {}
---@type table|nil
local normalizedConfigCache

local function sandboxValues()
    if type(SandboxVars) ~= "table" then
        return {}
    end
    local values = SandboxVars.VargursVampireMod
    return type(values) == "table" and values or {}
end

local function booleanValue(values, name, sandboxName)
    local value = values[sandboxName]
    if type(value) == "boolean" then
        return value
    end
    return defaults[name]
end

local function numberValue(values, name, sandboxName)
    local value = values[sandboxName]
    local default = defaults[name]
    if type(default) ~= "number" then
        error("Numeric config default missing for " .. name)
    end
    if type(value) ~= "number" or value ~= value then
        value = default
    end
    local range = bounds[name]
    return math.max(range[1], math.min(range[2], value))
end

function Config.get()
    if normalizedConfigCache then
        return normalizedConfigCache
    end

    local values = sandboxValues()
    normalizedConfigCache = {
        enabled = booleanValue(values, "enabled", "Enabled"),
        startAsVampire = booleanValue(values, "startAsVampire", "StartAsVampire"),
        sunDamageEnabled = booleanValue(values, "sunDamageEnabled", "SunDamageEnabled"),
        sunEnvironmentalUVMultiplier = numberValue(values, "sunEnvironmentalUVMultiplier", "SunEnvironmentalUVMultiplier"),
        sunDaylightCurveExponent = numberValue(values, "sunDaylightCurveExponent", "SunDaylightCurveExponent"),
        sunNoonIntensityBonus = numberValue(values, "sunNoonIntensityBonus", "SunNoonIntensityBonus"),
        sunNoonIntensityWidthHours = numberValue(values, "sunNoonIntensityWidthHours", "SunNoonIntensityWidthHours"),
        sunStressGainFractionPerMinute = numberValue(values, "sunStressGainFractionPerMinute", "SunStressGainFractionPerMinute"),
        sunStressRecoveryFractionPerMinute = numberValue(values, "sunStressRecoveryFractionPerMinute", "SunStressRecoveryFractionPerMinute"),
        sunDamagePerMinute = numberValue(values, "sunDamagePerMinute", "SunDamagePerMinute"),
    }
    return normalizedConfigCache
end

return Config
