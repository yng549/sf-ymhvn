trigger TriggerSurveyService on SurveyService__c (before insert,before update,after insert,after update) {
    if(Trigger.isBefore)
    {
        if(Trigger.isInsert)
        {
            TriggerSurveyServiceHandler.onBeforeInsert(Trigger.new);
        }
    }
    
    if(Trigger.isUpdate)
    {
        if(Trigger.isBefore)
        {
            TriggerSurveyServiceHandler.onBeforeUpdate(Trigger.New);
        }
    }
}