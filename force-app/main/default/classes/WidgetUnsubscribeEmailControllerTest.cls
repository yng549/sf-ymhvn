@IsTest
public class WidgetUnsubscribeEmailControllerTest {
  @testSetup
  static void setup() {
    Contact ct = new Contact();
    ct.FirstName = 'Test Contact';
    ct.LastName = 'Test Contact';
    ct.Email = 'trueexample@example.com';
    upsert ct;
    Lead ld = new Lead();
    ld.FirstName = 'Test Contact';
    ld.LastName = 'Test Contact';
    ld.Email = 'trueexample@example.com';
    upsert ld;
  }

  @isTest
  static void unsubscribeEmailTest() {
    WidgetUnsubscribeEmailController.unsubscribeEmail('example@example.com');
    WidgetUnsubscribeEmailController.unsubscribeEmail(
      'trueexample@example.com'
    );
  }
}
