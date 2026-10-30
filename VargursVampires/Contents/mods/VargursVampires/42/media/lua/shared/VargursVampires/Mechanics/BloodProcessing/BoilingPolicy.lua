local Config = require("VargursVampires/Infrastructure/Config")

local BoilingPolicy = {
    rawFluidType = "VargursZombieBlood",
    boiledFluidType = "VargursBoiledZombieBlood",
    minimumHeat = 1.6,
    yieldFraction = 0.5,
}

function BoilingPolicy.canBoil(item)
    if not item or item:isSealed() then
        return false
    end

    local fluids = item:getFluidContainer()
    if not fluids or fluids:isEmpty() then
        return false
    end

    local raw = Fluid.Get(BoilingPolicy.rawFluidType)
    local boiled = Fluid.Get(BoilingPolicy.boiledFluidType)
    if not raw or not boiled or not fluids:isPureFluid(raw) or not fluids:canAddFluid(boiled) then
        return false
    end

    local container = item:getOutermostContainer()
    if not container or container:getTemperature() <= BoilingPolicy.minimumHeat then
        return false
    end

    if not item:hasTag(ItemTag.COOKABLE) and not (container:isMicrowave() and item:hasTag(ItemTag.COOKABLE_MICROWAVE)) then
        return false
    end

    return item:getItemHeat() > BoilingPolicy.minimumHeat
end

function BoilingPolicy.convert(item)
    if (isClient() and not isServer()) or not BoilingPolicy.canBoil(item) or not Config.get().enabled then
        return false
    end

    local fluids = item:getFluidContainer()
    local originalAmount = fluids:getAmount()
    local amount = originalAmount * BoilingPolicy.yieldFraction

    fluids:Empty()
    fluids:addFluid(Fluid.Get(BoilingPolicy.boiledFluidType), amount)
    if fluids:isEmpty() then
        fluids:addFluid(Fluid.Get(BoilingPolicy.rawFluidType), originalAmount)
        return false
    end

    item:sendSyncEntity(nil)
    return true
end

return BoilingPolicy
