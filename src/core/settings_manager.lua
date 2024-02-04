local SettingsManager = {}

local logtag = "settings_manager"

local saved_settings_path = "./data/saved_settings.json"
local presets_path = "./data/presets.json"

local InventoryManager = {}
local TweakManager = {}

local settings_menu = {}

local active_settings = {}
local pending_settings = {}

local default_settings = {
    preset = 1,
    carryCapacity = 200,
    carryCapacityBooster = 1.5,
    noEquipWeight = true,
    carryCapacityCyberwareModifiers = true,
    strengthSkillCarryCapacityPassive = 1,
}

local valid_presets = false
local preset_selected = default_settings.preset
local preset_list = {}
local preset_settings = {}

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

-- Applies settings based on preset selected
local function apply_preset(native_settings)
    for key, value in pairs(preset_settings[preset_selected]) do
        if value ~= nil then                    -- typically will just skip the name which should be set to nil already
            if settings_menu[key] ~= nil then   -- verify the option exists on the settings menu
                native_settings.setOption(settings_menu[key], value)
            end
        end
    end
end

-- Calls manager's apply_settings functions, sets active_settings to pending_settings, and saves the settings to a file
local function apply_pending_settings()
    InventoryManager:apply_settings(pending_settings)
    TweakManager:apply_settings(pending_settings)

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

    -- verify all settings are set before applying
    for name, value in pairs(default_settings) do
        if pending_settings[name] == nil then
            LogDebug(logtag, name.." not found in "..saved_settings_path)
            pending_settings[name] = value
        end
    end

    apply_pending_settings()
end

local function load_presets()
    valid_presets, preset_settings = IsSuccessProtectedLoadJSONFile(presets_path)

    -- if presets are loaded, make the list for the selector
    if valid_presets then
        for i, preset_table in ipairs(preset_settings) do

            -- if presets aren't loading correctly, they aren't valid
            if preset_table.name == nil then
                valid_presets = false
                LogDebug(logtag, "Loaded presets are not valid")
                return
            end

            preset_list[i] = preset_table.name
            preset_table.name = nil
        end
    else
        LogDebug(logtag, "Loaded presets are not valid")
    end
end

-- Configures NativeSettings menu
local function create_settings_menu()
    local base_path = "/"..ModName
    local presets_path = base_path.."/presets"
    local settings_path = base_path.."/settings"
    local NativeSettings = GetMod('nativeSettings')

    if (NativeSettings == nil) then
        LogDebug(logtag, "NativeSettings not found")
        return
    end

    -- adds NativeSettings tab and subcategories
    if not NativeSettings.pathExists(base_path) then
        NativeSettings.addTab(base_path, ModName, apply_pending_settings)
    end
    if not NativeSettings.pathExists(presets_path) and valid_presets then
        NativeSettings.addSubcategory(presets_path, "Presets")
    end
    if not NativeSettings.pathExists(settings_path) then
        NativeSettings.addSubcategory(settings_path, "Settings")
    end

    -- Settings Variables --

    -- carry capacity
    local min_carry_capacity = 0
    local max_carry_capacity = 500
    local carry_capacity_step = 1

    -- carry capacity booster
    local min_carry_capacity_booster = 1.0
    local max_carry_capacity_booster = 3.0
    local carry_capacity_booster_step = 0.05

    -- carry capacity strength skill passive
    local strength_skill_carry_capacity_passive_names = {
        [1] = "Low",
        [2] = "Medium",
        [3] = "High",
        [4] = "Realistic",
        [5] = "Vanilla",
    }

    -- Settings UI --

    -- if presets file isn't loaded, don't load the UI for it
    if valid_presets then

        -- select preset string list
        NativeSettings.addSelectorString(
            presets_path,
            "Select Preset",
            "Choose which preset to apply",
            preset_list,
            active_settings.preset,
            default_settings.preset,
            function(value)
                preset_selected = value
            end
        )

        -- apply preset button
        NativeSettings.addButton(
            presets_path,
            "Apply Preset",
            "Applies the settings from the preset selected above",
            "Apply",
            45,
            function()
                apply_preset(NativeSettings)
            end
        )
    end

    -- noEquipWeight switch
    settings_menu.noEquipWeight = NativeSettings.addSwitch(
        settings_path,
        "Equipped Items Don't Affect Carry Weight",
        "Disable for vanilla settings",
        active_settings.noEquipWeight,
        default_settings.noEquipWeight,
        function(state)
            pending_settings.noEquipWeight = state
        end
    )

    -- carryCapacityCyberwareModifiers switch
    settings_menu.carryCapacityCyberwareModifiers = NativeSettings.addSwitch(
        settings_path,
        "Allow Cyberware Modifiers that Affect Carry Capacity",
        "**REQUIRES RELOAD**\nDisable to prevent the generation of cyberware modifiers (from buying or upgrading cyberware) that affect carry capacity.",
        active_settings.carryCapacityCyberwareModifiers,
        default_settings.carryCapacityCyberwareModifiers,
        function(state)
            pending_settings.carryCapacityCyberwareModifiers = state
        end
    )

    -- carryCapacity int slider
    settings_menu.carryCapacity = NativeSettings.addRangeInt(
        settings_path,
        "Carry Capacity",
        "**REQUIRES RELOAD**\nAmount of weight that the player can carry before becoming overencumbered",
        min_carry_capacity,
        max_carry_capacity,
        carry_capacity_step,
        active_settings.carryCapacity,
        default_settings.carryCapacity,
        function(value)
            pending_settings.carryCapacity = value
        end
    )

    -- carryCapacityBooster float slider
    settings_menu.carryCapacityBooster = NativeSettings.addRangeFloat(
        settings_path,
        "Multiplier from Carry Capacity Booster",
        "**REQUIRES RELOAD**\nChanges the multiplier from using a Carry Capacity Booster",
        min_carry_capacity_booster,
        max_carry_capacity_booster,
        carry_capacity_booster_step,
        "%.2f",
        active_settings.carryCapacityBooster,
        default_settings.carryCapacityBooster,
        function(value)
            pending_settings.carryCapacityBooster = value
        end
    )

    -- strengthSkillCarryCapacityPassive string list
    settings_menu.strengthSkillCarryCapacityPassive = NativeSettings.addSelectorString(
        settings_path,
        "Solo Skill Carry Capacity Boost",
        "**REQUIRES RELOAD**\nChanges the additional Capacity Capacity added by levels 5 and 25 of the Solo skill.\nLOW: Lvl 5: 15, Lvl 25: 35\nMEDIUM: Lvl 5: 25, Lvl 25: 75\nHIGH: Lvl 5: 100, Lvl 25: 300\nREALISTIC: Lvl 5: 1, Lvl 25: 1\nVANILLA: Lvl 5: 50, Lvl 25: 100",
        strength_skill_carry_capacity_passive_names,
        active_settings.strengthSkillCarryCapacityPassive,
        default_settings.strengthSkillCarryCapacityPassive,
        function(value)
            pending_settings.strengthSkillCarryCapacityPassive = value
        end
    )
end


-- SETTINGSMANAGER FUNCTIONS --

---@param inventory_manager table
---@param tweak_manager table
function SettingsManager:initialize(inventory_manager, tweak_manager)
    InventoryManager = inventory_manager
    TweakManager = tweak_manager
    load_presets()
    load_saved_settings()
    create_settings_menu()
end

return SettingsManager