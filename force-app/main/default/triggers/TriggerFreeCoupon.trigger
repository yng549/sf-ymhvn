trigger TriggerFreeCoupon on Free_Coupon__c (before insert,before update,after insert,after update) {
    if (Trigger.isInsert) {
        if(Trigger.isBefore) {
            TriggerHandlerFreeCoupons.handleBeforeInsert(Trigger.new);
         }
        if(Trigger.isAfter) {
            TriggerHandlerFreeCoupons.handleAfterInsert(Trigger.new);
        }
    }
    if (Trigger.isUpdate) {
        if(Trigger.isAfter) {
           TriggerHandlerFreeCoupons.handleAfterUpdate( Trigger.new, Trigger.newMap, Trigger.oldMap);
        }
    }
}