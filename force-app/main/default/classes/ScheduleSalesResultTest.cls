@isTest
public class ScheduleSalesResultTest {
	@isTest(seeAllData=true)
    static void onAfterUpsert() {
        try{
            system.schedule('Test 124', '0 0 23 * * ?', new ScheduleSalesResult());
        }catch(Exception e) {
            
        }
       
    }
}