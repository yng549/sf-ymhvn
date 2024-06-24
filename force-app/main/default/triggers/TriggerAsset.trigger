trigger TriggerAsset on Asset (before insert, before update) {
    List<User> lstUser = new List<User>();
    lstUser = [SELECT Id, Username, Name, ContactId, AccountId FROM User where Id =: UserInfo.getUserId()];
    
	List<String> uniqueValueList = new List<String>();
    for(Asset record : Trigger.new){
        uniqueValueList.add(record.Frame_Number__c);
        if(lstUser[0].AccountId != null){
            record.AccountId = lstUser[0].AccountId ;
            record.Create_Manual__c = true;
        }
    }

    Map<String,Asset> uniqueValueMap = new Map<String,Asset>();
    for(Asset record : [
        SELECT Frame_Number__c FROM Asset
        WHERE Frame_Number__c IN :uniqueValueList
    ]){
        uniqueValueMap.put(record.Frame_Number__c, record);        
    }

    for(Asset record : Trigger.new){
        if(record.Frame_Number__c != Null) {
            if(uniqueValueMap.containsKey(record.Frame_Number__c)){
                if(trigger.isInsert || (trigger.isUpdate && record.id<>uniqueValueMap.get(record.Frame_Number__c).id)){
                    record.addError('Frame No is already exists ! Can not create the record with the: ' +  record.Frame_Number__c);
                }           
            }
        }
    }
}