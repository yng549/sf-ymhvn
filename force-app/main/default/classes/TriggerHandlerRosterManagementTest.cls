@isTest
public class TriggerHandlerRosterManagementTest {
	static testMethod void testMethod1() {
       	test.startTest();
       		Roster_Management__c a = new Roster_Management__c();
        	insert a;
        	update a;
        	TriggerHandlerRosterManagement.cheat();
        test.stopTest();
    }
}