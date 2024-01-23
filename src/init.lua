local CarryCapacityOverhaul = {}

ModName = "Carry Capacity Overhaul"
FilePathsJSON = "./data/file_paths.json"
FilePaths = {}

DEBUG = true
local logtag = "init"

local SettingsManager = require("./core/settings_manager")
local InventoryManager = require("./core/inventory_manager")

local InventoryDataManagerV2Observer = require("./observers/InventoryDataManagerV2")
local VendorDataManagerObserver = require("./observers/VendorDataManager")

-- onInit
registerForEvent("onInit", function()
    LogDebug(logtag, "Start initialization")

    FilePaths = ProtectedLoadJSONFile(FilePathsJSON)

    SettingsManager:initialize(InventoryManager)

    InventoryDataManagerV2Observer:initialize()
    VendorDataManagerObserver:initialize()

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


 ---@param element any
 ---@param table table
 ---@return boolean
 -- Table should be set up with elements in keys and false in values
function ElementInTable(element, table)
    for key, value in pairs(table) do
        if (element == value) then
            return true
        end
    end

    return false
end

return CarryCapacityOverhaul