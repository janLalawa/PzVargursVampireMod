local Constants = require("VargursVampireMod/Infrastructure/Constants")
local SunPain = require("VargursVampireMod/Mechanics/Sun/SunPain")

local SunEffects = {}

function SunEffects.stressAfter(currentStress, directUV, elapsedMinutes, config)
    local delta = -config.sunStressRecoveryFractionPerMinute * elapsedMinutes
    if directUV > 0.0 then
        delta = directUV * config.sunStressGainFractionPerMinute * elapsedMinutes
    end

    return math.max(0.0, math.min(Constants.MAX_SUN_STRESS, currentStress + delta))
end

function SunEffects.damageMultiplier(directUV)
    return math.max(0.0, math.min(Constants.MAX_SUN_EXPOSURE_MULTIPLIER, directUV))
end

function SunEffects.damage(directUV, elapsedMinutes, config)
    local multiplier = SunEffects.damageMultiplier(directUV)
    local elapsed = math.max(0.0, elapsedMinutes)

    return multiplier * config.sunDamagePerMinute * elapsed
end

function SunEffects.calculate(exposure, currentStress, elapsedMinutes, config, previousPainRecovery)
    local damageByRegion = {}

    for regionName, region in pairs(exposure.regions) do
        damageByRegion[regionName] = SunEffects.damage(region.weightedUV, elapsedMinutes, config)
    end

    local targets = SunPain.calculate(exposure)
    local recovery = SunPain.recover(targets, previousPainRecovery or {}, currentStress, elapsedMinutes)
    return {
        sunStress = SunEffects.stressAfter(currentStress, exposure.directUV, elapsedMinutes, config),
        damageByRegion = damageByRegion,
        painByRegion = recovery.painByRegion,
        painRecoveryByRegion = recovery.stateByRegion,
    }
end

return SunEffects
