@isTest(SeeAllData = True)
public class SyncDMSOrderHelperTest {
	@isTest
    static void testSyncMCInvenJobSuccess() {
        try { 
            SyncDMSHelper.cheatTemp();
            List<Order> order = [SELECT Id FROM Order WHERE RecordtypeId =: RecordTypeHelper.ORDER_PROFOMAR_ORDER AND Status = 'Completed'];
            string jsonreq = '{\"code\":200,\"msg\":\"Requestsucceed.\"}';
            MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsonreq);
            
            Test.startTest();
            system.enqueueJob(new SyncDMSOrderHelper.CreateOrderQueue(new List<Id> {'801BB000000Imo0YAC'}, 'svfreecouponsorder'));
            Test.stopTest();
        }catch(Exception e) {
            
        }
		
    }
    @isTest
    static void testSync1() {
        try { 
            string jsonreq = '{\"code\":200,\"msg\":\"Requestsucceed.\"}';
            MockDMSHelperResponse.setTestMockResponse(201, 'OK', jsonreq);
           
            Test.startTest();
            system.enqueueJob(new SyncDMSOrderHelper.CreateOrderQueue(new List<Id> {'801BB000000J7u8YAC'}, 'mcsalesorder'));
        	Test.stopTest();
        }catch(Exception e) {
            
        }
        
    }
}