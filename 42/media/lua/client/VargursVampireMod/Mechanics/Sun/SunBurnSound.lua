local SOUND_NAME = "BurningFlesh"
local MIN_VOLUME = 0.04
local MAX_VOLUME = 0.25
---@type table<integer, integer|nil>
local handlesByPlayerIndex = {}

local SunBurnSound = {}

local function getEmitter()
    local soundManager = getSoundManager() --[[@as SoundManager]]
    return soundManager:getUIEmitter()
end

function SunBurnSound.stop(playerIndex)
    local handle = handlesByPlayerIndex[playerIndex]
    if handle then
        getEmitter():stopSound(handle)
        handlesByPlayerIndex[playerIndex] = nil
    end
end

function SunBurnSound.update(playerIndex, intensity)
    if intensity <= 0.0 then
        SunBurnSound.stop(playerIndex)
        return
    end

    local emitter = getEmitter()
    local handle = handlesByPlayerIndex[playerIndex]
    if not handle or not emitter:isPlaying(handle) then
        handle = emitter:playSound(SOUND_NAME)
        if handle == 0 then
            handlesByPlayerIndex[playerIndex] = nil
            return
        end
        handlesByPlayerIndex[playerIndex] = handle
        emitter:set3D(handle, false)
    end

    local boundedIntensity = math.max(0.0, math.min(1.0, intensity))
    emitter:setVolume(handle, MIN_VOLUME + (MAX_VOLUME - MIN_VOLUME) * boundedIntensity)
end

function SunBurnSound.stopAll()
    for playerIndex in pairs(handlesByPlayerIndex) do
        SunBurnSound.stop(playerIndex)
    end
end

return SunBurnSound