@isTest
public class KPIHelperTest {
    @isTest
    public static void testBtn()
    {
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        BtnCalculateKPIController.callCalculate(month.Id);
    }
    
    /*@isTest
    public static void testCal()
    {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Sales Consultant';
        insert category;
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        employee.KPI_Rule_1_Target__c = 1;
        employee.KPI_Rule_1_Value__c = 1;
        employee.KPI_Rule_1_Percent__c = 1;
        employee.KPI_Rule_2_Target__c = 1;
        employee.KPI_Rule_2_Value__c = 1;
        employee.KPI_Rule_2_Percent__c = 1;
        employee.KPI_Rule_2_Max_Percent__c = 1;
        employee.KPI_Rule_3_Target__c = 1;
        employee.KPI_Rule_3_Value__c = 1;
        employee.KPI_Rule_3_Percent__c = 1;
        employee.KPI_Rule_3_Max_Percent__c = 1;
        employee.KPI_Rule_4_Target__c = 1;
        employee.KPI_Rule_4_Value__c = 1;
        employee.KPI_Rule_4_Percent__c = 1;
        employee.KPI_Rule_4_Max_Percent__c = 1;
        employee.KPI_Rule_5_Target__c = 1;
        employee.KPI_Rule_5_Value__c = 1;
        employee.KPI_Rule_5_Percent__c = 1;
        employee.KPI_Rule_5_Max_Percent__c = 1;
        employee.KPI_Rule_6_Target__c = 1;
        employee.KPI_Rule_6_Value__c = 1;
        employee.KPI_Rule_6_Percent__c = 1;
        employee.KPI_Rule_6_Max_Percent__c = 1;
        employee.KPI_Rule_7_Target__c = 1;
        employee.KPI_Rule_7_Value__c = 1;
        employee.KPI_Rule_7_Percent__c = 1;
        employee.KPI_Rule_7_Max_Percent__c = 1;
        employee.Promo_In_Rate__c = 10;
        employee.Promo_Out_Rate__c = 10;
        employee.Used_Bike_Rate__c = 10;
        employee.E_Commerce_Rate__c = 10;
        insert employee;
        
        KPIHelper.calSalesConsultant(employee);
        KPIHelper.calSalesSuper(employee);
        KPIHelper.calSaleAM(employee);
        KPIHelper.calServiceConsultant(employee);
        KPIHelper.calAllTech(employee);
        KPIHelper.calServiceAM(employee);
        KPIHelper.calPCAConsultant(employee);
        KPIHelper.calPCASuper(employee);
        
        Monthly_KPI_Employee__c employee2 = new Monthly_KPI_Employee__c();
        employee2.Monthly_KPI__c = month.Id;
        employee2.KPI_Category_Management__c = category.Id;
        employee2.KPI_Rule_1_Target__c = 100;
        employee2.KPI_Rule_1_Value__c = 100;
        employee2.KPI_Rule_1_Percent__c = 100;
        employee2.KPI_Rule_2_Target__c = 100;
        employee2.KPI_Rule_2_Value__c = 100;
        employee2.KPI_Rule_2_Percent__c = 100;
        employee2.KPI_Rule_2_Max_Percent__c = 100;
        employee2.KPI_Rule_3_Target__c = 100;
        employee2.KPI_Rule_3_Value__c = 100;
        employee2.KPI_Rule_3_Percent__c = 100;
        employee2.KPI_Rule_3_Max_Percent__c = 100;
        employee2.KPI_Rule_4_Target__c = 100;
        employee2.KPI_Rule_4_Value__c = 100;
        employee2.KPI_Rule_4_Percent__c = 100;
        employee2.KPI_Rule_4_Max_Percent__c = 100;
        employee2.KPI_Rule_5_Target__c = 100;
        employee2.KPI_Rule_5_Value__c = 100;
        employee2.KPI_Rule_5_Percent__c = 100;
        employee2.KPI_Rule_5_Max_Percent__c = 100;
        employee2.KPI_Rule_6_Target__c = 100;
        employee2.KPI_Rule_6_Value__c = 100;
        employee2.KPI_Rule_6_Percent__c = 100;
        employee2.KPI_Rule_6_Max_Percent__c = 100;
        employee2.KPI_Rule_7_Target__c = 100;
        employee2.KPI_Rule_7_Value__c = 100;
        employee2.KPI_Rule_7_Percent__c = 100;
        employee2.KPI_Rule_7_Max_Percent__c = 100;
        employee2.Promo_In_Rate__c = 10;
        employee2.Promo_Out_Rate__c = 10;
        employee2.Used_Bike_Rate__c = 10;
        employee2.E_Commerce_Rate__c = 10;
        insert employee2;
        
        KPIHelper.calSalesConsultant(employee2);
        KPIHelper.calSalesSuper(employee2);
        KPIHelper.calSaleAM(employee2);
        KPIHelper.calServiceConsultant(employee2);
        KPIHelper.calAllTech(employee2);
        KPIHelper.calServiceAM(employee2);
        KPIHelper.calPCAConsultant(employee2);
        KPIHelper.calPCASuper(employee2);
    }*/
    
    @isTest 
    public static void testSale()
    {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Sales Consultant';
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
        order.Invoice_Date__c = Date.today();
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
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        employee.KPI_Rule_1_Target__c = 1;
        employee.KPI_Rule_1_Value__c = 1;
        employee.KPI_Rule_1_Percent__c = 1;
        employee.KPI_Rule_2_Target__c = 1;
        employee.KPI_Rule_2_Value__c = 1;
        employee.KPI_Rule_2_Percent__c = 1;
        employee.KPI_Rule_2_Max_Percent__c = 1;
        employee.KPI_Rule_3_Target__c = 1;
        employee.KPI_Rule_3_Value__c = 1;
        employee.KPI_Rule_3_Percent__c = 1;
        employee.KPI_Rule_3_Max_Percent__c = 1;
        employee.KPI_Rule_4_Target__c = 1;
        employee.KPI_Rule_4_Value__c = 1;
        employee.KPI_Rule_4_Percent__c = 1;
        employee.KPI_Rule_4_Max_Percent__c = 1;
        employee.KPI_Rule_5_Target__c = 1;
        employee.KPI_Rule_5_Value__c = 1;
        employee.KPI_Rule_5_Percent__c = 1;
        employee.KPI_Rule_5_Max_Percent__c = 1;
        employee.KPI_Rule_6_Target__c = 1;
        employee.KPI_Rule_6_Value__c = 1;
        employee.KPI_Rule_6_Percent__c = 1;
        employee.KPI_Rule_6_Max_Percent__c = 1;
        employee.KPI_Rule_7_Target__c = 1;
        employee.KPI_Rule_7_Value__c = 1;
        employee.KPI_Rule_7_Percent__c = 1;
        employee.KPI_Rule_7_Max_Percent__c = 1;
        employee.Promo_In_Rate__c = 10;
        employee.Promo_Out_Rate__c = 10;
        employee.Used_Bike_Rate__c = 10;
        employee.E_Commerce_Rate__c = 10;
        insert employee;
        
        KPIHelper.startCalculate(month.Id,new List<Monthly_KPI_Employee__c>{employee});
        
        
    }
    
    @isTest 
    public static void testSaleSuper()
    {
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
        order.Invoice_Date__c = Date.today();
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
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        employee.KPI_Rule_1_Target__c = 1;
        employee.KPI_Rule_1_Value__c = 1;
        employee.KPI_Rule_1_Percent__c = 1;
        employee.KPI_Rule_2_Target__c = 1;
        employee.KPI_Rule_2_Value__c = 1;
        employee.KPI_Rule_2_Percent__c = 1;
        employee.KPI_Rule_2_Max_Percent__c = 1;
        employee.KPI_Rule_3_Target__c = 1;
        employee.KPI_Rule_3_Value__c = 1;
        employee.KPI_Rule_3_Percent__c = 1;
        employee.KPI_Rule_3_Max_Percent__c = 1;
        employee.KPI_Rule_4_Target__c = 1;
        employee.KPI_Rule_4_Value__c = 1;
        employee.KPI_Rule_4_Percent__c = 1;
        employee.KPI_Rule_4_Max_Percent__c = 1;
        employee.KPI_Rule_5_Target__c = 1;
        employee.KPI_Rule_5_Value__c = 1;
        employee.KPI_Rule_5_Percent__c = 1;
        employee.KPI_Rule_5_Max_Percent__c = 1;
        employee.KPI_Rule_6_Target__c = 1;
        employee.KPI_Rule_6_Value__c = 1;
        employee.KPI_Rule_6_Percent__c = 1;
        employee.KPI_Rule_6_Max_Percent__c = 1;
        employee.KPI_Rule_7_Target__c = 1;
        employee.KPI_Rule_7_Value__c = 1;
        employee.KPI_Rule_7_Percent__c = 1;
        employee.KPI_Rule_7_Max_Percent__c = 1;
        employee.Promo_In_Rate__c = 10;
        employee.Promo_Out_Rate__c = 10;
        employee.Used_Bike_Rate__c = 10;
        employee.E_Commerce_Rate__c = 10;
        insert employee;
        
        KPIHelper.startCalculate(month.Id,new List<Monthly_KPI_Employee__c>{employee});
        
        
    }
    
    @isTest 
    public static void testSaleAM()
    {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Sales AM/Manager';
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
        order.Invoice_Date__c = Date.today();
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
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        employee.KPI_Rule_1_Target__c = 1;
        employee.KPI_Rule_1_Value__c = 1;
        employee.KPI_Rule_1_Percent__c = 1;
        employee.KPI_Rule_2_Target__c = 1;
        employee.KPI_Rule_2_Value__c = 1;
        employee.KPI_Rule_2_Percent__c = 1;
        employee.KPI_Rule_2_Max_Percent__c = 1;
        employee.KPI_Rule_3_Target__c = 1;
        employee.KPI_Rule_3_Value__c = 1;
        employee.KPI_Rule_3_Percent__c = 1;
        employee.KPI_Rule_3_Max_Percent__c = 1;
        employee.KPI_Rule_4_Target__c = 1;
        employee.KPI_Rule_4_Value__c = 1;
        employee.KPI_Rule_4_Percent__c = 1;
        employee.KPI_Rule_4_Max_Percent__c = 1;
        employee.KPI_Rule_5_Target__c = 1;
        employee.KPI_Rule_5_Value__c = 1;
        employee.KPI_Rule_5_Percent__c = 1;
        employee.KPI_Rule_5_Max_Percent__c = 1;
        employee.KPI_Rule_6_Target__c = 1;
        employee.KPI_Rule_6_Value__c = 1;
        employee.KPI_Rule_6_Percent__c = 1;
        employee.KPI_Rule_6_Max_Percent__c = 1;
        employee.KPI_Rule_7_Target__c = 1;
        employee.KPI_Rule_7_Value__c = 1;
        employee.KPI_Rule_7_Percent__c = 1;
        employee.KPI_Rule_7_Max_Percent__c = 1;
        employee.Promo_In_Rate__c = 10;
        employee.Promo_Out_Rate__c = 10;
        employee.Used_Bike_Rate__c = 10;
        employee.E_Commerce_Rate__c = 10;
        insert employee;
        
        KPIHelper.startCalculate(month.Id,new List<Monthly_KPI_Employee__c>{employee});
        
        
    }
    
    @isTest 
    public static void testServiceConsultant()
    {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Service Consultant';
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
        order.RecordTypeId = RecordTypeHelper.ORDER_SERVICE_ORDER;
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
        order.Bike_Delivery_Date__c = Date.today();
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
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        employee.KPI_Rule_1_Target__c = 1;
        employee.KPI_Rule_1_Value__c = 1;
        employee.KPI_Rule_1_Percent__c = 1;
        employee.KPI_Rule_2_Target__c = 1;
        employee.KPI_Rule_2_Value__c = 1;
        employee.KPI_Rule_2_Percent__c = 1;
        employee.KPI_Rule_2_Max_Percent__c = 1;
        employee.KPI_Rule_3_Target__c = 1;
        employee.KPI_Rule_3_Value__c = 1;
        employee.KPI_Rule_3_Percent__c = 1;
        employee.KPI_Rule_3_Max_Percent__c = 1;
        employee.KPI_Rule_4_Target__c = 1;
        employee.KPI_Rule_4_Value__c = 1;
        employee.KPI_Rule_4_Percent__c = 1;
        employee.KPI_Rule_4_Max_Percent__c = 1;
        employee.KPI_Rule_5_Target__c = 1;
        employee.KPI_Rule_5_Value__c = 1;
        employee.KPI_Rule_5_Percent__c = 1;
        employee.KPI_Rule_5_Max_Percent__c = 1;
        employee.KPI_Rule_6_Target__c = 1;
        employee.KPI_Rule_6_Value__c = 1;
        employee.KPI_Rule_6_Percent__c = 1;
        employee.KPI_Rule_6_Max_Percent__c = 1;
        employee.KPI_Rule_7_Target__c = 1;
        employee.KPI_Rule_7_Value__c = 1;
        employee.KPI_Rule_7_Percent__c = 1;
        employee.KPI_Rule_7_Max_Percent__c = 1;
        employee.Service_Hour_Rate__c = 10;
        employee.Part_Rate__c = 10;
        employee.A_A_Rate__c = 10;
        insert employee;
        
        KPIHelper.startCalculate(month.Id,new List<Monthly_KPI_Employee__c>{employee});
        
        
    }
    
    @isTest 
    public static void testTech()
    {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Service Technician';
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
        order.RecordTypeId = RecordTypeHelper.ORDER_SERVICE_ORDER;
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
        order.Bike_Delivery_Date__c = Date.today();
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
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        employee.KPI_Rule_1_Target__c = 1;
        employee.KPI_Rule_1_Value__c = 1;
        employee.KPI_Rule_1_Percent__c = 1;
        employee.KPI_Rule_2_Target__c = 1;
        employee.KPI_Rule_2_Value__c = 1;
        employee.KPI_Rule_2_Percent__c = 1;
        employee.KPI_Rule_2_Max_Percent__c = 1;
        employee.KPI_Rule_3_Target__c = 1;
        employee.KPI_Rule_3_Value__c = 1;
        employee.KPI_Rule_3_Percent__c = 1;
        employee.KPI_Rule_3_Max_Percent__c = 1;
        employee.KPI_Rule_4_Target__c = 1;
        employee.KPI_Rule_4_Value__c = 1;
        employee.KPI_Rule_4_Percent__c = 1;
        employee.KPI_Rule_4_Max_Percent__c = 1;
        employee.KPI_Rule_5_Target__c = 1;
        employee.KPI_Rule_5_Value__c = 1;
        employee.KPI_Rule_5_Percent__c = 1;
        employee.KPI_Rule_5_Max_Percent__c = 1;
        employee.KPI_Rule_6_Target__c = 1;
        employee.KPI_Rule_6_Value__c = 1;
        employee.KPI_Rule_6_Percent__c = 1;
        employee.KPI_Rule_6_Max_Percent__c = 1;
        employee.KPI_Rule_7_Target__c = 1;
        employee.KPI_Rule_7_Value__c = 1;
        employee.KPI_Rule_7_Percent__c = 1;
        employee.KPI_Rule_7_Max_Percent__c = 1;
        employee.Service_Hour_Rate__c = 10;
        employee.Part_Rate__c = 10;
        employee.A_A_Rate__c = 10;
        insert employee;
        
        KPIHelper.startCalculate(month.Id,new List<Monthly_KPI_Employee__c>{employee});
        
        
    }
    
    @isTest 
    public static void testServiceAM()
    {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Service AM/Sup';
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
        order.RecordTypeId = RecordTypeHelper.ORDER_SERVICE_ORDER;
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
        order.Bike_Delivery_Date__c = Date.today();
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
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        employee.KPI_Rule_1_Target__c = 1;
        employee.KPI_Rule_1_Value__c = 1;
        employee.KPI_Rule_1_Percent__c = 1;
        employee.KPI_Rule_2_Target__c = 1;
        employee.KPI_Rule_2_Value__c = 1;
        employee.KPI_Rule_2_Percent__c = 1;
        employee.KPI_Rule_2_Max_Percent__c = 1;
        employee.KPI_Rule_3_Target__c = 1;
        employee.KPI_Rule_3_Value__c = 1;
        employee.KPI_Rule_3_Percent__c = 1;
        employee.KPI_Rule_3_Max_Percent__c = 1;
        employee.KPI_Rule_4_Target__c = 1;
        employee.KPI_Rule_4_Value__c = 1;
        employee.KPI_Rule_4_Percent__c = 1;
        employee.KPI_Rule_4_Max_Percent__c = 1;
        employee.KPI_Rule_5_Target__c = 1;
        employee.KPI_Rule_5_Value__c = 1;
        employee.KPI_Rule_5_Percent__c = 1;
        employee.KPI_Rule_5_Max_Percent__c = 1;
        employee.KPI_Rule_6_Target__c = 1;
        employee.KPI_Rule_6_Value__c = 1;
        employee.KPI_Rule_6_Percent__c = 1;
        employee.KPI_Rule_6_Max_Percent__c = 1;
        employee.KPI_Rule_7_Target__c = 1;
        employee.KPI_Rule_7_Value__c = 1;
        employee.KPI_Rule_7_Percent__c = 1;
        employee.KPI_Rule_7_Max_Percent__c = 1;
        employee.Service_Hour_Rate__c = 10;
        employee.Part_Rate__c = 10;
        employee.A_A_Rate__c = 10;
        insert employee;
        
        KPIHelper.startCalculate(month.Id,new List<Monthly_KPI_Employee__c>{employee});
        
        
    }
    
    @isTest 
    public static void testPCAConsultant()
    {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'PCA Sales Consultant';
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
        order.RecordTypeId = RecordTypeHelper.ORDER_PCA;
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
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        employee.KPI_Rule_1_Target__c = 1;
        employee.KPI_Rule_1_Value__c = 1;
        employee.KPI_Rule_1_Percent__c = 1;
        employee.KPI_Rule_2_Target__c = 1;
        employee.KPI_Rule_2_Value__c = 1;
        employee.KPI_Rule_2_Percent__c = 1;
        employee.KPI_Rule_2_Max_Percent__c = 1;
        employee.KPI_Rule_3_Target__c = 1;
        employee.KPI_Rule_3_Value__c = 1;
        employee.KPI_Rule_3_Percent__c = 1;
        employee.KPI_Rule_3_Max_Percent__c = 1;
        employee.KPI_Rule_4_Target__c = 1;
        employee.KPI_Rule_4_Value__c = 1;
        employee.KPI_Rule_4_Percent__c = 1;
        employee.KPI_Rule_4_Max_Percent__c = 1;
        employee.KPI_Rule_5_Target__c = 1;
        employee.KPI_Rule_5_Value__c = 1;
        employee.KPI_Rule_5_Percent__c = 1;
        employee.KPI_Rule_5_Max_Percent__c = 1;
        employee.KPI_Rule_6_Target__c = 1;
        employee.KPI_Rule_6_Value__c = 1;
        employee.KPI_Rule_6_Percent__c = 1;
        employee.KPI_Rule_6_Max_Percent__c = 1;
        employee.KPI_Rule_7_Target__c = 1;
        employee.KPI_Rule_7_Value__c = 1;
        employee.KPI_Rule_7_Percent__c = 1;
        employee.KPI_Rule_7_Max_Percent__c = 1;
        employee.Part_Rate__c = 10;
        employee.A_A_Rate__c = 10;
        employee.Part_Service_Rate__c = 10;
        employee.A_A_Service_Rate__c = 10;
        insert employee;
        
        KPIHelper.startCalculate(month.Id,new List<Monthly_KPI_Employee__c>{employee});
        
        
    }
    
    @isTest 
    public static void testPCASuper()
    {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'PCA Supervisor';
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
        order.RecordTypeId = RecordTypeHelper.ORDER_PCA;
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
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        employee.KPI_Rule_1_Target__c = 1;
        employee.KPI_Rule_1_Value__c = 1;
        employee.KPI_Rule_1_Percent__c = 1;
        employee.KPI_Rule_2_Target__c = 1;
        employee.KPI_Rule_2_Value__c = 1;
        employee.KPI_Rule_2_Percent__c = 1;
        employee.KPI_Rule_2_Max_Percent__c = 1;
        employee.KPI_Rule_3_Target__c = 1;
        employee.KPI_Rule_3_Value__c = 1;
        employee.KPI_Rule_3_Percent__c = 1;
        employee.KPI_Rule_3_Max_Percent__c = 1;
        employee.KPI_Rule_4_Target__c = 1;
        employee.KPI_Rule_4_Value__c = 1;
        employee.KPI_Rule_4_Percent__c = 1;
        employee.KPI_Rule_4_Max_Percent__c = 1;
        employee.KPI_Rule_5_Target__c = 1;
        employee.KPI_Rule_5_Value__c = 1;
        employee.KPI_Rule_5_Percent__c = 1;
        employee.KPI_Rule_5_Max_Percent__c = 1;
        employee.KPI_Rule_6_Target__c = 1;
        employee.KPI_Rule_6_Value__c = 1;
        employee.KPI_Rule_6_Percent__c = 1;
        employee.KPI_Rule_6_Max_Percent__c = 1;
        employee.KPI_Rule_7_Target__c = 1;
        employee.KPI_Rule_7_Value__c = 1;
        employee.KPI_Rule_7_Percent__c = 1;
        employee.KPI_Rule_7_Max_Percent__c = 1;
        employee.Part_Rate__c = 10;
        employee.A_A_Rate__c = 10;
        employee.Part_Service_Rate__c = 10;
        employee.A_A_Service_Rate__c = 10;
        insert employee;
        
        KPIHelper.startCalculate(month.Id,new List<Monthly_KPI_Employee__c>{employee});
        
        
    }
    
	@isTest
    public static void addPoint()
    {
       KPIHelper.addPoint();
    }
}