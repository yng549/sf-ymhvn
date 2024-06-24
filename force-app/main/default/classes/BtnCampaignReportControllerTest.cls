@isTest
public class BtnCampaignReportControllerTest {
	@isTest
    static void test()
    {
       
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
              
        // insert product
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description='Test Product Entry For Product';
        p.productCode = 'SFDCPanther-123';
        p.isActive = true;
        insert p;
        
        // insert pricebook entry for the product
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = Test.getStandardPricebookId();
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 100;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        
        // insert account
        Account acc = new Account(
            Name = 'SFDCPanther.com',
            Rating = 'Hot',
            Industry = 'Banking',
            Phone = '9087654321'
        );
        insert acc;
        
        // Create Opportunity
        Opportunity opp = new Opportunity();
        opp.AccountId = acct.Id;
        opp.Name = 'Test Opportunity';
        opp.CloseDate= System.Today();
        opp.StageName='Qualification';
        opp.Pricebook2Id = Test.getStandardPricebookId();
        insert opp;
        
        // Add product and Pricebook to the particular opportunity using OpportunityLineItem 
        OpportunityLineItem oppLineItem = new OpportunityLineItem();
        oppLineItem.OpportunityId = opp.Id;
        oppLineItem.PricebookEntryId = standardPrice.Id;
        oppLineItem.UnitPrice = 7000;
        oppLineItem.Quantity = 5;
        //insert oppLineItem;
        //update oppLineItem;
       
        
        Campaign camp = new Campaign(
            Name = 'Test',
            IsActive = TRUE,
            StartDate = Date.today() - 30
        );            
        insert camp;
          
        
        Lead l = new Lead();
        l.LastName = 'test';
        l.DO_DL_Code__c = 'test';
        l.DO_DL_Create__c = acc.Id;
        insert l;
        
        CampaignMember member2 = new CampaignMember(
            LeadId = l.Id,
            Status = 'sent',
            CampaignId = camp.Id
        ); 
        insert member2; 
        
        Lead l2 = new Lead();
        l2.LastName = 'test';
        l2.DO_DL_Code__c = 'test';
        l2.DO_DL_Create__c = acc.Id;
        insert l2;
        Test.setCreatedDate(l2.Id, Date.today().addDays(-10));
        
        Lead l3 = new Lead();
        l3.LastName = 'test';
        l3.DO_DL_Code__c = 'test';
        l3.DO_DL_Create__c = acc.Id;
        insert l3;
        
        
		Order o = new Order();
        o.OpportunityId = opp.Id;
        o.Status = 'Completed';
        
        Order o2 = new Order();
        o2.RecordTypeId = RecordTypeHelper.ORDER_BIKE;
        o2.OpportunityId = opp.Id;
        o2.Status = 'Completed';
        //insert o2;
        
        
        CampaignMember member = new CampaignMember(
            ContactId = con.Id,
            Status = 'sent',
            CampaignId = camp.Id
        ); 
        insert member; 
        
        CampaignMember member3 = new CampaignMember(
            LeadId = l2.Id,
            Status = 'sent',
            CampaignId = camp.Id
        ); 
        insert member3; 
        
        CampaignMember member4 = new CampaignMember(
            LeadId = l3.Id,
            Status = 'sent',
            CampaignId = camp.Id,
            Old_Lead_2__c = true
        ); 
        insert member4; 
        
        
        update member;
        
        test.startTest();
        
        BtnCampaignReportController.calculateCamp(camp.Id);
        
        BtnCampaignReportController.addP();
        
        test.stopTest();
    }
}