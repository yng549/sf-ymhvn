trigger TriggerProductDetailService on Product_Detail_Service__c (before insert, after insert, before update, after update, before delete, after undelete, after delete) {
    if (Trigger.isAfter && Trigger.isInsert){
        TriggerProductDetailServiceHandler.onAfterInsert(Trigger.new);
        
    }
    if (Trigger.isAfter && Trigger.isUpdate){
        TriggerProductDetailServiceHandler.onAfterUpdate(Trigger.new);
        
    }
}