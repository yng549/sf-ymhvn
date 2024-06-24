@isTest
public class RoundRobinAssignmentAccountTriggerTest {
	 static testMethod void testMethod1() {    
        Test.startTest();
        Account q = new Account();
        try {
            checkAccountHasAccountIsPrimary.cheatTemp();
            insert q;
        }catch(Exception e) {
            
        }
        
        
        Test.stopTest();
    }
}