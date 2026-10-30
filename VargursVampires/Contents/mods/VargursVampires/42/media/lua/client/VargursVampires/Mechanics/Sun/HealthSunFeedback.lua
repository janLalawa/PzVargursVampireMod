require("XpSystem/ISUI/ISHealthPanel")

local Config = require("VargursVampires/Infrastructure/Config") --[[@as any]]
local Constants = require("VargursVampires/Infrastructure/Constants")
local State = require("VargursVampires/PlayerState/State")
local BodyRegions = require("VargursVampires/PlayerState/BodyRegions") --[[@as any]]
local SunExposure = require("VargursVampires/Mechanics/Sun/SunExposure") --[[@as any]]

---@class HealthSunFeedbackSnapshot
---@field patient IsoPlayer
---@field levelsByPart table<integer, number>
---@field nextRefreshMs number

---@class ISHealthPanel
---@field vargursSunFeedback? HealthSunFeedbackSnapshot

local SAMPLE_INTERVAL_MS = 250
local ROW_PADDING = 5
---@type table<number, string>
local sensationKeys = {
    "IGUI_VargursVampires_SkinPrickling",
    "IGUI_VargursVampires_SkinBurning",
    "IGUI_VargursVampires_SkinSearing",
}

local function sensationThresholds(config)
    local minimumUV = Constants.MIN_EFFECTIVE_LOCAL_UV
    local maximumUV = math.min(Constants.SUN_EXPOSURE_FEEDBACK_REFERENCE, config.sunEnvironmentalUVMultiplier * (1.0 + config.sunNoonIntensityBonus))
    maximumUV = math.max(minimumUV, maximumUV)

    return minimumUV + (maximumUV - minimumUV) / 3, minimumUV + 2 * (maximumUV - minimumUV) / 3
end

local function canShowFeedback(panel)
    local config = Config.get()
    local patient = panel:getPatient()
    return panel:isReallyVisible()
        and config.enabled
        and config.sunDamageEnabled
        and patient ~= nil
        and patient:isLocalPlayer()
        and not patient:isDead()
        and patient:getCurrentSquare() ~= nil
        and State.isVampire(patient)
end

---@param panel ISHealthPanel
---@return HealthSunFeedbackSnapshot?
local function getFeedback(panel)
    if not canShowFeedback(panel) then
        panel.vargursSunFeedback = nil
        return nil
    end
    local now = getTimestampMs()
    local patient = panel:getPatient()
    local feedback = panel.vargursSunFeedback
    if feedback and feedback.patient == patient and now < feedback.nextRefreshMs then
        return feedback
    end

    local config = Config.get()
    local burningUV, searingUV = sensationThresholds(config)
    local model = SunExposure.sample(patient)
    local levelsByRegion = {}
    for regionName, region in pairs(model.regions) do
        if region.effectiveUV >= searingUV then
            levelsByRegion[regionName] = 3
        elseif region.effectiveUV >= burningUV then
            levelsByRegion[regionName] = 2
        elseif region.effectiveUV >= Constants.MIN_EFFECTIVE_LOCAL_UV then
            levelsByRegion[regionName] = 1
        end
    end
    feedback = {
        patient = patient,
        levelsByPart = BodyRegions.maximumByPart(levelsByRegion),
        nextRefreshMs = now + SAMPLE_INTERVAL_MS,
    }
    panel.vargursSunFeedback = feedback
    return feedback
end

local originalGetDamagedParts = ISHealthPanel.getDamagedParts
function ISHealthPanel:getDamagedParts()
    local bodyParts = originalGetDamagedParts(self)
    local feedback = getFeedback(self)
    if not feedback then
        return bodyParts
    end

    local included = {}
    for _, bodyPart in ipairs(bodyParts) do
        included[BodyPartType.ToIndex(bodyPart:getType())] = true
    end
    local bodyDamage = self:getPatient():getBodyDamage()
    local addedParts = false
    for partIndex = 0, BodyPartType.ToIndex(BodyPartType.MAX) - 1 do
        if feedback.levelsByPart[partIndex] and not included[partIndex] then
            bodyParts[#bodyParts + 1] = bodyDamage:getBodyPart(BodyPartType.FromIndex(partIndex))
            addedParts = true
        end
    end
    if addedParts then
        table.sort(bodyParts, function(left, right)
            return BodyPartType.ToIndex(left:getType()) < BodyPartType.ToIndex(right:getType())
        end)
    end
    return bodyParts
end

local originalDoDrawItem = ISHealthBodyPartListBox.doDrawItem
function ISHealthBodyPartListBox:doDrawItem(y, item, alt)
    local vanillaRowBottom = originalDoDrawItem(self, y, item, alt)
    local panel = self.parent
    ---@cast panel ISHealthPanel?
    local feedback = panel and panel.vargursSunFeedback
    local partIndex = BodyPartType.ToIndex(item.item.bodyPart:getType())
    local level = feedback and feedback.levelsByPart[partIndex]
    if not level then
        return vanillaRowBottom
    end

    local sensationKey = sensationKeys[level]
    if not sensationKey then
        return vanillaRowBottom
    end

    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local text = "- " .. getText(sensationKey, {} --[[@as kahlua.Array<any>]])
    local drawHealthText = self.drawText --[[@as any]]
    drawHealthText(self, text, 15, vanillaRowBottom - ROW_PADDING, 0.89, 0.28, 0.28, 1, UIFont.Small)
    return vanillaRowBottom + fontHeight
end
