public without sharing class BatchAfterSalePCA extends BaseBatchHandler{
    private static FINAL String ORDERPCA = RecordTypeHelper.ORDER_ACCOUNT_PCA;
    private static FINAL String TASKAFTERSALE = RecordTypeHelper.TASK_AFTERSALE;
    private static Map<Id,User> mapAllUser = mapGetAllUser();
   
    public BatchAfterSalePCA() {
        this.objectName = 'Order_Account__c';
    }
    public override Database.querylocator start(Database.BatchableContext BC){ 
        List<String> query = new List<String>();
        query.add('SELECT Id');
        query.add('FROM ' + objectName);
        query.add('WHERE RecordTypeId = :ORDERPCA');
        
        if (Test.isRunningTest()){
            query.add('LIMIT 200');
        }
        return Database.getQueryLocator(String.join(query, ' '));
    }
    
    public override List<SObject> processData(List<SObject> records){
        List<Order_Account__c> lstOA = (List<Order_Account__c>) records;
        List<Order_Account__c> lstProcess = [SELECT Id
                                                , OwnerId
                                                , RecordTypeId
                                                , Order__c
                                                , Account__c
                                                , (SELECT Id, WhatId, Is_Close__c, 
                                                    Task_Name__c, Estimate_Task__c,
                                                    ActivityDate, Status, Subject, 
                                                    OwnerId 
                                                FROM Tasks
                                                WHERE Status = 'In Processing' OR Status = 'Open' )
                                            FROM Order_Account__c
                                            WHERE ID IN: lstOA];
        getTask(lstProcess);
        return records;
    }

    private static void getTask(List<Order_Account__c> lstOA){
        List<Follow_Fail__c> lstFollowFailInsert = new List<Follow_Fail__c>();
        List<Task> lstTaskUpdate = new List<Task>();
        try{
            for (Order_Account__c item : lstOA){
                if (!item.Tasks.isEmpty()) {
                    for (Task obj : item.Tasks){
                        if (!obj.Is_Close__c 
                        && (obj.Status == 'In Processing' || obj.Status == 'Open')
                        && obj.ActivityDate < System.today()){
                            obj.Status = 'Not Completed';
                            obj.Is_Close__c = true;
                            
                            Follow_Fail__c objFollowFail = new Follow_Fail__c();
                            objFollowFail.RecordTypeId = RecordTypeHelper.FOLLOWFAIL_AFTERSALE;
                            if(String.isNotBlank(item.Account__c)) {
                                objFollowFail.Account__c = item.Account__c;
                            }
                            objFollowFail.Order__c = item.Order__c;
                            objFollowFail.After_Sale__c = item.Id;
                            objFollowFail.Status__c = 'New';
                            if(mapAllUser.containsKey(item.OwnerId)) {
                                objFollowFail.OwnerId = item.OwnerId;
                                if(mapAllUser.get(item.OwnerID).PCA_Sup__c != null)
                                    objFollowFail.OwnerId = mapAllUser.get(item.OwnerID).PCA_Sup__c;
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
        Map<Id, User> mapUser = new Map<Id, User> ([SELECT Id , DODL_Manager__c,PCA_Sup__c FROM User WHERE IsActive = true]);
        return mapUser;
    }

    public override void handleFinish(){
       
    }
}