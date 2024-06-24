@isTest(SeeAllData = True)
public class SyncModelPricingDMSTest {
	
    @isTest
    static void testMethod1() {
		String jsonreq = '{\"msg\":\"Requestsucceed.\",\"code\":200,\"data\":[{\"ModelCode\":\"B7N800010C\",\"ModelName\":\"MT-09Xám-Đen\",\"Displacement\":\"900\",\"EmployeePrice\":3500000,\"RetailPrice\":370000000},{\"ModelCode\":\"B5U200010B\",\"ModelName\":\"TRACER9\",\"Displacement\":\"700\",\"EmployeePrice\":400000,\"RetailPrice\":380000000}],\"totalLine\":2}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsonreq);
        Test.startTest();
        System.schedule('Auto Sync MCPrice DMS', '0 30 6 * * ?', new ScheduleSyncModelPricingDMS());
        Test.stopTest();
    }
    @isTest
    static void testMethodTest() {
		
        Test.startTest();
        System.schedule('Auto Sync MCPrice HN 1', '0 30 6 * * ?', new ScheduleModelPricingHN());
        Test.stopTest();
    }
}