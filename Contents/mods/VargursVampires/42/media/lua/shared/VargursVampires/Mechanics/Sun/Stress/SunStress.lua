local SunStressPolicy = require("VargursVampires/Mechanics/Sun/Stress/SunStressPolicy")

local SunStress = {}

local function clamp(stress)
    return math.max(0.0, math.min(1.0, stress))
end

function SunStress.update(stress, environmentalUV, elapsedMinutes)
    local difference = math.max(0.0, environmentalUV) - SunStressPolicy.environmentalUVCrossover
    local rate = difference > 0.0 and SunStressPolicy.buildupPerGameMinute or SunStressPolicy.recoveryPerGameMinute
    
    return clamp(clamp(stress) + difference * rate * math.max(0.0, elapsedMinutes))
end

function SunStress.multiplier(stress)
    return SunStressPolicy.minimumExposureMultiplier
        + clamp(stress) * (SunStressPolicy.maximumExposureMultiplier - SunStressPolicy.minimumExposureMultiplier)
end

return SunStress