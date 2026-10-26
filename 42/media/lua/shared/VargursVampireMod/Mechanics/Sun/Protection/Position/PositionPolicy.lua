local TreePolicy = require("VargursVampireMod/Mechanics/Sun/Protection/Position/TreePolicy")
local OverheadPolicy = require("VargursVampireMod/Mechanics/Sun/Protection/Position/OverheadPolicy")
local WallPolicy = require("VargursVampireMod/Mechanics/Sun/Protection/Position/WallPolicy")
local IndoorPolicy = require("VargursVampireMod/Mechanics/Sun/Protection/Position/IndoorPolicy")

local PositionPolicy = {}
local CACHE_DURATION_MS = 250
local cacheByPlayer = setmetatable({}, { __mode = "k" })

function PositionPolicy.multiplier(player)
    if not player then
        return 0.0
    end
    local square = player:getCurrentSquare()
    if not square then
        cacheByPlayer[player] = nil
        return 0.0
    end

    local outside = square:isOutside()
    local now = getTimestampMs()
    local cached = cacheByPlayer[player]
    if cached and cached.square == square and cached.outside == outside and now >= cached.sampledAt and now < cached.expiresAt then
        return cached.multiplier
    end

    local multiplier
    if outside then
        multiplier = math.min(TreePolicy.multiplier(square), OverheadPolicy.multiplier(square), WallPolicy.multiplier(square))
    else
        multiplier = IndoorPolicy.multiplier(square)
    end
    cacheByPlayer[player] = {
        square = square,
        outside = outside,
        sampledAt = now,
        expiresAt = now + CACHE_DURATION_MS,
        multiplier = multiplier,
    }
    return multiplier
end

return PositionPolicy