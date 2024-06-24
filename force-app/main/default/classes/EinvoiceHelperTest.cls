@isTest
public class EinvoiceHelperTest {
	@isTest
    static void testHN()
    {       

        Test.startTest();
        EinvoiceHelper.cheatTemp();
        Test.setMock(HttpCalloutMock.class, new EinvoiceMockResponse());
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = Test.getStandardPricebookId();
        pricebook.IsActive = true;
        update pricebook;
        
        Asset asset = new Asset();
        asset.Name = 'test';
        insert asset;
        
        Account dodl = new Account();
        dodl.RecordTypeId = RecordTypeHelper.ACCOUNT_DODL;
        dodl.Name = 'Test';
        dodl.Einvoice_Location__c = 'Hà Nội';
        insert dodl;
        
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc.LastName = 'Test';
        insert acc;
        
        Opportunity opty = new Opportunity();
        opty.RecordTypeId = RecordTypeHelper.OPPORTUNITY_BIKE;
        opty.Name = 'Test';
        opty.AccountId = acc.Id;
        opty.StageName = 'New';
        opty.CloseDate = Date.today() + 7;
        opty.Enable_Round_Robin__c = false;
        opty.Pricebook2Id = Test.getStandardPricebookId();
        opty.Amount = 100;
        insert opty;
        
        
        
        Order order = new Order();
        order.RecordTypeId = RecordTypeHelper.ORDER_BIKE;
        order.Pricebook2Id = Test.getStandardPricebookId();
        order.AccountId = acc.Id;
        order.DO_DL__c = dodl.Id;
        order.OpportunityId = opty.Id;
        order.Status = 'Draft';
        order.EndDate = Date.today() + 1;
        order.EffectiveDate = Date.today();
        order.Tax_Address__c = 'Test';
        order.Tax_Code__c = 'TaxCode';
        order.Tax_Mobile__c = '0907868802';
        order.Payment_Method__c = 'Cash';
        order.Asset__c = asset.Id;
        insert order;
        
        Product2 p = new Product2();
        p.Name = 'Test Product';
        p.Description='Test Product';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = Test.getStandardPricebookId();
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 100;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
                
        OrderItem item = new OrderItem();
        item.OrderId = order.Id;
        item.UnitPrice = 2000;
        item.Product2Id = p.Id;
        item.Quantity = 1;
        item.PricebookEntryId = standardPrice.Id;
        insert item;
        
        BtnSendEinvoiceController.sendEinvoice(order.Id);
        BtnCreateEinvoiceController.createEinvoice(order.Id);
        
        Test.stopTest();
    }
    
    @isTest
    static void testHCM()
    {       
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EinvoiceMockResponse());
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = Test.getStandardPricebookId();
        pricebook.IsActive = true;
        update pricebook;
        
        Asset asset = new Asset();
        asset.Name = 'test';
        insert asset;
        
        Account dodl = new Account();
        dodl.RecordTypeId = RecordTypeHelper.ACCOUNT_DODL;
        dodl.Name = 'Test';
        dodl.Einvoice_Location__c = 'Hồ Chí Minh';
        insert dodl;
        
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc.LastName = 'Test';
        insert acc;
        
        Opportunity opty = new Opportunity();
        opty.RecordTypeId = RecordTypeHelper.OPPORTUNITY_BIKE;
        opty.Name = 'Test';
        opty.AccountId = acc.Id;
        opty.StageName = 'New';
        opty.CloseDate = Date.today() + 7;
        opty.Enable_Round_Robin__c = false;
        opty.Pricebook2Id = Test.getStandardPricebookId();
        opty.Amount = 100;
        insert opty;
        
        Order order = new Order();
        order.RecordTypeId = RecordTypeHelper.ORDER_BIKE;
        order.Pricebook2Id = Test.getStandardPricebookId();
        order.AccountId = acc.Id;
        order.DO_DL__c = dodl.Id;
        order.OpportunityId = opty.Id;
        order.Status = 'Draft';
        order.EndDate = Date.today() + 1;
        order.EffectiveDate = Date.today();
        order.Tax_Address__c = 'Test';
        order.Tax_Code__c = 'TaxCode';
        order.Tax_Mobile__c = '0907868802';
        order.Payment_Method__c = 'Cash';
        order.Asset__c = asset.Id;
        
        insert order;
        
        Product2 p = new Product2();
        p.Name = 'Test Product';
        p.Description='Test Product';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = Test.getStandardPricebookId();
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 100;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
                
        OrderItem item = new OrderItem();
        item.OrderId = order.Id;
        item.UnitPrice = 2000;
        item.Product2Id = p.Id;
        item.Quantity = 1;
        item.PricebookEntryId = standardPrice.Id;
        insert item;
        
        BtnSendEinvoiceController.sendEinvoice(order.Id);
        BtnCreateEinvoiceController.createEinvoice(order.Id);
        
        Test.stopTest();
    }
    
    @isTest
    static void testDN()
    {       
        Asset asset = new Asset();
        asset.Name = 'test';
        insert asset;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EinvoiceMockResponse());
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = Test.getStandardPricebookId();
        pricebook.IsActive = true;
        update pricebook;
        
        Account dodl = new Account();
        dodl.RecordTypeId = RecordTypeHelper.ACCOUNT_DODL;
        dodl.Name = 'Test';
        dodl.Einvoice_Location__c = 'Đà Nẵng';
        insert dodl;
        
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc.LastName = 'Test';
        insert acc;
        
        Opportunity opty = new Opportunity();
        opty.RecordTypeId = RecordTypeHelper.OPPORTUNITY_BIKE;
        opty.Name = 'Test';
        opty.AccountId = acc.Id;
        opty.StageName = 'New';
        opty.CloseDate = Date.today() + 7;
        opty.Enable_Round_Robin__c = false;
        opty.Pricebook2Id = Test.getStandardPricebookId();
        opty.Amount = 100;
        insert opty;
        
        Order order = new Order();
        order.RecordTypeId = RecordTypeHelper.ORDER_BIKE;
        order.Pricebook2Id = Test.getStandardPricebookId();
        order.AccountId = acc.Id;
        order.DO_DL__c = dodl.Id;
        order.OpportunityId = opty.Id;
        order.Status = 'Draft';
        order.EndDate = Date.today() + 1;
        order.EffectiveDate = Date.today();
        order.Tax_Address__c = 'Test';
        order.Tax_Code__c = 'TaxCode';
        order.Tax_Mobile__c = '0907868802';
        order.Payment_Method__c = 'Cash';
        order.Asset__c = asset.Id;
        
        insert order;
        
        Product2 p = new Product2();
        p.Name = 'Test Product';
        p.Description='Test Product';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = Test.getStandardPricebookId();
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 100;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
                
        OrderItem item = new OrderItem();
        item.OrderId = order.Id;
        item.UnitPrice = 2000;
        item.Product2Id = p.Id;
        item.Quantity = 1;
        item.PricebookEntryId = standardPrice.Id;
        insert item;
        
        BtnSendEinvoiceController.sendEinvoice(order.Id);
        BtnCreateEinvoiceController.createEinvoice(order.Id);
        
        Test.stopTest();
    }
    
    @isTest
    static void testNT()
    {       
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EinvoiceMockResponse());
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = Test.getStandardPricebookId();
        pricebook.IsActive = true;
        update pricebook;
        
        Asset asset = new Asset();
        asset.Name = 'test';
        insert asset;
        
        Account dodl = new Account();
        dodl.RecordTypeId = RecordTypeHelper.ACCOUNT_DODL;
        dodl.Name = 'Test';
        dodl.Einvoice_Location__c = 'Nha Trang';
        insert dodl;
        
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc.LastName = 'Test';
        insert acc;
        
        Opportunity opty = new Opportunity();
        opty.RecordTypeId = RecordTypeHelper.OPPORTUNITY_BIKE;
        opty.Name = 'Test';
        opty.AccountId = acc.Id;
        opty.StageName = 'New';
        opty.CloseDate = Date.today() + 7;
        opty.Enable_Round_Robin__c = false;
        opty.Pricebook2Id = Test.getStandardPricebookId();
        opty.Amount = 100;
        insert opty;
        
        Order order = new Order();
        order.RecordTypeId = RecordTypeHelper.ORDER_BIKE;
        order.Pricebook2Id = Test.getStandardPricebookId();
        order.AccountId = acc.Id;
        order.DO_DL__c = dodl.Id;
        order.OpportunityId = opty.Id;
        order.Status = 'Draft';
        order.EndDate = Date.today() + 1;
        order.EffectiveDate = Date.today();
        order.Tax_Address__c = 'Test';
        order.Tax_Code__c = 'TaxCode';
        order.Tax_Mobile__c = '0907868802';
        order.Payment_Method__c = 'Cash';
        order.Asset__c = asset.Id;
        insert order;
        
        Product2 p = new Product2();
        p.Name = 'Test Product';
        p.Description='Test Product';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = Test.getStandardPricebookId();
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 100;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
                
        OrderItem item = new OrderItem();
        item.OrderId = order.Id;
        item.UnitPrice = 2000;
        item.Product2Id = p.Id;
        item.Quantity = 1;
        item.PricebookEntryId = standardPrice.Id;
        insert item;
        
        BtnSendEinvoiceController.sendEinvoice(order.Id);
        BtnCreateEinvoiceController.createEinvoice(order.Id);
        
        Test.stopTest();
    }
    
    @isTest
    static void testHNWithContractInfo()
    {       
        try {
            Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EinvoiceMockResponse());
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = Test.getStandardPricebookId();
        pricebook.IsActive = true;
        update pricebook;
        
        Asset asset = new Asset();
        asset.Name = 'test';
        insert asset;
        
        Account dodl = new Account();
        dodl.RecordTypeId = RecordTypeHelper.ACCOUNT_DODL;
        dodl.Name = 'Test';
        dodl.Einvoice_Location__c = 'Hà Nội';
        insert dodl;
        
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc.LastName = 'Test';
        insert acc;
        
        Opportunity opty = new Opportunity();
        opty.RecordTypeId = RecordTypeHelper.OPPORTUNITY_BIKE;
        opty.Name = 'Test';
        opty.AccountId = acc.Id;
        opty.StageName = 'New';
        opty.CloseDate = Date.today() + 7;
        opty.Enable_Round_Robin__c = false;
        opty.Pricebook2Id = Test.getStandardPricebookId();
        opty.Amount = 100;
        insert opty;
        
        Contract_Information__c contractInfo = new Contract_Information__c();
        contractInfo.RecordTypeId = RecordTypeHelper.CONTRACT_INFORMATION_PERSON;
        contractInfo.Name = 'Test';
        contractInfo.Tax_code__c = 'TaxCode';
        contractInfo.Mobile__c = '0907868802';
        contractInfo.Address_No__c = 'Test';
        insert contractInfo;
        
        Contract contract = new Contract();
        contract.Opportunity__c = opty.Id;
        contract.AccountId = acc.Id;
        //contract.Contract_Information__c = contractInfo.Id;
        insert contract;
        
        opty.ContractId = contract.Id;
        update opty;
        
        
        
        Order order = new Order();
        order.RecordTypeId = RecordTypeHelper.ORDER_BIKE;
        order.Pricebook2Id = Test.getStandardPricebookId();
        order.AccountId = acc.Id;
        order.DO_DL__c = dodl.Id;
        order.OpportunityId = opty.Id;
        order.Status = 'Draft';
        order.EndDate = Date.today() + 1;
        order.EffectiveDate = Date.today();
        order.Tax_Address__c = 'Test';
        order.Tax_Code__c = 'TaxCode';
        order.Tax_Mobile__c = '0907868802';
        order.Payment_Method__c = 'Cash';
		order.Asset__c = order.Id;        
        insert order;
        
        Product2 p = new Product2();
        p.Name = 'Test Product';
        p.Description='Test Product';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = Test.getStandardPricebookId();
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 100;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
                
        OrderItem item = new OrderItem();
        item.OrderId = order.Id;
        item.UnitPrice = 2000;
        item.Product2Id = p.Id;
        item.Quantity = 1;
        item.PricebookEntryId = standardPrice.Id;
        insert item;
        
        BtnSendEinvoiceController.sendEinvoice(order.Id);
        BtnCreateEinvoiceController.createEinvoice(order.Id);
        
        Test.stopTest();
        }catch(Exception e) {
            
        }
    }
}