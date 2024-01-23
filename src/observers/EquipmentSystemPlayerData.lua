local EquipmentSystemPlayerDataObserver = {}


-- LOCAL FUNCTIONS --

local function observe_after_OnAttach()
    InventoryManager:adjust_calculate_encumbrance()
end


-- OBSERVER FUNCTIONS --

function EquipmentSystemPlayerDataObserver:initialize()
    -- Call adjust_calculate_encumberance when EquipmentSystemPlayerData is attached
    ObserveAfter("EquipmentSystemPlayerData", "OnAttach", observe_after_OnAttach)
end

return EquipmentSystemPlayerDataObserver