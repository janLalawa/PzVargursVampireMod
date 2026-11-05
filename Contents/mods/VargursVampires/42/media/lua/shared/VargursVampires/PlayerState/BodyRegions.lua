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

---@param regions table<string, SunRegion>
function BodyRegions.damageByPart(regions)
    local damageByPart = {}
    for regionName, region in pairs(regions) do
        local amount = region.damage
        if amount > 0.0 then
            visitParts(regionName, function(partIndex, share)
                damageByPart[partIndex] = (damageByPart[partIndex] or 0.0) + amount * share
            end)
        end
    end
    return damageByPart
end

function BodyRegions.maximumByPart(valuesByRegion, field)
    local valuesByPart = {}
    for regionName, value in pairs(valuesByRegion) do
        if field then
            value = value[field]
        end
        visitParts(regionName, function(partIndex)
            valuesByPart[partIndex] = math.max(valuesByPart[partIndex] or 0.0, value)
        end)
    end
    return valuesByPart
end

return BodyRegions
