@isTest
public class APIOwnerShipCreateCRMTest {
    @isTest(SeeAllData=true) 
    static void testApi() {
        string json = '{\"CRMConsumerId\":\"\",\"RecordTypeName\":\"CRM\",\"DealerCode\":\"RY01\",\"PointCode\":\"RY01A\",\"DataType\":\"\",\"Frameno\":\"JYARN6970MA000339\",\"Engineno\":\"\",\"ModelCode\":\"5C6400\",\"ModelName\":\"T110LSE\",\"Salesdate\":\"\",\"Firstname\":\"le\",\"Lastname\":\"Hung\",\"Gender\":\"Male\",\"Birthday\":\"2000-01-10\",\"ProvinceCode\":\"8413000\",\"DistrictCode\":\"8413001\",\"MobilePhone\":\"\",\"Mail\":\"huythe3@gmail.com\",\"Address\":\"384Cáchmạngtháng8\",\"RelationType\":\"\",\"OrderIdDMS\":\"\",\"OrderIDCRM\":\"801BB000000IttRYAS\"}';
        RestRequest request = new RestRequest();
        request.requestUri = '/APIOwnerShipCreateCRM/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(json);

        RestContext.request = request;
        RestContext.response = new RestResponse();
        APIOwnerShipCreateCRM.Run();        
    }
    @isTest(SeeAllData=true) 
    static void testApi1() {
        string json = '{\"CRMConsumerId\":\"001BB000002XfwpYAC\",\"RecordTypeName\":\"CRM\",\"DealerCode\":\"RY01\",\"PointCode\":\"RY01A\",\"DataType\":\"\",\"Frameno\":\"JYARN6970MA000339\",\"Engineno\":\"\",\"ModelCode\":\"5C6400\",\"ModelName\":\"T110LSE\",\"Salesdate\":\"\",\"Firstname\":\"le\",\"Lastname\":\"Hung\",\"Gender\":\"Male\",\"Birthday\":\"2000-01-10\",\"ProvinceCode\":\"8413000\",\"DistrictCode\":\"8413001\",\"MobilePhone\":\"\",\"Mail\":\"huythe3@gmail.com\",\"Address\":\"384Cáchmạngtháng8\",\"RelationType\":\"\",\"OrderIdDMS\":\"\",\"OrderIDCRM\":\"801BB000000IttRYAS\"}';
        RestRequest request = new RestRequest();
        request.requestUri = '/APIOwnerShipCreateCRM/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(json);

        RestContext.request = request;
        RestContext.response = new RestResponse();
        APIOwnerShipCreateCRM.Run();        
    }
}