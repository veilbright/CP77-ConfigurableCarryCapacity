local InventoryDataManagerV2Observer = {}


-- LOCAL FUNCTIONS --

---@param inventory_data_manager_v2 InventoryDataManagerV2
---@param itemID ItemID
---@param slot number
local function observe_before_EquipItem(inventory_data_manager_v2, itemID, slot)
    InventoryManager:before_equip_item(inventory_data_manager_v2, itemID, slot)
end

---@param inventory_data_manager_v2 InventoryDataManagerV2
---@param equip_area gamedataEquipmentArea
---@param slot number
local function observe_before_UnequipItem(inventory_data_manager_v2, equip_area, slot)
    InventoryManager:before_unequip_item(inventory_data_manager_v2, equip_area, slot)
end


-- OBSERVER FUNCTIONS --

function InventoryDataManagerV2Observer:initialize()
    -- Call before_equip_item when weapon or clothing is equipped
    ObserveBefore("InventoryDataManagerV2", "EquipItem", observe_before_EquipItem)

    -- Call before_unequip_item when weapon or clothing is unequipped
    ObserveBefore("InventoryDataManagerV2", "UnequipItem", observe_before_UnequipItem)
end

return InventoryDataManagerV2Observer