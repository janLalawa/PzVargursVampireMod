---@class SunRegionalPain
---@field severity integer
---@field targetPain number

---@class SunPainRecoveryRegion
---@field pain number
---@field recoveryStartPain? number
---@field recoveryTargetPain? number
---@field recoveryDurationMinutes? number
---@field recoveryElapsedMinutes? number

---@class SunPainRecoveryResult
---@field painByRegion table<string, SunRegionalPain>
---@field stateByRegion table<string, SunPainRecoveryRegion>

---@class VargursSunPainPolicy
---@field severity fun(exposure: number): integer
---@field calculate fun(exposure: SunExposureResult): table<string, SunRegionalPain>
---@field recover fun(targetsByRegion: table<string, SunRegionalPain>, previousByRegion: table<string, SunPainRecoveryRegion>, sunStress: number, elapsedMinutes: number): SunPainRecoveryResult
local SunPain = {}
---@type table<integer, number>
local PAIN_BY_SEVERITY = { 15.0, 35.0, 60.0, 85.0 }
local PAIN_UV_THRESHOLD = 0.25
local SEVERE_PAIN_UV_THRESHOLD = 0.6
local AGONY_UV_THRESHOLD = 1.0
local MIN_RECOVERY_MINUTES = 15.0
local EXTRA_RECOVERY_MINUTES_AT_FULL_STRESS = 45.0

local function severityForPain(pain)
    if pain <= 0.0 then
        return 0
    end
    for severity, threshold in ipairs(PAIN_BY_SEVERITY) do
        if pain <= threshold then
            return severity
        end
    end
    return #PAIN_BY_SEVERITY
end

local function recoveryDuration(sunStress)
    local stress = math.max(0.0, math.min(1.0, sunStress))
    return MIN_RECOVERY_MINUTES + EXTRA_RECOVERY_MINUTES_AT_FULL_STRESS * stress
end

local function recoverRegion(previous, targetPain, sunStress, elapsedMinutes)
    local currentPain = previous.pain or 0.0
    if targetPain >= currentPain then
        return { pain = targetPain }
    end

    local startPain = previous.recoveryStartPain or currentPain
    local duration = previous.recoveryDurationMinutes
    local elapsed = previous.recoveryElapsedMinutes or 0.0
    if previous.recoveryTargetPain ~= targetPain or not duration then
        startPain = currentPain
        duration = recoveryDuration(sunStress)
        elapsed = 0.0
    end

    elapsed = math.min(duration, elapsed + math.max(0.0, elapsedMinutes))
    local pain = startPain + (targetPain - startPain) * elapsed / duration
    if elapsed >= duration then
        return { pain = targetPain }
    end
    return {
        pain = math.max(targetPain, pain),
        recoveryStartPain = startPain,
        recoveryTargetPain = targetPain,
        recoveryDurationMinutes = duration,
        recoveryElapsedMinutes = elapsed,
    }
end

---@return SunPainRecoveryResult
function SunPain.recover(targetsByRegion, previousByRegion, sunStress, elapsedMinutes)
    local regionNames = {}
    for regionName in pairs(targetsByRegion) do
        regionNames[regionName] = true
    end
    for regionName in pairs(previousByRegion) do
        regionNames[regionName] = true
    end

    local painByRegion, stateByRegion = {}, {}
    for regionName in pairs(regionNames) do
        local target = targetsByRegion[regionName]
        local targetPain = target and target.targetPain or 0.0
        local previous = previousByRegion[regionName] or {}
        local recovery = recoverRegion(previous, targetPain, sunStress, elapsedMinutes)
        painByRegion[regionName] = {
            severity = severityForPain(recovery.pain),
            targetPain = recovery.pain,
        }
        if recovery.pain > 0.0 then
            stateByRegion[regionName] = recovery
        end
    end
    return { painByRegion = painByRegion, stateByRegion = stateByRegion }
end

function SunPain.severity(exposure)
    if exposure <= 0.0 then
        return 0
    end
    if exposure < PAIN_UV_THRESHOLD then
        return 1
    end
    if exposure < SEVERE_PAIN_UV_THRESHOLD then
        return 2
    end
    if exposure < AGONY_UV_THRESHOLD then
        return 3
    end
    return 4
end

---@param exposure SunExposureResult
---@return table<string, SunRegionalPain>
function SunPain.calculate(exposure)
    local painByRegion = {}
    for regionName, region in pairs(exposure.regions) do
        local severity = SunPain.severity(region.effectiveUV)
        painByRegion[regionName] = {
            severity = severity,
            targetPain = PAIN_BY_SEVERITY[severity] or 0.0,
        }
    end
    return painByRegion
end

return SunPain
