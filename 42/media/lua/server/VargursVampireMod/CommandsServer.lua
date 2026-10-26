if isClient() then
    return
end

local Constants = require("VargursVampireMod/Infrastructure/Constants")
local Config = require("VargursVampireMod/Infrastructure/Config")
local State = require("VargursVampireMod/PlayerState/State")
local Network = require("VargursVampireMod/Infrastructure/Network")

local function onClientCommand(module, command, player)
    if module ~= Constants.MOD_ID or command ~= Constants.COMMAND_REQUEST_STATE or not player then
        return
    end

    local config = Config.get()
    State.get(player, config.enabled and config.startAsVampire)
    Network.syncState(player)
end

Events.OnClientCommand.Add(onClientCommand)
