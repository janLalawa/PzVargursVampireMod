local PositionPolicy = require("VargursVampires/Mechanics/Sun/Protection/Position/PositionPolicy")
local TimeOfDayPolicy = require("VargursVampires/Mechanics/Sun/Protection/TimeOfDayPolicy")
local VehiclePolicy = require("VargursVampires/Mechanics/Sun/Protection/VehiclePolicy")
local WeatherPolicy = require("VargursVampires/Mechanics/Sun/Protection/WeatherPolicy")

local SUN_RESISTANT_TRAIT = CharacterTrait.get(ResourceLocation.of("vargursvampires:sunresistant"))
local SUN_RESISTANT_MULTIPLIER = 0.8

---@class SunEnvironmentSnapshot
---@field daylightIntensity number
---@field weatherMultiplier number
---@field vehicleMultiplier number
---@field outdoorMultiplier number
---@field traitMultiplier number

local SunEnvironment = {}

---@return SunEnvironmentSnapshot
function SunEnvironment.capture(player)
    if not player then
        return { daylightIntensity = 0.0, weatherMultiplier = 0.0, vehicleMultiplier = 0.0, outdoorMultiplier = 0.0, traitMultiplier = 1.0 }
    end
    return {
        daylightIntensity = TimeOfDayPolicy.multiplier(),
        weatherMultiplier = WeatherPolicy.multiplier(),
        vehicleMultiplier = VehiclePolicy.multiplier(player),
        outdoorMultiplier = PositionPolicy.multiplier(player),
        traitMultiplier = player:hasTrait(SUN_RESISTANT_TRAIT) and SUN_RESISTANT_MULTIPLIER or 1.0,
    }
end

return SunEnvironment
