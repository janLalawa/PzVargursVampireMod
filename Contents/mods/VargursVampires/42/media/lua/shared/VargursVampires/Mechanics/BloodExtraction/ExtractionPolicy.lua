local Config = require("VargursVampires/Infrastructure/Config")
local State = require("VargursVampires/PlayerState/State")
local ExtractionValues = require("VargursVampires/Mechanics/BloodExtraction/ExtractionValues")
local LiquidPolicy = require("VargursVampires/Mechanics/Consumption/Liquid/SustenancePolicy")

local ExtractionPolicy = {
    extractedKey = "VargursVampiresBloodExtracted",
    freshnessHours = 2.0,
    duration = 600,
    maximumFeedAmount = 1.0,
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

local function canAccessCorpse(player, corpse, requireReach)
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

function ExtractionPolicy.canFeed(player, corpse, requireReach)
    local valid, reason = canAccessCorpse(player, corpse, requireReach)
    if not valid then
        return false, reason
    end
    if player:getMoodles():getMoodleLevel(MoodleType.FOOD_EATEN) >= 3 then
        return false, "Full"
    end
    return true
end

function ExtractionPolicy.canExtract(player, corpse, container, tool, requireReach)
    local valid, reason = canAccessCorpse(player, corpse, false)
    if not valid then
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
        return canAccessCorpse(player, corpse, true)
    end

    return true
end

local function bloodAmount(corpse, profile, capacity)
    local animalBlood = corpse:isAnimal() and animalBloodQuantity(corpse) or nil
    local amount = animalBlood and ZombRandFloat(animalBlood * 0.1, animalBlood)
        or ZombRand(profile.minimumYield * 100, profile.maximumYield * 100 + 1) / 100.0
    return math.min(amount, capacity), animalBlood
end

local function markExtracted(corpse, animalBlood, amount)
    local data = corpse:getModData()
    if animalBlood then
        data.BloodQty = math.max(0.0, animalBlood - amount)
    end
    data[ExtractionPolicy.extractedKey] = true
    corpse:transmitModData()
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
    local amount, animalBlood = bloodAmount(corpse, profile, container:getFreeCapacity())
    container:addFluid(Fluid.Get(profile.fluidType), amount)

    local added = container:getAmount() - before
    if added <= VOLUME_EPSILON then
        return false, "Container"
    end

    markExtracted(corpse, animalBlood, added)
    item:syncItemFields()

    return true, added
end

function ExtractionPolicy.feed(player, corpse)
    if isClient() and not isServer() then
        return false
    end
    local valid, reason = ExtractionPolicy.canFeed(player, corpse, true)
    if not valid then
        return false, reason
    end

    local profile = ExtractionPolicy.profile(corpse)
    local fluid = Fluid.Get(profile.fluidType)
    if not fluid then
        return false, "Container"
    end
    local amount, animalBlood = bloodAmount(corpse, profile, ExtractionPolicy.maximumFeedAmount)
    local container = FluidContainer.CreateContainer()
    local before = 0.0
    local ok, failure = pcall(function()
        container:setCapacity(amount)
        container:addFluid(fluid, amount)
        before = container:getAmount()
        if before > VOLUME_EPSILON then
            LiquidPolicy.consumeFluid(player, container, function()
                return player:DrinkFluid(container, 1.0, false)
            end)
        end
    end)
    local consumed = math.max(0.0, before - container:getAmount())
    FluidContainer.DisposeContainer(container)
    if consumed > VOLUME_EPSILON then
        markExtracted(corpse, animalBlood, consumed)
    end
    if not ok then
        error(failure)
    end
    return consumed > VOLUME_EPSILON, consumed
end

return ExtractionPolicy
