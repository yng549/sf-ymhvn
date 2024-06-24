@isTest
public class TriggerHandlerLeadTransferTest {
	@isTest static void beforeInsertTest() {
        Lead_Transfer__c a = new Lead_Transfer__c();
        Test.startTest();
        insert a;
        TriggerHandlerLeadTransfer.cheatTemp();
        Test.stopTest();
    }
}