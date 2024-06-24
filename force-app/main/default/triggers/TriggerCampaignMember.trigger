trigger TriggerCampaignMember on CampaignMember (before insert, after insert, before update, after update, before delete, after undelete, after delete) {
	if(Trigger.isBefore && Trigger.isUpdate) {
        TriggerHandlerCampaignMember.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
}