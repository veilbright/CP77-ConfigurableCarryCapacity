@addField(PlayerPuppet)
let ignoreQuestWeight: Bool = false;

@addField(PlayerPuppet)
let noEquipWeight: Bool = false;

// Doesn't count items if they have a quest tag or are equipped
@replaceMethod(PlayerPuppet)
private final func CalculateEncumbrance() -> Void {
    let i: Int32;
    let items: array<wref<gameItemData>>;
    let TS: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.GetGame());
    TS.GetItemList(this, items);
    i = 0;
    this.m_curInventoryWeight = 0;
    while i < ArraySize(items) {
        if !ItemID.HasFlag(items[i].GetID(), gameEItemIDFlag.Preview) && (!this.ignoreQuestWeight || !items[i].HasTag(n"Quest")) && (!this.noEquipWeight || !RPGManager.IsItemEquipped(this, items[i].GetID())) {
            this.m_curInventoryWeight += RPGManager.GetItemStackWeight(this, items[i]);
        };
        i += 1;
    };
}