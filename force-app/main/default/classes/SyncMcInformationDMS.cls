/*******************************************************************************
 ** Class Name: SyncMcInformationDMS
 ** Description: Get all BB dealer’s product(MC) info.
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class SyncMcInformationDMS implements Queueable, Database.AllowsCallouts{
    Integer perPage = 200;
    Integer startIndex = 0;
    Date dateFrom;
    Integer countChain = 0;
    Integer currentPage = 0;
    Date dateTo;
    string DealerCode;
    public SyncMcInformationDMS(Date dateFrom, Date dateTo, Integer perPage , Integer startIndex, Integer currentPage, Integer countChain, string DealerCode) {
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
        PageSize_API__c pageAPI = new PageSize_API__c(Name = 'mcmodelinformation ' + DealerCode,
                                                      Start_Index__c = startIndex,
                                                      Current_Page__c = currentPage,
                                                      Total_record__c = totalline);
        return pageAPI;
    }
    private static final string URLDMS = 'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/mcmodelinformation';
	// IV.4	 mcmodelinformation Data
    public void execute(QueueableContext context) {
        try {
            if (countChain == 10) return;
            countChain += 1;
            boolean isNextPage = false;   
            HttpResponse response = SyncDMSHelper.requestPaginationDMS('mcmodelinformation', SyncDMSHelper.BODYEMPTY, dateFrom, dateTo, perPage, startIndex, DealerCode);
        	if(response.getStatusCode() == 200) {
                Map<String, Object> dataResult = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String message = String.valueOf(dataResult.get('msg'));
                Map<String, Product2> modelMap = new Map<String, Product2>();
                if (dataResult.get('code') ==  200) {                    
                    String jsonData = JSON.serialize(dataResult.get('data'));
                    
                    List<SObjectAPIDMSRespone.ModelData> bikeList = (List<SObjectAPIDMSRespone.ModelData>)JSON.deserialize(jsonData, List<SObjectAPIDMSRespone.ModelData>.class);
                    if (!bikeList.isEmpty()) {
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
                    for (SObjectAPIDMSRespone.ModelData modelItem : bikeList) {
                        if (String.isBlank(modelItem.ProductCode) || String.isBlank(modelItem.ColorCode)
                            || String.isBlank(modelItem.ModelName) || (modelItem.Displacement != null && Integer.valueOf(modelItem.Displacement) <= 170)) continue;
                        Product2 model = new Product2();
                        model.Name = modelItem.ModelName;
                        model.Model_Name__c = modelItem.ModelName;
                        model.Model_Code__c = modelItem.ProductCode;
                        model.ProductCode = modelItem.ProductCode;
                        model.RecordTypeId = RecordTypeHelper.PRODUCT_MODEL;
                        model.Model_Type__c = modelItem.ModelType;
                        model.Model_Type_Name__c = modelItem.ModelTypeName;
                        model.Bike_Type__c = 'Yamaha';
                        model.Bike_Type_2__c = 'New';
                        model.Engince_cc__c =String.isNotBlank(modelItem.Displacement) ? Decimal.valueOf(modelItem.Displacement) : 0;
                        if (String.isNotBlank(modelItem.EffectiveDate)) model.Effective_Date__c = SyncDMSHelper.convertFormatDate(modelItem.EffectiveDate);
                        //if (String.isNotBlank(modelItem.OutEffectiveDate)) model.Out_Effective_Date__c = convertFormatDate(modelItem.OutEffectiveDate);
						if (String.isNotBlank(modelItem.StdRetailPrice)) model.Std_Retail_Price__c = Decimal.valueOf(modelItem.StdRetailPrice);
                        if (String.isNotBlank(modelItem.ModelYear)) model.Model_Year__c = Decimal.valueOf(modelItem.ModelYear);
                        model.Color_Code__c = modelItem.ColorCode;
                        model.Color_Name__c = modelItem.ColorName;
                        model.Model__c = 'Yamaha';
                        model.IsActive = TRUE;
                        model.Bike_cc__c = String.isNotBlank(modelItem.Displacement) && Integer.valueOf(modelItem.Displacement) > 400 ? '>400cc' : '<400cc';
                        model.RegisteredModel__c = modelItem.RegisteredModel;
                        model.Model_Id__c = modelItem.ModelId;
                        model.ExternalID_DMS__c = modelItem.ProductCode + modelItem.ColorCode;
                        model.Product_Unit__c = 'Chiếc';
                        modelMap.put(model.ExternalID_DMS__c, model);
                    }
                }
                SyncDMSHelper.logError('syncModelsData', message, '', SyncDMSHelper.trimErrorMessage(response.getBody()), URLDMS);
                upsert modelMap.values() ExternalID_DMS__c;
                SyncDMSHelper.createPricebookEntireStandard(modelMap);
                // Start - Product New DO 26/06/2023
                List<Product_DO__c> productDO = new List<Product_DO__c>();
                for(Product2 p : modelMap.values()) {
                    productDO.add(new Product_DO__c(Name = p.Model_Name__c + ' ' + DealerCode,
                                                    GUID_Key__c = p.Model_Id__c,
                                                    ProductParent__c = p.Id,
                                                    DO_Code__c = DealerCode));
                }
                upsert productDO GUID_Key__c;
                // End - Product New DO 26/06/2023
                if (isNextPage) system.enqueueJob(new SyncMcInformationDMS(dateFrom, dateTo, perPage, startIndex, currentPage, countChain, DealerCode));
            }
        }catch (Exception e) {
            system.debug(e.getMessage() + e.getLineNumber());
            SyncDMSHelper.logError('syncModelsData', '', '', e.getMessage() + e.getLineNumber(), URLDMS);
        }
    }
}