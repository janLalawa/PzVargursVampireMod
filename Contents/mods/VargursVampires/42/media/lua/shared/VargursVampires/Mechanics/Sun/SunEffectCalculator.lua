local Constants = require("VargursVampires/Infrastructure/Constants") --[[@as any]]
local SunPain = require("VargursVampires/Mechanics/Sun/Pain/SunPain")

local SunEffectCalculator = {}

function SunEffectCalculator.damageMultiplier(weightedUV)
    return math.max(0.0, math.min(Constants.MAX_SUN_EXPOSURE_MULTIPLIER, weightedUV))
end

function SunEffectCalculator.damage(weightedUV, elapsedMinutes, config)
    local multiplier = SunEffectCalculator.damageMultiplier(weightedUV)
    local elapsed = math.max(0.0, elapsedMinutes)

    return multiplier * config.sunDamagePerMinute * elapsed
end

---@param model PlayerSunModel
---@return PlayerSunModel
function SunEffectCalculator.calculate(model, elapsedMinutes, config, remainingHealth)
    for _, region in pairs(model.regions) do
        region.damagePerMinute = SunEffectCalculator.damage(region.weightedUV, 1.0, config)
        region.damage = region.damagePerMinute * math.max(0.0, elapsedMinutes)
    end

    SunPain.update(model, elapsedMinutes, remainingHealth or 100.0)
    return model
end

return SunEffectCalculator
