local Constants = require("VargursVampires/Infrastructure/Constants")
local State = require("VargursVampires/PlayerState/State")

---@class VargursVampiresNetwork
---@field requestState fun(player: IsoPlayer)
---@field syncState fun(player: IsoPlayer)
---@field syncSunStress fun(player: IsoPlayer)
local Network = {}

function Network.requestState(player)
    sendClientCommand(player, Constants.MOD_ID, Constants.COMMAND_REQUEST_STATE, {})
end

function Network.syncState(player)
    if not isServer() or not player then
        return
    end
    sendSyncPlayerFields(player, 2)
    Network.syncSunStress(player)
end

function Network.syncSunStress(player)
    if not isServer() or not player or not State.isVampire(player) then
        return
    end
    sendServerCommand(player, Constants.MOD_ID, Constants.COMMAND_SYNC_SUN_STRESS, {
        onlineID = player:getOnlineID(),
        sunStress = State.getSunStress(player),
    })
end

return Network
