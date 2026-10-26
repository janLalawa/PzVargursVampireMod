require("TimedActions/ISAddItemInRecipe")

local BloodSpice = require("VargursVampireMod/Mechanics/Consumption/Food/BloodSpice/Logic")

local originalIsValidStart = ISAddItemInRecipe.isValidStart
function ISAddItemInRecipe:isValidStart()
    if BloodSpice.handles(self.recipe, self.usedItem) then
        return BloodSpice.isValidAction(self)
    end
    return originalIsValidStart(self)
end

local originalComplete = ISAddItemInRecipe.complete
function ISAddItemInRecipe:complete()
    if not BloodSpice.handles(self.recipe, self.usedItem) then
        return originalComplete(self)
    end
    if isClient() and not isServer() then
        return true
    end

    local result = BloodSpice.add(self)
    if not result then
        return true
    end

    self.baseItem = result
    ISAddItemInRecipe.checkName(self.baseItem, self.recipe)
    if isServer() then
        sendItemStats(self.baseItem)
        if self.usedItem:getContainer() then
            sendItemStats(self.usedItem)
        end
    end
    return true
end
