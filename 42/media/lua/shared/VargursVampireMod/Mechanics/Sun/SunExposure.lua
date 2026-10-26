local Constants = require("VargursVampireMod/Infrastructure/Constants")
local Config = require("VargursVampireMod/Infrastructure/Config")
local ClothingPolicy = require("VargursVampireMod/Mechanics/Sun/Protection/Clothing/ProtectionPolicy")
local SunEnvironment = require("VargursVampireMod/Mechanics/Sun/SunEnvironment")

---@class SunRegionExposure
---@field intactLayers number
---@field weight number
---@field transmission number
---@field windResistance number
---@field windProtectionBonus number
---@field rawUV number
---@field effectiveUV number
---@field weightedUV number

---@class SunExposureResult
---@field environment SunEnvironmentSnapshot
---@field environmentalUV number
---@field minimumEffectiveUV number
---@field clothingMultiplier number
---@field directUV number
---@field regions table<string, SunRegionExposure>

---@class VargursSunExposurePolicy
---@field calculate fun(environment: SunEnvironmentSnapshot, clothing: table, environmentalUVMultiplier: number): SunExposureResult
---@field sample fun(player: any): SunExposureResult
---@field directUV fun(player: any): number
local SunExposure = {}
local MIN_EFFECTIVE_LOCAL_UV = 0.04

local function boundedUV(value)
    return math.max(0.0, math.min(Constants.MAX_SUN_EXPOSURE_MULTIPLIER, value))
end

---@param environment SunEnvironmentSnapshot
---@param environmentalUVMultiplier number
---@return SunExposureResult
function SunExposure.calculate(environment, clothing, environmentalUVMultiplier)
    local environmentalUV = environment.daylightIntensity
        * environment.weatherMultiplier
        * environment.vehicleMultiplier
        * environment.outdoorMultiplier
        * environmentalUVMultiplier
    environmentalUV = boundedUV(environmentalUV)

    local regions = {}
    local totalUV = 0.0
    for regionName, clothingRegion in pairs(clothing.regions) do
        local rawUV = environmentalUV * clothingRegion.transmission
        local effectiveUV = rawUV
        if rawUV < MIN_EFFECTIVE_LOCAL_UV then
            effectiveUV = 0.0
        end
        local weightedUV = effectiveUV * clothingRegion.weight
        totalUV = totalUV + weightedUV
        regions[regionName] = {
            intactLayers = clothingRegion.intactLayers,
            weight = clothingRegion.weight,
            transmission = clothingRegion.transmission,
            windResistance = clothingRegion.windResistance,
            windProtectionBonus = clothingRegion.windProtectionBonus,
            rawUV = rawUV,
            effectiveUV = effectiveUV,
            weightedUV = weightedUV,
        }
    end

    return {
        environment = {
            daylightIntensity = environment.daylightIntensity,
            weatherMultiplier = environment.weatherMultiplier,
            vehicleMultiplier = environment.vehicleMultiplier,
            outdoorMultiplier = environment.outdoorMultiplier,
        },
        environmentalUV = environmentalUV,
        minimumEffectiveUV = MIN_EFFECTIVE_LOCAL_UV,
        clothingMultiplier = clothing.multiplier,
        directUV = boundedUV(totalUV),
        regions = regions,
    }
end

---@return SunExposureResult
function SunExposure.sample(player)
    local environment = SunEnvironment.capture(player)
    local _, _, clothing = ClothingPolicy.exposureShares(player)
    return SunExposure.calculate(environment, clothing, Config.get().sunEnvironmentalUVMultiplier)
end

function SunExposure.directUV(player)
    return SunExposure.sample(player).directUV
end

return SunExposure
