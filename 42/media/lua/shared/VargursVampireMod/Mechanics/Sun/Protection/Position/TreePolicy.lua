local TreePolicy = {}
local SEARCH_RADIUS = 2
local TRUNK_EXPOSURE = 0.5
local CANOPY_EXPOSURE = 0.8

function TreePolicy.radius(size)
    if size >= 5 then
        return 2
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
                if distanceSquared == 0 then
                    return TRUNK_EXPOSURE
                end
                local radius = TreePolicy.radius(tree:getSize())
                if distanceSquared <= radius * radius then
                    exposure = math.min(exposure, CANOPY_EXPOSURE)
                end
            end
        end
    end
    return exposure
end

return TreePolicy