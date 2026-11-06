local Constants = require("VargursVampires/Infrastructure/Constants")
local VampireTrait = require("VargursVampires/PlayerState/VampireTrait")

local State = {}

local function normalizeNumber(value, fallback, maximum)
    if type(value) ~= "number" or value ~= value then
        value = fallback
    end
    return math.max(0.0, math.min(maximum, value))
end

local function getModData(player)
    if not player then
        return nil
    end
    return player:getModData()
end

local function normalizeState(state)
    state.vitae = nil
    state.sunStress = normalizeNumber(state.sunStress, 0.0, 1.0)
    if type(state.sunPainRecovery) ~= "table" then
        state.sunPainRecovery = {}
    end
    return state
end

function State.get(player)
    local data = getModData(player)
    if not data then
        return nil
    end

    local state = data[Constants.STATE_KEY]
    if type(state) ~= "table" then
        state = {}
        data[Constants.STATE_KEY] = state
    end

    return normalizeState(state)
end

function State.isVampire(player)
    return VampireTrait.has(player)
end

function State.getSunStress(player)
    local data = getModData(player)
    local state = data and data[Constants.STATE_KEY]
    if type(state) ~= "table" then
        return 0.0
    end
    return normalizeNumber(state.sunStress, 0.0, 1.0)
end

function State.setSunStress(player, stress)
    local state = State.get(player)
    if state then
        state.sunStress = normalizeNumber(stress, 0.0, 1.0)
    end
end

---@param regions table<string, SunRegion>
function State.setSunPainRecovery(player, regions)
    local state = State.get(player)
    if not state then
        return nil
    end
    local savedPain = {}
    for regionName, region in pairs(regions) do
        if region.pain > 0.0 then
            savedPain[regionName] = { pain = region.pain }
        end
    end
    state.sunPainRecovery = savedPain
    return state.sunPainRecovery
end

return State
