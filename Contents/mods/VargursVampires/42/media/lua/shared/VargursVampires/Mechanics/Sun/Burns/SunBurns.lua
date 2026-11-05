local Config = require("VargursVampires/Infrastructure/Config")
local BodyRegions = require("VargursVampires/PlayerState/BodyRegions")
local Health = require("VargursVampires/PlayerState/Health")
local SunBurnsPolicy = require("VargursVampires/Mechanics/Sun/Burns/SunBurnsPolicy")

local minutesByPlayer = setmetatable({}, { __mode = "k" })

local SunBurns = {}

local function applyRandomBurn(player, partIndex)
    local part = player:getBodyDamage():getBodyPart(BodyPartType.FromIndex(partIndex))
    if part:getBurnTime() > 0.0 then
        return
    end

    local burnTime = SunBurnsPolicy.minimumBurnTime + ZombRand(SunBurnsPolicy.maximumBurnTime - SunBurnsPolicy.minimumBurnTime + 1)
    Health.applyBurn(player, partIndex, burnTime)
end

local function eligibleParts(player, model)
    local eligibleRegions = {}
    for regionName, region in pairs(model.regions) do
        if region.intactLayers == 0 and region.effectiveUV >= SunBurnsPolicy.minimumLocalUV then
            eligibleRegions[regionName] = region.effectiveUV
        end
    end

    local eligibleByPart = BodyRegions.maximumByPart(eligibleRegions)
    local bodyDamage = player:getBodyDamage()
    local candidates = {}
    for partIndex = 0, BodyPartType.ToIndex(BodyPartType.MAX) - 1 do
        if eligibleByPart[partIndex] then
            local part = bodyDamage:getBodyPart(BodyPartType.FromIndex(partIndex))
            if part:getBurnTime() <= 0.0 then
                candidates[#candidates + 1] = partIndex
            end
        end
    end
    return candidates
end

function SunBurns.clear(player)
    if player then
        minutesByPlayer[player] = nil
    end
end

---@param model PlayerSunModel
function SunBurns.updateExposureBurns(player, model, elapsedMinutes)
    if not player or player:isDead() then
        SunBurns.clear(player)
        return
    end
    if elapsedMinutes <= 0.0 then
        return
    end

    local chance = Config.get().sunBurnRandomChance
    if chance <= 0.0 then
        SunBurns.clear(player)
        return
    end

    local candidates = eligibleParts(player, model)
    if #candidates == 0 then
        SunBurns.clear(player)
        return
    end

    local minutes = (minutesByPlayer[player] or 0.0) + elapsedMinutes
    while minutes >= SunBurnsPolicy.checkIntervalMinutes and #candidates > 0 do
        minutes = minutes - SunBurnsPolicy.checkIntervalMinutes
        for candidateIndex = #candidates, 1, -1 do
            if chance >= 1.0 or ZombRandFloat(0.0, 1.0) < chance then
                applyRandomBurn(player, candidates[candidateIndex])
                table.remove(candidates, candidateIndex)
            end
        end
    end
    minutesByPlayer[player] = #candidates > 0 and minutes or nil
end

return SunBurns
