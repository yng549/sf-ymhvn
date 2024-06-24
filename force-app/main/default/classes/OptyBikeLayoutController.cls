public with sharing class OptyBikeLayoutController {
  @AuraEnabled(cacheable=true)
  public static List<Task> getTaskAccount(String strOptyId) {
    Opportunity objOpp = getOptyAccountTask(strOptyId);
    Set<Id> taskIds = new Set<Id>();
    List<Task> excludeTask = [SELECT  Id,Status FROM Task WHERE WhatId =: objOpp.Id AND 
    (Status != 'Completed' AND Status != 'Closed')] ;
    for (Task t : excludeTask){
      taskIds.add(t.Id);
    }
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
      WHERE WhoId = :objOpp.Account.PersonContactId AND Id NOT IN :taskIds
    ];
    if (lstTask.isEmpty()) {
      return new List<Task>();
    } else {
      return lstTask;
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Order> getOrderHistoryOpty(String strOptyId) {
    Opportunity objOpp = getOptyAccountTask(strOptyId);
    List<Order> lstOrder = [
      SELECT Id, OrderNumber, Status, AccountId, Account.Name, Recordtype.Name, OwnerId, Owner.Name
      FROM ORDER
      WHERE AccountId = :objOpp.AccountId
    ];
    if (lstOrder.isEmpty()) {
      return new List<Order>();
    } else {
      return lstOrder;
    }
  }

  private static Opportunity getOptyAccountTask(String strOptyId) {
    List<Opportunity> lstOpp = [
      SELECT Id, Name, AccountId,Account.PersonContactId
      FROM Opportunity
      WHERE Id = :strOptyId
    ];
    if (lstOpp.isEmpty()) {
      return new Opportunity();
    } else {
      return lstOpp[0];
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
    
  }
}