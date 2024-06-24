@isTest
public class AssignmentRuleManagementControllerTest {
    @isTest
    static void test_getInitialData(){
        Test.startTest();
        User u = TestDataFactory.createTestAdminUser();
        System.runAs(u) {
            List<Round_Robin_Assignment__c> assignments = TestDataFactory.createTestAssignmentRule(u);            
            if(!assignments.isEmpty()){
                ApiResponse apiResponse = AssignmentRuleManagementController.getInitialData(assignments[0].Id, 'Assignment Rule');

            } 
        }
        Test.stopTest();
    }

    @isTest
    static void test_saveRule(){
        Test.startTest();
        User u = TestDataFactory.createTestAdminUser();
        System.runAs(u) {
            TestDataFactory.createTestAssignmentRule(u);
            List<Round_Robin_Assignment__c> assignments = [
                SELECT 
                    Id,
                    (
                        SELECT 
                        Id, Field_Name__c, Operator__c, Condition__c, Sort_Order__c
                        FROM Round_Robin_Assignment_Rules1__r
                        WHERE Type__c = 'Assignment Rule'
                    )
                FROM Round_Robin_Assignment__c 
                LIMIT 1
            ];
            List<Round_Robin_Assignment__c> reassignments = [
                SELECT 
                    Id
                FROM Round_Robin_Assignment__c 
                LIMIT 1
            ];
            if(!assignments.isEmpty()){
                ApiResponse apiFailedResponse = AssignmentRuleManagementController.saveRule(assignments[0].Id, 'Assignment Rule', 'Or', '', assignments[0].Round_Robin_Assignment_Rules1__r);
                // Should throw exception because we are trying to change master details relationship

                List<Round_Robin_Assignment_Rule__c> rules = new List<Round_Robin_Assignment_Rule__c>();
                rules.add(new Round_Robin_Assignment_Rule__c(
                    Field_Name__c = 'Amount',
                    Operator__c = 'Less Than',
                    Condition__c = '1000',
                    Sort_Order__c = 5,
                    Type__c = 'Re-Assignment Rule'
                ));
                ApiResponse apiSuccessResponse = AssignmentRuleManagementController.saveRule(assignments[0].Id, 'Re-Assignment Rule', 'And', '1 & 2', rules);
                // Should save successfully without any error

                Id deletedId = assignments[0].Id;
                delete assignments[0];
                ApiResponse apiDeleteResponse = AssignmentRuleManagementController.saveRule(deletedId, 'Re-Assignment Rule', 'And', '', null);
                // Should throw invalid assignment id
            }            
        }
        Test.stopTest();
    }
}