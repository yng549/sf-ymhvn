@isTest(SeeAllData=true)
public class ApiResponseTest {
    @isTest static void onBeforeInsertTest() {
        ApiResponse api = new ApiResponse();
        api.addError('');
    }
}