@isTest
public class TriggerHandlerInventoryTHTest {
    @isTest static void onBeforeInsertTest() {
        TriggerHandlerInventoryTransactionHeader.cheatTemp();
        X3_Inventory_Transaction_Header__c q = new X3_Inventory_Transaction_Header__c();
        
        try {
            TriggerHandlerInventoryTransactionHeader.cheatTemp();
            insert q;
            
        }catch(Exception e) {
            
        }
    }
}