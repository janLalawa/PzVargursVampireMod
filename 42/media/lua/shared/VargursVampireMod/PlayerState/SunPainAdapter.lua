local BodyRegions = require("VargursVampireMod/PlayerState/BodyRegions")

local SunPainAdapter = {}
local CONTRIBUTIONS_KEY = "vargursVampireModSunPain"
local PRESENTATION_KEY = "vargursVampireModSunPainPresentation"
local MAX_ADDITIONAL_PAIN = 100.0

function SunPainAdapter.toBodyParts(painByRegion)
    local targetsByRegion, severitiesByRegion = {}, {}
    for regionName, pain in pairs(painByRegion) do
        targetsByRegion[regionName] = pain.targetPain
        severitiesByRegion[regionName] = pain.severity
    end
    local targetsByPart = BodyRegions.maximumByPart(targetsByRegion)
    local severitiesByPart = BodyRegions.maximumByPart(severitiesByRegion)
    local totalWeight = BodyRegions.totalPainWeight()
    local parts = {}
    for partIndex, target in pairs(targetsByPart) do
        parts[partIndex] = {
            severity = severitiesByPart[partIndex],
            targetPain = target / totalWeight,
        }
    end
    return parts
end

---@return boolean
function SunPainAdapter.apply(player, painByRegion)
    if not player then
        return false
    end

    local requestedParts = SunPainAdapter.toBodyParts(painByRegion)
    local modData = player:getModData()
    local previousContributions = modData[CONTRIBUTIONS_KEY] or {}
    local nextContributions, presentation, affectedParts = {}, {}, {}
    for partIndex in pairs(previousContributions) do
        affectedParts[partIndex] = true
    end
    for partIndex in pairs(requestedParts) do
        affectedParts[partIndex] = true
    end

    modData[CONTRIBUTIONS_KEY] = nextContributions
    modData[PRESENTATION_KEY] = presentation
    ---@type boolean
    local changed = false
    for partIndex in pairs(affectedParts) do
        local bodyPart = player:getBodyDamage():getBodyPart(BodyPartType.FromIndex(partIndex))
        local currentPain = bodyPart:getAdditionalPain()
        local previousContribution = previousContributions[partIndex] or 0.0
        local otherPain = math.max(0.0, currentPain - previousContribution)
        local request = requestedParts[partIndex]
        local targetPain = request and request.targetPain or 0.0
        local nextPain = math.max(otherPain, math.min(MAX_ADDITIONAL_PAIN, otherPain + targetPain))
        local contribution = nextPain - otherPain
        if contribution > 0.0 then
            nextContributions[partIndex] = contribution
        end
        if request and request.severity > 0 then
            presentation[partIndex] = {
                severity = request.severity,
                sunPain = contribution,
                otherPain = otherPain,
            }
        end
        if nextPain ~= currentPain then
            bodyPart:setAdditionalPain(nextPain)
            changed = true
        end
    end
    return changed
end

local function copyPresentation(presentation)
    local result = {}
    for partIndex, part in pairs(presentation) do
        result[partIndex] = {
            severity = part.severity,
            sunPain = part.sunPain,
            otherPain = part.otherPain,
        }
    end
    return result
end

function SunPainAdapter.presentation(player)
    if not player then
        return {}
    end
    return copyPresentation(player:getModData()[PRESENTATION_KEY] or {})
end

function SunPainAdapter.receivePresentation(player, presentation)
    player:getModData()[PRESENTATION_KEY] = copyPresentation(presentation or {})
end

return SunPainAdapter
