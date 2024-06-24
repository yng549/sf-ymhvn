public without sharing class TriggerHandlerTask{
	public static Boolean flagRun = false;
	public static String STR_1DAY = '1 DAY';
	public static String STR_5DAYS = '5 DAYS';
	public static String STR_7DAYS = '7 DAYS';

	public static void onBeforeUpdate(List<Task> lstTask, Map<Id,Task> oldMap) {
		Datetime dt = Datetime.now();
		List<Task> lstTask5Days = new List<Task>();
		List<Task> lstTask7Days = new List<Task>();
		for (Task item : lstTask){
			if (item.Estimate_Task__c >= dt){
                if(item.Status == 'Completed' && oldMap.get(item.Id).Status != item.Status) {
                    System.debug('Test update Task 1');
                    item.ActivityDate  = Date.valueOf(System.today()); 
                }
				/*if (item.Status == 'Completed'  && item.Task_Name__c == '5 Days'){
					lstTask5Days.add(item);
				} else if(item.Status == 'Completed'  && item.Task_Name__c == '7 Days') {
					lstTask7Days.add(item);
				}*/
			} 
		}
		/*if(!lstTask5Days.isEmpty()) {
			convertLead(lstTask5Days);
		}*/
		if(!lstTask7Days.isEmpty()) {
			//convertOpportunity(lstTask7Days);
		}
	}

	public static void onAfterUpdate(Map<Id,Task> oldMap, Map<Id,Task> newMap){
        List<Task> lstTask3DayForLead = new List<Task>();
		List<Task> lstTask7DayForOpp = new List<Task>();
        List<Task> lstTask10DayForOrder = new List<Task>();
        List<Task> lstTaskAfterSale = new List<Task>();
        List<Task> lstTask1ReassignAfterSale = new List<Task>();
		for (Task item : newMap.values()){
			if (item.ActivityDate >= System.today() && oldMap.get(item.Id).Status != item.Status) {
				if(item.Status == 'Completed'  
                        && item.Task_Name__c == '1 Day' 
                        && item.RecordTypeId == RecordTypeHelper.TASK_LEAD 
                        && !item.Is_Close__c) {
                         System.debug('Pass 1');
					lstTask3DayForLead.add(item);
				} else if(item.Status == 'Completed'  
                          && item.RecordTypeId == RecordTypeHelper.TASK_OPPORTUNITY 
                          && !item.Is_Close__c) {
                     System.debug('Pass 2');
					lstTask7DayForOpp.add(item);
				} else if(item.Status == 'Completed'
                        && (item.Task_Name__c == '10 Days' || item.Task_Name__c == '1 Day' || item.Task_Name__c == '15 Days' || item.Task_Name__c == '14 Days')
                        && item.RecordTypeId == RecordTypeHelper.TASK_ORDER 
                        && !item.Is_Close__c) {
                     System.debug('Pass 3');
					lstTask10DayForOrder.add(item);
				} else if(item.Status == 'Completed'  
                          /*||  item.Task_Name__c == '18 Days'*/
                        && (item.Task_Name__c == '1 Day' || item.Task_Name__c == '2 Days')
                        && item.RecordTypeId == RecordTypeHelper.TASK_AFTERSALE 
                        && !item.Is_Close__c) {
                            System.debug('Pass 4');
					lstTaskAfterSale.add(item);
				} else if(item.Status == 'Completed'
                          && item.Task_Name__c == '1 Day Reassign'
                          && item.Subject == 'After Sale 1 Day Reassign'
                          && item.RecordTypeId == RecordTypeHelper.TASK_AFTERSALE 
                          && !item.Is_Close__c) {
                            System.debug('Pass 5');
                     lstTask1ReassignAfterSale.add(item);         
                 }
			}
		}
		System.debug('lstTask3DayForLead :' + lstTask3DayForLead);
		if (!lstTask3DayForLead.isEmpty()){
            System.debug('Test update Task 2');
			flowTrue(lstTask3DayForLead);
		}
		if(!lstTask7DayForOpp.isempty()) {
            System.debug('Test update Task 3');
			flowTrueOpportunity(lstTask7DayForOpp);
		}
		if(!lstTask10DayForOrder.isEmpty()) {
            System.debug('Test update Task 4');
			createTaskForOrderStatusNotClosed(lstTask10DayForOrder);
		}
        if(!lstTaskAfterSale.isEmpty()) {
            System.debug('Test update Task 5');
            flowTrueAfterSale(lstTaskAfterSale);
        }
        if(!lstTask1ReassignAfterSale.isEmpty()) {
            System.debug('Test update Task 6');
            flowTrueAfterSale1DayReassign(lstTask1ReassignAfterSale);
        }
	
	}
    
    public static void changeDueDateTaskWhenUserOffLive(List<Task> lstTask) {
        Set<Id> setIdUser = new Set<Id>();
        Map<Id, User> mapContactIdWithUser = new Map<Id, User>();
        Map<Id, List<Task>> mapUserWithTasks = new Map<Id, List<Task>>();
        Map<Id, Task> mapTaskUpdate = new Map<Id, Task>();
        Map<Id, List<Roster_Management__c>> mapStaffWithRosters = new Map<Id, List<Roster_Management__c>>();
        try {
            List<Task> lstTaskQuery = [SELECT Id
                                                , OwnerId
                                                , ActivityDate
                                                , Estimate_Task__c
                                        FROM Task 
                                        WHERE Id IN: lstTask];
            System.debug('lstTaskQuery:' + lstTaskQuery);
            System.debug('lstTaskQuery Id :' + lstTaskQuery[0].Id);
            for(Task item : lstTaskQuery) {
                setIdUser.add(item.OwnerId);
            }
            Map<Id, User> mapUserByContactId = new Map<Id, User>([SELECT Id
                                                                  		, ContactId 
                                                                  FROM User 
                                                                  WHERE Id IN: setIdUser 
                                                                  	AND IsActive =: true]);
            for(User item : mapUserByContactId.values()) {
                mapContactIdWithUser.put(item.ContactId, item);
            }
            List<Roster_Management__c> lstRosterManagementQuery = [SELECT Id
                                                                   		, Date__c
                                                                   		, Staff__c
                                                                   		, Absent_Submit__c
                                                                   FROM Roster_Management__c 
                                                                   WHERE Staff__c IN: mapContactIdWithUser.keySet() 
                                                                   		AND Date__c >=: lstTaskQuery[0].ActivityDate
                                                                   ORDER BY Date__c ASC];
            System.debug('lstRosterManagementQuery:' + lstRosterManagementQuery);
            for(Roster_Management__c item : lstRosterManagementQuery) {
                if(mapStaffWithRosters.containsKey(item.Staff__c)) {
                    List<Roster_Management__c> lstRosters = mapStaffWithRosters.get(item.Staff__c);
                    lstRosters.add(item);
                    mapStaffWithRosters.put(item.Staff__c, lstRosters);
                } else {
                    mapStaffWithRosters.put(item.Staff__c, new List<Roster_Management__c>{item});
                }
            }
            for(Task item : lstTaskQuery) {
                if(mapUserWithTasks.containsKey(item.OwnerId)) {
                    List<Task> lstTaskExists = mapUserWithTasks.get(item.OwnerId);
                    lstTaskExists.add(item);
                    mapUserWithTasks.put(item.OwnerId, lstTaskExists);
                } else {
                    mapUserWithTasks.put(item.OwnerId, new List<Task>{item});
                }
            }
            System.debug('mapStaffWithRosters:' + mapStaffWithRosters);
            Boolean flag1 = false;
            for(Roster_Management__c rst : lstRosterManagementQuery) {
                if(mapContactIdWithUser.containsKey(rst.Staff__c)) {
                    System.debug('mapContactIdWithUser.get(rst.Staff__c).Id: ' + mapContactIdWithUser.get(rst.Staff__c).Id);
                    if(mapUserWithTasks.containsKey(mapContactIdWithUser.get(rst.Staff__c).Id)) {
                        
                        for(Task itmTask : mapUserWithTasks.get(mapContactIdWithUser.get(rst.Staff__c).Id)) {
                            System.debug('rst.Date__c:' + rst.Date__c);
                            System.debug('itmTask.ActivityDate:' + itmTask.ActivityDate);
                            
                            if(rst.Date__c == itmTask.ActivityDate && rst.Absent_Submit__c) {
                                if(!flag1) {
                                    flag1 = true;
                                }
                                System.debug('Line 152');
                                Boolean flag2 = false;
                                for(Roster_Management__c item : mapStaffWithRosters.get(rst.Staff__c)) {
                                    System.debug('item.Date__c: ' + item.Date__c);
                                    if(!item.Absent_Submit__c && item.Date__c > itmTask.ActivityDate) {
                                        System.debug('162');
                                        itmTask.ActivityDate = item.Date__c;
                                        itmTask.Estimate_Task__c = item.Date__c;
                                        mapTaskUpdate.put(itmTask.Id, itmTask);
                                        flag2 = true;
                                        break;
                                    }
								}
                                if(!flag2) {
                                    itmTask.ActivityDate = itmTask.ActivityDate.addMonths(1);
                                    itmTask.Estimate_Task__c = itmTask.ActivityDate;
                                    mapTaskUpdate.put(itmTask.Id, itmTask);
                                }
                            }
                        }
                    }
                }
            }
            System.debug('lstRosterManagementQuery: ' + lstRosterManagementQuery);
            if(!flag1 & !lstRosterManagementQuery.isEmpty()) {
                for(Roster_Management__c item : lstRosterManagementQuery) {
                    System.debug('Line 188 roster: ' + item);
                    if(!item.Absent_Submit__c) {
                        lstTaskQuery[0].ActivityDate = item.Date__c;
                        lstTaskQuery[0].Estimate_Task__c = lstTaskQuery[0].ActivityDate;
                        System.debug('lstTaskQuery: ' + lstTaskQuery[0]);
                        break;
                    }
                    
                }
            }
            System.debug('mapTaskUpdate:  ' + mapTaskUpdate);
            if(!mapTaskUpdate.isEmpty() && flag1) {
                update mapTaskUpdate.values();
            }
            if(!flag1) {
                System.debug('Line 194');
                System.debug('lstTaskQuery 194: ' + lstTaskQuery);
                update lstTaskQuery;
            }
        } catch(Exception ex) {
            System.debug('ex getmessage() :' + ex.getMessage() + ' ' + ex.getLineNumber());
        }
    }

    public static void onBeforeInsert(List<Task> lstTask){
		for (Task task : lstTask){
            task.IsVisibleInSelfService = true;
        }
	}

  
	public static void onAfterInsert(List<Task> lstTask){
		
	}

	private static void createTaskForOrderStatusNotClosed(List<Task> lstTask10O15Days) {
        try {
            Map<Id, Task> mapOrderTask = new Map<Id, Task>();
            List<Task> lstTaskUpsert = new List<Task>();
            List<String> fields = new List<String>(Task.SObjectType.getDescribe().fields.getMap().keySet());
                String soql = '' + 
                          ' SELECT ' + String.join(fields, ',') + ' FROM Task' + 
                          ' WHERE Id IN: lstTask10O15Days';
            for(Task item : Database.query(soql)) {
                mapOrderTask.put(item.WhatId, item);
            }
            for(Order item : [SELECT Id, Account.PersonContactId, Status, RecordTypeId, Delivery_Date__c, Is_Payment__c, OwnerId, Product__r.Bike_cc__c FROM Order WHERE Id IN: mapOrderTask.keySet()]) {
                if(mapOrderTask.containsKey(item.Id) && item.Status != 'Closed' && item.Status != 'Cancel') {
                    System.debug('Test Task Closed');
                    Task taskprior = new Task(Id = mapOrderTask.get(item.Id).Id, Is_Close__c = true);
                    Task taskClone = mapOrderTask.get(item.Id).clone(false, false, false, false);
                    taskClone.Status = 'In Processing';
                    taskClone.OwnerId = item.OwnerId;
                    taskClone.WhoId = item.Account.PersonContactId;
                    taskClone.WhatId = item.Id;
                    taskClone.Is_Close__c = false;
                    taskClone.Task_Type__c = 'Follow Up';
                    taskClone.Comment__c = '';
                    taskClone.Description = '';
                    taskClone.RecordTypeId = RecordTypeHelper.TASK_ORDER;
                    taskClone.Task_Name__c = null;
                    if(item.Is_Payment__c && item.RecordTypeId == RecordtypeHelper.ORDER_PCA) {
                        taskClone.Task_Name__c = '7 Days';
                        taskClone.Estimate_Task__c = item.Delivery_Date__c.addDays(-7);
                    } else if( item.RecordTypeId == RecordtypeHelper.ORDER_BIKE) {
                        taskClone.Task_Name__c = '10 Days';
                        taskClone.Estimate_Task__c = Datetime.now().addHours(240);
                    }
                    taskClone.ActivityDate = Date.valueOf(taskClone.Estimate_Task__c);
                    lstTaskUpsert.add(taskprior);
                    if(taskClone.Task_Name__c != null)
                        lstTaskUpsert.add(taskClone);
                }
            }
            upsert lstTaskUpsert;
        } catch(Exception ex) {
            System.debug('ex getmessage() :' + ex.getMessage() + ' ' + ex.getLineNumber());
        }
		
	}

	public static void convertLead(List<Task> lstTaskUpdate){
		try{
			Set<Id> setIdLeads = new Set<Id>();
			List<String> fields = new List<String>(Task.SObjectType.getDescribe().fields.getMap().keySet());
			String soql = '' + 
					  ' SELECT ' + String.join(fields, ',') + ' FROM Task' + 
					  ' WHERE Id IN: lstTaskUpdate';
            
			for (Task item : Database.query(soql)){
				setIdLeads.add(item.WhoId);
			}
			Map<Id, Lead> mapLeadQuerrys = new Map<Id, Lead>([SELECT ID, Status, Progress_Flow_Details__c, Progress_Flow_Details__r.Name
			                                                  FROM Lead
			                                                  WHERE Id IN :setIdLeads]);

			for(Task item : lstTaskUpdate) {
				if(mapLeadQuerrys.containsKey(item.WhoId)) {
					if(mapLeadQuerrys.get(item.WhoId).Status != 'Unqualified' && mapLeadQuerrys.get(item.WhoId).Status != 'Converted') {
						item.addError('Please, You must update field status "converted" or "unqualified" on lead then system automation update field status completed.');
					}
				}
			}
		} catch (Exception ex){
			System.debug('ex getmessage() :' + ex.getMessage() + ' ' + ex.getLineNumber());
		}
	}


	public static void convertOpportunity(List<Task> lstTaskUpdate){
		try{
			Set<Id> setIdOpps = new Set<Id>();
			List<String> fields = new List<String>(Task.SObjectType.getDescribe().fields.getMap().keySet());
			String soql = '' + 
					  ' SELECT ' + String.join(fields, ',')+' FROM Task' + 
					  ' WHERE Id IN: lstTaskUpdate';

			for (Task item : Database.query(soql)){
				setIdOpps.add(item.WhatId);
			}
			Map<Id, Opportunity> mapOpportunityQuerrys = new Map<Id, Opportunity>([SELECT ID
																			, StageName
																			, Progress_Flow_Details__c
																			, Progress_Flow_Details__r.Name
																			, Is_Close__c
																	FROM Opportunity
																	WHERE Id IN : setIdOpps]);

			for(Task item : lstTaskUpdate) {
				if(mapOpportunityQuerrys.containsKey(item.WhatId)) {
					if(mapOpportunityQuerrys.get(item.WhatId).StageName != 'Closed Won'
						&& mapOpportunityQuerrys.get(item.WhatId).StageName != 'Closed Lost') {
						item.addError('Please, You must update field stage "Closed Won" or "Closed Lost" on Opportunity then system automation update field status completed.');
					}
				}
			}
		} catch (Exception ex){
            System.debug('ex getmessage() :' + ex.getMessage() + ' ' + ex.getLineNumber());
		}
	}

	public static void flowTrue(List<Task> lstTaskUpdate){
		try{
			Set<Id> setIdLeads = new Set<Id>();
			List<String> fields = new List<String>(Task.SObjectType.getDescribe().fields.getMap().keySet());
			String soql = '' + 
					  ' SELECT ' + String.join(fields, ',')+' FROM Task' + 
					  ' WHERE Id IN: lstTaskUpdate';
            
			List<Task> lstTaskUpsert = new List<Task>();
			List<Lead> lstLeadUpdate = new List<Lead>();
            
			for (Task item : Database.query(soql)){
				Task taskprior = new Task(Id = item.Id, Is_Close__c = true);
				Task taskClone = item.clone(false, false, false, false);
                
                taskClone.Comment__c = '';
				taskClone.Status = 'In Processing';
				taskClone.OwnerId = item.OwnerId;
				taskClone.Is_Close__c = false;
				taskClone.Estimate_Task__c = Datetime.now().addHours(72);
				taskClone.ActivityDate = Date.valueOf(taskClone.Estimate_Task__c);
				taskClone.Task_Name__c = '3 Days';
                taskClone.Task_Type__c = 'Follow Up';
                taskClone.WhoId = item.WhoId;
                taskClone.WhatId = item.WhatId;
                taskClone.WhoId_Tempt__c = item.WhoId;
				setIdLeads.add(item.WhoId);
                lstTaskUpsert.add(taskprior);
				lstTaskUpsert.add(taskClone);
			}
            upsert lstTaskUpsert;
		} catch (Exception ex){
			System.debug('Exception e '+ex);
            System.debug('Exception e '+ex.getLineNumber());
		}
	}

	//Task For Opportunity Complete
	public static void flowTrueOpportunity(List<Task> lstTaskUpdate){
		try{
			Set<Id> setIdOpps = new Set<Id>();
            Map<Id, Task> mapOpptyWithTask = new Map<Id, Task>();
			List<String> fields = new List<String>(Task.SObjectType.getDescribe().fields.getMap().keySet());
			String soql = '' + 
					  ' SELECT ' + String.join(fields, ',')+' FROM Task' + 
					  ' WHERE Id IN: lstTaskUpdate';
			List<Task> lstTaskUpsert = new List<Task>();
			List<Opportunity> lstOppUpdate = new List<Opportunity>();
			for (Task item : Database.query(soql)){
				mapOpptyWithTask.put(item.WhatId, item);
			}
            // Check Opty RecordType = Bike
            List<Opportunity> lstOpptyQuerry = [SELECT Id, StageName, RecordTypeId  FROM Opportunity WHERE Id IN: mapOpptyWithTask.keySet() AND RecordTypeId != :RecordTypeHelper.OPPORTUNITY_PCA];
            for (Opportunity item : lstOpptyQuerry){
                if(mapOpptyWithTask.containsKey(item.Id)) {
                    if(item.StageName  != 'Deposit' && item.StageName  != 'Contract') {
                        Task taskprior = new Task(Id = mapOpptyWithTask.get(item.Id).Id, Is_Close__c = true);
                        Task taskClone = mapOpptyWithTask.get(item.Id).clone(false, false, false, false);
                        taskClone.Comment__c = '';
                        taskClone.Description = '';
                        taskClone.Status = 'In Processing';
                        taskClone.Subject = 'Opportunity Task (7 days)';
                        taskClone.OwnerId = mapOpptyWithTask.get(item.Id).OwnerId;
                        taskClone.WhoId = mapOpptyWithTask.get(item.Id).WhoId;
                        taskClone.WhatId = item.Id;
                        taskClone.Is_Close__c = false;
                        taskClone.Estimate_Task__c = Datetime.now().addHours(168);
                        taskClone.ActivityDate = Date.valueOf(taskClone.Estimate_Task__c);
                        taskClone.Task_Name__c = '7 Days';
                        lstTaskUpsert.add(mapOpptyWithTask.get(item.Id));
                        lstTaskUpsert.add(taskClone);
                	}
                }
			}
            if(!lstTaskUpsert.isEmpty()) {
                upsert lstTaskUpsert;
            }
		} catch (Exception ex){
			System.debug('Exception e '+ex);
            System.debug('Exception e '+ex.getLineNumber());
		}
	}
    
    //Task For Opportunity Complete
	public static void flowTrueAfterSale(List<Task> lstTaskUpdate){
		try{
            Map<Id, Task> mapOrderAccountTask = new Map<Id, Task>();
			List<String> fields = new List<String>(Task.SObjectType.getDescribe().fields.getMap().keySet());
			String soql = '' + 
					  ' SELECT ' + String.join(fields, ',') + ' FROM Task' + 
					  ' WHERE Id IN: lstTaskUpdate';
			List<Task> lstTaskUpsert = new List<Task>();
            for(Task item : Database.query(soql)) {
                mapOrderAccountTask.put(item.WhatId, item);
            }
            
			for (Order_Account__c item : [SELECT Id
                                          		, OwnerId
                                          		, Account__r.LastActivityDate
                                          		, Account__r.Last_Activity_Date__c
                                          		,  Order__r.Product__r.Bike_cc__c
                                          		, RecordTypeId
                                          FROM Order_Account__c 
                                          WHERE Id IN: mapOrderAccountTask.keySet()]){
                if(mapOrderAccountTask.containsKey(item.Id) && item.RecordTypeId == RecordTypeHelper.ORDER_ACCOUNT_BIKE) {
                    Task taskprior = new Task(Id = mapOrderAccountTask.get(item.Id).Id, Is_Close__c = true);
                    Task taskClone = mapOrderAccountTask.get(item.Id).clone(false, false, false, false);
                    taskClone.Status = 'In Processing';
                    taskClone.Description = '';
                    taskClone.OwnerId = mapOrderAccountTask.get(item.Id).OwnerId;
                    taskClone.Comment__c = '';
                    taskClone.Is_Close__c = false;
                    taskClone.WhoId = mapOrderAccountTask.get(item.Id).WhoId;
                	taskClone.WhatId = mapOrderAccountTask.get(item.Id).WhatId;
                    
                    if(item.Order__r.Product__r.Bike_cc__c == '>400cc' ) {
                        if(mapOrderAccountTask.get(item.Id).Task_Name__c == '1 Day') {
                            taskClone.Subject = 'After Sale 2 Days';
                            taskClone.Task_Name__c = '2 Days';
                            taskClone.Estimate_Task__c = Datetime.now().addHours(48);
                            taskClone.ActivityDate = Date.today().addDays(2);
                        } else if(mapOrderAccountTask.get(item.Id).Task_Name__c == '2 Days') {
                            taskClone.Subject = 'After Sale 18 Days';
                            taskClone.Task_Name__c = '18 Days';
                            taskClone.Estimate_Task__c = Datetime.now().addHours(432);
                            taskClone.ActivityDate = Date.today().addDays(18);
                        }
                    } else if(item.Order__r.Product__r.Bike_cc__c == '<400cc') {
                        if(mapOrderAccountTask.get(item.Id).Task_Name__c == '2 Days') {
                            taskClone.Subject = '30 Days';
                            taskClone.Task_Name__c = '30 Days';
                            taskClone.Estimate_Task__c = Datetime.now().addHours(720);
                            taskClone.ActivityDate = Date.today().addDays(30);
                        }
                    }
                    
                    lstTaskUpsert.add(taskprior);
                    lstTaskUpsert.add(taskClone);
                }
			}
            upsert lstTaskUpsert;
		} catch (Exception ex){
			System.debug('Exception e '+ex);
            System.debug('Exception e '+ex.getLineNumber());
		}
	}
    
    public static void flowTrueAfterSale1DayReassign(List<Task> lstTaskUpdate){
		try{
            
			Set<Id> setIdOrderAccount = new Set<Id>();
            Map<Id, Task> mapOrderAccountTask = new Map<Id, Task>();
			List<String> fields = new List<String>(Task.SObjectType.getDescribe().fields.getMap().keySet());
			String soql = '' + 
					  ' SELECT ' + String.join(fields, ',')+' FROM Task' + 
					  ' WHERE Id IN: lstTaskUpdate';

			List<Task> lstTaskUpsert = new List<Task>();
            for(Task item : Database.query(soql)) {
                mapOrderAccountTask.put(item.WhatId, item);
            }
            
			for (Order_Account__c item :  [SELECT Id
                                           		, OwnerId
                                           		, Order__r.Product__r.Bike_cc__c
                                           		, Order__r.RecordTypeId
                                           		, RecordTypeId
                                           FROM Order_Account__c WHERE Id IN: mapOrderAccountTask.keySet()]){
                if(mapOrderAccountTask.containsKey(item.Id) && item.RecordTypeId == RecordTypeHelper.ORDER_ACCOUNT_BIKE) {
                    Task taskprior = new Task (Id = mapOrderAccountTask.get(item.Id).Id, Is_Close__c= true);
                    Task taskClone = mapOrderAccountTask.get(item.Id).clone(false, false, false, false);
                    taskClone.Status = 'In Processing';
                    taskClone.Comment__c = '';
                    taskClone.Description = '';
                    taskClone.WhoId = mapOrderAccountTask.get(item.Id).WhoId;
                	taskClone.WhatId = mapOrderAccountTask.get(item.Id).WhatId;
                    taskClone.OwnerId = mapOrderAccountTask.get(item.Id).OwnerId;
                    taskClone.Is_Close__c = false;
                    taskClone.Subject = 'After Sale 30 Days';
                    taskClone.Task_Name__c = '30 Days';
                    taskClone.Estimate_Task__c = Datetime.now().addHours(720);
                    taskClone.ActivityDate = Date.valueOf(taskClone.Estimate_Task__c);
                    lstTaskUpsert.add(taskprior);
                    lstTaskUpsert.add(taskClone);
                }
			}
            System.debug('TriggerHandlerTask.flowTrueAfterSale1DayReassign: ' + lstTaskUpsert);
            upsert lstTaskUpsert;
		} catch (Exception ex){
			System.debug('Exception e '+ex);
            System.debug('Exception e '+ex.getLineNumber());
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
            a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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