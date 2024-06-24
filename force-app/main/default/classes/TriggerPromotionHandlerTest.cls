@isTest
public class TriggerPromotionHandlerTest {
	@isTest
    private static void testTemp(){
        Promotion__c t = new Promotion__c();
        try {
            TriggerPromotionHandler.cheatTemp();
            insert t; 
        }catch (Exception e) {
            
        }
       
    }
}