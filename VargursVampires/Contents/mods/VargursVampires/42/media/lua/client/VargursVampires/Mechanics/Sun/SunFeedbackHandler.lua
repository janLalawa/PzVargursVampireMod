local Config = require("VargursVampires/Infrastructure/Config")
local Constants = require("VargursVampires/Infrastructure/Constants")
local State = require("VargursVampires/PlayerState/State")
local SunExposure = require("VargursVampires/Mechanics/Sun/SunExposure")
local SunGlare = require("VargursVampires/Mechanics/Sun/SunGlare")
local SunBurnSound = require("VargursVampires/Mechanics/Sun/SunBurnSound")

local SAMPLE_INTERVAL_SECONDS = 0.1
local feedbackByPlayerIndex = {}

local function canReceiveFeedback(player, config)
    return config.enabled
        and config.sunDamageEnabled
        and config.sunDamagePerMinute > 0.0
        and player ~= nil
        and not player:isDead()
        and player:getCurrentSquare() ~= nil
        and State.isVampire(player)
end

local function clearPlayerFeedback(playerIndex)
    SunGlare.clear(playerIndex)
    SunBurnSound.stop(playerIndex)
    feedbackByPlayerIndex[playerIndex] = nil
end

local function sampleIntensity(feedback, elapsedSeconds)
    feedback.secondsUntilSample = feedback.secondsUntilSample - elapsedSeconds
    if feedback.secondsUntilSample > 0.0 then
        return false
    end

    local totalWeightedUV = SunExposure.sample(feedback.player).totalWeightedUV
    local normalizedUV = math.max(0.0, math.min(1.0, totalWeightedUV / Constants.SUN_EXPOSURE_FEEDBACK_REFERENCE))
    feedback.intensity = math.sqrt(normalizedUV)
    feedback.secondsUntilSample = SAMPLE_INTERVAL_SECONDS
    return true
end

local function updatePlayerFeedback(playerIndex, config, elapsedSeconds)
    local player = getSpecificPlayer(playerIndex)
    if not canReceiveFeedback(player, config) then
        clearPlayerFeedback(playerIndex)
        return
    end

    local feedback = feedbackByPlayerIndex[playerIndex]
    if not feedback or feedback.player ~= player then
        clearPlayerFeedback(playerIndex)
        feedback = { player = player, intensity = 0.0, secondsUntilSample = 0.0 }
        feedbackByPlayerIndex[playerIndex] = feedback
    end

    if sampleIntensity(feedback, elapsedSeconds) then
        SunBurnSound.update(playerIndex, feedback.intensity)
    end
    SunGlare.update(playerIndex, feedback.intensity, elapsedSeconds, SunGlare.washMultiplier(player))
end

local function onTick()
    local config = Config.get()
    local elapsedSeconds = math.max(0.0, math.min(0.25, getGameTime():getRealworldSecondsSinceLastUpdate()))
    local playerCount = getNumActivePlayers()
    for playerIndex = 0, playerCount - 1 do
        updatePlayerFeedback(playerIndex, config, elapsedSeconds)
    end

    for playerIndex in pairs(feedbackByPlayerIndex) do
        if playerIndex >= playerCount then
            clearPlayerFeedback(playerIndex)
        end
    end
end

local function onPreUIDraw()
    local config = Config.get()
    for playerIndex, feedback in pairs(feedbackByPlayerIndex) do
        local player = getSpecificPlayer(playerIndex)
        if feedback.player == player and canReceiveFeedback(player, config) then
            SunGlare.draw(playerIndex)
        end
    end
end

local function clearAllFeedback()
    SunGlare.clearAll()
    SunBurnSound.stopAll()
    feedbackByPlayerIndex = {}
end

Events.OnTick.Add(onTick)
Events.OnPreUIDraw.Add(onPreUIDraw)
Events.OnMainMenuEnter.Add(clearAllFeedback)
Events.OnDisconnect.Add(clearAllFeedback)
