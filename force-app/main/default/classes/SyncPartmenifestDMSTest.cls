@isTest(SeeAllData = True)
public class SyncPartmenifestDMSTest {
	// IV.3 partmenifest Data
    @isTest
    static void testSyncPartSuccess() {
        
		String jsonreq = '{\"msg\":\"Requestsucceed.\",\"code\":200,\"data\":[{\"ManifestItemID\":\"9ba22769-fae9-4bca-ade2-ac31bd5445ab\",\"DealerCode\":\"RY01\",\"InvoiceNo\":\"BS/20E0004913\",\"YourOrderNo\":\"2203A0002\",\"PartsNo\":\"BD5154510000\",\"PartsNoOrdered\":\"BD5154510000\",\"Price\":89246,\"CaseNo\":\"M91129\",\"PackingQty\":1,\"ShippedDate\":\"20220413\",\"InvoiceSeqNo\":\"00282050935\",\"ShipmentNo\":\"40039288\",\"UpdateDate\":\"20220329\"},{\"ManifestItemID\":\"a826dc25-b621-42ca-8ae9-2d8a705694fc\",\"DealerCode\":\"RY01\",\"InvoiceNo\":\"BS/20E0004992\",\"YourOrderNo\":\"00000265\",\"PartsNo\":\"1WDE34401000\",\"PartsNoOrdered\":\"1WDE34401000\",\"Price\":55359,\"CaseNo\":\"I85201\",\"PackingQty\":3,\"ShippedDate\":\"20220413\",\"InvoiceSeqNo\":\"00282051011\",\"ShipmentNo\":\"40039386\",\"UpdateDate\":\"20220405\"},{\"ManifestItemID\":\"b17e7e14-2a92-4165-96bd-09b8f13cbccb\",\"DealerCode\":\"RY01\",\"InvoiceNo\":\"BS/20E0004913\",\"YourOrderNo\":\"2203A0004\",\"PartsNo\":\"BK6H33400000\",\"PartsNoOrdered\":\"BK6H33400000\",\"Price\":42413,\"CaseNo\":\"M91129\",\"PackingQty\":1,\"ShippedDate\":\"20220413\",\"InvoiceSeqNo\":\"00282050935\",\"ShipmentNo\":\"40039288\",\"UpdateDate\":\"20220329\"},{\"ManifestItemID\":\"b7ed1d08-0635-43f5-bb1b-7ebaca3bc9d8\",\"DealerCode\":\"RY01\",\"InvoiceNo\":\"BS/20E0005044\",\"YourOrderNo\":\"00000265\",\"PartsNo\":\"5GH134406100\",\"PartsNoOrdered\":\"5GH134406000\",\"Price\":145409,\"CaseNo\":\"M97868\",\"PackingQty\":8,\"ShippedDate\":\"20220413\",\"InvoiceSeqNo\":\"00282051062\",\"ShipmentNo\":\"40039425\",\"UpdateDate\":\"20220407\"}],\"totalLine\":14}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsonreq);
        Test.startTest();
        date dateFrom = Date.today().addDays(-1);
        Date dateTo = Date.today().addDays(-1);
         system.enqueueJob(new SyncPartmenifestDMS(dateFrom, dateTo, 200, 0, 0, 0, 'RY01'));
        //System.schedule('Auto Sync Partmanifest DMS', '0 0 0 * * ?', new ScheduleSyncPartmanifest());
        Test.stopTest();
    }
}