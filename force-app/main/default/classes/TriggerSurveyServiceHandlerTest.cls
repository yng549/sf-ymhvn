@isTest
public class TriggerSurveyServiceHandlerTest {
	@isTest
    public static void test()
    {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EinvoiceMockResponse());
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Id = Test.getStandardPricebookId();
        pricebook.IsActive = true;
        update pricebook;
        
        Account dodl = new Account();
        dodl.RecordTypeId = RecordTypeHelper.ACCOUNT_DODL;
        dodl.Name = 'Test';
        dodl.Einvoice_Location__c = 'Hà Nội';
        insert dodl;
        
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc.LastName = 'Test';
        insert acc;
        
        Opportunity opty = new Opportunity();
        opty.RecordTypeId = RecordTypeHelper.OPPORTUNITY_BIKE;
        opty.Name = 'Test';
        opty.AccountId = acc.Id;
        opty.StageName = 'New';
        opty.CloseDate = Date.today() + 7;
        opty.Enable_Round_Robin__c = false;
        opty.Pricebook2Id = Test.getStandardPricebookId();
        opty.Amount = 100;
        insert opty;
        
        Order order = new Order();
        order.RecordTypeId = RecordTypeHelper.ORDER_BIKE;
        order.Pricebook2Id = Test.getStandardPricebookId();
        order.AccountId = acc.Id;
        order.DO_DL__c = dodl.Id;
        order.OpportunityId = opty.Id;
        order.Status = 'Draft';
        order.EndDate = Date.today() + 1;
        order.EffectiveDate = Date.today();
        order.Tax_Address__c = 'Test';
        order.Tax_Code__c = 'TaxCode';
        order.Tax_Mobile__c = '0907868802';
        order.Payment_Method__c = 'Cash';
        
        insert order;
        
        Product2 p = new Product2();
        p.Name = 'Test Product';
        p.Description='Test Product';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = Test.getStandardPricebookId();
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 100;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
                
        OrderItem item = new OrderItem();
        item.OrderId = order.Id;
        item.UnitPrice = 2000;
        item.Product2Id = p.Id;
        item.Quantity = 1;
        item.PricebookEntryId = standardPrice.Id;
        insert item;
        
        SurveyService__c survey = new SurveyService__c();
        survey.AccountPersonal__c = acc.Id;
        survey.AccountDealer__c = dodl.Id;
        survey.Order__c = order.Id;
        survey.Question_0__c = 'Yes';
        survey.Question_1__c = '7';
        survey.Question_3_1__c = '7';
        survey.Question_3_2__c = '7';
        survey.Question_5__c = '7';
       	survey.Question_6__c = '7';
        survey.Question_7__c = '7';
        survey.Question_8__c = '7';
        survey.Question_9__c = 'Yes';
        survey.Question_10__c = 'Yes';
        survey.Question_11__c = 'Yes';
        survey.Question_13__c = 'Yes';
        survey.Question_14__c = 'Yes';
        survey.Question_15__c = 'Yes';
        survey.Question_16__c = '7';
        survey.Question_17__c = '7';
        survey.Question_18__c = '7';
        survey.Question_19__c = 'Yes';
        survey.Question_20__c = 'Yes';
        survey.Question_2__c = '7';
        insert survey;
        
        SurveyService__c survey2 = new SurveyService__c();
        survey2.AccountPersonal__c = acc.Id;
        survey2.AccountDealer__c = dodl.Id;
        survey2.Order__c = order.Id;
        survey2.Question_0__c = 'Yes';
        survey2.Question_1__c = '2';
        survey2.Question_3__c = '2';
        survey2.Question_3__c = 'Yes';
        survey2.Question_3_1__c = '2';
        survey2.Question_3_2__c = '2';
        survey2.Question_5__c = '2';
       	survey2.Question_6__c = '2';
        survey2.Question_7__c = '2';
        survey2.Question_8__c = '2';
        survey2.Question_9__c = 'No';
        survey2.Question_10__c = 'No';
        survey2.Question_11__c = 'No';
        survey2.Question_13__c = 'No';
        survey2.Question_14__c = 'No';
        survey2.Question_15__c = 'No';
        survey2.Question_16__c = '2';
        survey2.Question_17__c = '2';
        survey2.Question_18__c = '2';
        survey2.Question_19__c = 'No';
        survey2.Question_20__c = 'No';
        survey2.Question_2__c = '2';
        insert survey2;
        
        update survey2;
        Test.stopTest();
        
        
    }
}