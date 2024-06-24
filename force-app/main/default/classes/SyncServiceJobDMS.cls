/*******************************************************************************
 ** Class Name: SyncServiceJobDMS
 ** Description: all BB dealer’s servicejobinformationget from YNSPIRE SP
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class SyncServiceJobDMS implements Queueable, Database.AllowsCallouts {
    Integer perPage = 200;
    Integer startIndex = 0;
    Date dateFrom;
    Integer countChain = 0;
    Integer currentPage = 0;
    Date dateTo;
    string DealerCode;
    public SyncServiceJobDMS(Date dateFrom, Date dateTo, Integer perPage , Integer startIndex, Integer currentPage, Integer countChain, string DealerCode) {
        this.dateFrom = dateFrom;
        this.dateTo = dateTo;
        this.startIndex = startIndex;
        this.dateTo = dateTo;
        this.perPage = perPage;
        this.currentPage = currentPage;
        this.countChain = countChain;
        this.DealerCode = DealerCode;
    }
    private static PageSize_API__c createPageAPI(integer startIndex, integer currentPage, integer totalline, string DealerCode) {
        PageSize_API__c pageAPI = new PageSize_API__c(Name = 'servicejobinformation ' + DealerCode,
                                                      Start_Index__c = startIndex,
                                                      Current_Page__c = currentPage,
                                                      Total_record__c = totalline);
        
        return pageAPI;
    }
    private static final string URLDMS = 'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/servicejobinformation';
	// IV.5	servicejobinformation Data
    public void execute(QueueableContext context){
        try {
            if (countChain == 10) return;
            countChain += 1;
            boolean isNextPage = false;
            HttpResponse response = SyncDMSHelper.requestPaginationDMS('servicejobinformation', SyncDMSHelper.BODYEMPTY, dateFrom, dateTo, perPage, startIndex, DealerCode);
        	if(response.getStatusCode() == 200) {
                Map<String, Object> dataResult = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String message = String.valueOf(dataResult.get('msg'));
                Map<String, Product2> servicejobMap = new Map<String, Product2>();
                if (dataResult.get('code') ==  200) {
                    String jsonData = JSON.serialize(dataResult.get('data'));
                    List<SObjectAPIDMSRespone.ServiceJobData> servicejobList = (List<SObjectAPIDMSRespone.ServiceJobData>)JSON.deserialize(jsonData, List<SObjectAPIDMSRespone.ServiceJobData>.class);
                    
                    if (!servicejobList.isEmpty()) {
                        PageSize_API__c pageAPI = createPageAPI(startIndex, currentPage, Integer.valueOf(dataResult.get('totalLine')), DealerCode);
                        
                        if (perPage < Integer.valueOf(dataResult.get('totalLine')) && startIndex < Integer.valueOf(dataResult.get('totalLine')) && (startIndex + perPage) < Integer.valueOf(dataResult.get('totalLine'))) {
                            pageAPI.End_Index__c = currentPage == 0 ? perPage : pageAPI.Start_Index__c + perPage;
                            startIndex += currentPage == 0 ? perPage + 1 : perPage;
                            isNextPage = true;
                            currentPage += 1;
                        } else {
                            pageAPI.Is_Empty_Return__c = true;
                            pageAPI.End_Index__c = Integer.valueOf(dataResult.get('totalLine'));
                        }
						insert pageAPI;                                                                
                    }
                    for (SObjectAPIDMSRespone.ServiceJobData serviceItem : servicejobList) {
                        if (String.isBlank(serviceItem.dJobCode) || String.isBlank(serviceItem.hProductLineCode)) continue;
                        Product2 serviceJob = new Product2();
                        serviceJob.Name = String.isBlank(serviceItem.dJobDescriptionLocal) ? 'Name undefined DMS' : serviceItem.dJobDescriptionLocal;
                        serviceJob.Job_Description_Eng__c = serviceItem.dJobDescriptionEng;
                        serviceJob.ProductCode = serviceItem.dJobCode;
                        serviceJob.RecordTypeId = RecordTypeHelper.SV_JOB;
                        serviceJob.Dealer_Code__c = serviceItem.dDealerCode;
                        serviceJob.Point_Code__c = serviceItem.dPointCode;
                        serviceJob.LastModify_DMS__c = serviceItem.UpdateDate;
                        serviceJob.Description = serviceItem.dJobDescriptionLocalForDo;
                        serviceJob.ProductLineCode__c = serviceItem.hProductLineCode;
                        serviceJob.Job_ID__c = serviceItem.dJobId;
                        serviceJob.IsActive = true;
                        // Key upsert
                        serviceJob.ExternalID_DMS__c = serviceItem.hProductLineCode + ':' + serviceItem.dJobCode;
                        servicejobMap.put(serviceJob.ExternalID_DMS__c, serviceJob);
                    }
                }
                SyncDMSHelper.logError('SyncServiceJobDMS', message, '', SyncDMSHelper.trimErrorMessage(response.getBody()), URLDMS);
                upsert servicejobMap.values() ExternalID_DMS__c;
                SyncDMSHelper.createPricebookEntireStandard(servicejobMap);
                // Start - Product New DO 26/06/2023
                List<Product_DO__c> productDO = new List<Product_DO__c>();
                for(Product2 p : servicejobMap.values()) {
                    productDO.add(new Product_DO__c(Name = p.Name + ' ' + DealerCode,
                                                    GUID_Key__c = p.Job_ID__c,
                                                    ProductParent__c = p.Id,
                                                    DO_Code__c = DealerCode));
                }
                upsert productDO GUID_Key__c;
                // End - Product New DO 26/06/2023
                if (isNextPage) system.enqueueJob(new SyncServiceJobDMS(dateFrom, dateTo, perPage, startIndex, currentPage, countChain, DealerCode));
            }
        }catch (Exception e) {
            system.debug(e.getMessage() + e.getLineNumber());
            SyncDMSHelper.logError('SyncServiceJobDMS', '', '', e.getMessage() + e.getLineNumber(), URLDMS);
        }
    }
}