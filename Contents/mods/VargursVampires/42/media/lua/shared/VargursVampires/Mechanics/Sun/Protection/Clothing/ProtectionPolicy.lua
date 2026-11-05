local ProtectionValues = require("VargursVampires/Mechanics/Sun/Protection/Clothing/ProtectionValues")
local ClothingSnapshot = require("VargursVampires/Mechanics/Sun/Protection/Clothing/ClothingSnapshot")
local SunModel = require("VargursVampires/Mechanics/Sun/SunModel")

local ProtectionPolicy = {}

local function transmissionForLayers(layerCount, profile)
    if layerCount >= 2 then
        local additionalLayers = layerCount - 2
        local additionalTransmission = profile.additionalLayerTransmissionMultiplier ^ additionalLayers
        return profile.twoLayerTransmission * additionalTransmission
    end
    if layerCount == 1 then
        return profile.oneLayerTransmission
    end
    return profile.uncoveredTransmission
end

---@param model PlayerSunModel
---@return PlayerSunModel
function ProtectionPolicy.calculate(model)
    model.clothingMultiplier = 0.0
    for regionName, region in pairs(model.regions) do
        local profile = ProtectionValues.get(regionName)
        local layerTransmission = transmissionForLayers(region.intactLayers, profile)
        local windProtectionBonus = region.windResistance * profile.maxWindTransmissionReduction
        local windTransmissionMultiplier = 1.0 - windProtectionBonus
        local nonLayerTransmissionMultiplier = windTransmissionMultiplier * region.itemTransmissionMultiplier
        region.transmission = layerTransmission * nonLayerTransmissionMultiplier
        model.clothingMultiplier = model.clothingMultiplier + region.transmission * region.weight

        if model.debug then
            region.debug = {
                layerTransmission = layerTransmission,
                windTransmissionMultiplier = windTransmissionMultiplier,
                itemTransmissionMultiplier = region.itemTransmissionMultiplier,
            }
        end
    end
    return model
end

---@return PlayerSunModel
function ProtectionPolicy.sample(player, previousPain, includeDebug)
    local model = SunModel.new(previousPain)
    if includeDebug then
        model.debug = {}
    end
    ClothingSnapshot.capture(player, model)
    return ProtectionPolicy.calculate(model)
end

function ProtectionPolicy.multiplier(player)
    return ProtectionPolicy.sample(player).clothingMultiplier
end

return ProtectionPolicy
