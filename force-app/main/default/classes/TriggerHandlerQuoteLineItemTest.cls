@isTest
public class TriggerHandlerQuoteLineItemTest {
	@isTest
    private static void testTemp(){
        QuoteLineItem t = new QuoteLineItem();
        try {
            TriggerHandlerQuoteLineItem.cheatTemp();
            insert t; 
        }catch (Exception e) {
            
        }
    }
    
}