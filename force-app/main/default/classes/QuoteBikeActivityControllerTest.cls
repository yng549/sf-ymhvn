@isTest
public with sharing class QuoteBikeActivityControllerTest {
    static testMethod void testMethod1() {
        Opportunity opty = new Opportunity(Name ='Test',
                                           StageName = 'Completed',
                                           CloseDate = System.today());
        insert opty;
        Quote qo = new Quote(Name = 'Test', 
                             OpportunityId = opty.Id,
                             Email = 'Test@Gmail.com');
        insert qo;
        Test.startTest();
        QuoteBikeActivityController.getQuoteActivity(qo.Id);
           QuoteBikeActivityController.getQuoteActivity('qo.Id');
        Test.stopTest();
    }
    
}