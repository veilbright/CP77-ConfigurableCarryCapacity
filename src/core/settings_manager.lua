local SettingsManager = {}

local logtag = "settings_manager"

local saved_settings_path = "./data/saved_settings.json"
local presets_path = "./data/presets.json"

local EncumbranceManager = {}
local TweakManager = {}

local settings_menu = {}

local active_settings = {}
local pending_settings = {}

local default_settings = {
    preset = 1,
    blackmarketCarryCapacityBooster = 100;
    carryCapacity = 200,
    carryCapacityBooster = 50,
    carryCapacityCyberwareModifiers = true,
    carryShardBoost = 2.0;
    ignoreQuestWeight = true,
    infiniteCarryCapacity = false;
    maxTitaniumInfusedBonesCarryCapacityBoost = 66,
    minTitaniumInfusedBonesCarryCapacityBoost = 30,
    noEquipWeight = true,
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
    EncumbranceManager:apply_settings(pending_settings)
    TweakManager:apply_settings(pending_settings)

    for name, value in pairs(pending_settings) do
        active_settings[name] = value
    end
    save_settings()
end

-- Sets pending_settings to default_settings and applies them
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
            local preset_name = ""

            -- if presets aren't loading correctly, they aren't valid
            if preset_table.key == nil then
                if preset_table.name == nil then                                    -- for custom presets without keys
                    valid_presets = false
                    LogDebug(logtag, "Loaded presets are not valid")
                    return
                else
                    preset_name = preset_table.name                                 -- as long as name is present, use that
                    preset_table.name = nil
                end
            else
                preset_name = LocalizationManager:get_translation(preset_table.key) -- otherwise use localization
                preset_table.key = nil
            end

            preset_list[i] = preset_name
        end
    else
        LogDebug(logtag, "Loaded presets are not valid")
    end
end

-- Configures NativeSettings menu
local function create_settings_menu()
    local base_path = "/"..LocalizationManager:get_translation("modName")
    local presets_path = base_path.."/presets"
    local settings_path = base_path.."/settings"
    local NativeSettings = GetMod('nativeSettings')

    if (NativeSettings == nil) then
        LogDebug(logtag, "NativeSettings not found")
        return
    end

    -- adds NativeSettings tab and subcategories
    if not NativeSettings.pathExists(base_path) then
        NativeSettings.addTab(base_path, LocalizationManager:get_translation("modName"), apply_pending_settings)
    end
    if not NativeSettings.pathExists(presets_path) and valid_presets then
        NativeSettings.addSubcategory(presets_path, LocalizationManager:get_translation("settings.presets.name"))
    end
    if not NativeSettings.pathExists(settings_path) then
        NativeSettings.addSubcategory(settings_path, LocalizationManager:get_translation("settings.settings.name"))
    end

    -- Settings Variables --

    -- carry capacity
    local min_carry_capacity = 0
    local max_carry_capacity = 500
    local carry_capacity_step = 1

    -- carry capacity boosters
    local min_carry_capacity_booster = 0
    local max_carry_capacity_booster = 300
    local carry_capacity_booster_step = 1

    -- carry shard boost
    local min_carry_shard_boost = 0.0
    local max_carry_shard_boost = 10.0
    local carry_shard_boost_step = 0.1

    -- titanium infused bones carry capacity boost
    local titanium_infused_bones_carry_capacity_boost_min_setting = 0
    local titanium_infused_bones_carry_capacity_boost_max_setting = 300
    local titanium_infused_bones_carry_capacity_boost_step = 1

    -- carry capacity strength skill passive
    local strength_skill_carry_capacity_passive_names = {
        [1] = LocalizationManager:get_translation("settings.settings.strengthSkillCarryCapacityPassive.low.name"),
        [2] = LocalizationManager:get_translation("settings.settings.strengthSkillCarryCapacityPassive.medium.name"),
        [3] = LocalizationManager:get_translation("settings.settings.strengthSkillCarryCapacityPassive.high.name"),
        [4] = LocalizationManager:get_translation("settings.settings.strengthSkillCarryCapacityPassive.realistic.name"),
        [5] = LocalizationManager:get_translation("settings.settings.strengthSkillCarryCapacityPassive.vanilla.name"),
    }

    -- Settings UI --

    -- if presets file isn't loaded, don't load the UI for it
    if valid_presets then

        -- select preset string list
        NativeSettings.addSelectorString(
            presets_path,
            LocalizationManager:get_translation("settings.presets.select.label"),
            LocalizationManager:get_translation("settings.presets.select.description"),
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
            LocalizationManager:get_translation("settings.presets.apply.label"),
            LocalizationManager:get_translation("settings.presets.apply.description"),
            LocalizationManager:get_translation("settings.presets.apply.button.label"),
            45,
            function()
                apply_preset(NativeSettings)
            end
        )
    end

    -- carryCapacity int slider
    settings_menu.carryCapacity = NativeSettings.addRangeInt(
        settings_path,
        LocalizationManager:get_translation("settings.settings.carryCapacity.label"),
        LocalizationManager:get_translation("settings.settings.carryCapacity.description"),
        min_carry_capacity,
        max_carry_capacity,
        carry_capacity_step,
        active_settings.carryCapacity,
        default_settings.carryCapacity,
        function(value)
            pending_settings.carryCapacity = value
        end
    )

    -- infiniteCarryCapacity switch
    settings_menu.infiniteCarryCapacity = NativeSettings.addSwitch(
        settings_path,
        LocalizationManager:get_translation("settings.settings.infiniteCarryCapacity.label"),
        LocalizationManager:get_translation("settings.settings.infiniteCarryCapacity.description"),
        active_settings.infiniteCarryCapacity,
        default_settings.infiniteCarryCapacity,
        function(state)
            pending_settings.infiniteCarryCapacity = state
        end
    )

    -- noEquipWeight switch
    settings_menu.noEquipWeight = NativeSettings.addSwitch(
        settings_path,
        LocalizationManager:get_translation("settings.settings.noEquipWeight.label"),
        LocalizationManager:get_translation("settings.settings.noEquipWeight.description"),
        active_settings.noEquipWeight,
        default_settings.noEquipWeight,
        function(state)
            pending_settings.noEquipWeight = state
        end
    )

    -- ignoreQuestWeight switch
    settings_menu.ignoreQuestWeight = NativeSettings.addSwitch(
        settings_path,
        LocalizationManager:get_translation("settings.settings.ignoreQuestWeight.label"),
        LocalizationManager:get_translation("settings.settings.ignoreQuestWeight.description"),
        active_settings.ignoreQuestWeight,
        default_settings.ignoreQuestWeight,
        function(state)
            pending_settings.ignoreQuestWeight = state
        end
    )

    -- carryCapacityCyberwareModifiers switch
    settings_menu.carryCapacityCyberwareModifiers = NativeSettings.addSwitch(
        settings_path,
        LocalizationManager:get_translation("settings.settings.carryCapacityCyberwareModifiers.label"),
        LocalizationManager:get_translation("settings.settings.carryCapacityCyberwareModifiers.description"),
        active_settings.carryCapacityCyberwareModifiers,
        default_settings.carryCapacityCyberwareModifiers,
        function(state)
            pending_settings.carryCapacityCyberwareModifiers = state
        end
    )

    -- strengthSkillCarryCapacityPassive string list
    settings_menu.strengthSkillCarryCapacityPassive = NativeSettings.addSelectorString(
        settings_path,
        LocalizationManager:get_translation("settings.settings.strengthSkillCarryCapacityPassive.label"),
        LocalizationManager:get_translation("settings.settings.strengthSkillCarryCapacityPassive.description"),
        strength_skill_carry_capacity_passive_names,
        active_settings.strengthSkillCarryCapacityPassive,
        default_settings.strengthSkillCarryCapacityPassive,
        function(value)
            pending_settings.strengthSkillCarryCapacityPassive = value
        end
    )

    -- carryCapacityBooster int slider
    settings_menu.carryCapacityBooster = NativeSettings.addRangeInt(
        settings_path,
        LocalizationManager:get_translation("settings.settings.carryCapacityBooster.label"),
        LocalizationManager:get_translation("settings.settings.carryCapacityBooster.description"),
        min_carry_capacity_booster,
        max_carry_capacity_booster,
        carry_capacity_booster_step,
        active_settings.carryCapacityBooster,
        default_settings.carryCapacityBooster,
        function(value)
            pending_settings.carryCapacityBooster = value
        end
    )

    -- blackmarketCarryCapacityBooster int slider
    settings_menu.blackmarketCarryCapacityBooster = NativeSettings.addRangeInt(
        settings_path,
        LocalizationManager:get_translation("settings.settings.blackmarketCarryCapacityBooster.label"),
        LocalizationManager:get_translation("settings.settings.blackmarketCarryCapacityBooster.description"),
        min_carry_capacity_booster,
        max_carry_capacity_booster,
        carry_capacity_booster_step,
        active_settings.blackmarketCarryCapacityBooster,
        default_settings.blackmarketCarryCapacityBooster,
        function(value)
            pending_settings.blackmarketCarryCapacityBooster = value
        end
    )

    -- minTitaniumInfusedBonesCarryCapacityBoost int slider
    settings_menu.minTitaniumInfusedBonesCarryCapacityBoost = NativeSettings.addRangeInt(
        settings_path,
        LocalizationManager:get_translation("settings.settings.minTitaniumInfusedBonesCarryCapacityBoost.label"),
        LocalizationManager:get_translation("settings.settings.minTitaniumInfusedBonesCarryCapacityBoost.description"),
        titanium_infused_bones_carry_capacity_boost_min_setting,
        titanium_infused_bones_carry_capacity_boost_max_setting,
        titanium_infused_bones_carry_capacity_boost_step,
        active_settings.minTitaniumInfusedBonesCarryCapacityBoost,
        default_settings.minTitaniumInfusedBonesCarryCapacityBoost,
        function(value)
            pending_settings.minTitaniumInfusedBonesCarryCapacityBoost = value
        end
    )

    -- maxTitaniumInfusedBonesCarryCapacityBoost int slider
    settings_menu.maxTitaniumInfusedBonesCarryCapacityBoost = NativeSettings.addRangeInt(
        settings_path,
        LocalizationManager:get_translation("settings.settings.maxTitaniumInfusedBonesCarryCapacityBoost.label"),
        LocalizationManager:get_translation("settings.settings.maxTitaniumInfusedBonesCarryCapacityBoost.description"),
        titanium_infused_bones_carry_capacity_boost_min_setting,
        titanium_infused_bones_carry_capacity_boost_max_setting,
        titanium_infused_bones_carry_capacity_boost_step,
        active_settings.maxTitaniumInfusedBonesCarryCapacityBoost,
        default_settings.maxTitaniumInfusedBonesCarryCapacityBoost,
        function(value)
            pending_settings.maxTitaniumInfusedBonesCarryCapacityBoost = value
        end
    )

    -- carryShardBoost float slider
    settings_menu.carryShardBoost = NativeSettings.addRangeFloat(
        settings_path,
        LocalizationManager:get_translation("settings.settings.carryShardBoost.label"),
        LocalizationManager:get_translation("settings.settings.carryShardBoost.description"),
        min_carry_shard_boost,
        max_carry_shard_boost,
        carry_shard_boost_step,
        "%.1f",
        active_settings.carryShardBoost,
        default_settings.carryShardBoost,
        function(value)
            pending_settings.carryShardBoost = value
        end
    )
end


-- SETTINGSMANAGER FUNCTIONS --

---@param encumbrance_manager table
---@param tweak_manager table
function SettingsManager:initialize(encumbrance_manager, tweak_manager)
    LogDebug(logtag, "start initialize")

    EncumbranceManager = encumbrance_manager
    TweakManager = tweak_manager
    load_presets()
    load_saved_settings()
    create_settings_menu()

    LogDebug(logtag, "end initialize")
end

return SettingsManager