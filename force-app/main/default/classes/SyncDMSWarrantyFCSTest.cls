@isTest(SeeAllData=true)
public class SyncDMSWarrantyFCSTest {
    @isTest
    static void testAPI() {
        string jsondata = '{\"msg\":\"Requestsucceed.\",\"totalLine\":1,\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"MH3RH07Z0MK001028\",\"WarrantyEffectiveDate\":\"20200628\",\"WarrantyExpiredDate\":\"20230627\",\"WarrantyMileage\":\"10000\",\"WarrantyPolicyType\":\"NewWarrantyPolicy\",\"UpdateDate\":\"20220331\",\"coupons\":[{\"coupon\":{\"CouponCategoryLevel\":\"3\",\"ServiceDate\":\"20150723\",\"Mileage\":\"10000\"}},{\"coupon\":{\"CouponCategoryLevel\":\"1\",\"ServiceDate\":\"20150723\",\"Mileage\":\"449\"}},{\"coupon\":{\"CouponCategoryLevel\":\"7\",\"ServiceDate\":\"20150723\",\"Mileage\":\"15887\"}},{\"coupon\":{\"CouponCategoryLevel\":\"6\",\"ServiceDate\":\"20150413\",\"Mileage\":\"12345\"}},{\"coupon\":{\"CouponCategoryLevel\":\"2\",\"ServiceDate\":\"20210115\",\"Mileage\":\"500\"}},{\"coupon\":{\"CouponCategoryLevel\":\"5\",\"ServiceDate\":\"20211226\",\"Mileage\":\"7710\"}}]}}]}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
        // SyncDMSWarrantyFCS.cheat();
        Test.startTest();
        System.schedule(
            'Auto Sync war DMS',
            '0 30 7 * * ?',
            new ScheduleSyncWarrantyFCS()
        );
        Test.stopTest();
    }
    @isTest
    static void testAPIHN() {
        string jsondata = '{\"msg\":\"Requestsucceed.\",\"totalLine\":1,\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"MH3RH07Z0MK001028\",\"WarrantyEffectiveDate\":\"20200628\",\"WarrantyExpiredDate\":\"20230627\",\"WarrantyMileage\":\"10000\",\"WarrantyPolicyType\":\"NewWarrantyPolicy\",\"UpdateDate\":\"20220331\",\"coupons\":[{\"coupon\":{\"CouponCategoryLevel\":\"3\",\"ServiceDate\":\"20150723\",\"Mileage\":\"10000\"}},{\"coupon\":{\"CouponCategoryLevel\":\"1\",\"ServiceDate\":\"20150723\",\"Mileage\":\"449\"}},{\"coupon\":{\"CouponCategoryLevel\":\"7\",\"ServiceDate\":\"20150723\",\"Mileage\":\"15887\"}},{\"coupon\":{\"CouponCategoryLevel\":\"6\",\"ServiceDate\":\"20150413\",\"Mileage\":\"12345\"}},{\"coupon\":{\"CouponCategoryLevel\":\"2\",\"ServiceDate\":\"20210115\",\"Mileage\":\"500\"}},{\"coupon\":{\"CouponCategoryLevel\":\"5\",\"ServiceDate\":\"20211226\",\"Mileage\":\"7710\"}}]}}]}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
        // SyncDMSWarrantyFCS.cheat();
        Test.startTest();
        System.schedule(
            'Auto Sync Warranty HN',
            '0 30 7 * * ?',
            new ScheduleWarrantyHNFCS()
        );
        Test.stopTest();
    }
    @isTest
    static void testAPI1() {
        string jsondata = '{\"msg\":\"Requestsucceed.\",\"totalLine\":1,\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"JYARN6970MA000343\",\"WarrantyEffectiveDate\":\"20200628\",\"WarrantyExpiredDate\":\"20230627\",\"WarrantyMileage\":\"10000\",\"WarrantyPolicyType\":\"NewWarrantyPolicy\",\"UpdateDate\":\"20220331\",\"coupons\":[{\"coupon\":{\"CouponCategoryLevel\":\"1\",\"ServiceDate\":\"20150723\",\"Mileage\":\"10000\"}}]}}]}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);

        Test.startTest();
        System.schedule(
            'Auto Sync war DMS',
            '0 30 7 * * ?',
            new ScheduleSyncWarrantyFCS()
        );
        Test.stopTest();
    }
    @isTest
    static void testAPI3() {
        string jsondata = '{\"msg\":\"Requestsucceed.\",\"totalLine\":1,\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"JYARN7040MA000422\",\"WarrantyEffectiveDate\":\"20200628\",\"WarrantyExpiredDate\":\"20230627\",\"WarrantyMileage\":\"10000\",\"WarrantyPolicyType\":\"NewWarrantyPolicy\",\"UpdateDate\":\"20220331\",\"coupons\":[]}}]}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);

        Test.startTest();
        System.schedule(
            'Auto Sync war DMS',
            '0 30 7 * * ?',
            new ScheduleSyncWarrantyFCS()
        );
        Test.stopTest();
    }
    @isTest
    static void testAPI2() {
        string jsondata = '{\"msg\":\"Requestsucceed.\",\"totalLine\":1,\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"JYARN4570MA000606\",\"WarrantyEffectiveDate\":\"20200628\",\"WarrantyExpiredDate\":\"20230627\",\"WarrantyMileage\":\"10000\",\"WarrantyPolicyType\":\"NewWarrantyPolicy\",\"UpdateDate\":\"20220331\",\"coupons\":[]}}]}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);

        Test.startTest();
        System.schedule(
            'Auto Sync war DMS',
            '0 30 7 * * ?',
            new ScheduleSyncWarrantyFCS()
        );
        Test.stopTest();
    }

    // Additional test classes
    @isTest
    static void testCreateDateLevelData() {
        // Create mock data
        SObjectAPIDMSRespone.WarrantyItem unitWarranty = new SObjectAPIDMSRespone.WarrantyItem();
        unitWarranty.WarrantyEffectiveDate = '20210901';

        Test.startTest();
        Date lastValidDateTo = SyncDMSWarrantyFCS.testCreateDateLevelData(
            unitWarranty
        );
        Test.stopTest();

        Date expectedLastDate = SyncDMSHelper.convertFormatDate('20241031');

        Assert.areEqual(
            expectedLastDate,
            lastValidDateTo,
            'Date to is not correct'
        );
    }

    @isTest
    static void testCreateDateLevelDataWithIsTestVisible() {
        SObjectAPIDMSRespone.WarrantyItem unitWarranty = new SObjectAPIDMSRespone.WarrantyItem();
        unitWarranty.WarrantyEffectiveDate = '20210901';

        Test.startTest();
        Map<Integer, SyncDMSWarrantyFCS.WarrantyDateValid> actualDateLevelData = SyncDMSWarrantyFCS.createDateLevelData(
            unitWarranty
        );
        Test.stopTest();

        System.debug('Actual value' + actualDateLevelData);

        Map<Integer, SyncDMSWarrantyFCS.WarrantyDateValid> expectedDateLevelData = new Map<Integer, SyncDMSWarrantyFCS.WarrantyDateValid>();
        expectedDateLevelData.put(
            1,
            new SyncDMSWarrantyFCS.WarrantyDateValid(
                SyncDMSHelper.convertFormatDate('20210901'),
                SyncDMSHelper.convertFormatDate('20211231')
            )
        );
        expectedDateLevelData.put(
            2,
            new SyncDMSWarrantyFCS.WarrantyDateValid(
                SyncDMSHelper.convertFormatDate('20220101'),
                SyncDMSHelper.convertFormatDate('20220630')
            )
        );
        expectedDateLevelData.put(
            8,
            new SyncDMSWarrantyFCS.WarrantyDateValid(
                SyncDMSHelper.convertFormatDate('20240301'),
                SyncDMSHelper.convertFormatDate('20240630')
            )
        );
        expectedDateLevelData.put(
            9,
            new SyncDMSWarrantyFCS.WarrantyDateValid(
                SyncDMSHelper.convertFormatDate('20240701'),
                SyncDMSHelper.convertFormatDate('20241031')
            )
        );

        for (Integer dateKey : expectedDateLevelData.keySet()) {
            if (actualDateLevelData.containsKey(dateKey)) {
                Assert.areEqual(
                    expectedDateLevelData.get(dateKey).dateFrom,
                    actualDateLevelData.get(dateKey).dateFrom,
                    'From Date is not correct'
                );
                Assert.areEqual(
                    expectedDateLevelData.get(dateKey).dateTo,
                    actualDateLevelData.get(dateKey).dateTo,
                    'To date is not correct'
                );
            }
        }
    }
}
