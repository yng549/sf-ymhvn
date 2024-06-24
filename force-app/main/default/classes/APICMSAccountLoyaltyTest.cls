@isTest
public class APICMSAccountLoyaltyTest {
	@isTest 
    static void testAPI(){
        string jsondata = '{\"phoneNo\":\"0978876872\",\"districtcode\":\"8413001\",\"provincecode\":\"8413000\",\"addressno\":\"384/1cCachmangt8\",\"gender\":\"Male\",\"firstname\":\"Van\",\"lastname\":\"Duy\",\"email\":\"vanduy@gmail.com\",\"websiteID\":\"760\"}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APICheckingAccountWebsite/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsondata);
        request.addHeader('Content-Type', 'application/json');

        RestContext.request = request;
        RestContext.response = new RestResponse();
        APICheckingAccountWebsite.Run();        
		Account acc = [SELECT Id, Website_ID__c FROM Account]; 
        system.debug('acc' + acc);
        string jsonResponse = '{\"status\":\"200\",\"message\":\"Success\"}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsonResponse);
        system.enqueueJob(new APICMSAccountLoyalty(new List<Id> {acc.Id}));
        APICMSAccountLoyalty.logError('test', 'test', 'test', 'test', 'test');
        Test.stopTest();
    }
    	@isTest 
    static void testAPI1(){
        string jsondata = '{}';
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APICheckingAccountWebsite/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsondata);
        request.addHeader('Content-Type', 'application/json');

        RestContext.request = request;
        RestContext.response = new RestResponse();
        APICheckingAccountWebsite.Run();        
		
        Test.stopTest();
    }
}