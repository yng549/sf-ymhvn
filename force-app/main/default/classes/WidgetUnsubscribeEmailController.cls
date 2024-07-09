public without sharing class WidgetUnsubscribeEmailController {
  @AuraEnabled
  public static Boolean unsubscribeEmail(String email) {
    List<Contact> contacts = [
      SELECT Id, Name, HasOptedOutOfEmail
      FROM Contact
      WHERE Email = :email
    ];
    List<Lead> leads = [
      SELECT Id, Name, HasOptedOutOfEmail
      FROM Lead
      WHERE Email = :email
    ];

    Boolean success = true;

    if (!contacts.isEmpty()) {
      for (Contact contact : contacts) {
        contact.HasOptedOutOfEmail = true;
      }
      try {
        update contacts;
      } catch (Exception e) {
        success = false;
        System.debug(e);
      }
    }
    if (!leads.isEmpty()) {
      for (Lead lead : leads) {
        lead.HasOptedOutOfEmail = true;
      }
      try {
        update leads;
      } catch (Exception e) {
        success = false;
        System.debug(e);
      }
    }
    return success;
  }
}
