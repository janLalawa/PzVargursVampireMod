local Constants = require("VargursVampires/Infrastructure/Constants")
local Config = require("VargursVampires/Infrastructure/Config")
local ClothingPolicy = require("VargursVampires/Mechanics/Sun/Protection/Clothing/ProtectionPolicy")
local SunEnvironment = require("VargursVampires/Mechanics/Sun/SunEnvironment")
local SunStress = require("VargursVampires/Mechanics/Sun/Stress/SunStress")
local State = require("VargursVampires/PlayerState/State")

---@class VargursSunExposurePolicy
---@field environmentalUV fun(environment: SunEnvironmentSnapshot, environmentalUVMultiplier: number): number
---@field calculate fun(environment: SunEnvironmentSnapshot, model: PlayerSunModel, environmentalUVMultiplier: number, stress?: number): PlayerSunModel
---@field captureInputs fun(player: any, previousPain?: table, includeDebug?: boolean): SunExposureInputs
---@field sampleWithInputs fun(player: any, inputs: SunExposureInputs): PlayerSunModel
---@field sample fun(player: any, previousPain?: table, includeDebug?: boolean, capturedEnvironment?: SunEnvironmentSnapshot): PlayerSunModel
---@field totalWeightedUV fun(player: any): number
---@class SunExposureInputs
---@field environment SunEnvironmentSnapshot
---@field environmentDebug? SunEnvironmentDebugSnapshot
---@field config {sunEnvironmentalUVMultiplier: number}
---@field stress? number
---@field previousPain? table
---@field includeDebug? boolean
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

    model.traitDamageMultiplier = environment.traitMultiplier
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

local function captureInputs(player, previousPain, includeDebug, capturedEnvironment)
    local environment, environmentDebug
    if capturedEnvironment and not includeDebug then
        environment = capturedEnvironment
    else
        environment, environmentDebug = SunEnvironment.capture(player, includeDebug)
    end
    local config = Config.get()
    local stress
    if player and config.enabled and config.sunDamageEnabled and config.sunDamagePerMinute > 0.0 and State.isVampire(player) then
        stress = State.getSunStress(player)
    end
    return {
        environment = environment,
        environmentDebug = environmentDebug,
        config = config,
        stress = stress,
        previousPain = previousPain,
        includeDebug = includeDebug,
    }
end

function SunExposure.captureInputs(player, previousPain, includeDebug)
    return captureInputs(player, previousPain, includeDebug)
end

---@param inputs SunExposureInputs
---@return PlayerSunModel
function SunExposure.sampleWithInputs(player, inputs)
    if inputs.includeDebug then
        assert(inputs.environmentDebug, "Sun environment debug snapshot expected")
    end
    local model = ClothingPolicy.sample(player, inputs.previousPain, inputs.includeDebug)
    if model.debug then
        model.debug.environment = inputs.environmentDebug
    end
    return SunExposure.calculate(inputs.environment, model, inputs.config.sunEnvironmentalUVMultiplier, inputs.stress)
end

---@return PlayerSunModel
function SunExposure.sample(player, previousPain, includeDebug, capturedEnvironment)
    local inputs = captureInputs(player, previousPain, includeDebug, capturedEnvironment)
    return SunExposure.sampleWithInputs(player, inputs)
end

function SunExposure.totalWeightedUV(player)
    return SunExposure.sampleWithInputs(player, SunExposure.captureInputs(player)).totalWeightedUV
end

return SunExposure
