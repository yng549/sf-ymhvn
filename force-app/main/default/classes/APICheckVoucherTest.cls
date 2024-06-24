@isTest
public class APICheckVoucherTest {
	 @isTest(SeeAllData = True)
    static void testSyncProd() {
		String jsonreq = '{\"voucherCode\":\"02NgD-Hjz0y\",\"source\":\"0933210140\"}';
        RestResponse res = new RestResponse();
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APICheckVoucher/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonreq);
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = res;
        APICheckVoucher.run();
        
        Test.stopTest();
    }
     @isTest(SeeAllData = True)
    static void testSyncProd1() {
		String jsonreq = '{\"voucherCode\":\"02Nyz-KdChX\",\"source\":\"0933210140\"}';
        RestResponse res = new RestResponse();
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APICheckVoucher/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonreq);
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = res;
        APICheckVoucher.run();
        
        Test.stopTest();
    }
     @isTest(SeeAllData = True)
    static void testSyncProd2() {
		String jsonreq = '{\"voucherCode\":\"113\",\"source\":\"0933210140\"}';
        RestResponse res = new RestResponse();
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APICheckVoucher/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonreq);
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = res;
        APICheckVoucher.run();
        
        Test.stopTest();
    }
}