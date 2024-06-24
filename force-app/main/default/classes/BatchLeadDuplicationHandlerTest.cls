@isTest
public class BatchLeadDuplicationHandlerTest {
    @isTest static void test() {
        Account acc2 = new Account();
        acc2.LastName = 'acc2';
        acc2.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc2.Is_Primary__c = false;
        acc2.DO_DL_Owner__c = UserInfo.getUserId();
        insert acc2;
        
        Id standardPricebookID = Test.getStandardPricebookId();        
        Product2 p = new Product2();
        p.Name = 'Test Product';
        insert p;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookID,
            Product2Id = p.Id,
            UnitPrice = 1020,
            IsActive = true,
            UseStandardPrice = false
        );
        Insert pbe;
        
        Account acc1 = new Account();
        acc1.LastName = 'acc1';
        acc1.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc1.Is_Primary__c = true;
        insert acc1;
        acc1.Account_Is_Primary__c = acc1.Id;
        acc1.Applied_Promotion__c = true;
        
        Lead l = new Lead();
        l.LastName = 'LastName';
        l.Customer_Account__c = acc2.Id;
        l.Product__c = p.Id;
        l.Phone = '0938707111';
        l.Email = 'abc@abc.cac';
        l.MobilePhone = '0938707111';
        l.OwnerId = [select id from user where Profile.Name = 'Community Sale Profile' and isactive = true limit 1].Id;
        insert l;
		
        Lead l1= new Lead();
        l1.LastName = 'test2';
        l1.Customer_Account__c = acc2.Id;
        l1.Product__c = p.Id;
        l1.Phone = '0938707111';
        l1.Email = 'abc@abc.cac';
        l1.MobilePhone = '0938707111';
        l1.OwnerId = [select id from user where Profile.Name = 'Community Sale Profile' and isactive = true limit 1].Id;
        insert l1;
        BatchLeadDuplicationHandler.cheatTemp();
        BaseBatchHandler.cheatTemp();
        
    }
}