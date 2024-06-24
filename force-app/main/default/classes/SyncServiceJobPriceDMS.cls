/*******************************************************************************
 ** Class Name: SyncServiceJobPriceDMS
 ** Description: Get pricing job info
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class SyncServiceJobPriceDMS implements Queueable, Database.AllowsCallouts{
	
    Date dateFrom;
    Date dateTo;
    string DealerCode;
    private static List<Pricebook2> pircebookWarranty = [SELECT Id FROM Pricebook2 WHERE Type__c = 'Warranty' AND Isactive = True];
    public SyncServiceJobPriceDMS(Date dateFrom, Date dateTo, string DealerCode) {
        this.dateFrom = dateFrom;
        this.dateTo = dateTo;
        this.DealerCode = DealerCode;
    }
    private static final string URLDMS = 'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/jobpricing';
	// IV.8	JobMaster Data
    public void execute(QueueableContext context) {
        try {
            if (pircebookWarranty.isEmpty()) return;
            HttpResponse response = SyncDMSHelper.requestApiDMS('jobpricing', SyncDMSHelper.BODYEMPTY, dateFrom, dateTo, DealerCode);
        	if(response.getStatusCode() == 200) {
                Map<String, Object> dataResult = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String message = String.valueOf(dataResult.get('msg'));
                if (dataResult.get('code') == 200) {
                    String jsonData = JSON.serialize(dataResult.get('data'));
                    List<Object> resList = (List<Object>) JSON.deserializeUntyped(jsonData);
                    // parse product line code
                    SObjectAPIDMSRespone.Productlinedate productLine = (SObjectAPIDMSRespone.Productlinedate)JSON.deserialize(Json.serialize(resList[0]), SObjectAPIDMSRespone.Productlinedate.class);
                    
                    if (String.isBlank(productLine.ProductLineCode)) {
                        return;
                    }
                    // parse jobmaster data
                    SObjectAPIDMSRespone.JobMasterData jobMasters = (SObjectAPIDMSRespone.JobMasterData)JSON.deserialize(Json.serialize(resList[1]), SObjectAPIDMSRespone.JobMasterData.class);
					
                    Map<String, SObjectAPIDMSRespone.JobDetail> jobcodes = new Map<String, SObjectAPIDMSRespone.JobDetail>();
                    Map<String, PricebookEntry> mapProduct = new Map<String, PricebookEntry>();
                    List<Product2> jobsUpdate = new List<Product2>();
					Map<String, Id> mapServiceJobId = new Map<String, Id>();
                    
                    for (SObjectAPIDMSRespone.FlatrateDetail jobdetail : jobMasters.FlatrateGroups.detail) {
                        if (jobdetail.jobs != null && String.isnotBlank(jobdetail.jobs.JobCode)) jobcodes.put(productLine.ProductLineCode  + ':' + jobdetail.jobs.JobCode, jobdetail.jobs);
                    }
                   
                                        
                    for (Product2 job : [SELECT ID, Last_Cost__c, ExternalID_DMS__c, Labor_HOUR__c
                                         FROM Product2
                                         WHERE ExternalID_DMS__c IN: jobcodes.keySet() AND RecordTypeId =: RecordTypeHelper.SV_JOB]) {
                        job.Last_Cost__c = jobcodes.get(job.ExternalID_DMS__c).LabourCost != null ? Decimal.valueOf(jobcodes.get(job.ExternalID_DMS__c).LabourCost) : 0;
                        job.Labor_HOUR__c = jobcodes.get(job.ExternalID_DMS__c).FlatRate != null  ? Decimal.valueOf(jobcodes.get(job.ExternalID_DMS__c).FlatRate) : 0;
                        jobsUpdate.add(job);
                        mapProduct.put(job.ExternalID_DMS__c, SyncDMSHelper.createPriceBookEntry(pircebookWarranty[0].Id, job.Id, job.Last_Cost__c * job.Labor_HOUR__c));
                    }
                    update jobsUpdate;
                    
                    for (PricebookEntry entry : [SELECT Id, ServiceJob_Key__c
                                                 FROM PricebookEntry
                                                 WHERE ServiceJob_Key__c IN: mapProduct.keySet() AND Pricebook2Id =: pircebookWarranty[0].Id]) {
                        mapServiceJobId.put(entry.ServiceJob_Key__c, entry.Id);
                    }
                    for (String serviceJob : mapProduct.keySet()) {
                        if(mapServiceJobId.containsKey(serviceJob)) mapProduct.get(serviceJob).put('Id', mapServiceJobId.get(serviceJob));
                    }
                    upsert mapProduct.values();
                    SyncDMSHelper.logError('syncJobMasterData', '', message, SyncDMSHelper.trimErrorMessage(jsonData), URLDMS);
                }else {
                    system.debug('test');
                    SyncDMSHelper.logError('syncJobMasterData', '', message, SyncDMSHelper.trimErrorMessage(response.getBody()), URLDMS);
                }
            }
        }catch (Exception e) {
            system.debug(e.getMessage() + e.getLineNumber());
            SyncDMSHelper.logError('syncJobMasterData', '', '', e.getMessage() + e.getLineNumber(), URLDMS);
        }       
    }
}