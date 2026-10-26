local LiquidValues = require("VargursVampireMod/Mechanics/Consumption/Liquid/SustenanceValues")

local BloodSpice = {}
BloodSpice.itemType = "Base.VargursBloodSpice"
BloodSpice.fluidAmountPerSeasoning = 0.2

local fluidTypes = { "AnimalBlood", "VargursHumanBlood" }
local nutritionFields = { "calories", "carbohydrates", "proteins", "lipids" }
local VOLUME_EPSILON = 0.000001
local SOURCE_VOLUME_SHORTFALL_TOLERANCE = 0.02

function BloodSpice.supportsRecipe(recipe)
    local ingredients = recipe:getItemsList()
    return ingredients:get("VargursBloodSpice") ~= nil or ingredients:get("OilOlive") ~= nil
end

function BloodSpice.registerRecipe(recipe)
    local ingredients = recipe:getItemsList()
    if ingredients:get("VargursBloodSpice") then
        return true
    end
    if not ingredients:get("OilOlive") then
        return false
    end

    ingredients:put("VargursBloodSpice", ItemRecipe.new("VargursBloodSpice", "Base", 2))
    return true
end

local function sourceComposition(source)
    local container = source:getFluidContainer()
    if not container then
        return nil
    end
    if source:isSealed() then
        return nil
    end
    local amount = container:getAmount()
    local minimumAmount = BloodSpice.fluidAmountPerSeasoning - SOURCE_VOLUME_SHORTFALL_TOLERANCE
    if amount < minimumAmount then
        return nil
    end

    local portions = {}
    local bloodAmount = 0.0
    for _, fluidType in ipairs(fluidTypes) do
        local fluid = Fluid.Get(fluidType)
        if fluid and container:contains(fluid) then
            local fluidAmount = container:getSpecificFluidAmount(fluid)
            portions[fluidType] = fluidAmount / amount
            bloodAmount = bloodAmount + fluidAmount
        end
    end

    if bloodAmount <= 0.0 then
        return nil
    end
    if amount - bloodAmount > VOLUME_EPSILON then
        return nil
    end
    return {
        fluidPortions = portions,
        consumedAmount = math.min(amount, BloodSpice.fluidAmountPerSeasoning),
    }
end

function BloodSpice.getSourceComposition(source)
    return sourceComposition(source)
end

function BloodSpice.handles(recipe, source)
    return source:getFluidContainer() ~= nil and BloodSpice.supportsRecipe(recipe) and recipe:getItemRecipe(source) == nil
end

function BloodSpice.canAdd(recipe, dish, source, player, composition)
    if source == dish or not instanceof(dish, "Food") or not recipe:isResultItem(dish) then
        return false
    end
    if not BloodSpice.supportsRecipe(recipe) then
        return false
    end
    if dish:isNoRecipes(player) or source:isNoRecipes(player) then
        return false
    end
    if dish:isFrozen() and not recipe:isAllowFrozenItem() then
        return false
    end

    local spices = dish:getSpices()
    if spices and spices:contains(BloodSpice.itemType) then
        return false
    end

    composition = composition or sourceComposition(source)
    return composition ~= nil, composition
end

function BloodSpice.isValidAction(action)
    local inventory = action.character:getInventory()
    if isClient() then
        if not inventory:containsID(action.baseItem:getID()) or not inventory:containsID(action.usedItem:getID()) then
            return false
        end
    elseif not inventory:contains(action.baseItem) or not inventory:contains(action.usedItem) then
        return false
    end
    return BloodSpice.canAdd(action.recipe, action.baseItem, action.usedItem, action.character)
end

local function createSpice(composition)
    local spice = instanceItem(BloodSpice.itemType)
    if not spice or not instanceof(spice, "Food") then
        return nil
    end
    ---@cast spice Food

    local nutrients = {}
    for _, field in ipairs(nutritionFields) do
        local value = 0.0
        for fluidType, fraction in pairs(composition.fluidPortions) do
            value = value + (LiquidValues[fluidType][field] or 0.0) * fraction * composition.consumedAmount
        end
        nutrients[field] = value
    end
    spice:setCalories(nutrients.calories)
    spice:setCarbohydrates(nutrients.carbohydrates)
    spice:setProteins(nutrients.proteins)
    spice:setLipids(nutrients.lipids)
    return spice
end

function BloodSpice.add(action)
    local valid, composition = BloodSpice.isValidAction(action)
    if not valid or not BloodSpice.registerRecipe(action.recipe) then
        return nil
    end

    local spice = createSpice(composition)
    if not spice then
        return nil
    end

    local inventory = action.character:getInventory()
    inventory:AddItem(spice)
    if not action.recipe:getItemsCanBeUse(action.character, action.baseItem, nil):contains(spice) then
        inventory:Remove(spice)
        return nil
    end

    action.character:removeFromHands(action.baseItem)
    local result = action.recipe:addItem(action.baseItem, spice, action.character)
    if inventory:contains(spice) then
        inventory:Remove(spice)
    end
    if not result or not result:getSpices() or not result:getSpices():contains(BloodSpice.itemType) then
        return nil
    end

    action.usedItem:getFluidContainer():removeFluid(composition.consumedAmount)
    action.usedItem:syncItemFields()
    return result
end

return BloodSpice
