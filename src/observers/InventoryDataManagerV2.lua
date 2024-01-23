local InventoryDataManagerV2Observer = {}

local logtag = "inventory_data_manager_v2_observer"


-- LOCAL FUNCTIONS --

---@param inventory_data_manager_v2 InventoryDataManagerV2
---@param itemID ItemID
---@param slot number
local function observe_before_EquipItem(inventory_data_manager_v2, itemID, slot)
    InventoryManager:before_equip_item(inventory_data_manager_v2, itemID, slot)
end

local function observe_before_UnequipItem(inventory_data_manager_v2, equip_area, slot)
    InventoryManager:before_unequip_item(inventory_data_manager_v2, equip_area, slot)
end


-- OBSERVER FUNCTIONS --

function InventoryDataManagerV2Observer:initialize()
    -- Call before_equip_item when weapon or clothing is equipped
    ObserveBefore('InventoryDataManagerV2', 'EquipItem', observe_before_EquipItem)

    -- Call before_unequip_item when weapon or clothing is unequipped
    ObserveBefore('InventoryDataManagerV2', 'UnequipItem', observe_before_UnequipItem)
end

return InventoryDataManagerV2Observer