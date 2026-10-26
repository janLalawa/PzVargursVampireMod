local MixedFoodPolicy = {}
local FoodConsumptionSnapshot = require("VargursVampireMod/Mechanics/Consumption/Food/FoodConsumptionSnapshot")
local ConsumptionEffects = require("VargursVampireMod/Mechanics/Consumption/Effects")
local Constants = require("VargursVampireMod/Infrastructure/Constants")
local SustenanceValues = require("VargursVampireMod/Mechanics/Consumption/Food/SustenanceValues")

local function foodComposition(item)
    local components = item:getExtraItems()
    local sustainingHunger = 0.0
    local totalHunger = 0.0
    local weightedEffects = {}

    local function addComponent(fullType)
        local scriptItem = getScriptManager():FindItem(fullType)
        local hunger = math.abs(scriptItem:getHungerChange())

        totalHunger = totalHunger + hunger

        local foodType = getItemFoodType(fullType)
        local profile = SustenanceValues.get(foodType, fullType)
        if profile.retainVanillaNutrition then
            sustainingHunger = sustainingHunger + hunger
        end

        ConsumptionEffects.accumulate(weightedEffects, profile, hunger)
    end

    if components then
        for index = 0, components:size() - 1 do
            addComponent(components:get(index))
        end
    end

    local spices = item:getSpices()
    if spices then
        for index = 0, spices:size() - 1 do
            local fullType = spices:get(index)
            if SustenanceValues.items[fullType] then
                addComponent(fullType)
            end
        end
    end

    if totalHunger <= 0.0 then
        return 0.0, SustenanceValues.incompatible
    end
    local effects = {}
    ConsumptionEffects.accumulate(effects, weightedEffects, 1.0 / totalHunger)
    return math.max(0.0, math.min(1.0, sustainingHunger / totalHunger)), effects
end

local function eatWithoutVanillaSickness(item, vanillaEat)
    local dangerousUncooked = item:isbDangerousUncooked()
    local foodSicknessChange = item:getFoodSicknessChange()

    if not item:isRotten() then
        item:setbDangerousUncooked(false)
        item:setFoodSicknessChange(0)
    end

    local result = vanillaEat()
    item:setbDangerousUncooked(dangerousUncooked)
    item:setFoodSicknessChange(foodSicknessChange)
    return result
end

function MixedFoodPolicy.consume(player, item, portion, vanillaEat)
    local nutritionShare, profile = foodComposition(item)
    local consumedFraction = math.max(0.0, math.min(1.0, portion))
    local consumedHunger = math.max(0.0, -item:getHungerChange()) * consumedFraction
    local before = FoodConsumptionSnapshot.capture(player)
    local result = eatWithoutVanillaSickness(item, vanillaEat)
    local after = FoodConsumptionSnapshot.capture(player)

    local effects = FoodConsumptionSnapshot.adjustments(before, after, nutritionShare)
    ConsumptionEffects.accumulate(effects, profile, consumedHunger / Constants.HUNGER_REDUCTION_PER_FOOD_EFFECT_UNIT)
    ConsumptionEffects.apply(player, effects)

    return result
end

return MixedFoodPolicy
