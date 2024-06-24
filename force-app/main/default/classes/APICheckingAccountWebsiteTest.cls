@isTest
public class APICheckingAccountWebsiteTest {
    @isTest(seeAlldata=True)
    static void testSync1() {
       Test.startTest();
       		List<User> user = [SELECT Id, Name FROM User WHERE Profile.Name =: 'MKT Manager'];
            Account acc2 = new Account();
            acc2.FirstName = 'Tran';
            acc2.LastName = 'Duy';
            acc2.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
            acc2.PersonMobilePhone = '0933123111';
            acc2.Is_Primary__c = TRUE;
            acc2.DO_DL_Owner__c = user[0].Id;
        	try {
            	insert acc2;
            }catch(Exception e) {}
        Test.stopTest();
    }
    @isTest
    static void testSyncProd() {
    
        
        
		String jsonreq = '{\"phoneNo\":\"0933567777\",\"districtcode\":\"\",\"provincecode\":\"\",\"addressno\":\"381Cáchmạngtháng8\",\"gender\":\"Female\",\"firstname\":\"Hònngọc\",\"lastname\":\"ViễnĐông\",\"email\":\"viendong@gmail.com\",\"websiteID\":\"199218281828121\"}';
        RestResponse res = new RestResponse();
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APICheckingAccountWebsite/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonreq);
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = res;
        APICheckingAccountWebsite.run();
        
        Test.stopTest();
    }
    @isTest
    static void testSyncProd2() {
		String jsonreq = '{\"phoneNo\":\"+84353959191\",\"districtcode\":\"\",\"provincecode\":\"\",\"addressno\":\"381Cáchmạngtháng8\",\"gender\":\"Female\",\"firstname\":\"Hònngọc\",\"lastname\":\"ViễnĐông\",\"email\":\"viendong@gmail.com\",\"workshopID\":\"199218281828121\",\"websiteID\":\"1310982\"}';
        RestResponse res = new RestResponse();
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APICheckingAccountWebsite/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonreq);
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = res;
        APICheckingAccountWebsite.run();
        
        Test.stopTest();
    }
    @isTest
    static void testSyncProd1() {
		String jsonreq = '{\"phoneNo\":\"\",\"districtcode\":\"\",\"provincecode\":\"\",\"addressno\":\"381Cáchmạngtháng8\",\"gender\":\"Female\",\"firstname\":\"Hònngọc\",\"lastname\":\"ViễnĐông\",\"email\":\"viendong@gmail.com\",\"websiteID\":\"199218281828121\"}';
        RestResponse res = new RestResponse();
        Test.startTest();
        RestRequest request = new RestRequest();
        request.requestUri = '/APICheckingAccountWebsite/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonreq);
        request.addHeader('Content-Type', 'application/json');
        RestContext.request = request;
        RestContext.response = res;
        APICheckingAccountWebsite.run();
        
        Test.stopTest();
    }
}