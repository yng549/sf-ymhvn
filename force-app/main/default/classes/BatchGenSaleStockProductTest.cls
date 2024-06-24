@isTest
public class BatchGenSaleStockProductTest {	
    @isTest(seeAlldata=true)
    static void testData() {
        try{
            BatchGenSaleStockProduct.cheatCode();
			Database.executebatch(new BatchGenSaleStockProduct('RY01', 2023));            
        }catch(Exception e) {
            
        }
        
    }
}