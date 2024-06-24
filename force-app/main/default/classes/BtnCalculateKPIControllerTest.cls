@isTest
public class BtnCalculateKPIControllerTest {
	@isTest
    static void test()
    {    
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EinvoiceMockResponse());
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = Test.getStandardPricebookId();
        pricebook.IsActive = true;
        update pricebook;
        
        Contact contactSaleAM = new Contact();
        contactSaleAM.LastName = 'Test';
        insert contactSaleAM;
        
        Contact contactSaleSuper = new Contact();
        contactSaleSuper.LastName = 'Test';
        contactSaleSuper.Manager__c = contactSaleAM.Id;
        insert contactSaleSuper;
        
        Contact contactSales = new Contact();
        contactSales.LastName = 'test';
        contactSales.Manager__c = contactSaleSuper.Id;
        insert contactSales;
        
        
        
        
        
        UserRole ur = [SELECT Id FROM UserRole limit 1];
        
        Profile profile = [SELECT Id FROM Profile WHERE Name='Community Sale Profile'];
        
        /*User userSales = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                  EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                  LocaleSidKey='en_US', ProfileId = profile.Id, 
                                  TimeZoneSidKey='America/Los_Angeles', UserName='standarduser213@testorg.com',
                                  UserRoleId = ur.Id,ContactId = contactSales.Id);
        insert userSales;
        
        User userSaleSuper = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                      EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                      LocaleSidKey='en_US', ProfileId = profile.Id, 
                                      TimeZoneSidKey='America/Los_Angeles', UserName='standarduser321@testorg.com',
                                      UserRoleId = ur.Id , ContactId = contactSaleSuper.Id);
        insert userSaleSuper;
        
        User userSaleAM = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                   EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profile.Id, 
                                   TimeZoneSidKey='America/Los_Angeles', UserName='standarduser123@testorg.com',
                                   UserRoleId = ur.Id , ContactId = contactSaleAM.Id);
        insert userSaleAM;*/
        
        Contact contactSale = new Contact();
        
        
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
        
        Opportunity opty2 = new Opportunity();
        opty2.RecordTypeId = RecordTypeHelper.OPPORTUNITY_BIKE;
        opty2.Name = 'Test';
        opty2.AccountId = acc.Id;
        opty2.StageName = 'New';
        opty2.CloseDate = Date.today() + 7;
        opty2.Enable_Round_Robin__c = false;
        opty2.Pricebook2Id = Test.getStandardPricebookId();
        opty2.Amount = 100;
        opty2.CS_Review_Date__c = Date.today();
        opty2.Wrong_Info__c = 'Name';
        insert opty2;
        
        
        
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
        order.Invoice_Date__c = Date.today();
        order.TSI__c = 95;
        insert order;
        
        Order order2 = new Order();
        order2.RecordTypeId = RecordTypeHelper.ORDER_BIKE;
        order2.Pricebook2Id = Test.getStandardPricebookId();
        order2.AccountId = acc.Id;
        order2.DO_DL__c = dodl.Id;
        order2.OpportunityId = opty.Id;
        order2.Status = 'Draft';
        order2.EndDate = Date.today() + 1;
        order2.EffectiveDate = Date.today();
        order2.Tax_Address__c = 'Test';
        order2.Tax_Code__c = 'TaxCode';
        order2.Tax_Mobile__c = '0907868802';
        order2.Payment_Method__c = 'Cash';
        order2.Invoice_Date__c = Date.today();
        order2.TSI__c = 95;
        insert order2;
        
        SurveySales__c surveySales = new SurveySales__c();
        surveySales.Order__c = order.Id;
        surveySales.Question_0__c = 'No';
        surveySales.Question_1_CSI__c = '10';
        insert surveySales;
        
        
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
        
        KPI_Category_Management__c saleCategory = new KPI_Category_Management__c();
        saleCategory.Role__c = 'Sales Consultant';
        insert saleCategory;
        
        KPI_Category_Management__c saleSuperCategory = new KPI_Category_Management__c();
        saleSuperCategory.Role__c = 'Sales Supevisor';
        insert saleSuperCategory;
        
        KPI_Category_Management__c saleAMCategory = new KPI_Category_Management__c();
        saleAMCategory.Role__c = 'Sales AM/Manager';
        insert saleAMCategory;
        
        Monthly_KPI__c monthlyKPI = new Monthly_KPI__c();
        monthlyKPI.Month__c = Date.today().month();
        monthlyKPI.Year__c = Date.today().year();
        insert monthlyKPI;
        
        Monthly_KPI_Employee__c saleAM = new Monthly_KPI_Employee__c();
        saleAM.Employee__c = contactSaleAM.Id;
        saleAM.Monthly_KPI__c = monthlyKPI.Id;
        saleAM.KPI_Category_Management__c = saleAMCategory.Id;
        saleAM.KPI_Rule_1_Target__c = 1;
        saleAM.KPI_Rule_2_Target__c = 1;
        saleAM.KPI_Rule_3_Target__c = 1;
        saleAM.KPI_Rule_4_Target__c = 1;
        saleAM.KPI_Rule_5_Target__c = 1;
        saleAM.KPI_Rule_6_Target__c = 1;
        saleAM.KPI_Rule_1_Percent__c = 25;
        saleAM.KPI_Rule_2_Percent__c = 25;
        saleAM.KPI_Rule_3_Percent__c = 10;
        saleAM.KPI_Rule_4_Percent__c = 10;
        saleAM.KPI_Rule_5_Percent__c = 15;
        saleAM.KPI_Rule_6_Percent__c = 10;
        saleAM.KPI_Rule_3_Max_Percent__c = 10;
        saleAM.KPI_Rule_4_Max_Percent__c = 10;
        saleAM.KPI_Rule_5_Max_Percent__c = 15;
        saleAM.KPI_Rule_6_Max_Percent__c = 10;
        insert saleAM;
        
        Monthly_KPI_Employee__c saleSuper = new Monthly_KPI_Employee__c();
        saleSuper.Employee__c = contactSaleSuper.Id;
        saleSuper.Manager__c = saleAM.Id;
        saleSuper.Monthly_KPI__c = monthlyKPI.Id;
        saleSuper.KPI_Category_Management__c = saleSuperCategory.Id;
        saleSuper.KPI_Rule_1_Target__c = 1;
        saleSuper.KPI_Rule_2_Target__c = 1;
        saleSuper.KPI_Rule_3_Target__c = 1;
        saleSuper.KPI_Rule_4_Target__c = 1;
        saleSuper.KPI_Rule_5_Target__c = 1;
        saleSuper.KPI_Rule_6_Target__c = 1;
        saleSuper.KPI_Rule_7_Target__c = 1;
        saleSuper.KPI_Rule_1_Percent__c = 35;
        saleSuper.KPI_Rule_2_Percent__c = 10;
        saleSuper.KPI_Rule_3_Percent__c = 10;
        saleSuper.KPI_Rule_4_Percent__c = 10;
        saleSuper.KPI_Rule_5_Percent__c = 15;
        saleSuper.KPI_Rule_6_Percent__c = 10;
        saleSuper.KPI_Rule_7_Percent__c = 10;
        saleSuper.KPI_Rule_2_Max_Percent__c = 10;
        saleSuper.KPI_Rule_3_Max_Percent__c = 10;
        saleSuper.KPI_Rule_4_Max_Percent__c = 10;
        saleSuper.KPI_Rule_5_Max_Percent__c = 15;
        saleSuper.KPI_Rule_6_Max_Percent__c = 10;
        saleSuper.KPI_Rule_7_Max_Percent__c = 10;
        insert saleSuper;
        
        Monthly_KPI_Employee__c sale = new Monthly_KPI_Employee__c();
        sale.Employee__c = contactSales.Id;
        sale.Manager__c = saleSuper.Id;
        sale.Monthly_KPI__c = monthlyKPI.Id;
        sale.KPI_Category_Management__c = saleCategory.Id;
        sale.KPI_Rule_1_Target__c = 1;
        sale.KPI_Rule_2_Target__c = 1;
        sale.KPI_Rule_3_Target__c = 1;
        sale.KPI_Rule_4_Target__c = 1;
        sale.KPI_Rule_5_Target__c = 1;
        sale.KPI_Rule_6_Target__c = 1;
        sale.KPI_Rule_7_Target__c = 1;
        sale.KPI_Rule_1_Percent__c = 40;
        sale.KPI_Rule_2_Percent__c = 10;
        sale.KPI_Rule_3_Percent__c = 10;
        sale.KPI_Rule_4_Percent__c = 5;
        sale.KPI_Rule_5_Percent__c = 10;
        sale.KPI_Rule_6_Percent__c = 15;
        sale.KPI_Rule_7_Percent__c = 10;
        sale.KPI_Rule_2_Max_Percent__c = 10;
        sale.KPI_Rule_3_Max_Percent__c = 10;
        sale.KPI_Rule_4_Max_Percent__c = 5;
        sale.KPI_Rule_5_Max_Percent__c = 10;
        sale.KPI_Rule_6_Max_Percent__c = 15;
        sale.KPI_Rule_7_Max_Percent__c = 10;
        insert sale;
        
        
        
        
   
        
        
        BtnCalculateKPIController.callCalculate(monthlyKPI.Id);
          
        Test.stopTest();
    }
}