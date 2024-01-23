local SettingsManager = {}

local logtag = "settings_manager"

local saved_settings_path = "./data/saved_settings.json"

local InventoryManager = {}

local active_settings = {}
local pending_settings = {}

local default_settings = {
    carryCapacity = 200,
    noEquipWeight = true
}

local min_carry_capacity = 0
local max_carry_capacity = 1000

-- LOCAL FUNCTIONS --

-- Sets pending_settings to default_settings
local function set_default_settings()
    for name, value in pairs(default_settings) do
        pending_settings[name] = value
    end
end

-- Writes active_settings to file
local function save_settings()
    WriteJSONFile(saved_settings_path, active_settings)
end

-- Calls manager's apply_settings functions, sets active_settings to pending_settings, and saves the settings to a file
local function apply_pending_settings()
    InventoryManager:apply_settings(pending_settings)

    for name, value in pairs(pending_settings) do
        active_settings[name] = value
    end
    save_settings()
end

-- Sets pending_settings to defaul_settings and applies them
local function apply_default_settings()
    set_default_settings()
    apply_pending_settings()
end

-- Loads settings from file
local function load_saved_settings()
    local is_valid = false
    is_valid, pending_settings = IsSuccessProtectedLoadJSONFile(saved_settings_path)

    if (not is_valid) then
        apply_default_settings()
        return
    end

    apply_pending_settings()
end

-- Configures nativeSettings menu
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

    -- carryCapacity slider int
    nativeSettings.addRangeInt(
        path,
        "Carry Capacity (Requires Reload)",
        "**REQUIRES RELOAD** Amount of weight that the player can carry before becoming overencumbered",
        min_carry_capacity,
        max_carry_capacity,
        1,
        active_settings.carryCapacity,
        default_settings.carryCapacity,
        function(value)
            pending_settings.carryCapacity = value
        end
    )

    -- noEquipWeight switch
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


-- SETTINGSMANAGER FUNCTIONS --

---@param inventory_manager table
function SettingsManager:initialize(inventory_manager)
    InventoryManager = inventory_manager
    load_saved_settings()
    create_settings_menu()
end

return SettingsManager