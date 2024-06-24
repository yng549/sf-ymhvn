@isTest
public class ScheduleModeltypeTest {
	@isTest(seeAllData=True)
    static void testModel() {
       List<Order> order = [SELECT Id FROM Order WHERE RecordtypeId =: RecordTypeHelper.ORDER_PROFOMAR_ORDER AND Status = 'Completed'];
            string jsonreq = '{\"msg\":\"Requestsucceed.\",\"code\":200,\"data\":[{\"ModelCode\":\"BPC200010C\",\"ModelType\":\"JUPITERFINNFI-BPC1\"},{\"ModelCode\":\"1FCD00010C\",\"ModelType\":\"SIRIUSFI1FC8\"},{"ModelCode\":\"2NDB00010B\",\"ModelType\":\"EXCITER2ND1\"}]}';
            MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsonreq);
            
            Test.startTest();
            system.enqueueJob(new APIGetModelTypeBike('RY01'));
            Test.stopTest();
    }
    @isTest
    static void testModel1() {
         System.schedule('Auto update model type product', '0 0 7 * * ?', new ScheduleGetModelType());
    }
    @isTest
    static void testModel2() {
         System.schedule('Auto update model type product HN Test', '0 0 7 * * ?', new ScheduleModelTypeHN());
    }
}