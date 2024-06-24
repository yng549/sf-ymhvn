@isTest
public class ScheduleKPIHelperTest {
	@isTest
    static void test()
    {
        Account acc = new Account();
        acc.Name = 'test';
        acc.DO_DL_Code__c = 'RY01A - SG';
        insert acc;
        
        Test.startTest();
        Monthly_KPI__c monthly = new Monthly_KPI__c();
		monthly.Name = 'Test';
		monthly.Month__c = Date.today().month();
		monthly.Year__c = Date.today().year();
        monthly.DO_DL__c = acc.Id;
		insert monthly;        
        
        ScheduleKPIHelper.startSchedule('Test Kpi Calculate 1');        
        Test.stopTest();
    }
    
    @isTest
    static void test2()
    {
        Account acc = new Account();
        acc.Name = 'test';
        acc.DO_DL_Code__c = 'RY02A - HN';
        insert acc; 
        
        Test.startTest();
        Monthly_KPI__c monthly = new Monthly_KPI__c();
		monthly.Name = 'Test';
		monthly.Month__c = Date.today().month();
		monthly.Year__c = Date.today().year();
        monthly.DO_DL__c = acc.Id;
		insert monthly;        
        
        ScheduleKPIHelperDO2.startSchedule('Test Kpi Calculate 2');        
        Test.stopTest();
    }
}