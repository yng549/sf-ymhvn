@isTest
public class CheckOrderWarrantyLastModifiedTest {
	@isTest(seeAlldata=true)
    static void testInitProd() {
        try{
            string jsonreq = '{\"code\":200,\"msg\":\"Requestsucceed.\"}';
            MockDMSHelperResponse.setTestMockResponse(201, 'OK', jsonreq);
            
            Test.startTest();
            CheckOrderWarrantyLastModified.getInitialData('02iBB0000005LDjYAM');
            Test.stopTest();
        }catch(Exception e) {
            
        }
        
    }
    @isTest(seeAllData=true)
    static void testcheckFrameNoDMSProd() {
        string json = '{\"msg\":\"Requestsucceed.\",\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"RLCS1FC10DY028886\",\"WarrantyEffectiveDate\":\"20131122\",\"WarrantyExpiredDate\":\"20141121\",\"WarrantyMileage\":\"12000\",\"WarrantyPolicyType\":\"OldWarrantyPolicy\",\"UpdateDate\":\"00011231\",\"coupons\":[{\"coupon\":{\"CouponCategoryLevel\":\"4\",\"ServiceDate\":\"20150211\",\"Mileage\":\"5600\"}},{\"coupon\":{\"CouponCategoryLevel\":\"5\",\"ServiceDate\":\"20150723\",\"Mileage\":\"16987\"}}]}}]}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', json);
        Test.startTest();
        List<Asset> assets = [SELECT ID, Frame_Number__c, DO_DL_Code__c
                              FROM Asset
                              WHERE Id = '02iBB0000005LDjYAM'];
        ApiResponse t1 = CheckOrderWarrantyLastModified.checkFrameNoDMS(assets[0]);
        Test.stopTest();
    }
    @isTest(seeAllData=true)
    static void testcheckFrameNoFailProd() {
        string json = '{\"msg\":\"Requestsucceed.\",\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"RLCS1FC10DY028886\",\"WarrantyEffectiveDate\":\"20131122\",\"WarrantyExpiredDate\":\"20141121\",\"WarrantyMileage\":\"12000\",\"WarrantyPolicyType\":\"OldWarrantyPolicy\",\"UpdateDate\":\"00011231\",\"coupons\":[{\"coupon\":{\"CouponCategoryLevel\":\"4\",\"ServiceDate\":\"20150211\",\"Mileage\":\"5600\"}},{\"coupon\":{\"CouponCategoryLevel\":\"5\",\"ServiceDate\":\"20150723\",\"Mileage\":\"16987\"}}]}}]}';
        MockDMSHelperResponse.setTestMockResponse(400, 'OK', json);
        Test.startTest();
        List<Asset> assets = [SELECT ID, Frame_Number__c,  DO_DL_Code__c
                              FROM Asset
                              WHERE Id = '02iBB0000005LDjYAM'];
        ApiResponse t1 = CheckOrderWarrantyLastModified.checkFrameNoDMS(assets[0]);
        Test.stopTest();
    }
    @isTest(seeAlldata=true)
    static void testInitDev() {
        try{
        	Test.startTest();
            CheckOrderWarrantyLastModified.getInitialData('02iO000000HLbjbIAD');
            Test.stopTest();    
        }catch(exception e) {
            
        }
        
    }
    @isTest(seeAllData=true)
    static void testcheckFrameNoDMSDev() {
        try{
            string json = '{\"msg\":\"Requestsucceed.\",\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"RLCS1FC10DY028886\",\"WarrantyEffectiveDate\":\"20131122\",\"WarrantyExpiredDate\":\"20141121\",\"WarrantyMileage\":\"12000\",\"WarrantyPolicyType\":\"OldWarrantyPolicy\",\"UpdateDate\":\"00011231\",\"coupons\":[{\"coupon\":{\"CouponCategoryLevel\":\"4\",\"ServiceDate\":\"20150211\",\"Mileage\":\"5600\"}},{\"coupon\":{\"CouponCategoryLevel\":\"5\",\"ServiceDate\":\"20150723\",\"Mileage\":\"16987\"}}]}}]}';
            MockDMSHelperResponse.setTestMockResponse(200, 'OK', json);
            Test.startTest();
            List<Asset> assets = [SELECT ID, Frame_Number__c
                                  FROM Asset
                                  WHERE Id = '02iO000000HLbjbIAD'];
            ApiResponse t1 = CheckOrderWarrantyLastModified.checkFrameNoDMS(assets[0]);
            Test.stopTest();
        }catch(exception e) {
            
        }
    }
    @isTest(seeAllData=true)
    static void testcheckFrameNoFailDev() {
         try{
            string json = '{\"msg\":\"Requestsucceed.\",\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"RLCS1FC10DY028886\",\"WarrantyEffectiveDate\":\"20131122\",\"WarrantyExpiredDate\":\"20141121\",\"WarrantyMileage\":\"12000\",\"WarrantyPolicyType\":\"OldWarrantyPolicy\",\"UpdateDate\":\"00011231\",\"coupons\":[{\"coupon\":{\"CouponCategoryLevel\":\"4\",\"ServiceDate\":\"20150211\",\"Mileage\":\"5600\"}},{\"coupon\":{\"CouponCategoryLevel\":\"5\",\"ServiceDate\":\"20150723\",\"Mileage\":\"16987\"}}]}}]}';
            MockDMSHelperResponse.setTestMockResponse(400, 'OK', json);
            Test.startTest();
            List<Asset> assets = [SELECT ID, Frame_Number__c
                                  FROM Asset
                                  WHERE Id = '02iO000000HLbjbIAD'];
            ApiResponse t1 = CheckOrderWarrantyLastModified.checkFrameNoDMS(assets[0]);
            Test.stopTest();
        }catch(exception e) { 
            
        }
    }
}