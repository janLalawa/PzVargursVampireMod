local Network = require("VargursVampires/Infrastructure/Network")
local Constants = require("VargursVampires/Infrastructure/Constants")
local State = require("VargursVampires/PlayerState/State")

local function onCreatePlayer(_, player)
    Network.requestState(player)
end

local function onServerCommand(module, command, args)
    if module ~= Constants.MOD_ID or command ~= Constants.COMMAND_SYNC_SUN_STRESS then
        return
    end
    if type(args) ~= "table" or type(args.sunStress) ~= "number" then
        return
    end
    for playerIndex = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(playerIndex)
        if player and player:getOnlineID() == args.onlineID then
            State.setSunStress(player, args.sunStress)
        end
    end
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnServerCommand.Add(onServerCommand)
