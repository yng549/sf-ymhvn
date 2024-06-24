@isTest(SeeAllData = True)
public class APICheckPCAInventoryTest {
	@isTest
    static void testmockAPI() {
		String jsonreq = '{\"productCodes\":[\"90798AJBKT0B\",\"B67247C00200\"]}';
        RestResponse res = new RestResponse();
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APICheckPCAInventory/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonreq);
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = res;
        APICheckPCAInventory.run();
        Test.stopTest();
    }
}