local Config = require("VargursVampires/Infrastructure/Config")
local ITEM_NAME = "VargursHumanBloodBottle"
local DEFAULT_LOOT_AMOUNT = 0.6
local BASE_CHANCES = {
    FridgeMedical = 0.5,
    HospitalRoomFridge = 0.5,
    HospitalRoomShelves = 0.2,
    MedicalCabinet = 0.1,
    MedicalClinicDrugs = 0.1,
    MedicalStorageDrugs = 0.1,
}

local function addRareBloodBottle(distributionName, chance)
    local distribution = ProceduralDistributions.list[distributionName]
    if not distribution or type(distribution.items) ~= "table" then
        return
    end

    for index = 1, #distribution.items, 2 do
        if distribution.items[index] == ITEM_NAME then
            if chance > 0.0 then
                distribution.items[index + 1] = chance
            else
                table.remove(distribution.items, index + 1)
                table.remove(distribution.items, index)
            end
            return
        end
    end

    if chance <= 0.0 then
        return
    end
    distribution.items[#distribution.items + 1] = ITEM_NAME
    distribution.items[#distribution.items + 1] = chance
end

local function applyLootAmount(multiplier)
    for distributionName, chance in pairs(BASE_CHANCES) do
        addRareBloodBottle(distributionName, chance * multiplier)
    end
end

Events.OnPreDistributionMerge.Add(function()
    applyLootAmount(1.0)
end)

Events.OnGameTimeLoaded.Add(function()
    local multiplier = Config.get().bloodLoot / DEFAULT_LOOT_AMOUNT
    if multiplier == 1.0 or isClient() then
        return
    end
    applyLootAmount(multiplier)
    IsoWorld.parseDistributions()
end)
