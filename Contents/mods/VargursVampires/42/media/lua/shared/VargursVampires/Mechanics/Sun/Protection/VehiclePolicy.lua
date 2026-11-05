local Config = require("VargursVampires/Infrastructure/Config")

local VehiclePolicy = {}
local UNPROTECTED_EXPOSURE_MULTIPLIER = 1.0

function VehiclePolicy.multiplier(player)
    if not player or player:getVehicle() then
        return 1.0 - Config.get().sunAttenuationVehicle
    end

    return UNPROTECTED_EXPOSURE_MULTIPLIER
end

return VehiclePolicy
