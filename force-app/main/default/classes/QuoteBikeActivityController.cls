public with sharing class QuoteBikeActivityController {
  @AuraEnabled(cacheable=true)
  public static List<Task> getQuoteActivity(String quoteId) {
    Quote objQuote = getQuote(quoteId);
    List<Task> lstTask = [
      SELECT
        Id,
        OwnerId,
        WhoId,
        WhatId,
        Subject,
        Status,
        Priority,
        ActivityDate,
        Comment__c,
        Description,
        Owner.Name,
        Who.Name,
        What.Name
      FROM Task
      WHERE WhatId = :objQuote.OpportunityId OR WhatId = :quoteId
    ];
    if (lstTask.isEmpty()) {
      return new List<Task>();
    } else {
      return lstTask;
    }
  }
  private static Quote getQuote(String quoteId) {
    List<Quote> lstQuote = [
      SELECT Id, OpportunityId, Email
      FROM Quote
      WHERE Id = :quoteId
    ];
    if (lstQuote.isEmpty()) {
      return new Quote();
    } else {
      return lstQuote[0];
    }
  }
}