local SettingsManager = {}

local logtag = "settings_manager"

local inventory_manager = {}

local active_settings = {}
local pending_settings = {}

local default_settings = {
    noEquipWeight = true
}


local function set_default_settings()
    for name, value in pairs(default_settings) do
        pending_settings[name] = value
    end
end

local function save_settings()
    WriteJSONFile(FilePaths.savedSettings, active_settings)
end

local function apply_pending_settings()
    inventory_manager:apply_settings(pending_settings)

    for name, value in pairs(pending_settings) do
            active_settings[name] = value
    end
    save_settings()
end

local function apply_default_settings()
    set_default_settings()
    apply_pending_settings()
end

local function load_saved_settings()
    local is_valid = false
    is_valid, pending_settings = IsSuccessProtectedLoadJSONFile(FilePaths.savedSettings)

    if (not is_valid) then
        apply_default_settings()
        return
    end

    apply_pending_settings()
end

local function create_settings_menu()
    local path = '/' .. ModName
    local nativeSettings = GetMod('nativeSettings')

    if (nativeSettings == nil) then
        LogDebug(logtag, "nativeSettings not found")
        return
    end

    if not nativeSettings.pathExists(path) then
        nativeSettings.addTab(path, ModName, apply_pending_settings)
    end

    -- nativeSettings.addSwitch(path, label, desc, currentValue, defaultValue, callback, optionalIndex)
    nativeSettings.addSwitch(
        path,
        "Equipped Items Don't Affect Carry Weight",
        "Weapons or clothing that you equip will not contribute to the amount of weight you are carrying",
        active_settings.noEquipWeight,
        default_settings.noEquipWeight,
        function(state)
            pending_settings.noEquipWeight = state
        end
    )
end

---@param inv_manager table
function SettingsManager:initialize(inv_manager)
    inventory_manager = inv_manager
    load_saved_settings()
    create_settings_menu()
end

return SettingsManager