@isTest
public class BatchUpdateAccActivityDateTest {
	@isTest
    static void test()
    {
        Account acc = new Account();
        acc.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
        acc.LastName = 'Test';
        insert acc;
        
        Database.executeBatch(new BatchUpdateAccActivityDate(), 2000);  
        
        BatchUpdateAccActivityDate.addpoint();
    }
}