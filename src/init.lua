local ConfigurableCarryCapacity = {}

ModName = "Configurable Carry Capacity"

DEBUG = true
local logtag = "init"

-- Global Managers
LocalizationManager = require("./core/localization_manager")

-- Managers
local EncumbranceManager = require("./core/encumbrance_manager")
local SettingsManager = require("./core/settings_manager")
local TweakManager = require("./core/tweak_manager")


-- Observers
local InventoryDataManagerV2Observer = require("./observers/InventoryDataManagerV2")
local VendorDataManagerObserver = require("./observers/VendorDataManager")

-- Initialize Observers
local function initialize_observers()
    InventoryDataManagerV2Observer:initialize()
    VendorDataManagerObserver:initialize()
end

-- On CET Init, will initialize SettingsManager and observers
registerForEvent("onInit", function()
    LogDebug(logtag, "Start initialization")

    initialize_observers()
    LocalizationManager:initialize()
    SettingsManager:initialize(EncumbranceManager, TweakManager)

    LogDebug(logtag, "End initialization")
end)

-------------------------------------------------------------------------------
---                                 UTILS                                   ---
-------------------------------------------------------------------------------

---@param filepath string
---@return table, boolean
-- How to call: is_valid, content = pcall(function() return LoadJSONFile(filepath) end)
function LoadJSONFile(filepath)
    local file = io.open(filepath, "r")

    if file == nil then
        LogDebug(logtag, "Failed to load "..filepath)
        error()
    end

    local contents = file:read("*a")
    return json.decode(contents), true
end

---@param filepath string
---@return table
-- Loads a JSON file as a table. Logs an error if JSON isn't valid or file doesn't exist. Returns contents
function ProtectedLoadJSONFile(filepath)
    local is_successful, content = IsSuccessProtectedLoadJSONFile(filepath)
    return content
end

---@param filepath string
---@return boolean, table
-- Loads a JSON file as a table. Logs an error if JSON isn't valid or file doesn't exist. Returns is_successful, contents
function IsSuccessProtectedLoadJSONFile(filepath)
    local is_successful, content = pcall(function() return LoadJSONFile(filepath) end)

    if not is_successful then
        LogError(logtag, filepath.." is not valid JSON")
        return false, {}
    end

    return true, content
end

---@param filepath string
---@param contents_table table
-- Writes a table as JSON to a filepath
function WriteJSONFile(filepath, contents_table)
    local is_valid_json, contents = pcall(function() return json.encode(contents_table) end)

    if not is_valid_json then
        LogError(logtag, contents)
        return
    end

    if (contents == nil) then
        LogDebug(logtag, "Contents of "..filepath.." == nil")
        return
    end

    local file = io.open(filepath, "w+")
    file:write(contents)
    file:close()
end

---@param tag string
---@param text any
function LogDebug(tag, text)
    if DEBUG == true then
        spdlog.info(tostring("["..ModName.."] DEBUG "..tag..": "..text))
    end
end

---@param tag string
---@param text any
function LogError(tag, text)
    spdlog.info(tostring("["..ModName.."] ERROR "..tag..": "..text))
    print(tostring("["..ModName.."] ERROR "..tag..": "..text))
end

 ---@param element any
 ---@param table table
 ---@return boolean
 -- Returns if the element is found in the table
function ElementInTable(element, table)
    for key, value in pairs(table) do
        if (element == value) then
            return true
        end
    end

    return false
end

function DumpTable(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. DumpTable(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

return ConfigurableCarryCapacity