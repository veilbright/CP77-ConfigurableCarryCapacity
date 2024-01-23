local CarryCapacityOverhaul = {}

ModName = "Carry Capacity Overhaul"
FilePathsJSON = "./data/file_paths.json"
FilePaths = {}

DEBUG = true
local logtag = "init"

-- Managers
local SettingsManager = require("./core/settings_manager")
local InventoryManager = require("./core/inventory_manager")

-- Observers
local EquipmentSystemPlayerDataObserver = require("./observers/EquipmentSystemPlayerData")
local InventoryDataManagerV2Observer = require("./observers/InventoryDataManagerV2")
local PlayerPuppetObserver = require("./observers/PlayerPuppet")
local VendorDataManagerObserver = require("./observers/VendorDataManager")

local function initialize_observers()
    EquipmentSystemPlayerDataObserver:initialize()
    InventoryDataManagerV2Observer:initialize()
    PlayerPuppetObserver:initialize()
    VendorDataManagerObserver:initialize()
end

-- On CET Init, will load data filepaths and initialize SettingsManager and observers
registerForEvent("onInit", function()
    LogDebug(logtag, "Start initialization")

    FilePaths = ProtectedLoadJSONFile(FilePathsJSON)

    SettingsManager:initialize(InventoryManager)
    initialize_observers()

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

    if (file == nil) then
        LogDebug(logtag, "Failed to load "..filepath)
        error()
    end

    local contents = file:read("*a")
    return json.decode(contents), true
end

---@param filepath string
---@return table
-- Loads a JSON file as a table. Logs an error if JSON isn't valid or file doesn't exist. Returns is_successful, contents
function ProtectedLoadJSONFile(filepath)
    local is_successful, content = IsSuccessProtectedLoadJSONFile(filepath)
    return content
end

---@param filepath string
---@return boolean, table
-- Loads a JSON file as a table. Logs an error if JSON isn't valid or file doesn't exist. Returns is_successful, contents
function IsSuccessProtectedLoadJSONFile(filepath)
    local is_successful, content = pcall(function() return LoadJSONFile(filepath) end)

    if (not is_successful) then
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

return CarryCapacityOverhaul