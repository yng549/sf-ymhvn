trigger TriggerProduct on Product2(before insert, before update, after update) {
  if (Trigger.isUpdate) {
    if (Trigger.isBefore) {
      TriggerHandlerProduct.onBeforeUpdate(
        Trigger.new,
        Trigger.newMap,
        Trigger.oldMap
      );
    }
    if (Trigger.isAfter) {
      TriggerHandlerProduct.onAfterUpdate(
        Trigger.new,
        Trigger.newMap,
        Trigger.oldMap
      );
    }
  }
}
