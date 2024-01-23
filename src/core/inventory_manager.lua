InventoryManager = {}

local logtag = "inventory_manager"

local no_equip_weight = true


---@return number
local function calculate_weight()
    -- Items in empty inventory for some reason, can't figure out another way to determine what they are
    local empty_inventory_clothes = {
        0x80A501BB, -- Items.Mask_02_basic_01
        0x3AB907E7, -- Items.Q001_TShirt
        0xD11BBC3E, -- Items.Jacket_01_basic_02
        0xB545F5A5, -- Items.Jacket_15_old_01
        0xF566FA18  -- Items.Tech_01_rich_01
    }

    local player = Game.GetPlayer()
    local equipment_system = Game.GetScriptableSystemsContainer():Get('EquipmentSystem')

    local equipment_system_player_data = equipment_system:GetPlayerData(player)
    local inventory_data_manager_v2 = equipment_system_player_data:GetInventoryManager()

    -- DEBUG (there has to be a better way to do this)
    -- for i, item_data in pairs(inventory_data_manager_v2:GetPlayerItems()) do
    --     print(item_data:GetNameAsString(),": ",item_data:GetID().id.hash,": ",item_data:GetItemType(), ": ",gameRPGManager.GetItemWeight(item_data))
    --     print('Not Counted: ', ElementInTable(item_data:GetID().id.hash, empty_inventory_clothes), ": ",item_data:GetID(), " ")
    -- end

    local total_weight = 0
    for i, item_data in pairs(inventory_data_manager_v2:GetPlayerItems()) do
        local item_weight = gameRPGManager.GetItemWeight(item_data)
        if item_weight > 0 then
            if (not ElementInTable(item_data:GetID().id.hash, empty_inventory_clothes)) then
                total_weight = total_weight + item_weight
            end
        end
    end

    -- Could be better to use gameRPGManager.IsItemEquipped in loop above
    if (no_equip_weight) then
        for i, inventory_data in pairs(inventory_data_manager_v2:GetEquippedWeapons()) do
            total_weight = total_weight - gameRPGManager.GetItemWeight(inventory_data:GetGameItemData())
        end
        for i, clothing_area in pairs(equipment_system.GetClothingEquipmentAreas()) do
            total_weight = total_weight - RPGManager.GetItemWeight(inventory_data_manager_v2:GetPlayerItemData(inventory_data_manager_v2:GetEquippedItemIdInArea(clothing_area, 0)))
        end
    end
    return total_weight
end

---@param inventory_data_manager_v2 InventoryDataManagerV2
---@param itemID ItemID
---@param slot number
-- When an item is equipped, remove weight from inventory based on equipped weapon and add weight based on an unequipped weapon
function InventoryManager:before_equip_item(inventory_data_manager_v2, itemID, slot)
    if (not no_equip_weight) then                                -- if noEquipWeight is disabled in settings
        return
    end
    
    if not gameItemID.IsValid(itemID) then                          -- error check from CDPR code
        LogDebug(logtag, itemID.." is not a valid itemID")
        return
    end

    local equipmentSystem = Game.GetScriptableSystemsContainer():Get("EquipmentSystem") -- get EquipmentSystem
    local player = Game.GetPlayer()                                                     -- get Player

    local equippedItemData = inventory_data_manager_v2:GetPlayerItemData(itemID)                -- get item data of item equipped
    local equippedItemWeight = gameRPGManager.GetItemWeight(equippedItemData)                   -- get weight of item equipped

    local equipArea = equipmentSystem.GetEquipAreaType(itemID)                                  -- get area where item is equipped
    local unequippedItemID = inventory_data_manager_v2:GetEquippedItemIdInArea(equipArea, slot) -- get item about to be unequipped
    local unequippedItemData = inventory_data_manager_v2:GetPlayerItemData(unequippedItemID)    -- get item data of item about to be unequipped
    local unequippedItemWeight = gameRPGManager.GetItemWeight(unequippedItemData)               -- get weight of item about to be unequipped

    local weightChange = unequippedItemWeight - equippedItemWeight                      -- add weight of item about to be unequipped and subtract weight of item being equipped

    if weightChange == 0.00 then                        -- this is done in CDPR code
        return;
    end

    player:UpdateInventoryWeight(weightChange)          -- add weightChange to inventoryWeight
end

---@param inventory_data_manager_v2 InventoryDataManagerV2
---@param equip_area gamedataEquipmentArea
---@param slot number
-- When an item is unequipped, add item's weight to inventory
function InventoryManager:before_unequip_item(inventory_data_manager_v2, equip_area, slot)
    if (not no_equip_weight) then
        return
    end

    if equip_area == gamedataEquipmentArea.Invalid then      -- error check from CDPR code
        LogDebug(logtag, equip_area.." is not a valid EquipmentArea")
        return
    end
    local player = Game.GetPlayer()                                                 -- get Player

    local unequippedItemID = inventory_data_manager_v2:GetEquippedItemIdInArea(equip_area, slot)         -- get item about to be unequipped
    local unequippedItemData = inventory_data_manager_v2:GetPlayerItemData(unequippedItemID)             -- get item data of item about to be unequipped
    local unequippedItemWeight = gameRPGManager.GetItemWeight(unequippedItemData)   -- get weight of item about to be unequipped

    if unequippedItemWeight == 0.00 then            -- this is done in CDPR code
        return;
    end

    player:UpdateInventoryWeight(unequippedItemWeight)          -- add weightChange to inventoryWeight
end

local function reset_weight()
    local player = Game.GetPlayer()

    player:UpdateInventoryWeight(-9999999)              --TODO: probably shouldn't be -9999999
    player:UpdateInventoryWeight(calculate_weight())
end

---@param settings table
function InventoryManager:apply_settings(settings)
    if (no_equip_weight ~= settings.noEquipWeight) then
        no_equip_weight = settings.noEquipWeight
        reset_weight()
    end
end

---@param item_data gameItemData
local function add_weight_if_equipped(item_data)
    local player = Game.GetPlayer()

    print(gameRPGManager.IsItemEquipped(player, item_data:GetID()))
    if (gameRPGManager.IsItemEquipped(player, item_data:GetID())) then
        print(gameRPGManager.GetItemWeight(item_data))
        player:UpdateInventoryWeight(gameRPGManager.GetItemWeight(item_data))
    end
end

---@param item_data gameItemData
function InventoryManager:before_transfer_item(item_data)
    if (no_equip_weight) then
        add_weight_if_equipped(item_data)
    end
end

---@param item_data gameItemData
function InventoryManager:before_sell_item(item_data)
    if (no_equip_weight) then
        add_weight_if_equipped(item_data)
    end
end

return InventoryManager