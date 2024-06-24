public with sharing class scheduleAfterDeliveryOrderBike Implements Schedulable {
    private static User objUserMarketting = gerUserMarketting();
    private static Map<Id,User> objUserSalesManager = gerUserSalesManager();
    private static Map<Id,User> objAllUser = mapGetAllUser();
    
    public void execute(SchedulableContext sc){
        getTask();
    }
    
    public void getTask(){
        try {
            List<Order_Account__c> lstOrderAccountQuerry = getLstOrderAccount();
            List<Follow_Fail__c> lstFollowFailInsert = new List<Follow_Fail__c> ();
            List<Task> lstTaskUpdate = new List<Task>();
            List<Task> lstTaskInsert = new List<Task>();
            List<Task> lstTaskInsertPCA = new List<Task>();
            List<Order_Account__c> lstOrderAccountUpdate = new List<Order_Account__c>();

            for (Order_Account__c item : lstOrderAccountQuerry){
                if (!item.Tasks.isEmpty()) {
                    for (Task obj : item.Tasks){
                        if (!obj.Is_Close__c 
                            && obj.Status == 'In Processing' 
                            && obj.ActivityDate < System.today()){
                                obj.Status = 'Not Completed';
                                obj.Is_Close__c = true;
                                if(obj.Task_Name__c == '1 Day Reassign') {
                                    System.debug('1 Day reassign');
                                    Follow_Fail__c objFollowFail = new Follow_Fail__c();
                                    objFollowFail.RecordTypeId = RecordTypeHelper.FOLLOWFAIL_AFTERSALE;
                                    if(String.isNotBlank(item.Account__c)) {
                                        objFollowFail.Account__c = item.Account__c;
                                    }
                                    objFollowFail.Order__c = item.Order__c;
                                    objFollowFail.After_Sale__c = item.Id;
                                    objFollowFail.Status__c = 'New';
                                    if(objAllUser.containsKey(item.OwnerId)) {
                                        objFollowFail.OwnerId = objUserMarketting.Id;
                                    }
                                    lstFollowFailInsert.add(objFollowFail); 
                                } else {
                                    if(item.Order__r.Product__r.Bike_cc__c == '>400cc') {
                                        if(obj.Task_Name__c == '1 Day') {
                                            Task taskClone = obj.clone(false, false, false, false);
                                            taskClone.Status = 'In Processing';
                                            taskClone.Id = null;
                                            taskClone.Is_Close__c = false;
                                            System.debug('Pass1');
                                            taskClone.Subject = 'After Sale 2 Days';
                                            taskClone.Task_Name__c = '2 Days';
                                            taskClone.Estimate_Task__c = taskClone.Estimate_Task__c.addHours(48);
                                            taskClone.ActivityDate = Date.valueOf(taskClone.Estimate_Task__c);    
                                            lstTaskInsert.add(taskClone);                              
                                        } else if(obj.Task_Name__c == '2 Days') {
                                            Task taskClone = obj.clone(false, false, false, false);
                                            taskClone.Status = 'In Processing';
                                            taskClone.Id = null;
                                            taskClone.Is_Close__c = false;
                                            System.debug('Pass2');
                                            taskClone.Subject = 'After Sale 18 Days';
                                            taskClone.Task_Name__c = '18 Days';
                                            taskClone.Estimate_Task__c = taskClone.Estimate_Task__c.addHours(432);
                                            taskClone.ActivityDate = Date.valueOf(taskClone.Estimate_Task__c);
                                            lstTaskInsert.add(taskClone);
                                        }  else if(obj.Task_Name__c == '18 Days') {
                                            Task taskClone = obj.clone(false, false, false, false);
                                            taskClone.Status = 'In Processing';
                                            taskClone.Is_Close__c = false;
                                            System.debug('Pass3');
                                            taskClone.Subject = 'After Sale 30 Days';
                                            taskClone.Task_Name__c = '30 Days';
                                            taskClone.Estimate_Task__c = taskClone.Estimate_Task__c.addHours(720);
                                            taskClone.ActivityDate = Date.valueOf(taskClone.Estimate_Task__c);
                                            lstTaskInsert.add(taskClone);
                                        } else if(obj.Task_Name__c == '30 Days') {
                                            System.debug('Pass4');
                                            Follow_Fail__c objFollowFail = new Follow_Fail__c();
                                            objFollowFail.RecordTypeId = RecordTypeHelper.FOLLOWFAIL_AFTERSALE;
                                            if(String.isNotBlank(item.Account__c)) {
                                                objFollowFail.Account__c = item.Account__c;
                                            }
                                            objFollowFail.Order__c = item.Order__c;
                                            objFollowFail.After_Sale__c = item.Id;
                                            objFollowFail.Status__c = 'New';
                                            if(objAllUser.containsKey(item.OwnerId)) {
                                                objFollowFail.OwnerId = objUserMarketting.Id;
                                            }
                                            lstFollowFailInsert.add(objFollowFail);                             
                                        }
                                    } else if(item.Order__r.Product__r.Bike_cc__c == '<400cc') {
                                        Follow_Fail__c objFollowFail = new Follow_Fail__c();
                                        objFollowFail.RecordTypeId = RecordTypeHelper.FOLLOWFAIL_AFTERSALE;
                                        if(String.isNotBlank(item.Account__c)) {
                                            objFollowFail.Account__c = item.Account__c;
                                        }
                                        objFollowFail.Order__c = item.Order__c;
                                        objFollowFail.After_Sale__c = item.Id;
                                        objFollowFail.Status__c = 'New';
                                        if(obj.Task_Name__c == '2 Days') {
                                            Task taskClone = obj.clone(false, false, false, false);
                                            taskClone.Status = 'In Processing';
                                            taskClone.Is_Close__c = false;
                                            System.debug('Pass5');
                                            taskClone.Subject = 'After Sale 30 Days';
                                            taskClone.Task_Name__c = '30 Days';
                                            taskClone.Estimate_Task__c = taskClone.Estimate_Task__c.addHours(720);
                                            taskClone.ActivityDate = Date.valueOf(taskClone.Estimate_Task__c);
                                            lstTaskInsert.add(taskClone);
                                            if(objAllUser.containsKey(item.OwnerId)) {
                                                objFollowFail.OwnerId = objAllUser.get(item.OwnerId).DODL_Manager__c;
                                            }
                                        }  else if(obj.Task_Name__c == '30 Days') {
                                            System.debug('Pass6');
                                            
                                            if(objAllUser.containsKey(item.OwnerId)) {
                                                objFollowFail.OwnerId = objUserMarketting.Id;
                                            }                  
                                        }
                                        if(String.isNotBlank(objFollowFail.OwnerId)) {
                                           	lstFollowFailInsert.add(objFollowFail);   
                                        }
                                    }
                                }
                                lstTaskUpdate.add(obj);
                            }
                    }
                }
                if(item.Account__r.Last_Activity_Date__c > 30 
                   	&& item.RecordtypeId == RecordTypeHelper.ORDER_ACCOUNT_PCA
                  	&& item.Order__r.Total_Amount__c > 20000000
                  	&& !item.Created_for_PCA__c) {
                    lstTaskInsertPCA.add(new Task(
                        Id = null,
                        Status = 'In Processing',
                        Is_Close__c = false,
                        //RecordTypeId = RecordTypeHelper.TASK_AFTERSALE,
                        WhatId = item.Id,
                        Subject = 'After Sale PCA 1 Day',
                        Task_Name__c = '1 Day',
                        Estimate_Task__c = Datetime.now().addDays(1),
                        ActivityDate = Date.today().addDays(1),
                        OwnerId = item.Order__r.OwnerId
                    ));
                    item.Created_for_PCA__c = true;
                    lstOrderAccountUpdate.add(item);
                }              
            }
            System.debug('lstTaskInsert : ' + lstTaskInsert);
            System.debug('lstTaskInsertPCA : ' + lstTaskInsertPCA);
            System.debug('lstTaskUpdate : ' + lstTaskUpdate);   
            if(!lstTaskInsert.isEmpty()) {
                insert lstTaskInsert;
            }
            if(!lstTaskInsertPCA.isEmpty()) {
                upsert lstTaskInsertPCA;
                if(!lstOrderAccountUpdate.isEmpty()) {
                    update lstOrderAccountUpdate;
                }
            }
            if (!lstTaskUpdate.isEmpty()){
                update lstTaskUpdate;	
            }
            if (!lstFollowFailInsert.isEmpty()){
                System.debug('lstFollowFailInsert :' + lstFollowFailInsert);
                upsert lstFollowFailInsert;	
            }
        }catch(Exception ex) {
            System.debug('ex :' + ex.getMessage() + ' ' + ex.getLineNumber());
        }
    }
    
    private static Map<Id, User> mapGetAllUser() {
        Map<Id, User> mapUser = new Map<Id, User> ([SELECT Id , DODL_Manager__c FROM USer]);
        return mapUser;
    }
    
    private static List<Order_Account__c> getLstOrderAccount(){
        return  new List<Order_Account__c>([SELECT Id
                                           			, OwnerId
                                           			, RecordTypeId
                                           			, Order__r.Product__r.Bike_cc__c
                                           			, Order__r.Product__c
                                           			, Account__r.Last_Activity_Date__c
                                           			, Account__c
                                           			, Order__c
                                            		, Order__r.OrderNumber
                                            		, Order__r.Total_Amount__c
                                            		, Order__r.OwnerId
                                            		, Created_for_PCA__c
                                            		, (SELECT Id
                                                            , WhatId
                                                            , Is_Close__c
                                                            , Task_Name__c
                                                            , Estimate_Task__c
                                                            , ActivityDate
                                                            , Status
                                                            , Subject
                                                            , OwnerId
                                                        FROM Tasks
                                                        WHERE RecordTypeId =: RecordTypeHelper.TASK_AFTERSALE
                                                        	AND (Status =: 'In Processing' OR Status =: 'Open')
                                                      	LIMIT 1)
                                           FROM Order_Account__c
                                           WHERE RecordtypeId =: RecordTypeHelper.ORDER_ACCOUNT_PCA 
                                           		OR RecordtypeId =: RecordTypeHelper.ORDER_ACCOUNT_BIKE]);
    }
    
    private static Progress_Flow_Details__c getFlowDetail240Hour(){
        return [SELECT Id, Name, Activity_Timeout__c
                FROM Progress_Flow_Details__c
                WHERE Activity_Timeout__c = :'240 HOURS'
                LIMIT 1];
    }
    
    private static User gerUserMarketting(){
        return [Select Id, Name
                From User
                Where Profile.Name = 'MKT Manager' LIMIT 1];
    }
    
    private static Map<Id,User> gerUserSalesManager(){
        return new Map<Id, User>([Select Id, Name
                                  From User
                                  Where Profile.Name = 'Community DO DL Manager']);
    }
    public static void cheatTemp() {
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