local VampireTrait = {}
local TRAIT_ID = "vargursvampires:vampire"

local function getTrait()
    return CharacterTrait.get(ResourceLocation.of(TRAIT_ID))
end

function VampireTrait.has(player)
    return player ~= nil and player:hasTrait(getTrait())
end

function VampireTrait.set(player, enabled)
    if not player or VampireTrait.has(player) == enabled then
        return false
    end

    local traits = player:getCharacterTraits()
    if enabled then
        traits:add(getTrait())
    else
        traits:remove(getTrait())
    end
    if isServer() then
        sendSyncPlayerFields(player, 2)
    end
    return true
end

return VampireTrait
