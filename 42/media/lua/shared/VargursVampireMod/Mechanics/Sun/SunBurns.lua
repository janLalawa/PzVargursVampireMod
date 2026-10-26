local BodyRegions = require("VargursVampireMod/PlayerState/BodyRegions")
local Health = require("VargursVampireMod/PlayerState/Health")

local MIN_LOCAL_UV = 0.6
local CHANCE_DENOMINATOR = 500
local MIN_BURN_TIME = 5
local MAX_BURN_TIME = 15
local CHECK_INTERVAL_MINUTES = 1.0
local minutesByPlayer = setmetatable({}, { __mode = "k" })

local SunBurns = {}

local function applyRandomBurn(player, partIndex)
    local part = player:getBodyDamage():getBodyPart(BodyPartType.FromIndex(partIndex))
    if part:getBurnTime() > 0.0 then
        return
    end

    local burnTime = MIN_BURN_TIME + ZombRand(MAX_BURN_TIME - MIN_BURN_TIME + 1)
    Health.applyBurn(player, partIndex, burnTime)
end

function SunBurns.applyDepleted(player, partIndices)
    if not player or player:isDead() then
        return
    end
    for _, partIndex in ipairs(partIndices) do
        applyRandomBurn(player, partIndex)
    end
end

local function eligibleParts(player, exposure)
    local eligibleRegions = {}
    for regionName, region in pairs(exposure.regions) do
        if region.intactLayers == 0 and region.effectiveUV >= MIN_LOCAL_UV then
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

function SunBurns.update(player, exposure, elapsedMinutes)
    if not player or player:isDead() then
        SunBurns.clear(player)
        return
    end
    if elapsedMinutes <= 0.0 then
        return
    end

    local candidates = eligibleParts(player, exposure)
    if #candidates == 0 then
        SunBurns.clear(player)
        return
    end

    local minutes = (minutesByPlayer[player] or 0.0) + elapsedMinutes
    while minutes >= CHECK_INTERVAL_MINUTES and #candidates > 0 do
        minutes = minutes - CHECK_INTERVAL_MINUTES
        if ZombRand(CHANCE_DENOMINATOR) == 0 then
            local choice = (ZombRand(#candidates) + 1) --[[@as integer]]
            applyRandomBurn(player, candidates[choice])
            table.remove(candidates, choice)
        end
    end
    minutesByPlayer[player] = #candidates > 0 and minutes or nil
end

return SunBurns
