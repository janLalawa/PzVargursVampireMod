local BodyRegions = {}
local REGION_PART_SHARES = {
    Back = { Torso_Upper = 0.6, Torso_Lower = 0.4 },
}

local function visitParts(regionName, callback)
    local shares = REGION_PART_SHARES[regionName]
    if not shares then
        callback(BodyPartType.ToIndex(BodyPartType[regionName]), 1.0)
        return
    end
    for partName, share in pairs(shares) do
        callback(BodyPartType.ToIndex(BodyPartType[partName]), share)
    end
end

function BodyRegions.damageByPart(damageByRegion)
    local damageByPart = {}
    for regionName, amount in pairs(damageByRegion) do
        if amount > 0.0 then
            visitParts(regionName, function(partIndex, share)
                damageByPart[partIndex] = (damageByPart[partIndex] or 0.0) + amount * share
            end)
        end
    end
    return damageByPart
end

function BodyRegions.maximumByPart(valuesByRegion)
    local valuesByPart = {}
    for regionName, value in pairs(valuesByRegion) do
        visitParts(regionName, function(partIndex)
            valuesByPart[partIndex] = math.max(valuesByPart[partIndex] or 0.0, value)
        end)
    end
    return valuesByPart
end

function BodyRegions.totalPainWeight()
    local totalWeight = 0.0
    local partCount = BodyPartType.ToIndex(BodyPartType.MAX)
    for partIndex = 0, partCount - 1 do
        totalWeight = totalWeight + BodyPartType.getPainModifyer(partIndex)
    end
    return totalWeight
end

return BodyRegions
