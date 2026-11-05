require("NPCs/BodyLocations")

local Config = require("VargursVampires/Infrastructure/Config")
local State = require("VargursVampires/PlayerState/State")

local CorpseSicknessResistance = {}
local ITEM_TYPE = "Base.VargursVampiresCorpseResistance"
local BODY_LOCATION = ItemBodyLocation.get(ResourceLocation.of("vargursvampires:corpseresistance"))

BodyLocations.getGroup("Human"):getOrCreateLocation(BODY_LOCATION)

local function isResistanceItem(item)
    return item ~= nil and item:getFullType() == ITEM_TYPE
end

local function syncAddedItem(inventory, item)
    if isServer() then
        sendAddItemToContainer(inventory, item)
    end
end

local function removeItem(inventory, item)
    if isServer() then
        sendRemoveItemFromContainer(inventory, item)
    end
    inventory:Remove(item)
end

function CorpseSicknessResistance.updatePlayer(player)
    if not player or isClient() then
        return
    end

    local inventory = player:getInventory()
    local wornItem = player:getWornItem(BODY_LOCATION)
    if wornItem and not isResistanceItem(wornItem) then
        return
    end

    local shouldApply = Config.get().enabled and not player:isDead() and State.isVampire(player)
    if not shouldApply and wornItem then
        player:setWornItem(BODY_LOCATION, nil, false)
    end

    local retainedItem = shouldApply and wornItem or nil
    local retainedInInventory = false
    local items = inventory:getItems()
    for itemIndex = items:size() - 1, 0, -1 do
        local item = items:get(itemIndex)
        if isResistanceItem(item) then
            if shouldApply and not retainedItem then
                retainedItem = item
            end
            if item == retainedItem then
                retainedInInventory = true
            else
                removeItem(inventory, item)
            end
        end
    end

    if not shouldApply then
        return
    end

    if not retainedItem then
        retainedItem = inventory:AddItem(ITEM_TYPE)
        if not retainedItem then
            return
        end
        syncAddedItem(inventory, retainedItem)
    elseif not retainedInInventory then
        inventory:AddItem(retainedItem)
        syncAddedItem(inventory, retainedItem)
    end

    if not retainedItem:getVisual() then
        return
    end
    if retainedItem:getCondition() <= 0 then
        retainedItem:setCondition(retainedItem:getConditionMax())
    end
    if wornItem ~= retainedItem then
        player:setWornItem(BODY_LOCATION, retainedItem, false)
    end
end

return CorpseSicknessResistance
