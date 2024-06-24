@isTest
public class APICMSUpsertPromotionMasterTest {
	@isTest(seeAlldata=true)
    static void testAPIWorkshopDev(){
        string jsondata = '{}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
       
        Test.startTest();
        system.enqueueJob(new APICMSUpsertPromotionMaster.CreatePromoQueue(new List<Id> {'a0CO000000WFOWTMA5'}));
        Test.stopTest();
    }
    @isTest(seeAlldata=true)
    static void testAPIRevzoneDev(){
        string jsondata = '{}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
       
        Test.startTest();
        system.enqueueJob(new APICMSUpsertPromotionMaster.CreatePromoQueue(new List<Id> {'a0CO000000WFD61MAH'}));
        Test.stopTest();
    }
    @isTest(seeAlldata=true)
    static void testAPIWorkshopProd(){
        string jsondata = '{}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
       
        Test.startTest();
        system.enqueueJob(new APICMSUpsertPromotionMaster.CreatePromoQueue(new List<Id> {'a1CBB0000003YuV2AU'}));
        Test.stopTest();
    }
    @isTest(seeAlldata=true)
    static void testAPIRevzoneProd(){
        string jsondata = '{}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
       
        Test.startTest();
        system.enqueueJob(new APICMSUpsertPromotionMaster.CreatePromoQueue(new List<Id> {'a1CBB0000000Nx72AE'}));
        Test.stopTest();
    }
}