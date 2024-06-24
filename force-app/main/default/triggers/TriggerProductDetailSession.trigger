trigger TriggerProductDetailSession on Product_Detail_Session__c (before insert, after insert, before update, after update, before delete, after undelete, after delete) {
	if (Trigger.isAfter && Trigger.isInsert){
        TriggerProductDetailSessionHandler.onAfterInsert(Trigger.new);
        
    }
    if (Trigger.isAfter && Trigger.isUpdate){
        TriggerProductDetailSessionHandler.onAfterUpdate(Trigger.new);
        
    }
}