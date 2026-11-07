local ProtectionValues = require("VargursVampires/Mechanics/Sun/Protection/Clothing/ProtectionValues")

---@class SunRegion
---@field debug SunRegionDebug|nil
---@field intactLayers number Populated by the clothing snapshot.
---@field materialLayers SunMaterialLayer[] Populated by the clothing snapshot.
---@field itemTransmissionMultiplier number Populated by the clothing snapshot.
---@field weight number
---@field transmission number Calculated by the clothing policy.
---@field effectiveUV number Calculated by the exposure policy.
---@field weightedUV number Calculated by the exposure policy.
---@field pain number Restored from prior state and updated by the effects calculation.
---@field damage number Calculated by the effects calculation.
---@field damagePerMinute number Calculated by the effects calculation.

---@class SunMaterialLayer
---@field windResistance number
---@field insulation number

---@class SunRegionDebug
---@field uvBeforeClothing number
---@field layerTransmission number
---@field windTransmissionMultiplier number
---@field insulationTransmissionMultiplier number
---@field itemTransmissionMultiplier number

---@class SunExposureDebug
---@field environment SunEnvironmentDebugSnapshot
---@field environmentalUV number
---@field sunStress number
---@field stressMultiplier number
---@field amplifiedUV number
---@field totalDamagePerGameMinute number

---@class PlayerSunModel
---@field regions table<string, SunRegion>
---@field totalWeightedUV number Calculated by the exposure policy.
---@field debug SunExposureDebug|nil
---@field clothingMultiplier number Calculated by the clothing policy.

local SunModel = {}

---@param previousPain? table
---@return PlayerSunModel
function SunModel.new(previousPain)
    local model = {
        regions = {},
        totalWeightedUV = 0.0,
        clothingMultiplier = 0.0,
    }
    local totalWeight = 0.0
    for regionName in pairs(ProtectionValues.regions) do
        totalWeight = totalWeight + ProtectionValues.get(regionName).weight
    end

    for regionName in pairs(ProtectionValues.regions) do
        local previous = previousPain and previousPain[regionName] or {}
        model.regions[regionName] = {
            intactLayers = 0,
            materialLayers = {},
            itemTransmissionMultiplier = 1.0,
            weight = ProtectionValues.get(regionName).weight / totalWeight,
            transmission = 1.0,
            effectiveUV = 0.0,
            weightedUV = 0.0,
            pain = previous.pain or previous.targetPain or 0.0,
            damage = 0.0,
            damagePerMinute = 0.0,
        }
    end

    return model
end

return SunModel
