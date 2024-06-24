public with sharing class AssignmentRuleManagementController {
    
    @AuraEnabled
    public static ApiResponse getInitialData(String recordId, String type){
        ApiResponse apiResponse = new ApiResponse(true);

        Map<String, Object> result = new Map<String, Object>();
        List<Round_Robin_Assignment__c> assignments = [
            SELECT 
                Id, For_Object__c, 
                Assignment_Rule_Type__c, Custom_Assignment_Rule_Order__c, 
                Auto_Reassign_Rule_Type__c, Custom_Auto_Reassign_Rule_Order__c
            FROM Round_Robin_Assignment__c
            WHERE Id = :recordId
        ];

        if(!assignments.isEmpty()){
            List<Round_Robin_Assignment_Rule__c> rules = [
                SELECT 
                    Id, Field_Name__c, Operator__c, Condition__c, Sort_Order__c
                FROM Round_Robin_Assignment_Rule__c
                WHERE 
                    Round_Robin_Assignment__c = :assignments[0].Id
                    AND Type__c = :type
                ORDER BY Sort_Order__c ASC
            ];
            
            result.put('assignment', assignments[0]);
            result.put('rules', rules);
        }
        result.put('namespacePrefix', Utils.getNamespacePrefix());
        apiResponse.result = result;

        return apiResponse;
    }

    @AuraEnabled
    public static ApiResponse saveRule(String recordId, String type, String ruleType, String customRuleLogic, List<Round_Robin_Assignment_Rule__c> rules){
        ApiResponse apiResponse = new ApiResponse();        

        Round_Robin_Assignment__c[] assignments = [
            SELECT 
                Id, For_Object__c, 
                Assignment_Rule_Type__c, Custom_Assignment_Rule_Order__c, 
                Auto_Reassign_Rule_Type__c, Custom_Auto_Reassign_Rule_Order__c
            FROM Round_Robin_Assignment__c
            WHERE 
                Id = :recordId
            LIMIT 1
        ];

        List<String> errors = new List<String>();
        if(assignments.isEmpty()){
            errors.add('Invalid assignment id');
        }

        if(!PermissionHelper.checkPermission(PermissionHelper.PermissionType.CAN_DELETE, Schema.SObjectType.Round_Robin_Assignment_Rule__c, null)){
            errors.add('You don\'t have enough permission to delete Round_Robin_Assignment_Rule__c');
        }

        if(!PermissionHelper.checkPermission(PermissionHelper.PermissionType.CAN_UPDATE, Schema.SObjectType.Round_Robin_Assignment__c, new String[] {
            'Assignment_Rule_Type__c', 'Custom_Assignment_Rule_Order__c', 'Auto_Reassign_Rule_Type__c', 'Custom_Auto_Reassign_Rule_Order__c'
        })){
            errors.add('You don\'t have enough permission to update Round_Robin_Assignment__c');
        }
                
        if(!PermissionHelper.checkPermission(PermissionHelper.PermissionType.CAN_CREATE, Schema.SObjectType.Round_Robin_Assignment_Rule__c, new String[] {
            'Condition__c', 'Field_Name__c', 'Round_Robin_Assignment__c', 'Operator__c', 'Sort_Order__c', 'Type__c'
        })){
            errors.add('You don\'t have enough permission to insert Round_Robin_Assignment_Rule__c');
        }

        if(!errors.isEmpty()){
            apiResponse.error = String.join(errors, '. ');
        } else {
            try{
                Round_Robin_Assignment__c updateAssignment = new Round_Robin_Assignment__c(Id = assignments[0].Id);
                if(type.equals('Assignment Rule')){
                    updateAssignment.Assignment_Rule_Type__c = ruleType;
                    updateAssignment.Custom_Assignment_Rule_Order__c = customRuleLogic;
                }

                if(type.equals('Re-Assignment Rule')){
                    updateAssignment.Auto_Reassign_Rule_Type__c = ruleType;
                    updateAssignment.Custom_Auto_Reassign_Rule_Order__c = customRuleLogic;
                }

                List<Round_Robin_Assignment_Rule__c> existingRules = [
                    SELECT 
                        Id
                    FROM Round_Robin_Assignment_Rule__c
                    WHERE 
                        Round_Robin_Assignment__c = :updateAssignment.Id
                        AND Type__c = :type
                    ORDER BY Sort_Order__c ASC
                ];
                if(!existingRules.isEmpty()){
                    delete existingRules;
                }

                for(Round_Robin_Assignment_Rule__c rule : rules){
                    rule.Round_Robin_Assignment__c = updateAssignment.Id;
                    rule.Type__c = type;
                }
                insert rules;
                update updateAssignment;

                apiResponse.success = true;
            } catch(Exception e){
                apiResponse.error = e.getMessage();
            }
        }
        
        return apiResponse;
    }
}