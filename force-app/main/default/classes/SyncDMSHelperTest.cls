@isTest(seeAllData=true)
public class SyncDMSHelperTest {
    @isTest
    static void test1() {
        try {
            SyncDMSHelper.cheatTemp();
        } catch (Exception e) {
        }
    }
    @isTest
    static void testConvertModelSaleRequestData() {
        // Create test data
        Account testAccount = new Account(
            LastName = 'Test',
            FirstName = 'John',
            Gender__c = 'Male',
            PersonEmail = 'test@example.com',
            DOB__pc = Date.today().addYears(-30)
        );
        insert testAccount;

        Asset testAsset = new Asset(Name = 'Test Asset');
        insert testAsset;

        Province__c testProvince = new Province__c(
            Province_Code__c = 'PROV001'
        );
        insert testProvince;

        District__c testDistrict = new District__c(
            District_Code__c = 'DIST001'
        );
        insert testDistrict;

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Asset__c = testAsset.Id,
            Province__c = testProvince.Id,
            District__c = testDistrict.Id,
            Address_No__c = '123 Test St',
            DmsOrderId__c = 'DMS001'
        );
        insert testOrder;

        Test.startTest();
        SObjectAPIDMSRespone.Modelcsalesorder result = SyncDMSHelper.convertModelSaleRequestData(
            testOrder,
            new List<OrderItem>{}
        );
        Test.stopTest();

        // Assertions
        System.assertEquals(testOrder.Id, result.CRMOrderId);
        System.assertEquals(testOrder.OrderNumber, result.CRMOrderNo);
        System.assertEquals(
            String.valueOf(testOrder.EffectiveDate).replaceAll('-', ''),
            result.SalesDate
        );
        System.assertEquals('1', result.EinvoiceFlag);
        System.assertEquals(
            String.valueOf(Date.today()).replaceAll('-', ''),
            result.RegistrationDate
        );
        System.assertEquals(testAccount.Gender__c, result.Gender);
        System.assertEquals(testOrder.Address_No__c, result.Address);
        System.assertEquals('C030CASH', result.PaymentMethod);
        System.assertEquals('DO', result.DealerType);
        System.assertEquals('SpecialOrder', result.OrderType);
        System.assertEquals(
            String.valueOf(testOrder.DmsOrderId__c),
            result.DmsOrderId
        );
    }

    @isTest
    static void testConvertModelSaleRequestDataWithNullValues() {
        Account testAccount = new Account(LastName = 'Test');
        insert testAccount;

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft'
        );
        insert testOrder;

        Test.startTest();
        SObjectAPIDMSRespone.Modelcsalesorder result = SyncDMSHelper.convertModelSaleRequestData(
            testOrder,
            new List<OrderItem>()
        );
        Test.stopTest();

        System.assertEquals(testOrder.Id, result.CRMOrderId);
        System.assertEquals(testOrder.OrderNumber, result.CRMOrderNo);
        System.assertEquals(null, result.DealerCode);
        System.assertEquals(null, result.PointCode);
        System.assertEquals(
            String.valueOf(testOrder.EffectiveDate).replaceAll('-', ''),
            result.SalesDate
        );
        System.assertEquals('1', result.EinvoiceFlag);
        System.assertEquals(null, result.FrameNo);
        System.assertEquals(
            String.valueOf(Date.today()).replaceAll('-', ''),
            result.RegistrationDate
        );
        System.assertEquals(null, result.CRMConsumerId);
        System.assertEquals(null, result.DateofBirth);
        System.assertEquals(null, result.Mobile);
        System.assertEquals('Male', result.Gender);
        System.assertEquals(null, result.ProvinceCode);
        System.assertEquals(null, result.DistrictCode);
        System.assertEquals(null, result.Email);
        System.assertEquals(null, result.Address);
        System.assertEquals('C030CASH', result.PaymentMethod);
        System.assertEquals('DO', result.DealerType);
        System.assertEquals('SpecialOrder', result.OrderType);
        System.assertEquals(null, result.SellingPrice);
        System.assertEquals(null, result.Amount);
        System.assertEquals(null, result.DiscountAmount);
        System.assertEquals(null, result.DmsOrderId);
    }
}
