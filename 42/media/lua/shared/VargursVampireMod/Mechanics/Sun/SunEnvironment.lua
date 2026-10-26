local PositionPolicy = require("VargursVampireMod/Mechanics/Sun/Protection/Position/PositionPolicy")
local TimeOfDayPolicy = require("VargursVampireMod/Mechanics/Sun/Protection/TimeOfDayPolicy")
local VehiclePolicy = require("VargursVampireMod/Mechanics/Sun/Protection/VehiclePolicy")
local WeatherPolicy = require("VargursVampireMod/Mechanics/Sun/Protection/WeatherPolicy")

---@class SunEnvironmentSnapshot
---@field daylightIntensity number
---@field weatherMultiplier number
---@field vehicleMultiplier number
---@field outdoorMultiplier number

local SunEnvironment = {}

---@return SunEnvironmentSnapshot
function SunEnvironment.capture(player)
    if not player then
        return { daylightIntensity = 0.0, weatherMultiplier = 0.0, vehicleMultiplier = 0.0, outdoorMultiplier = 0.0 }
    end
    return {
        daylightIntensity = TimeOfDayPolicy.multiplier(),
        weatherMultiplier = WeatherPolicy.multiplier(),
        vehicleMultiplier = VehiclePolicy.multiplier(player),
        outdoorMultiplier = PositionPolicy.multiplier(player),
    }
end

return SunEnvironment
