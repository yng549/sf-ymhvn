@isTest(SeeAllData = True)
public class ButtonSyncPromotionToCMSTest {
	// IV.3 partmenifest Data
    @isTest
    static void testSyncPartSuccess() {
        List<Promotion__c> promo = [SELECT Id FROM Promotion__c];
        string jsondata = '{}';
		MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
        Test.startTest();
        ButtonSyncPromotionToCMS.syncPromotionToDMS(promo[0].Id);
        Test.stopTest();
    }
}