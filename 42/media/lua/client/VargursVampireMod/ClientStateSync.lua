local Constants = require("VargursVampireMod/Infrastructure/Constants")
local State = require("VargursVampireMod/PlayerState/State")
local Network = require("VargursVampireMod/Infrastructure/Network")
local SunPainAdapter = require("VargursVampireMod/PlayerState/SunPainAdapter")

local function localPlayer(playerID)
    for index = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(index)
        if player and player:getOnlineID() == playerID then
            return player
        end
    end

    return nil
end

local function onServerCommand(module, command, arguments)
    if module ~= Constants.MOD_ID or command ~= Constants.COMMAND_SYNC_STATE then
        return
    end

    local player = localPlayer(arguments.playerID)
    if not player then
        return
    end

    local state = State.get(player)
    state.isVampire = arguments.isVampire
    State.setSunStress(player, arguments.sunStress)
    SunPainAdapter.receivePresentation(player, arguments.sunPain)
end

local function onCreatePlayer(_, player)
    Network.requestState(player)
end

Events.OnServerCommand.Add(onServerCommand)
Events.OnCreatePlayer.Add(onCreatePlayer)
