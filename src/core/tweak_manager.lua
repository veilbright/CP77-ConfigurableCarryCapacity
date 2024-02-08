TweakManager = {}

local blackmarket_carry_capacity_booster = nil;
local carry_capacity = nil
local carry_capacity_booster = nil
local carry_capacity_cyberware_modifiers = nil
local infinite_carry_capacity = nil
local strength_skill_carry_capacity_passive_id = nil
local min_titanium_infused_bones_carry_capacity_boost = nil
local max_titanium_infused_bones_carry_capacity_boost = nil

local strength_skill_carry_capacity_passive_ids = {
    [1] = "configurable_carry_capacity_strength_skill_passives_low",
    [2] = "configurable_carry_capacity_strength_skill_passives_medium",
    [3] = "configurable_carry_capacity_strength_skill_passives_high",
    [4] = "configurable_carry_capacity_strength_skill_passives_realistic",
    [5] = "strength_skill_passives",
}


-- LOCAL FUNCTIONS --

local function set_carry_capacity()
    if infinite_carry_capacity then
        TweakDB:SetFlat("Character.Player_Primary_Stats_Base_inline13.value", math.huge)
    else
        TweakDB:SetFlat("Character.Player_Primary_Stats_Base_inline13.value", carry_capacity)
    end
end

local function set_carry_capacity_booster()
    local multiplier = 1 + (carry_capacity_booster / 100)   -- convert to float

    TweakDB:SetFlat("BaseStatusEffect.CarryCapacityBooster_inline1.value", multiplier)          -- changes actual effect
    TweakDB:SetFlat("Items.CarryCapacityBooster_inline1.intValues", {carry_capacity_booster})   -- chanegs UI
end

local function set_blackmarket_carry_capacity_booster()
    TweakDB:SetFlat("BaseStatusEffect.Blackmarket_CarryCapacityBooster_inline1.value", blackmarket_carry_capacity_booster)  -- changes actual effect
    TweakDB:SetFlat("Items.Blackmarket_CarryCapacityBooster_inline3.intValues", {blackmarket_carry_capacity_booster, 20})       -- changes UI
end

local function set_carry_capacity_cyberware_modifiers()
    if not carry_capacity_cyberware_modifiers then                                  -- run if disabled
        local modifier_groups = {                                                   -- all places Modifiers.CarryCapacity can be found
            "Items.AdvancedBloodPumpStatsShard.statModifiers",
            "Items.AdvancedPowerGripStatsShard.statModifiers",
            "Items.AdvancedAdaptiveStemCellsStatsShard.statModifiers",
            "Items.AdvancedPainReductorStatsShard.statModifiers",
            "Items.AdvancedReinforcedMusclesStatsShard.statModifiers",
            "Items.AdvancedAgileJointsStatsShard.statModifiers",
            "Items.AdvancedRapidMuscleNurishStatsShard.statModifiers",
            "Items.AdvancedTroubleFinderStatsShard.statModifiers",
            "ModifierGroups.SimpleCyberwareModifiers.statModifiers",
            "ModifierGroups.AdvancedCyberwareModifiersDriverUpdate.statModifiers",  
            "ModifierGroups.CyberwareModifierBoosts.statModifiers",
            "ModifierGroups.BodyCyberwareSimple.statModifiers",
            "ModifierGroups.TechnicalAbilityCyberwareSimple.statModifiers",
            "ModifierGroups.GenericCyberwareVariantModifiers.statModifiers",
            "ModifierGroups.SimpleCyberwareVariantModifiers.statModifiers",
        }
    
        for i, path in ipairs(modifier_groups) do           -- go to every flat in the table above
            local modifier_table = TweakDB:GetFlat(path)    -- returns a table of modifiers
    
            for j, modifier in ipairs(modifier_table) do    -- loop through the table of modifiers
                if modifier.value == "Modifiers.CarryCapacity" or modifier.value == "Modifiers.CarryCapacityRandom" or modifier.value == "Modifiers.CarryCapacityBoost" or modifier.value == "Modifiers.CarryCapacityToggle" or modifier.value == "Modifiers.CarryCapacityQualityToggle" then
                    table.remove(modifier_table, j)         -- remove any that have to do with carry capacity
                end
            end
    
            TweakDB:SetFlat(path, modifier_table)           -- replace the flat with the updated one
        end
    end
end

local function set_strength_skill_carry_capacity_passive_id()
    local strength_skill_carry_capacity_ui = {
        ["configurable_carry_capacity_strength_skill_passives_low"] = {{15}, {35}},
        ["configurable_carry_capacity_strength_skill_passives_medium"] = {{25}, {75}},
        ["configurable_carry_capacity_strength_skill_passives_high"] = {{100}, {300}},
        ["configurable_carry_capacity_strength_skill_passives_realistic"] = {{1}, {1}},
        ["strength_skill_passives"] = {{50}, {100}},
    }

    TweakDB:SetFlat("Proficiencies.Player_StrengthSkill_Passives_inline1.id", strength_skill_carry_capacity_passive_id)
    TweakDB:SetFlat("Proficiencies.StrengthSkill_inline1.intValues", strength_skill_carry_capacity_ui[strength_skill_carry_capacity_passive_id][1])
    TweakDB:SetFlat("Proficiencies.StrengthSkill_inline7.intValues", strength_skill_carry_capacity_ui[strength_skill_carry_capacity_passive_id][2])
end

local function set_titanium_infused_bones_carry_capacity_boost()
    local min = min_titanium_infused_bones_carry_capacity_boost / 100   -- converts from UI to float
    local max = max_titanium_infused_bones_carry_capacity_boost / 100   -- converts from UI to float
    local step = (max-min) / 4                                          -- there are 10 steps, so divide by 10

    -- Tier 1
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesCommon_inline1.value", min)
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesCommon_inline2.intValues", {math.floor(min * 100)})
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesCommon2_inline1.value", min)
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesCommon2_inline2.intValues", {math.floor(min * 100)})

    -- Tier 2
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesUncommon_inline1.value", min+step)
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesUncommon_inline2.intValues", {math.floor((min+step) * 100)})
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesUncommon2_inline1.value", min+step)
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesUncommon2_inline2.intValues", {math.floor((min+step) * 100)})

    -- Tier 3
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesRare_inline1.value", min+(step*2))
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesRare_inline2.intValues", {math.floor((min+(step*2)) * 100)})
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesRare2_inline1.value", min+(step*2))
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesRare2_inline2.intValues", {math.floor((min+(step*2)) * 100)})

    -- Tier 4
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesEpic_inline1.value", min+(step*3))
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesEpic_inline2.intValues", {math.floor((min+(step*3)) * 100)})
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesEpic2_inline1.value", min+(step*3))
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesEpic2_inline2.intValues", {math.floor((min+(step*3)) * 100)})

    -- Tier 5
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesLegendary_inline1.value", max)
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesLegendary_inline2.intValues", {max * 100})
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesLegendary2_inline1.value", max)
    TweakDB:SetFlat("Items.AdvancedTitaniumInfusedBonesLegendary2_inline2.intValues", {max * 100})
end

-- TWEAKMANAGER FUNCTIONS --

-- Fixes bugs with blackmarket_carrycapacitybooster (Ol Donkey)
function TweakManager:initialize()
    TweakDB:SetFlat("Items.Blackmarket_CarryCapacityBooster_inline5.localizedDescription", "None")          -- remove this lockey
    TweakDB:SetFlat("Items.Blackmarket_CarryCapacityBooster_inline3.localizedDescription", "LocKey#92976")  -- correct lockey, but not broken up
    TweakDB:SetFlat("Items.Blackmarket_CarryCapacityBooster_inline3.intValues", {100, 20})                  -- filling in lockey based on default values
end

---@param settings table
-- Updates TweakDB for settings changed
function TweakManager:apply_settings(settings)

    -- carry_capacity
    if carry_capacity ~= settings.carryCapacity then
        carry_capacity = settings.carryCapacity
        set_carry_capacity()
    end

    -- infinite_carry_capacity
    if infinite_carry_capacity ~= settings.infiniteCarryCapacity then
        infinite_carry_capacity = settings.infiniteCarryCapacity
        set_carry_capacity()
    end

    -- carry_capacity_booster
    if carry_capacity_booster ~= settings.carryCapacityBooster then
        carry_capacity_booster = settings.carryCapacityBooster
        set_carry_capacity_booster()
    end

    -- blackmarket_carry_capacity_booster
    if blackmarket_carry_capacity_booster ~= settings.blackmarketCarryCapacityBooster then
        blackmarket_carry_capacity_booster = settings.blackmarketCarryCapacityBooster
        set_blackmarket_carry_capacity_booster()
    end

    -- carry_capacity_cyberware_modifiers
    if carry_capacity_cyberware_modifiers ~= settings.carryCapacityCyberwareModifiers then
        carry_capacity_cyberware_modifiers = settings.carryCapacityCyberwareModifiers
        set_carry_capacity_cyberware_modifiers()
    end

    -- strength_skill_carry_capacity_passive_id
    if strength_skill_carry_capacity_passive_id ~= strength_skill_carry_capacity_passive_ids[settings.strengthSkillCarryCapacityPassive] then
        strength_skill_carry_capacity_passive_id = strength_skill_carry_capacity_passive_ids[settings.strengthSkillCarryCapacityPassive]
        set_strength_skill_carry_capacity_passive_id()
    end
    
    -- titanium_infused_bones_carry_capacity_boost
    if min_titanium_infused_bones_carry_capacity_boost ~= settings.minTitaniumInfusedBonesCarryCapacityBoost or max_titanium_infused_bones_carry_capacity_boost ~= settings.maxTitaniumInfusedBonesCarryCapacityBoost then
        min_titanium_infused_bones_carry_capacity_boost = settings.minTitaniumInfusedBonesCarryCapacityBoost
        max_titanium_infused_bones_carry_capacity_boost = settings.maxTitaniumInfusedBonesCarryCapacityBoost
        set_titanium_infused_bones_carry_capacity_boost()
    end
end

return TweakManager