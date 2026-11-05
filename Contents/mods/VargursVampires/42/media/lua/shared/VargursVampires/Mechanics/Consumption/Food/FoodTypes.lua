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
        and (hasItemTag(fullType, ItemTag.FISH_MEAT) or hasItemTag(fullType, ItemTag.UNCUT_FISH))
end

return FoodTypes
