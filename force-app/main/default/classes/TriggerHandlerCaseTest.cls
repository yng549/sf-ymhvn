@isTest
public class TriggerHandlerCaseTest {
    @isTest static void onAfterUpsert() {
        Account acc1 = new Account();
        acc1.LastName = 'acc1';
        acc1.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc1.Is_Primary__c = true;
        insert acc1;
        
        Asset a1 = new Asset();
        a1.Name = 'Asset 1';
        a1.AccountId = acc1.Id;
        insert a1;
        
        Asset a2 = new Asset();
        a2.Name = 'Asset 2';
        a2.AccountId = acc1.Id;
        insert a2;
        
        Case c = new Case();
        c.AssetId = a1.Id;
        insert c;
        
        c.AssetId = a2.Id;
        update c;
    }
}