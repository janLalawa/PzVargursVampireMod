local ProtectionValues = {
    defaults = {
        weight = 1.0,
        uncoveredTransmission = 1.0,
        oneLayerTransmission = 0.5,
        twoLayerTransmission = 0.1,
        additionalLayerTransmissionMultiplier = 0.7,
        maxWindTransmissionReduction = 0.6,
    },
    regions = {
        Head = { weight = 7.0 },
        Neck = { weight = 2.0, oneLayerTransmission = 0.05, twoLayerTransmission = 0.01 },
        Torso_Upper = { weight = 12.0 },
        Torso_Lower = { weight = 8.0 },
        Back = { weight = 20.0 },
        Groin = { weight = 3.0, oneLayerTransmission = 0.07, twoLayerTransmission = 0.01, maxWindTransmissionReduction = 0.8 },
        UpperArm_L = { weight = 5.0 },
        UpperArm_R = { weight = 5.0 },
        ForeArm_L = { weight = 7.0 },
        ForeArm_R = { weight = 7.0 },
        Hand_L = { weight = 5.0, oneLayerTransmission = 0.05, twoLayerTransmission = 0.01 },
        Hand_R = { weight = 5.0, oneLayerTransmission = 0.05, twoLayerTransmission = 0.01 },
        UpperLeg_L = { weight = 8.0, oneLayerTransmission = 0.07, twoLayerTransmission = 0.01, maxWindTransmissionReduction = 0.8 },
        UpperLeg_R = { weight = 8.0, oneLayerTransmission = 0.07, twoLayerTransmission = 0.01, maxWindTransmissionReduction = 0.8 },
        LowerLeg_L = { weight = 6.0 },
        LowerLeg_R = { weight = 6.0 },
        Foot_L = { weight = 2.0, twoLayerTransmission = 0.05 },
        Foot_R = { weight = 2.0, twoLayerTransmission = 0.05 },
    },
}

function ProtectionValues.get(regionName)
    local profile = {}

    for field, value in pairs(ProtectionValues.defaults) do
        profile[field] = value
    end
    for field, value in pairs(ProtectionValues.regions[regionName] or {}) do
        profile[field] = value
    end

    return profile
end

return ProtectionValues
