@isTest(SeeAllData = True)
public class TriggerHandlerFreeCouponsTest {
	@isTest 
    static void testAPI(){
        string jsondata = '{\"msg\":\"Requestsucceed.\",\"totalLine\":1,\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"MH3RH07Z0MK001028\",\"WarrantyEffectiveDate\":\"20200628\",\"WarrantyExpiredDate\":\"20230627\",\"WarrantyMileage\":\"10000\",\"WarrantyPolicyType\":\"NewWarrantyPolicy\",\"UpdateDate\":\"20220331\",\"coupons\":[{\"coupon\":{\"CouponCategoryLevel\":\"3\",\"ServiceDate\":\"20150723\",\"Mileage\":\"10000\"}},{\"coupon\":{\"CouponCategoryLevel\":\"1\",\"ServiceDate\":\"20150723\",\"Mileage\":\"449\"}},{\"coupon\":{\"CouponCategoryLevel\":\"7\",\"ServiceDate\":\"20150723\",\"Mileage\":\"15887\"}},{\"coupon\":{\"CouponCategoryLevel\":\"6\",\"ServiceDate\":\"20150413\",\"Mileage\":\"12345\"}},{\"coupon\":{\"CouponCategoryLevel\":\"2\",\"ServiceDate\":\"20210115\",\"Mileage\":\"500\"}},{\"coupon\":{\"CouponCategoryLevel\":\"5\",\"ServiceDate\":\"20211226\",\"Mileage\":\"7710\"}}]}}]}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
       TriggerHandlerFreeCoupons.cheatcode();
        Test.startTest();
        system.enqueueJob(new SyncDMSWarrantyFCS(date.today(), date.today(), 200, 0, 0, 0));
        Test.stopTest();
    }
    @isTest 
    static void testAPI1(){
        string jsondata = '{\"msg\":\"Requestsucceed.\",\"totalLine\":1,\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"JYARN6970MA000343\",\"WarrantyEffectiveDate\":\"20200628\",\"WarrantyExpiredDate\":\"20230627\",\"WarrantyMileage\":\"10000\",\"WarrantyPolicyType\":\"NewWarrantyPolicy\",\"UpdateDate\":\"20220331\",\"coupons\":[{\"coupon\":{\"CouponCategoryLevel\":\"1\",\"ServiceDate\":\"20150723\",\"Mileage\":\"10000\"}}]}}]}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
       
        Test.startTest();
        system.enqueueJob(new SyncDMSWarrantyFCS(date.today(), date.today(), 200, 0, 0, 0));
        Test.stopTest();
    }
    @isTest 
    static void testAPI3(){
        string jsondata = '{\"msg\":\"Requestsucceed.\",\"totalLine\":1,\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"JYARN7040MA000422\",\"WarrantyEffectiveDate\":\"20200628\",\"WarrantyExpiredDate\":\"20230627\",\"WarrantyMileage\":\"10000\",\"WarrantyPolicyType\":\"NewWarrantyPolicy\",\"UpdateDate\":\"20220331\",\"coupons\":[]}}]}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
       
        Test.startTest();
        system.enqueueJob(new SyncDMSWarrantyFCS(date.today(), date.today(), 200, 0, 0, 0));
        Test.stopTest();
    }
    @isTest 
    static void testAPI2(){
        string jsondata = '{\"msg\":\"Requestsucceed.\",\"totalLine\":1,\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"JYARN4570MA000606\",\"WarrantyEffectiveDate\":\"20200628\",\"WarrantyExpiredDate\":\"20230627\",\"WarrantyMileage\":\"10000\",\"WarrantyPolicyType\":\"NewWarrantyPolicy\",\"UpdateDate\":\"20220331\",\"coupons\":[]}}]}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
       
        Test.startTest();
        system.enqueueJob(new SyncDMSWarrantyFCS(date.today(), date.today(), 200, 0, 0, 0));
        Test.stopTest();
    } 
}