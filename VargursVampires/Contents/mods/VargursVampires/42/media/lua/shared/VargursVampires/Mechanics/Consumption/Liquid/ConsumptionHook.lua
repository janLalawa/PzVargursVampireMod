require("TimedActions/ISDrinkFluidAction")

local LiquidPolicy = require("VargursVampires/Mechanics/Consumption/Liquid/SustenancePolicy")

local function observeDrink(action, vanillaDrink)
    return LiquidPolicy.consume(action, vanillaDrink)
end

local originalUpdateEat = ISDrinkFluidAction.updateEat
function ISDrinkFluidAction:updateEat(delta)
    return observeDrink(self, function()
        return originalUpdateEat(self, delta)
    end)
end
