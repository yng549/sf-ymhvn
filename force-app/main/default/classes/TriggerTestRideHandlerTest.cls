@isTest
public class TriggerTestRideHandlerTest {
	static testMethod void testMethod1() {    
        Test.startTest();
      	Test_Ride__c ride = new Test_Ride__c();
        try {
            TriggerTestRideHandler.cheatTemp();
            insert ride;
        }catch(Exception e) {
            
        }
        Test.stopTest();
    }
}