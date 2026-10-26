local ProtectionValues = require("VargursVampireMod/Mechanics/Sun/Protection/Clothing/ProtectionValues")
local ClothingSnapshot = require("VargursVampireMod/Mechanics/Sun/Protection/Clothing/ClothingSnapshot")

local ProtectionPolicy = {}

local function transmissionForLayers(layerCount, profile)
    if layerCount >= 2 then
        local additionalLayers = layerCount - 2
        local additionalTransmission = profile.additionalLayerTransmissionMultiplier ^ additionalLayers
        return profile.twoLayerTransmission * additionalTransmission
    end
    if layerCount == 1 then
        return profile.oneLayerTransmission
    end
    return profile.uncoveredTransmission
end

local function resolveProfiles()
    local profiles = {}
    local totalWeight = 0.0

    for regionName in pairs(ProtectionValues.regions) do
        local profile = ProtectionValues.get(regionName)
        profiles[regionName] = profile
        totalWeight = totalWeight + profile.weight
    end

    return profiles, totalWeight
end

local function calculateRegionalProtection(snapshot, profiles, totalWeight)
    local regionalProtection = {
        shares = {},
        localExposures = {},
        regions = {},
        weightedExposure = 0.0,
    }

    for regionName, profile in pairs(profiles) do
        local observedRegion = snapshot[regionName] or {}
        local layerCount = observedRegion.intactLayers or 0
        local windResistance = observedRegion.windResistance or 0.0
        local regionWeight = profile.weight / totalWeight
        local baseTransmission = transmissionForLayers(layerCount, profile)
        local windBonus = windResistance * profile.maxWindTransmissionReduction
        local transmission = baseTransmission * (1.0 - windBonus)

        local exposureShare = transmission * regionWeight
        regionalProtection.shares[regionName] = exposureShare
        regionalProtection.localExposures[regionName] = transmission
        regionalProtection.weightedExposure = regionalProtection.weightedExposure + exposureShare
        regionalProtection.regions[regionName] = {
            intactLayers = layerCount,
            weight = regionWeight,
            transmission = transmission,
            windResistance = windResistance,
            windProtectionBonus = windBonus,
        }
    end

    return regionalProtection
end

local function summarizeProtection(regionalProtection)
    return {
        regions = regionalProtection.regions,
        multiplier = regionalProtection.weightedExposure,
    }
end

function ProtectionPolicy.calculate(snapshot)
    local profiles, totalWeight = resolveProfiles()
    local regionalProtection = calculateRegionalProtection(snapshot, profiles, totalWeight)
    local protection = summarizeProtection(regionalProtection)

    return regionalProtection.shares, regionalProtection.localExposures, protection
end

function ProtectionPolicy.exposureShares(player)
    return ProtectionPolicy.calculate(ClothingSnapshot.capture(player))
end

function ProtectionPolicy.multiplier(player)
    local _, _, result = ProtectionPolicy.exposureShares(player)
    return result.multiplier
end

return ProtectionPolicy
