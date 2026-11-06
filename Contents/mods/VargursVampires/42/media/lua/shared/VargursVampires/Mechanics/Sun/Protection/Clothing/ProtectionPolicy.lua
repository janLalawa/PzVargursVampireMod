local ProtectionValues = require("VargursVampires/Mechanics/Sun/Protection/Clothing/ProtectionValues")
local ClothingSnapshot = require("VargursVampires/Mechanics/Sun/Protection/Clothing/ClothingSnapshot")
local SunModel = require("VargursVampires/Mechanics/Sun/SunModel")

local ProtectionPolicy = {}

local function materialTransmission(material, profile)
    local wind = 1.0 - material.windResistance * (1.0 - profile.windTransmissionMultiplierAtMax)
    local insulation = 1.0 - material.insulation * (1.0 - profile.insulationTransmissionMultiplierAtMax)
    return wind, insulation
end

local function transmissionForMaterials(materialLayers, profile)
    local function providesMoreMaterialProtection(garment, otherGarment)
        local wind, insulation = materialTransmission(garment, profile)
        local otherWind, otherInsulation = materialTransmission(otherGarment, profile)
        local transmission = wind * insulation
        local otherTransmission = otherWind * otherInsulation
        if transmission == otherTransmission then
            return wind < otherWind
        end
        return transmission < otherTransmission
    end

    table.sort(materialLayers, providesMoreMaterialProtection)

    local windMultiplier = 1.0
    local insulationMultiplier = 1.0
    for rank, garment in ipairs(materialLayers) do
        local stackingStrength = profile.materialStackingStrengths[rank] or profile.additionalMaterialStackingStrength
        local wind, insulation = materialTransmission(garment, profile)
        windMultiplier = windMultiplier * (1.0 - stackingStrength * (1.0 - wind))
        insulationMultiplier = insulationMultiplier * (1.0 - stackingStrength * (1.0 - insulation))
    end
    return windMultiplier, insulationMultiplier
end

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
        local windTransmissionMultiplier, insulationTransmissionMultiplier = transmissionForMaterials(region.materialLayers, profile)
        local nonLayerTransmissionMultiplier = windTransmissionMultiplier
            * insulationTransmissionMultiplier
            * region.itemTransmissionMultiplier
        region.transmission = layerTransmission * nonLayerTransmissionMultiplier
        model.clothingMultiplier = model.clothingMultiplier + region.transmission * region.weight

        if model.debug then
            region.debug = {
                layerTransmission = layerTransmission,
                windTransmissionMultiplier = windTransmissionMultiplier,
                insulationTransmissionMultiplier = insulationTransmissionMultiplier,
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
