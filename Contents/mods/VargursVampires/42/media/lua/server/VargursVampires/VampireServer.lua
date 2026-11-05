if isClient() then
    return
end

local Config = require("VargursVampires/Infrastructure/Config")
local VampireService = require("VargursVampires/VampireService")
local HealthRegeneration = require("VargursVampires/Mechanics/PlayerBuffs/HealthRegeneration")
local CorpseSicknessResistance = require("VargursVampires/Mechanics/PlayerBuffs/CorpseSicknessResistance")
local Uninstall = require("VargursVampires/Uninstall")
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
    if Config.get().uninstall then
        Uninstall.cleanPlayer(player)
        return
    end
    VampireService.initializePlayer(player)
    HealthRegeneration.updatePlayer(player)
    CorpseSicknessResistance.updatePlayer(player)
end

local function onEveryOneMinute()
    if Config.get().uninstall then
        eachOnlinePlayer(Uninstall.cleanPlayer)
    end
end

local function onTick()
    if Config.get().uninstall then
        return
    end
    local gameTime = getGameTime()
    local elapsedMinutes = gameTime:getGameWorldSecondsSinceLastUpdate() / SECONDS_PER_MINUTE
    eachOnlinePlayer(function(player)
        if elapsedMinutes > 0.0 then
            VampireService.updatePlayer(player, elapsedMinutes)
        end
        HealthRegeneration.updatePlayer(player)
        CorpseSicknessResistance.updatePlayer(player)
    end)

    secondsSinceSync = secondsSinceSync + gameTime:getRealworldSecondsSinceLastUpdate()
    if secondsSinceSync >= SYNC_INTERVAL_REAL_SECONDS then
        secondsSinceSync = secondsSinceSync % SYNC_INTERVAL_REAL_SECONDS
        eachOnlinePlayer(VampireService.syncPlayer)
    end
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.EveryOneMinute.Add(onEveryOneMinute)
Events.OnTick.Add(onTick)
