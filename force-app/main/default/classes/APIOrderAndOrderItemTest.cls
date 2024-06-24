@istest
public class APIOrderAndOrderItemTest {
    @isTest(SeeAllData=true)
    static void testSyncQuoteDev() {
        List<Quote> quotes = [SELECT ID, Status, Delivery_Date__c FROM Quote WHERE Id = '0Q0O0000000EWzQKAW'];
       
        Test.startTest();
        if(!quotes.isEmpty()) {
            quotes[0].Delivery_Date__c = Date.today().addMonths(1);
        	quotes[0].Status = 'Approved';
        	update quotes;
        }
        Test.stopTest();
		
    }
    @isTest(SeeAllData=true)
    static void testSyncQuoteProd() {
        List<Quote> quotes = [SELECT ID, Status, Delivery_Date__c FROM Quote WHERE Id = '0Q0BB0000004UdG0AU'];
        if(quotes.isEmpty()) return;
        Test.startTest();
        quotes[0].Delivery_Date__c = Date.today().addMonths(1);
        quotes[0].Status = 'Approved';
        update quotes;
        Test.stopTest();
    }
    // IV.3 partmenifest Data
    @isTest(SeeAllData=true)
    static void testSyncDev() {
         String jsonreq = '{\"orders\":[{\"guest\":1,\"name\":\"PhanTaiAnh\",\"phone\":\"0933216222\",\"email\":\"vanha95@gmail.com\",\"order_source\":\"Revzone\",\"web_order_id\":\"091312\",\"order_type\":\"PCA\",\"customer_id\":\"001O000002HvYZzIAN\",\"receive_address\":\"BếnThành\",\"recevie_province\":\"8410300\",\"receive_district\":\"8410301\",\"receive_ward\":\"Phường6\",\"invoice_require\":\"1\",\"tax_number\":\"0323445\",\"company_info\":\"\",\"company_address\":\"\",\"dealer_code\":\"RY01A\",\"payment_method\":\"Showroom\",\"promotion_code\":\"\",\"promotion_ItemID\":\"\",\"vouchers\":[],\"orderProducts\":[{\"productcode\":\"B23RH123W60L\",\"quantity\":\"1\",\"sizecode\":\"\",\"colorcode\":\"010A\",\"price\":\"65550000\",\"sale_off\":\"3450000\"}]}]}';
        
        RestResponse res = new RestResponse();
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APIOrderAndOrderItemModel/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonreq);
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = res;
        APIOrderAndOrderItem.run();
        
        Test.stopTest();
		
    }
    // IV.3 partmenifest Data
    @isTest(SeeAllData=true)
    static void testSyncPCADev() {
        String jsonreq = '{\"orders\":[{\"guest\":1,\"name\":\"PhanTaiAnh\",\"phone\":\"0933216222\",\"email\":\"vanha95@gmail.com\",\"order_source\":\"Revzone\",\"web_order_id\":\"123490\",\"order_type\":\"PCA\",\"customer_id\":\"001O000002H5stmIAB\",\"receive_address\":\"BếnThành\",\"recevie_province\":\"8410300\",\"receive_district\":\"8410301\",\"receive_ward\":\"Phường6\",\"invoice_require\":\"1\",\"tax_number\":\"0323445\",\"company_info\":\"\",\"company_address\":\"\",\"dealer_code\":\"RY01A\",\"payment_method\":\"Showroom\",\"promotion_code\":\"\",\"promotion_ItemID\":\"\",\"vouchers\":[],\"orderProducts\":[{\"productcode\":\"B5C854A30000\",\"quantity\":\"1\",\"sizecode\":\"\",\"colorcode\":\"010A\",\"price\":\"65550000\",\"sale_off\":\"3450000\"}]}]}';
        
        RestResponse res = new RestResponse();
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APIOrderAndOrderItemModel/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonreq);
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = res;
        APIOrderAndOrderItem.run();
        
        Test.stopTest();
		
    }
    // IV.3 partmenifest Data
    @isTest(SeeAllData=true)
    static void testSyncPartSuccessDev() {
		String jsonreq = '{\"orders\":[{\"guest\":0,\"name\":\"PhanTaiAnh\",\"phone\":\"+84966756751\",\"email\":\"vanha95@gmail.com\",\"order_source\":\"Revzone\",\"web_order_id\":\"8213\",\"order_type\":\"Bike\",\"customer_id\":\"001O000002I4T9vIAF\",\"receive_address\":\"71CoBacKi\",\"recevie_province\":\"8410300\",\"receive_district\":\"8410301\",\"receive_ward\":\"Tankitanphu\",\"invoice_require\":\"1\",\"tax_number\":\"0323445\",\"company_info\":\"OMNI1\",\"company_address\":\"PhuNhuan\",\"company_address__c\":\"PhuNhuan\",\"dealer_code\":\"RY01A\",\"payment_method\":\"Showroom\",\"promotion_code\":\"PM1112\",\"promotion_ItemID\":\"a0DO000000EynHfMAJ\",\"vouchers\":[\"\"],\"orderProducts\":[{\"productcode\":\"B8D600\",\"quantity\":\"1\",\"sizecode\":\"\",\"colorcode\":\"010A\",\"price\":\"65550000\",\"sale_off\":\"3450000\"}]}]}';
        
        RestResponse res = new RestResponse();
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APIOrderAndOrderItemModel/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonreq);
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = res;
        APIOrderAndOrderItem.run();
        Test.stopTest();
        List<Order_WebCommercal__c> orders = [select id from Order_WebCommercal__c];
        orders[0].Status__c = 'DO/DL tiếp nhận thông tin';
        update orders;
        APIUpdatePayementMethod.requestBody payment = new  APIUpdatePayementMethod.requestBody();
        payment.orderid = orders[0].Id;
        payment.paymentmethod = 'Trả góp ngân hàng';
        string data = Json.serialize(payment);
        RestResponse res1 = new RestResponse();
        RestRequest request1 = new RestRequest();
        request1.requestUri = '/APIUpdatePayementMethod/';
        request1.httpMethod = 'POST';
        request1.requestBody = Blob.valueOf(data);
        request1.addHeader('Content-Type', 'application/json');
        RestContext.request = request1;
        RestContext.response = res1;
        APIUpdatePayementMethod.run();
        
        APIOrderCancle.requestBody cancelstatus = new  APIOrderCancle.requestBody();
        cancelstatus.orderid = orders[0].Id;
        cancelstatus.reasoncancel = 'Không đủ tiền';
        string data2= Json.serialize(cancelstatus);
        RestResponse res2 = new RestResponse();
        RestRequest request2 = new RestRequest();
        request2.requestUri = '/APIOrderCancle/';
        request2.httpMethod = 'POST';
        request2.requestBody = Blob.valueOf(data2);
        request2.addHeader('Content-Type', 'application/json');
        RestContext.request = request2;
        RestContext.response = res2;
        APIOrderCancle.run();
    }
    
    
    
    // IV.3 partmenifest Data
    @isTest(SeeAllData=true)
    static void testSyncProd() {
        String jsonreq = '{\"orders\":[{\"guest\":1,\"name\":\"PhanTaiAnh\",\"phone\":\"0834258643\",\"email\":\"vanha95@gmail.com\",\"order_source\":\"Revzone\",\"web_order_id\":\"33451231`\",\"order_type\":\"PCA\",\"customer_id\":\"001BB0000037ha1YAA\",\"receive_address\":\"BếnThành\",\"recevie_province\":\"8410300\",\"receive_district\":\"8410301\",\"receive_ward\":\"Phường6\",\"invoice_require\":\"1\",\"tax_number\":\"0323445\",\"company_info\":\"\",\"company_address\":\"\",\"dealer_code\":\"RY01A\",\"payment_method\":\"Showroom\",\"promotion_code\":\"NTTD\",\"promotion_ItemID\":\"a19BB000004ZN0VYAW\",\"vouchers\":[],\"orderProducts\":[{\"productcode\":\"B23RH123W60L\",\"quantity\":\"1\",\"sizecode\":\"\",\"colorcode\":\"010A\",\"price\":\"65550000\",\"sale_off\":\"3450000\"}]}]}';
        
        RestResponse res = new RestResponse();
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APIOrderAndOrderItemModel/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonreq);
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = res;
        APIOrderAndOrderItem.run();
        Test.stopTest();
    }
    // IV.3 partmenifest Data
   @isTest(SeeAllData=true)
   static void testSyncPartSuccess() {
		String jsonreq = '{\"orders\":[{\"guest\":0,\"name\":\"PhanTaiAnh\",\"phone\":\"+84353959191\",\"email\":\"vanha95@gmail.com\",\"order_source\":\"Revzone\",\"web_order_id\":\"131099\",\"order_type\":\"Bike\",\"customer_id\":\"001BB000002XHs7YAG\",\"receive_address\":\"71CoBacKi\",\"recevie_province\":\"8410300\",\"receive_district\":\"8410301\",\"receive_ward\":\"Tankitanphu\",\"invoice_require\":\"1\",\"tax_number\":\"0323445\",\"company_info\":\"OMNI1\",\"company_address\":\"PhuNhuan\",\"company_address__c\":\"PhuNhuan\",\"dealer_code\":\"RY01A\",\"payment_method\":\"Showroom\",\"promotion_code\":\"NTTD\",\"promotion_ItemID\":\"a19BB000004ZN0VYAW\",\"vouchers\":[\"\"],\"orderProducts\":[{\"productcode\":\"B8D600\",\"quantity\":\"1\",\"sizecode\":\"\",\"colorcode\":\"010A\",\"price\":\"65550000\",\"sale_off\":\"3450000\"}]}]}';
        
        RestResponse res = new RestResponse();
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APIOrderAndOrderItemModel/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonreq);
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = res;
        APIOrderAndOrderItem.run();
        Test.stopTest();
       	
        string jsondata = '{}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);

        List<Order_WebCommercal__c> orders = [SELECT id FROM Order_WebCommercal__c];
        orders[0].Status__c = 'DO/DL tiếp nhận thông tin';
        update orders;
       
        APIUpdatePayementMethod.requestBody payment = new  APIUpdatePayementMethod.requestBody();
        payment.orderid = orders[0].Id;
        payment.paymentmethod = 'Trả góp ngân hàng';
        string data = Json.serialize(payment);
        RestResponse res1 = new RestResponse();
        RestRequest request1 = new RestRequest();
        request1.requestUri = '/APIUpdatePayementMethod/';
        request1.httpMethod = 'POST';
        request1.requestBody = Blob.valueOf(data);
        request1.addHeader('Content-Type', 'application/json');
        RestContext.request = request1;
        RestContext.response = res1;
        APIUpdatePayementMethod.run();
        
        APIOrderCancle.requestBody cancelstatus = new  APIOrderCancle.requestBody();
        cancelstatus.orderid = orders[0].Id;
        cancelstatus.reasoncancel = 'Không đủ tiền';
        string data2= Json.serialize(cancelstatus);
        RestResponse res2 = new RestResponse();
        RestRequest request2 = new RestRequest();
        request2.requestUri = '/APIOrderCancle/';
        request2.httpMethod = 'POST';
        request2.requestBody = Blob.valueOf(data2);
        request2.addHeader('Content-Type', 'application/json');
        RestContext.request = request2;
        RestContext.response = res2;
        APIOrderCancle.run();
    }
}