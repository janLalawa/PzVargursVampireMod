require("XpSystem/ISUI/ISHealthPanel")

local Config = require("VargursVampireMod/Infrastructure/Config")
local State = require("VargursVampireMod/PlayerState/State")
local SunPainAdapter = require("VargursVampireMod/PlayerState/SunPainAdapter")
local VISIBLE_PAIN_THRESHOLD = 10.0
local SEVERE_PAIN_THRESHOLD = 50.0
local PAIN_SEVERITY = 2
local SEVERE_PAIN_SEVERITY = 3
local ROW_PADDING = 5
local TEXT_INDENT = 15

local originalGetDamagedParts = ISHealthPanel.getDamagedParts
local originalDrawItem = ISHealthBodyPartListBox.doDrawItem
local translate = getText --[[@as fun(key: string): string]]

local function sunlightPainByPart(panel)
    local config = Config.get()
    local player = panel.otherPlayer or panel.character
    if not config.enabled or not config.sunDamageEnabled or not player or player:isDead() then
        return {}
    end
    if not State.isVampire(player) then
        return {}
    end

    return SunPainAdapter.presentation(player)
end

local function painLabel(pain)
    local severity = pain.severity
    local otherPain = pain.otherPain
    if otherPain > SEVERE_PAIN_THRESHOLD then
        severity = math.max(severity, SEVERE_PAIN_SEVERITY)
    end
    if otherPain > VISIBLE_PAIN_THRESHOLD then
        severity = math.max(severity, PAIN_SEVERITY)
    end
    return "- " .. translate("Moodles_Pain_lvl" .. severity)
end

function ISHealthPanel:getDamagedParts()
    local damagedParts = originalGetDamagedParts(self)
    local painByPart = sunlightPainByPart(self)
    self.vargursSunPainByPart = painByPart

    local includedParts = {}
    for _, bodyPart in ipairs(damagedParts) do
        includedParts[bodyPart:getIndex()] = true
    end

    local player = self.otherPlayer or self.character
    for partIndex, pain in pairs(painByPart) do
        if pain.severity > 0 and not includedParts[partIndex] then
            local bodyPart = player:getBodyDamage():getBodyPart(BodyPartType.FromIndex(partIndex))
            damagedParts[#damagedParts + 1] = bodyPart
        end
    end
    table.sort(damagedParts, function(first, second)
        return first:getIndex() < second:getIndex()
    end)
    return damagedParts
end

function ISHealthBodyPartListBox:doDrawItem(y, item, alt)
    ---@type table
    local listBox = self
    local panel = listBox.parent
    if not panel then
        return originalDrawItem(self, y, item, alt)
    end
    local bodyPart = item.item.bodyPart
    local partIndex = bodyPart:getIndex()
    local painByPart = panel.vargursSunPainByPart or {}
    local pain = painByPart[partIndex]
    if not pain or pain.severity == 0 then
        return originalDrawItem(self, y, item, alt)
    end

    local label = painLabel(pain)
    local originalDrawText = listBox.drawText
    local drewPainLabel = false
    local vanillaPain = "- " .. translate("IGUI_health_Pain")
    local vanillaSeverePain = "- " .. translate("IGUI_health_HeavyPain")
    listBox.drawText = function(target, text, ...)
        if text == vanillaPain or text == vanillaSeverePain then
            text = label
            drewPainLabel = true
        end
        return originalDrawText(target, text, ...)
    end

    local succeeded, bottom = pcall(originalDrawItem, self, y, item, alt)
    listBox.drawText = originalDrawText
    if not succeeded then
        error(bottom)
    end
    if not drewPainLabel then
        originalDrawText(self, label, TEXT_INDENT, bottom - ROW_PADDING, 0.89, 0.28, 0.28, 1, UIFont.Small)
        bottom = bottom + getTextManager():getFontHeight(UIFont.Small)
    end
    return bottom
end
