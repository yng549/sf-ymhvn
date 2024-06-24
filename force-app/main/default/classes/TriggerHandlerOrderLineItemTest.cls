@isTest
public class TriggerHandlerOrderLineItemTest {
    
    
    static testMethod void testMethod1() {
        TriggerHandlerOrderLineItem.cheat();
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Sales Supevisor';
        insert category;
        
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = Test.getStandardPricebookId();
        pricebook.IsActive = true;
        update pricebook;
        
        Account dodl = new Account();
        dodl.RecordTypeId = RecordTypeHelper.ACCOUNT_DODL;
        dodl.Name = 'Test';
        dodl.Einvoice_Location__c = 'Hà Nội';
        insert dodl;
        
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc.LastName = 'Test';
        insert acc;
        
        Contact contact = new Contact();
        contact.LastName = 'Test';
        insert contact;
        
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
        
        
        
        Order order = new Order( RecordTypeId = RecordTypeHelper.ORDER_BIKE,
                                Pricebook2Id = Test.getStandardPricebookId(),
                                AccountId = acc.Id,
                                DO_DL__c = dodl.Id,
                                OpportunityId = opty.Id,
                                Status = 'Draft',
                                EndDate = Date.today() + 1,
                                EffectiveDate = Date.today(),
                                Tax_Address__c = 'Test',
                                Tax_Code__c = 'TaxCode',
                                Tax_Mobile__c = '0907868802',
                                Payment_Method__c = 'Cash',
                                Invoice_Date__c = Date.today());
        
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
        
        OrderItem item = new OrderItem(OrderId = order.Id,
                                       UnitPrice = 2000,
                                       Product2Id = p.Id,
                                       Quantity = 1,
                                       PricebookEntryId = standardPrice.Id);
        
        insert item;
        item.Discount__c = 60;
        update item;
        
        order.Manual_Discount_Approve__c = true;
        update order;
    }
    static testMethod void testMethod2() {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Sales Supevisor';
        insert category;
        
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = Test.getStandardPricebookId();
        pricebook.IsActive = true;
        update pricebook;
        
        Account dodl = new Account();
        dodl.RecordTypeId = RecordTypeHelper.ACCOUNT_DODL;
        dodl.Name = 'Test';
        dodl.Einvoice_Location__c = 'Hà Nội';
        insert dodl;
        
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc.LastName = 'Test';
        insert acc;
        
        Contact contact = new Contact();
        contact.LastName = 'Test';
        insert contact;
        
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
        
        Order order2 = new Order( RecordTypeId = RecordTypeHelper.ORDER_PCA,
                                 Pricebook2Id = Test.getStandardPricebookId(),
                                 AccountId = acc.Id,
                                 DO_DL__c = dodl.Id,
                                 OpportunityId = opty.Id,
                                 Status = 'Draft',
                                 EndDate = Date.today() + 1,
                                 EffectiveDate = Date.today(),
                                 Tax_Address__c = 'Test',
                                 Tax_Code__c = 'TaxCode',
                                 Tax_Mobile__c = '0907868802',
                                 Payment_Method__c = 'Cash',
                                 Invoice_Date__c = Date.today());
        
        insert order2;
        
        Order order3 = new Order( RecordTypeId = RecordTypeHelper.ORDER_SERVICE_ORDER,
                                 Pricebook2Id = Test.getStandardPricebookId(),
                                 AccountId = acc.Id,
                                 DO_DL__c = dodl.Id,
                                 OpportunityId = opty.Id,
                                 Status = 'Draft',
                                 EndDate = Date.today() + 1,
                                 EffectiveDate = Date.today(),
                                 Tax_Address__c = 'Test',
                                 Tax_Code__c = 'TaxCode',
                                 Tax_Mobile__c = '0907868802',
                                 Payment_Method__c = 'Cash',
                                 Invoice_Date__c = Date.today());
        
        insert order3;
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
        
        
        
        OrderItem item2 = new OrderItem(OrderId = order2.Id,
                                        UnitPrice = 2000,
                                        Product2Id = p.Id,
                                        Quantity = 1,
                                        PricebookEntryId = standardPrice.Id);
        
        insert item2;
        OrderItem item3 = new OrderItem(OrderId = order3.Id,
                                        UnitPrice = 2000,
                                        Product2Id = p.Id,
                                        Quantity = 1,
                                        PricebookEntryId = standardPrice.Id);
        
        insert item3;
        
        item2.Discount__c = 50;
        update item2;
        order2.Manual_Discount_Approve__c = true;
        update order2;
    }
    static testMethod void testMethod3() {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Sales Supevisor';
        insert category;
        
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = Test.getStandardPricebookId();
        pricebook.IsActive = true;
        update pricebook;
        
        Account dodl = new Account();
        dodl.RecordTypeId = RecordTypeHelper.ACCOUNT_DODL;
        dodl.Name = 'Test';
        dodl.Einvoice_Location__c = 'Hà Nội';
        insert dodl;
        
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc.LastName = 'Test';
        insert acc;
        
        Contact contact = new Contact();
        contact.LastName = 'Test';
        insert contact;
        
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
        
        Order order3 = new Order( RecordTypeId = RecordTypeHelper.ORDER_SERVICE_ORDER,
                                 Pricebook2Id = Test.getStandardPricebookId(),
                                 AccountId = acc.Id,
                                 DO_DL__c = dodl.Id,
                                 OpportunityId = opty.Id,
                                 Status = 'Draft',
                                 EndDate = Date.today() + 1,
                                 EffectiveDate = Date.today(),
                                 Tax_Address__c = 'Test',
                                 Tax_Code__c = 'TaxCode',
                                 Tax_Mobile__c = '0907868802',
                                 Payment_Method__c = 'Cash',
                                 Invoice_Date__c = Date.today());
        
        insert order3;
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
        
        OrderItem item3 = new OrderItem(OrderId = order3.Id,
                                        UnitPrice = 2000,
                                        Product2Id = p.Id,
                                        Quantity = 1,
                                        PricebookEntryId = standardPrice.Id);
        
        insert item3;
        item3.Discount__c = 50;
        update item3;
        order3.Manual_Discount_Approve__c = true;
        update order3;
    }
      static testMethod void testMethod4() {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Sales Supevisor';
        insert category;
        
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = Test.getStandardPricebookId();
        pricebook.IsActive = true;
        update pricebook;
        
        Account dodl = new Account();
        dodl.RecordTypeId = RecordTypeHelper.ACCOUNT_DODL;
        dodl.Name = 'Test';
        dodl.Einvoice_Location__c = 'Hà Nội';
        insert dodl;
        
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc.LastName = 'Test';
        insert acc;
        
        Contact contact = new Contact();
        contact.LastName = 'Test';
        insert contact;
        
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
        
        Order order = new Order( RecordTypeId = RecordTypeHelper.ORDER_BIKE,
                                Pricebook2Id = Test.getStandardPricebookId(),
                                AccountId = acc.Id,
                                DO_DL__c = dodl.Id,
                                OpportunityId = opty.Id,
                                Status = 'Draft',
                                EndDate = Date.today() + 1,
                                EffectiveDate = Date.today(),
                                Tax_Address__c = 'Test',
                                Tax_Code__c = 'TaxCode',
                                Tax_Mobile__c = '0907868802',
                                Payment_Method__c = 'Cash',
                                Invoice_Date__c = Date.today(),
                               	Manual_Discount_Approve__c = true);
        
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
        
        OrderItem item = new OrderItem(OrderId = order.Id,
                                       UnitPrice = 2000,
                                       Product2Id = p.Id,
                                       Quantity = 1,
                                       PricebookEntryId = standardPrice.Id);
        
        insert item;
        item.Discount__c = 60;
        update item;
    }
    static testMethod void testMethod5() {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Sales Supevisor';
        insert category;
        
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = Test.getStandardPricebookId();
        pricebook.IsActive = true;
        update pricebook;
        
        Account dodl = new Account();
        dodl.RecordTypeId = RecordTypeHelper.ACCOUNT_DODL;
        dodl.Name = 'Test';
        dodl.Einvoice_Location__c = 'Hà Nội';
        insert dodl;
        
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc.LastName = 'Test';
        insert acc;
        
        Contact contact = new Contact();
        contact.LastName = 'Test';
        insert contact;
        
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
        
        Order order2 = new Order( RecordTypeId = RecordTypeHelper.ORDER_PCA,
                                 Pricebook2Id = Test.getStandardPricebookId(),
                                 AccountId = acc.Id,
                                 DO_DL__c = dodl.Id,
                                 OpportunityId = opty.Id,
                                 Status = 'Draft',
                                 EndDate = Date.today() + 1,
                                 EffectiveDate = Date.today(),
                                 Tax_Address__c = 'Test',
                                 Tax_Code__c = 'TaxCode',
                                 Tax_Mobile__c = '0907868802',
                                 Payment_Method__c = 'Cash',
                                 Invoice_Date__c = Date.today(),
                                 Manual_Discount_Approve__c = true);
        
        insert order2;
        
        Order order3 = new Order( RecordTypeId = RecordTypeHelper.ORDER_SERVICE_ORDER,
                                 Pricebook2Id = Test.getStandardPricebookId(),
                                 AccountId = acc.Id,
                                 DO_DL__c = dodl.Id,
                                 OpportunityId = opty.Id,
                                 Status = 'Draft',
                                 EndDate = Date.today() + 1,
                                 EffectiveDate = Date.today(),
                                 Tax_Address__c = 'Test',
                                 Tax_Code__c = 'TaxCode',
                                 Tax_Mobile__c = '0907868802',
                                 Payment_Method__c = 'Cash',
                                 Invoice_Date__c = Date.today());
        
        insert order3;
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
        
        
        
        OrderItem item2 = new OrderItem(OrderId = order2.Id,
                                        UnitPrice = 2000,
                                        Product2Id = p.Id,
                                        Quantity = 1,
                                        PricebookEntryId = standardPrice.Id);
        
        insert item2;
        OrderItem item3 = new OrderItem(OrderId = order3.Id,
                                        UnitPrice = 2000,
                                        Product2Id = p.Id,
                                        Quantity = 1,
                                        PricebookEntryId = standardPrice.Id);
        
        insert item3;
        
        item2.Discount__c = 50;
        update item2;
        order2.Manual_Discount_Approve__c = true;
        update order2;
    }
    static testMethod void testMethod6() {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Sales Supevisor';
        insert category;
        
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = Test.getStandardPricebookId();
        pricebook.IsActive = true;
        update pricebook;
        
        Account dodl = new Account();
        dodl.RecordTypeId = RecordTypeHelper.ACCOUNT_DODL;
        dodl.Name = 'Test';
        dodl.Einvoice_Location__c = 'Hà Nội';
        insert dodl;
        
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc.LastName = 'Test';
        insert acc;
        
        Contact contact = new Contact();
        contact.LastName = 'Test';
        insert contact;
        
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
        
        Order order3 = new Order( RecordTypeId = RecordTypeHelper.ORDER_SERVICE_ORDER,
                                 Pricebook2Id = Test.getStandardPricebookId(),
                                 AccountId = acc.Id,
                                 DO_DL__c = dodl.Id,
                                 OpportunityId = opty.Id,
                                 Status = 'Draft',
                                 EndDate = Date.today() + 1,
                                 EffectiveDate = Date.today(),
                                 Tax_Address__c = 'Test',
                                 Tax_Code__c = 'TaxCode',
                                 Tax_Mobile__c = '0907868802',
                                 Payment_Method__c = 'Cash',
                                 Invoice_Date__c = Date.today(),
                                 Manual_Discount_Approve__c = true);
        
        insert order3;
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
        
        OrderItem item3 = new OrderItem(OrderId = order3.Id,
                                        UnitPrice = 2000,
                                        Product2Id = p.Id,
                                        Quantity = 1,
                                        PricebookEntryId = standardPrice.Id);
        
        insert item3;
        item3.Discount__c = 50;
        update item3;
        order3.Manual_Discount_Approve__c = true;
        update order3;
    }
}