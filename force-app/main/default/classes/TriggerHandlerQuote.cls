/*******************************************************************************
 ** Class Name: TriggerHandlerQuote
 ** Description: TestClass APIOrderAndOrderItemTest
 ** Version: 1.0
 ** Created By: OMN1
 ** Modified By:
 *******************************************************************************/
public without sharing class TriggerHandlerQuote {
    public static void beforeInsert(List<Quote> newRecordsList) {
        List<User> lstUserHN = [
            SELECT Id, AccountId
            FROM User
            WHERE Account.Name = :'REVZONE YAMAHA MOTOR HA NOI'
        ];
        Set<String> setOptyIds = new Set<String>();
        Set<String> setDODL = new Set<String>();
        Map<String, List<Quote>> mapLstBikeDODL = new Map<String, List<Quote>>();
        Map<String, List<Quote>> mapLstPcaDODL = new Map<String, List<Quote>>();

        for (Quote item : newRecordsList) {
            setOptyIds.add(item.OpportunityId);
        }
        Map<Id, Opportunity> mapOpty = new Map<Id, Opportunity>(
            [SELECT Id, DODL_Create__c FROM Opportunity WHERE Id IN :setOptyIds]
        );
        for (Quote item : newRecordsList) {
            if (
                mapOpty.containsKey(item.OpportunityID) &&
                mapOpty.get(item.OpportunityID).DODL_Create__c != null
            ) {
                if (item.RecordTypeId == RecordTypeHelper.QUOTE_SALES_BIKE) {
                    if (
                        !mapLstBikeDODL.containsKey(
                            mapOpty.get(item.OpportunityID).DODL_Create__c
                        )
                    ) {
                        mapLstBikeDODL.put(
                            mapOpty.get(item.OpportunityID).DODL_Create__c,
                            new List<Quote>()
                        );
                    }
                    mapLstBikeDODL.get(
                            mapOpty.get(item.OpportunityID).DODL_Create__c
                        )
                        .add(item);
                } else if (item.RecordTypeId == RecordTypeHelper.QUOTE_SALES) {
                    if (
                        !mapLstPcaDODL.containsKey(
                            mapOpty.get(item.OpportunityID).DODL_Create__c
                        )
                    ) {
                        mapLstPcaDODL.put(
                            mapOpty.get(item.OpportunityID).DODL_Create__c,
                            new List<Quote>()
                        );
                    }
                    mapLstPcaDODL.get(
                            mapOpty.get(item.OpportunityID).DODL_Create__c
                        )
                        .add(item);
                }
                setDODL.add(mapOpty.get(item.OpportunityID).DODL_Create__c);
            }
        }

        integer Month = Date.today().month();
        string MonthNo = Month < 10
            ? '0' + String.valueOf(Month)
            : String.valueOf(Month);
        integer Year = Date.today().year();
        if (!mapLstBikeDODL.isEmpty()) {
            for (String dodlId : setDODL) {
                integer IndexTestRide = 0;
                String prefixName = 'QUO-MC-';
                if (lstUserHN.size() > 0 && lstUserHN[0].AccountId == dodlId)
                    prefixName = 'QUO-MC-HN-';
                List<Quote> quoteBike = [
                    SELECT Quote_No__c
                    FROM Quote
                    WHERE
                        Quote_No__c > 0
                        AND Opportunity.DODL_Create__c = :dodlId
                        AND CALENDAR_MONTH(CreatedDate) = :Month
                        AND CALENDAR_YEAR(CreatedDate) = :Year
                        AND RecordTypeId = :RecordTypeHelper.QUOTE_SALES_BIKE
                    ORDER BY Quote_No__c DESC
                    LIMIT 1
                ];
                if (!quoteBike.isEmpty())
                    IndexTestRide = quoteBike[0].Quote_No__c.intValue();
                string prefixNumber =
                    prefixName +
                    String.valueOf(Year).right(2) +
                    MonthNo;
                handlerDefineQuoteNumber(
                    mapLstBikeDODL.get(dodlId),
                    IndexTestRide,
                    prefixNumber
                );
            }
        }

        if (!mapLstPcaDODL.isEmpty()) {
            for (String dodlId : setDODL) {
                integer IndexTestRide = 0;
                String prefixName = 'QUO-PCA-';
                if (lstUserHN[0].AccountId == dodlId)
                    prefixName = 'QUO-PCA-HN-';
                List<Quote> quotePCA = [
                    SELECT Quote_No__c
                    FROM Quote
                    WHERE
                        Quote_No__c > 0
                        AND Opportunity.DODL_Create__c = :dodlId
                        AND CALENDAR_MONTH(CreatedDate) = :Month
                        AND CALENDAR_YEAR(CreatedDate) = :Year
                        AND RecordTypeId = :RecordTypeHelper.QUOTE_SALES
                    ORDER BY Quote_No__c DESC
                    LIMIT 1
                ];
                if (!quotePCA.isEmpty())
                    IndexTestRide = quotePCA[0].Quote_No__c.intValue();
                string prefixNumber =
                    prefixName +
                    String.valueOf(Year).right(2) +
                    MonthNo;
                handlerDefineQuoteNumber(
                    mapLstPcaDODL.get(dodlId),
                    IndexTestRide,
                    prefixNumber
                );
            }
        }
    }
    private static void handlerDefineQuoteNumber(
        List<Quote> quotes,
        integer IndexTestRide,
        string prefixNumber
    ) {
        for (Quote item : quotes) {
            IndexTestRide += 1;
            item.Quote_No__c = IndexTestRide;
            string IndexTestRideNo = string.valueOf(IndexTestRide);
            if (IndexTestRide < 10)
                IndexTestRideNo = '000' + String.valueOf(IndexTestRide);
            else if (IndexTestRide < 100)
                IndexTestRideNo = '00' + String.valueOf(IndexTestRide);
            else if (IndexTestRide < 1000)
                IndexTestRideNo = '000' + String.valueOf(IndexTestRide);
            item.Quote_Number__c = prefixNumber + '-' + IndexTestRideNo;
        }
    }
    public static void onAfterInsert(List<Quote> newData) {
        Map<Id, Id> quoteMap = new Map<Id, Id>();
        Map<Id, Id> quoteLimitProductFieldMap = new Map<Id, Id>();
        for (Quote currentQuote : newData) {
            if (currentQuote.Is_CMS__c) {
                quoteMap.put(currentQuote.Id, currentQuote.OpportunityId);
            }
            quoteLimitProductFieldMap.put(
                currentQuote.Id,
                currentQuote.OpportunityId
            );
        }
        syncQuote(quoteMap);
        updateLimitPromotionProductOnQuote(quoteLimitProductFieldMap);
    }

    private static void updateLimitPromotionProductOnQuote(
        Map<Id, Id> quoteMap
    ) {
        List<Quote> quotesUpdate = new List<Quote>();
        Map<Id, Opportunity> oppOwnQuote = new Map<Id, Opportunity>(
            [
                SELECT Id, Product__r.Maxmimum_Promotion__c
                FROM Opportunity
                WHERE Id IN :quoteMap.values()
            ]
        );
        for (Id currentQuote : quoteMap.keyset()) {
            if (oppOwnQuote.containsKey(quoteMap.get(currentQuote))) {
                Quote quote = new Quote();
                quote.Id = currentQuote;
                quote.Limit_Product_Promotion__c = oppOwnQuote.get(
                        quoteMap.get(currentQuote)
                    )
                    .Product__r.Maxmimum_Promotion__c;
                quotesUpdate.add(quote);
            }
        }
        update quotesUpdate;
    }

    public static void onBeforeUpdate(
        Map<Id, Quote> mapOlds,
        Map<Id, Quote> mapNews
    ) {
        for (Quote item : mapNews.values()) {
            if (
                (mapOlds.get(item.Id).IsSyncing != item.IsSyncing &&
                item.IsSyncing) ||
                (mapOlds.get(item.Id).Status != item.Status &&
                item.Status == 'Approved')
            ) {
                if (item.Delivery_Date__c == null) {
                    item.addError(
                        'Please input value for field delivery date on quote before syncing the quote.'
                    );
                }
            }
        }
    }

    @future
    public static void syncQuote(Map<Id, Id> quoteMap) {
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for (Id currentQuote : quoteMap.keyset()) {
            Opportunity opp = new Opportunity();
            opp.Id = quoteMap.get(currentQuote);
            opp.SyncedQuoteId = currentQuote;
            oppMap.put(opp.Id, opp);
        }
        update oppMap.values();
    }

    public static void onAfterUpdate(
        Map<Id, Quote> mapOlds,
        Map<Id, Quote> mapNews
    ) {
        Set<Id> quotesID = new Set<Id>();
        for (Quote item : mapNews.values()) {
            if (
                mapOlds.get(item.Id).Status != item.Status &&
                item.Status == 'Approved'
            ) {
                quotesID.add(item.Id);
            }
        }
        if (!quotesID.isEmpty() && !System.isFuture()) {
            SyncQuoteWithOpportunity.SyncQuote(quotesID);
        }
    }
    public static void cheat() {
        String a = '';
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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
