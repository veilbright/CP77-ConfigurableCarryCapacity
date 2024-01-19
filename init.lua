-- mod info
Mod = {
    ready = false
}

-- print on load
print('Test Mod loaded')

-- onInit
registerForEvent('onInit', function()
    Mod.ready = true

    print('Test Mod initialized')
end)

---@param self InventoryDataManagerV2
---@param itemID ItemID
---@param slot number
-- When an item is equipped, remove weight from inventory based on equipped weapon and add weight based on an unequipped weapon 
Observe('InventoryDataManagerV2', 'EquipItem', function(self, itemID, slot)

    if gameItemID.IsValid(itemID) then                                                      -- from CDPR code
        local equipmentSystem = Game.GetScriptableSystemsContainer():Get("EquipmentSystem") -- get EquipmentSystem
        local player = Game.GetPlayer()                                                     -- get Player

        local equippedItemData = self:GetPlayerItemData(itemID)                             -- get item data of item equipped
        local equippedItemWeight = gameRPGManager.GetItemWeight(equippedItemData)           -- get weight of item equipped

        local equipArea = equipmentSystem.GetEquipAreaType(itemID)                          -- get area where item is equipped
        local unequippedItemID = self:GetEquippedItemIdInArea(equipArea, slot)              -- get item about to be unequipped
        local unequippedItemData = self:GetPlayerItemData(unequippedItemID)                 -- get item data of item about to be unequipped
        local unequippedItemWeight = gameRPGManager.GetItemWeight(unequippedItemData)       -- get weight of item about to be unequipped

        local weightChange = unequippedItemWeight - equippedItemWeight                      -- add weight of item about to be unequipped and subtract weight of item being equipped

        if weightChange == 0.00 then                        -- this is done in CDPR code
            return;
        end

        player:UpdateInventoryWeight(weightChange)          -- add weightChange to inventoryWeight
    end
end)

---@param self InventoryDataManagerV2
---@param equipArea gamedataEquipmentArea
---@param slot number
-- When an item is unequipped, add item's weight to inventory
Observe('InventoryDataManagerV2', 'UnequipItem', function(self, equipArea, slot)

    if equipArea ~= gamedataEquipmentArea.Invalid then                                      -- from CDPR code
        local player = Game.GetPlayer()                                                     -- get Player

        local unequippedItemID = self:GetEquippedItemIdInArea(equipArea, slot)              -- get item about to be unequipped
        local unequippedItemData = self:GetPlayerItemData(unequippedItemID)                 -- get item data of item about to be unequipped
        local unequippedItemWeight = gameRPGManager.GetItemWeight(unequippedItemData)       -- get weight of item about to be unequipped

        if unequippedItemWeight == 0.00 then                        -- this is done in CDPR code
            return;
        end

        player:UpdateInventoryWeight(unequippedItemWeight)          -- add weightChange to inventoryWeight
    end
end)

return Mod