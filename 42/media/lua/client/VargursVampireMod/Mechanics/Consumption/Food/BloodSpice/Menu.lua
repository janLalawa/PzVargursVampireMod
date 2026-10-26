require("ISUI/ISInventoryPaneContextMenu")

local BloodSpice = require("VargursVampireMod/Mechanics/Consumption/Food/BloodSpice/Logic")
---@type fun(key: string, ...: any): string
local text = getText

local function bloodSources(player)
    local sources = {}
    local seen = {}
    local containers = ISInventoryPaneContextMenu.getContainers(player)
    if not containers then
        return sources
    end
    for index = 0, containers:size() - 1 do
        local items = containers:get(index):getItems()
        for itemIndex = 0, items:size() - 1 do
            local item = items:get(itemIndex)
            if not seen[item] then
                seen[item] = true
                local composition = BloodSpice.getSourceComposition(item)
                if composition then
                    table.insert(sources, { item = item, composition = composition })
                end
            end
        end
    end
    return sources
end

---@param context ISContextMenu
---@param title string
---@return ISContextMenu|nil
local function findRecipeMenu(context, title)
    for _, option in ipairs(context.options) do
        if option.subOption then
            local subMenu = context:getSubMenu(option.subOption)
            if subMenu then
                if option.name == title then
                    return subMenu
                end
                local found = findRecipeMenu(subMenu, title)
                if found then
                    return found
                end
            end
        end
    end
    return nil
end

---@param context ISContextMenu
---@param recipe EvolvedRecipe
---@return ISContextMenu
local function getRecipeMenu(context, recipe)
    local title = text("ContextMenu_EvolvedRecipe_" .. recipe:getUntranslatedName())
    local existing = findRecipeMenu(context, title)
    if existing then
        return existing
    end

    local option = context:addOption(title, nil)
    local subMenu = context:getNew(context)
    context:addSubMenu(option, subMenu)
    return subMenu
end

local function onFillInventoryObjectContextMenu(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex)
    if not player or player:isDead() then
        return
    end

    local actualItems = ISInventoryPane.getActualItems(items)
    local foodCount = 0
    for _, item in ipairs(actualItems) do
        if instanceof(item, "Food") then
            foodCount = foodCount + 1
        end
    end
    if foodCount == 0 then
        return
    end

    local sources = bloodSources(player)
    if #sources == 0 then
        return
    end

    local recipes = getEvolvedRecipes()
    for _, dish in ipairs(actualItems) do
        if instanceof(dish, "Food") then
            for index = 0, recipes:size() - 1 do
                local recipe = recipes:get(index)
                ---@type ISContextMenu|nil
                local subMenu
                for _, sourceInfo in ipairs(sources) do
                    local source = sourceInfo.item
                    if BloodSpice.canAdd(recipe, dish, source, player, sourceInfo.composition) and BloodSpice.registerRecipe(recipe) then
                        local recipeMenu = subMenu or getRecipeMenu(context, recipe)
                        subMenu = recipeMenu
                        local name = text("Fluid_Name_Blood") .. " (" .. source:getDisplayName() .. ")"
                        local title = text("ContextMenu_Add_Ingredient", name, text("ContextMenu_EvolvedRecipe_Spice"))
                        recipeMenu:addOption(title, recipe, ISInventoryPaneContextMenu.onAddItemInEvoRecipe, dish, source, playerIndex)
                    end
                end
                if subMenu then
                    return
                end
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
