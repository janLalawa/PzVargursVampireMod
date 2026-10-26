local ConsumptionEffects = {}

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
end

---@param player IsoPlayer
---@param changes table<string, number>
---@param amount number|nil
function ConsumptionEffects.apply(player, changes, amount)
    local stats = player:getStats()
    for field, statId in pairs(statIds) do
        local change = (changes[field] or 0.0) * (amount or 1.0)
        if change ~= 0.0 then
            local stat = CharacterStat[statId]
            local value = stats:get(stat) + change
            stats:set(stat, stat:clamp(value))
        end
    end

    local nutrition = player:getNutrition()
    for field, methods in pairs(nutritionMethods) do
        local change = (changes[field] or 0.0) * (amount or 1.0)
        if change ~= 0.0 then
            local value = nutrition[methods[1]](nutrition) + change
            nutrition[methods[2]](nutrition, value)
        end
    end

    local generalHealthChange = (changes.generalHealthChange or 0.0) * (amount or 1.0)
    if generalHealthChange > 0.0 then
        player:getBodyDamage():AddGeneralHealth(generalHealthChange)
    end
end

return ConsumptionEffects
