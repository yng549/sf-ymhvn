public without sharing class BatchFollowFailOrderService extends BaseBatchHandler{
    private static FINAL String ORDER_PCA = RecordTypeHelper.ORDER_PCA;
    private static FINAL String ORDER_BIKE = RecordTypeHelper.ORDER_BIKE;
    private static FINAL String ORDER_PROFOMAR = RecordTypeHelper.ORDER_PROFOMAR_ORDER;

    private static FINAL Map<Id,User> mapAllUser = mapGetAllUser();
   
    public BatchFollowFailOrderService() {
        this.objectName = 'Order';
  
    }
    public override Database.querylocator start(Database.BatchableContext BC){
        List<String> query = new List<String>();
        query.add('SELECT Id');
        query.add('FROM ' + objectName);
        query.add('WHERE RecordTypeId != :ORDER_PCA AND RecordTypeId != :ORDER_BIKE AND RecordTypeId != :ORDER_PROFOMAR');
        
        if (Test.isRunningTest()){
            query.add('LIMIT 200');
        }
        return Database.getQueryLocator(String.join(query, ' '));
    }
    
    public override List<SObject> processData(List<SObject> records){
        List<Order> lstOA = (List<Order>) records;
        List<Order> lstProcess = [SELECT Id
                                		, Is_Payment__c
                                		, OwnerId
										, Product__c
                                		, Product__r.Bike_cc__c
                                		, RecordTypeId
                                		, Status
                                		, Flow_Fouls__c
                                		, Order_Number__c
                                		, AccountId
                                		, Cashier__c
                                		, (SELECT Id
                                           		, Task_Name__c
                                           		, ActivityDate
                                           		, Status
                                           		, Is_Close__c
                                           		, WhatId
                                           		, WhoId
                                           		, OwnerId
                                          FROM Tasks
                                          WHERE Is_Close__c =: false
											AND Status !=: 'Closed'
                                          	AND Status !=: 'Not Completed'
                                          	AND Status !=: 'Completed'
                                          )
                                FROM Order 
                                WHERE ID IN: lstOA];
        getTask(lstProcess);
        return records;
    }

    private static void getTask(List<Order> lstOA){
        List<Follow_Fail__c> lstFollowFailInsert = new List<Follow_Fail__c>();
        List<Task> lstTaskUpdate = new List<Task>();
        try{
            for (Order item : lstOA){
                if (!item.Tasks.isEmpty()) {
                    for (Task obj : item.Tasks){
                        if (!obj.Is_Close__c 
                        && (obj.Status == 'In Processing' || obj.Status == 'Open')
                        && obj.ActivityDate < System.today()){
                            obj.Status = 'Not Completed';
                            obj.Is_Close__c = true;
                            
                            Follow_Fail__c objFollowFail = new Follow_Fail__c();
                            objFollowFail.RecordTypeId = RecordTypeHelper.FOLLOWFAIL_ORDER;
                            if(String.isNotBlank(item.AccountId)) {
                                objFollowFail.Account__c = item.AccountId;
                            }
                            objFollowFail.Order__c = item.Id;
             
                            objFollowFail.Status__c = 'New';
                            if(mapAllUser.containsKey(item.OwnerId)) {
                                objFollowFail.OwnerId = item.OwnerId;
                                if(mapAllUser.get(item.OwnerID).Service_Manager__c != null)
                                    objFollowFail.OwnerId = mapAllUser.get(item.OwnerID).Service_Manager__c;
                            }
                            objFollowFail.Consultant__c = item.OwnerId;
                            lstFollowFailInsert.add(objFollowFail);  
                            lstTaskUpdate.add(obj);
                        }
                    }
                }
            }
            insert lstFollowFailInsert;
            update lstTaskUpdate;
            System.debug(lstFollowFailInsert);
            System.debug(lstTaskUpdate);
        }catch(Exception ex){
            System.debug(ex.getMessage() + ' | ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString());
        }
    }

    private static Map<Id, User> mapGetAllUser() {
        Map<Id, User> mapUser = new Map<Id, User> ([SELECT Id , DODL_Manager__c,PCA_Sup__c,Service_Manager__c FROM User WHERE IsActive = true]);
        return mapUser;
    }

    public override void handleFinish(){
       
    }
}