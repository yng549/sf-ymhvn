@isTest(SeeAllData=true)
public class APIDMSPartInformationTest {
    // IV.3 partinformation Data
    @isTest
    static void testSyncPartSuccess() {
        String jsonreq = '{\"msg\":\"Requestsucceed.\",\"code\":200,\"data\":[{\"PartNo\":\"A21BG102B00S\",\"PartNameEng\":\"retainer,ballbearing\",\"PartNameNative\":\"biphuốc\",\"SupersedingPart\":\"A21BG102B00M\",\"ProductCategory\":\"SI\",\"PartSizeHigh\":null,\"PartSizeWidth\":null,\"PartSizeLong\":null,\"PartWeight\":null,\"PurchaseLot\":1,\"SalesLot\":1,\"NonSalesId\":\"0\",\"RetailPrice\":9091,\"WholeSales\":9091,\"RetailPriceRevisionDate\":\"20220420\",\"WholeSalesRevisionDate\":\"20220420\",\"SupersedingRevisionDate\":\"\",\"OptionCode1\":\"\",\"OptionName1\":\"\",\"RegisterDate\":\"20010117\",\"DealerCode\":\"RY01\",\"PointCode\":\"RY01A\",\"PartsId\":\"9718148d-6497-49d5-bf26-3584f3f44e35\",\"CreateDate\":\"20211227\",\"LastModify\":\"20211227\",\"UpdateDate\":\"20211227\"},{\"PartNo\":\"A21BG102B00S\",\"PartNameEng\":\"retainer,ballbearing\",\"PartNameNative\":\"biphuốc\",\"SupersedingPart\":\"A21BG102B00M\",\"ProductCategory\":\"SI\",\"PartSizeHigh\":null,\"PartSizeWidth\":null,\"PartSizeLong\":null,\"PartWeight\":null,\"PurchaseLot\":1,\"SalesLot\":1,\"NonSalesId\":\"0\",\"RetailPrice\":9091,\"WholeSales\":9091,\"RetailPriceRevisionDate\":\"20220420\",\"WholeSalesRevisionDate\":\"20220420\",\"SupersedingRevisionDate\":\"\",\"OptionCode1\":\"\",\"OptionName1\":\"\",\"RegisterDate\":\"20010117\",\"DealerCode\":\"RY01\",\"PointCode\":\"RY01A\",\"PartsId\":\"9718148d-6497-49d5-bf26-3584f3f44e35\",\"CreateDate\":\"20211227\",\"LastModify\":\"20211227\",\"UpdateDate\":\"20211227\"}],\"totalLine\":2}';
        MockDMSHelperResponse.setTestMockResponse(200, 'OK', jsonreq);
        Test.startTest();
        Date dateFrom = Date.today().addDays(-1);
        Date dateTo = Date.today().addDays(-1);
        system.enqueueJob(
            new APIDMSPartInformation(dateFrom, dateTo, 200, 0, 0, 0, 'RY01')
        );
        Test.stopTest();
    }
    @isTest
    static void testSyncPartHCMSuccess() {
        Test.startTest();
        System.schedule(
            'Auto Sync Part HCM DMS Test',
            '0 0 6 * * ?',
            new ScheduleDMSSyncPartInfo()
        );
        Test.stopTest();
    }
    @isTest
    static void testSyncPartHNSuccess() {
        Test.startTest();
        System.schedule(
            'Auto Sync Part HN Test',
            '0 0 6 * * ?',
            new SchedulePartInfoHN()
        );
        Test.stopTest();
    }
}
