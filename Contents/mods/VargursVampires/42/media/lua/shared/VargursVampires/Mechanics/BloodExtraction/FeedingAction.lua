require("TimedActions/ISBaseTimedAction")

local ExtractionPolicy = require("VargursVampires/Mechanics/BloodExtraction/ExtractionPolicy")

---@class VargursVampiresFeedingAction: ISBaseTimedAction
---@field corpse IsoDeadBody
VargursVampiresFeedingAction = ISBaseTimedAction:derive("VargursVampiresFeedingAction")

---@return boolean
function VargursVampiresFeedingAction:isValidStart()
    return self:isValid()
end

---@return boolean
function VargursVampiresFeedingAction:isValid()
    local valid = ExtractionPolicy.canFeed(self.character, self.corpse, true)
    return valid
end

function VargursVampiresFeedingAction:waitToStart()
    self.character:faceThisObject(self.corpse)
    return self.character:shouldBeTurning()
end

function VargursVampiresFeedingAction:start()
    self:setActionAnim("VargursVampiresFeed")
    self:setOverrideHandModels(nil, nil)
    self.character:reportEvent("EventTakeWater")
end

function VargursVampiresFeedingAction:update()
    self.character:faceThisObject(self.corpse)
end

function VargursVampiresFeedingAction:complete()
    return ExtractionPolicy.feed(self.character, self.corpse)
end

function VargursVampiresFeedingAction:getDuration()
    return self.character:isTimedActionInstant() and 1 or ExtractionPolicy.duration
end

---@param character IsoPlayer
---@param corpse IsoDeadBody
---@return VargursVampiresFeedingAction
function VargursVampiresFeedingAction:new(character, corpse)
    local action = ISBaseTimedAction.new(self, character)
    ---@cast action VargursVampiresFeedingAction
    action.corpse = corpse
    action.stopOnWalk = true
    action.stopOnRun = true
    action.stopOnAim = true
    action.maxTime = action:getDuration()
    return action
end

return VargursVampiresFeedingAction