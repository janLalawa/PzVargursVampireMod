---@type VargursClothingProtectionValues
local ProtectionValues = require("VargursVampires/Mechanics/Sun/Protection/Clothing/ProtectionValues")

local ClothingSnapshot = {}
local MIN_WIND_RESISTANCE = 0.0
local MAX_WIND_RESISTANCE = 1.0
local MIN_INSULATION = 0.0
local MAX_INSULATION = 1.0
local NO_HOLE = 0.0

local function garmentWindResistance(item)
    local windResistance = item:getWindresistance()
    return math.max(MIN_WIND_RESISTANCE, math.min(MAX_WIND_RESISTANCE, windResistance))
end

local function garmentInsulation(item)
    local insulation = item:getInsulation()
    return math.max(MIN_INSULATION, math.min(MAX_INSULATION, insulation))
end

local function addProtection(region, windResistance, insulation, transmissionMultiplier)
    region.intactLayers = region.intactLayers + 1
    region.materialLayers[#region.materialLayers + 1] = {
        windResistance = windResistance,
        insulation = insulation,
    }
    region.itemTransmissionMultiplier = region.itemTransmissionMultiplier * transmissionMultiplier
end

local function captureGarment(regionsByIndex, regionsByName, item)
    if not instanceof(item, "Clothing") then
        return
    end

    local coveredParts = item:getCoveredParts()
    local visual = item:getVisual()
    if not coveredParts or not visual then
        return
    end

    local override = ProtectionValues.getItemOverride(item:getFullType())
    local transmissionMultiplier = override.transmissionMultiplier or 1.0
    local windResistance = garmentWindResistance(item)
    local insulation = garmentInsulation(item)
    local coveredRegions = {}
    for partIndex = 0, coveredParts:size() - 1 do
        local bodyPart = coveredParts:get(partIndex)
        local region = regionsByIndex[bodyPart:index()]
        if region and not coveredRegions[region] then
            coveredRegions[region] = true
            if visual:getHole(bodyPart) == NO_HOLE then
                addProtection(region, windResistance, insulation, transmissionMultiplier)
            end
        end
    end

    for _, area in ipairs(override.ExtraProtectionAreas or {}) do
        local regionName = area
        local areaTransmissionMultiplier = transmissionMultiplier
        if type(area) == "table" then
            regionName = area.region
            areaTransmissionMultiplier = area.transmissionMultiplier or transmissionMultiplier
        end
        local region = regionsByName[regionName]
        if region and not coveredRegions[region] then
            coveredRegions[region] = true
            addProtection(region, windResistance, insulation, areaTransmissionMultiplier)
        end
    end
end

---@param model PlayerSunModel
---@return PlayerSunModel
function ClothingSnapshot.capture(player, model)
    local regionsByIndex = {}

    for regionName, region in pairs(model.regions) do
        region.intactLayers = 0
        region.materialLayers = {}
        region.itemTransmissionMultiplier = 1.0
        local bodyPartType = assert(BloodBodyPartType[regionName], "Unknown sun region body part: " .. regionName)
        local regionIndex = bodyPartType:index()
        regionsByIndex[regionIndex] = region
    end

    if not player then
        return model
    end

    local wornItems = player:getWornItems()
    for itemIndex = 0, wornItems:size() - 1 do
        captureGarment(regionsByIndex, model.regions, wornItems:getItemByIndex(itemIndex))
    end

    return model
end

return ClothingSnapshot
