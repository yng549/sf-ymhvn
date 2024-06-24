/*******************************************************************************
 ** Class Name: APIDMSPartmanifest
 ** Description: Get all BB dealer’s part inventory from YNSPIRE SP
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class APIDMSPartmanifest {
	// IV.9	- API create partmanifest partmanifest Data
	@future(callout=true)
    public static void syncPartManifest(Date dateFrom, Date dateTo) {
        try {
            HttpResponse response = SyncDMSHelper.requestApiDMS('partmanifest', SyncDMSHelper.BODYEMPTY, dateFrom, dateTo);
        	if(response.getStatusCode() == 200) {
                Map<String, Object> dataResult = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String message = String.valueOf(dataResult.get('msg'));
                String jsonData = JSON.serialize(dataResult.get('data'));
                Map<String, PartManifest__c> pManifestMap = new Map<String, PartManifest__c>();
                if (dataResult.get('code') ==  200) {
                    List<SObjectAPIDMSRespone.PartManifestData> partManifestList = (List<SObjectAPIDMSRespone.PartManifestData>)JSON.deserialize(jsonData, List<SObjectAPIDMSRespone.PartManifestData>.class);
                    for (SObjectAPIDMSRespone.PartManifestData pManifestItem : partManifestList) {
                        if (String.isBlank(pManifestItem.ManifestItemID)) continue;
                        PartManifest__c partmanifest = new PartManifest__c();
                        partmanifest.Name = pManifestItem.InvoiceNo;
                        partmanifest.DealerCode__c = pManifestItem.DealerCode;
                        partmanifest.YourOrderNo__c = pManifestItem.YourOrderNo;
                        partmanifest.PartsNo__c = pManifestItem.PartsNo;
                        partmanifest.PartsNoOrdered__c = pManifestItem.PartsNoOrdered;
                        partmanifest.CaseNo__c = pManifestItem.CaseNo;
                        partmanifest.PackingQty__c = pManifestItem.PackingQty;
                        partmanifest.ShipmentNo__c = pManifestItem.ShipmentNo;
                        partmanifest.InvoiceNo__c = pManifestItem.InvoiceSeqNo;
                        if (String.isNotBlank(pManifestItem.ShippedDate)) partmanifest.ShippedDate__c = SyncDMSHelper.convertFormatDate(pManifestItem.ShippedDate);
                        // Key upsert
                        partmanifest.PartManifest_ID__c = pManifestItem.ManifestItemID;
                        pManifestMap.put(partmanifest.PartManifest_ID__c, partmanifest);
                    }
                }
                system.debug('pManifestMap ' + pManifestMap);
                SyncDMSHelper.logError('syncPartManifest', '', message, SyncDMSHelper.trimErrorMessage(jsonData), 'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/partmanifest');
                upsert pManifestMap.values() PartManifest_ID__c;
            }
        }catch (Exception e) {
            system.debug(e.getMessage() + e.getLineNumber());
            SyncDMSHelper.logError('syncPartManifest', '', '', e.getMessage() + e.getLineNumber(), 'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/partmanifest');
        }
    }
}