if isClient() then
    return
end

local VampireService = require("VargursVampireMod/VampireService")
local SECONDS_PER_MINUTE = 60.0
local SYNC_INTERVAL_REAL_SECONDS = 1.0
local secondsSinceSync = 0.0

local function eachOnlinePlayer(callback)
    if isServer() then
        local players = getOnlinePlayers()
        for index = 0, players:size() - 1 do
            callback(players:get(index))
        end
        return
    end

    for index = 0, getNumActivePlayers() - 1 do
        callback(getSpecificPlayer(index))
    end
end

local function onCreatePlayer(_, player)
    VampireService.initializePlayer(player)
end

local function onTick()
    local gameTime = getGameTime()
    local elapsedMinutes = gameTime:getGameWorldSecondsSinceLastUpdate() / SECONDS_PER_MINUTE
    if elapsedMinutes > 0.0 then
        eachOnlinePlayer(function(player)
            VampireService.updatePlayer(player, elapsedMinutes)
        end)
    end

    secondsSinceSync = secondsSinceSync + gameTime:getRealworldSecondsSinceLastUpdate()
    if secondsSinceSync >= SYNC_INTERVAL_REAL_SECONDS then
        secondsSinceSync = secondsSinceSync % SYNC_INTERVAL_REAL_SECONDS
        eachOnlinePlayer(VampireService.syncPlayer)
    end
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnTick.Add(onTick)
