require("TimedActions/ISEatFoodAction")

---@type FoodSustenancePolicy
local FoodPolicy = require("VargursVampireMod/Mechanics/Consumption/Food/SustenancePolicy")

local function observeEat(action, portion, vanillaEat)
    return FoodPolicy.consume(action.character, action.item, portion, vanillaEat)
end

local originalComplete = ISEatFoodAction.complete
ISEatFoodAction.complete = function(self)
    return observeEat(self, self.percentage, function()
        return originalComplete(self)
    end)
end

local originalEat = ISEatFoodAction.eat
---@param food Food
---@param percentage number
function ISEatFoodAction:eat(food, percentage)
    local consumedFraction = percentage or 1.0
    if consumedFraction > 0.95 then
        consumedFraction = 1.0
    end
    consumedFraction = self.percentage * consumedFraction
    return observeEat(self, consumedFraction, function()
        return originalEat(self, food, percentage)
    end)
end
