local Constants = require("VargursVampires/Infrastructure/Constants")
local Config = require("VargursVampires/Infrastructure/Config")
local ClothingPolicy = require("VargursVampires/Mechanics/Sun/Protection/Clothing/ProtectionPolicy")
local SunEnvironment = require("VargursVampires/Mechanics/Sun/SunEnvironment")
local SunStress = require("VargursVampires/Mechanics/Sun/Stress/SunStress")
local State = require("VargursVampires/PlayerState/State")

---@class VargursSunExposurePolicy
---@field environmentalUV fun(environment: SunEnvironmentSnapshot, environmentalUVMultiplier: number): number
---@field calculate fun(environment: SunEnvironmentSnapshot, model: PlayerSunModel, environmentalUVMultiplier: number, stress?: number): PlayerSunModel
---@field sample fun(player: any, previousPain?: table, includeDebug?: boolean, capturedEnvironment?: SunEnvironmentSnapshot): PlayerSunModel
---@field totalWeightedUV fun(player: any): number
local SunExposure = {}

local function boundedUV(value)
    return math.max(0.0, math.min(Constants.MAX_SUN_EXPOSURE_MULTIPLIER, value))
end

function SunExposure.environmentalUV(environment, environmentalUVMultiplier)
    local environmentalUV = environment.daylightIntensity
        * environment.weatherMultiplier
        * environment.vehicleMultiplier
        * environment.positionMultiplier
        * environment.traitMultiplier
        * environmentalUVMultiplier
    return boundedUV(environmentalUV)
end

---@param environment SunEnvironmentSnapshot
---@param model PlayerSunModel
---@param environmentalUVMultiplier number
---@param stress? number
---@return PlayerSunModel
function SunExposure.calculate(environment, model, environmentalUVMultiplier, stress)
    local environmentalUV = SunExposure.environmentalUV(environment, environmentalUVMultiplier)
    local stressMultiplier = stress ~= nil and SunStress.multiplier(stress) or 1.0
    local amplifiedUV = boundedUV(environmentalUV * stressMultiplier)

    if model.debug then
        model.debug.environmentalUV = environmentalUV
        model.debug.sunStress = stress or 0.0
        model.debug.stressMultiplier = stressMultiplier
        model.debug.amplifiedUV = amplifiedUV
    end
    model.totalWeightedUV = 0.0
    for _, region in pairs(model.regions) do
        local rawUV = amplifiedUV * region.transmission
        local effectiveUV = rawUV
        if rawUV < Constants.MIN_EFFECTIVE_LOCAL_UV then
            effectiveUV = 0.0
        end
        if region.debug then
            region.debug.uvBeforeClothing = amplifiedUV
        end
        region.effectiveUV = effectiveUV
        region.weightedUV = effectiveUV * region.weight
        model.totalWeightedUV = model.totalWeightedUV + region.weightedUV
    end

    model.totalWeightedUV = boundedUV(model.totalWeightedUV)
    return model
end

---@return PlayerSunModel
function SunExposure.sample(player, previousPain, includeDebug, capturedEnvironment)
    local environment, environmentDebug
    if capturedEnvironment and not includeDebug then
        environment = capturedEnvironment
    else
        environment, environmentDebug = SunEnvironment.capture(player, includeDebug)
    end
    local model = ClothingPolicy.sample(player, previousPain, includeDebug)
    if model.debug then
        model.debug.environment = environmentDebug
    end
    local config = Config.get()
    local stress
    if player and config.enabled and config.sunDamageEnabled and config.sunDamagePerMinute > 0.0 and State.isVampire(player) then
        stress = State.getSunStress(player)
    end
    return SunExposure.calculate(environment, model, config.sunEnvironmentalUVMultiplier, stress)
end

function SunExposure.totalWeightedUV(player)
    return SunExposure.sample(player).totalWeightedUV
end

return SunExposure
