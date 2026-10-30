---@type table<string, boolean|nil>
local sustainingTypes = {
    Bacon = true,
    Beef = true,
    Game = true,
    Meat = true,
    Poultry = true,
    Sausage = true,
    Venison = true,
}

local FoodTypes = {}

---@param foodType string|nil
---@return boolean
function FoodTypes.isSustaining(foodType)
    return sustainingTypes[foodType] == true
end

return FoodTypes
