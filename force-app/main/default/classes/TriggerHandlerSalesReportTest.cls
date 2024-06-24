@isTest
public class TriggerHandlerSalesReportTest {
	@isTest(seeAllData=true)
    static void test_getInitialData(){
        Test.startTest();
        List<Sales_Report__c> sl = [SELECT ID FROM Sales_Report__c WHERE JodID__c  = '707RB000004fNUdYAM'];
        update sl;
        Test.stopTest();
    }
    @isTest()
    static void test_getInitialData2(){
        
        Test.startTest();
        try {
            Sales_Report__c s = new Sales_Report__c();
            s.Name = 'Target';
            s.DO_Code__c = 'RY01A';
            s.Date_Scheduled__c = Date.newInstance(2022, 01,01);
        	insert s;
        }catch(Exception e) {
            
        }
        
        Test.stopTest();
    }
}