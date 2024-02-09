@addField(PlayerPuppet)
let ignoreQuestWeight: Bool = false;

@addField(PlayerPuppet)
let noEquipWeight: Bool = false;

@addField(PlayerPuppet)
let carryShardBoost: Float = 2.0;

// Doesn't count items if they have a quest tag or are equipped
@replaceMethod(PlayerPuppet)
private final func CalculateEncumbrance() -> Void {
    let i: Int32;
    let items: array<wref<gameItemData>>;
    let TS: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.GetGame());
    TS.GetItemList(this, items);
    i = 0;

    LogChannel(n"DEBUG", "Called now");

    this.m_curInventoryWeight = 0;
    while i < ArraySize(items) {
        if !ItemID.HasFlag(items[i].GetID(), gameEItemIDFlag.Preview) && (!this.ignoreQuestWeight || !items[i].HasTag(n"Quest")) && (!this.noEquipWeight || !RPGManager.IsItemEquipped(this, items[i].GetID())) {
            this.m_curInventoryWeight += RPGManager.GetItemStackWeight(this, items[i]);
        };
        i += 1;
    };
}

// Changes carry capacity added by carry shards by adding another modifier
@wrapMethod(PlayerPuppet)
protected cb func OnStatusEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Bool {
    wrappedMethod(evt);

    if evt.staticData.GameplayTagsContains(n"CarryShard") {
        let modifier: Float = this.carryShardBoost - 2.0;
        
        if modifier != 0.0 {
            let permaMod: ref<gameStatModifierData> = RPGManager.CreateStatModifier(gamedataStatType.CarryCapacity, gameStatModifierType.Additive, modifier);
            GameInstance.GetStatsSystem(this.GetGame()).AddSavedModifier(Cast<StatsObjectID>(this.GetEntityID()), permaMod);
        }    
    }
}