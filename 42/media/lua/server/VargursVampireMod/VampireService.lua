local Config = require("VargursVampireMod/Infrastructure/Config")
local State = require("VargursVampireMod/PlayerState/State")
---@type VargursSunExposurePolicy
local SunExposure = require("VargursVampireMod/Mechanics/Sun/SunExposure")
local SunEffects = require("VargursVampireMod/Mechanics/Sun/SunEffects")
local SunPainAdapter = require("VargursVampireMod/PlayerState/SunPainAdapter")
local Health = require("VargursVampireMod/PlayerState/Health")
local SunBurns = require("VargursVampireMod/Mechanics/Sun/SunBurns")
---@type VargursVampireNetwork
local Network = require("VargursVampireMod/Infrastructure/Network")

local VampireService = {}

local function isDead(player)
    return not player or player:isDead()
end

local function applySunPain(player, painByRegion)
    if SunPainAdapter.apply(player, painByRegion) then
        Health.queueSync(player)
    end
end

local function clearSunPain(player, state)
    SunBurns.clear(player)
    if state then
        state.sunPainRecovery = {}
    end
    applySunPain(player, {})
end

local function updateSunExposure(player, state, elapsedMinutes)
    if not Config.get().sunDamageEnabled then
        State.setSunStress(player, 0.0)
        clearSunPain(player, state)
        return
    end

    local exposure = SunExposure.sample(player)
    local effects = SunEffects.calculate(exposure, state.sunStress, elapsedMinutes, Config.get(), state.sunPainRecovery)
    state.sunPainRecovery = effects.painRecoveryByRegion
    applySunPain(player, effects.painByRegion)

    State.setSunStress(player, effects.sunStress)
    local depletedParts = Health.applyRegionalDamage(player, effects.damageByRegion)
    SunBurns.applyDepleted(player, depletedParts)
    if Config.get().sunDamagePerMinute > 0.0 then
        SunBurns.update(player, exposure, elapsedMinutes)
    else
        SunBurns.clear(player)
    end
end

function VampireService.initializePlayer(player)
    local config = Config.get()
    if not config.enabled then
        return
    end

    State.get(player, config.startAsVampire)
    Network.syncState(player)
end

function VampireService.updatePlayer(player, elapsedMinutes)
    if not player then
        return
    end

    if not Config.get().enabled or isDead(player) then
        clearSunPain(player, State.get(player, Config.get().startAsVampire))
        return
    end

    local state = State.get(player, Config.get().startAsVampire)
    if not state or not state.isVampire then
        clearSunPain(player, state)
        return
    end

    if elapsedMinutes <= 0.0 then
        return
    end

    updateSunExposure(player, state, elapsedMinutes)
end

function VampireService.syncPlayer(player)
    if not player then
        return
    end

    Health.syncDamage(player)
    Network.syncState(player)
end

return VampireService
