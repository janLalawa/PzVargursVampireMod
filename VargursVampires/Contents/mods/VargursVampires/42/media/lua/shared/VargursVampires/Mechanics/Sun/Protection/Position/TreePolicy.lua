local TreePolicy = {}
local SEARCH_RADIUS = 3
local TRUNK_EXPOSURE = 0.4
local CANOPY_EXPOSURE = 0.6
local MIN_EXPOSURE = 0.15

function TreePolicy.radius(size)
    if size >= 5 then
        return SEARCH_RADIUS
    end
    if size >= 3 then
        return 1
    end
    return 0
end

function TreePolicy.multiplier(square)
    local cell = square:getCell()
    local originX, originY, level = square:getX(), square:getY(), square:getZ()
    local exposure = 1.0
    for offsetX = -SEARCH_RADIUS, SEARCH_RADIUS do
        for offsetY = -SEARCH_RADIUS, SEARCH_RADIUS do
            local neighbor = cell:getGridSquare(originX + offsetX, originY + offsetY, level)
            local tree = neighbor and neighbor:getTree()
            if tree then
                local distanceSquared = offsetX * offsetX + offsetY * offsetY
                local radius = TreePolicy.radius(tree:getSize())
                if distanceSquared == 0 then
                    exposure = exposure * TRUNK_EXPOSURE
                elseif distanceSquared <= radius * radius then
                    exposure = exposure * CANOPY_EXPOSURE
                end
            end
        end
    end
    return math.max(MIN_EXPOSURE, exposure)
end

return TreePolicy
