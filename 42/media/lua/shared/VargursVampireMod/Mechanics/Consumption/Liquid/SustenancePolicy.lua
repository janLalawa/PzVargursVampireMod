local State = require("VargursVampireMod/PlayerState/State")
---@type table<string, table<string, number>|nil>
local SustenanceValues = require("VargursVampireMod/Mechanics/Consumption/Liquid/SustenanceValues")
local ConsumptionEffects = require("VargursVampireMod/Mechanics/Consumption/Effects")

---@class LiquidSustenancePolicy
local LiquidPolicy = {}
---@class SustainedFluid
---@field fluid Fluid
---@field fluidType string
---@field profile table<string, number>
---@type SustainedFluid[]
local fluidCache = {}

local function getSustainedFluids()
    if #fluidCache > 0 then
        return fluidCache
    end

    local result = {}
    local fluids = Fluid.getAllFluids()
    for index = 0, fluids:size() - 1 do
        local fluid = fluids:get(index)
        local fluidType = fluid:getFluidTypeString()
        local profile = SustenanceValues[fluidType]
        if profile then
            table.insert(result, { fluid = fluid, fluidType = fluidType, profile = profile })
        end
    end
    for _, entry in ipairs(result) do
        table.insert(fluidCache, entry)
    end
    return fluidCache
end

local function fluidAmounts(container, fluids)
    local amounts = {}
    for _, entry in ipairs(fluids) do
        if container:contains(entry.fluid) then
            amounts[entry.fluidType] = container:getSpecificFluidAmount(entry.fluid)
        end
    end
    return amounts
end

---@param action ISDrinkFluidAction
---@param vanillaDrink fun():any
---@return any
function LiquidPolicy.consume(action, vanillaDrink)
    local player = action.character
    if (isClient() and not isServer()) or not State.isVampire(player) then
        return vanillaDrink()
    end

    local fluids = getSustainedFluids()
    local before = fluidAmounts(action.fluidContainer, fluids)
    local result = vanillaDrink()
    local after = fluidAmounts(action.fluidContainer, fluids)
    local effects = {}

    for _, entry in ipairs(fluids) do
        local consumedAmount = math.max(0.0, (before[entry.fluidType] or 0.0) - (after[entry.fluidType] or 0.0))
        ConsumptionEffects.accumulate(effects, entry.profile, consumedAmount)
    end

    ConsumptionEffects.apply(player, effects)

    return result
end

return LiquidPolicy
