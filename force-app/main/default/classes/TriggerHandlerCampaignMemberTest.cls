@isTest
public class TriggerHandlerCampaignMemberTest {
	 static testMethod void testMethod1() {
       	test.startTest();
         	Account acct = new Account (Name = 'Acme, Inc.');
             insert acct;
             system.debug('Inserted Account, ID: ' + acct.id);
            
            Contact con = new Contact(
                              FirstName = 'Robin',
                              LastName = 'Koehler',
                              AccountId = acct.Id
                              );
            insert con;   
            
            
            Contact con1 = new Contact(
                FirstName = 'Robin',
                LastName = 'Koehler',
                AccountId = acct.Id
            );
            insert con1;  
            
            Campaign camp = new Campaign(
                Name = 'Test',
                IsActive = TRUE
            );            
            insert camp;
            
            
             
            
            CampaignMember member = new CampaignMember(
                ContactId = con.Id,
                Status = 'sent',
                CampaignId = camp.Id
            ); 
            insert member; 
            
            
            update member;
        	TriggerHandlerCampaignMember.cheat();
        test.stopTest();
    }
}