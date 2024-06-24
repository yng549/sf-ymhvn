trigger TriggerSurveyPCA on SurveyPCA__c (before insert,before update , after insert,after update) {
	if(Trigger.isInsert)
    {
        if(Trigger.isBefore)
        {
            TriggerSurveyPCAHandler.onBeforeInsert(Trigger.New);
        }
    }
    
    if(Trigger.isUpdate)
    {
        if(Trigger.isBefore)
        {
            TriggerSurveyPCAHandler.onBeforeUpdate(Trigger.New);
        }
    }
}