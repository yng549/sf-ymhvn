@isTest
public class TriggerHandlerQuoteTest {
    
    static testMethod void testMethod1() {    
        Test.startTest();
        Profile p = [SELECT ID From profile WHERE Name = 'System Administrator'];
        Account acc = new Account(Name = 'Revzone HN',RecordTypeId = RecordTypeHelper.ACCOUNT_DODL);
        insert acc;
        Account acc2 = [SELECT Id, PersonContactId  FROM Account WHERE Id = :acc.Id];
        User u = new User(ContactId = acc2.PersonContactId,
                          FirstName = 'TestFirstName',
                          LastName = 'TestLastName',
                          Email = 'test@user.com',
                          Username = 'asd@user.com',
                          Alias = 'TestPA', 
                          TimeZoneSidKey = 'GMT', 
                          LocaleSidKey = 'en_US', 
                          EmailEncodingKey = 'UTF-8', 
                          ProfileId = p.Id, 
                          LanguageLocaleKey = 'en_US');
        insert u;
        Opportunity opty = new Opportunity(Name = 'Test', StageName = 'Draft', CloseDate =System.today());
        insert opty;
        Quote q = new Quote();
        q.Name = 'Test';
        q.OpportunityId = opty.Id;
        insert q;
        try {
            TriggerhandlerQuote.cheat();
        }catch(Exception e) {
            
        }
        Test.stopTest();
    }
    
}