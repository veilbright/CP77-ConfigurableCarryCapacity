TweakManager = {}

local carry_capacity = nil
local carry_capacity_booster = nil
local carry_capacity_cyberware_modifiers = nil
local strength_skill_carry_capacity_passive_id = nil


-- LOCAL FUNCTIONS --

local function set_carry_capacity()
    TweakDB:SetFlat("Character.Player_Primary_Stats_Base_inline13.value", carry_capacity)
end

local function set_carry_capacity_booster()
    --local ui_effect = {(carry_capacity_booster * 100) - 100}

    TweakDB:SetFlat("BaseStatusEffect.CarryCapacityBooster_inline1.value", carry_capacity_booster)      -- changes actual effect
    --TweakDB:SetFlat("BaseStatusEffect.CarryCapacityBooster_inline2.intValues", ui_effect)
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
        ["carry_capacity_overhaul_strength_skill_passives_low"] = {{15}, {35}},
        ["carry_capacity_overhaul_strength_skill_passives_medium"] = {{25}, {75}},
        ["carry_capacity_overhaul_strength_skill_passives_high"] = {{100}, {300}},
        ["carry_capacity_overhaul_strength_skill_passives_realistic"] = {{1}, {1}},
        ["strength_skill_passives"] = {{50}, {100}},
    }

    TweakDB:SetFlat("Proficiencies.Player_StrengthSkill_Passives_inline1.id", strength_skill_carry_capacity_passive_id)
    TweakDB:SetFlat("Proficiencies.StrengthSkill_inline1.intValues", strength_skill_carry_capacity_ui[strength_skill_carry_capacity_passive_id][1])
    TweakDB:SetFlat("Proficiencies.StrengthSkill_inline7.intValues", strength_skill_carry_capacity_ui[strength_skill_carry_capacity_passive_id][2])
end

-- TWEAKMANAGER FUNCTIONS --

---@param settings table
-- Updates TweakDB for settings changed
function TweakManager:apply_settings(settings)
    local strength_skill_carry_capacity_passive_ids = {
        [1] = "carry_capacity_overhaul_strength_skill_passives_low",
        [2] = "carry_capacity_overhaul_strength_skill_passives_medium",
        [3] = "carry_capacity_overhaul_strength_skill_passives_high",
        [4] = "carry_capacity_overhaul_strength_skill_passives_realistic",
        [5] = "strength_skill_passives",
    }

    -- carry_capacity TODO: maybe reload doesn't have to be required?
    if carry_capacity ~= settings.carryCapacity then
        carry_capacity = settings.carryCapacity
        set_carry_capacity()
    end

    -- carry_capacity_booster TODO: maybe reload doesn't have to be required?
    if carry_capacity_booster ~= settings.carryCapacityBooster then
        carry_capacity_booster = settings.carryCapacityBooster
        set_carry_capacity_booster()
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
    
end

return TweakManager