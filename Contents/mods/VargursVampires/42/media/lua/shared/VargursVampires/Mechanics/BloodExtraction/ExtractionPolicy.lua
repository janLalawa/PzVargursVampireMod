local Config = require("VargursVampires/Infrastructure/Config")
local State = require("VargursVampires/PlayerState/State")
local ExtractionValues = require("VargursVampires/Mechanics/BloodExtraction/ExtractionValues")

local ExtractionPolicy = {
    extractedKey = "VargursVampiresBloodExtracted",
    freshnessHours = 2.0,
    duration = 180,
}

local VOLUME_EPSILON = 0.000001

---@param corpse IsoDeadBody
---@return VargursBloodExtractionProfile
function ExtractionPolicy.profile(corpse)
    if corpse:isAnimal() then
        return ExtractionValues.animals[corpse:getAnimalType()] or ExtractionValues.animalDefault
    end
    local data = corpse:getModData()
    if (type(data.ProjectALifeCorpseOf) == "string" and data.ProjectALifeCorpseOf ~= "")
        or data.ProjectALifeOwned == true or not corpse:isZombie() then
        return ExtractionValues.human
    end
    return ExtractionValues.zombie
end

local function animalBloodQuantity(corpse)
    local quantity = corpse:getModData().BloodQty
    if type(quantity) ~= "number" or quantity ~= quantity or quantity < 0.0 or quantity == math.huge then
        return nil
    end
    return quantity
end

function ExtractionPolicy.isTool(item)
    return item and item:getCondition() > 0 and item:hasTag(ItemTag.SHARP_KNIFE)
end

function ExtractionPolicy.corpseReason(corpse)
    if not corpse or not instanceof(corpse, "IsoDeadBody") or corpse:getStaticMovingObjectIndex() < 0 or not corpse:getSquare() then
        return "Corpse"
    end
    if corpse:isSkeleton() or corpse:isFakeDead() or corpse:getSquare():haveFire() then
        return "Corpse"
    end
    if corpse:getModData()[ExtractionPolicy.extractedKey] then
        return "Extracted"
    end
    if corpse:isAnimal() then
        local quantity = animalBloodQuantity(corpse)
        if quantity and quantity <= VOLUME_EPSILON then
            return "Depleted"
        end
    end

    local deathTime = corpse:getDeathTime()
    local age = getGameTime():getWorldAgeHours() - deathTime
    if deathTime < 0.0 or age < 0.0 or age > ExtractionPolicy.freshnessHours then
        return "Freshness"
    end
end

function ExtractionPolicy.containerReason(item, fluidType)
    local container = item and item:getFluidContainer()
    local fluid = Fluid.Get(fluidType or ExtractionValues.zombie.fluidType)

    if not container or item:isSealed() or not fluid or not container:canAddFluid(fluid) then
        return "Container"
    end

    if container:getAmount() > VOLUME_EPSILON then
        local bloodAmount = container:contains(fluid) and container:getSpecificFluidAmount(fluid) or 0.0
        if container:getAmount() - bloodAmount > VOLUME_EPSILON then
            return "Mixture"
        end
    end

    if container:getFreeCapacity() <= VOLUME_EPSILON then
        return "Capacity"
    end
end

function ExtractionPolicy.canExtract(player, corpse, container, tool, requireReach)
    if not Config.get().enabled or not player or player:isDead() or player:getVehicle() then
        return false, "Player"
    end
    if not State.isVampire(player) then
        return false, "Vampire"
    end

    local reason = ExtractionPolicy.corpseReason(corpse)
    if reason then
        return false, reason
    end

    local inventory = player:getInventory()
    if not ExtractionPolicy.isTool(tool) or inventory:getItemById(tool:getID()) ~= tool then
        return false, "Tool"
    end

    if not container or inventory:getItemById(container:getID()) ~= container then
        return false, "Container"
    end

    local containerReason = ExtractionPolicy.containerReason(container, ExtractionPolicy.profile(corpse).fluidType)
    if containerReason then
        return false, containerReason
    end

    if requireReach then
        local deltaX = player:getX() - corpse:getX()
        local deltaY = player:getY() - corpse:getY()
        local square = player:getSquare()
        if not square or player:getZ() ~= corpse:getZ() or deltaX * deltaX + deltaY * deltaY > 4.0 or not square:canReachTo(corpse:getSquare()) then
            return false, "Distance"
        end
    end

    return true
end

function ExtractionPolicy.extract(player, corpse, item, tool)
    if isClient() and not isServer() then
        return false
    end

    local valid, reason = ExtractionPolicy.canExtract(player, corpse, item, tool, true)
    if not valid then
        return false, reason
    end

    local container = item:getFluidContainer()
    local before = container:getAmount()
    local profile = ExtractionPolicy.profile(corpse)
    local animalBlood = corpse:isAnimal() and animalBloodQuantity(corpse) or nil
    local amount = animalBlood or ZombRand(profile.minimumYield * 100, profile.maximumYield * 100 + 1) / 100.0
    amount = math.min(amount, container:getFreeCapacity())
    container:addFluid(Fluid.Get(profile.fluidType), amount)

    local added = container:getAmount() - before
    if added <= VOLUME_EPSILON then
        return false, "Container"
    end

    local data = corpse:getModData()
    if animalBlood then
        data.BloodQty = math.max(0.0, animalBlood - added)
    end
    data[ExtractionPolicy.extractedKey] = true
    corpse:transmitModData()
    item:sendSyncEntity(nil)

    return true, added
end

return ExtractionPolicy
