local BodyRegions = require("VargursVampires/PlayerState/BodyRegions")

local SunPainAdapter = {}
local CONTRIBUTIONS_KEY = "vargursVampiresSunPain"
SunPainAdapter.contributionsKey = CONTRIBUTIONS_KEY
local MAX_ADDITIONAL_PAIN = 100.0

function SunPainAdapter.toBodyParts(regions)
    return BodyRegions.maximumByPart(regions, "pain")
end

---@return boolean
function SunPainAdapter.apply(player, regions)
    if not player then
        return false
    end

    local requestedParts = SunPainAdapter.toBodyParts(regions)
    local modData = player:getModData()
    local previousContributions = modData[CONTRIBUTIONS_KEY] or {}
    local nextContributions, affectedParts = {}, {}
    for partIndex in pairs(previousContributions) do
        affectedParts[partIndex] = true
    end
    for partIndex in pairs(requestedParts) do
        affectedParts[partIndex] = true
    end

    modData[CONTRIBUTIONS_KEY] = nextContributions
    ---@type boolean
    local changed = false
    for partIndex in pairs(affectedParts) do
        local bodyPart = player:getBodyDamage():getBodyPart(BodyPartType.FromIndex(partIndex))
        local currentPain = bodyPart:getAdditionalPain()
        local previousContribution = previousContributions[partIndex] or 0.0
        local otherPain = math.max(0.0, currentPain - previousContribution)
        local targetPain = requestedParts[partIndex] or 0.0
        local nextPain = math.max(otherPain, math.min(MAX_ADDITIONAL_PAIN, otherPain + targetPain))
        local contribution = nextPain - otherPain
        if contribution > 0.0 then
            nextContributions[partIndex] = contribution
        end
        if nextPain ~= currentPain then
            bodyPart:setAdditionalPain(nextPain)
            changed = true
        end
    end
    return changed
end

return SunPainAdapter
