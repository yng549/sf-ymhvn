@isTest
public class BatchSetOriginAmountInventoryTest {
	@isTest
    public static void test()
    {
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
        insert item;
        
        
        
        
        Database.executeBatch(new BatchSetOriginAmountInventory(),2000);
    }
}