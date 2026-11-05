local State = require("VargursVampires/PlayerState/State")
local MixedFoodPolicy = require("VargursVampires/Mechanics/Consumption/Food/MixedFoodPolicy")
local SingleFoodPolicy = require("VargursVampires/Mechanics/Consumption/Food/SingleFoodPolicy")
local SustenanceValues = require("VargursVampires/Mechanics/Consumption/Food/SustenanceValues")

---@class FoodSustenancePolicy
local FoodPolicy = {}

local function isMixedDish(food)
    local extraItems = food:getExtraItems()
    if extraItems and extraItems:size() > 0 then
        return true
    end

    local spices = food:getSpices()
    if spices then
        for index = 0, spices:size() - 1 do
            if SustenanceValues.items[spices:get(index)] then
                return true
            end
        end
    end

    return false
end

---@param player IsoPlayer
---@param item Food
---@param portion number
---@param vanillaEat fun():any
---@return any
function FoodPolicy.consume(player, item, portion, vanillaEat)
    if (isClient() and not isServer()) or not State.isVampire(player) then
        return vanillaEat()
    end

    if isMixedDish(item) then
        return MixedFoodPolicy.consume(player, item, portion, vanillaEat)
    end
    return SingleFoodPolicy.consume(player, item, portion, vanillaEat)
end

return FoodPolicy
