local FoodConsumptionSnapshot = {}
local ConsumptionEffects = require("VargursVampires/Mechanics/Consumption/Effects")
local Constants = require("VargursVampires/Infrastructure/Constants")

---@param player IsoPlayer
---@param item Food
---@return table
function FoodConsumptionSnapshot.capture(player, item)
    local nutrition = player:getNutrition()
    local stats = player:getStats()
    return {
        hunger = stats:get(CharacterStat.HUNGER),
        foodTimer = player:getBodyDamage():getHealthFromFoodTimer(),
        foodHunger = item:getHungerChange(),
        remainingHunger = item:getHungChange(),
        cooked = item:isCooked(),
        foodSickness = stats:get(CharacterStat.FOOD_SICKNESS),
        calories = nutrition:getCalories(),
        carbohydrates = nutrition:getCarbohydrates(),
        lipids = nutrition:getLipids(),
        proteins = nutrition:getProteins(),
    }
end

function FoodConsumptionSnapshot.adjustments(before, after, nutritionShare, consumedHunger)
    local rejectedShare = 1.0 - nutritionShare
    return {
        hungerChange = before.hunger - consumedHunger * nutritionShare - after.hunger,
        calories = (before.calories - after.calories) * rejectedShare,
        carbohydrates = (before.carbohydrates - after.carbohydrates) * rejectedShare,
        lipids = (before.lipids - after.lipids) * rejectedShare,
        proteins = (before.proteins - after.proteins) * rejectedShare,
        foodSicknessChange = math.max(0.0, before.foodSickness - after.foodSickness),
    }
end

function FoodConsumptionSnapshot.apply(player, before, after, nutritionShare, profile)
    local consumedFraction = 0.0
    if before.remainingHunger ~= 0.0 then
        consumedFraction = math.max(0.0, math.min(1.0, 1.0 - after.remainingHunger / before.remainingHunger))
    end

    local consumedHunger = math.max(0.0, -before.foodHunger) * consumedFraction
    local effects = FoodConsumptionSnapshot.adjustments(before, after, nutritionShare, consumedHunger)
    local amount = consumedHunger / Constants.HUNGER_REDUCTION_PER_FOOD_EFFECT_UNIT
    ConsumptionEffects.accumulate(effects, profile, amount)

    local nourishment = math.max(0.0, consumedHunger * nutritionShare - (profile.hungerChange or 0.0) * amount)
    ConsumptionEffects.apply(player, effects)

    local timer = before.foodTimer
    if nourishment > 0.0 and CharacterStat.HUNGER:isAtMinimum(player:getStats():get(CharacterStat.HUNGER)) then
        local multiplier = before.cooked and 2.0 or 1.0
        timer = math.min(Constants.MAX_FOOD_TIMER, math.floor(timer + nourishment * Constants.FOOD_TIMER_PER_HUNGER * multiplier))
    end
    ConsumptionEffects.setFoodTimer(player, timer)
end

return FoodConsumptionSnapshot
