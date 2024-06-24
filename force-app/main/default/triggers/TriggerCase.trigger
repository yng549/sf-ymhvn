trigger TriggerCase on Case  (before insert, after insert, before update, after update, before delete, after undelete, after delete) {
   if (Trigger.isInsert && Trigger.isAfter) {
        TriggerHandlerCase.onAfterUpsert(Trigger.new);
   }
    
   if (Trigger.isUpdate && Trigger.isAfter) {
        TriggerHandlerCase.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
   }
   //TriggerDispatcher.run(new TriggerCaseHandler() , Trigger.OperationType);
}