@isTest
public class TestDataFactory {
    public static User createTestAdminUser(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        String randomCode = generateRandomCode(20);
        User u = new User(
            Alias = 'admin', 
            Email='testadmin' + randomCode + '@test.com',
            EmailEncodingKey='UTF-8', 
            LastName='Testing', 
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='testadmin' + randomCode + '@test.com'
        );
        
        return u;
    }
    
    public static User createStandardUser(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        String randomCode = generateRandomCode(20);
        User u = new User(
            Alias = 'admin', 
            Email='teststandarduser' + randomCode + '@test.com',
            EmailEncodingKey='UTF-8', 
            LastName='Testing', 
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='teststandarduser' + randomCode + '@test.com'
        );
        
        return u;
    }
    
    public static List<Round_Robin_Assignment__c> createTestAssignmentRule(User u){
        List<Round_Robin_Assignment__c> assignments = new List<Round_Robin_Assignment__c>();
        Round_Robin_Assignment__c assignmentAnd = new Round_Robin_Assignment__c(
            For_Object__c = 'Lead',
            Assignment_Rule_Type__c = 'And',
            Auto_Reassign_Rule_Type__c = 'Or'
        );
        assignments.add(assignmentAnd);
        
        Round_Robin_Assignment__c assignmentOr = new Round_Robin_Assignment__c(
            For_Object__c = 'Opportunity',
            Assignment_Rule_Type__c = 'Or',
            Auto_Reassign_Rule_Type__c = 'And'
        );
        assignments.add(assignmentOr);
        insert assignments;
        
        List<Round_Robin_Assignee__c> assignees = new  List<Round_Robin_Assignee__c>();
        List<Round_Robin_Assignment_Rule__c> rules = new List<Round_Robin_Assignment_Rule__c>();
        for(Round_Robin_Assignment__c assignment : assignments){
            // Add assignee
            Round_Robin_Assignee__c assignee = new Round_Robin_Assignee__c(
                Assignee__c = u.Id,
                Is_Active__c = true,
                Round_Robin_assignment__c = assignment.Id,
                Sort_Order__c = 0
            );
            assignees.add(assignee);
            
            // Add rule
            Round_Robin_Assignment_Rule__c rule = new Round_Robin_Assignment_Rule__c(
                Field_Name__c = 'Description',
                Operator__c = 'Is Null',
                Condition__c = 'False',
                Sort_Order__c = 0,
                Type__c = 'Assignment Rule',
                Round_Robin_Assignment__c = assignment.Id
            );
            rules.add(rule);
            
            rule = new Round_Robin_Assignment_Rule__c(
                Field_Name__c = 'Description',
                Operator__c = 'Is Blank',
                Condition__c = 'False',
                Sort_Order__c = 1,
                Type__c = 'Assignment Rule',
                Round_Robin_Assignment__c = assignment.Id
            ); 
            rules.add(rule);
            
            rule = new Round_Robin_Assignment_Rule__c(
                Field_Name__c = 'Description',
                Operator__c = 'Equals',
                Condition__c = 'Test',
                Sort_Order__c = 2,
                Type__c = 'Assignment Rule',
                Round_Robin_Assignment__c = assignment.Id
            ); 
            rules.add(rule);
            
            rule = new Round_Robin_Assignment_Rule__c(
                Field_Name__c = 'Description',
                Operator__c = 'Does Not Equal',
                Condition__c = 'Test Fail',
                Sort_Order__c = 3,
                Type__c = 'Assignment Rule',
                Round_Robin_Assignment__c = assignment.Id
            ); 
            rules.add(rule);

            rule = new Round_Robin_Assignment_Rule__c(
                Field_Name__c = 'Description',
                Operator__c = 'Greater Than',
                Condition__c = '0',
                Sort_Order__c = 4,
                Type__c = 'Re-Assignment Rule',
                Round_Robin_Assignment__c = assignment.Id
            ); 
            rules.add(rule);
            
            rule = new Round_Robin_Assignment_Rule__c(
                Field_Name__c = 'Description',
                Operator__c = 'Less Than',
                Condition__c = '1000',
                Sort_Order__c = 5,
                Type__c = 'Re-Assignment Rule',
                Round_Robin_Assignment__c = assignment.Id
            ); 
            rules.add(rule);
            
        }
        insert assignees;
        insert rules;   
        
        return assignments;
    }
    
    
    
    private static String generateRandomCode(Integer length){
        String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
        String[] charArray = chars.split('');
        Integer charLength = charArray.size();
        
        String accessCode = '';
        for(Integer i = 0; i < length; i++){
            Integer randomIndex = Math.round(Math.random() * (charLength - 1));
            accessCode += charArray[randomIndex];
        }
        return accessCode;
    }
}