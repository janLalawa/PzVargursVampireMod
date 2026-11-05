local ConsumptionEffects = {}
local Health = require("VargursVampires/PlayerState/Health")
local IRON_GUT_TRAIT = CharacterTrait.IRON_GUT
local WEAK_STOMACH_TRAIT = CharacterTrait.WEAK_STOMACH
---@type table<IsoPlayer, table<string, boolean>|nil>
local pendingStatsByPlayer = setmetatable({}, { __mode = "k" })
---@type table<IsoPlayer, boolean|nil>
local pendingNutritionByPlayer = setmetatable({}, { __mode = "k" })

local statIds = {
    hungerChange = "HUNGER",
    thirstChange = "THIRST",
    enduranceChange = "ENDURANCE",
    foodSicknessChange = "FOOD_SICKNESS",
    poisonChange = "POISON",
    stressChange = "STRESS",
    intoxicationChange = "INTOXICATION",
    panicChange = "PANIC",
    boredomChange = "BOREDOM",
    unhappinessChange = "UNHAPPINESS",
}

local nutritionMethods = {
    calories = { "getCalories", "setCalories" },
    carbohydrates = { "getCarbohydrates", "setCarbohydrates" },
    proteins = { "getProteins", "setProteins" },
    lipids = { "getLipids", "setLipids" },
}

function ConsumptionEffects.setFoodTimer(player, value)
    local bodyDamage = player:getBodyDamage()
    if bodyDamage:getHealthFromFoodTimer() ~= value then
        bodyDamage:setHealthFromFoodTimer(value)
        Health.queueSync(player)
    end
end

---@param changes table<string, number>
---@param profile table
---@param amount number
function ConsumptionEffects.accumulate(changes, profile, amount)
    for field in pairs(statIds) do
        changes[field] = (changes[field] or 0.0) + (profile[field] or 0.0) * amount
    end
    for field in pairs(nutritionMethods) do
        changes[field] = (changes[field] or 0.0) + (profile[field] or 0.0) * amount
    end

    changes.generalHealthChange = (changes.generalHealthChange or 0.0) + (profile.generalHealthChange or 0.0) * amount
    changes.painReduction = (changes.painReduction or 0.0) + (profile.painReduction or 0.0) * amount
end

---@param player IsoPlayer
---@param changes table<string, number>
---@param amount number|nil
function ConsumptionEffects.apply(player, changes, amount)
    local stats = player:getStats()
    for field, statId in pairs(statIds) do
        local change = (changes[field] or 0.0) * (amount or 1.0)
        if field == "poisonChange" and change > 0.0 then
            if player:hasTrait(IRON_GUT_TRAIT) then
                change = change / 2.0
            end
            if player:hasTrait(WEAK_STOMACH_TRAIT) then
                change = change * 2.0
            end
        end

        if change ~= 0.0 then
            local stat = CharacterStat[statId] --[[@as CharacterStat]]
            local value = stats:get(stat) + change
            stats:set(stat, stat:clamp(value))
            if isServer() then
                local pendingStats = pendingStatsByPlayer[player]
                if not pendingStats then
                    pendingStats = {}
                    pendingStatsByPlayer[player] = pendingStats
                end
                pendingStats[statId] = true
            end
        end
    end

    local nutrition = player:getNutrition()
    for field, methods in pairs(nutritionMethods) do
        local change = (changes[field] or 0.0) * (amount or 1.0)
        if change ~= 0.0 then
            local value = nutrition[methods[1]](nutrition) + change
            nutrition[methods[2]](nutrition, value)
            if isServer() then
                pendingNutritionByPlayer[player] = true
            end
        end
    end

    local generalHealthChange = (changes.generalHealthChange or 0.0) * (amount or 1.0)
    if generalHealthChange > 0.0 then
        player:getBodyDamage():AddGeneralHealth(generalHealthChange)
        Health.queueSync(player)
    end

    local painReduction = (changes.painReduction or 0.0) * (amount or 1.0)
    if painReduction ~= 0.0 then
        local bodyDamage = player:getBodyDamage()
        bodyDamage:setPainReduction(bodyDamage:getPainReduction() + painReduction)
        Health.queueSync(player)
    end
end

function ConsumptionEffects.syncPlayer(player)
    if not isServer() or not player then
        return
    end

    local pendingStats = pendingStatsByPlayer[player]
    if pendingStats then
        ---@type integer
        local syncParams = 0
        for statId in pairs(pendingStats) do
            local stat = CharacterStat[statId] --[[@as CharacterStat]]
            local bitMask = SyncPlayerStatsPacket.getBitMaskForStat(stat) --[[@as integer]]
            syncParams = syncParams + bitMask
        end
        pendingStatsByPlayer[player] = nil
        if syncParams ~= 0 then
            syncPlayerStats(player, syncParams)
        end
    end

    if pendingNutritionByPlayer[player] then
        pendingNutritionByPlayer[player] = nil
        syncPlayerStats(player, -1)
    end
end

return ConsumptionEffects
