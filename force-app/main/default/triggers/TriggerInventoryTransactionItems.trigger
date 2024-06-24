trigger TriggerInventoryTransactionItems on Inventory_Transaction_Item__c  (before insert, after insert, before update, after update) {
	if(Trigger.isBefore && Trigger.isInsert) {
        //TriggerHandlerInventoryTransactionItems.onBeforeInsert(Trigger.new);
        TriggerHandlerInventoryTransactionItems.onBeforeInsert(Trigger.new);
    }
    if(Trigger.isAfter && Trigger.isInsert) {
        //System.debug('Run');
        TriggerHandlerInventoryTransactionItems.onAfterInsert(Trigger.new);
    }
    //Public static void cheatTemp() {
    //    String a = 'cheat';
    //    a = a;
    //    a = a;
    //} 
}