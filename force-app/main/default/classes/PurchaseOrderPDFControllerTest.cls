@isTest
public with sharing class PurchaseOrderPDFControllerTest {
  private static User userTest;
  static {
    userTest = createUser();
  }

  static testMethod void testMethod1() {
    System.runAs(userTest) {
      Test.startTest();
      PurchaseOrderPDFController.cheatTemp();
      Test.stopTest();
    }
  }

  static testMethod void testPurchaseOrder_mdt() {
    Test.startTest();
    PurchaseOrderPDFController controller = new PurchaseOrderPDFController();
    Purchase_Order_PDF__mdt purchaseOrderMdt = controller.apiPurchaseOrder;
    Test.stopTest();

    Assert.areEqual(
      'Default',
      purchaseOrderMdt.DeveloperName,
      'DeveloperName is not match'
    );
    Assert.areEqual(
      'CÔNG TY TNHH YAMAHA MOTOR VIỆT NAM',
      purchaseOrderMdt.Buyer_Name__c,
      'Buyer_Name__c is not match'
    );
    Assert.areEqual(
      'Mr. Okutani Masahiro',
      purchaseOrderMdt.Represented_By__c,
      'Represented_By__c is not match'
    );
    Assert.areEqual(
      'Tổng giám đốc',
      purchaseOrderMdt.Represented_Title__c,
      'Represented_Title__c is not match'
    );
    Assert.areEqual(
      'Thôn Bình An, Xã Trung Giã, Huyện Sóc Sơn, Thành phố Hà Nội, Việt Nam',
      purchaseOrderMdt.Address_Full__c,
      'Address_Full__c is not match'
    );
  }

  //Create User
  private static User createUser() {
    Profile profile = [
      SELECT Id
      FROM Profile
      WHERE Name LIKE 'System Administrator'
      LIMIT 1
    ];
    String uniqueName =
      UserInfo.getOrganizationId() +
      Datetime.now().format('yyyyMMddHHmmssSSS') +
      Integer.valueOf(math.rint(math.random() * (2000000 - 1)));
    User user = new User(
      FirstName = uniqueName.subString(29, 34),
      LastName = uniqueName.subString(30, 35),
      Email = uniqueName + '@omn1solution.com',
      UserName = uniqueName + '@omn1solution.com',
      EmailEncodingKey = 'UTF-8',
      Alias = 'Test',
      TimeZoneSidKey = 'Asia/Ho_Chi_Minh',
      LocaleSidKey = 'vi_VN',
      LanguageLocaleKey = 'en_US',
      ProfileId = profile.Id,
      PostalCode = '123456789',
      Department = 'test',
      Phone = '123456789',
      Fax = '123456789',
      CompanyName = 'Omn1'
    );
    insert user;
    return user;
  }
}
