local defaults = {
    enabled = true,
    difficultyPreset = 1,
    uninstall = 0,
    bloodLoot = 0.6,
    vampireHealthRegenMultiplier = 5,
    sunDamageEnabled = true,
    sunBurnRandomChance = 0.01,
    sunAttenuationClouds = 0.3,
    sunAttenuationPrecipitation = 0.7,
    sunAttenuationFog = 0.6,
    sunAttenuationVehicle = 0.85,
    sunEnvironmentalUVMultiplier = 1,
    sunDaylightCurveExponent = 0.5,
    sunNoonIntensityBonus = 0.4,
    sunNoonIntensityWidthHours = 1,
    sunDamagePerMinute = 16,
}

---@type table<integer, table<string, number>?>
local difficultyPresets = {
    [2] = { -- Forgiving
        sunDamagePerMinute = 5.0,
        sunEnvironmentalUVMultiplier = 0.8,
        sunBurnRandomChance = 0.005,
    },
    [3] = { -- Standard
        sunDamagePerMinute = 18.0,
        sunEnvironmentalUVMultiplier = 1.0,
        sunBurnRandomChance = 0.01,
    },
    [4] = { -- Hard
        sunDamagePerMinute = 25.0,
        sunEnvironmentalUVMultiplier = 1.2,
        sunBurnRandomChance = 0.02,
    },
    [5] = { -- Brutal
        sunDamagePerMinute = 50.0,
        sunEnvironmentalUVMultiplier = 1.5,
        sunBurnRandomChance = 0.05,
    },
    [6] = { -- Actually Too Hard You Will Die
        sunDamagePerMinute = 150.0,
        sunEnvironmentalUVMultiplier = 3.0,
        sunBurnRandomChance = 0.1,
    },
}

local bounds = {
    uninstall = { 0, 1 },
    bloodLoot = { 0.0, 4.0 },
    vampireHealthRegenMultiplier = { 0.0, 10.0 },
    sunBurnRandomChance = { 0.0, 1.0 },
    sunAttenuationClouds = { 0.0, 1.0 },
    sunAttenuationPrecipitation = { 0.0, 1.0 },
    sunAttenuationFog = { 0.0, 1.0 },
    sunAttenuationVehicle = { 0.0, 1.0 },
    sunEnvironmentalUVMultiplier = { 0.0, 3.0 },
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
    local values = SandboxVars.VargursVampires
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

local function difficultyValue(values)
    local selectedPreset = values.DifficultyPreset
    if difficultyPresets[selectedPreset] then
        return selectedPreset
    end
    return defaults.difficultyPreset
end

function Config.get()
    if normalizedConfigCache then
        return normalizedConfigCache
    end

    local values = sandboxValues()
    local uninstall = numberValue(values, "uninstall", "Uninstall") >= 1
    normalizedConfigCache = {
        enabled = booleanValue(values, "enabled", "Enabled") and not uninstall,
        difficultyPreset = difficultyValue(values),
        uninstall = uninstall,
        bloodLoot = uninstall and 0.0 or numberValue(values, "bloodLoot", "BloodLoot"),
        vampireHealthRegenMultiplier = numberValue(values, "vampireHealthRegenMultiplier", "VampireHealthRegenMultiplier"),
        sunDamageEnabled = booleanValue(values, "sunDamageEnabled", "SunDamageEnabled"),
        sunBurnRandomChance = numberValue(values, "sunBurnRandomChance", "SunBurnRandomChance"),
        sunAttenuationClouds = numberValue(values, "sunAttenuationClouds", "SunAttenuationClouds"),
        sunAttenuationPrecipitation = numberValue(values, "sunAttenuationPrecipitation", "SunAttenuationPrecipitation"),
        sunAttenuationFog = numberValue(values, "sunAttenuationFog", "SunAttenuationFog"),
        sunAttenuationVehicle = numberValue(values, "sunAttenuationVehicle", "SunAttenuationVehicle"),
        sunEnvironmentalUVMultiplier = numberValue(values, "sunEnvironmentalUVMultiplier", "SunEnvironmentalUVMultiplier"),
        sunDaylightCurveExponent = numberValue(values, "sunDaylightCurveExponent", "SunDaylightCurveExponent"),
        sunNoonIntensityBonus = numberValue(values, "sunNoonIntensityBonus", "SunNoonIntensityBonus"),
        sunNoonIntensityWidthHours = numberValue(values, "sunNoonIntensityWidthHours", "SunNoonIntensityWidthHours"),
        sunDamagePerMinute = numberValue(values, "sunDamagePerMinute", "SunDamagePerMinute"),
    }
    local preset = difficultyPresets[normalizedConfigCache.difficultyPreset]
    if preset then
        for field, value in pairs(preset) do
            normalizedConfigCache[field] = value
        end
    end
    return normalizedConfigCache
end

-- Needed to reload sandbox settings early enough for uninstall script :)
if Events and Events.OnGameTimeLoaded then
    Events.OnGameTimeLoaded.Add(function()
        normalizedConfigCache = nil
    end)
end

return Config
