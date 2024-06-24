@isTest
public with sharing class SaleOrderPCAPDFControllerTest {
    private static User userTest;
    static {
      userTest = createUser();
    }
  
    static testMethod void testMethod1() {
      System.runAs(userTest) {
        Test.startTest();
        SaleOrderPCAPDFController.cheatTemp();
        Test.stopTest();
      }
    }
  
    private static Account createAccount() {
      Account a = new Account();
      a.Name = 'Test Account';
      insert a;
      return a;
    }
  
    private static Product2 createProduct2() {
      // Insert Product
      Product2 p = new Product2();
      p.Name = ' Test Product ';
      p.Description = 'Test Product Entry 1';
      p.productCode = 'ABC';
      p.isActive = true;
      p.Model__c = 'Yamaha';
      p.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName()
        .get('PCA')
        .getRecordTypeId();
      p.Bike_cc__c = '>400cc';
      insert p;
      return p;
    }
  
    private static PricebookEntry createPriceBook(
      String strIdProd2,
      String pricebookId
    ) {
      // Insert PricebookEntry
      PricebookEntry standardPrice = new PricebookEntry();
      standardPrice.Pricebook2Id = pricebookId;
      standardPrice.Product2Id = strIdProd2;
      standardPrice.UnitPrice = 1;
      standardPrice.IsActive = true;
      standardPrice.UseStandardPrice = false;
      insert standardPrice;
      return standardPrice;
    }
  
    private static Order createOrder(String accountId, Id pricebookId) {
      Order o = new Order();
      o.Name = 'Test Order ';
      o.Status = 'Draft';
      o.EffectiveDate = system.today();
      o.EndDate = system.today() + 4;
      o.AccountId = accountId;
      o.RecordTypeId = RecordTypeHelper.ORDER_APPRAISAL;
      o.Pricebook2Id = pricebookId;
  
      insert o;
      return o;
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