@isTest
public class BatchKPIHelperTest {
	@isTest
    public static void test()
    {
        Monthly_KPI__c monthly = new Monthly_KPI__c();
        monthly.Month__c = Date.today().month();
        monthly.Year__c = Date.today().year();
        insert monthly;
        
        Database.executeBatch(new BatchKPIHelper(monthly.Id,1), 1);
        BatchKPIHelper.addpoint();
    }
}