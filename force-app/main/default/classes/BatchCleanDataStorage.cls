public with sharing class BatchCleanDataStorage extends BaseBatchHandler{
    public BatchCleanDataStorage() {
        this.objectName = 'Stock_History__c';
    }

    public override Database.QueryLocator start(Database.BatchableContext BC){
        // Get data lastest 2 months after that delete all of them.
        Date ondate = Date.today().addMonths(-2);
        List<string> query = new List<string>();
        query.add('SELECT Id ');
        query.add('FROM ' + objectName);
        query.add('WHERE Date__c <: ondate');
        if(Test.isRunningTest()) {
            query.add('LIMIT 200');
        }
        return Database.getQueryLocator(string.join(query, ' '));
    }

    public override List<SObject> processData(List<SObject> records){
        delete records;
        //database.emptyRecycleBin	10,000	10,000
        Database.emptyRecycleBin(records);
        return records;
    }
    public override void handleFinish(){

    }
}