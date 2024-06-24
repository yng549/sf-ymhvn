public with sharing class scheduleOrderPCA Implements Schedulable {
	
    
	public void execute(SchedulableContext sc){
		getTask();
	}

	public void getTask(){
        String FOLLOWFAIL_ORDER = Schema.SObjectType.Follow_Fail__c.getRecordTypeInfosByDeveloperName()
                                                                .get('Follow_Fail_Order')
                                                                .getRecordTypeId();
        User objUserMarketting = gerUserMarketting();
		Map<Id,User> objUserSalesManager = gerUserSalesManager();
		Map<Id,User> objAllUser = mapGetAllUser();
        Map<Id, List<Task>> mapTaskByOrders = new Map<Id, List<Task>>();
        List<Order> lstOrderQuerry = getLstOrder();
        List<Task> lstTaskUpdate = new List<Task>();
        List<Task> lstTaskInsert = new List<Task>();
        List<Follow_Fail__c> lstFollowFail = new List<Follow_Fail__c>();
		try {
			Datetime dt = Datetime.now();
			for (Order item : lstOrderQuerry){
                if(!item.Tasks.isEmpty()) {
                    for(Task obj : item.Tasks) {
                         if (obj.ActivityDate < System.today()){
                            Follow_Fail__c objFollowFail = new Follow_Fail__c();
                            objFollowFail.RecordTypeId = FOLLOWFAIL_ORDER;
                            objFollowFail.Order__c  = item.Id;
                            objFollowFail.Status__c = 'New';
                            objFollowFail.Consultant__c = item.OwnerId;
                            objFollowFail.OwnerId = item.OwnerId;
                            objFollowFail.Account__c = item.AccountId;
                            if(obj.Task_Name__c == '14 Days') {
                                obj.Status = 'Not Completed';
                                obj.Is_Close__c = true;
                                lstTaskUpdate.add(obj);
                                lstTaskInsert.add(new Task(
                                    Type = 'Call',
                                    Status = 'In Processing',
                                    Priority = 'High',
                                    Subject = 'Follow Order PCA',
                                    WhatId = item.Id,
                                    Estimate_Task__c = item.Delivery_Date__c.addDays(-7),
                                    Task_Name__c = '7 Days',
                                    OwnerId = item.Opportunity.OwnerId,
                                    RecordTypeId = RecordTypeHelper.TASK_ORDER,
                                    Task_Type__c = 'Follow Up',
                                    ActivityDate = item.Delivery_Date__c.addDays(-7)
                                ));
                            }
                            lstFollowFail.add(objFollowFail);
						}
                    }
                }
               
			}
            if(!lstFollowFail.isEmpty()) {
				insert lstFollowFail;
			}
            
			if(!lstTaskInsert.isEmpty()) {
				insert lstTaskInsert;
			}

			if (!lstTaskUpdate.isEmpty()){
				update lstTaskUpdate;	
			}			
		} catch(Exception ex) {
			System.debug('ex :' + ex.getMessage());
		}
	}

	private static Map<Id, User> mapGetAllUser() {
		Map<Id, User> mapUser = new Map<Id, User> ([SELECT Id , DODL_Manager__c FROM USer]);
		return mapUser;
	}

	private static List<Order> getLstOrder(){
		return new List<Order>([SELECT Id
                                		, OwnerId
                                		, Is_Payment__c
                                		, Opportunity.OwnerId
                                		, OpportunityId
                                		, Delivery_Date__c
                                		, AccountId
                                		, (SELECT Id
                                           		, Status
                                           		, Is_Close__c
                                           		, ActivityDate
                                           		, Task_Name__c
                                          FROM Tasks
                                          WHERE Is_Close__c =: false
											AND Status !=: 'Closed'
                                          	AND Status !=: 'Not Completed'
                                          	AND Status !=: 'Completed'
                                          LIMIT 1)
                                FROM Order
                                WHERE RecordTypeId =: RecordTypeHelper.ORDER_PCA
                               		AND Status !=: 'Completed'
                               		AND Status !=: 'Closed'
                               		AND Status !=: 'Cancle'
                               		AND Is_Payment__c =: true]);
	}

	private static User gerUserMarketting(){
		return [Select Id, Name
		        From User
		        Where Profile.Name = 'MKT Manager'];
	}

	private static Map<Id,User> gerUserSalesManager(){
		return new Map<Id, User>([Select Id, Name
		        From User
		        Where Profile.Name = 'Community DO DL Manager']);
	}
    
}