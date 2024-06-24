@isTest(SeeAllData=true)
public with sharing class BatchCleanDataStorageTest {
    public BatchCleanDataStorageTest() {

    }
	public static final String CRON_EXPR = '0 0 6 1 1/1 ? *';
    @isTest static void test(){

        Product2 prod = new Product2(
            Name = 'Product Test',
            Bike_cc__c = '<400cc'
        );
        insert prod;
        Product2 product = [SELECT Id, Name FROM Product2 WHERE Id =: prod.Id][0];
        // List<Product2> lstInsert = new List<Product2>();
        Stock_History__c historyStock = new Stock_History__c();
        historyStock.Name = product.Name + ' ' + System.today().format();
        historyStock.Date__c = System.today().addMonths(-3);
        historyStock.Product__c = product.Id;
        historyStock.Number_In__c = 0;
        historyStock.Number_Out__c = 0;
        // lstInsert.add(historyStock);
        insert historyStock;

        test.startTest();
        system.schedule('Clean up Data Histories 1', CRON_EXPR, new ScheduleCleanDataStorage());
        test.stopTest();
    }
}