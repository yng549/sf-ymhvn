trigger TriggerSurveySales on SurveySales__c (before insert,before update,after insert,after update) {

    if(Trigger.isInsert)
    {
        if(Trigger.isBefore)
        {
            TriggerSurveySalesHandler.onBeforeInsert(Trigger.new);
        }
    }
    
    if(Trigger.isUpdate)
    {
        if(Trigger.isBefore)
        {
            TriggerSurveySalesHandler.onBeforeUpdate(Trigger.New);
        }
    }
}