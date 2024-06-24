@isTest
public class SyncVATListDMSTest {
	@isTest(SeeAllData=true) 
    static void testAPIBooking() {
        String jsondata = '{\"msg\":\"Requestsucceed.\",\"code\":200,\"data\":[{\"ProductCode\":\"15C100010A\",\"Type\":\"GOODS\",\"VAT\":8},{\"ProductCode\":\"15C100010B\",\"Type\":\"GOODS\",\"VAT\":8},{\"ProductCode\":\"15C100010C\",\"Type\":\"GOODS\",\"VAT\":8},{\"ProductCode\":\"15C100010D\",\"Type\":\"GOODS\",\"VAT\":8},{\"ProductCode\":\"15C200010A\",\"Type\":\"GOODS\",\"VAT\":8},{\"ProductCode\":\"15C200010B\",\"Type\":\"GOODS\",\"VAT\":8},{\"ProductCode\":\"15C200010C\",\"Type\":\"GOODS\",\"VAT\":8},{\"ProductCode\":\"15C200010D\",\"Type\":\"GOODS\",\"VAT\":8},{\"ProductCode\":\"BNK0012022B\",\"Type\":\"GOODS\",\"VAT\":8}],\"totalLine\":200}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
       
        Test.startTest();
        System.schedule('Auto Sync VATAll DMS 1', '0 0 0 * * ?', new ScheduleGetVATList());
        
        Test.stopTest();
        ScheduleGetVATList.stopSchedule();
    }
    @isTest(SeeAllData=true) 
    static void testAPIHN() {
        
        Test.startTest();
            System.schedule('Auto Sync VATAll Test HN', '0 0 6 * * ?', new ScheduleVATListHN());
        Test.stopTest();
    }
}