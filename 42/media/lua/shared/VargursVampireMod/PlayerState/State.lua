local Constants = require("VargursVampireMod/Infrastructure/Constants")

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

local function normalizeState(state, startAsVampire)
    state.vitae = nil
    if type(state.isVampire) ~= "boolean" then
        state.isVampire = startAsVampire == true
    end
    state.sunStress = normalizeNumber(state.sunStress, 0.0, Constants.MAX_SUN_STRESS)
    if type(state.sunPainRecovery) ~= "table" then
        state.sunPainRecovery = {}
    end
    return state
end

function State.get(player, startAsVampire)
    local data = getModData(player)
    if not data then
        return nil
    end

    local state = data[Constants.STATE_KEY]
    if type(state) ~= "table" then
        state = {}
        data[Constants.STATE_KEY] = state
    end

    return normalizeState(state, startAsVampire)
end

function State.isVampire(player)
    local state = State.get(player)
    return state ~= nil and state.isVampire
end

function State.setSunStress(player, value)
    local state = State.get(player)
    if not state then
        return nil
    end
    state.sunStress = normalizeNumber(value, 0.0, Constants.MAX_SUN_STRESS)
    return state.sunStress
end

return State
