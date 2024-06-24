@isTest(SeeAllData = True)
public class APICheckMcInventoryTest {
	@isTest
    static void testmockAPI() {
		String jsonreq = '{\"modelCodes\":[\"B8D600\",\"BAE100\"]}';
        RestResponse res = new RestResponse();
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APICheckMcInventory/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonreq);
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = res;
        APICheckMcInventory.run();
        Test.stopTest();
    }
}