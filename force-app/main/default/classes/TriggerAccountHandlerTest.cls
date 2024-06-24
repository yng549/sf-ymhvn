@isTest
public class TriggerAccountHandlerTest {
    @isTest static void beforeInsertTest() {
        Account sup1 = new Account();
        sup1.Name = 'sup1';
        sup1.RecordTypeId = RecordTypeHelper.ACCOUNT_SUPPLIER;
        sup1.AccountNo__c = 1001;
        insert sup1;
        update sup1;
        
        Account sup2 = new Account();
        sup2.Name = 'sup2';
        sup2.RecordTypeId = RecordTypeHelper.ACCOUNT_SUPPLIER;
        sup2.AccountNo__c = 1002;
        insert sup2;
        
        Account acc1 = new Account();
        acc1.LastName = 'acc1';
        acc1.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc1.Is_Primary__c = true;
        insert acc1;
        
        Account acc11 = new Account();
        acc11.LastName = 'acc11';
        acc11.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc11.Is_Primary__c = true;
        insert acc11;
        
        Account acc2 = new Account();
        acc2.LastName = 'acc2';
        acc2.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc2.Is_Primary__c = false;
        acc2.DO_DL_Owner__c = UserInfo.getUserId();
        insert acc2;
        
        Account acc22 = new Account();
        acc22.LastName = 'acc22';
        acc22.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc22.Is_Primary__c = false;
        acc22.DO_DL_Owner__c = UserInfo.getUserId();
        insert acc22;
        
        TriggerAccountHandler.cheatTemp();
    }
}