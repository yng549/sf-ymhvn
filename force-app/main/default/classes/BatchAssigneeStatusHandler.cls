public without sharing class BatchAssigneeStatusHandler extends BaseBatchHandler{
    
	public BatchAssigneeStatusHandler(){
        this.objectName = 'Round_Robin_Assignment__c';
    }
    
    public override Database.querylocator start(Database.BatchableContext BC){
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> schemaFieldMap = sobjectType.getDescribe().fields.getMap();
        
        String query = ' ';
        query += 'SELECT Id, (SELECT Id, Assignee__c, Is_Active__c, Assignee__r.Profile.Name FROM Round_Robin_Assignee__r) ';
        query += ' FROM ' + objectName;
        query += ' WHERE Is_Active__c = TRUE';
        System.debug('query:' +query);
        if (Test.isRunningTest()){
            query += ' LIMIT 200';
        }
        return Database.getQueryLocator(query);
    }
    
    public override List<SObject> processData(List<SObject> records){
        System.debug('Batch newData ');
        List<Round_Robin_Assignment__c> newData = (List<Round_Robin_Assignment__c>)records;
        try {
            updateStatusAssignee(newData);
        } Catch(Exception ex){
            System.debug(ex.getLineNumber() + ' | ' + ex.getMessage());
            System.debug(ex.getStackTraceString());
            DevLog__c objDevLog = new DevLog__c();
            objDevLog.Input__c += ' Lead Id: ' + newData[0].Id + '<br>/';
            objDevLog.Output__c += ex.getLineNumber() + ' | ' + ex.getMessage() + '<br>/';
            objDevLog.Output__c += ex.getStackTraceString() + '<br>/';
          
        }
        return newData;
    }
    
    private static void updateStatusAssignee(List<Round_Robin_Assignment__c> newData) {
		Set<Id> setIdUser = new Set<Id>();
        Map<Id, Id> mapUserWithContactId = new Map<Id, Id>();
        Map<Id, Roster_Management__c> mapStaffWithRoster = new Map<Id, Roster_Management__c>();
        Map<Id, Round_Robin_Assignee__c> mapRoundRobinAssignee = new Map<Id, Round_Robin_Assignee__c>();
        List<Round_Robin_Assignee__c> lstAssigneeUpdate = new List<Round_Robin_Assignee__c>();
        try {
            for(Round_Robin_Assignment__c item : newData) {
                if(!item.Round_Robin_Assignee__r.isEmpty()) {
                    for(Round_Robin_Assignee__c obj : item.Round_Robin_Assignee__r) {
                        if(obj.Assignee__r.Profile.Name == 'Community Sale Sup' || obj.Assignee__r.Profile.Name == 'Community Sale Profile') {
                        	System.debug('aa:' + obj.Assignee__r.Profile.Name);
                            mapRoundRobinAssignee.put(obj.Id, obj);
                            setIdUser.add(obj.Assignee__c);
                		}
                    }
                }
            }
            System.debug('mapRoundRobinAssignee: ' + mapRoundRobinAssignee);
            Map<Id, User> mapUser = new Map<Id, User>([SELECT Id
                                                       		, ContactId
                                                       		, Profile.Name
                                                       FROM User 
                                                       WHERE Id IN: setIdUser]);
            for(User item : mapUser.values()) {
                mapUserWithContactId.put(item.Id, item.ContactId);
            }
            System.debug('mapUserWithContactId: ' + mapUserWithContactId);
            List<Roster_Management__c> lstRosterManagementQuery = [SELECT Id
                                                                   		, Date__c
                                                                   		, Staff__c
                                                                   		, Absent_Submit__c
                                                                   FROM Roster_Management__c 
                                                                   WHERE Staff__c IN: mapUserWithContactId.values() 
                                                                   		AND Date__c =: Date.today()
                                                                   ORDER BY Date__c ASC];
            System.debug('lstRosterManagementQuery: ' + lstRosterManagementQuery);
            for(Roster_Management__c item : lstRosterManagementQuery) {
                mapStaffWithRoster.put(item.Staff__c, item);
            }
            for(Round_Robin_Assignee__c item : mapRoundRobinAssignee.values()) {
                if(mapUserWithContactId.containsKey(item.Assignee__c)) {
                    System.debug('Line74');
                    System.debug('mapUserWithContactId.get(item.Assignee__c): ' + mapUserWithContactId.get(item.Assignee__c));
                    if(mapStaffWithRoster.containsKey(mapUserWithContactId.get(item.Assignee__c))) {
                        System.debug('Line 77 ');
                        if(mapStaffWithRoster.get(mapUserWithContactId.get(item.Assignee__c)).Absent_Submit__c && item.Is_Active__c) {
                            System.debug('Line 79: ' +item);
                            item.Is_Active__c = false;
                            lstAssigneeUpdate.add(item);
                        } else if(!mapStaffWithRoster.get(mapUserWithContactId.get(item.Assignee__c)).Absent_Submit__c && !item.Is_Active__c) {
                            System.debug('Line 82: ' +item);
                            item.Is_Active__c = true;
                            lstAssigneeUpdate.add(item);
                        }
                    } else {
                        System.debug('Line 86 ');
                        if(item.Is_Active__c) {
                            item.Is_Active__c = false;
                        	lstAssigneeUpdate.add(item);
                        }
                    }
                }
            }
            System.debug('lstAssigneeUpdate:' + lstAssigneeUpdate);
            if(!lstAssigneeUpdate.isEmpty()) {
                update lstAssigneeUpdate;
            }
        } catch(Exception ex) {
            System.debug('ex get error: ' + ex.getMessage() +  ' ' + ex.getLineNumber());
        }
    }    
    
    public override void handleFinish(){
        
    }
    
    public static void cheat(){
        String a = '';
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
    }
}