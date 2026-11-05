local Constants = require("VargursVampires/Infrastructure/Constants")

---@class VargursVampiresNetwork
---@field requestState fun(player: IsoPlayer)
---@field syncState fun(player: IsoPlayer)
local Network = {}

function Network.requestState(player)
    sendClientCommand(player, Constants.MOD_ID, Constants.COMMAND_REQUEST_STATE, {})
end

function Network.syncState(player)
    if not isServer() or not player then
        return
    end
    sendSyncPlayerFields(player, 2)
end

return Network
