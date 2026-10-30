---@class VargursSunBurnsPolicy
---@field minimumLocalUV number
---@field minimumBurnTime integer
---@field maximumBurnTime integer
---@field checkIntervalMinutes number
local SunBurnsPolicy = {
    minimumLocalUV = 0.6,
    minimumBurnTime = 5,
    maximumBurnTime = 15,
    checkIntervalMinutes = 1.0,
}

return SunBurnsPolicy
