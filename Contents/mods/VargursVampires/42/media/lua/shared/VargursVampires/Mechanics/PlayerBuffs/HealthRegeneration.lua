local Config = require("VargursVampires/Infrastructure/Config")
local State = require("VargursVampires/PlayerState/State")
local SunExposure = require("VargursVampires/Mechanics/Sun/SunExposure")

local HealthRegeneration = {}
local BASELINE_KEY = "vargursVampiresHealthRegenerationBaseline"
HealthRegeneration.baselineKey = BASELINE_KEY

local function readRates(bodyDamage)
    return {
        standard = bodyDamage:getStandardHealthAddition(),
        reduced = bodyDamage:getReducedHealthAddition(),
        severelyReduced = bodyDamage:getSeverlyReducedHealthAddition(),
        sleeping = bodyDamage:getSleepingHealthAddition(),
    }
end

local function isValidRates(rates)
    return type(rates) == "table"
        and type(rates.standard) == "number"
        and type(rates.reduced) == "number"
        and type(rates.severelyReduced) == "number"
        and type(rates.sleeping) == "number"
end

local function applyRates(bodyDamage, rates, multiplier)
    bodyDamage:setStandardHealthAddition(rates.standard * multiplier)
    bodyDamage:setReducedHealthAddition(rates.reduced * multiplier)
    bodyDamage:setSeverlyReducedHealthAddition(rates.severelyReduced * multiplier)
    bodyDamage:setSleepingHealthAddition(rates.sleeping * multiplier)
end

---@param player IsoPlayer|nil
function HealthRegeneration.updatePlayer(player)
    if not player then
        return
    end

    local modData = player:getModData()
    local baseline = modData[BASELINE_KEY]
    local bodyDamage = player:getBodyDamage()
    local config = Config.get()
    local shouldApply = config.enabled and not player:isDead() and State.isVampire(player)

    if shouldApply then
        if not isValidRates(baseline) then
            baseline = readRates(bodyDamage)
            modData[BASELINE_KEY] = baseline
        end
        local multiplier = config.vampireHealthRegenMultiplier
        if config.sunDamageEnabled and config.sunDamagePerMinute > 0.0 and SunExposure.totalWeightedUV(player) > 0.0 then
            multiplier = 0.0
        end
        applyRates(bodyDamage, baseline, multiplier)
    elseif baseline ~= nil then
        if isValidRates(baseline) then
            applyRates(bodyDamage, baseline, 1.0)
        end
        modData[BASELINE_KEY] = nil
    end
end

return HealthRegeneration
