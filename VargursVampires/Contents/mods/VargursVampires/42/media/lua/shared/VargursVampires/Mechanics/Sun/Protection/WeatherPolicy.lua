local Config = require("VargursVampires/Infrastructure/Config")

local WeatherPolicy = {}
local MIN_NORMALIZED_VALUE = 0.0
local MAX_NORMALIZED_VALUE = 1.0

local LINEAR_RESPONSE_EXPONENT = 1.0
local EARLY_RESPONSE_EXPONENT = 0.85

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function attenuationFactor(intensity, maximumAttenuation, responseExponent)
    local normalizedIntensity = clamp(intensity, MIN_NORMALIZED_VALUE, MAX_NORMALIZED_VALUE)
    return 1.0 - normalizedIntensity ^ responseExponent * maximumAttenuation
end

local function cloudMultiplier(climateManager, maximumAttenuation)
    local cloudIntensity = climateManager:getCloudIntensity()
    local responseExponent = LINEAR_RESPONSE_EXPONENT

    return attenuationFactor(cloudIntensity, maximumAttenuation, responseExponent)
end

local function fogMultiplier(climateManager, maximumAttenuation)
    local fogIntensity = climateManager:getFogIntensity()
    local responseExponent = EARLY_RESPONSE_EXPONENT

    return attenuationFactor(fogIntensity, maximumAttenuation, responseExponent)
end

local function precipitationMultiplier(climateManager, maximumAttenuation)
    local precipitationIntensity = climateManager:getPrecipitationIntensity()
    local responseExponent = EARLY_RESPONSE_EXPONENT

    return attenuationFactor(precipitationIntensity, maximumAttenuation, responseExponent)
end

function WeatherPolicy.multiplier()
    local climateManager = getClimateManager()
    local config = Config.get()
    local cloudFactor = cloudMultiplier(climateManager, config.sunAttenuationClouds)
    local fogFactor = fogMultiplier(climateManager, config.sunAttenuationFog)
    local precipitationFactor = precipitationMultiplier(climateManager, config.sunAttenuationPrecipitation)

    return cloudFactor * fogFactor * precipitationFactor
end

return WeatherPolicy
