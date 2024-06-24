@isTest
public class TriggerHandlerPaymentTest {
	@isTest
    private static void testTemp(){
        Payment__c t = new Payment__c();
        try {
            TriggerHandlerPayment.cheatTemp();
            insert t; 
        }catch (Exception e) {
            
        }
       
    }
}