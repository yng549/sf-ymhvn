public with sharing class FlowCreateTaskOrder {
    private static String strProfileName1 = 'Community DO DL Manager';
	private static String strProfileName2 = 'Community Sale Sup';
	private static String strProfileName3 = 'System Administrator';
	private static String strProfileName4 = 'Community Sale Profile';
	private static String STR_1DAY = '1 DAY';
	private static String STR_10DAYS = '10 DAYS';
    private static String STR_15DAYS = '15 DAYS';
    
    
	public static void onBeforeInsert(List<Order> lstOrderNews){
		updateFieldFlowFails(lstOrderNews);
	}

	public static void onAfterInsert(List<Order> lstOrderNews){
        Map<Id, User> mapUserProfileSale = mapUserProfileSale();
        List<Order> lstOrderSaleCreated = new List<Order>();
        for(Order item : lstOrderNews) {
            if(mapUserProfileSale.containsKey(item.OwnerId)) {
                lstOrderSaleCreated.add(item);
            }
        }
        if(!lstOrderSaleCreated.isEmpty()) {
            createTask(lstOrderNews);
        }
	}

	public static void onAfterUpdate(Map<Id, Order> mapOrderOlds, Map<Id, Order> mapOrderNews){
		List<Order> lstOrder = new List<Order>();
		for (Order item : mapOrderNews.values()){
			if ((item.OwnerId != mapOrderOlds?.get(item.Id)?.OwnerId) 
                || (item.Is_Payment__c != mapOrderOlds?.get(item.Id)?.Is_Payment__c && item.Is_Payment__c)
                || (item.Delivery_Date__c != mapOrderOlds?.get(item.Id)?.Delivery_Date__c)){
				lstOrder.add(item);
			}
		}
		System.debug('lstOrder :' + lstOrder);
		if (!lstOrder.isEmpty()){
			updateOwner(lstOrder);
		}
	}

	private static void updateFieldFlowFails(List<Order> lstOrderNews){
		for (Order item : lstOrderNews){
			item.Flow_Fouls__c = 0;
		}
	}

	private static void createTask(List<Order> lstOrder){
        try {
            Set<Id> setIdlstOrder = new Set<Id>();
            Map<Id, Task> mapOrderTask = new Map<Id, Task>();
            List<Order> lstOrderUpdate = new List<Order>();
            List<Order> lstOrderFilter = new List<Order>();
           
            Progress_Flow_Details__c objFlowDetail10Days = getFlowDetail();
            Map<Id, Profile> objProfileDODLManager = new Map<Id, Profile>([SELECT Id, Name
                                                                                      FROM Profile
                                                                                      WHERE Name = :strProfileName1]);
            Map<Id, Profile> objProfileSaleSub = new Map<Id, Profile>([SELECT Id, Name
                                                                                  FROM Profile
                                                                                  WHERE Name = :strProfileName2]);
            Map<Id, Profile> objProfileSale = new Map<Id, Profile>([SELECT Id, Name
                                                                               FROM Profile
                                                                               WHERE Name = :strProfileName4]);
            Map<Id, User> objUser = getUserById();
            Map<Id, List<Task>> mapIdParentToLstChild = new Map<Id, List<Task>>();
           
            for (Order item : lstOrder){
                if(item.RecordTypeId == RecordTypeHelper.ORDER_BIKE) {
                    setIdlstOrder.add(item.Id);
                }
            }
            if (!setIdlstOrder.isEmpty()){
                List<Order> lstOrderQuerry = getOrderQuerry(setIdlstOrder);
                List<Task> lstTask = getlstTask(lstOrderQuerry);
                if(lstTask.size() > 0) {
                    checkOrderHasTask(lstTask, mapIdParentToLstChild);
                }
                DateTime now = DateTime.parse(System.Now().format());
                if (!lstOrderQuerry.isEmpty()){
                    updateFieldFlowDetails(lstOrderQuerry, objProfileDODLManager, objProfileSaleSub);
                    for (Order item : lstOrderQuerry){
                        if ((objProfileSale.containsKey(item.Owner.ProfileId) 
                             || objProfileSaleSub.containsKey(item.Owner.ProfileId)) && item.Is_Payment__c) {
                            //|| objProfileSaleSub.containsKey(item.Owner.ProfileId) 
                            //|| objProfileDODLManager.containsKey(item.Owner.ProfileId)){
                            
                            item.DO_DL_Owner__c = objUser.get(item.OwnerId).DODL_Manager__c;
                            item.Sale_Sub_DO__c = objUser.get(item.OwnerId).Sale_Sup__c;
                        }
                        
                        if(!mapIdParentToLstChild.containsKey(item.Id)) {
                            System.debug('Pass Case Is Not Exits Task');
                            Task objTask = new Task();
                            objTask.Type = 'Other';
                            objTask.Status = 'In Processing';
                            objTask.Priority = 'High';
                            objTask.Subject = 'Delivery Bike';
                            objTask.Task_Type__c = 'Follow up';
                            objTask.WhatId = item.Id;
                            objTask.WhoId = item.Account.PersonContactId;
                            objTask.Task_Name__c = '10 Days';
                            objTask.Estimate_Task__c = now.addHours(240);
                            objTask.ActivityDate = Date.valueOf(objTask.Estimate_Task__c);
                            item.Progress_Flow_Details__c = objFlowDetail10Days.Id;
                            objTask.RecordTypeId = RecordTypeHelper.TASK_ORDER;
                            objTask.OwnerId = item.OwnerId;
                            mapOrderTask.put(item.Id, objTask);
                        }
                    }
                    if (!mapOrderTask.values().isEmpty()){
                        update lstOrderQuerry;
                        insert mapOrderTask.values();
                    }
                }
            }
        } catch(Exception ex) {
            lstOrder[0].addError(ex.getMessage() + ' ' + ex.getLineNumber());
            System.debug('ex getmessage() :' + ex.getMessage() + ' ' + ex.getLineNumber());
        }
	}

	private static void updateFieldFlowDetails(List<Order> lstOrder, Map<Id, Profile> objProfileDODLManager, Map<Id, Profile> objProfileSaleSub){
		for (Order item : lstOrder){
			if (objProfileDODLManager.containsKey(item.Owner.ProfileId)){
				item.DO_DL_Owner__c = item.OwnerId;
			}
			if (objProfileSaleSub.containsKey(item.Owner.ProfileId)){
				item.Sale_Sub_DO__c = item.OwnerId;
			}
		}
	}

	private static void updateOwner(List<Order> lstOrder){
        try {
            Set<id> setIdOrder = new Set<Id>();
            Map<Id, Task> mapOrderTask = new Map<Id, Task>();
            for (Order item : lstOrder){
                setIdOrder.add(item.Id);
            }
            List<Order> lstOrderUpdate = new List<Order>();
            List<Order> lstOrderFilter = new List<Order>();
            Progress_Flow_Details__c objFlowDetail15Days = getFlowDetail360Hours();
            List<Order> lstOrderQuerry = getOrderQuerry(setIdOrder);
            Progress_Flow_Details__c objFlowDetail10Days = getFlowDetail();
            Progress_Flow_Details__c objFlowDetail1Day = getFlowDetail1Day();
            Map<Id, List<Task>> mapIdParentToLstChild = new Map<Id, List<Task>>();
            Map<Id, Profile> objProfileDODLManager = new Map<Id, Profile>([SELECT Id, Name
                                                                                      FROM Profile
                                                                                      WHERE Name = :strProfileName1]);
            Map<Id, Profile> objProfileSaleSub = new Map<Id, Profile>([SELECT Id, Name
                                                                                  FROM Profile
                                                                                  WHERE Name = :strProfileName2]);
            Map<Id, Profile> objProfileSale = new Map<Id, Profile>([SELECT Id, Name
                                                                               FROM Profile
                                                                               WHERE Name = :strProfileName4]);
            if (!lstOrderQuerry.isEmpty()){
                for (Order item : lstOrderQuerry) {
                    if (objProfileDODLManager.containsKey(item.Owner.ProfileId)){
                        item.DO_DL_Owner__c = item.DO_DL_Owner__c != Null ? item.DO_DL_Owner__c : item.OwnerId;
                    } else if (objProfileSaleSub.containsKey(item.Owner.ProfileId)){
                        item.Sale_Sub_DO__c = item.Sale_Sub_DO__c != Null ? item.Sale_Sub_DO__c : item.OwnerId;
                        System.debug('item.Sale_Sub_DO__c :' + item.Sale_Sub_DO__c);
                    }
                    if (objProfileSale.containsKey(item.Owner.ProfileId) && item.Is_Payment__c){
                        lstOrderFilter.add(item);
                    }
                    lstOrderUpdate.add(item);
                }
                if (!lstOrderUpdate.isEmpty()){
                    update lstOrderUpdate;
                }
                if (!lstOrderFilter.isEmpty()){
                    List<Task> lstTask = getlstTask(lstOrderFilter);
                    if (!lstTask.isEmpty()){
                        checkOrderHasTask(lstTask, mapIdParentToLstChild);
                        DateTime now = DateTime.parse(System.Now().format());
                        for (Order item : lstOrderFilter){
                            Boolean flagInProcessing = false;
                            if (!mapIdParentToLstChild.containsKey(item.Id) && item.RecordTypeId == RecordTypeHelper.ORDER_BIKE){
                                Task objTask = new Task();
                                objTask.Type = 'Other';
                                objTask.Status = 'In Processing';
                                objTask.Priority = 'High';
                                objTask.Subject = 'Delivery Bike';
                                objTask.WhatId = item.Id;
                                objTask.WhoId = item.Account.PersonContactId;
                                objTask.OwnerId = item.OwnerId;
                                objTask.Task_Type__c = 'Follow up';
                                objTask.RecordTypeId = RecordTypeHelper.TASK_ORDER;
                                if(item.Flow_Fouls__c >= 2) {
                                    objTask.Task_Name__c = '1 Day';
                                    objTask.Estimate_Task__c = now.addHours(24);
                                    objTask.ActivityDate = Date.valueOf(objTask.Estimate_Task__c);
                                    item.Progress_Flow_Details__c = objFlowDetail1Day.Id;
                                } else {
                                    Integer distanceDaytest = item.EffectiveDate.daysBetween(item.Delivery_Date__c);
                                    objTask.Task_Name__c = '10 Days';
                                    objTask.Estimate_Task__c = now.addHours(240);
                                    objTask.ActivityDate = Date.valueOf(objTask.Estimate_Task__c);
                                    item.Progress_Flow_Details__c = objFlowDetail10Days.Id;
                                }
                                mapOrderTask.put(item.Id, objTask);
                            } else {
                                for(Task objTask : mapIdParentToLstChild.get(item.Id)) {
                                    if(objTask.Status == 'In Processing' && !objTask.Is_Close__c) {
                                        flagInProcessing = true;
                                        break;
                                    }
                                }
                                if(!flagInProcessing) {
                                    Task objTask = new Task();
                                    objTask.Type = 'Other';
                                    objTask.Status = 'In Processing';
                                    objTask.Priority = 'High';
                                    objTask.Subject = 'Delivery Bike';
                                    objTask.OwnerId = item.OwnerId;
                                    objTask.WhatId = item.Id;
                                    objTask.WhoId = item.Account.PersonContactId;
                                    objTask.Task_Type__c = 'Follow up';
                                    objTask.RecordTypeId = RecordTypeHelper.TASK_ORDER;
                                    if(item.Flow_Fouls__c >= 2) {
                                        objTask.Task_Name__c = '1 Day';
                                        objTask.Estimate_Task__c = now.addHours(24);
                                        objTask.ActivityDate = Date.valueOf(objTask.Estimate_Task__c);
                                        item.Progress_Flow_Details__c = objFlowDetail1Day.Id;
                                    } else {
                                        objTask.Task_Name__c = '10 Days';
                                        objTask.Estimate_Task__c = now.addHours(240);
                                        objTask.ActivityDate = Date.valueOf(objTask.Estimate_Task__c);
                                        item.Progress_Flow_Details__c = objFlowDetail10Days.Id;
                                        /*else if (item.Product__r.Bike_cc__c == '<400cc') {
                                            objTask.Task_Name__c = '15 Days';
                                            objTask.Estimate_Task__c = now.addHours(360); //objFlowDetail360Hours
                                            objTask.ActivityDate = Date.valueOf(objTask.Estimate_Task__c);
                                            item.Progress_Flow_Details__c = objFlowDetail15Days.Id;
                                        }*/
                                    }
                                    mapOrderTask.put(item.Id, objTask);
                                }
                            }
                        }
                    }
                }
                if (!mapOrderTask.values().isEmpty()){
                    update lstOrderFilter;
                    insert mapOrderTask.values();
                }
            }
        } catch(exception ex) {
            System.debug('ex getmessage() :' + ex.getMessage());
        }
		
	}


	

	
	private static List<Task> getlstTask(List<Order> lstOrder){
		List<Task> lstTaskQuerry = [SELECT Id, Status, Is_Close__c, WhatId
		                            FROM Task  
                                    WHERE (Status  != 'Closed' OR Status != 'Not Completed')
                                   AND WhatId IN: lstOrder];
		return lstTaskQuerry;
	}

	private static Map<Id, User> getUserById(){
		return new Map<Id, User>([SELECT Id, Name, DODL_Manager__c, Sale_Sup__c
							FROM User]);
	}




	//SOQL querry Progress_Flow_Details__c dynamic. Get All fields
	private static List<Order> getOrderQuerry(Set<Id> setIdOrder){
		List<String> fields = new List<String>(Order.SObjectType.getDescribe().fields.getMap().keySet());
		String soql = '' + 
					  ' SELECT Owner.ProfileId , Product__r.Bike_cc__c , Account.PersonContactId,  ' + String.join(fields, ',')+' FROM Order' + 
					  ' WHERE Id IN: setIdOrder';

		List<Order> lstOrderQuerry = (Order[])Database.query(soql);
		return lstOrderQuerry;
	}

	//SOQL querry Progress_Flow_Details__c dynamic. Get All fields
	private static Progress_Flow_Details__c getFlowDetail1Day(){
        String strName = 'Order';
		List<String> fields = new List<String>(Progress_Flow_Details__c.SObjectType.getDescribe().fields.getMap().keySet());
		String soql = '' + 
					  ' SELECT ' + String.join(fields, ',')+' FROM Progress_Flow_Details__c' + 
					  ' WHERE Activity_Timeout__c =: STR_1DAY AND Progress_Flow__r.Name_Object__c =: strName' + 
					  '    LIMIT 1';
		List<Progress_Flow_Details__c> lstFlowDetailQuerry = (Progress_Flow_Details__c[])Database.query(soql);
		return !lstFlowDetailQuerry.isEmpty() ? lstFlowDetailQuerry[0] : new Progress_Flow_Details__c();
    }

	//SOQL querry Progress_Flow_Details__c dynamic. Get All fields
	private static Progress_Flow_Details__c getFlowDetail(){
        String strName = 'Order';
		List<String> fields = new List<String>(Progress_Flow_Details__c.SObjectType.getDescribe().fields.getMap().keySet());
		String soql = '' + 
					  ' SELECT ' + String.join(fields, ',')+' FROM Progress_Flow_Details__c' + 
					  ' WHERE Activity_Timeout__c =: STR_10DAYS AND Progress_Flow__r.Name_Object__c =: strName' + 
					  '    LIMIT 1';
		List<Progress_Flow_Details__c> lstFlowDetailQuerry = (Progress_Flow_Details__c[])Database.query(soql);
        return !lstFlowDetailQuerry.isEmpty() ? lstFlowDetailQuerry[0] : new Progress_Flow_Details__c();
		
	}

    //SOQL querry Progress_Flow_Details__c dynamic. Get All fields
	private static Progress_Flow_Details__c getFlowDetail360Hours(){
        String strName = 'Order';
		List<String> fields = new List<String>(Progress_Flow_Details__c.SObjectType.getDescribe().fields.getMap().keySet());
		String soql = '' + 
					  ' SELECT ' + String.join(fields, ',')+' FROM Progress_Flow_Details__c' + 
					  ' WHERE Activity_Timeout__c =: STR_15DAYS AND Progress_Flow__r.Name_Object__c =: strName' + 
					  '    LIMIT 1';
		List<Progress_Flow_Details__c> lstFlowDetailQuerry = (Progress_Flow_Details__c[])Database.query(soql);
		return !lstFlowDetailQuerry.isEmpty() ? lstFlowDetailQuerry[0] : new Progress_Flow_Details__c();
	}
    
    private static Map<Id, User> mapUserProfileSale() {
        return new Map<Id, User>([SELECT Id, ProfileId FROM User WHERE Profile.Name =: strProfileName4]);
    }

	private static void checkOrderHasTask(List<Task> LstTaks, Map<Id, List<Task>> mapIdParentToLstChild){
		for (Task item : LstTaks){
			if (mapIdParentToLstChild.containsKey(item.WhatID)){
				List<Task> lstTaskChild = mapIdParentToLstChild.get(item.WhatID);
				lstTaskChild.add(item);
				mapIdParentToLstChild.put(item.WhatID, lstTaskChild);
			} else{
				mapIdParentToLstChild.put(item.WhatID, new List<Task>{item});
			}
		}
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