@isTest
public class APIServiceBookingTest {
    @isTest(SeeAllData=true) 
    static void testAPIBooking() {
        String jsondata = '{\"Brand\":\"Honda\",\"Model\":\"Test\",\"FullName\":\"DuyNguyen\",\"Mobile\":\"0933245678\",\"Email\":\"huythe3@gmail.com\",\"Adrress\":\"71AnDươngVương\",\"BookingTime\":\"Sáng\",\"BookingDate\":\"20220321\",\"ServiceType\":\"TestDrive\",\"DoDL\":\"RY01A\"}';
        RestRequest request = new RestRequest();
        request.requestUri = '/APIServiceBooking/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsondata);

        RestContext.request = request;
        RestContext.response = new RestResponse();
        APIServiceBooking.Run();        
    }
}