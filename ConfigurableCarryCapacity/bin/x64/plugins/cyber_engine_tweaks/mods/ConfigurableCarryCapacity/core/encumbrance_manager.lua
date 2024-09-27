EncumbranceManager = {}

local logtag = "EncumbranceManager"


-- LOCAL FUNCTIONS --

---@param item_data gameItemData
-- Adds weight of quest items or items currently equipped to the player's inventory weight
local function balance_weight(item_data)
    local player = Game.GetPlayer()

    if player.ignoreQuestWeight and item_data:HasTag("Quest") then
        player:UpdateInventoryWeight(gameRPGManager.GetItemWeight(item_data))
        return
    end

    if player.noEquipWeight and gameRPGManager.IsItemEquipped(player, item_data:GetID()) then
        player:UpdateInventoryWeight(gameRPGManager.GetItemWeight(item_data))
    end
end

-- ENCUMBRANCEMANAGER FUNCTIONS --

---@param settings table
-- Updates settings variables and resets anything needed
function EncumbranceManager:apply_settings(settings)
    local should_reset_weight = false
    local player = Game.GetPlayer()

    player.carryShardBoost = settings.carryShardBoost

    -- no_equip_weight
    if (player.noEquipWeight ~= settings.noEquipWeight) then
        player.noEquipWeight = settings.noEquipWeight

        should_reset_weight = true
    end

    -- ignore_quest_weight
    if (player.ignoreQuestWeight ~= settings.ignoreQuestWeight) then
        player.ignoreQuestWeight = settings.ignoreQuestWeight

        should_reset_weight = true
    end

    if should_reset_weight then
        player:CalculateEncumbrance()
    end
end

---@param settings table
---@param player PlayerPuppet
-- Updates settings variables and resets anything needed
function EncumbranceManager:apply_player_settings(settings, player)
    local should_reset_weight = false

    player.carryShardBoost = settings.carryShardBoost

    -- no_equip_weight
    if (player.noEquipWeight ~= settings.noEquipWeight) then
        player.noEquipWeight = settings.noEquipWeight

        should_reset_weight = true
    end

    -- ignore_quest_weight
    if (player.ignoreQuestWeight ~= settings.ignoreQuestWeight) then
        player.ignoreQuestWeight = settings.ignoreQuestWeight

        should_reset_weight = true
    end

    if should_reset_weight then
        player:CalculateEncumbrance()
    end
end


-- OBSERVER FUNCTIONS --

---@param inventory_data_manager_v2 InventoryDataManagerV2
---@param itemID ItemID
---@param slot number
-- When an item is equipped, remove weight from inventory based on equipped weapon and add weight based on an unequipped weapon
function EncumbranceManager:before_equip_item(inventory_data_manager_v2, itemID, slot)
    -- Get game systems
    local equipmentSystem = Game.GetScriptableSystemsContainer():Get("EquipmentSystem")
    local player = Game.GetPlayer()
    
    if (not player.noEquipWeight) then   -- if noEquipWeight is disabled in settings, don't do the rest of this function
        return
    end
    
    if not gameItemID.IsValid(itemID) then                  -- error check from CDPR code
        LogDebug(logtag, itemID.." is not a valid itemID")
        return
    end

    -- Get weight of item being equipped
    local equippedItemData = inventory_data_manager_v2:GetPlayerItemData(itemID)    -- get item data of item equipped
    local equippedItemWeight = 0

    if not player.ignoreQuestWeight or not equippedItemData:HasTag("Quest") then         -- if ignore_quest_weight and a quest item, the item's weight is 0
        equippedItemWeight = gameRPGManager.GetItemWeight(equippedItemData)         -- get weight of item equipped
    end 

    -- Get weight of item about to be unequipped
    local equipArea = equipmentSystem.GetEquipAreaType(itemID)                                  -- get area where item is equipped
    local unequippedItemID = inventory_data_manager_v2:GetEquippedItemIdInArea(equipArea, slot) -- get item about to be unequipped
    local unequippedItemData = inventory_data_manager_v2:GetPlayerItemData(unequippedItemID)    -- get item data of item about to be unequipped
    local unequippedItemWeight = 0

    if unequippedItemData ~= nil then                                                   -- don't check the tag if the item doesn't exist
        if not player.ignoreQuestWeight or not unequippedItemData:HasTag("Quest") then  -- if ignore_quest_weight and a quest item, the item's weight is 0
            unequippedItemWeight = gameRPGManager.GetItemWeight(unequippedItemData)     -- get weight of item unequipped
        end 
    end

    local weightChange = unequippedItemWeight - equippedItemWeight          -- add weight of item about to be unequipped and subtract weight of item being equipped

    if weightChange == 0.00 then                -- this check is done in CDPR code
        return;
    end

    player:UpdateInventoryWeight(weightChange) -- add weightChange to inventoryWeight
end

---@param inventory_data_manager_v2 InventoryDataManagerV2
---@param equip_area gamedataEquipmentArea
---@param slot number
-- When an item is unequipped, add item's weight to inventory
function EncumbranceManager:before_unequip_item(inventory_data_manager_v2, equip_area, slot)
    local player = Game.GetPlayer()
    
    if not player.noEquipWeight then           -- if noEquipWeight is disabled in settings, don't do the rest of this function
        return
    end

    if equip_area == gamedataEquipmentArea.Invalid then      -- error check from CDPR code
        LogDebug(logtag, equip_area.." is not a valid EquipmentArea")
        return
    end

    -- get data of item about to be unequipped
    local unequippedItemID = inventory_data_manager_v2:GetEquippedItemIdInArea(equip_area, slot)    -- get item about to be unequipped
    local unequippedItemData = inventory_data_manager_v2:GetPlayerItemData(unequippedItemID)        -- get item data of item about to be unequipped

    -- quest items won't add any weight
    if player.ignoreQuestWeight and unequippedItemData:HasTag("Quest") then
        return
    end

    local unequippedItemWeight = gameRPGManager.GetItemWeight(unequippedItemData)   -- get weight of item about to be unequipped

    if unequippedItemWeight == 0.00 then    -- this check is done in CDPR code
        return;
    end

    player:UpdateInventoryWeight(unequippedItemWeight)      -- add weightChange to inventoryWeight
end

---@param item_data gameItemData
-- Adds weight before an equipped item is transferred
function EncumbranceManager:before_transfer_item(item_data)
    balance_weight(item_data)
end

---@param item_data gameItemData
-- Adds weight before an equipped item is sold
function EncumbranceManager:before_sell_item(item_data)
    balance_weight(item_data)
end

return EncumbranceManager