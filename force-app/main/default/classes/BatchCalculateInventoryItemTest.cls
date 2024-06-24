@isTest
public class BatchCalculateInventoryItemTest {
    @isTest
    public static void test()
    {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EinvoiceMockResponse());
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = Test.getStandardPricebookId();
        pricebook.IsActive = true;
        update pricebook;
        
        Product2 p = new Product2();
        p.Name = 'Test Product';
        p.Description='Test Product';
        p.productCode = 'ABC';
        p.isActive = true;
        p.RecordTypeId = RecordTypeHelper.PRODUCT_PCA;
        insert p;
        
        X3_Inventory_Transaction_Header__c header = new X3_Inventory_Transaction_Header__c();
        //header.Header_Type__c = 'Input';
        header.Status__c = 'Completed';
        insert header;
        
        
        Inventory_Transaction_Item__c item = new Inventory_Transaction_Item__c();
        item.Inventory_Transaction_Header__c = header.Id;
        item.Product__c = p.Id;
        item.Quantity_Amount_Remaing_KPI__c = 100;
        insert item;
        
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
        
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = Test.getStandardPricebookId();
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 100;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
                
        OrderItem oItem = new OrderItem();
        oItem.OrderId = order.Id;
        oItem.UnitPrice = 2000;
        oItem.Product2Id = p.Id;
        oItem.Quantity = 1;
        oItem.PricebookEntryId = standardPrice.Id;  
        oItem.Is_Calculate_Stock__c = false;
        insert oItem;
        
        Database.executeBatch(new BatchCalculateInventoryItem(),200);
        Test.stopTest();
    }
}