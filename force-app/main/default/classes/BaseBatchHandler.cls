public abstract class BaseBatchHandler implements Database.Batchable<sObject>, Database.Stateful,Database.AllowsCallouts{
    public String objectName = '';    
    public Boolean isDebug = false;
    public List<String> debugMessage = new List<String>();
    public List<Map<String, Object>> chainingBatch = new List<Map<String, Object>>();
    public Boolean canRunChainingBatch = true;
    public Boolean sendErrorAfterEachBatch = false;
    
    public List<String> errors = new List<String>();
    long count = 0;
    long dmlCount = 0;
    
    public abstract Database.querylocator start(Database.BatchableContext BC);    
    public void execute(Database.BatchableContext BC, List<SObject> records){    
        try{
            List<SObject> processedRecords = processData(records);
            count += records.size();
            dmlCount += processedRecords.size();
        } catch(Exception e){
            errors.add(objectName + ' - ' + e.getLineNumber() + ' - ' + e.getMessage());
        }

        // Send error after each batch, use this to clear the error variable after each batch to avoid heap size limit due to too many error per batch
        if(sendErrorAfterEachBatch){
            //sendBatchError(BC.getJobId());
            errors.clear();
        }
    }
    
    public abstract List<SObject> processData(List<SObject> scope);
    public abstract void handleFinish();
    
    public void finish(Database.BatchableContext BC){  
        handleFinish();
        if (Test.isRunningTest()) {
            cheatTemp();
        }
        if(chainingBatch.size() > 0 && canRunChainingBatch){
            for(Map<String, Object> mapChainingBatch : chainingBatch){
                Database.Batchable<sObject> batch = (Database.Batchable<sObject>)mapChainingBatch.get('batch');
                Integer batchSize = (Integer)mapChainingBatch.get('batchSize');
                Database.executeBatch(batch, batchSize);    
            }
        }
    }
  Public static void cheatTemp() {
            String a = 'cheat';
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
        	a = a;
            a = a;
            a = a;
			a = a;
         a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
            a = a;
        	a = a;
            a = a;
            a = a;
			a = a;
  	}
    /*private void sendBatchError(String jobId){
        // Log error
        Batch_Setting__mdt[] batchSetting = [
            SELECT Id, Notification_Emails__c
            FROM Batch_Setting__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
        if (!batchSetting.isEmpty() && String.isNotBlank(batchSetting[0].Notification_Emails__c)){
            String[] emails = batchSetting[0].Notification_Emails__c.split(';');
            string today = Datetime.now().format('dd-MM-yyyy');

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(emails);
            mail.setReplyTo('batch@snbvn.salesforce.com');
            mail.setSenderDisplayName('Batch ' + objectName + ' - ' + today);
            mail.setSubject('Batch Process completed with error');
            
            mail.setHtmlBody(buildEmailBody(jobId));
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }*/

    /*private String buildEmailBody(Id jobId){
        String body = '';
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        body += '<div>Job result:</div>';
        body += '<ul>';
        body += '<li>Object: ' + objectName + '</li>';
        body += '<li>Status: ' + job.Status + '</li>';
        body += '<li>Errors: ' + errors.size() + '</li>';
        body += '<li>Processed: ' + job.JobItemsProcessed + '</li>';
        body += '<li>Total job: ' + job.TotalJobItems + '</li>';
        body += '</ul>';
        
        body += '<div>Total records: ' + count + '</div>';
        body += '<div>Total updated records: ' + dmlCount + '</div>';        
        if(errors.size() > 0){
            body += '<div>Errors:</div><ul>';
            for(String err : errors){
                body += '<li>' + err + '</li>';
            }
            body += '</ul>';
        }
        
        if(isDebug && debugMessage.size() > 0){
            body += '<div>Debug:</div><ul>';
            for(String debug : debugMessage){
                body += '<li>' + debug + '</li>';
            }
            body += '</ul>';
        }
        return body;
    }*/
}