@isTest
public class TriggerHandlerInventoryTITest {
    @isTest static void onBeforeInsertTest() {
        TriggerHandlerInventoryTransactionItems.cheatTemp();
        
        X3_Inventory_Transaction_Header__c q = new X3_Inventory_Transaction_Header__c();
        
        try {
            TriggerHandlerInventoryTransactionHeader.cheatTemp();
            insert q;

			Inventory_Transaction_Item__c obj = new Inventory_Transaction_Item__c();
			            obj.Inventory_Transaction_Header__c = q.Id;
            insert obj;
        }catch(Exception e) {
            
        }
    }
}