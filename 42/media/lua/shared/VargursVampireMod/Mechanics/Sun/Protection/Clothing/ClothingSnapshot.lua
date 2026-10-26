local ProtectionValues = require("VargursVampireMod/Mechanics/Sun/Protection/Clothing/ProtectionValues")

local ClothingSnapshot = {}
local MIN_WIND_RESISTANCE = 0.0
local MAX_WIND_RESISTANCE = 1.0
local NO_HOLE = 0.0

local function garmentWindResistance(item)
    local windResistance = item:getWindresistance()
    return math.max(MIN_WIND_RESISTANCE, math.min(MAX_WIND_RESISTANCE, windResistance))
end

local function captureGarment(regionsByIndex, item)
    if not instanceof(item, "Clothing") then
        return
    end

    local coveredParts = item:getCoveredParts()
    local visual = item:getVisual()
    if not coveredParts or not visual then
        return
    end

    local windResistance = garmentWindResistance(item)
    for partIndex = 0, coveredParts:size() - 1 do
        local bodyPart = coveredParts:get(partIndex)
        local region = regionsByIndex[bodyPart:index()]
        if region and visual:getHole(bodyPart) == NO_HOLE then
            region.intactLayers = region.intactLayers + 1
            region.windResistance = math.max(region.windResistance, windResistance)
        end
    end
end

function ClothingSnapshot.capture(player)
    local regions = {}
    local regionsByIndex = {}

    for regionName in pairs(ProtectionValues.regions) do
        local region = { intactLayers = 0, windResistance = MIN_WIND_RESISTANCE }
        regions[regionName] = region

        local regionIndex = BloodBodyPartType[regionName]:index()
        regionsByIndex[regionIndex] = region
    end

    if not player then
        return regions
    end

    local wornItems = player:getWornItems()
    for itemIndex = 0, wornItems:size() - 1 do
        captureGarment(regionsByIndex, wornItems:getItemByIndex(itemIndex))
    end

    return regions
end

return ClothingSnapshot
