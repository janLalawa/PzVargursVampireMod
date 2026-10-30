require("ISUI/ISWorldObjectContextMenu")
require("TimedActions/ISTimedActionQueue")

local Config = require("VargursVampires/Infrastructure/Config")
local State = require("VargursVampires/PlayerState/State")
local ExtractionPolicy = require("VargursVampires/Mechanics/BloodExtraction/ExtractionPolicy")
local ExtractionAction = require("VargursVampires/Mechanics/BloodExtraction/ExtractionAction")
---@type fun(key: string, ...: any): string
local text = getText

local function disable(option, reason)
    option.notAvailable = true
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip.description = text("UI_VargursVampires_BloodExtraction_Reason_" .. reason)
    option.toolTip = tooltip
end

local function onExtract(player, corpse, container, tool)
    if ExtractionPolicy.canExtract(player, corpse, container, tool) and luautils.walkAdj(player, corpse:getSquare()) then
        ISTimedActionQueue.add(ExtractionAction:new(player, corpse, container, tool))
    end
end

local function hasFluidContainer(item)
    return item:getFluidContainer() ~= nil
end

local function onFillWorldObjectContextMenu(playerIndex, context, worldobjects, test)
    local player = getSpecificPlayer(playerIndex)
    local fetch = ISWorldObjectContextMenu.fetchVars
    local corpse = fetch and fetch.body
    if
        not Config.get().enabled
        or not player
        or player:isDead()
        or not State.isVampire(player)
        or not corpse
        or not instanceof(corpse, "IsoDeadBody")
        or not corpse:isZombie()
    then
        return
    end
    if test then
        return ISWorldObjectContextMenu.setTest()
    end

    local option = context:addOption(text("UI_VargursVampires_BloodExtraction_Extract"), nil)
    ISWorldObjectContextMenu.initWorldItemHighlightOption(option, corpse)
    local reason = ExtractionPolicy.corpseReason(corpse)
    if reason then
        disable(option, reason)
        return
    end
    local inventory = player:getInventory()
    local tools = inventory:getAllEvalRecurse(ExtractionPolicy.isTool)
    if tools:isEmpty() then
        disable(option, "Tool")
        return
    end
    local tool = tools:get(0)
    local containers = inventory:getAllEvalRecurse(hasFluidContainer)
    if containers:isEmpty() then
        disable(option, "Container")
        return
    end

    local subMenu = context:getNew(context)
    context:addSubMenu(option, subMenu)
    for index = 0, containers:size() - 1 do
        local container = containers:get(index)
        local entry = subMenu:addGetUpOption(container:getDisplayName(), player, onExtract, corpse, container, tool)
        local valid, failure = ExtractionPolicy.canExtract(player, corpse, container, tool)
        if not valid then
            disable(entry, failure)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
