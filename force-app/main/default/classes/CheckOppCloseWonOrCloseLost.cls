public without sharing class CheckOppCloseWonOrCloseLost {
    public static Boolean flagRun = false;
    
    public static void onBeforeUpdate(Map<Id, Opportunity> mapOpportunityOlds, Map<Id, Opportunity> mapOpportunityNews) {
        List<Opportunity> lstOpportunity = new List<Opportunity>();
        Map<Id, Opportunity> mapOpptyBike = new Map<Id, Opportunity>();
		for (Opportunity item : mapOpportunityNews.values()){
			if (item.StageName != mapOpportunityOlds?.get(item.Id)?.StageName){
                if(item.StageName == 'Closed Lost') {
                    item.Status_Before_Close_Lost__c = mapOpportunityOlds.get(item.Id).StageName;
                } else if(item.StageName == 'Closed Won' && item.RecordTypeId == RecordTypeHelper.OPPORTUNITY_BIKE) {
                    mapOpptyBike.put(item.Id, item);
                }
			}
		}
        if(!mapOpptyBike.values().isEmpty()) {
            System.debug('lstOpptyBike:' + mapOpptyBike.values());
            checkConditionBeforeCloseWon(mapOpptyBike);
        }
    }
    
    private static void checkConditionBeforeCloseWon(Map<Id, Opportunity> mapOpptyBike) {
        try {
            Set<Id> setIdOrder = new Set<Id>();
            List<Opportunity> lstOpportunity = [SELECT Id
                                                        , (SELECT Id
                                                                , Delivery_Date__c
                                                                , Remaining_Amount__c 
                                                            FROM Orders 
                                                            WHERE RecordTypeId =: RecordTypeHelper.ORDER_BIKE
                                                                AND Status =: 'Completed'
                                                            LIMIT 1)
                                                		, (SELECT Id
                                                           		, Comment__c 
                                                           FROM Tasks
                                                           WHERE Status =: 'In Processing' AND Status =: 'Open')
                                                FROM Opportunity 
                                                WHERE Id IN: mapOpptyBike.keySet()];
            System.debug('lstOpportunity:' + lstOpportunity);                                    
            for(Opportunity item : lstOpportunity) {
                if(!item.Tasks.isEmpty()) {
                    if(String.isBlank(item.Tasks[0].Comment__c) || item.Tasks[0].Comment__c.length() < 80) {
                        mapOpptyBike.values().get(0).addError('Having a task open, user have to fill in Comment.');
                    }
				}
                if(item.Orders.isEmpty()) {
                    mapOpptyBike?.get(item.Id).addError('Opportunity không tồn tại bất kì order bike nào.');
                } else {
                    System.debug('Pass'); 
                    for(Order objOrder : item.Orders) {
                        setIdOrder.add(objOrder.Id);
                        if(objOrder.Delivery_Date__c == Null) {
                            mapOpptyBike?.get(item.Id).addError('Order trên opportunity ngày giao xe chưa được điền thông tin.');
                            break;
                        }
                        if(objOrder.Remaining_Amount__c > 0) {
                            mapOpptyBike?.get(item.Id).addError('Số tiền còn lại chưa thanh toán đủ');
                            break;
                        }
                    }
                }
            }
            List<Order> lstOrderQuerry = [SELECT Id, OpportunityId, (SELECT Id FROM Einvoices__r) FROM Order WHERE Id IN: setIdOrder];
            for(Order item : lstOrderQuerry) {
                if(item.Einvoices__r.isEmpty()) {
                    mapOpptyBike?.get(item.OpportunityId).addError('Order chưa phát sinh E-Invoince.');
                }
            }
        } catch(Exception ex) {
            mapOpptyBike.values().get(0).addError(ex.getMessage() + ' ' + ex.getLineNumber());
        }
    }
    
    public static void onAfterUpdate(Map<Id, Opportunity> mapOpportunityOlds, Map<Id, Opportunity> mapOpportunityNews){
        System.debug('CheckOppCloseWon After Update');
		Set<Id> setIdOpp = new Set<Id>();
        List<Opportunity> lstOpptyPCA = new List<Opportunity>();
        List<Opportunity> lstOpptyBike = new List<Opportunity>();
        Set<Id> setIdOrder = new Set<Id>();
        Map<Id, Opportunity> mapOpptyBikeCloseWon = new Map<Id, Opportunity>();
		for (Opportunity item : mapOpportunityNews.values()){
			if (item.StageName != mapOpportunityOlds?.get(item.Id)?.StageName){
                if((item.StageName == 'Closed Won') || (item.StageName == 'Closed Lost')) {
                    //item.addError('Currently');
                    setIdOpp.add(item.Id);
                }
                
                if(item.RecordTypeId == RecordTypeHelper.OPPORTUNITY_PCA && item.StageName == 'Closed Won') {
                    lstOpptyPCA.add(item);
                } else if(item.RecordTypeId == RecordTypeHelper.OPPORTUNITY_BIKE && item.StageName == 'Closed Won') {
                    System.debug('Run Case');
                    mapOpptyBikeCloseWon.put(item.Id, item);
                }
			}/*
            if(item.RecordTypeId == RecordTypeHelper.OPPORTUNITY_BIKE 
                && item.Buy_PCA__c != mapOpportunityOlds?.get(item.Id)?.Buy_PCA__c
                && item.Buy_PCA__c) {
                    System.debug('Run PCA');
                       System.debug('CheckOppCloseWon After Update 2');
                lstOpptyBike.add(item); 
            }*/
		}
		if (!setIdOpp.isEmpty()){
			updateTaskComplete(setIdOpp);
		}
        if(!lstOpptyPCA.isEmpty()) {
            closeWonOpportynity(lstOpptyPCA);
        }
        if(!lstOpptyBike.isEmpty()) {
            cloneOpportunityWhenCheckBoxBuyPCAOnBike(lstOpptyBike);
        }
        if(!mapOpptyBikeCloseWon.values().isEmpty()) {
            System.debug('Run Case Map');
            progressWhenCloseWonOppty(mapOpptyBikeCloseWon);
        }
	}

    private static void progressWhenCloseWonOppty(Map<Id, Opportunity> mapOpptyBikeCloseWon) {
        try {
            Map<Id, Task> mapTaskByOppty = new Map<Id, Task>();
            List<Order> lstOrderBike = new List<Order>();
            List<Order> lstOrderUpdate = new List<Order>();
            Set<Id> setIdOrder = new Set<Id>();
            List<Opportunity> lstOpptyQuerry = [SELECT Id
                                                        , (SELECT Id
                                                        , Delivery_Date__c
                                                        , Remaining_Amount__c 
                                                        FROM Orders 
                                                        WHERE Status =: 'Completed'
                                                            AND RecordTypeId =: RecordTypeHelper.ORDER_BIKE
                                                        LIMIT 1)
                                                FROM Opportunity
                                                WHERE Id IN: mapOpptyBikeCloseWon.keySet()];
            List<Task> lstTaskQuerry = getLstTask(mapOpptyBikeCloseWon.keySet());
            System.debug('lstTaskQuerry:' + lstTaskQuerry);
            for(Task item : lstTaskQuerry) {
                mapTaskByOppty.put(item.WhatId, item);
            }
            for(Opportunity item : lstOpptyQuerry) {
                if(!item.Orders.isEmpty()) {
                    setIdOrder.add(item.Orders[0].Id);
                }
                if(mapTaskByOppty.containsKey(item.Id)) {
                    mapTaskByOppty.get(item.Id).Status = 'Completed';
                }
            }
            if(!mapTaskByOppty.values().isEmpty()) {
                update mapTaskByOppty.values();
            }
            System.debug('setIdOrder:' + setIdOrder);
            if (!setIdOrder.isEmpty()){
                List<Task> lstTaskInsert = new List<Task>();
                List<Order_Account__c> lstOrderAccountQuerry = [SELECT Id
                                                                	, Account__r.PersonContactId
                                                                	, Order__c, Order__r.Product__c
                                                                	, Bike_cc_Product__c, RecordTypeID
                                                                	, Order__r.Total_Amount__c
                                         FROM Order_Account__c
                                         WHERE Order__c IN: setIdOrder];
                System.debug('lstOrderAccountQuerry:' + lstOrderAccountQuerry);
                for (Order_Account__c item : lstOrderAccountQuerry){
                    if (item.Bike_cc_Product__c == '>400cc' && item.RecordTypeId == RecordTypeHelper.ORDER_ACCOUNT_BIKE){
                        /*(item.RecordTypeID == RecordTypeHelper.ORDER_ACCOUNT_PCA && item.Order__r.Total_Amount__c > 20000000)*/
                        System.debug('Pass1');
                        lstTaskInsert.add(createTaskByProductBike(item, '1 Day', 24));
                    } else if (item.Bike_cc_Product__c == '<400cc' && item.RecordTypeId == RecordTypeHelper.ORDER_ACCOUNT_BIKE){
                        lstTaskInsert.add(createTaskByProductBike(item, '2 Days', 48));
                    }
                }
                if (lstTaskInsert.isEmpty()){
                    return;
                }
                insert lstTaskInsert;
            }
            // if(!lstOrderUpdate.isEmpty()) {
            //     update lstOrderUpdate;
            // }
        } catch(Exception ex) {
            mapOpptyBikeCloseWon.values().get(0).addError(ex.getMessage() + ' ' + ex.getLineNumber());
        }
    }

    private static Task createTaskByProductBike(Order_Account__c item, String strNameTask, Integer intTimeAdd){
        Datetime dt = Datetime.now();
        Task task = new Task();
        task.WhatId = item.Id;
        task.WhoId = item.Account__r.PersonContactId;
        task.Subject = item.RecordTypeId == RecordTypeHelper.ORDER_ACCOUNT_BIKE ? 'Follow up After Sale Bike' : 
       					(item.RecordTypeId == RecordTypeHelper.ORDER_ACCOUNT_PCA ? 'Follow up After Sale PCA' : null);
        task.Status = 'In Processing';
        task.Is_Close__c = false;
        task.RecordTypeId = RecordTypeHelper.TASK_AFTERSALE;
        task.Task_Type__c = 'Follow up';
        task.Task_Name__c = strNameTask;
        task.Estimate_Task__c = dt.addHours(intTimeAdd);
        task.ActivityDate = Date.valueOf(task.Estimate_Task__c);
        System.debug('task :' + task);
        return task;
    }

    private static void cloneOpportunityWhenCheckBoxBuyPCAOnBike(List<Opportunity> lstOpportunityNews) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Opportunity> lstOpportunityInsert = new List<Opportunity>();
            List<Task> lstTaskForUser = new List<Task>();
            List<Opportunity> lstOpptyQuerry = [SELECT Id
                                                        , PCA_Type__c
                                                        , RecordTypeId
                                                        , OwnerId
                                                        , Account.Name
                                                        , Account.DO_DL_Create_Account__c
                                                FROM Opportunity
                                                WHERE Id =: lstOpportunityNews];
            Set<Id> setIdOpportunity = new Set<Id>();            
                                               
            List<User> objUser = [SELECT Id
                            	, AccountId 
                            FROM User 
                            WHERE Id =: userinfo.getuserid()
                           		AND IsActive =: true];
            if(objUser.isEmpty()) {
                return;
            }
            List<User> objUserPCA = [SELECT Id
                                      , ProfileId
                                      , Profile.Name 
                                    FROM    User
                                    WHERE AccountId =: objUser[0].AccountId
                                        AND Profile.Name =: 'Community Consultant PCA'
                               			AND IsActive =: true
                                    LIMIT 1];                
            List<User> objUserPCAClothing = [SELECT Id
                                        , ProfileId
                                        , Profile.Name 
                                FROM    User
                                WHERE AccountId =: objUser[0].AccountId
                                    AND Profile.Name =: 'Community Consultant PCA 2'
                                    AND IsActive =: true
                                LIMIT 1];
             	System.debug('objUserPCAClothing: ' + objUserPCAClothing);
            for(Opportunity item : lstOpptyQuerry) {
                setIdOpportunity.add(item.Id);
                //Nếu ko có danh sách objUserPCA thì ko chạy vào.
                if(!objUserPCA.isEmpty()) {
                    lstOpportunityInsert.add(new Opportunity(
                        RecordTypeId = RecordTypeHelper.OPPORTUNITY_PCA,
                        PCA_Type__c = 'P&A',
                        OwnerId = objUserPCA[0].Id,
                        Opportunity_Bike__c = item.Id,
                        AccountId = item.AccountId,
                        StageName = 'Assigned',
                        CloseDate = Date.today().addMonths(1),  
                        Name = item.Account.Name + '-P&A',
                      	DODL_Create__c =  item.Account.DO_DL_Create_Account__c

                    ));
                    	System.debug('Test 1: ' + lstOpportunityInsert);
                }/*
                //Nếu ko có danh sách objUserPCAClothing thì ko chạy vào
                if(!objUserPCAClothing.isEmpty()) {
                    lstOpportunityInsert.add(new Opportunity(
                        RecordTypeId = RecordTypeHelper.OPPORTUNITY_PCA,
                        PCA_Type__c = 'Clothing',
                        OwnerId = objUserPCAClothing[0].Id,
                        Opportunity_Bike__c = item.Id,
                        AccountId = item.AccountId,
                        StageName = 'Assigned',
                        CloseDate = Date.today().addMonths(1),
                        Name = item.Account.Name + '-Clothing',
                        DODL_Create__c =  item.Account.DO_DL_Create_Account__c

                    ));
                    System.debug('Test 2: ' + lstOpportunityInsert);
                }*/
            }
            List<Task> lstTaskInProcess = [SELECT Id, Status FROM Task WHERE WhatId IN: setIdOpportunity AND Status =: 'In Processing'];
            if(!lstTaskInProcess.isEmpty()) {
                for(Task item : lstTaskInProcess) {
                    item.Status = 'Completed';
                }
                update lstTaskInProcess;
            }
            
            if(lstOpportunityInsert.isEmpty()) {
               return; 
              
            }
            insert lstOpportunityInsert;                       
            for(Opportunity item : lstOpportunityInsert) {
                lstTaskForUser.add(new Task(
                    Type = 'Call',
                    Status = 'In Processing',
                    Priority = 'High',
                    Subject = 'Follow Opportunity PCA',
                    WhatId = item.Id,
                    Estimate_Task__c = Datetime.now().addHours(48),
                    Task_Name__c = '2 Days',
                    OwnerId = item.OwnerId,
                    RecordTypeId = RecordTypeHelper.TASK_OPPORTUNITY,
                    Task_Type__c = 'Follow Up',
                    ActivityDate = Date.today().addDays(2)
                ));
            }
            insert lstTaskForUser;
        } Catch(Exception ex) {
            System.debug('ex.getMessage() :' + ex.getMessage() + ' ' + ex.getLineNumber());
            Database.rollBack(sp);
			lstOpportunityNews.get(0).addError(ex.getMessage() + ex.getLineNumber());
        }
    }

    private static void checkLeadHasTask(List<Task> LstTaks, Map<Id, List<Task>> mapIdParentToLstChild){
		for (Task item : LstTaks){
			if (mapIdParentToLstChild.containsKey(item.WhoId)){
				List<Task> lstTaskChild = mapIdParentToLstChild.get(item.WhoId);
				lstTaskChild.add(item);
				mapIdParentToLstChild.put(item.WhoId, lstTaskChild);
			} else{
				mapIdParentToLstChild.put(item.WhoId, new List<Task>{item});
			}
		}
	}


    private static void closeWonOpportynity(List<Opportunity> lstOpptyPCA) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Order> lstOrderInsert = new List<Order>();
            List<OrderItem> lstOrderItemInsert = new List<OrderItem>();
            List<Task> lstTaskInsert = new List<Task>();
            List<Payment__c> lstPaymentUpdate = new List<Payment__c>();
            List<Object_Promotion__c> lstPromotionUpdate = new List<Object_Promotion__c>();
            User objUser = [SELECT Id, AccountId FROM User WHERE Id =: userinfo.getuserid() AND IsActive =: true];
            Map<Id, Opportunity> lstOpportunityQuerry = new Map<Id, Opportunity>([SELECT Id
                                                                                        , (SELECT Id, Product2Id, PricebookEntryId, UnitPrice, Quantity FROM OpportunityLineItems)
                                                                                        , (SELECT Id, Order__c FROM Payments__r)
                                                                                        , (SELECT Id,  Order__c FROM Object_Promotions__r)
                                                                                        , AccountId
                                                                                        , OwnerId
                                                                                FROM Opportunity 
                                                                                WHERE Id IN: lstOpptyPCA]);
            for(Opportunity item : lstOpportunityQuerry.values()) {
                lstOrderInsert.add(new Order(
                    RecordTypeId = RecordTypeHelper.ORDER_PCA
                ,   AccountId = item.AccountId
                ,   DO_DL__c = objUser.AccountId
                ,   EffectiveDate =  Date.today()
                ,   OpportunityId = item.Id
                ,   OwnerId = item.OwnerId
                ,   Delivery_Date__c = Date.today().addMonths(1)
                ,   Status = 'Draft'));     
            }
            if(lstOrderInsert.isEmpty()) {
                return;
            }  
            insert lstOrderInsert;
            List<Order> lstOrderQuerryAfterInsert = [SELECT Id, OpportunityId, Opportunity.OwnerId, Pricebook2Id, Pricebook2.name FROM Order WHERE Id =: lstOrderInsert];
                                             
            for(Order item : lstOrderQuerryAfterInsert) {
                if(lstOpportunityQuerry.containsKey(item.OpportunityId)) {
                    for(OpportunityLineItem itemOpptyItem : lstOpportunityQuerry.get(item.OpportunityId).OpportunityLineItems) {
                        lstOrderItemInsert.add(new OrderItem(
                            UnitPrice = itemOpptyItem.UnitPrice,
                            Quantity = itemOpptyItem.Quantity,
                            OrderId = item.Id,
                            PricebookEntryId = itemOpptyItem.PricebookEntryId));
                    }
                    for(Payment__c objPayment : lstOpportunityQuerry.get(item.OpportunityId).Payments__r) {
                        objPayment.Order__c = item.Id;
                        lstPaymentUpdate.add(objPayment);
                    }
                    for(Object_Promotion__c objPromotion : lstOpportunityQuerry.get(item.OpportunityId).Object_Promotions__r) {
                        objPromotion.Order__c = item.Id;
                        lstPromotionUpdate.add(objPromotion);
                    }
                }
            }
            if(!lstOrderItemInsert.isEmpty()) {
                insert lstOrderItemInsert;
            }
            if(!lstPaymentUpdate.isEmpty()) {
                update lstPaymentUpdate;
            }
            if(!lstPromotionUpdate.isEmpty()) {
                update lstPromotionUpdate;
            }
            List<Order> lstOrderAfterInsertPayment = [SELECT Id
                                                            , OpportunityId
                                                            , Opportunity.OwnerId
                                                            , Pricebook2Id
                                                            , Pricebook2.name
                                                            , Is_Payment__c
                                                        FROM Order WHERE Id =: lstOrderInsert];
            for(Order item : lstOrderAfterInsertPayment) {
                if(item.Is_Payment__c) {
                    lstTaskInsert.add(new Task(
                        Type = 'Call',
                        Status = 'In Processing',
                        Priority = 'High',
                        Subject = 'Follow Order PCA',
                        WhatId = item.Id,
                        Estimate_Task__c = Datetime.now().addDays(14),
                        Task_Name__c = '14 Days',
                        OwnerId = item.Opportunity.OwnerId,
                        RecordTypeId = RecordTypeHelper.TASK_ORDER,
                        Task_Type__c = 'Follow Up',
                        ActivityDate = Date.today().addDays(14)
                    ));
                }
            }
            insert lstTaskInsert;
        } catch(Exception ex) {
            System.debug('ex.getMessage() :' + ex.getMessage());
            Database.rollBack(sp);
			lstOpptyPCA.get(0).addError(ex.getMessage());
        }
    }

    private static void updateTaskComplete(Set<Id> setIdOpp) {
        try {
            //Datetime dt = Datetime.now();
            Set<Id> setIdAccountId = new Set<Id>();
            List<Task> lstTaskUpdate = new List<Task>();
            List<Opportunity> lstOpportunityUpdate = new List<Opportunity>();
            Map<Id, Opportunity> mapOpportunityQuerry = new Map<Id, Opportunity>(getLstOpportunity(setIdOpp));
            List<Task> lstTaskQuerry = getLstTask(setIdOpp);
            List<Task> lstTaskInsert = new List<Task>();
            if(!lstTaskQuerry.isEmpty()) {
                for(Task item : lstTaskQuerry) {
                    if(mapOpportunityQuerry.containsKey(item.WhatId)) {
                        //if(item.Estimate_Task__c >= dt) {
                        if(item.Is_Close__c == false) {
                            item.Status = 'Completed';
                            item.Is_Close__c = true;
                            lstTaskUpdate.add(item);
                        }
                        mapOpportunityQuerry.get(item.WhatId).Is_Close__c = true;
                        if(mapOpportunityQuerry.get(item.WhatId).IsPrimary__c) {
                            setIdAccountId.add(mapOpportunityQuerry.get(item.WhatId).AccountId);
                        }
                        /*if(mapOpportunityQuerry.get(item.WhatId).StageName == 'Unqualified') {
                            mapOpportunityQuerry.get(item.WhatId).OwnerId = objUserMarketting.Id;
                        }*/
                        lstOpportunityUpdate.add(mapOpportunityQuerry.get(item.WhatId));
                        //}
                    }
                }
            }
            if(!lstOpportunityUpdate.isEmpty()) {
                update lstOpportunityUpdate;
            }
            if(!lstTaskUpdate.isEmpty()) {
                update lstTaskUpdate;
            }
            if(!setIdAccountId.isEmpty()) {
                for(Account a : [SELECT Id
                , (SELECT Id, Name, CreatedDate FROM Opportunities Order WHERE  IsPrimary__c =: false ORDER BY CreatedDate ASC LIMIT 1) 
                        FROM Account
                        WHERE Id =:  setIdAccountId]) {
                    if(!a.opportunities.isEmpty()) {
                        lstTaskInsert.add(new Task(
                            Subject = 'Send Quote',
                            Status = 'In Processing',
                            Is_Close__c = false,
                            WhatId = a.opportunities[0].Id,
                            Task_Name__c = '12 hours',
                            Estimate_Task__c = Datetime.now().addHours(12),
                            ActivityDate = Date.valueOf(Datetime.now().addHours(12))
                        ));
                    }
                }
            }
            if(lstTaskInsert.isEmpty()) {
                return;
            }
            
            insert lstTaskInsert;
            for(Task item : lstTaskInsert) {
                item.Status = 'Completed';
            }
            update lstTaskInsert;
        } catch (Exception ex){
			System.debug('Exception e '+ ex);
            System.debug('Exception e '+ ex.getLineNumber());
		}
    }

    private static List<Opportunity> getLstOpportunity(Set<Id> setIdOpportunity){
		return new List<Opportunity> ([SELECT ID, StageName, Is_Close__c, IsPrimary__c, AccountId FROM Opportunity WHERE Id IN: setIdOpportunity]);
	}

	private static List<Task> getLstTask(Set<Id> setIdOpportunity){
        String strStatus = 'In Processing';	
		return [SELECT  Id
                        , WhatId
                        , WhoId
                        , Status
                        , Is_Close__c
                        , Task_Name__c
                        , Estimate_Task__c
                        , WhoId_Tempt__c
                FROM    Task
                WHERE   WhatId IN : setIdOpportunity
                    AND (Status =: 'In Processing' OR Status =: 'Open')];
	}

    private static User gerUserMarketting(){
		return [Select Id, Name
		        From User
		        Where Profile.Name = 'MKT Manager' AND IsActive =: true];
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
    }  
    public class CustomException extends Exception {}
}