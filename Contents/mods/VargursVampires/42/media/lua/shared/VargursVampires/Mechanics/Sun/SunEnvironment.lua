local PositionPolicy = require("VargursVampires/Mechanics/Sun/Protection/Position/PositionPolicy")
local TimeOfDayPolicy = require("VargursVampires/Mechanics/Sun/Protection/TimeOfDayPolicy")
local VehiclePolicy = require("VargursVampires/Mechanics/Sun/Protection/VehiclePolicy")
local WeatherPolicy = require("VargursVampires/Mechanics/Sun/Protection/WeatherPolicy")
local Config = require("VargursVampires/Infrastructure/Config")

local SUN_RESISTANT_TRAIT = CharacterTrait.get(ResourceLocation.of("vargursvampires:sunresistant"))
local SUN_RESISTANT_MULTIPLIER = 0.8

---@class SunEnvironmentSnapshot
---@field daylightIntensity number
---@field weatherMultiplier number
---@field vehicleMultiplier number
---@field positionMultiplier number
---@field traitMultiplier number

---@class SunEnvironmentDebugSnapshot
---@field timeOfDay number
---@field daylightIntensity number
---@field weatherMultiplier number
---@field cloudMultiplier number
---@field fogMultiplier number
---@field rainMultiplier number
---@field vehicleMultiplier number
---@field treeShadeMultiplier number
---@field overheadShadeMultiplier number
---@field wallShadeMultiplier number
---@field shadeMultiplier number
---@field indoorWindowMultiplier number
---@field umbrellaMultiplier number
---@field positionMultiplier number
---@field traitMultiplier number
---@field configuredUVMultiplier number
---@field protectionMultiplier number

local SunEnvironment = {}

---@param includeDebug? boolean
---@return SunEnvironmentSnapshot
---@return SunEnvironmentDebugSnapshot|nil
function SunEnvironment.capture(player, includeDebug)
    if not player then
        local environment = {
            daylightIntensity = 0.0,
            weatherMultiplier = 0.0,
            vehicleMultiplier = 1.0,
            positionMultiplier = 0.0,
            traitMultiplier = 1.0,
        }
        if not includeDebug then
            return environment
        end
        return environment, {
            timeOfDay = 0.0,
            daylightIntensity = 0.0,
            weatherMultiplier = 0.0,
            cloudMultiplier = 1.0,
            fogMultiplier = 1.0,
            rainMultiplier = 1.0,
            vehicleMultiplier = 1.0,
            treeShadeMultiplier = 1.0,
            overheadShadeMultiplier = 1.0,
            wallShadeMultiplier = 1.0,
            shadeMultiplier = 1.0,
            indoorWindowMultiplier = 1.0,
            umbrellaMultiplier = 1.0,
            positionMultiplier = 0.0,
            traitMultiplier = 1.0,
            configuredUVMultiplier = 1.0,
            protectionMultiplier = 0.0,
        }
    end

    local weatherMultiplier, weatherDebug = WeatherPolicy.capture(includeDebug)
    local positionMultiplier, positionDebug = PositionPolicy.capture(player, includeDebug)
    local vehicleMultiplier = VehiclePolicy.multiplier(player)
    local traitMultiplier = player:hasTrait(SUN_RESISTANT_TRAIT) and SUN_RESISTANT_MULTIPLIER or 1.0
    local configuredUVMultiplier = Config.get().sunEnvironmentalUVMultiplier
    local daylightIntensity = TimeOfDayPolicy.multiplier()
    local environment = {
        daylightIntensity = daylightIntensity,
        weatherMultiplier = weatherMultiplier,
        vehicleMultiplier = vehicleMultiplier,
        positionMultiplier = positionMultiplier,
        traitMultiplier = traitMultiplier,
    }
    if not includeDebug then
        return environment
    end

    return environment, {
        timeOfDay = getGameTime():getTimeOfDay(),
        daylightIntensity = daylightIntensity,
        weatherMultiplier = weatherMultiplier,
        cloudMultiplier = weatherDebug.cloudMultiplier,
        fogMultiplier = weatherDebug.fogMultiplier,
        rainMultiplier = weatherDebug.rainMultiplier,
        vehicleMultiplier = vehicleMultiplier,
        treeShadeMultiplier = positionDebug.treeShadeMultiplier,
        overheadShadeMultiplier = positionDebug.overheadShadeMultiplier,
        wallShadeMultiplier = positionDebug.wallShadeMultiplier,
        shadeMultiplier = positionDebug.shadeMultiplier,
        indoorWindowMultiplier = positionDebug.indoorWindowMultiplier,
        umbrellaMultiplier = positionDebug.umbrellaMultiplier,
        positionMultiplier = positionMultiplier,
        traitMultiplier = traitMultiplier,
        configuredUVMultiplier = configuredUVMultiplier,
        protectionMultiplier = weatherMultiplier * vehicleMultiplier * positionMultiplier * traitMultiplier * configuredUVMultiplier,
    }
end

return SunEnvironment
