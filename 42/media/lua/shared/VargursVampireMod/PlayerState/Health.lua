local BodyRegions = require("VargursVampireMod/PlayerState/BodyRegions")

local Health = {}
local pendingDamageSync = setmetatable({}, { __mode = "k" })
local MIN_HEALTH = 0.0
local WAKE_HEALTH_THRESHOLD = 10.0

---@return integer[]
function Health.applyRegionalDamage(player, damageByRegion)
    if not player or player:isDead() then
        return {}
    end

    local bodyDamage = player:getBodyDamage()
    local damageByPart = BodyRegions.damageByPart(damageByRegion)

    local damaged = false
    local depletedParts = {}
    for partIndex, amount in pairs(damageByPart) do
        local partType = BodyPartType.FromIndex(partIndex)
        local bodyPart = bodyDamage:getBodyPart(partType)
        local modifier = BodyPartType.getDamageModifyer(partIndex)
        local partDamage = math.min(bodyPart:getHealth(), amount / modifier)
        if partDamage > MIN_HEALTH then
            bodyPart:ReduceHealth(partDamage)
            damaged = true
            if bodyPart:getHealth() <= MIN_HEALTH then
                depletedParts[#depletedParts + 1] = partIndex
            end
        end
    end

    if not damaged then
        return depletedParts
    end

    bodyDamage:calculateOverallHealth()
    if bodyDamage:getOverallBodyHealth() <= WAKE_HEALTH_THRESHOLD then
        player:forceAwake()
    end
    if isServer() then
        pendingDamageSync[player] = true
    end
    return depletedParts
end

function Health.syncDamage(player)
    if pendingDamageSync[player] then
        sendDamage(player)
        pendingDamageSync[player] = nil
    end
end

function Health.queueSync(player)
    if isServer() then
        pendingDamageSync[player] = true
    end
end

function Health.applyBurn(player, partIndex, burnTime)
    if not player or player:isDead() then
        return false
    end

    local bodyPart = player:getBodyDamage():getBodyPart(BodyPartType.FromIndex(partIndex))
    if bodyPart:getBurnTime() > 0.0 then
        return false
    end

    bodyPart:setBurnTime(burnTime)
    bodyPart:setNeedBurnWash(true)
    bodyPart:setLastTimeBurnWash(0.0)
    Health.queueSync(player)
    return true
end

return Health
