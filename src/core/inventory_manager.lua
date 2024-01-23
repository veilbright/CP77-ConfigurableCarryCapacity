InventoryManager = {}

local logtag = "inventory_manager"

local no_equip_weight = true


-- LOCAL FUNCTIONS --

---@param item_data gameItemData
-- Adds weight of items currently equipped to the player's inventory weight
local function add_weight_if_equipped(item_data)
    local player = Game.GetPlayer()

    if (gameRPGManager.IsItemEquipped(player, item_data:GetID())) then
        player:UpdateInventoryWeight(gameRPGManager.GetItemWeight(item_data))
    end
end

-- Sets inventory weight based on items in inventory
local function reset_weight()

    -- Get game systems
    local player = Game.GetPlayer()

    -- TODO: probably shouldn't be -9999999
    player:UpdateInventoryWeight(-9999999)              -- resets inventory weight to 0
    player:CalculateEncumbrance()                       -- adds weight of every item in inventory
end


-- INVENTORYMANAGER FUNCTIONS --

---@param settings table
-- Updates settings variables and resets anything needed
function InventoryManager:apply_settings(settings)
    if (no_equip_weight ~= settings.noEquipWeight) then     -- if no_equip_weight is changed
        no_equip_weight = settings.noEquipWeight
        reset_weight()                                      -- reset the inventory weight based on new value
    end
end


-- OBSERVER FUNCTIONS --

---@param inventory_data_manager_v2 InventoryDataManagerV2
---@param itemID ItemID
---@param slot number
-- When an item is equipped, remove weight from inventory based on equipped weapon and add weight based on an unequipped weapon
function InventoryManager:before_equip_item(inventory_data_manager_v2, itemID, slot)
    if (not no_equip_weight) then   -- if noEquipWeight is disabled in settings, don't do the rest of this function
        return
    end
    
    if not gameItemID.IsValid(itemID) then                  -- error check from CDPR code
        LogDebug(logtag, itemID.." is not a valid itemID")
        return
    end

    -- Get game systems
    local equipmentSystem = Game.GetScriptableSystemsContainer():Get("EquipmentSystem")
    local player = Game.GetPlayer()

    -- Get weight of item being equipped
    local equippedItemData = inventory_data_manager_v2:GetPlayerItemData(itemID)                -- get item data of item equipped
    local equippedItemWeight = gameRPGManager.GetItemWeight(equippedItemData)                   -- get weight of item equipped

    -- Get weight of item about to be unequipped
    local equipArea = equipmentSystem.GetEquipAreaType(itemID)                                  -- get area where item is equipped
    local unequippedItemID = inventory_data_manager_v2:GetEquippedItemIdInArea(equipArea, slot) -- get item about to be unequipped
    local unequippedItemData = inventory_data_manager_v2:GetPlayerItemData(unequippedItemID)    -- get item data of item about to be unequipped
    local unequippedItemWeight = gameRPGManager.GetItemWeight(unequippedItemData)               -- get weight of item about to be unequipped

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
function InventoryManager:before_unequip_item(inventory_data_manager_v2, equip_area, slot)
    if (not no_equip_weight) then           -- if noEquipWeight is disabled in settings, don't do the rest of this function
        return
    end

    if equip_area == gamedataEquipmentArea.Invalid then      -- error check from CDPR code
        LogDebug(logtag, equip_area.." is not a valid EquipmentArea")
        return
    end

    local player = Game.GetPlayer()

    -- Get weight of item about to be unequipped
    local unequippedItemID = inventory_data_manager_v2:GetEquippedItemIdInArea(equip_area, slot)    -- get item about to be unequipped
    local unequippedItemData = inventory_data_manager_v2:GetPlayerItemData(unequippedItemID)        -- get item data of item about to be unequipped
    local unequippedItemWeight = gameRPGManager.GetItemWeight(unequippedItemData)   -- get weight of item about to be unequipped

    if unequippedItemWeight == 0.00 then    -- this check is done in CDPR code
        return;
    end

    player:UpdateInventoryWeight(unequippedItemWeight)      -- add weightChange to inventoryWeight
end

---@param item_data gameItemData
-- Adds weight before an equipped item is transferred
function InventoryManager:before_transfer_item(item_data)
    if (no_equip_weight) then
        add_weight_if_equipped(item_data)
    end
end

---@param item_data gameItemData
-- Adds weight before an equipped item is sold
function InventoryManager:before_sell_item(item_data)
    if (no_equip_weight) then
        add_weight_if_equipped(item_data)
    end
end

function InventoryManager:adjust_calculate_encumbrance()
    if (no_equip_weight) then
        -- Get game systems (error checks are here because PlayerPuppet calls CalculateEncumbrance OnGameAttached, and InventoryDataManagerV2 is nil when that happens)
        local player = Game.GetPlayer()

        local equipment_system = Game.GetScriptableSystemsContainer():Get('EquipmentSystem')
        if equipment_system == nil then
            return
        end

        local equipment_system_player_data = equipment_system:GetPlayerData(player)
        if equipment_system_player_data == nil then
            return
        end

        local inventory_data_manager_v2 = equipment_system_player_data:GetInventoryManager()
        if inventory_data_manager_v2 == nil then
            return
        end

        local equipped_weight = 0
        
        for i, inventory_data in pairs(inventory_data_manager_v2:GetEquippedWeapons()) do                   -- iterate through equipped weapons
            equipped_weight = equipped_weight + gameRPGManager.GetItemWeight(inventory_data:GetGameItemData())    -- subtract their weight
        end
        for i, clothing_area in pairs(equipment_system.GetClothingEquipmentAreas()) do                      -- iterate through clothing equipment areas
            equipped_weight = equipped_weight + RPGManager.GetItemWeight(inventory_data_manager_v2:GetPlayerItemData(inventory_data_manager_v2:GetEquippedItemIdInArea(clothing_area, 0)))    -- subtract their weight
        end

        player:UpdateInventoryWeight(-equipped_weight)  -- subtract weight of equipped items
    end
end

return InventoryManager