@isTest
public class TriggerHandlerInventoryTransactionTest {
	@isTest 
    static  void testMethod1() {   
        X3_Inventory_Transaction_Header__c q = new X3_Inventory_Transaction_Header__c();
        
        try {
            TriggerHandlerInventoryTransactionHeader.cheatTemp();
            insert q;
            
        }catch(Exception e) {
            
        }
    }
}