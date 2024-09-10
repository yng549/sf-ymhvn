/*******************************************************************************
 ** Class Name: APIDMSPartInformation
 ** Description: all BB dealer’s partinformation get from YNSPIRE SP then send to CRM
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class APIDMSPartInformation implements Queueable, Database.AllowsCallouts {
    Integer perPage = 200;
    Integer startIndex = 0;
    Date dateFrom;
    Integer countChain = 0;
    Integer currentPage = 0;
    Date dateTo;
    string DealerCode;
    public APIDMSPartInformation(
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
            Name = 'partinformation ' + DealerCode,
            Start_Index__c = startIndex,
            Current_Page__c = currentPage,
            Total_record__c = totalline
        );
        return pageAPI;
    }
    //IV.3	 partinformation Data -	API create partinformation
    public void execute(QueueableContext context) {
        try {
            if (countChain == 10)
                return;
            countChain += 1;
            boolean isNextPage = false;
            HttpResponse response = SyncDMSHelper.requestPaginationDMS(
                'partinformation',
                SyncDMSHelper.BODYEMPTY,
                dateFrom,
                dateTo,
                perPage,
                startIndex,
                DealerCode
            );

            System.debug('res::' + response);

            if (response.getStatusCode() == 200) {
                Map<string, Object> dataResult = (Map<string, Object>) JSON.deserializeUntyped(
                    response.getBody()
                );
                String message = String.valueOf(dataResult.get('msg'));
                Map<string, Product2> partNoMap = new Map<string, Product2>();
                Map<string, List<string>> partNoSuppersending = new Map<string, List<string>>();
                Map<string, Integer> partNoRetailPriceMap = new Map<string, Integer>();
                System.debug('partsList.size()::' + dataResult);

                if (dataResult.get('code') == 200) {
                    String jsonData = JSON.serialize(dataResult.get('data'));
                    List<SObjectAPIDMSRespone.PartData> partsList = (List<SObjectAPIDMSRespone.PartData>) JSON.deserialize(
                        jsonData,
                        List<SObjectAPIDMSRespone.PartData>.class
                    );
                    System.debug('partsList.size()::' + partsList.size());
                    if (!partsList.isEmpty()) {
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
                    for (SObjectAPIDMSRespone.PartData partItem : partsList) {
                        if (
                            String.isBlank(partItem.PartNo) ||
                            String.isBlank(partItem.PartsId)
                        )
                            continue;
                        Product2 part = new Product2();
                        part.Family = 'Part';
                        part.VAT__c = 10;
                        part.Name = partItem.PartNameNative;
                        part.ProductCode = partItem.PartNo;
                        part.RecordTypeId = RecordTypeHelper.PRODUCT_PCA;
                        part.PartsNameEng__c = partItem.PartNameEng;
                        part.PartNo__c = partItem.PartNo;
                        part.SupersedingPart__c = partItem.SupersedingPart;
                        part.Product_Category__c = partItem.ProductCategory;
                        part.Brand_name__c = 'GENUINE YAMAHA';
                        part.IsActive = true;
                        part.CreateDateDMS__c = partItem.CreateDate;
                        part.LastModify_DMS__c = partItem.LastModify;
                        part.Is_Genuine__c = true;
                        if (String.isNotBlank(partItem.PartSizeHigh))
                            part.Part_Size_High__c = Decimal.valueOf(
                                partItem.PartSizeHigh
                            );
                        if (String.isNotBlank(partItem.PartSizeWidth))
                            part.Part_Size_Width__c = Decimal.valueOf(
                                partItem.PartSizeWidth
                            );
                        if (String.isNotBlank(partItem.PartSizeLong))
                            part.Part_Size_Long__c = Decimal.valueOf(
                                partItem.PartSizeLong
                            );
                        if (String.isNotBlank(partItem.PartWeight))
                            part.Part_Weight__c = Decimal.valueOf(
                                partItem.PartWeight
                            );
                        if (String.isNotBlank(partItem.PurchaseLot))
                            part.Purchase_Lot__c = Decimal.valueOf(
                                partItem.PurchaseLot
                            );
                        if (String.isNotBlank(partItem.SalesLot))
                            part.Sales_Lot__c = Decimal.valueOf(
                                partItem.SalesLot
                            );
                        part.NonSalesId__c = partItem.NonSalesId;
                        part.Retail_Price__c = Integer.valueOf(
                            partItem.RetailPrice
                        );
                        part.PartID__c = partItem.PartsId;
                        if (String.isNotBlank(partItem.RetailPriceRevisionDate))
                            part.RetailPriceRevisionDate__c = SyncDMSHelper.convertFormatDate(
                                partItem.RetailPriceRevisionDate
                            );
                        if (String.isNotBlank(partItem.RetailPriceRevisionDate))
                            part.WholesalePriceRevisionDate__c = SyncDMSHelper.convertFormatDate(
                                partItem.WholeSalesRevisionDate
                            );
                        if (String.isNotBlank(partItem.SupersedingRevisionDate))
                            part.SupersedingRevisionDate__c = SyncDMSHelper.convertFormatDate(
                                partItem.SupersedingRevisionDate
                            );
                        // Key upsert
                        part.Product_Unit__c = 'Chiếc';
                        part.ExternalID_DMS__c = partItem.PartNo;
                        partNoMap.put(partItem.PartNo, part);
                        if (string.isNotBlank(partItem.SupersedingPart)) {
                            if (
                                !partNoSuppersending.containsKey(
                                    partItem.PartNo
                                )
                            )
                                partNoSuppersending.put(
                                    partItem.PartNo,
                                    new List<string>{ partItem.SupersedingPart }
                                );
                            if (
                                !partNoSuppersending.get(partItem.PartNo)
                                    .contains(partItem.SupersedingPart)
                            )
                                partNoSuppersending.get(partItem.PartNo)
                                    .add(partItem.SupersedingPart);
                        }

                        partNoRetailPriceMap.put(
                            partItem.PartNo,
                            partItem.RetailPrice != null
                                ? Integer.valueOf(partItem.RetailPrice)
                                : 0
                        );
                    }
                }
                for (string partNo : partNoSuppersending.keySet()) {
                    string superParts = string.join(
                        partNoSuppersending.get(partNo),
                        ','
                    );
                    partNoMap.get(partNo).put('SupersedingPart__c', superParts);
                }

                SyncDMSHelper.logError(
                    'syncPartData',
                    message,
                    '',
                    SyncDMSHelper.trimErrorMessage(response.getBody()),
                    'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/partinformation'
                );
                upsert partNoMap.values() ExternalID_DMS__c;
                SyncDMSHelper.createPricebookEntireStandard(partNoMap);
                SyncDMSHelper.createPricebookEntirePart(
                    partNoMap,
                    partNoRetailPriceMap
                );
                SyncDMSHelper.createPEPartWarranty(
                    partNoMap,
                    partNoRetailPriceMap
                );

                // // YMHVN-996, New nethod to create pricebook entry for YMH's employees
                SyncDMSHelper.createPricebookEntirePartEmployee(
                    partNoMap,
                    partNoRetailPriceMap
                );
                // Start - Product New DO 26/06/2023
                List<Product_DO__c> productDO = new List<Product_DO__c>();
                for (Product2 p : partNoMap.values()) {
                    productDO.add(
                        new Product_DO__c(
                            Name = p.Name + ' ' + DealerCode,
                            GUID_Key__c = p.PartID__c,
                            ProductParent__c = p.Id,
                            DO_Code__c = DealerCode
                        )
                    );
                }
                upsert productDO GUID_Key__c;
                // End - Product New DO 26/06/2023
                if (isNextPage)
                    system.enqueueJob(
                        new APIDMSPartInformation(
                            dateFrom,
                            dateTo,
                            perPage,
                            startIndex,
                            currentPage,
                            countChain,
                            DealerCode
                        )
                    );
            }
        } catch (Exception e) {
            system.debug(e.getMessage() + e.getLineNumber());
            SyncDMSHelper.logError(
                'syncPartData',
                '',
                '',
                e.getMessage() + e.getLineNumber(),
                'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/partinformation'
            );
        }
    }
}
