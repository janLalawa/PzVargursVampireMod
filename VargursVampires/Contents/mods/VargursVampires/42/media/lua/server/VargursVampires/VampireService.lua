local Config = require("VargursVampires/Infrastructure/Config")
local State = require("VargursVampires/PlayerState/State")
---@type VargursSunExposurePolicy
local SunExposure = require("VargursVampires/Mechanics/Sun/SunExposure")
local SunEffectCalculator = require("VargursVampires/Mechanics/Sun/SunEffectCalculator") --[[@as any]]
local SunPainAdapter = require("VargursVampires/PlayerState/SunPainAdapter")
local Health = require("VargursVampires/PlayerState/Health")
local SunBurns = require("VargursVampires/Mechanics/Sun/Burns/SunBurns")
local ConsumptionEffects = require("VargursVampires/Mechanics/Consumption/Effects")
---@type VargursVampiresNetwork
local Network = require("VargursVampires/Infrastructure/Network")

local VampireService = {}

local function isDead(player)
    return not player or player:isDead()
end

local function applySunPain(player, regions)
    if SunPainAdapter.apply(player, regions) then
        Health.queueSync(player)
    end
end

local function clearSunPainAndBurnProgress(player, state)
    SunBurns.clear(player)
    if state then
        State.setSunPainRecovery(player, {})
    end
    applySunPain(player, {})
end

local function updateSunExposure(player, state, elapsedMinutes)
    if not Config.get().sunDamageEnabled then
        clearSunPainAndBurnProgress(player, state)
        return
    end

    local model = SunExposure.sample(player, state.sunPainRecovery)
    SunEffectCalculator.calculate(model, elapsedMinutes, Config.get(), player:getBodyDamage():getOverallBodyHealth())
    State.setSunPainRecovery(player, model.regions)
    applySunPain(player, model.regions)

    Health.applyRegionalDamage(player, model.regions)
    if Config.get().sunDamagePerMinute > 0.0 then
        SunBurns.updateExposureBurns(player, model, elapsedMinutes)
    else
        SunBurns.clear(player)
    end
end

function VampireService.initializePlayer(player)
    local config = Config.get()
    if not config.enabled then
        return
    end

    State.get(player)
    Network.syncState(player)
end

function VampireService.updatePlayer(player, elapsedMinutes)
    if not player then
        return
    end

    if not Config.get().enabled or isDead(player) then
        clearSunPainAndBurnProgress(player, State.get(player))
        return
    end

    local state = State.get(player)
    if not state or not State.isVampire(player) then
        clearSunPainAndBurnProgress(player, state)
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

    ConsumptionEffects.syncPlayer(player)
    Health.syncDamage(player)
end

return VampireService
