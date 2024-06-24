@isTest
public class UnlockRecordsTest {
    @isTest static void beforeInsertTest() {
        Test.startTest();
        Account sup1 = new Account();
        sup1.Name = 'sup1';
        sup1.RecordTypeId = RecordTypeHelper.ACCOUNT_SUPPLIER;
        sup1.AccountNo__c = 1001;
        insert sup1;
        
        List<ID> lstID = new List<ID>();
        lstID.add(sup1.Id);
        
        UnlockRecords.unlock(lstID);
        Test.stopTest();
    }
}