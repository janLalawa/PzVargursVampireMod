---@class SunPainCurvePoint
---@field survivalMinutes number
---@field pain number

---@class VargursSunPainPolicy
---@field painCurve SunPainCurvePoint[]
---@field recoveryPerMinute number
local SunPainPolicy = {
    painCurve = {
        { survivalMinutes = 180.0, pain = 5.0 },
        { survivalMinutes = 120.0, pain = 15.0 },
        { survivalMinutes = 75.0, pain = 30.0 },
        { survivalMinutes = 45.0, pain = 50.0 },
        { survivalMinutes = 30.0, pain = 60.0 },
        { survivalMinutes = 15.0, pain = 80.0 },
    },
    recoveryPerMinute = 4.0,
}

return SunPainPolicy
