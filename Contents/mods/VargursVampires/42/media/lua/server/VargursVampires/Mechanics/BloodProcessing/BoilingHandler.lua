if isClient() then
    return
end

local Config = require("VargursVampires/Infrastructure/Config")
local BoilingPolicy = require("VargursVampires/Mechanics/BloodProcessing/BoilingPolicy")

local function onEveryTenMinutes()
    if not Config.get().enabled then
        return
    end

    local cell = getCell()
    if not cell then
        return
    end

    local items = cell:getProcessItems()
    for index = 0, items:size() - 1 do
        BoilingPolicy.convert(items:get(index))
    end
end

Events.EveryTenMinutes.Add(onEveryTenMinutes)
