local SingleFoodPolicy = {}
local FoodTypes = require("VargursVampireMod/Mechanics/Consumption/Food/FoodTypes")
local FoodConsumptionSnapshot = require("VargursVampireMod/Mechanics/Consumption/Food/FoodConsumptionSnapshot")
local ConsumptionEffects = require("VargursVampireMod/Mechanics/Consumption/Effects")
local Constants = require("VargursVampireMod/Infrastructure/Constants")
local SustenanceValues = require("VargursVampireMod/Mechanics/Consumption/Food/SustenanceValues")

local function isSustainingFood(food)
    return FoodTypes.isSustaining(food:getFoodType())
end

local function eatWithRawMeatSafety(item, vanillaEat)
    if not item:isUncooked() or item:isRotten() then
        return vanillaEat()
    end

    local dangerousUncooked = item:isbDangerousUncooked()
    local foodSicknessChange = item:getFoodSicknessChange()
    item:setbDangerousUncooked(false)
    item:setFoodSicknessChange(0)

    local result = vanillaEat()
    item:setbDangerousUncooked(dangerousUncooked)
    item:setFoodSicknessChange(foodSicknessChange)
    return result
end

function SingleFoodPolicy.consume(player, item, portion, vanillaEat)
    local sustainingFood = isSustainingFood(item)
    local profile = SustenanceValues.get(item:getFoodType(), item:getFullType())
    local before = FoodConsumptionSnapshot.capture(player)
    local consumedFraction = math.max(0.0, math.min(1.0, portion))
    local consumedHunger = math.max(0.0, -item:getHungerChange()) * consumedFraction

    local result
    if sustainingFood then
        result = eatWithRawMeatSafety(item, vanillaEat)
    else
        result = vanillaEat()
    end

    local after = FoodConsumptionSnapshot.capture(player)
    local nutritionShare = profile.retainVanillaNutrition and 1.0 or 0.0

    local effects = FoodConsumptionSnapshot.adjustments(before, after, nutritionShare)
    ConsumptionEffects.accumulate(effects, profile, consumedHunger / Constants.HUNGER_REDUCTION_PER_FOOD_EFFECT_UNIT)
    ConsumptionEffects.apply(player, effects)

    return result
end

return SingleFoodPolicy
