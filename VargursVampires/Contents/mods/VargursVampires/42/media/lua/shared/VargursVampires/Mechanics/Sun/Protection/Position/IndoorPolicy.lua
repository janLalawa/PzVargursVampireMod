local IndoorPolicy = {}
local GLASS_EXPOSURE = 0.125
local OPEN_EXPOSURE = 0.25
local DISTANT_MULTIPLIER = 0.5
local DIRECTIONS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

local function visibilityBetween(square, neighbor)
    return tostring(square:testVisionAdjacent(neighbor:getX() - square:getX(), neighbor:getY() - square:getY(), 0, false, false))
end

local function openingExposure(square, exterior)
    local visibility = visibilityBetween(square, exterior)
    if visibility == "Blocked" then
        return 0.0
    end

    local window = square:getWindowTo(exterior)
    if window then
        if window:IsOpen() or window:isSmashed() then
            return OPEN_EXPOSURE
        end
        return GLASS_EXPOSURE
    end

    local door = square:getDoorTo(exterior)
    if door then
        if door:IsOpen() then
            return OPEN_EXPOSURE
        end
        return visibility == "ClearThroughClosedDoor" and GLASS_EXPOSURE or 0.0
    end

    if visibility == "Clear" or visibility == "ClearThroughOpenDoor" then
        return OPEN_EXPOSURE
    end
    if visibility == "ClearThroughWindow" or visibility == "ClearThroughClosedDoor" then
        return GLASS_EXPOSURE
    end
    return 0.0
end

local function nearbyOpenings(square)
    local cell = square:getCell()
    local exposure = 0.0
    for _, direction in ipairs(DIRECTIONS) do
        local exterior = cell:getGridSquare(square:getX() + direction[1], square:getY() + direction[2], square:getZ())
        if exterior and exterior:isOutside() then
            exposure = math.max(exposure, openingExposure(square, exterior))
        end
    end
    return exposure
end

function IndoorPolicy.multiplier(square)
    local exposure = nearbyOpenings(square)
    local cell = square:getCell()
    for _, direction in ipairs(DIRECTIONS) do
        local neighbor = cell:getGridSquare(square:getX() + direction[1], square:getY() + direction[2], square:getZ())
        if neighbor and not neighbor:isOutside() then
            local visibility = visibilityBetween(square, neighbor)
            if visibility == "Clear" or visibility == "ClearThroughOpenDoor" then
                exposure = math.max(exposure, nearbyOpenings(neighbor) * DISTANT_MULTIPLIER)
            end
        end
    end
    return exposure
end

return IndoorPolicy