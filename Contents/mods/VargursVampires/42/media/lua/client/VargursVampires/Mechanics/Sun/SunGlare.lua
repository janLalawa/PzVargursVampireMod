local MIN_WASH_ALPHA = 0.025
local MAX_WASH_ALPHA = 0.45
local MAX_EDGE_ALPHA = 0.75
local EDGE_WIDTH_FRACTION = 0.20
local EDGE_STEPS = 32
local FADE_IN_SECONDS = 0.5
local FADE_OUT_SECONDS = 1
local SUNGLASSES_WASH_MULTIPLIER = 0.01
local SUNGLASSES_TYPES = {
    Glasses_Aviators = true,
    Glasses_Prescription_Aviators = true,
    Glasses_Shooting = true,
    Glasses_Prescription_Shooting = true,
    Glasses_SkiGoggles = true,
    Glasses_Sun = true,
    Glasses_Prescription_Sun = true,
    Glasses_CatsEye_Sun = true,
    Glasses_Prescription_CatsEye_Sun = true,
    Glasses_JackieO = true,
    Glasses_Prescription_JackieO = true,
    Glasses_Macho = true,
    Glasses_Round_Shades = true,
    Glasses_Prescription_Round_Shades = true,
    Glasses_SunCheap = true,
    Glasses_NewWave = true,
    Glasses_OldWeldingGoggles = true,
}
local visualsByPlayerIndex = {}

local SunGlare = {}

function SunGlare.washMultiplier(player)
    local eyewear = player and player:getWornItem(ItemBodyLocation.EYES)
    if eyewear and SUNGLASSES_TYPES[eyewear:getType()] then
        return SUNGLASSES_WASH_MULTIPLIER
    end
    return 1.0
end

local function washAlphaForIntensity(intensity)
    if intensity <= 0.0 then
        return 0.0
    end
    return MIN_WASH_ALPHA + (MAX_WASH_ALPHA - MIN_WASH_ALPHA) * intensity
end

function SunGlare.update(playerIndex, intensity, elapsedSeconds, washMultiplier)
    local visual = visualsByPlayerIndex[playerIndex]
    if not visual then
        visual = { washAlpha = 0.0, edgeAlpha = 0.0 }
        visualsByPlayerIndex[playerIndex] = visual
    end

    local targetWashAlpha = washAlphaForIntensity(intensity) * (washMultiplier or 1.0)
    local targetEdgeAlpha = MAX_EDGE_ALPHA * intensity
    local fadeSeconds = targetWashAlpha > visual.washAlpha and FADE_IN_SECONDS or FADE_OUT_SECONDS
    local blend = 1.0 - math.exp(-elapsedSeconds / fadeSeconds)
    local edgeFadeSeconds = targetEdgeAlpha > visual.edgeAlpha and FADE_IN_SECONDS or FADE_OUT_SECONDS
    local edgeBlend = 1.0 - math.exp(-elapsedSeconds / edgeFadeSeconds)

    visual.washAlpha = visual.washAlpha + (targetWashAlpha - visual.washAlpha) * blend
    visual.edgeAlpha = visual.edgeAlpha + (targetEdgeAlpha - visual.edgeAlpha) * edgeBlend

    if targetWashAlpha == 0.0 and visual.washAlpha < 0.001 then
        visual.washAlpha = 0.0
    end
    if targetEdgeAlpha == 0.0 and visual.edgeAlpha < 0.001 then
        visual.edgeAlpha = 0.0
    end
end

function SunGlare.clear(playerIndex)
    visualsByPlayerIndex[playerIndex] = nil
end

function SunGlare.clearAll()
    visualsByPlayerIndex = {}
end

local function drawWhiteRectangle(x, y, width, height, alpha)
    SpriteRenderer.instance:renderi(nil --[[@as Texture]], x, y, width, height, 1.0, 1.0, 1.0, alpha, nil --[[@as Consumer<TextureDraw>]])
end

local function drawBorderBand(x, y, width, height, inset, thickness, alpha)
    local innerInset = inset + thickness
    local horizontalWidth = width - 2 * inset
    local verticalHeight = height - 2 * innerInset

    drawWhiteRectangle(x + inset, y + inset, horizontalWidth, thickness, alpha)
    drawWhiteRectangle(x + inset, y + height - innerInset, horizontalWidth, thickness, alpha)
    drawWhiteRectangle(x + inset, y + innerInset, thickness, verticalHeight, alpha)
    drawWhiteRectangle(x + width - innerInset, y + innerInset, thickness, verticalHeight, alpha)
end

local function drawEdgeGlare(x, y, width, height, edgeAlpha)
    local edgeWidth = math.floor(math.min(width, height) * EDGE_WIDTH_FRACTION)
    for step = 1, EDGE_STEPS do
        local inset = math.floor((step - 1) * edgeWidth / EDGE_STEPS)
        local nextInset = math.floor(step * edgeWidth / EDGE_STEPS)
        local thickness = nextInset - inset
        if thickness > 0 then
            local distanceFromEdge = (step - 0.5) / EDGE_STEPS
            local alpha = edgeAlpha * (1.0 - distanceFromEdge) ^ 2
            drawBorderBand(x, y, width, height, inset, thickness, alpha)
        end
    end
end

function SunGlare.draw(playerIndex)
    local visual = visualsByPlayerIndex[playerIndex]
    if not visual or (visual.washAlpha <= 0.0 and visual.edgeAlpha <= 0.0) then
        return
    end

    local x = IsoCamera.getScreenLeft(playerIndex)
    local y = IsoCamera.getScreenTop(playerIndex)
    local width = IsoCamera.getScreenWidth(playerIndex)
    local height = IsoCamera.getScreenHeight(playerIndex)
    if width <= 0 or height <= 0 then
        return
    end

    drawWhiteRectangle(x, y, width, height, visual.washAlpha)
    drawEdgeGlare(x, y, width, height, visual.edgeAlpha)
end

return SunGlare
