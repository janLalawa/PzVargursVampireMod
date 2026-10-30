local FoodTypes = require("VargursVampires/Mechanics/Consumption/Food/FoodTypes")

-- Extra amounts for vampires per 10 hunger points consumed (0.10 native hunger reduction).
local SustenanceValues = {
    sustaining = {
        retainVanillaNutrition = true,
        calories = 30.0,
        carbohydrates = 0.0,
        proteins = 5.0,
        lipids = 5.0,
        hungerChange = -0.02,
        thirstChange = -0.02,
        foodSicknessChange = 0.0,
        poisonChange = 0.0,
        stressChange = 0.0,
        intoxicationChange = 0.0,
        panicChange = 0.0,
        boredomChange = -1,
        unhappinessChange = 0.0,
    },
    sustainingRaw = {
        calories = 60.0,
        proteins = 10.0,
        lipids = 10.0,
        carbohydrates = 10.0,
        hungerChange = -0.08,
        thirstChange = -0.04,
        foodSicknessChange = 0.0,
        poisonChange = -1.0,
        stressChange = 0.0,
        intoxicationChange = 0.0,
        panicChange = 0.0,
        boredomChange = 0,
        unhappinessChange = -10,
        generalHealthChange = 2.5,
    },
    incompatible = {
        retainVanillaNutrition = false,
        calories = 0.0,
        carbohydrates = 0.0,
        proteins = 0.0,
        lipids = 0.0,
        hungerChange = 0.0,
        thirstChange = 0.0,
        foodSicknessChange = 0.0,
        poisonChange = 8.0,
        stressChange = 0.1,
        intoxicationChange = 0.0,
        panicChange = 0.0,
        boredomChange = 0.0,
        unhappinessChange = 0.5,
    },
    foodTypes = {},
    items = {
        ["Base.VargursBloodSpice"] = {
            retainVanillaNutrition = true,
            enduranceChange = 0.1,
            generalHealthChange = 2.5,
            poisonChange = -10.0,
            foodSicknessChange = -5.0,
            stressChange = -0.1,
            unhappinessChange = -0.1,
        },
        ["Base.Garlic"] = {
            poisonChange = 40.0,
            stressChange = 0.7,
            unhappinessChange = 5.0,
        },
        ["Base.PowderedGarlic"] = {
            poisonChange = 40.0,
            stressChange = 0.7,
            unhappinessChange = 5.0,
        },
        ["Base.WildGarlic2"] = {
            poisonChange = 40.0,
            stressChange = 0.7,
            unhappinessChange = 5.0,
        },
        ["Base.WildGarlicDried"] = {
            poisonChange = 40.0,
            stressChange = 0.7,
            unhappinessChange = 5.0,
        },
    },
}

function SustenanceValues.get(foodType, fullType, rawEligible)
    local sustaining = FoodTypes.isSustaining(foodType)
    local defaults = sustaining and SustenanceValues.sustaining or SustenanceValues.incompatible
    local rawOverride = sustaining and rawEligible and SustenanceValues.sustainingRaw or nil
    local typeOverride = SustenanceValues.foodTypes[foodType]
    local itemOverride = SustenanceValues.items[fullType]
    if not rawOverride and not typeOverride and not itemOverride then
        return defaults
    end

    local profile = {}

    for field, value in pairs(defaults) do
        profile[field] = value
    end

    for field, value in pairs(rawOverride or {}) do
        profile[field] = value
    end

    for field, value in pairs(typeOverride or {}) do
        profile[field] = value
    end

    for field, value in pairs(itemOverride or {}) do
        profile[field] = value
    end

    return profile
end

return SustenanceValues
