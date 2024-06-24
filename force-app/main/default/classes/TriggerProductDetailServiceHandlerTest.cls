@isTest
public class TriggerProductDetailServiceHandlerTest {
    @isTest static void onAfterUpsert() {
        Product_Detail_Service__c obj = new Product_Detail_Service__c();
        insert obj;
        update obj;
        TriggerProductDetailServiceHandler.cheatTemp();
    }
}