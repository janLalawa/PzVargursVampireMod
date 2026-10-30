local Constants = require("VargursVampires/Infrastructure/Constants")
local Health = require("VargursVampires/PlayerState/Health")
local SunPainAdapter = require("VargursVampires/PlayerState/SunPainAdapter")
local SunBurns = require("VargursVampires/Mechanics/Sun/Burns/SunBurns")
local HealthRegeneration = require("VargursVampires/Mechanics/PlayerBuffs/HealthRegeneration")
local CorpseSicknessResistance = require("VargursVampires/Mechanics/PlayerBuffs/CorpseSicknessResistance")

local Uninstall = {}

local LOG_PREFIX = "[VargursVampires] Uninstall"
local TRAIT_IDS = { "vargursvampires:vampire", "vargursvampires:sunresistant" }
local ITEM_TYPES = {
    ["Base.VargursHumanBloodBottle"] = true,
    ["Base.VargursBloodSpice"] = true,
    ["Base.VargursVampiresCorpseResistance"] = true,
}
local FLUID_TYPES = { "VargursHumanBlood", "VargursZombieBlood", "VargursBoiledZombieBlood" }
local MOD_DATA_KEYS = { Constants.STATE_KEY, HealthRegeneration.baselineKey, SunPainAdapter.contributionsKey }

local announced = false

local function isModItem(item)
    return ITEM_TYPES[item:getFullType()] == true
end

local function hasFluidContainer(item)
    return item:getFluidContainer() ~= nil
end

local function countModItems(player)
    return player:getInventory():getAllEvalRecurse(isModItem):size()
end

local function restorePlayerAdjustments(player, changes)
    if player:getModData()[HealthRegeneration.baselineKey] ~= nil then
        HealthRegeneration.updatePlayer(player)
        changes[#changes + 1] = "restored native health regeneration rates"
    end

    SunBurns.clear(player)
    if player:getModData()[SunPainAdapter.contributionsKey] ~= nil and SunPainAdapter.apply(player, {}) then
        Health.queueSync(player)
        changes[#changes + 1] = "removed sunlight pain"
    end

    local itemsBefore = countModItems(player)
    CorpseSicknessResistance.updatePlayer(player)
    local removedCarriers = itemsBefore - countModItems(player)
    if removedCarriers > 0 then
        changes[#changes + 1] = "removed " .. removedCarriers .. " hidden corpse-resistance item(s)"
    end
end

local function removeTraits(player, changes)
    local removed = false
    for _, traitId in ipairs(TRAIT_IDS) do
        local trait = CharacterTrait.get(ResourceLocation.of(traitId))
        if trait and player:hasTrait(trait) then
            player:getCharacterTraits():remove(trait)
            removed = true
            changes[#changes + 1] = "removed trait " .. traitId
        end
    end
    if removed and isServer() then
        sendSyncPlayerFields(player, 2)
    end
end

local function removeItems(player, changes)
    local items = player:getInventory():getAllEvalRecurse(isModItem)
    local handsChanged = false
    for index = items:size() - 1, 0, -1 do
        local item = items:get(index)
        if player:isEquippedClothing(item) then
            player:removeWornItem(item, false)
        end
        if player:isHandItem(item) then
            player:removeFromHands(item)
            handsChanged = true
        end
        local container = item:getContainer()
        if container then
            if isServer() then
                sendRemoveItemFromContainer(container, item)
            end
            container:Remove(item)
            changes[#changes + 1] = "removed item " .. item:getFullType()
        end
    end
    if handsChanged and isServer() then
        sendEquip(player)
    end
end

local function removeFluids(player, changes)
    local items = player:getInventory():getAllEvalRecurse(hasFluidContainer)
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local fluids = item:getFluidContainer()
        local changed = false
        for _, fluidType in ipairs(FLUID_TYPES) do
            local fluid = Fluid.Get(fluidType)
            if fluid and fluids:contains(fluid) then
                local amount = fluids:getSpecificFluidAmount(fluid)
                fluids:adjustSpecificFluidAmount(fluid, 0.0)
                changed = true
                changes[#changes + 1] = string.format("removed %.2f L of %s from %s", amount, fluidType, item:getFullType())
            end
        end
        if changed then
            item:sendSyncEntity(nil)
        end
    end
end

local function removeModData(player, changes)
    local modData = player:getModData()
    for _, key in ipairs(MOD_DATA_KEYS) do
        if modData[key] ~= nil then
            modData[key] = nil
            changes[#changes + 1] = "removed saved data " .. key
        end
    end
end

---@param player IsoPlayer|nil
---@return string[]
function Uninstall.cleanPlayer(player)
    if not player then
        return {}
    end
    if not announced then
        announced = true
        print(LOG_PREFIX .. ": uninstall mode is active; mod gameplay is disabled and players will be cleaned as they load in.")
    end

    local changes = {}
    restorePlayerAdjustments(player, changes)
    removeTraits(player, changes)
    removeItems(player, changes)
    removeFluids(player, changes)
    removeModData(player, changes)
    Health.syncDamage(player)

    local name = player:getUsername()
    for _, change in ipairs(changes) do
        print(LOG_PREFIX .. " [" .. tostring(name) .. "]: " .. change)
    end
    if #changes > 0 then
        print(LOG_PREFIX .. " [" .. tostring(name) .. "]: " .. #changes .. " change(s); safe to save and remove the mod for this player.")
    end
    return changes
end

return Uninstall
