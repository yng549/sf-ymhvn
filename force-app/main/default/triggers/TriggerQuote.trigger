trigger TriggerQuote on Quote (before insert, after insert, before update, after update, before delete, after undelete, after delete) {

    if(Trigger.isBefore && Trigger.isInsert) {
        TriggerHandlerQuote.beforeInsert(Trigger.new);
    }
    if(Trigger.isBefore && Trigger.isUpdate) {
		TriggerHandlerQuote.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
    if(Trigger.isAfter && Trigger.isUpdate) {
		TriggerHandlerQuote.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
    }
    if(Trigger.isAfter && Trigger.isInsert) {
		TriggerHandlerQuote.onAfterInsert(Trigger.New);
    }
}