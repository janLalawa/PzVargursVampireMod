---@type table<string, boolean|nil>
local sustainingTypes = {
    Bacon = true,
    Beef = true,
    Fish = true,
    Game = true,
    Insect = true,
    Meat = true,
    Poultry = true,
    Sausage = true,
    Seafood = true,
    Venison = true,
}

---@type table<string, boolean|nil>
local sustainingItems = {
    ["Base.DeadBird"] = true,
    ["Base.DeadRabbit"] = true,
    ["Base.DeadSquirrel"] = true,
}

local FoodTypes = {}
local hasItemTag = _G.hasItemTag
local ItemTag = _G.ItemTag

---@param foodType string|nil
---@return boolean
function FoodTypes.isSustaining(foodType, fullType)
    if sustainingTypes[foodType] == true then
        return true
    end

    return fullType ~= nil
        and (sustainingItems[fullType] == true
            or hasItemTag(fullType, ItemTag.FISH_MEAT)
            or hasItemTag(fullType, ItemTag.UNCUT_FISH)
            or hasItemTag(fullType, ItemTag.VERMIN))
end

return FoodTypes
