require("TimedActions/ISBaseTimedAction")

local ExtractionPolicy = require("VargursVampires/Mechanics/BloodExtraction/ExtractionPolicy")
---@type fun(key: string, ...: any): string
local text = getText

---@class VargursVampiresExtractionAction: ISBaseTimedAction
---@class VargursVampiresExtractionAction: ISBaseTimedAction
---@field corpse IsoDeadBody
---@field container InventoryItem?
---@field tool InventoryItem?
---@field started boolean?
---@field pourStarted boolean
---@field sound integer?
VargursVampiresExtractionAction = ISBaseTimedAction:derive("VargursVampiresExtractionAction")
VargursVampiresExtractionAction = ISBaseTimedAction:derive("VargursVampiresExtractionAction")

---@return boolean
function VargursVampiresExtractionAction:isValidStart()
    return self:isValid()
end

---@return boolean
function VargursVampiresExtractionAction:isValid()
    local valid = ExtractionPolicy.canExtract(self.character, self.corpse, self.container, self.tool, true)
    return valid
end

function VargursVampiresExtractionAction:waitToStart()
    self.character:faceThisObject(self.corpse)
    return self.character:shouldBeTurning()
end

function VargursVampiresExtractionAction:start()
    if not self.container or not self.tool then
        return
    end

    local inventory = self.character:getInventory()
    self.container = inventory:getItemById(self.container:getID())
    self.tool = inventory:getItemById(self.tool:getID())
    if not self.container or not self.tool then
        return
    end

    self.started = true
    self.container:setJobType(text("UI_VargursVampires_BloodExtraction_Job"))
    self.container:setJobDelta(0.0)
    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "Low")
    self.character:reportEvent("EventLootItem")
end

function VargursVampiresExtractionAction:update()
    self.character:faceThisObject(self.corpse)
    if self.container then
        self.container:setJobDelta(self:getJobDelta())
    end

    if not self.pourStarted and self:getJobDelta() >= 0.7 then
        self.pourStarted = true
        self.sound = self.character:playSound("PourWaterIntoObject")
    end
end

function VargursVampiresExtractionAction:cleanup()
    if self.sound then
        self.character:stopOrTriggerSound(self.sound)
        self.sound = nil
    end

    if self.container then
        self.container:setJobDelta(0.0)
        self.container:setJobType("")
    end

    if self.started then
        self.character:clearVariable("LootPosition")
        self.started = false
    end
end

function VargursVampiresExtractionAction:stop()
    self:cleanup()
    ISBaseTimedAction.stop(self)
end

function VargursVampiresExtractionAction:serverStop()
    self:cleanup()
end

function VargursVampiresExtractionAction:perform()
    self:cleanup()
    ISBaseTimedAction.perform(self)
end

function VargursVampiresExtractionAction:complete()
    local result = ExtractionPolicy.extract(self.character, self.corpse, self.container, self.tool)
    self:cleanup()
    return result
end

function VargursVampiresExtractionAction:getDuration()
    return self.character:isTimedActionInstant() and 1 or ExtractionPolicy.duration
end

---@param character IsoPlayer
---@param corpse IsoDeadBody
---@param container InventoryItem
---@param tool InventoryItem
---@return VargursVampiresExtractionAction
---@return VargursVampiresExtractionAction
function VargursVampiresExtractionAction:new(character, corpse, container, tool)
    local action = ISBaseTimedAction.new(self, character)
    ---@cast action VargursVampiresExtractionAction
    ---@cast action VargursVampiresExtractionAction
    action.corpse = corpse
    action.container = container
    action.tool = tool
    action.stopOnWalk = true
    action.stopOnRun = true
    action.stopOnAim = true
    action.pourStarted = false
    action.maxTime = action:getDuration()
    return action
end

return VargursVampiresExtractionAction
