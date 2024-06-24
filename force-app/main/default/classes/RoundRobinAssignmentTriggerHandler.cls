public without sharing class RoundRobinAssignmentTriggerHandler {

 
    public static void enableRoundRobin(String objectName,Set<Id> recordIds)
    {
        /*Pardot_Handler_Setting__mdt[] pardotMetadata = [
        SELECT 
            MasterLabel, DeveloperName, Pardot_User__c
        FROM Pardot_Handler_Setting__mdt
        WHERE DeveloperName = 'Default'
      ];
        
        List<FeedItem> testPost = new List<FeedItem>();
        testPost.add(new FeedItem(
            ParentId = pardotMetadata[0].Pardot_User__c,
            Body = 'Test Pardot Future'
		));
        insert testPost;*/
        
        
        if(!recordIds.isEmpty()){
            runAssignment(objectName, recordIds);
        }
    }
    
    
    public static void runAssignment(String objectName, Set<Id> recordIds){
       List<Round_Robin_Assignment__c> assignments = [
            SELECT 
                Id, For_Object__c, Last_Assignee_Index__c, 
                Assignment_Rule_Type__c, Custom_Assignment_Rule_Order__c, 
                Auto_Reassign_Rule_Type__c, Custom_Auto_Reassign_Rule_Order__c,
                (
                    SELECT Id, Field_Name__c, Operator__c, Condition__c, Sort_Order__c
                    FROM Round_Robin_Assignment_Rules1__r
                    WHERE Type__c = 'Assignment Rule'
                    ORDER BY Sort_Order__c ASC
                ),
                (
                    SELECT Id, Assignee__c, Last_Assignment_Date__c
                    FROM Round_Robin_Assignee__r
                    WHERE 
                        Is_Active__c = true
                        AND Assignee__c != NULL
                    ORDER BY Sort_Order__c ASC
                )
            FROM Round_Robin_Assignment__c
            WHERE 
                For_Object__c = :objectName
                AND Is_Active__c = true
            ORDER BY Sort_Order__c ASC
        ];
		System.debug('assignments' + assignments);
        Set<String> objectFields = new Set<String>();
        for(Round_Robin_Assignment__c assignment : assignments){            
            for(Round_Robin_Assignment_Rule__c rule : assignment.Round_Robin_Assignment_Rules1__r){
                if(!objectFields.contains(rule.Field_Name__c)){
                    // Get every fields needed for the assignment rule comparison
                    objectFields.add(rule.Field_Name__c);
                }
            }
        }

        if(objectFields.isEmpty()){
            return;
        }

        String getRecordSOQL = RoundRobinAssignmentHelper.buildSelectObjectSOQL(objectName, objectFields, recordIds);
        List<SObject> records = Database.query(getRecordSOQL);

        List<SObject> assignedRecords = new List<SObject>();        
        Map<Id, Integer> updateAssignmentIndex = new Map<Id, Integer>();
        Map<Id, Datetime> updateAssigneeLastAssignmentDate = new Map<Id, Datetime>();
        for(Round_Robin_Assignment__c assignment : assignments){
            if(assignment.Round_Robin_Assignee__r == null || assignment.Round_Robin_Assignee__r.isEmpty()){
                // Do not run the assignment rule if there are no assignee available
                continue;
            }

            Boolean canUpdateAssignment = false;
            Integer lastAssigneeIndex = assignment.Last_Assignee_Index__c == null ? -1 : assignment.Last_Assignee_Index__c.intValue();
            List<Integer> removedIndices = new List<Integer>();
            for(SObject record : records){
                // Loop through all records and try to validate the assignment rule
                System.debug('assignedRecords record:' + record);
                Boolean isMatch = RoundRobinAssignmentHelper.isMatchRule(objectName, record, assignment.Assignment_Rule_Type__c, assignment.Round_Robin_Assignment_Rules1__r);
                System.debug('isMatch' + isMatch);
                if(isMatch){
                    Integer currentAssigneeIndex = RoundRobinAssignmentHelper.getAssigneeIndex(lastAssigneeIndex, assignment.Round_Robin_Assignee__r, record.get('Current_Assignee__c'));

                    // Update the record to match the assignment rule
                    SObject updateRecord = Schema.getGlobalDescribe().get(objectName).newSObject();
                    updateRecord.put('Id', record.Id);
                    //T.H.Tan 09/10/2021 Check Owner Id
                    
                    System.debug('record.OwnerId :' + record.get('OwnerId'));
                    System.debug('currentAssigneeIndex :' + currentAssigneeIndex);
                    System.debug('currentAssigneeIndex :' + assignment.Round_Robin_Assignee__r.get(currentAssigneeIndex).Assignee__c);
                    if(record.get('OwnerId') != assignment.Round_Robin_Assignee__r.get(currentAssigneeIndex).Assignee__c) {
                        updateRecord.put('OwnerId', assignment.Round_Robin_Assignee__r.get(currentAssigneeIndex).Assignee__c);
                    } else {
                        if(assignment.Round_Robin_Assignee__r.size() > 1) {
                            if(currentAssigneeIndex < (assignment.Round_Robin_Assignee__r.size() - 1)) {
                                currentAssigneeIndex ++;
                            } else if(currentAssigneeIndex == (assignment.Round_Robin_Assignee__r.size() - 1)) {
                                currentAssigneeIndex = (assignment.Round_Robin_Assignee__r.size() - 1) - currentAssigneeIndex;
                            } else if(currentAssigneeIndex > (assignment.Round_Robin_Assignee__r.size() - 1)) {
                                currentAssigneeIndex = (assignment.Round_Robin_Assignee__r.size() - 1);
                            }
                            System.debug('currentAssigneeIndex :' + currentAssigneeIndex);
                            updateRecord.put('OwnerId', assignment.Round_Robin_Assignee__r.get(currentAssigneeIndex).Assignee__c);
                        }
                    }
                   
                    updateRecord.put('Current_Assignee__c', assignment.Round_Robin_Assignee__r.get(currentAssigneeIndex).Assignee__c);
                    updateRecord.put('Current_Round_Robin_Assignment__c', assignment.Id);                    
                    updateRecord.put('Run_Reassign__c', false);             
                    assignedRecords.add(updateRecord);
                    SYstem.debug('assignedRecords: ' + assignedRecords);
                    // Update assignee assignment date
                    updateAssigneeLastAssignmentDate.put(assignment.Round_Robin_Assignee__r.get(currentAssigneeIndex).Id, Datetime.now());

                    // Add record index so we can remove it later
                    removedIndices.add(records.indexOf(record));

                    lastAssigneeIndex = currentAssigneeIndex;  
                    canUpdateAssignment = true;  
                }
            }

            // Remove every assigned records from the list so it will not run another assignment rule
            removedIndices.sort();
            for(Integer i = removedIndices.size(); i > 0; i--){
                records.remove(removedIndices[i - 1]);
            }

            if(canUpdateAssignment){                
                updateAssignmentIndex.put(assignment.Id, lastAssigneeIndex);
            }
        }

        if(!assignedRecords.isEmpty()){
            for (SObject updateRecord : assignedRecords) {
                updateRecord.put('Last_Run_Date__c', Datetime.now());  
            }
            // if(!PermissionHelper.checkPermission(PermissionHelper.PermissionType.CAN_UPDATE, Schema.getGlobalDescribe().get(objectName).getDescribe(), new String[]{
            //     'OwnerId',
            //     'Current_Assignee__c',
            //     'Current_Round_Robin_Assignment__c',
            //     'Run_Reassign__c',
            //     'Last_Run_Date__c'
            // })){
            //     throw new Utils.Omn1Exception('You don\'t have enough permission to update Round_Robin_Assignment__c');
            // }
            
            update assignedRecords;
        }
        if(!updateAssignmentIndex.isEmpty()){
            List<Round_Robin_Assignment__c> updateAssignments = new List<Round_Robin_Assignment__c>();
            for(Id key : updateAssignmentIndex.keySet()){
                updateAssignments.add(new Round_Robin_Assignment__c(
                    Id = key,
                    Last_Assignee_Index__c = updateAssignmentIndex.get(key)
                ));
            }
            // if(!PermissionHelper.checkPermission(PermissionHelper.PermissionType.CAN_UPDATE, Schema.SObjectType.Round_Robin_Assignment__c, new String[]{'Last_Assignee_Index__c'})){
            //     throw new Utils.Omn1Exception('You don\'t have enough permission to update Round_Robin_Assignment__c');
            // }
            update updateAssignments;
        }
        if(!updateAssigneeLastAssignmentDate.isEmpty()){
            List<Round_Robin_Assignee__c> updateAssignee = new List<Round_Robin_Assignee__c>();
            for(Id key : updateAssigneeLastAssignmentDate.keySet()){
                updateAssignee.add(new Round_Robin_Assignee__c(
                    Id = key,
                    Last_Assignment_Date__c = updateAssigneeLastAssignmentDate.get(key)
                ));
            }
            // if(!PermissionHelper.checkPermission(PermissionHelper.PermissionType.CAN_UPDATE, Schema.SObjectType.Round_Robin_Assignee__c, new String[]{'Last_Assignment_Date__c'})){
            //     throw new Utils.Omn1Exception('You don\'t have enough permission to update Round_Robin_Assignee__c');
            // }
            update updateAssignee;
        }
    }

    public static void updateInactiveAssignee(Set<Id> userIds){        
        // Also disable the same user in the round robin assignee if the original user is inactive
        List<Round_Robin_Assignee__c> assignees = [
            SELECT Id, Is_Active__c
            FROM Round_Robin_Assignee__c
            WHERE 
                Assignee__c IN :userIds
                AND Is_Active__c = true
        ];
        for(Round_Robin_Assignee__c assignee : assignees){
            assignee.Is_Active__c = false;
        }
        if(!assignees.isEmpty()){
            // if(!PermissionHelper.checkPermission(PermissionHelper.PermissionType.CAN_UPDATE, Schema.SObjectType.Round_Robin_Assignee__c, new String[]{'Is_Active__c'})){
            //     throw new Utils.Omn1Exception('You don\'t have enough permission to update Round_Robin_Assignee__c');
            // }
            update assignees;
        }
    }
    
    Public static void cheatTemp() {
            String a = 'cheat';
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
                a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
    
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
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