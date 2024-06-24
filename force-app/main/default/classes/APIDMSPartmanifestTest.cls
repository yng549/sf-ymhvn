@isTest(SeeAllData = True)
public class APIDMSPartmanifestTest {
	@isTest
    static void testSyncPartManifestSuccess() {
		String jsonreq = '{\"msg\":\"Requestsucceed.\",\"code\":200,\"data\":[{\"ManifestItemID\":\"43c81bb2-9a0f-4cd7-8b7a-fb58899335d8\",\"DealerCode\":\"RY01\",\"InvoiceNo\":\"BS/20E0004900\",\"YourOrderNo\":\"2203A0003\",\"PartsNo\":\"2PN833200000\",\"PartsNoOrdered\":\"2PN833200000\",\"Price\":164662,\"CaseNo\":\"M92425\",\"PackingQty\":2,\"ShippedDate\":\"20220326\",\"InvoiceSeqNo\":\"00282050923\",\"ShipmentNo\":\"40039270\",\"UpdateDate\":\"20220326\"}]}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsonreq);
       
        Test.startTest();
        System.schedule('Auto Sync Partmanifest DMS', '0 0 0 * * ?', new ScheduleSyncPartmanifest());
        Test.stopTest();
    }
    @isTest
    static void testSyncPartManifestHNSuccess() {
		String jsonreq = '{\"msg\":\"Requestsucceed.\",\"code\":200,\"data\":[{\"ManifestItemID\":\"43c81bb2-9a0f-4cd7-8b7a-fb58899335d8\",\"DealerCode\":\"RY01\",\"InvoiceNo\":\"BS/20E0004900\",\"YourOrderNo\":\"2203A0003\",\"PartsNo\":\"2PN833200000\",\"PartsNoOrdered\":\"2PN833200000\",\"Price\":164662,\"CaseNo\":\"M92425\",\"PackingQty\":2,\"ShippedDate\":\"20220326\",\"InvoiceSeqNo\":\"00282050923\",\"ShipmentNo\":\"40039270\",\"UpdateDate\":\"20220326\"}]}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsonreq);
       
        Test.startTest();
        System.schedule('Auto Sync Partmanifest HN DMS', '0 0 0 * * ?', new SchedulePartmanifestHN());
        Test.stopTest();
    }
}