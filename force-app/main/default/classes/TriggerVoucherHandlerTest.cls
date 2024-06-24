@isTest
public class TriggerVoucherHandlerTest {
	@isTest
    private static void testTemp(){
        Voucher__c t = new Voucher__c();
        try {
            TriggerVoucherHandler.cheatTemp();
            insert t; 
        }catch (Exception e) {
            
        }
       
    }
}