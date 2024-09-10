/*******************************************************************************
 ** Class Name: SyncModelPricingDMS
 ** Description: Get mc pricing info
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class SyncModelPricingDMS implements Queueable, Database.AllowsCallouts {
    Integer perPage = 200;
    Integer startIndex = 0;
    Date dateFrom;
    Integer countChain = 0;
    Integer currentPage = 0;
    Date dateTo;
    string DealerCode;
    private static List<Pricebook2> pircebookBike = [
        SELECT Id
        FROM Pricebook2
        WHERE Type__c = 'Bike' AND Isactive = TRUE
    ];
    public SyncModelPricingDMS(
        Date dateFrom,
        Date dateTo,
        Integer perPage,
        Integer startIndex,
        Integer currentPage,
        Integer countChain,
        string DealerCode
    ) {
        this.dateFrom = dateFrom;
        this.dateTo = dateTo;
        this.startIndex = startIndex;
        this.dateTo = dateTo;
        this.perPage = perPage;
        this.currentPage = currentPage;
        this.countChain = countChain;
        this.DealerCode = DealerCode;
    }
    private static PageSize_API__c createPageAPI(
        integer startIndex,
        integer currentPage,
        integer totalline,
        string DealerCode
    ) {
        PageSize_API__c pageAPI = new PageSize_API__c(
            Name = 'mcpricing ' + DealerCode,
            Start_Index__c = startIndex,
            Current_Page__c = currentPage,
            Total_record__c = totalline
        );
        return pageAPI;
    }
    private static final string URLDMS = 'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/mcpricing';
    // IV.7	mcpricing Data
    public void execute(QueueableContext context) {
        try {
            if (countChain == 10)
                return;
            countChain += 1;
            boolean isNextPage = false;

            if (pircebookBike.isEmpty())
                return;
            HttpResponse response = SyncDMSHelper.requestPaginationDMS(
                'mcpricing',
                SyncDMSHelper.BODYEMPTY,
                dateFrom,
                dateTo,
                perPage,
                startIndex,
                DealerCode
            );
            if (response.getStatusCode() == 200) {
                Map<String, Object> dataResult = (Map<String, Object>) JSON.deserializeUntyped(
                    response.getBody()
                );
                String message = String.valueOf(dataResult.get('msg'));
                if (dataResult.get('code') == 200) {
                    Map<String, SObjectAPIDMSRespone.ModelPricingData> mccodeMap = new Map<String, SObjectAPIDMSRespone.ModelPricingData>();
                    String jsonData = JSON.serialize(dataResult.get('data'));
                    List<SObjectAPIDMSRespone.ModelPricingData> mcpricingList = (List<SObjectAPIDMSRespone.ModelPricingData>) JSON.deserialize(
                        jsonData,
                        List<SObjectAPIDMSRespone.ModelPricingData>.class
                    );
                    if (!mcpricingList.isEmpty()) {
                        PageSize_API__c pageAPI = createPageAPI(
                            startIndex,
                            currentPage,
                            Integer.valueOf(dataResult.get('totalLine')),
                            DealerCode
                        );
                        if (
                            perPage <
                            Integer.valueOf(dataResult.get('totalLine')) &&
                            startIndex <
                            Integer.valueOf(dataResult.get('totalLine')) &&
                            (startIndex + perPage) <
                            Integer.valueOf(dataResult.get('totalLine'))
                        ) {
                            pageAPI.End_Index__c = currentPage == 0
                                ? perPage
                                : pageAPI.Start_Index__c + perPage;
                            startIndex += currentPage == 0
                                ? perPage + 1
                                : perPage;
                            isNextPage = true;
                            currentPage += 1;
                        } else {
                            pageAPI.Is_Empty_Return__c = true;
                            pageAPI.End_Index__c = Integer.valueOf(
                                dataResult.get('totalLine')
                            );
                        }
                        insert pageAPI;
                    }
                    Map<String, Id> mapExternalId = new Map<String, Id>();
                    List<PricebookEntry> pbeMCs = new List<PricebookEntry>();
                    Map<String, Product2> mapMcColorCode = new Map<String, Product2>();
                    for (
                        SObjectAPIDMSRespone.ModelPricingData mcPrice : mcpricingList
                    ) {
                        // Check value ModelCode, EmployeePrice, RetailPrice
                        if (String.isBlank(mcPrice.ModelCode))
                            continue;
                        mccodeMap.put(mcPrice.ModelCode, mcPrice);
                    }
                    for (Product2 mc : [
                        SELECT
                            Id,
                            ProductCode,
                            Employee_Price__c,
                            Retail_Price__c,
                            Color_Code__c,
                            ExternalID_DMS__c
                        FROM Product2
                        WHERE
                            ExternalID_DMS__c IN :mccodeMap.keySet()
                            AND RecordTypeId = :RecordTypeHelper.PRODUCT_MODEL
                    ]) {
                        mc.WholesaleStandardPrice__c = mccodeMap.get(
                                    mc.ExternalID_DMS__c
                                )
                                .EmployeePrice != null
                            ? mccodeMap.get(mc.ExternalID_DMS__c).EmployeePrice
                            : 0;
                        mc.Retail_Price__c = mccodeMap.get(mc.ExternalID_DMS__c)
                                .RetailPrice != null
                            ? mccodeMap.get(mc.ExternalID_DMS__c).RetailPrice
                            : 0;
                        mapMcColorCode.put(mc.ExternalID_DMS__c, mc);
                    }
                    update mapMcColorCode.values();
                    System.debug('To Test');

                    for (PricebookEntry entry : [
                        SELECT Id, ServiceJob_Key__c
                        FROM PricebookEntry
                        WHERE
                            ServiceJob_Key__c IN :mapMcColorCode.keySet()
                            AND Pricebook2Id = :pircebookBike[0].Id
                    ]) {
                        mapExternalId.put(entry.ServiceJob_Key__c, entry.Id);
                    }
                    for (String mcColorCode : mapMcColorCode.keySet()) {
                        Product2 model = mapMcColorCode.get(mcColorCode);
                        PricebookEntry pricingMC = SyncDMSHelper.createPriceBookEntry(
                            pircebookBike[0].Id,
                            model.Id,
                            model.Retail_Price__c
                        );
                        pricingMC.Id = mapExternalId.get(mcColorCode);
                        pbeMCs.add(pricingMC);
                    }
                    upsert pbeMCs;
                }
                SyncDMSHelper.logError(
                    'syncModelPricingData',
                    '',
                    message,
                    SyncDMSHelper.trimErrorMessage(response.getBody()),
                    URLDMS
                );
            }
        } catch (Exception e) {
            system.debug(e.getMessage() + e.getLineNumber());
            SyncDMSHelper.logError(
                'syncModelPricingData',
                '',
                '',
                e.getMessage() + e.getLineNumber(),
                URLDMS
            );
        }
    }
}
