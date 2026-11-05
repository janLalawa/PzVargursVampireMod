---@class VargursExtraSunProtectionArea
---@field region string
---@field transmissionMultiplier? number

---@class VargursClothingItemOverride
---@field profile? string
---@field transmissionMultiplier? number
---@field ExtraProtectionAreas? (string|VargursExtraSunProtectionArea)[]

---@class VargursSunRegionProfile
---@field uncoveredTransmission number
---@field oneLayerTransmission number
---@field twoLayerTransmission number
---@field additionalLayerTransmissionMultiplier number
---@field maxWindTransmissionReduction number

---@class VargursResolvedSunRegionProfile: VargursSunRegionProfile
---@field weight number

---@class VargursClothingProtectionValues
---@field itemOverrides table<string, VargursClothingItemOverride>
---@field clothingProfiles table<string, VargursClothingItemOverride?>
---@field regionProfiles table<string, VargursSunRegionProfile?>
---@field regions table<string, {weight: number, profile: string}?>
---@field get? fun(regionName: string): VargursResolvedSunRegionProfile
---@field getItemOverride? fun(fullType: string): VargursClothingItemOverride
---@type VargursClothingProtectionValues
local ProtectionValues = {
    clothingProfiles = {
        Sealed = {
            transmissionMultiplier = 0.1,
        },
        FaceCover = {
            transmissionMultiplier = 0.25,
        },
        WideBrimHat = {
            transmissionMultiplier = 0.15,
            ExtraProtectionAreas = {
                { region = "Neck", transmissionMultiplier = 0.5 },
                "Head",
            },
        },
    },
    itemOverrides = {
        ["Base.HazmatSuit"] = { profile = "Sealed" },
        ["Base.Hat_BalaclavaFace"] = { profile = "FaceCover" },
        ["Base.Hat_BalaclavaFull"] = { profile = "FaceCover" },
        ["Base.Hat_ShemaghFace"] = { profile = "FaceCover" },
        ["Base.Hat_ShemaghFull"] = { profile = "FaceCover" },
        ["Base.Hat_ShemaghFace_Green"] = { profile = "FaceCover" },
        ["Base.Hat_ShemaghFull_Green"] = { profile = "FaceCover" },
        ["Base.Hat_ShemaghFace_Burlap"] = { profile = "FaceCover" },
        ["Base.Hat_ShemaghFull_Burlap"] = { profile = "FaceCover" },
        ["Base.Hat_ShemaghFace_Cotton"] = { profile = "FaceCover" },
        ["Base.Hat_ShemaghFull_Cotton"] = { profile = "FaceCover" },
        ["Base.ShemaghScarfFace"] = { profile = "FaceCover" },
        ["Base.ShemaghScarfFace_Green"] = { profile = "FaceCover" },
        ["Base.Hat_TarpHat"] = { profile = "WideBrimHat" },
        ["Base.Hat_Ranger"] = { profile = "WideBrimHat" },
        ["Base.Hat_Sheriff"] = { profile = "WideBrimHat" },
        ["Base.Hat_SummerHat"] = { profile = "WideBrimHat" },
        ["Base.Hat_Cowboy"] = { profile = "WideBrimHat" },
        ["Base.Hat_Cowboy_Black"] = { profile = "WideBrimHat" },
        ["Base.Hat_Cowboy_White"] = { profile = "WideBrimHat" },
        ["Base.Hat_Cowboy_CowHide"] = { profile = "WideBrimHat" },
        ["Base.Hat_Cowboy_Angus"] = { profile = "WideBrimHat" },
        ["Base.Hat_Cowboy_Holstein"] = { profile = "WideBrimHat" },
        ["Base.Hat_Cowboy_Simmental"] = { profile = "WideBrimHat" },
        ["Base.Hat_BonnieHat"] = { profile = "WideBrimHat" },
        ["Base.Hat_BonnieHat_CamoGreen"] = { profile = "WideBrimHat" },
        ["Base.Hat_BonnieHat_OliveDrab"] = { profile = "WideBrimHat" },
        ["Base.Hat_BonnieHat_DesertCamoNew"] = { profile = "WideBrimHat" },
        ["Base.Hat_BonnieHat_MiliusCamo"] = { profile = "WideBrimHat" },
        ["Base.Hat_BonnieHat_TigerStripeCamo"] = { profile = "WideBrimHat" },
        ["Base.Hat_BonnieHat_DesertCamo"] = { profile = "WideBrimHat" },
    },
    regionProfiles = {
        Standard = {
            uncoveredTransmission = 1.0,
            oneLayerTransmission = 0.5,
            twoLayerTransmission = 0.1,
            additionalLayerTransmissionMultiplier = 0.7,
            maxWindTransmissionReduction = 0.6,
        },
        StrongCoverage = {
            uncoveredTransmission = 1.0,
            oneLayerTransmission = 0.05,
            twoLayerTransmission = 0.01,
            additionalLayerTransmissionMultiplier = 0.7,
            maxWindTransmissionReduction = 0.6,
        },
        StrongCoverageHighWindProtection = {
            uncoveredTransmission = 1.0,
            oneLayerTransmission = 0.07,
            twoLayerTransmission = 0.01,
            additionalLayerTransmissionMultiplier = 0.7,
            maxWindTransmissionReduction = 0.8,
        },
        StrongTwoLayerCoverage = {
            uncoveredTransmission = 1.0,
            oneLayerTransmission = 0.5,
            twoLayerTransmission = 0.05,
            additionalLayerTransmissionMultiplier = 0.7,
            maxWindTransmissionReduction = 0.6,
        },
    },
    regions = {
        Head = { weight = 7.0, profile = "Standard" },
        Neck = { weight = 2.0, profile = "StrongCoverage" },
        Torso_Upper = { weight = 12.0, profile = "Standard" },
        Torso_Lower = { weight = 8.0, profile = "Standard" },
        Back = { weight = 20.0, profile = "Standard" },
        Groin = { weight = 3.0, profile = "StrongCoverageHighWindProtection" },
        UpperArm_L = { weight = 5.0, profile = "Standard" },
        UpperArm_R = { weight = 5.0, profile = "Standard" },
        ForeArm_L = { weight = 7.0, profile = "Standard" },
        ForeArm_R = { weight = 7.0, profile = "Standard" },
        Hand_L = { weight = 5.0, profile = "StrongCoverage" },
        Hand_R = { weight = 5.0, profile = "StrongCoverage" },
        UpperLeg_L = { weight = 8.0, profile = "StrongCoverageHighWindProtection" },
        UpperLeg_R = { weight = 8.0, profile = "StrongCoverageHighWindProtection" },
        LowerLeg_L = { weight = 6.0, profile = "Standard" },
        LowerLeg_R = { weight = 6.0, profile = "Standard" },
        Foot_L = { weight = 2.0, profile = "StrongTwoLayerCoverage" },
        Foot_R = { weight = 2.0, profile = "StrongTwoLayerCoverage" },
    },
}

function ProtectionValues.get(regionName)
    local region = ProtectionValues.regions[regionName]
    local profileName = region and region.profile or "Standard"
    local source = assert(ProtectionValues.regionProfiles[profileName], "Unknown sun region profile: " .. profileName)
    local profile = {}

    for field, value in pairs(source) do
        profile[field] = value
    end
    profile.weight = region and region.weight or 1.0

    ---@cast profile VargursResolvedSunRegionProfile
    return profile
end

function ProtectionValues.getItemOverride(fullType)
    local itemOverride = ProtectionValues.itemOverrides[fullType] or {}
    local profile = {}
    if itemOverride.profile then
        local source = assert(ProtectionValues.clothingProfiles[itemOverride.profile], "Unknown sun clothing profile: " .. itemOverride.profile)
        for field, value in pairs(source) do
            profile[field] = value
        end
    end
    for field, value in pairs(itemOverride) do
        if field ~= "profile" then
            profile[field] = value
        end
    end
    return profile
end

return ProtectionValues
