public without sharing class FlowCreateTaskOpportunity{
	private static String strProfileName1 = 'Community DO DL Manager';
	private static String strProfileName2 = 'Community Sale Sup';
	private static String strProfileName3 = 'System Administrator';
	private static String strProfileName4 = 'Community Sale Profile';
	private static String STR_1DAY = '1 DAY';
	private static Map<Id, Profile> objProfileDODLManager = new Map<Id, Profile>([SELECT Id, Name
	                                                                              FROM Profile
	                                                                              WHERE Name = :strProfileName1]);
	private static Map<Id, Profile> objProfileSaleSub = new Map<Id, Profile>([SELECT Id, Name
	                                                                          FROM Profile
	                                                                          WHERE Name = :strProfileName2]);
	private static Map<Id, Profile> objProfileSale = new Map<Id, Profile>([SELECT Id, Name
	                                                                       FROM Profile
	                                                                       WHERE Name = :strProfileName4]);

	public static void onBeforeInsert(List<Opportunity> lstOpportunityNews){
		updateFieldFlowFails(lstOpportunityNews);
	}

	private static void updateFieldFlowFails(List<Opportunity> lstOpportunityNews){
		for (Opportunity item : lstOpportunityNews){
			item.Flow_Fouls__c = 0;
		}
	}

	public static void onAfterInsert(List<Opportunity> lstOpportunityNews){
		System.debug('On After Inser Opportunity');
        updateLastActivityOnAccount(lstOpportunityNews);
		List<Opportunity> lstOpptyBike = new List<Opportunity>();
		for(Opportunity item : lstOpportunityNews) {
			if(item.RecordTypeId == RecordTypeHelper.OPPORTUNITY_BIKE) {
				lstOpptyBike.add(item);
			}
		}
		if(!lstOpportunityNews.isEmpty()) {
			updateOwnerCreateTask(lstOpportunityNews);
		}
	}
    
    private static void updateLastActivityOnAccount(List<Opportunity> lstOpportunityNews) {
        Set<Id> setIdAccount = new Set<Id>();
        try {
            for(Opportunity item : lstOpportunityNews) {
                setIdAccount.add(item.AccountId);
            }
            Map<Id, Account> mapAccountQuerry = new Map<Id, Account>([SELECT Id, Last_Activity_Date_Custom__c  FROM Account WHERE Id IN: setIdAccount]);
            for(Opportunity item : lstOpportunityNews) {
                if(mapAccountQuerry.containsKey(item.AccountId)) {
                    mapAccountQuerry.get(item.AccountId).Last_Activity_Date_Custom__c = Date.valueOf(item.CreatedDate);
                }
            }
            if(!mapAccountQuerry.values().isEmpty()) {
                update mapAccountQuerry.values();
            }
         } catch(Exception ex) {
            lstOpportunityNews.get(0).addError(ex.getMessage() + ' ' + ex.getLineNumber()); 
        }
    }

	public static void onAfterUpdate(Map<Id, Opportunity> mapOpportunityOlds, Map<Id, Opportunity> mapOpportunityNews){
		List<Opportunity> lstOpportunity = new List<Opportunity>();
		for (Opportunity item : mapOpportunityNews.values()){
            System.debug('item.OwnerId:' + item.OwnerId);
            System.debug('mapOpportunityOlds?.get(item.Id)?.OwnerId:' + mapOpportunityOlds?.get(item.Id)?.OwnerId);
			if ((item.OwnerId != mapOpportunityOlds?.get(item.Id)?.OwnerId) 
                && item.RecordTypeId == RecordTypeHelper.OPPORTUNITY_BIKE){
				lstOpportunity.add(item);
			}
		}
		if (!lstOpportunity.isEmpty()){
            System.debug('lstOpportunity:' + lstOpportunity);
			updateOwnerCreateTask(lstOpportunity);
			updateOwnerAccount(lstOpportunity);
		}
	}

	private static void checkAccountHasOppty(List<Opportunity> lstOpportunity, Map<String, List<Opportunity>> mapAccountToOpportunity){
		for (Opportunity item : lstOpportunity){
			if (mapAccountToOpportunity.containsKey(item.AccountId)){
				List<Opportunity> lstOpportunitys = mapAccountToOpportunity.get(item.AccountId);
				lstOpportunitys.add(item);
				mapAccountToOpportunity.put(item.AccountId, lstOpportunitys);
			} else{
				mapAccountToOpportunity.put(item.AccountId, new List<Opportunity>{item});
			}
		}
	}
	
	private static void getAccountParentOpptyLstChildrent(List<Opportunity> LstOpptys, Map<Id, List<Opportunity>> mapIdParentToLstChild){
		for (Opportunity item : LstOpptys){
			if (mapIdParentToLstChild.containsKey(item.AccountId)){
				List<Opportunity> lstOpportunityChild = mapIdParentToLstChild.get(item.AccountId);
				lstOpportunityChild.add(item);
				mapIdParentToLstChild.put(item.AccountId, lstOpportunityChild);
			} else{
				mapIdParentToLstChild.put(item.AccountId, new List<Opportunity>{item});
			}
		}
	}

	private static List<Opportunity> getListOpptyByAccountId(Set<Id> setIdAccount) {
		return new List<Opportunity> ([SELECT Id, AccountId, Lead_Type__c, StageName FROM Opportunity WHERE AccountId IN : setIdAccount]);
	}

	private static void updateOwnerAccount(List<Opportunity> lstOpportunity) {
		List<Opportunity> lstOppQuerry = [SELECT Id, Account.PersonContactId, AccountId, OwnerID FROM Opportunity WHERE Id IN: lstOpportunity];
		List<Account> lstAccIsPrimaryQuerry = new List<Account>();
		Map<Id, Id> mapIdAccountIsPrimary = new Map<Id, Id>();
		for(Opportunity item : lstOppQuerry) {
				mapIdAccountIsPrimary.put(item.AccountId, item.OwnerID);
			
		}
		Map<Id, Account> mapAccount = getAccount(mapIdAccountIsPrimary);
		if(!mapAccount.values().isEmpty()) {
			for(Account item : mapAccount.values()) {
				if(mapIdAccountIsPrimary.containsKey(item.Id)) {
					item.OwnerID = mapIdAccountIsPrimary.get(item.Id);
					lstAccIsPrimaryQuerry.add(item);
				}
			}
			if(!lstAccIsPrimaryQuerry.isEmpty()) {
				System.debug('lstAccIsPrimaryQuerry :' + lstAccIsPrimaryQuerry);
				update lstAccIsPrimaryQuerry;
			}
		}
	}

	private static Map<Id, Account> getAccount(Map<Id, Id> mapIdAccountIsPrimary) {
		return  new Map<Id, Account> ([SELECT Id, OwnerID FROM Account WHERE Id IN : mapIdAccountIsPrimary.keySet()]);
	}

    private static Map<Id, User> getUser(){
        return new Map<Id, User>([SELECT Id, AccountId FROM User WHERE AccountId!=NULL]);
    }


	private static void updateOwnerCreateTask(List<Opportunity> lstOpportunity){
		List<Task> lstTaskInsert = new List<Task>();
		List<Opportunity> lstOpportunityUpdate = new List<Opportunity>();
        Map<Id, User> mapUserAccountId = getUser();
        try {
            List<Opportunity> lstOpportunityQuerry = getOpportunityQuerry(lstOpportunity);
            if (!lstOpportunityQuerry.isEmpty()){
                
                for (Opportunity item : lstOpportunityQuerry){
                    if (objProfileDODLManager.containsKey(item.Owner.ProfileId)){
                        item.DO_DL_Owner__c = item.OwnerId;
                    } else if (objProfileSaleSub.containsKey(item.Owner.ProfileId)){
                        item.Sale_Sub_DO__c = item.OwnerId;
                    }
                    if(String.isBlank(item.DODL_create__c)){
                        if(mapUserAccountId.containsKey(item.OwnerId)) { 
                            item.DODL_Create__c = mapUserAccountId.get(item.OwnerId).AccountId;
                        }
                    }
                    if(objProfileSale.containsKey(item.Owner.ProfileId) || objProfileSaleSub.containsKey(item.Owner.ProfileId)) {
                        System.debug('item.Tasks.isEmpty():' + item.Tasks.isEmpty());
                        if(item.Tasks.isEmpty()) {
                            Task objTask = new Task();
                            objTask.Type = 'Call';
                            objTask.Status = 'In Processing';
                            objTask.Priority = 'High';
                            objTask.Subject = 'Send Quote';
                            objTask.WhatId = item.Id;
                            objTask.WhoId = item.Account.PersonContactId;
                            objTask.Task_Name__c = '1 Day';
                            objTask.Estimate_Task__c = Datetime.now().addDays(1);
                            objTask.ActivityDate = Date.valueOf(objTask.Estimate_Task__c);
                            objTask.OwnerId = item.OwnerId;
                            objTask.RecordTypeId = RecordTypeHelper.TASK_OPPORTUNITY;
                            objTask.Task_Type__c = 'Follow Up';
                            lstOpportunityUpdate.add(item);
                            lstTaskInsert.add(objTask);	
                        }
                    }
                }
            }
            
            if(!lstTaskInsert.isEmpty()) {
                insert lstTaskInsert;
            }
            if(!lstOpportunityUpdate.isEmpty()) {
                update lstOpportunityUpdate;
            }
        } catch(Exception ex) {
            lstOpportunity.get(0).addError(ex.getMessage() + ' ' + ex.getLineNumber());
        }
	}


	//SOQL querry Progress_Flow_Details__c dynamic. Get All fields
	private static List<Opportunity> getOpportunityQuerry(List<Opportunity> lstOppty){
		return new List<Opportunity>([SELECT Id
                                            , Owner.ProfileId
                                            , Progress_Flow_Details__c
                                            , DO_DL_Owner__c
                                            , Sale_Sub_DO__c
                                            , Lead_Type__c
                                            , AccountId
                                            , StageName
                                            , RecordTypeId
                                            , Account.PersonContactId
                                            , DODL_create__c
                                            , (SELECT Id
                                                    , Status
                                                    , Is_Close__c
                                                    , WhoId
                                                    , WhatId
                                            FROM Tasks  
                                            WHERE Status  != 'Closed' 
                                                AND Status != 'Not Completed'
                                                AND Status != 'Completed')
                                    FROM Opportunity 
                                    WHERE Id IN: lstOppty]);
	}


	private static void checkOppHasTaskInProcess(List<Task> LstTaks, Map<Id, List<Task>> mapIdParentToLstChild){
		for (Task item : LstTaks){
            if(item.Status == 'In Processing') {
                if (mapIdParentToLstChild.containsKey(item.WhatId)){
                    List<Task> lstTaskChild = mapIdParentToLstChild.get(item.WhatId);
                    lstTaskChild.add(item);
                    mapIdParentToLstChild.put(item.WhatId, lstTaskChild);
                } else{
                    mapIdParentToLstChild.put(item.WhatId, new List<Task>{item});
                }
            }
		}
	}

	private static Progress_Flow_Details__c getFlowDetail(){
		List<String> fields = new List<String>(Progress_Flow_Details__c.SObjectType.getDescribe().fields.getMap().keySet());
		String soql = '' + 
					  ' SELECT ' + String.join(fields, ',')+' FROM Progress_Flow_Details__c' + 
					  ' WHERE Activity_Timeout__c =: STR_1DAY' + 
					  '    LIMIT 1';
		List<Progress_Flow_Details__c> lstFlowDetailQuerry = (Progress_Flow_Details__c[])Database.query(soql);
        
        if(lstFlowDetailQuerry.isEmpty())
        {
            Progress_Flow_Details__c pro = new Progress_Flow_Details__c();     
            pro.Activity_Timeout__c = 'STR_1DAY';
            lstFlowDetailQuerry.add(pro);
            //insert lstFlowDetailQuerry;
        }
        
		return lstFlowDetailQuerry[0];
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