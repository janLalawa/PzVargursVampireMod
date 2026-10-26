local WeatherPolicy = {}
local MIN_NORMALIZED_VALUE = 0.0
local MAX_NORMALIZED_VALUE = 1.0

local MAX_CLOUD_ATTENUATION = 0.3
local MAX_FOG_ATTENUATION = 0.45
local MAX_PRECIPITATION_ATTENUATION = 0.4

local LINEAR_RESPONSE_EXPONENT = 1.0
local EARLY_RESPONSE_EXPONENT = 0.85

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function attenuationFactor(intensity, maximumAttenuation, responseExponent)
    local normalizedIntensity = clamp(intensity, MIN_NORMALIZED_VALUE, MAX_NORMALIZED_VALUE)
    return 1.0 - normalizedIntensity ^ responseExponent * maximumAttenuation
end

local function cloudMultiplier(climateManager)
    local cloudIntensity = climateManager:getCloudIntensity()
    local maximumAttenuation = MAX_CLOUD_ATTENUATION
    local responseExponent = LINEAR_RESPONSE_EXPONENT

    return attenuationFactor(cloudIntensity, maximumAttenuation, responseExponent)
end

local function fogMultiplier(climateManager)
    local fogIntensity = climateManager:getFogIntensity()
    local maximumAttenuation = MAX_FOG_ATTENUATION
    local responseExponent = EARLY_RESPONSE_EXPONENT

    return attenuationFactor(fogIntensity, maximumAttenuation, responseExponent)
end

local function precipitationMultiplier(climateManager)
    local precipitationIntensity = climateManager:getPrecipitationIntensity()
    local maximumAttenuation = MAX_PRECIPITATION_ATTENUATION
    local responseExponent = EARLY_RESPONSE_EXPONENT

    return attenuationFactor(precipitationIntensity, maximumAttenuation, responseExponent)
end

function WeatherPolicy.multiplier()
    local climateManager = getClimateManager()
    local cloudFactor = cloudMultiplier(climateManager)
    local fogFactor = fogMultiplier(climateManager)
    local precipitationFactor = precipitationMultiplier(climateManager)

    return cloudFactor * fogFactor * precipitationFactor
end

return WeatherPolicy
