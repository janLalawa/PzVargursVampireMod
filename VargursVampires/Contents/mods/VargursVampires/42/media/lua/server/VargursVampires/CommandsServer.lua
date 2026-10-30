if isClient() then
    return
end

local Config = require("VargursVampires/Infrastructure/Config")
local Constants = require("VargursVampires/Infrastructure/Constants")
local State = require("VargursVampires/PlayerState/State")
local Network = require("VargursVampires/Infrastructure/Network")

local function onClientCommand(module, command, player)
    if module ~= Constants.MOD_ID or command ~= Constants.COMMAND_REQUEST_STATE or not player then
        return
    end
    if Config.get().uninstall then
        return
    end

    State.get(player)
    Network.syncState(player)
end

Events.OnClientCommand.Add(onClientCommand)
