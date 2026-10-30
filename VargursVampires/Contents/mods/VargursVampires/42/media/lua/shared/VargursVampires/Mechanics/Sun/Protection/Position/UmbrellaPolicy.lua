local UmbrellaPolicy = {}
local SHADED_EXPOSURE = 0.4

local function providesShade(item)
    return item and item:isProtectFromRainWhileEquipped()
end

function UmbrellaPolicy.multiplier(player)
    if player and (providesShade(player:getPrimaryHandItem()) or providesShade(player:getSecondaryHandItem())) then
        return SHADED_EXPOSURE
    end
    return 1.0
end

return UmbrellaPolicy
