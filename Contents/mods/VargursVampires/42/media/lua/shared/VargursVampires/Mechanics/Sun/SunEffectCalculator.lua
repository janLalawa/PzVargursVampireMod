local Constants = require("VargursVampires/Infrastructure/Constants") --[[@as any]]
local SunPain = require("VargursVampires/Mechanics/Sun/Pain/SunPain")

local SunEffectCalculator = {}

function SunEffectCalculator.damageUV(localUV, damageCurve)
    local exponent = damageCurve and damageCurve.exponent or Constants.SUN_DAMAGE_CURVE_EXPONENT
    local crossoverUV = damageCurve and damageCurve.referenceUV or Constants.SUN_DAMAGE_CURVE_CROSSOVER_UV
    local boundedUV = math.max(0.0, math.min(Constants.MAX_SUN_EXPOSURE_MULTIPLIER, localUV))
    if exponent == 1.0 then return boundedUV end
    return math.min(Constants.MAX_SUN_EXPOSURE_MULTIPLIER,
        crossoverUV * (boundedUV / crossoverUV) ^ exponent)
end

function SunEffectCalculator.damageMultiplier(weightedUV)
    return math.max(0.0, math.min(Constants.MAX_SUN_EXPOSURE_MULTIPLIER, weightedUV))
end

function SunEffectCalculator.damage(weightedUV, elapsedMinutes, config)
    local multiplier = SunEffectCalculator.damageMultiplier(weightedUV)
    local elapsed = math.max(0.0, elapsedMinutes)

    return multiplier * config.sunDamagePerMinute * elapsed
end

function SunEffectCalculator.calculateRates(model, config, damageCurve)
    local totalDamagePerGameMinute = 0.0
    for _, region in pairs(model.regions) do
        local damageUV = SunEffectCalculator.damageUV(region.effectiveUV, damageCurve)
        region.damagePerMinute = SunEffectCalculator.damage(damageUV * region.weight, 1.0, config)
        if model.debug then
            totalDamagePerGameMinute = totalDamagePerGameMinute + region.damagePerMinute
        end
    end
    if model.debug then
        model.debug.totalDamagePerGameMinute = totalDamagePerGameMinute
    end
    return model
end

---@param model PlayerSunModel
---@return PlayerSunModel
function SunEffectCalculator.calculate(model, elapsedMinutes, config, remainingHealth)
    SunEffectCalculator.calculateRates(model, config)
    for _, region in pairs(model.regions) do
        region.damage = region.damagePerMinute * math.max(0.0, elapsedMinutes)
    end

    SunPain.update(model, elapsedMinutes, remainingHealth or 100.0)
    return model
end

return SunEffectCalculator
