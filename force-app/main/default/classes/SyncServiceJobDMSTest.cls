@isTest(SeeAllData = True)
public class SyncServiceJobDMSTest {
	// IV.4 service job Data
    @isTest
    static void testSyncPartHCMSuccess() {
		String jsonreq = '{\"msg\":\"Requestsucceed.\",\"code\":200,\"data\":[{\"hProductLineCode\":\"10\",\"dJobId\":\"15d7dd89-990d-4027-a769-c736fa6bf3f5\",\"dDealerCode\":\"RY01\",\"dPointCode\":\"RY01A\",\"dJobCode\":\"S598\",\"dJobDescriptionEng\":\"\",\"dJobDescriptionLocal\":\"\",\"dJobDescriptionLocalForDo\":null,\"UpdateDate\":\"20220414\"},{\"hProductLineCode\":\"10\",\"dJobId\":\"633b2f79-fd92-43d1-962e-2c9f06ddcb83\",\"dDealerCode\":\"RY01\",\"dPointCode\":\"RY01A\",\"dJobCode\":\"9640\",\"dJobDescriptionEng\":\"\",\"dJobDescriptionLocal\":\"\",\"dJobDescriptionLocalForDo\":null,\"UpdateDate\":\"20220414\"},{\"hProductLineCode\":\"10\",\"dJobId\":\"68616d88-b307-4af3-9176-439283781c22\",\"dDealerCode\":\"RY01\",\"dPointCode\":\"RY01A\",\"dJobCode\":\"9650\",\"dJobDescriptionEng\":\"\",\"dJobDescriptionLocal\":\"\",\"dJobDescriptionLocalForDo\":null,\"UpdateDate\":\"20220414\"},{\"hProductLineCode\":\"10\",\"dJobId\":\"c00f6dc9-e033-4f1a-bd16-55be3caaee49\",\"dDealerCode\":\"RY01\",\"dPointCode\":\"RY01A\",\"dJobCode\":\"9660\",\"dJobDescriptionEng\":\"\",\"dJobDescriptionLocal\":\"\",\"dJobDescriptionLocalForDo\":null,\"UpdateDate\":\"20220414\"}],\"totalLine\":4}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsonreq);
        Test.startTest();
        System.schedule('Sync Service job HCM 1', '0 0 0 * * ?', new ScheduleServiceJobDMS());
        Test.stopTest();
    }
    @isTest
    static void testSyncPartHNSuccess() {
		String jsonreq = '{\"msg\":\"Requestsucceed.\",\"code\":200,\"data\":[{\"hProductLineCode\":\"10\",\"dJobId\":\"15d7dd89-990d-4027-a769-c736fa6bf3f5\",\"dDealerCode\":\"RY01\",\"dPointCode\":\"RY01A\",\"dJobCode\":\"S598\",\"dJobDescriptionEng\":\"\",\"dJobDescriptionLocal\":\"\",\"dJobDescriptionLocalForDo\":null,\"UpdateDate\":\"20220414\"},{\"hProductLineCode\":\"10\",\"dJobId\":\"633b2f79-fd92-43d1-962e-2c9f06ddcb83\",\"dDealerCode\":\"RY01\",\"dPointCode\":\"RY01A\",\"dJobCode\":\"9640\",\"dJobDescriptionEng\":\"\",\"dJobDescriptionLocal\":\"\",\"dJobDescriptionLocalForDo\":null,\"UpdateDate\":\"20220414\"},{\"hProductLineCode\":\"10\",\"dJobId\":\"68616d88-b307-4af3-9176-439283781c22\",\"dDealerCode\":\"RY01\",\"dPointCode\":\"RY01A\",\"dJobCode\":\"9650\",\"dJobDescriptionEng\":\"\",\"dJobDescriptionLocal\":\"\",\"dJobDescriptionLocalForDo\":null,\"UpdateDate\":\"20220414\"},{\"hProductLineCode\":\"10\",\"dJobId\":\"c00f6dc9-e033-4f1a-bd16-55be3caaee49\",\"dDealerCode\":\"RY01\",\"dPointCode\":\"RY01A\",\"dJobCode\":\"9660\",\"dJobDescriptionEng\":\"\",\"dJobDescriptionLocal\":\"\",\"dJobDescriptionLocalForDo\":null,\"UpdateDate\":\"20220414\"}],\"totalLine\":4}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsonreq);
        Test.startTest();
        System.schedule('Sync Service job HN 1', '0 0 0 * * ?', new ScheduleServiceJobHN());
        Test.stopTest();
    }
}