trigger TriggerProduct on Product2 (before insert, before update) {
    if (Trigger.isUpdate) {
        if(Trigger.isBefore) {
            TriggerHandlerProduct.onBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
        }
    }
}