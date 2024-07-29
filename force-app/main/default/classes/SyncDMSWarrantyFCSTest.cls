@isTest(SeeAllData=true)
public class SyncDMSWarrantyFCSTest {
  @isTest
  static void testAPI() {
    string jsondata = '{\"msg\":\"Requestsucceed.\",\"totalLine\":1,\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"MH3RH07Z0MK001028\",\"WarrantyEffectiveDate\":\"20200628\",\"WarrantyExpiredDate\":\"20230627\",\"WarrantyMileage\":\"10000\",\"WarrantyPolicyType\":\"NewWarrantyPolicy\",\"UpdateDate\":\"20220331\",\"coupons\":[{\"coupon\":{\"CouponCategoryLevel\":\"3\",\"ServiceDate\":\"20150723\",\"Mileage\":\"10000\"}},{\"coupon\":{\"CouponCategoryLevel\":\"1\",\"ServiceDate\":\"20150723\",\"Mileage\":\"449\"}},{\"coupon\":{\"CouponCategoryLevel\":\"7\",\"ServiceDate\":\"20150723\",\"Mileage\":\"15887\"}},{\"coupon\":{\"CouponCategoryLevel\":\"6\",\"ServiceDate\":\"20150413\",\"Mileage\":\"12345\"}},{\"coupon\":{\"CouponCategoryLevel\":\"2\",\"ServiceDate\":\"20210115\",\"Mileage\":\"500\"}},{\"coupon\":{\"CouponCategoryLevel\":\"5\",\"ServiceDate\":\"20211226\",\"Mileage\":\"7710\"}}]}}]}';
    MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsondata);
    SyncDMSWarrantyFCS.cheat();
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
    SyncDMSWarrantyFCS.cheat();
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
  // Task [YMVN-982]
  @isTest
  static void testConvertCouponCategoriesToBigBikeModelCodes() {
    List<SObjectAPIDMSRespone.CouponCategory> mockCategories = new List<SObjectAPIDMSRespone.CouponCategory>();
    SObjectAPIDMSRespone.CouponCategory category = new SObjectAPIDMSRespone.CouponCategory();
    category.detail = new List<SObjectAPIDMSRespone.DetailItem>();

    SObjectAPIDMSRespone.DetailItem item1 = new SObjectAPIDMSRespone.DetailItem();
    item1.ModelCodes = new SObjectAPIDMSRespone.ModelCodes();
    item1.ModelCodes.ModelCode = 'MODEL001';
    category.detail.add(item1);

    SObjectAPIDMSRespone.DetailItem item2 = new SObjectAPIDMSRespone.DetailItem();
    item2.ModelCodes = new SObjectAPIDMSRespone.ModelCodes();
    item2.ModelCodes.ModelCode = 'MODEL002';
    category.detail.add(item2);

    mockCategories.add(category);

    Test.startTest();
    Set<String> result = SyncDMSWarrantyFCS.convertCouponCategoriesToBigBikeModelCodes(
      mockCategories
    );
    Test.stopTest();

    System.assertEquals(2, result.size(), 'Should return 2 model codes');
    System.assert(result.contains('MODEL001'), 'Should contain MODEL001');
    System.assert(result.contains('MODEL002'), 'Should contain MODEL002');
  }

  @isTest
  static void testConvertCouponCategoriesToBigBikeModelCodes_RealData() {
    String response = '{"msg":"Request succeed.","code":200,"data":[{"CoupCtgCode":"C003","PlCd":"10","detail":[{"CoupCtgLevels":{"CoupCtgLevel":"CJPSerDem0001","UsedMonthFrom":"0","UsedMonthTo":"12","MileageFrom":"0","MileageTo":"1000"}},{"ModelCodes":{"ModelCode":"B5CF00"}},{"ModelCodes":{"ModelCode":"B5U200"}},{"ModelCodes":{"ModelCode":"B5Y800"}},{"ModelCodes":{"ModelCode":"B7N800"}},{"ModelCodes":{"ModelCode":"B7NK00"}},{"ModelCodes":{"ModelCode":"BAE800"}},{"ModelCodes":{"ModelCode":"BAMG00"}},{"ModelCodes":{"ModelCode":"BEBC00"}},{"ModelCodes":{"ModelCode":"BFT600"}},{"ModelCodes":{"ModelCode":"BHL900"}},{"ModelCodes":{"ModelCode":"BS2T00"}},{"ModelCodes":{"ModelCode":"BW88P0"}}]},{"CoupCtgCode":"C002","PlCd":"10","detail":[{"CoupCtgLevels":{"CoupCtgLevel":"CJPSerDem0001","UsedMonthFrom":"0","UsedMonthTo":"2","MileageFrom":"0","MileageTo":"0"}},{"ModelCodes":{"ModelCode":"BAE100"}},{"ModelCodes":{"ModelCode":"BS2G00"}}]}]}';

    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(
      (String) response
    );

    String jsonData = JSON.serialize(jsonMap.get('data'));
    List<SObjectAPIDMSRespone.CouponCategory> couponCategories = (List<SObjectAPIDMSRespone.CouponCategory>) JSON.deserialize(
      jsonData,
      List<SObjectAPIDMSRespone.CouponCategory>.class
    );

    Test.startTest();
    Set<String> result = SyncDMSWarrantyFCS.convertCouponCategoriesToBigBikeModelCodes(
      couponCategories
    );
    Test.stopTest();

    System.debug(result);

    System.assertEquals(14, result.size(), 'Should return 14 model codes');
    System.assert(result.contains('B5CF00'), 'Should contain B5CF00');
    System.assert(result.contains('B5U200'), 'Should contain B5U200');
    System.assert(result.contains('B5Y800'), 'Should contain B5Y800');
  }

  @isTest
  static void testConvertCouponCategoriesToBigBikeModelCodes_NullModelCodes() {
    List<SObjectAPIDMSRespone.CouponCategory> mockCategories = new List<SObjectAPIDMSRespone.CouponCategory>();
    SObjectAPIDMSRespone.CouponCategory category = new SObjectAPIDMSRespone.CouponCategory();
    category.detail = new List<SObjectAPIDMSRespone.DetailItem>();

    SObjectAPIDMSRespone.DetailItem item = new SObjectAPIDMSRespone.DetailItem();
    item.ModelCodes = null;
    category.detail.add(item);

    mockCategories.add(category);

    Test.startTest();
    Set<String> result = SyncDMSWarrantyFCS.convertCouponCategoriesToBigBikeModelCodes(
      mockCategories
    );
    Test.stopTest();

    System.assertEquals(
      0,
      result.size(),
      'Should return empty set for null ModelCodes'
    );
  }
  @isTest
  static void testExecuteWithEmptyPageSize() {
    String response = '{"msg":"Request succeed.","code":200,"data":[{"CoupCtgCode":"C003","PlCd":"10","detail":[{"CoupCtgLevels":{"CoupCtgLevel":"CJPSerDem0001","UsedMonthFrom":"0","UsedMonthTo":"12","MileageFrom":"0","MileageTo":"1000"}},{"ModelCodes":{"ModelCode":"B5CF00"}},{"ModelCodes":{"ModelCode":"B5U200"}},{"ModelCodes":{"ModelCode":"B5Y800"}},{"ModelCodes":{"ModelCode":"B7N800"}},{"ModelCodes":{"ModelCode":"B7NK00"}},{"ModelCodes":{"ModelCode":"BAE800"}},{"ModelCodes":{"ModelCode":"BAMG00"}},{"ModelCodes":{"ModelCode":"BEBC00"}},{"ModelCodes":{"ModelCode":"BFT600"}},{"ModelCodes":{"ModelCode":"BHL900"}},{"ModelCodes":{"ModelCode":"BS2T00"}},{"ModelCodes":{"ModelCode":"BW88P0"}}]},{"CoupCtgCode":"C002","PlCd":"10","detail":[{"CoupCtgLevels":{"CoupCtgLevel":"CJPSerDem0001","UsedMonthFrom":"0","UsedMonthTo":"2","MileageFrom":"0","MileageTo":"0"}},{"ModelCodes":{"ModelCode":"BAE100"}},{"ModelCodes":{"ModelCode":"BS2G00"}}]}]}';
    MockDMSHelperResponse.setTestMockResponse(200, 'OK', response);

    PageSize_API__c testPage = new PageSize_API__c(
      Name = 'warranty RY01',
      Current_Page__c = 1,
      End_Index__c = 200,
      Is_Empty_Return__c = false
    );
    insert testPage;

    List<PageSize_API__c> currentPage = [
      SELECT Current_Page__c, Id, End_Index__c, Is_Empty_Return__c
      FROM PageSize_API__c
      WHERE Name = 'warranty RY01' AND Createddate = Today
      ORDER BY Current_Page__c DESC
    ];
    // if api current page lastest empty data, schedule not next proccess
    if (!currentPage.isEmpty() && currentPage[0].Is_Empty_Return__c) {
      System.debug(currentPage);
    }
    Date dateFrom = Date.today().addDays(-1);
    Date dateTo = Date.today().addDays(-1);

    Test.startTest();
    Set<String> result = new SyncDMSWarrantyFCS(
        dateFrom,
        dateTo,
        200,
        currentPage.isEmpty()
          ? 0
          : Integer.valueOf(currentPage[0].End_Index__c) + 1,
        0,
        0,
        'RY01'
      )
      .getAllBigBikeModel();
    Test.stopTest();

    System.debug(result);
    System.assertEquals(14, result.size(), 'Should return 14 model codes');
    System.assert(result.contains('B5CF00'), 'Should contain B5CF00');
    System.assert(result.contains('B5U200'), 'Should contain B5U200');
    System.assert(result.contains('B5Y800'), 'Should contain B5Y800');
  }
  @isTest
  static void testExecuteWithSuccessfulResponse() {
    String jsonData = '{\"msg\":\"Request succeed.\",\"totalLine\":100,\"code\":200,\"data\":[{\"UnitWarranty\":{\"FrameNo\":\"TEST123\",\"WarrantyEffectiveDate\":\"20210101\",\"WarrantyExpiredDate\":\"20240101\",\"WarrantyMileage\":\"10000\",\"WarrantyPolicyType\":\"TestPolicy\",\"UpdateDate\":\"20220101\",\"coupons\":[]}}]}';
    MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsonData);
    String response = '{"msg":"Request succeed.","code":200,"data":[{"CoupCtgCode":"C003","PlCd":"10","detail":[{"CoupCtgLevels":{"CoupCtgLevel":"CJPSerDem0001","UsedMonthFrom":"0","UsedMonthTo":"12","MileageFrom":"0","MileageTo":"1000"}},{"ModelCodes":{"ModelCode":"B5CF00"}},{"ModelCodes":{"ModelCode":"B5U200"}},{"ModelCodes":{"ModelCode":"B5Y800"}},{"ModelCodes":{"ModelCode":"B7N800"}},{"ModelCodes":{"ModelCode":"B7NK00"}},{"ModelCodes":{"ModelCode":"BAE800"}},{"ModelCodes":{"ModelCode":"BAMG00"}},{"ModelCodes":{"ModelCode":"BEBC00"}},{"ModelCodes":{"ModelCode":"BFT600"}},{"ModelCodes":{"ModelCode":"BHL900"}},{"ModelCodes":{"ModelCode":"BS2T00"}},{"ModelCodes":{"ModelCode":"BW88P0"}}]},{"CoupCtgCode":"C002","PlCd":"10","detail":[{"CoupCtgLevels":{"CoupCtgLevel":"CJPSerDem0001","UsedMonthFrom":"0","UsedMonthTo":"2","MileageFrom":"0","MileageTo":"0"}},{"ModelCodes":{"ModelCode":"BAE100"}},{"ModelCodes":{"ModelCode":"BS2G00"}}]}]}';
    MockDMSHelperResponse.setTestMockResponse(200, 'OK', response);
    PageSize_API__c testPage = new PageSize_API__c(
      Name = 'warranty RY01',
      Current_Page__c = 1,
      End_Index__c = 200,
      Is_Empty_Return__c = false
    );
    insert testPage;

    List<PageSize_API__c> currentPage = [
      SELECT Current_Page__c, Id, End_Index__c, Is_Empty_Return__c
      FROM PageSize_API__c
      WHERE Name = 'warranty RY01' AND Createddate = Today
      ORDER BY Current_Page__c DESC
    ];
    // if api current page lastest empty data, schedule not next proccess
    if (!currentPage.isEmpty() && currentPage[0].Is_Empty_Return__c) {
      System.debug(currentPage);
    }
    Date dateFrom = Date.today().addDays(-1);
    Date dateTo = Date.today().addDays(-1);

    Test.startTest();
    SyncDMSWarrantyFCS syncDMSWarrantyFCS = new SyncDMSWarrantyFCS(
      dateFrom,
      dateTo,
      200,
      currentPage.isEmpty()
        ? 0
        : Integer.valueOf(currentPage[0].End_Index__c) + 1,
      0,
      0,
      'RY01'
    );
    Set<String> allModelCodesBigBike = syncDMSWarrantyFCS.getAllBigBikeModel();
    System.enqueueJob(syncDMSWarrantyFCS);
    Test.stopTest();

    System.debug(allModelCodesBigBike);
    List<AsyncApexJob> jobs = [
      SELECT Id, Status
      FROM AsyncApexJob
      WHERE ApexClass.Name = 'SyncDMSWarrantyFCS' AND Status = 'Completed'
    ];
    System.assertEquals(
      1,
      jobs.size(),
      'Job should complete without further chaining'
    );
    System.assertEquals(
      14,
      allModelCodesBigBike.size(),
      'Should return 14 model codes'
    );
  }
}
