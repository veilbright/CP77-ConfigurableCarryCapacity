local VendorDataManagerObserver = {}


-- LOCAL FUNCTIONS --

---@param item_data gameItemData
local function observe_before_TransferItem(class, source, target, item_data)
    EncumbranceManager:before_transfer_item(item_data)
end

---@param item_data gameItemData
local function observe_before_SellItemToVendor(class, item_data)
    EncumbranceManager:before_sell_item(item_data)
end


-- OBSERVER FUNCTIONS --

function VendorDataManagerObserver:initialize()
    -- Call before_transfer_item when the player/vendor transfers an item
    ObserveBefore("VendorDataManager", "TransferItem", observe_before_TransferItem)

    -- Call before_sell_item before the player sells an item to a vendor
    ObserveBefore("VendorDataManager", "SellItemToVendor", observe_before_SellItemToVendor)
end

return VendorDataManagerObserver