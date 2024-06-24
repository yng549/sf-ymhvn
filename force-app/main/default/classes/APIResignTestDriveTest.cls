@isTest
public class APIResignTestDriveTest {
	@isTest(SeeAllData=true) 
    static void testDriveTest() {
        String jsondata = '{\"ProductCode\":\"BAE100\",\"Fullname\":\"NguyễnĐứcDuy\",\"Mobile\":\"0933737893\",\"Email\":\"duyduc@gmail.com\",\"Address\":\"71CôBắcBìnhĐiềnLongAn\",\"BookingDate\":\"2022-11-07\",\"BookingTime\":\"Sáng\",\"ServiceType\":\"Láithử\",\"License\":\"1\",\"DoDL\":\"RY01A\"}';
        RestRequest request = new RestRequest();
        request.requestUri = '/APIResignTestDrive/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsondata);

        RestContext.request = request;
        RestContext.response = new RestResponse();
        APIResignTestDrive.Run();        
    }
}