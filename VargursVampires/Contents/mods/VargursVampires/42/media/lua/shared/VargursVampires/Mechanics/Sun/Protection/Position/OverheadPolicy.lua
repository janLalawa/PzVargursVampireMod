local OverheadPolicy = {}
local EAVE_EXPOSURE = 0.8
local CANOPY_EXPOSURE = 0.7

local function squareMultiplier(square, includeEaves)
    if not square then
        return 1.0
    end

    local exposure = includeEaves and square:HasEave() and EAVE_EXPOSURE or 1.0
    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        local sprite = objects:get(index):getSprite()
        local properties = sprite and sprite:getProperties()
        if properties and properties:get("CustomName") == "Canopy" then
            return math.min(exposure, CANOPY_EXPOSURE)
        end
    end
    return exposure
end

function OverheadPolicy.multiplier(square)
    local above = square:getCell():getGridSquare(square:getX(), square:getY(), square:getZ() + 1)
    return math.min(squareMultiplier(square, false), squareMultiplier(above, true))
end

return OverheadPolicy