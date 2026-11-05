local TreePolicy = require("VargursVampires/Mechanics/Sun/Protection/Position/TreePolicy")
local OverheadPolicy = require("VargursVampires/Mechanics/Sun/Protection/Position/OverheadPolicy")
local WallPolicy = require("VargursVampires/Mechanics/Sun/Protection/Position/WallPolicy")
local IndoorPolicy = require("VargursVampires/Mechanics/Sun/Protection/Position/IndoorPolicy")
local UmbrellaPolicy = require("VargursVampires/Mechanics/Sun/Protection/Position/UmbrellaPolicy")

local PositionPolicy = {}
local CACHE_DURATION_MS = 250
local cacheByPlayer = setmetatable({}, { __mode = "k" })

function PositionPolicy.capture(player, includeDebug)
    if not player then
        if not includeDebug then
            return 0.0
        end
        return 0.0, {
            treeShadeMultiplier = 1.0,
            overheadShadeMultiplier = 1.0,
            wallShadeMultiplier = 1.0,
            shadeMultiplier = 1.0,
            indoorWindowMultiplier = 1.0,
            umbrellaMultiplier = 1.0,
        }
    end
    local square = player:getCurrentSquare()
    if not square then
        cacheByPlayer[player] = nil
        if not includeDebug then
            return 0.0
        end
        return 0.0, {
            treeShadeMultiplier = 1.0,
            overheadShadeMultiplier = 1.0,
            wallShadeMultiplier = 1.0,
            shadeMultiplier = 1.0,
            indoorWindowMultiplier = 1.0,
            umbrellaMultiplier = 1.0,
        }
    end

    local outside = square:isOutside()
    local umbrellaMultiplier = outside and UmbrellaPolicy.multiplier(player) or 1.0
    local now = getTimestampMs()
    local cached = cacheByPlayer[player]
    if cached and cached.square == square and cached.outside == outside and now >= cached.sampledAt and now < cached.expiresAt then
        local multiplier = math.min(cached.multiplier, umbrellaMultiplier)
        if not includeDebug then
            return multiplier
        end
        return multiplier, {
            treeShadeMultiplier = cached.treeShadeMultiplier,
            overheadShadeMultiplier = cached.overheadShadeMultiplier,
            wallShadeMultiplier = cached.wallShadeMultiplier,
            shadeMultiplier = cached.shadeMultiplier,
            indoorWindowMultiplier = cached.indoorWindowMultiplier,
            umbrellaMultiplier = umbrellaMultiplier,
        }
    end

    local treeShadeMultiplier = outside and TreePolicy.multiplier(square) or 1.0
    local overheadShadeMultiplier = outside and OverheadPolicy.multiplier(square) or 1.0
    local wallShadeMultiplier = outside and WallPolicy.multiplier(square) or 1.0
    local shadeMultiplier = math.min(treeShadeMultiplier, overheadShadeMultiplier, wallShadeMultiplier)
    local indoorWindowMultiplier = outside and 1.0 or IndoorPolicy.multiplier(square)
    local multiplier = outside and shadeMultiplier or indoorWindowMultiplier
    cacheByPlayer[player] = {
        square = square,
        outside = outside,
        sampledAt = now,
        expiresAt = now + CACHE_DURATION_MS,
        multiplier = multiplier,
        treeShadeMultiplier = treeShadeMultiplier,
        overheadShadeMultiplier = overheadShadeMultiplier,
        wallShadeMultiplier = wallShadeMultiplier,
        shadeMultiplier = shadeMultiplier,
        indoorWindowMultiplier = indoorWindowMultiplier,
    }

    local positionMultiplier = math.min(multiplier, umbrellaMultiplier)
    if not includeDebug then
        return positionMultiplier
    end
    return positionMultiplier, {
        treeShadeMultiplier = treeShadeMultiplier,
        overheadShadeMultiplier = overheadShadeMultiplier,
        wallShadeMultiplier = wallShadeMultiplier,
        shadeMultiplier = shadeMultiplier,
        indoorWindowMultiplier = indoorWindowMultiplier,
        umbrellaMultiplier = umbrellaMultiplier,
    }
end

function PositionPolicy.multiplier(player)
    return PositionPolicy.capture(player, false)
end

return PositionPolicy
