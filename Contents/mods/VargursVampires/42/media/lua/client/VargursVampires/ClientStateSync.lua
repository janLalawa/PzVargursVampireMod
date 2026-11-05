local Network = require("VargursVampires/Infrastructure/Network")

local function onCreatePlayer(_, player)
    Network.requestState(player)
end

Events.OnCreatePlayer.Add(onCreatePlayer)
