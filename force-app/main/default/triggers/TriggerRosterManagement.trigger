/**
 * @description       : 
 * @author            : DuyNguyen
 * @group             : 
 * @last modified on  : 16-07-2021
 * @last modified by  : DuyNguyen
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   16-07-2021   DuyNguyen   Initial Version
**/
trigger TriggerRosterManagement on Roster_Management__c (before insert, after insert, after update) {
    if(Trigger.isInsert){
     
        if(Trigger.isAfter){
            TriggerHandlerRosterManagement.onAfterInsert(Trigger.new);
        }
    }
    
    if(Trigger.isUpdate){
        if(Trigger.isAfter){
            TriggerHandlerRosterManagement.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
            //TriggerHandlerRosterManagement.onAfterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap, Trigger.size);
        }
    }
}