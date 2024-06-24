trigger TriggerPricebook on Pricebook2 (before insert, before update, after insert, after update) {
    if(Trigger.isInsert){
        if(Trigger.isBefore){
            TriggerHandlerPricebook.onBeforeInsert(Trigger.new);
        }
        if(Trigger.isAfter){
            TriggerHandlerPricebook.onAfterInsert(Trigger.new);
        }
    }
    
    if(Trigger.isUpdate){
        if(Trigger.isBefore){
            TriggerHandlerPricebook.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
        if(Trigger.isAfter){
            TriggerHandlerPricebook.onAfterInsert(Trigger.new);
        }
    }
}