trigger TriggerOrder on Order (before insert, after insert, before update, after update, before delete, after undelete, after delete) {
    if(Trigger.isBefore && Trigger.isInsert) {
        //TriggerOrderHandler.beforeInsert(Trigger.new);
        TriggerOrder.onBeforeInsert(Trigger.new);
    }
    if(Trigger.isBefore && Trigger.isUpdate) {
        //TriggerOrderHandler.beforeInsert(Trigger.new);
        TriggerOrder.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
    if(Trigger.isAfter && Trigger.isUpdate && !TriggerOrder.flagRunCancleOrderBike) {
        TriggerOrder.flagRunCancleOrderBike = true;
        TriggerOrder.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
    }
    if(Trigger.isAfter && Trigger.isInsert) {
        TriggerOrder.onAfterInsert(Trigger.new);   
    }
    
   
}