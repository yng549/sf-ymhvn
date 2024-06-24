public without sharing class SyncQuoteWithOpportunity{
    @future
    public static void SyncQuote(Set<Id> quoteIds) {
       	Map<Id, Quote> mapIdOpptyQuote = new Map<Id, Quote>();
        List<Opportunity> opps = new List<Opportunity>();
        List<Opportunity> oppNews = new List<Opportunity>();
        List<Quote> quotes = [SELECT Id, OpportunityId, (SELECT Id, Product2Id 
                                                         FROM QuoteLineItems WHERE Product2.RecordTypeId =: RecordTypeHelper.PRODUCT_MODEL) 
                              FROM Quote WHERE Id IN :quoteIds];
        for(Quote item : quotes) {
        	mapIdOpptyQuote.put(item.OpportunityId, item);
        }
        for(Quote item : [SELECT Id, OpportunityId FROM Quote WHERE OpportunityId IN: mapIdOpptyQuote.keySet() AND IsSyncing =: true]) {
            opps.add(new Opportunity(Id = item.OpportunityId, SyncedQuoteId = null));
        }
        update opps;      
       
        for (Quote q : quotes) {
            Opportunity opp = new Opportunity();
            opp.Id = q.OpportunityId;
            if(!q.QuoteLineItems.isEmpty()) {
                opp.Product__c = q.QuoteLineItems[0].Product2Id;
            }
            opp.SyncedQuoteId = q.Id;
            opp.Proposal_Date__c = Date.today();
            oppNews.add(opp);
        }
        update oppNews;
    }
}