local Constants = require("VargursVampires/Infrastructure/Constants")
local Config = require("VargursVampires/Infrastructure/Config")
local ClothingPolicy = require("VargursVampires/Mechanics/Sun/Protection/Clothing/ProtectionPolicy")
local SunEnvironment = require("VargursVampires/Mechanics/Sun/SunEnvironment")

---@class VargursSunExposurePolicy
---@field calculate fun(environment: SunEnvironmentSnapshot, model: PlayerSunModel, environmentalUVMultiplier: number): PlayerSunModel
---@field sample fun(player: any, previousPain?: table, includeDebug?: boolean): PlayerSunModel
---@field totalWeightedUV fun(player: any): number
local SunExposure = {}

local function boundedUV(value)
    return math.max(0.0, math.min(Constants.MAX_SUN_EXPOSURE_MULTIPLIER, value))
end

---@param environment SunEnvironmentSnapshot
---@param model PlayerSunModel
---@param environmentalUVMultiplier number
---@return PlayerSunModel
function SunExposure.calculate(environment, model, environmentalUVMultiplier)
    local environmentalUV = environment.daylightIntensity
        * environment.weatherMultiplier
        * environment.vehicleMultiplier
        * environment.positionMultiplier
        * environment.traitMultiplier
        * environmentalUVMultiplier
    environmentalUV = boundedUV(environmentalUV)

    if model.debug then
        model.debug.environmentalUV = environmentalUV
    end
    model.totalWeightedUV = 0.0
    for _, region in pairs(model.regions) do
        local rawUV = environmentalUV * region.transmission
        local effectiveUV = rawUV
        if rawUV < Constants.MIN_EFFECTIVE_LOCAL_UV then
            effectiveUV = 0.0
        end
        if region.debug then
            region.debug.uvBeforeClothing = environmentalUV
        end
        region.effectiveUV = effectiveUV
        region.weightedUV = effectiveUV * region.weight
        model.totalWeightedUV = model.totalWeightedUV + region.weightedUV
    end

    model.totalWeightedUV = boundedUV(model.totalWeightedUV)
    return model
end

---@return PlayerSunModel
function SunExposure.sample(player, previousPain, includeDebug)
    local environment, environmentDebug = SunEnvironment.capture(player, includeDebug)
    local model = ClothingPolicy.sample(player, previousPain, includeDebug)
    if model.debug then
        model.debug.environment = environmentDebug
    end
    return SunExposure.calculate(environment, model, Config.get().sunEnvironmentalUVMultiplier)
end

function SunExposure.totalWeightedUV(player)
    return SunExposure.sample(player).totalWeightedUV
end

return SunExposure
