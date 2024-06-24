trigger TriggerSalesReport on Sales_Report__c (before insert, after insert, before update) {
	If(Trigger.isInsert) {
        if(Trigger.isBefore) {
            TriggerHandlerSalesReport.onAfterInsert(Trigger.new);
        }
    }
    if(Trigger.isUpdate) {
        if(Trigger.isBefore) {
            TriggerHandlerSalesReport.onBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
        }
    }
}