@isTest
public with sharing class RemoveVietnameseToneTest {
    private static User userTest;
  static {
    userTest = createUser();
  }

  static testMethod void testMethod1() {
    System.runAs(userTest) {
      Test.startTest();
      RemoveVietnameseTone.RemoveTone('Ý Leas Mọt');
      RemoveVietnameseTone.RemoveToneProvince('Province asdasdsa');
      RemoveVietnameseTone.RemoveToneProvince('City asdasdsa');
      Test.stopTest();
    }
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