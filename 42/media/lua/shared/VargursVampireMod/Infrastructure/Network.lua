local Constants = require("VargursVampireMod/Infrastructure/Constants")
local State = require("VargursVampireMod/PlayerState/State")
local SunPainAdapter = require("VargursVampireMod/PlayerState/SunPainAdapter")

---@class VargursVampireNetwork
---@field requestState fun(player: IsoPlayer)
---@field syncState fun(player: IsoPlayer)
local Network = {}

function Network.requestState(player)
    sendClientCommand(player, Constants.MOD_ID, Constants.COMMAND_REQUEST_STATE, {})
end

function Network.syncState(player)
    if not isServer() then
        return
    end
    local state = State.get(player)
    if not state then
        return
    end
    sendServerCommand(player, Constants.MOD_ID, Constants.COMMAND_SYNC_STATE, {
        playerID = player:getOnlineID(),
        isVampire = state.isVampire,
        sunStress = state.sunStress,
        sunPain = SunPainAdapter.presentation(player),
    })
end

return Network
