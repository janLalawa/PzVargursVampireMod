local SunPainPolicy = require("VargursVampires/Mechanics/Sun/Pain/SunPainPolicy")
local BodyRegions = require("VargursVampires/PlayerState/BodyRegions")

---@class VargursSunPainLogic
---@field update fun(model: PlayerSunModel, elapsedMinutes: number, remainingHealth: number): PlayerSunModel
local SunPain = {}

local function painForSurvivalTime(survivalMinutes)
    local curve = SunPainPolicy.painCurve
    local first = curve[1]
    if survivalMinutes >= first.survivalMinutes then
        return first.pain * first.survivalMinutes / survivalMinutes
    end
    for index = 2, #curve do
        local lower = curve[index - 1]
        local upper = curve[index]
        if survivalMinutes >= upper.survivalMinutes then
            local fraction = (lower.survivalMinutes - survivalMinutes) / (lower.survivalMinutes - upper.survivalMinutes)
            return lower.pain + (upper.pain - lower.pain) * fraction
        end
    end
    return curve[#curve].pain
end

---@param model PlayerSunModel
---@return PlayerSunModel
function SunPain.update(model, elapsedMinutes, remainingHealth)
    local totalDamagePerMinute = 0.0
    local painWeights = {}
    for regionName, region in pairs(model.regions) do
        local damagePerMinute = math.max(0.0, region.damagePerMinute)
        painWeights[regionName] = damagePerMinute
        totalDamagePerMinute = totalDamagePerMinute + damagePerMinute
    end

    local totalTargetPain = 0.0
    local weightedParts = 0.0
    if totalDamagePerMinute > 0.0 and remainingHealth > 0.0 then
        totalTargetPain = painForSurvivalTime(remainingHealth / totalDamagePerMinute)
        for partIndex, weight in pairs(BodyRegions.maximumByPart(painWeights)) do
            weightedParts = weightedParts + weight * BodyPartType.getPainModifyer(partIndex)
        end
    end

    local recovery = SunPainPolicy.recoveryPerMinute * math.max(0.0, elapsedMinutes)
    for regionName, region in pairs(model.regions) do
        local targetPain = weightedParts > 0.0 and totalTargetPain * painWeights[regionName] / weightedParts or 0.0
        targetPain = math.min(100.0, targetPain)
        region.pain = math.max(targetPain, region.pain - recovery)
    end

    return model
end

return SunPain
