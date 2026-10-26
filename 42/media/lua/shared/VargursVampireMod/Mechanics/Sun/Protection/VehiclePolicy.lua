local VehiclePolicy = {}
local PROTECTED_EXPOSURE_MULTIPLIER = 0.2
local UNPROTECTED_EXPOSURE_MULTIPLIER = 1.0

function VehiclePolicy.multiplier(player)
    if not player or player:getVehicle() then
        return PROTECTED_EXPOSURE_MULTIPLIER
    end

    return UNPROTECTED_EXPOSURE_MULTIPLIER
end

return VehiclePolicy
