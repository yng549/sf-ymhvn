trigger TriggerAccount on Account (before insert, after update, before update) {
    if(Trigger.isInsert) {
        if(Trigger.isBefore) {
            TriggerAccountHandler.beforeInsert(Trigger.new);
        }
    }
    if (Trigger.isUpdate) {
        if(Trigger.isBefore) {
            TriggerAccountHandler.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
        if(Trigger.isAfter) {
            TriggerAccountHandler.onAfterUpdate(Trigger.new, Trigger.newMap, Trigger.oldMap);
        }
    }
}