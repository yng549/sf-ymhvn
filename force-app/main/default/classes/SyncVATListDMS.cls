/*******************************************************************************
 ** Class Name: SyncVATListDMS
 ** Description: Get all VAT 8 from YNSPIRE SP
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class SyncVATListDMS implements Queueable, Database.AllowsCallouts {
    Integer perPage = 200;
    Integer startIndex = 0;
    Date dateFrom;
    Integer countChain = 0;
    Integer currentPage = 0;
    Date dateTo;
    string DealerCode;
    public SyncVATListDMS(Date dateFrom, Date dateTo, Integer perPage , Integer startIndex, Integer currentPage, Integer countChain, string DealerCode) {
        this.dateFrom = dateFrom;
        this.dateTo = dateTo;
        this.startIndex = startIndex;
        this.dateTo = dateTo;
        this.perPage = perPage;
        this.currentPage = currentPage;
        this.countChain = countChain;
        this.DealerCode = DealerCode;
    }
    private PageSize_API__c createPageAPI(integer startIndex, integer currentPage, integer totalline, string DealerCode) {
        PageSize_API__c pageAPI = new PageSize_API__c(Name = 'vatlist ' + DealerCode,
                                                      Start_Index__c = startIndex,
                                                      Current_Page__c = currentPage,
                                                      Total_record__c = totalline);
        
        return pageAPI;
    }
    
    private static final string URLDMS = 'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/vatlist';
    
	// IV.22 vatlist Data
    public void execute(QueueableContext context){
        try {
            if (countChain == 30) return;
            countChain += 1;
            boolean isNextPage = false;
            HttpResponse response = SyncDMSHelper.requestPaginationDMS('vatlist', SyncDMSHelper.BODYEMPTY, dateFrom, dateTo, perPage, startIndex, DealerCode);
            if(response.getStatusCode() == 200) {
                Map<String, Object> dataResult = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String message = String.valueOf(dataResult.get('msg'));
                Map<String, SObjectAPIDMSRespone.VATProductData> mapProductVat = new Map<String, SObjectAPIDMSRespone.VATProductData>();
                if (dataResult.get('code') ==  200) {
                    String jsonData = JSON.serialize(dataResult.get('data')).replaceAll('Type', 'nType');
                    List<SObjectAPIDMSRespone.VATProductData> productsVAT = (List<SObjectAPIDMSRespone.VATProductData>)JSON.deserialize(jsonData, List<SObjectAPIDMSRespone.VATProductData>.class);
                    
                    if (!productsVAT.isEmpty()) {
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
                    for (SObjectAPIDMSRespone.VATProductData productVAT : productsVAT) 
                    mapProductVat.put(productVAT.ProductCode, productVAT);
                    List<Product2> productsUpdateVAT = new List<Product2>();
                    //List<PricebookEntry> lstPriceBookEntry = new List<PriceBookEntry>();
                    for (Product2 product : [SELECT Id, ExternalID_DMS__c, Retail_Price__c, RecordTypeId, (SELECT Id, UnitPrice FROM PricebookEntries WHERE Pricebook2.IsStandard != TRUE)
                                             FROM Product2 WHERE ExternalID_DMS__c IN: mapProductVat.keySet()]) {
						productsUpdateVAT.add(new Product2(Id = product.Id, Vat__c = mapProductVat.get(product.ExternalID_DMS__c).VAT));
                        if(product.RecordTypeId == RecordTypeHelper.PRODUCT_MODEL || product.Retail_Price__c == null) continue;
                        /*for(PricebookEntry pbe : product.PricebookEntries) {
                            pbe.UnitPrice = product.Retail_Price__c + ((product.Retail_Price__c * mapProductVat.get(product.ExternalID_DMS__c).VAT)/100);
                            lstPriceBookEntry.add(pbe);
                        }*/
                    }
                    update productsUpdateVAT;
                	//update lstPriceBookEntry;
                }
                SyncDMSHelper.logError('SyncVATListDMS', message, '', SyncDMSHelper.trimErrorMessage(response.getBody()), URLDMS);
                //upsert servicejobMap.values() ExternalID_DMS__c;
                //SyncDMSHelper.createPricebookEntireStandard(servicejobMap);
                if (isNextPage) system.enqueueJob(new SyncVATListDMS(dateFrom, dateTo, perPage, startIndex, currentPage, countChain, DealerCode));
            }
        }catch (Exception e) {
            system.debug(e.getMessage() + e.getLineNumber());
            SyncDMSHelper.logError('SyncVATListDMS', '', '', e.getMessage() + e.getLineNumber(), URLDMS);
        }
    }
}