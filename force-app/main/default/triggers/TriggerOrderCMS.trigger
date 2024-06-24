trigger TriggerOrderCMS on Order_WebCommercal__c (before insert, before update, after insert, after update) {
    if(Trigger.isInsert) {
        if(Trigger.isAfter) {
            //TriggerHandlerOrderCMS.onAfterInsert(Trigger.New, false);
        }
    }
	if(Trigger.isUpdate) {
        if(Trigger.isAfter) {
            TriggerHandlerOrderCMS.onAfterUpdate(Trigger.New, Trigger.newMap, Trigger.oldMap);
        }
    }
}