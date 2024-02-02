TweakManager = {}

local carry_capacity = nil
local carry_capacity_booster = nil
local carry_capacity_cyberware_modifiers = nil


-- TWEAKMANAGER FUNCTIONS --

---@param settings table
-- Updates TweakDB for settings changed
function TweakManager:apply_settings(settings)

    -- carry_capacity TODO: maybe reload doesn't have to be required?
    if carry_capacity ~= settings.carryCapacity then
        carry_capacity = settings.carryCapacity
        TweakDB:SetFlat("Character.Player_Primary_Stats_Base_inline13.value", carry_capacity)
        
    end

    -- carry_capacity_booster TODO: maybe reload doesn't have to be required?
    if carry_capacity_booster ~= settings.carryCapacityBooster then
        carry_capacity_booster = settings.carryCapacityBooster
        --local ui_effect = {(carry_capacity_booster * 100) - 100}

        TweakDB:SetFlat("BaseStatusEffect.CarryCapacityBooster_inline1.value", carry_capacity_booster)      -- changes actual effect
        --TweakDB:SetFlat("BaseStatusEffect.CarryCapacityBooster_inline2.intValues", ui_effect)
    end

    -- carry_capacity_cyberware_modifiers
    if carry_capacity_cyberware_modifiers ~= settings.carryCapacityCyberwareModifiers then
        carry_capacity_cyberware_modifiers = settings.carryCapacityCyberwareModifiers

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
end

return TweakManager