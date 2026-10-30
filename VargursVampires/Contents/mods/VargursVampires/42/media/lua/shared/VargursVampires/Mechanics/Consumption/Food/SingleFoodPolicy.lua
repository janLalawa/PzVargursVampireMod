local SingleFoodPolicy = {}
local FoodTypes = require("VargursVampires/Mechanics/Consumption/Food/FoodTypes")
local FoodConsumptionSnapshot = require("VargursVampires/Mechanics/Consumption/Food/FoodConsumptionSnapshot")
local SustenanceValues = require("VargursVampires/Mechanics/Consumption/Food/SustenanceValues")

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
    local rawEligible = sustainingFood and item:isUncooked() and not item:isRotten()
    local profile = SustenanceValues.get(item:getFoodType(), item:getFullType(), rawEligible)
    local before = FoodConsumptionSnapshot.capture(player, item)

    local result
    if sustainingFood then
        result = eatWithRawMeatSafety(item, vanillaEat)
    else
        result = vanillaEat()
    end

    local after = FoodConsumptionSnapshot.capture(player, item)
    local nutritionShare = profile.retainVanillaNutrition and 1.0 or 0.0

    FoodConsumptionSnapshot.apply(player, before, after, nutritionShare, profile)

    return result
end

return SingleFoodPolicy
