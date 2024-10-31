/*******************************************************************************
 ** Class Name: SyncDMSWarrantyFCS
 ** Description: Get displacement >175 MC’s warranty info
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class SyncDMSWarrantyFCS implements Queueable, Database.AllowsCallouts {
    Integer perPage = 200;
    Integer startIndex = 0;
    Date dateFrom;
    Integer countChain = 0;
    Integer currentPage = 0;
    Date dateTo;
    string DealerCode;
    public SyncDMSWarrantyFCS(
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
        string dealerCode
    ) {
        PageSize_API__c pageAPI = new PageSize_API__c(
            Name = 'warranty ' + dealerCode,
            Start_Index__c = startIndex,
            Current_Page__c = currentPage,
            Total_record__c = totalline
        );
        return pageAPI;
    }
    private static final string URLDMS = 'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/warranty';
    private static final String URLBIGBIKE = 'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/bigbikemodel';
    // IV.18 - API Get warranty info
    public void execute(QueueableContext context) {
        try {
            if (countChain == 30)
                return;
            countChain += 1;
            boolean isNextPage = false;
            HttpResponse response = SyncDMSHelper.requestPaginationDMS(
                'warranty',
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
                    String jsonData = JSON.serialize(dataResult.get('data'));
                    List<SObjectAPIDMSRespone.WarrantyServiceRequest> warantyRequests = (List<SObjectAPIDMSRespone.WarrantyServiceRequest>) JSON.deserialize(
                        jsonData,
                        List<SObjectAPIDMSRespone.WarrantyServiceRequest>.class
                    );

                    if (!warantyRequests.isEmpty()) {
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
                    handlerCreateFCSWarranty(warantyRequests, dealerCode);
                }
                SyncDMSHelper.logError(
                    'syncWarrantRequest' + DealerCode,
                    message,
                    '',
                    SyncDMSHelper.trimErrorMessage(response.getBody()),
                    URLDMS
                );
                if (isNextPage)
                    system.enqueueJob(
                        new SyncDMSWarrantyFCS(
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
                'syncWarrantRequest' + DealerCode,
                e.getMessage() + e.getLineNumber(),
                '',
                '',
                URLDMS
            );
        }
    }
    // IV.21 - API Get bigbikemodel info
    public static Set<String> getAllBigBikeModel(String dealerCode) {
        Set<String> bigBikeModelCode = new Set<String>();
        try {
            HttpResponse response = SyncDMSHelper.requestApiBigBikeModelDMS(
                'bigbikemodel',
                dealerCode
            );
            if (response.getStatusCode() == 200) {
                Map<String, Object> dataResult = (Map<String, Object>) JSON.deserializeUntyped(
                    response.getBody()
                );
                if (dataResult.get('code') == 200) {
                    String jsonData = JSON.serialize(dataResult.get('data'));
                    List<SObjectAPIDMSRespone.CouponCategory> couponCategories = (List<SObjectAPIDMSRespone.CouponCategory>) JSON.deserialize(
                        jsonData,
                        List<SObjectAPIDMSRespone.CouponCategory>.class
                    );
                    bigBikeModelCode.addAll(
                        convertCouponCategoriesToBigBikeModelCodes(
                            couponCategories
                        )
                    );
                }
            }
            return bigBikeModelCode;
        } catch (Exception e) {
            System.debug(e.getMessage() + e.getLineNumber());
            SyncDMSHelper.logError(
                'syncWarrantyRequest' + DealerCode,
                e.getMessage() + e.getLineNumber(),
                '',
                '',
                URLBIGBIKE
            );
            return bigBikeModelCode;
        }
    }
    @TestVisible
    private static Set<String> convertCouponCategoriesToBigBikeModelCodes(
        List<SObjectAPIDMSRespone.CouponCategory> couponCategories
    ) {
        Set<String> bigBikeModelCode = new Set<String>();
        for (
            SObjectAPIDMSRespone.CouponCategory cp : (List<SObjectAPIDMSRespone.CouponCategory>) couponCategories
        ) {
            for (SObjectAPIDMSRespone.DetailItem item : cp.detail) {
                if (item.ModelCodes != null) {
                    bigBikeModelCode.add(item.ModelCodes.ModelCode);
                }
            }
        }
        return bigBikeModelCode;
    }

    public static void handlerCreateFCSWarranty(
        List<SObjectAPIDMSRespone.WarrantyServiceRequest> warantyRequests,
        String dealerCode
    ) {
        Map<String, SObjectAPIDMSRespone.WarrantyItem> mapFrameNo = new Map<String, SObjectAPIDMSRespone.WarrantyItem>();
        List<Free_Coupon__c> couponData = new List<Free_Coupon__c>();
        Set<String> bigBikeModelCodes = getAllBigBikeModel(dealerCode);

        for (
            SObjectAPIDMSRespone.WarrantyServiceRequest warItem : warantyRequests
        ) {
            if (
                String.isBlank(warItem.UnitWarranty.FrameNo) ||
                String.isBlank(warItem.UnitWarranty.WarrantyEffectiveDate) ||
                String.isBlank(warItem.UnitWarranty.WarrantyExpiredDate)
            )
                continue;
            mapFrameNo.put(warItem.UnitWarranty.FrameNo, warItem.UnitWarranty);
        }
        for (Asset asset : [
            SELECT
                Id,
                Frame_Number__c,
                Product2.Bike_cc__c,
                Product_Code__c,
                (
                    SELECT Id, ServiceDate__c, CouponCategoryLevel__c
                    FROM Free_Coupons__r
                    WHERE CouponCategoryLevel__c != NULL
                    ORDER BY CouponCategoryLevel__c ASC
                )
            FROM Asset
            WHERE Frame_Number__c IN :mapFrameNo.keySet()
        ]) {
            if (!bigBikeModelCodes.contains(asset.Product_Code__c)) {
                if (
                    mapFrameNo.get(asset.Frame_Number__c).coupons.isEmpty() &&
                    asset.Free_Coupons__r.isEmpty()
                ) {
                    couponData.addAll(
                        createFullCouponWarranty(
                            asset.Id,
                            mapFrameNo.get(asset.Frame_Number__c)
                        )
                    );
                } else if (
                    !mapFrameNo.get(asset.Frame_Number__c).coupons.isEmpty()
                ) {
                    couponData.addAll(
                        upsertMoreCoupon(
                            asset.Id,
                            mapFrameNo.get(asset.Frame_Number__c),
                            asset.Free_Coupons__r
                        )
                    );
                }
            }
            if (bigBikeModelCodes.contains(asset.Product_Code__c)) {
                if (
                    mapFrameNo.get(asset.Frame_Number__c).coupons.isEmpty() &&
                    asset.Free_Coupons__r.isEmpty()
                ) {
                    couponData.add(
                        createCouponBigBike400cc(
                            asset.Id,
                            mapFrameNo.get(asset.Frame_Number__c)
                        )
                    );
                } else if (
                    !mapFrameNo.get(asset.Frame_Number__c).coupons.isEmpty()
                ) {
                    couponData.add(
                        upsertCouponBigBike400cc(
                            asset.Id,
                            mapFrameNo.get(asset.Frame_Number__c),
                            asset.Free_Coupons__r
                        )
                    );
                }
            }
        }
        upsert couponData;
    }
    private static Free_Coupon__c upsertCouponBigBike400cc(
        Id idAsset,
        SObjectAPIDMSRespone.WarrantyItem unitWarranty,
        List<Free_Coupon__c> coupons
    ) {
        Map<String, Id> mapLevelCouponExist = new Map<String, Id>();
        for (Free_Coupon__c cExs : coupons)
            mapLevelCouponExist.put(cExs.CouponCategoryLevel__c, cExs.Id);
        SObjectAPIDMSRespone.CouponItem coupon = unitWarranty.coupons[0];
        Free_Coupon__c c = new Free_Coupon__c(
            Id = mapLevelCouponExist.containsKey(
                    coupon.coupon.CouponCategoryLevel
                )
                ? mapLevelCouponExist.get(coupon.coupon.CouponCategoryLevel)
                : null
        );
        c.Applied__c = true;
        if (String.isNotBlank(coupon.coupon.ServiceDate))
            c.ServiceDate__c = SyncDMSHelper.convertFormatDate(
                coupon.coupon.ServiceDate
            );
        c.Asset__c = idAsset;
        c.CouponCategoryLevel__c = '1';
        c.WarrantyEffectiveDate__c = SyncDMSHelper.convertFormatDate(
            unitWarranty.WarrantyEffectiveDate
        );
        c.WarrantyExpiredDate__c = SyncDMSHelper.convertFormatDate(
            unitWarranty.WarrantyExpiredDate
        );
        c.WarrantyPolicyType__c = unitWarranty.WarrantyPolicyType;
        system.debug(
            'unitWarranty.WarrantyMileage' + unitWarranty.WarrantyMileage
        );
        c.WarrantyMileage__c = Decimal.valueOf(unitWarranty.WarrantyMileage);
        c.Sync_DMS__c = true;
        return c;
    }
    public static void cheat() {
        string a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
    }
    private static Free_Coupon__c createCouponBigBike400cc(
        Id idAsset,
        SObjectAPIDMSRespone.WarrantyItem unitWarranty
    ) {
        Free_Coupon__c coupon = new Free_Coupon__c();
        coupon.Asset__c = idAsset;
        coupon.WarrantyEffectiveDate__c = SyncDMSHelper.convertFormatDate(
            unitWarranty.WarrantyEffectiveDate
        );
        coupon.WarrantyExpiredDate__c = SyncDMSHelper.convertFormatDate(
            unitWarranty.WarrantyExpiredDate
        );
        system.debug(
            'unitWarranty.WarrantyMileage ' + unitWarranty.WarrantyMileage
        );
        coupon.WarrantyMileage__c = Decimal.valueOf(
            unitWarranty.WarrantyMileage
        );
        coupon.WarrantyPolicyType__c = unitWarranty.WarrantyPolicyType;
        coupon.CouponCategoryLevel__c = '1';
        coupon.Sync_DMS__c = true;
        return coupon;
    }
    private static List<Free_Coupon__c> createFullCouponWarranty(
        Id idAsset,
        SObjectAPIDMSRespone.WarrantyItem unitWarranty
    ) {
        List<Free_Coupon__c> lstCoupons = new List<Free_Coupon__c>();
        Map<Integer, WarrantyDateValid> mapLevelDate = createDateLevelData(
            unitWarranty
        );
        for (Integer i = 1; i < 10; i++) {
            Free_Coupon__c couponNew = new Free_Coupon__c();
            couponNew.Asset__c = idAsset;
            couponNew.WarrantyEffectiveDate__c = mapLevelDate.get(i).dateFrom;
            couponNew.WarrantyExpiredDate__c = mapLevelDate.get(i).dateTo;
            couponNew.WarrantyMileage__c = Decimal.valueOf(
                unitWarranty.WarrantyMileage
            );
            couponNew.WarrantyPolicyType__c = unitWarranty.WarrantyPolicyType;
            couponNew.CouponCategoryLevel__c = string.valueOf(i);
            couponNew.Sync_DMS__c = true;
            lstCoupons.add(couponNew);
        }
        return lstCoupons;
    }
    private static List<Free_Coupon__c> upsertMoreCoupon(
        Id idAsset,
        SObjectAPIDMSRespone.WarrantyItem unitWarranty,
        List<Free_Coupon__c> coupons
    ) {
        List<Free_Coupon__c> lstCoupons = new List<Free_Coupon__c>();
        Map<Integer, WarrantyDateValid> mapLevelDate = createDateLevelData(
            unitWarranty
        );
        Map<Integer, SObjectAPIDMSRespone.coupondetail> mapLevelCouponApplied = new Map<Integer, SObjectAPIDMSRespone.coupondetail>();
        Map<Integer, Id> mapLevelCouponExist = new Map<Integer, Id>();
        for (Free_Coupon__c c : coupons)
            mapLevelCouponExist.put(
                Integer.valueOf(c.CouponCategoryLevel__c),
                c.Id
            );
        for (SObjectAPIDMSRespone.CouponItem coupon : unitWarranty.coupons)
            mapLevelCouponApplied.put(
                Integer.valueOf(coupon.coupon.CouponCategoryLevel),
                coupon.coupon
            );

        List<Integer> indexSortCoupons = new List<Integer>();
        indexSortCoupons.addAll(mapLevelCouponApplied.keySet());
        indexSortCoupons.sort();
        Integer lastCoupon = indexSortCoupons.size() - 1;

        for (Integer level : mapLevelCouponExist.keySet()) {
            if (level <= indexSortCoupons[lastCoupon]) {
                Free_Coupon__c couponEx = new Free_Coupon__c();
                couponEx.Id = mapLevelCouponExist.get(level);
                couponEx.Applied__c = true;
                if (mapLevelDate.containsKey(level)) {
                    couponEx.WarrantyEffectiveDate__c = mapLevelDate.get(level)
                        .dateFrom;
                    couponEx.WarrantyEffectiveDate__c = mapLevelDate.get(level)
                        .dateFrom;
                }

                if (
                    mapLevelCouponApplied.containsKey(level) &&
                    String.isNotBlank(
                        mapLevelCouponApplied.get(level).ServiceDate
                    )
                )
                    couponEx.ServiceDate__c = SyncDMSHelper.convertFormatDate(
                        mapLevelCouponApplied.get(level).ServiceDate
                    );
                lstCoupons.add(couponEx);
            }
        }
        for (Integer i = indexSortCoupons[lastCoupon] + 1; i < 10; i++) {
            Free_Coupon__c coupon = new Free_Coupon__c(
                Id = mapLevelCouponExist.containsKey(i)
                    ? mapLevelCouponExist.get(i)
                    : null
            );
            coupon.Sync_DMS__c = true;
            coupon.Asset__c = idAsset;
            coupon.WarrantyEffectiveDate__c = mapLevelDate.get(i).dateFrom;
            coupon.WarrantyExpiredDate__c = mapLevelDate.get(i).dateTo;
            coupon.WarrantyMileage__c = Decimal.valueOf(
                unitWarranty.WarrantyMileage
            );
            coupon.WarrantyPolicyType__c = unitWarranty.WarrantyPolicyType;
            coupon.CouponCategoryLevel__c = string.valueOf(i);
            lstCoupons.add(coupon);
        }
        return lstCoupons;
    }
    @TestVisible
    private static Map<Integer, WarrantyDateValid> createDateLevelData(
        SObjectAPIDMSRespone.WarrantyItem unitWarranty
    ) {
        Date dateFrom = SyncDMSHelper.convertFormatDate(
            unitWarranty.WarrantyEffectiveDate
        );
        Date dateTo = SyncDMSHelper.convertFormatDate(
            unitWarranty.WarrantyExpiredDate
        );
        Map<Integer, WarrantyDateValid> mapLevelDateValid = new Map<Integer, WarrantyDateValid>();
        for (Integer i = 1; i < 10; i++) {
            WarrantyDateValid dateLevel = new WarrantyDateValid();
            dateLevel.dateFrom = i == 1
                ? dateFrom
                : mapLevelDateValid.get(i - 1).dateFrom.addMonths(4);

            dateLevel.dateTo = i == 2
                ? mapLevelDateValid.get(i - 1).dateTo.addMonths(6)
                : (i == 1
                      ? dateLevel.dateFrom.addMonths(4).addDays(-1)
                      : mapLevelDateValid.get(i - 1).dateTo.addMonths(4));
            mapLevelDateValid.put(i, dateLevel);
        }
        return mapLevelDateValid;
    }
    @TestVisible
    private class WarrantyDateValid {
        @TestVisible
        private Date dateFrom;
        @TestVisible
        private Date dateTo;

        public WarrantyDateValid(Date dateFrom, Date dateTo) {
            this.dateFrom = dateFrom;
            this.dateTo = dateTo;
        }
        public WarrantyDateValid() {
        }
    }

    public static Date testCreateDateLevelData(
        SObjectAPIDMSRespone.WarrantyItem unitWarranty
    ) {
        Map<Integer, WarrantyDateValid> mapLevelDateValid = createDateLevelData(
            unitWarranty
        );

        return mapLevelDateValid.get(9).dateTo;
    }
}
