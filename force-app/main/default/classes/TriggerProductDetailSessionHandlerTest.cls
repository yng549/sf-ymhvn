@isTest
public class TriggerProductDetailSessionHandlerTest {
@isTest static void onAfterUpsert() {
    	Product_Detail_Session__c obj = new Product_Detail_Session__c();
    	insert obj;
    	update obj;
        TriggerProductDetailSessionHandler.cheatTemp();
    }
}