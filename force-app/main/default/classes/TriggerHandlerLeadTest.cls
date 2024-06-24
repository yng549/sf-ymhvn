@isTest(SeeAllData=true)
public class TriggerHandlerLeadTest {
    @isTest static void onBeforeInsertTest() {
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
        
        Opportunity opty = new Opportunity();
        opty.Name = 'Opty';
        opty.AccountId = acc1.Id;
        opty.StageName = 'New';
        opty.CloseDate = system.today().addDays(7);
        opty.Amount = 100;
        insert opty;
        
        Warehouse_Inventory__c wh = new Warehouse_Inventory__c();
        wh.Vendor__c = [select id, AccountId from user where Profile.Name = 'Community Sale Profile' and isactive = true limit 1].AccountId;
        wh.QoH__c = 1000;
        wh.Product__c = p.Id;
        insert wh;
        
        Lead l = new Lead();
        l.LastName = 'LastName';
        l.Customer_Account__c = acc2.Id;
        l.Product__c = p.Id;
        l.Phone = '0938707111';
        l.Email = 'abc@abc.cac';
        l.MobilePhone = '0938707111';
        l.OwnerId = [select id from user where Profile.Name = 'Community Sale Profile' and isactive = true limit 1].Id;
        //l.IsConverted = true;
        //l.ConvertedOpportunityId = opty.Id;
        //l.ConvertedAccountId = acc1.Id;
        //l.ConvertedDate = system.today();
        insert l;
        
        
        
        
        test.startTest();
        database.leadConvert lc = new database.leadConvert();
        lc.setLeadId(l.id);
        lc.setAccountId(acc1.Id);
        lc.setOpportunityId(opty.Id);
        
        leadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
        
        
        test.stopTest();
		
    }
}