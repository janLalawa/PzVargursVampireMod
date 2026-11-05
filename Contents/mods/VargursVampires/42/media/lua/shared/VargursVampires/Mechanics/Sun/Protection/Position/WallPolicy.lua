local WallPolicy = {}
local SEARCH_DISTANCE = 2
local SHADED_EXPOSURE = 0.75

function WallPolicy.sunDirection(hour, dawn, noon, dusk)
    if dawn >= dusk or hour <= dawn or hour >= dusk then
        return 0, 0
    end
    if noon <= dawn or noon >= dusk then
        noon = (dawn + dusk) / 2.0
    end
    if hour < (dawn + noon) / 2.0 then
        return 1, 0
    end
    if hour < (noon + dusk) / 2.0 then
        return 0, 1
    end
    return -1, 0
end

function WallPolicy.multiplier(square)
    local climate = getClimateManager():getClimateValuesCopy()
    local offsetX, offsetY = WallPolicy.sunDirection(getGameTime():getTimeOfDay(), climate:getDawn(), climate:getNoon(), climate:getDusk())
    if offsetX == 0 and offsetY == 0 then
        return 1.0
    end

    local cell = square:getCell()
    local current = square
    for distance = 1, SEARCH_DISTANCE do
        local neighbor = cell:getGridSquare(square:getX() + offsetX * distance, square:getY() + offsetY * distance, square:getZ())
        if not neighbor then
            return 1.0
        end
        if current:isWallTo(neighbor) then
            return SHADED_EXPOSURE
        end
        current = neighbor
    end
    return 1.0
end

return WallPolicy
