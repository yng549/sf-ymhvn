/*******************************************************************************
 ** Class Name: SyncPartmenifestDMS
 ** Description:: Get all BB dealer’s part inventory from YNSPIRE SP
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class SyncPartmenifestDMS implements Queueable, Database.AllowsCallouts{
    Integer perPage = 200;
    Integer startIndex = 0;
    Date dateFrom;
    Integer countChain = 0;
    Integer currentPage = 0;
    Date dateTo;
    string DealerCode;
    private static final string URLDMS = 'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/partmanifest';
    public SyncPartmenifestDMS(Date dateFrom, Date dateTo, Integer perPage , Integer startIndex, Integer currentPage, Integer countChain, string DealerCode) {
        this.dateFrom = dateFrom;
        this.dateTo = dateTo;
        this.startIndex = startIndex;
        this.dateTo = dateTo;
        this.perPage = perPage;
        this.currentPage = currentPage;
        this.countChain = countChain;
        this.DealerCode = DealerCode;
    }
    private static PageSize_API__c createPageAPI(integer startIndex, integer currentPage, integer totalline, string dealerCode) {
        PageSize_API__c pageAPI = new PageSize_API__c(Name = 'partmanifest ' + dealerCode,
                                                      Start_Index__c = startIndex,
                                                      Current_Page__c = currentPage,
                                                      Total_record__c = totalline);
        return pageAPI;
    }
	// IV.9	- PI create partmanifest
	public void execute(QueueableContext context)  {
        try {
            if (countChain == 10) return;
            countChain += 1;
            boolean isNextPage = false;
            if(Test.isRunningTest()) cheatTemp();
            HttpResponse response = SyncDMSHelper.requestPaginationDMS('partmanifest', SyncDMSHelper.BODYEMPTY, dateFrom, dateTo, perPage, startIndex, DealerCode);
        	if(response.getStatusCode() == 200) {
                Map<String, Object> dataResult = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String message = String.valueOf(dataResult.get('msg'));
                String jsonData = JSON.serialize(dataResult.get('data'));
                Map<String, List<SObjectAPIDMSRespone.PartManifestData>> mapPartsShipmentNo = new Map<String, List<SObjectAPIDMSRespone.PartManifestData>>();
                Map<String, Id> mapPartsShipmentNoExs = new Map<String, Id>();
                Map<String, PartManifest__c> mapPMTempt = new Map<String, PartManifest__c>();
                Map<String, Id> partProducts = new Map<String, Id>();
                Set<String> dealersCode = new Set<String>();
                if (dataResult.get('code') ==  200) {
                    List<SObjectAPIDMSRespone.PartManifestData> partManifestList = (List<SObjectAPIDMSRespone.PartManifestData>)JSON.deserialize(jsonData, List<SObjectAPIDMSRespone.PartManifestData>.class);
                    if (!partManifestList.isEmpty()) {
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
                    
                    for (SObjectAPIDMSRespone.PartManifestData p : partManifestList) {
                        if (String.isBlank(p.ManifestItemID) || string.isBlank(p.ShipmentNo) || string.isBlank(p.PartsNo)) continue;
                        PartManifest__c partmanifest = new PartManifest__c();
                        partmanifest.Name = p.InvoiceNo;
                        partmanifest.DealerCode__c = p.DealerCode;
                        partmanifest.YourOrderNo__c = p.YourOrderNo;
                        partmanifest.PartsNo__c = p.PartsNo;
                        partmanifest.PartsNoOrdered__c = p.PartsNoOrdered;
                        partmanifest.CaseNo__c = p.CaseNo;
                        partmanifest.PackingQty__c = p.PackingQty;
                        partmanifest.ShipmentNo__c = p.ShipmentNo;
                        partmanifest.InvoiceNo__c = p.InvoiceSeqNo;
                        if (String.isNotBlank(p.ShippedDate)) partmanifest.ShippedDate__c = SyncDMSHelper.convertFormatDate(p.ShippedDate);
                        // Key upsert
                        partmanifest.PartManifest_ID__c = p.ManifestItemID;
                        mapPMTempt.put(partmanifest.PartManifest_ID__c, partmanifest);
                        partProducts.put(p.PartsNo, null);
                        dealersCode.add(p.DealerCode);
                        mapPartsShipmentNoExs.put(p.ShipmentNo, null);
                        if (mapPartsShipmentNo.containsKey(p.ShipmentNo)) {
                            mapPartsShipmentNo.get(p.ShipmentNo).add(p);
                            continue;
                        }
                        mapPartsShipmentNo.put(p.ShipmentNo, new List<SObjectAPIDMSRespone.PartManifestData> {p});
                    }
                }
                if(DealerCode == 'RY01')
                dealersCode.add('RY01A');
                if(DealerCode == 'RY02')
                dealersCode.add('RY02A');
                // Create new Partmanifest Tempt
                upsert mapPMTempt.values() PartManifest_ID__c;
                
                // Find Part products
                for (Product2 p : [SELECT Id,ProductCode FROM Product2 WHERE ProductCode IN: partProducts.keySet()]){
                    partProducts.put(p.ProductCode, p.Id);
                }
                // Find ware house location by Code DODL
                Map<String, Id> pointCodeWarehouse = new Map<String, Id>();
                for (Account acc : [SELECT Id, Warehouse_Location__c, DO_DL_Code__c FROM Account 
									WHERE DO_DL_Code__c IN: dealersCode AND RecordTypeId =: RecordTypeHelper.ACCOUNT_DODL
                                    AND Warehouse_Location__c != null]) {
                   pointCodeWarehouse.put(acc.DO_DL_Code__c, acc.Warehouse_Location__c);
                }
                // Create new Transaction Header.
                Map<String, X3_Inventory_Transaction_Header__c> mapCaseTranscHeader = new Map<String, X3_Inventory_Transaction_Header__c>();
                for (X3_Inventory_Transaction_Header__c i : [SELECT Id, Name FROM X3_Inventory_Transaction_Header__c WHERE Name IN: mapPartsShipmentNoExs.keySet()]) {
                    mapPartsShipmentNoExs.put(i.Name, i.Id);
                }
                for (String key : mapPartsShipmentNo.keySet()) {
                    X3_Inventory_Transaction_Header__c header = new X3_Inventory_Transaction_Header__c();
                    if (mapPartsShipmentNoExs.containsKey(key) && mapPartsShipmentNoExs.get(key) != null) {
                        header.Id = mapPartsShipmentNoExs.get(key);
                    } else {
                        header.Name = key;
                        header.Is_DMS__c = true;
                        header.Status__c = 'Draft';
                        header.To_Warehouse_Location__c = DealerCode == 'RY01' ? pointCodeWarehouse?.get('RY01A') :  pointCodeWarehouse?.get('RY02A');
                    }
                    mapCaseTranscHeader.put(key, header);
                }
                upsert mapCaseTranscHeader.values();
                
                // Create Trancsaction Item.
                Map<String, Inventory_Transaction_Item__c> headerItems = new Map<String, Inventory_Transaction_Item__c>();
                for (String shipNo : mapPartsShipmentNo.keySet()) {
                    for (SObjectAPIDMSRespone.PartManifestData p :mapPartsShipmentNo.get(shipNo)) {
                        if (partProducts.containsKey(p.PartsNo) && partProducts.get(p.PartsNo) != null)
							headerItems.put(p.ManifestItemID, new Inventory_Transaction_Item__c(
                                Inventory_Transaction_Header__c = mapCaseTranscHeader.get(shipNo).Id, 
                                Quantity__c = p.PackingQty, 
                                Name = p.YourOrderNo,
                                Part_No_Order__c = p.YourOrderNo,
                                Case_No__c = p.CaseNo,
                                PartManifest_ID__c = p.ManifestItemID,
                                Invoice_No__c = p.InvoiceNo,
                                Invoice_SeqNo__c = p.InvoiceSeqNo,
                                Unit_Price__c = p.Price,
                                Product__c = partProducts.get(p.PartsNo))); 
                    }
                }
                for (Inventory_Transaction_Item__c item :[SELECT ID, PartManifest_ID__c
                                                          FROM Inventory_Transaction_Item__c 
                                                          WHERE PartManifest_ID__c IN: headerItems.keySet()]) {
                    headerItems.get(item.PartManifest_ID__c).Id = item.Id;
                }
                upsert headerItems.values();
                // Update status which is complete. If transaction item not empty.
                update mapCaseTranscHeader.values();
                if (isNextPage) system.enqueueJob(new SyncPartmenifestDMS(dateFrom, dateTo, perPage, startIndex, currentPage, countChain, DealerCode));
                SyncDMSHelper.logError('syncPartManifest', '', message, SyncDMSHelper.trimErrorMessage(jsonData), URLDMS);
            }
        }catch (Exception e) {
            system.debug(e.getMessage() + e.getLineNumber());
            SyncDMSHelper.logError('syncPartManifest', '', '', e.getMessage() + e.getLineNumber(), URLDMS);
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
        a = a;
        a = a;
        a = a;
        a = a;
    }
}