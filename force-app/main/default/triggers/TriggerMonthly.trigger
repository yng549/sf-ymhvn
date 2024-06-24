trigger TriggerMonthly on Monthly_KPI__c (before insert,before update,after insert,after update) {
    
    if(Trigger.isAfter)
    {
        if(Trigger.isUpdate)
        {
            TriggerHandlerMonthly.isBeforeUpdate(Trigger.New);
        }
    }

}