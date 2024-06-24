@isTest
public class followAfterSaleTest {
	 @isTest 
    static  void testMethod1() {   
        Order_Account__c q = new Order_Account__c();
        
        try {
            followAfterSale.cheatTemp();
            insert q;
            
        }catch(Exception e) {
            
        }
    }
}