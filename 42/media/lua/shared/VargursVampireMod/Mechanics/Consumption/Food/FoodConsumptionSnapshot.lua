local FoodConsumptionSnapshot = {}

---@param player IsoPlayer
---@return table
function FoodConsumptionSnapshot.capture(player)
    local nutrition = player:getNutrition()
    local stats = player:getStats()
    return {
        hunger = stats:get(CharacterStat.HUNGER),
        foodSickness = stats:get(CharacterStat.FOOD_SICKNESS),
        calories = nutrition:getCalories(),
        carbohydrates = nutrition:getCarbohydrates(),
        lipids = nutrition:getLipids(),
        proteins = nutrition:getProteins(),
    }
end

function FoodConsumptionSnapshot.adjustments(before, after, nutritionShare)
    local rejectedShare = 1.0 - nutritionShare
    return {
        hungerChange = (before.hunger - after.hunger) * rejectedShare,
        calories = (before.calories - after.calories) * rejectedShare,
        carbohydrates = (before.carbohydrates - after.carbohydrates) * rejectedShare,
        lipids = (before.lipids - after.lipids) * rejectedShare,
        proteins = (before.proteins - after.proteins) * rejectedShare,
        foodSicknessChange = math.max(0.0, before.foodSickness - after.foodSickness),
    }
end

return FoodConsumptionSnapshot
