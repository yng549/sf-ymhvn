@isTest
public class ScheduleAfterSalePCATest {
    @TestSetup static void setupData(){
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
        
        Contact contact = new Contact();
        contact.LastName = 'Test';
        insert contact;
        
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
        
        Order order = new Order( RecordTypeId = RecordTypeHelper.ORDER_PCA,
                                Pricebook2Id = Test.getStandardPricebookId(),
                                AccountId = acc.Id,
                                DO_DL__c = dodl.Id,
                                OpportunityId = opty.Id,
                                Status = 'Draft',
                                EndDate = Date.today() + 1,
                                EffectiveDate = Date.today(),
                                Tax_Address__c = 'Test',
                                Tax_Code__c = 'TaxCode',
                                Tax_Mobile__c = '0907868802',
                                Payment_Method__c = 'Cash',
                                Invoice_Date__c = Date.today(),
                                Is_Payment__c = true,
                                Delivery_Date__c = Date.today());
        
        insert order;
        Order_Account__c orderAcc = new Order_Account__c( RecordTypeId = RecordTypeHelper.ORDER_ACCOUNT_PCA,
                                                         Order__c = order.Id,
                                                         Account__c = acc.Id);
        
        insert orderAcc;
        
        Task task = new Task(Subject = 'Test',
                             Status = 'Open',
                             WhatId = orderAcc.Id,
                             ActivityDate = Date.today().addDays(-1),
                             Task_Name__c = '14 Days');
        insert task;
    }
    @isTest static void method1(){
        System.schedule('ScheduleAfterSalePCA Everyday at 1:00', '0 0 1 * * ?', new ScheduleAfterSalePCA());
        Database.executeBatch(new BatchAfterSalePCA());
    }
}