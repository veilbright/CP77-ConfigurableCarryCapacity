local PlayerPuppetObserver = {}


-- LOCAL FUNCTIONS --

local function observe_after_CalculateEncumbrance()
    InventoryManager:adjust_calculate_encumbrance()
end


-- OBSERVER FUNCTIONS --

function PlayerPuppetObserver:initialize()
    -- Call adjust_calculate_encumberance when EquipmentSystemPlayerData is attached
    ObserveAfter("PlayerPuppet", "CalculateEncumbrance", observe_after_CalculateEncumbrance)
end

return PlayerPuppetObserver