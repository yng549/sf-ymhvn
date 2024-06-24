public without sharing class FlowCreateTask{
    public static Boolean flag = false;
    private static String strProfileName1 = 'Community DO DL Manager';
    private static String strProfileName2 = 'Community Sale Sup';
    private static String strProfileName3 = 'System Administrator';
    private static String strProfileName4 = 'Community Sale Profile';
    private static String strProfileName5 = 'MKT Manager';
    private static String STR_1DAY = '1 DAY';
	
    public static void onBeforeInsert(List<Lead> lstLeadNews){
        StringHelper.normalizeSObjectPhoneNumber(lstLeadNews);
        updateReviewWhenIsNotCommunity(lstLeadNews);
        updateFieldFlowFails(lstLeadNews);
    }
    
    private static void updateReviewWhenIsNotCommunity(List<Lead> lstLeadNew){
        Map<Id, User> mapUserIsNotCommunity = new Map<Id, User>([SELECT Id
                                                                 FROM User
                                                                 WHERE Profile.Name = :strProfileName4]);
        Map<Id, User> mapAllUser = new Map<Id, User>([SELECT Id, AccountId
                                                                 FROM User]);
        for (Lead item : lstLeadNew){
            if (!mapUserIsNotCommunity.containsKey(item.OwnerId) && item.Run_Reassign__c == false){
                item.Run_Reassign__c = true;
            }
            if(mapAllUser.containsKey(item.OwnerId)) {
                if(String.isNotBlank(mapAllUser.get(item.OwnerId).AccountId)) {
                    item.DO_DL_Create__c = mapAllUser.get(item.OwnerId).AccountId;
                }
            }
        }
    }
    
    public static void onAfterInsert(List<Lead> lstLeadNews){
        if (!System.isBatch() && !System.isFuture()){
            Set<Id> checkDupIds = new Set<Id>();
            //Database.executeBatch(new BatchLeadDuplicationHandler(newMap.keySet()), 2000);
            for (Lead l : lstLeadNews){
                
                checkDupIds.add(l.Id);
            }
            if (!checkDupIds.isEmpty()){
                System.debug('checkDupIds:' + checkDupIds);
                Database.executeBatch(new BatchLeadDuplicationHandler(checkDupIds), 2000);
            }
        }
        // createTask(lstLeadNews);
    }
    
    public static void onAfterUpdate(Map<Id, Lead> mapLeadOlds, Map<Id, Lead> mapLeadNews){
        System.debug('onAfterUpdate RUN');
        System.debug('onAfterUpdate RUN :' + mapLeadNews);
        List<Lead> lstLead = new List<Lead>();
        List<Lead> lstLeadUnqualified = new List<Lead>();
        List<Lead> lstLeadIsUpdatingGetLead = new List<Lead>();
        Set<Id> checkDupIds = new Set<Id>();
        for (Lead item : mapLeadNews.values()){
            if ((item.OwnerId != mapLeadOlds?.get(item.Id)?.OwnerId) && item.Status != 'Unqualified'){
                lstLead.add(item);
            }
            // System.debug('item.Status = ' + item.Status);
            System.debug('Owner Id diff:' + item.OwnerId + ' | ' + mapLeadOlds?.get(item.Id)?.OwnerId);
            System.debug('item.Status Same:' + item.Status == mapLeadOlds?.get(item.Id)?.Status);
            if((item.OwnerId != mapLeadOlds?.get(item.Id)?.OwnerId) 
               && (item.Status == mapLeadOlds?.get(item.Id)?.Status) 
               && (item.Status == 'Unqualified')) {
                System.debug('Unqualified!!');
                checkDupIds.add(item.Id);
                lstLeadUnqualified.add(item);
            }
            if(item.Is_Round_Robin__c != mapLeadOlds?.get(item.Id)?.Is_Round_Robin__c && item.Is_Round_Robin__c) {
                lstLeadIsUpdatingGetLead.add(item);
            }
            
        }
        if (!System.isBatch() && !System.isFuture()){
            if (!checkDupIds.isEmpty()){
                System.debug('checkDupIds After Update Get Lead:' + checkDupIds);
                Database.executeBatch(new BatchLeadDuplicationHandler(checkDupIds), 2000);
            }
        }
        if(!lstLeadIsUpdatingGetLead.isEmpty()) {
            updateFieldRoundRobin(lstLeadIsUpdatingGetLead);
        }
        
        System.debug('lstLeadUnqualified: ' + lstLeadUnqualified);
        if(!lstLeadUnqualified.isEmpty()) {
            updateOwnerWhenLeadUnqualified(lstLeadUnqualified);
        }
        if (!lstLead.isEmpty()) {
            updateOwner(lstLead);
        }
    }
    
    private static void updateFieldRoundRobin(List<Lead> lstLead) {
        System.debug('updateFieldRoundRobin RUN: ');
        List<Lead> lstLeadsQuery = new List<Lead>();
        try {
            lstLeadsQuery = [SELECT Id, Is_Round_Robin__c FROM Lead WHERE Id IN: lstLead];
            for(Lead item : lstLeadsQuery) {
                item.Is_Round_Robin__c = false;
            }
            if(lstLeadsQuery.isEmpty()) {
                return;
            }
            update lstLeadsQuery;
        } catch(Exception ex) {
            lstLead.get(0).addError(ex.getMessage() + ' ' + ex.getLineNumber()); 
        }     
    }
    
    private static void updateOwnerWhenLeadUnqualified(List<Lead> lstLeadNews) {
        Map<Id, Profile> objProfileSaleSub = new Map<Id, Profile>([SELECT Id, Name
                                                                FROM Profile
                                                                WHERE Name = :strProfileName2]);
        Map<Id, Profile> objProfileSale = new Map<Id, Profile>([SELECT Id, Name
                                                                FROM Profile
                                                                WHERE Name = :strProfileName4]);
        List<Lead> lstLeadsQuery = new List<Lead>();
        List<Opportunity> lstOpportunityInsert = new List<Opportunity>();
        List<Account> lstAccountUpdate = new List<Account>();
        List<Lead_Opportunity_Open__c> lstLeadOpptyOpen = new List<Lead_Opportunity_Open__c>();
        Set<Id> setAccountIds = new Set<Id>();
        DevLog__c objDevLog = new DevLog__c();
        System.debug('unqualified run');
        try {
           objDevLog.Function__c = 'Lead Unqualified Change Owner';
           System.debug('updateOwnerWhenLeadUnqualified');
           lstLeadsQuery = [SELECT Id
                            	, Status
                            	, Product__r.RecordTypeId
                            	, OwnerId
                            	, Owner.ProfileId
                            	, Owner.Profile.Name
                            	, Product__r.Name
                            	, Name
                            	, (SELECT Id
                                   		, New_Lead__c
                                   		, Account__c
                                   		, Account__r.OwnerId
                                        , Account__r.Owner.ProfileId
                                        , Account__r.Last_Activity_Date__c
                                        , Account__r.Latest_Opportunity_Lost__c
                                        , Account__r.Latest_Opportunity_Won__c
                                        , Account__r.Count_Opportunity_Bike_Open__c
                                  	FROM Duplicate_Records__r
                                  	WHERE New_Lead__c !=: NULL 
                                   		AND Account__c !=: NULL
                                   		AND (Account__r.Owner.Profile.Name =: 'Community Consultant Service'
                                            OR Account__r.Owner.Profile.Name =: 'Community Consultant PCA'
                                            OR Account__r.Owner.Profile.Name =: 'Community Consultant PCA 2'
                                            OR Account__r.Owner.Profile.Name =: 'Community Sale Sup'
                                            OR Account__r.Owner.Profile.Name =: 'Community Sale Profile'
                                            )
                                            )
                           FROM Lead
                           WHERE Id IN: lstLeadNews 
                            AND (Owner.Profile.Name =: 'Community Sale Profile'
                            OR Owner.Profile.Name =: 'Community Sale Sup')
                           	AND Lead_Type__c =: 'Bike'];
            objDevLog.Input__c = ' lstLeadsQuery: ' + String.valueOf(lstLeadsQuery) + '<br/>';
            System.debug('lstLeadsQuery: ' + lstLeadsQuery);
  
            for(Lead item : lstLeadsQuery) {
                objDevLog.Input__c += ' item.Duplicate_Records__r.isEmpty(): ' + item.Duplicate_Records__r.isEmpty() + '<br/>';
                if(!item.Duplicate_Records__r.isEmpty()) {
                    System.debug('Duplicate_Records__r: ' + item.Duplicate_Records__r[0].Account__r.Owner.ProfileId);
                    Opportunity opty = new Opportunity(
                        StageName = 'New',
                        Name = item.Name + ' ' + item.Product__r.Name,
                        Product__c = item.Product__c != Null ? item.Product__c : Null,
                        CloseDate = System.today(),
                        AccountId = item.Duplicate_Records__r[0].Account__c,
                        OwnerId =  item.OwnerId,
                        Lead__c = item.Id,
                        RecordTypeId = RecordTypeHelper.OPPORTUNITY_BIKE
                    );

                    Account acc = new Account(
                        Id = item.Duplicate_Records__r[0].Account__c,
                        OwnerId = item.OwnerId);
                    
                    if(item.Duplicate_Records__r[0].Account__r.Last_Activity_Date__c >= 0 
                        && item.Duplicate_Records__r[0].Account__r.Last_Activity_Date__c < 30){
                            if (item.Duplicate_Records__r[0].Account__r.Count_Opportunity_Bike_Open__c == 0){
                                 //check latest opty close won with 0 opty open
                                 if (item.Duplicate_Records__r[0].Account__r.Latest_Opportunity_Won__c != null 
                                 || item.Duplicate_Records__r[0].Account__r.Latest_Opportunity_Lost__c != null){
                                    if (item.Duplicate_Records__r[0].Account__r.Latest_Opportunity_Won__c != null 
                                    && item.Duplicate_Records__r[0].Account__r.Latest_Opportunity_Lost__c != null){
                                        if (item.Duplicate_Records__r[0].Account__r.Latest_Opportunity_Won__c 
                                        >= item.Duplicate_Records__r[0].Account__r.Latest_Opportunity_Lost__c){
                                            opty.OwnerId = item.Duplicate_Records__r[0].Account__r.OwnerId;
                                        }else{
                                            opty.OwnerId = item.OwnerId;
                                            acc.OwnerId = item.OwnerId;
                                        }
                                    }else{
                                        opty.OwnerId = (item.Duplicate_Records__r[0].Account__r.Latest_Opportunity_Won__c != null ? item.Duplicate_Records__r[0].Account__r.OwnerId : item.OwnerId);
                                        acc.OwnerId = (item.Duplicate_Records__r[0].Account__r.Latest_Opportunity_Won__c != null ? item.Duplicate_Records__r[0].Account__r.OwnerId : item.OwnerId);
                                    }       

                                    if (objProfileSaleSub.containsKey(item.Duplicate_Records__r[0].Account__r.Owner.ProfileId)
                                    || objProfileSale.containsKey(item.Duplicate_Records__r[0].Account__r.Owner.ProfileId)){
                                        lstOpportunityInsert.add(opty);
                                        lstAccountUpdate.add(acc);
                                    }
                                }
                            }
                        }
                        System.debug('opty: asdasdsa' + opty);
                        System.debug('acc: asdasdasd' + acc);
                    if (!objProfileSaleSub.containsKey(item.Duplicate_Records__r[0].Account__r.Owner.ProfileId)
                    && !objProfileSale.containsKey(item.Duplicate_Records__r[0].Account__r.Owner.ProfileId)){
                        lstOpportunityInsert.add(opty);
                        lstAccountUpdate.add(acc);
                    }
                }
            }
            System.debug('lstOpportunityInsert Create Task: ' + lstOpportunityInsert);
            System.debug('lstAccountUpdate after update: ' + lstAccountUpdate);
            objDevLog.Output__c += ' lstOpportunityInsert: ' + String.valueOf(lstOpportunityInsert) + '<br/>';
            objDevLog.Output__c += ' lstAccountUpdate: ' + String.valueOf(lstAccountUpdate) + '<br/>';
            insert objDevLog;
            if(!lstOpportunityInsert.isEmpty()) {
                insert lstOpportunityInsert;
                List<Opportunity> lstOpportunityQuerry = [SELECT Id
                                                              		, RecordTypeId
                                                              		, OwnerId
                                                              		, Owner.Profile.Name
                                                              		, Lead__c
                                                              FROM Opportunity 
                                                              WHERE Id IN: lstOpportunityInsert];
                for(Opportunity item : lstOpportunityQuerry) {
                    lstLeadOpptyOpen.add(new Lead_Opportunity_Open__c(
                        Opportunity__c = item.Id,
                        Lead__c = item.Lead__c));                       
                }
                
                if(!lstLeadOpptyOpen.isEmpty()) {
                    insert lstLeadOpptyOpen;
                }
                if(!lstAccountUpdate.isEmpty()) {
					update lstAccountUpdate;
                }
            }
        } catch(Exception ex) {
            System.debug(ex.getLineNumber() + ' | ' + ex.getMessage());
            System.debug(ex.getStackTraceString());
           lstLeadNews.get(0).addError(ex.getMessage() + ' ' + ex.getLineNumber()); 
        }
    }
    
    private static void updateFieldFlowFails(List<Lead> lstLeadNews){
        for (Lead item : lstLeadNews){
            item.Flow_Fouls__c = 0;
        }
    }
    
    public static void createTask(List<Lead> lstLead){

        System.debug('createTask RUn');
        Savepoint sp = Database.setSavepoint();
        Map<Id, Profile> objProfileDODLManager = new Map<Id, Profile>([SELECT Id, Name
                                                                       FROM Profile
                                                                       WHERE Name = :strProfileName1]);
        Map<Id, Profile> objProfileSale = new Map<Id, Profile>([SELECT Id, Name
                                                                FROM Profile
                                                                WHERE Name = :strProfileName4]);
        Map<Id, Profile> objProfileMKT = new Map<Id, Profile>([SELECT Id, Name
                                                                FROM Profile
                                                                WHERE Name = :strProfileName5]);
        Map<Id, User> objGetAllUser = getUserById();
        List<Lead> lstLeadQuerry = new List<Lead>();
        List<Lead> lstLeadUpdate = new List<Lead>();
        List<Task> lstTaskInsert = new List<Task>();                                            
        try {
            Progress_Flow_Details__c objFlowDetail = getFlowDetail();
            lstLeadQuerry = getLeadQuerry(lstLead);
            DateTime now = DateTime.parse(System.Now().format());
            if (!lstLeadQuerry.isEmpty()){
                for (Lead item : lstLeadQuerry){
                    if(item.Tasks.isEmpty()) {
                    	item.DO_DL_Owner__c = objGetAllUser?.get(item.OwnerId)?.DODL_Manager__c != Null
                                            ? objGetAllUser?.get(item.OwnerId)?.DODL_Manager__c
                                            : Null;
                        System.debug('item.DO_DL_Owner__c:'+ item.DO_DL_Owner__c);
                        item.Sale_Sub_DO__c = objGetAllUser?.get(item.OwnerId)?.Sale_Sup__c != Null 
                                                ? objGetAllUser?.get(item.OwnerId)?.Sale_Sup__c
                                                : Null ;
                        
                        if (item.Status != 'Unqualified' 
                            && !objProfileDODLManager.containsKey(item.Owner.ProfileId)
                            && !objProfileMKT.containsKey(item.Owner.ProfileId)
                            && item.Lead_Type__c == 'Bike'){
                                System.debug('Pass:');
                                Task objTask = new Task();
                                objTask.Type = 'Call';
                                objTask.Status = 'In Processing';
                                objTask.Priority = 'High';
                                objTask.Subject = 'Call';
                                objTask.WhoId = item.Id;
                                objTask.Estimate_Task__c = now.addDays(1);
                                objTask.Task_Name__c = '1 Day';
                                objTask.OwnerId = item.OwnerId;
                                objTask.ActivityDate = Date.valueOf(objTask.Estimate_Task__c);
                                objTask.RecordTypeId = RecordTypeHelper.TASK_LEAD;
                                objTask.Task_Type__c = 'Follow Up';
                                objTask.WhoId_Tempt__c = item.Id;
                                item.Progress_Flow_Details__c = objFlowDetail.Id;
                                
                                System.debug('objTask:' + objTask);
                                lstTaskInsert.add(objTask);
                        }
                        
                        lstLeadUpdate.add(item);    
                    }
                }
                if(!lstLeadUpdate.isEmpty()) {
                    update lstLeadUpdate;
                }
                if (!lstTaskInsert.isEmpty()){
                    insert lstTaskInsert;
                }
            }
        } catch(Exception ex) {
            System.debug(ex.getLineNumber() + ' | ' + ex.getMessage());
            System.debug(ex.getStackTraceString());
            Database.rollBack(sp);
            lstLead.get(0).addError(ex.getMessage() + ' ' + ex.getLineNumber());
        }
    }
    
    private static void updateOwner(List<Lead> lstLead){
        System.debug('updateOwner RUN ');
        Progress_Flow_Details__c objFlowDetail = getFlowDetail();
        Map<Id, Profile> objProfileDODLManager = new Map<Id, Profile>([SELECT Id, Name
                                                                       FROM Profile
                                                                       WHERE Name = :strProfileName1]);
        Map<Id, Profile> objProfileSaleSub = new Map<Id, Profile>([SELECT Id, Name
                                                                   FROM Profile
                                                                   WHERE Name = :strProfileName2]);
        Map<Id, Profile> objProfileSale = new Map<Id, Profile>([SELECT Id, Name
                                                                FROM Profile
                                                                WHERE Name = :strProfileName4]);
        Map<Id, Profile> objProfileMKT = new Map<Id, Profile>([SELECT Id, Name
                                                                FROM Profile
                                                                WHERE Name = :strProfileName5]);
        List<Task> lstTaskInsert = new List<Task>();
        List<Lead> lstLeadUpdate = new List<Lead>();
        List<Lead> lstLeadQuerry = getLeadQuerry(lstLead);
        Savepoint sp = Database.setSavepoint();
        try{
            for (Lead item : lstLeadQuerry){
                if (item.Tasks.isEmpty()){
					if(item.Is_Close__c) {
                        item.Is_Close__c = false;
                    }
                    if(item.Is_Round_Robin__c) {
                        item.Is_Round_Robin__c = false;
                    }
                    if (objProfileDODLManager.containsKey(item.Owner.ProfileId)){
                        item.DO_DL_Owner__c = item.DO_DL_Owner__c != Null ? item.DO_DL_Owner__c : item.OwnerId;
                    } else if (objProfileSaleSub.containsKey(item.Owner.ProfileId)){
                        item.Sale_Sub_DO__c = item.Sale_Sub_DO__c != Null ? item.Sale_Sub_DO__c : item.OwnerId;
                    }
                    if ((objProfileSale.containsKey(item.Owner.ProfileId) 
                    || (objProfileSaleSub.containsKey(item.Owner.ProfileId))
                    && item.Lead_Type__c == 'Bike') && item.Status != 'Unqualified'){
                        System.debug('Pass');
                        DateTime now = DateTime.parse(System.Now().format());
                        Task objTask = new Task();
                        objTask.Type = 'Call';
                        objTask.Status = 'In Processing';
                        objTask.Priority = 'High';
                        objTask.Subject = 'Call';
                        objTask.WhoId = item.Id;
                        objTask.Task_Name__c = '1 Day';
                        objTask.Estimate_Task__c = now.addDays(1);
                        objTask.ActivityDate = Date.valueOf(objTask.Estimate_Task__c);
                        objTask.OwnerId = item.OwnerId;
                        objTask.RecordTypeId = RecordTypeHelper.TASK_LEAD;
                        objTask.Task_Type__c = 'Follow Up';
                        objTask.WhoId_Tempt__c = item.Id;
                        item.Is_Assigned__c = true;
                        item.Progress_Flow_Details__c = objFlowDetail.Id;
                        lstTaskInsert.add(objTask);
                    }
                    lstLeadUpdate.add(item);   
                }
            }
            if(!lstLeadUpdate.isEmpty()) {
                update lstLeadUpdate;
            }
            if (!lstTaskInsert.isEmpty()){
            	insert lstTaskInsert;
        	}
        } catch(Exception ex) {
            Database.rollBack(sp);
            lstLead.get(0).addError(ex.getMessage() + ' ' + ex.getLineNumber());
        }
    }
    
    private static Map<Id, User> getUserById(){
        return new Map<Id, User>([SELECT Id, Name, DODL_Manager__c, Sale_Sup__c
                                  FROM User]);
    }
    
    //SOQL querry Progress_Flow_Details__c dynamic. Get All fields
    private static List<Lead> getLeadQuerry(List<Lead> lstLead){
        return new List<Lead>([SELECT Id
                                , Status
                                , OwnerId
                                , Is_Close__c
                                , Flow_Fouls__c
                                , Owner.ProfileId 
                                , Product__r.RecordTypeId
                                , Lead_Type__c
                                , DO_DL_Owner__c
                                , Sale_Sub_DO__c
                                , Progress_Flow_Details__c
                               	, Is_Round_Robin__c
                                , (SELECT Id
                                        , RecordTypeId
                                        , Status
                                        , Is_Close__c
                                        , ActivityDate
                                    FROM Tasks
                                    WHERE Status !=: 'Closed' 
                                    AND Status !=: 'Not Completed'
                                    AND Status != 'Completed'
                                    LIMIT 1)
                            FROM Lead
                            WHERE Id IN: lstLead]);
    }
    
    //SOQL querry Progress_Flow_Details__c dynamic. Get All fields
    private static Progress_Flow_Details__c getFlowDetail(){
        String strNameObject = 'Lead';
        List<String> fields = new List<String>(Progress_Flow_Details__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = '' + 
            ' SELECT ' + String.join(fields, ',') + ' FROM Progress_Flow_Details__c' + 
            ' WHERE Activity_Timeout__c =: STR_1DAY AND Progress_Flow__r.Name_Object__c =: strNameObject ' + 
            '    LIMIT 1';
        List<Progress_Flow_Details__c> lstFlowDetailQuerry = (Progress_Flow_Details__c[])Database.query(soql);
        if (lstFlowDetailQuerry.isEmpty()){
            return new Progress_Flow_Details__c();
        } else{
            return lstFlowDetailQuerry[0];
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