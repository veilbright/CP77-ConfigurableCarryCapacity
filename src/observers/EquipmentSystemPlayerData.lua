local EquipmentSystemPlayerDataObserver = {}

local SettingsManager = nil

local logtag = "EquipmentSystemPlayerDataObserver"

-- LOCAL FUNCTIONS --


-- make sure player settings are correct
-- needs to be after the player has an equipment system so items can be equipped
local function observe_after_OnAttach()
    print(Game.GetPlayer().noEquipWeight)
    if SettingsManager ~= nil then
        SettingsManager:apply_player_settings()
    else
        LogError(logtag, "SettingsManager not passed correctly. PlayerPuppet settings not configured.")
    end
    print(Game.GetPlayer().noEquipWeight)
end


-- OBSERVER FUNCTIONS --

---@param settings_manager table
function EquipmentSystemPlayerDataObserver:initialize(settings_manager)
    SettingsManager = settings_manager

    -- Call adjust_calculate_encumberance when EquipmentSystemPlayerData is attached
    ObserveAfter("EquipmentSystemPlayerData", "OnAttach", observe_after_OnAttach)
end

return EquipmentSystemPlayerDataObserver