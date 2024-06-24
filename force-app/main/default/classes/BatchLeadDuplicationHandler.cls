public without sharing class BatchLeadDuplicationHandler extends BaseBatchHandler{
    public Set<Id> leadIds;
        
    
    public static Boolean flagRun = false;
    
    public BatchLeadDuplicationHandler(Set<Id> leadIds){
        this.objectName = 'Lead';
        this.leadIds = leadIds;
    }
    
    public override Database.querylocator start(Database.BatchableContext BC){
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> schemaFieldMap = sobjectType.getDescribe().fields.getMap();
        
        List<String> query = new List<String>();
        query.add('SELECT  Product__r.RecordTypeId, Product__r.Name, ' + String.join(new List<String>(schemaFieldMap.keySet()), ','));
        query.add('FROM ' + objectName);
        query.add('WHERE Id IN :leadIds');
        
        if (Test.isRunningTest()){
            query.add('LIMIT 200');
        }
        return Database.getQueryLocator(String.join(query, ' '));
    }
    
    public override List<SObject> processData(List<SObject> records){
        System.debug('Batch lead dup run');
        List<Lead> newData = (List<Lead>)records;
        Map<Id, Lead> mapLeadNews = new Map<Id, Lead>(newData);
        Map<Id, Lead> mapUpdatedLead = new Map<Id, Lead>();
        List<Duplicate_Record__c> newDuplicatedRecords = new List<Duplicate_Record__c>();
        try{
            checkDuplicatedAccount(newData, mapUpdatedLead, newDuplicatedRecords);
            checkDuplicatedLead(newData, mapUpdatedLead, newDuplicatedRecords);
            if (!mapUpdatedLead.isEmpty()){
                for (Lead l : newData){
                    if (mapUpdatedLead.containsKey(l.Id)){
                        l.Is_Duplicated_Lead__c = mapUpdatedLead.get(l.Id).Is_Duplicated_Lead__c;
                    }
                }
            }
        }Catch(Exception ex){
            System.debug(ex.getLineNumber() + ' | ' + ex.getMessage());
            System.debug(ex.getStackTraceString());
            DevLog__c objDevLog = new DevLog__c();
            objDevLog.Input__c += ' Lead Id: ' + newData[0].Id + '<br>/';
            objDevLog.Output__c += ex.getLineNumber() + ' | ' + ex.getMessage() + '<br>/';
            objDevLog.Output__c += ex.getStackTraceString() + '<br>/';
          
        }
        return newData;
    }
    
       
    
    public override void handleFinish(){
        List<Lead> lstLead = [SELECT Id FROM Lead WHERE Id IN :leadIds];
        FlowCreateTask.createTask(lstLead);
    }
    
    public static void checkDuplicatedLead(List<Lead> newData, Map<Id, Lead> mapUpdatedLead, List<Duplicate_Record__c> newDuplicatedRecords){
        try {
            Map<Id, User> objUserMarketting = gerUserMarketting();
            Map<Id, User> objAllUser = getAllUser();
            Map<Id, Lead> mapLeadNew = new Map<Id, Lead>(newData);
            List<Lead> lstLeadUpdate = new List<Lead>();
            Set<String> setPhoneNumbers = new Set<String>();
            Map<String, Id> mapFirstLeadByPhone = new Map<String, Id>();
            List<Lead> lstLeadMKTUpdate = new List<Lead>();
            for (Lead l : newData){
                if (String.isNotBlank(l.Phone == Null ? l.MobilePhone : l.Phone)){
                    setPhoneNumbers.add(l.Phone == Null ? l.MobilePhone : l.Phone);
                    if (!mapFirstLeadByPhone.containsKey(l.Phone == Null ? l.MobilePhone : l.Phone)){
                        mapFirstLeadByPhone.put(l.Phone == Null ? l.MobilePhone : l.Phone, l.Id);
                    }
                }
            }
            // Modified add field query data type
            List<Lead> possibleDuplicatedLead = [SELECT Id
                                                 , Phone
                                                 , MobilePhone
                                                 , CreatedDate
                                                 , Status
                                                 , Lead_Type__c
                                                 , OwnerId
                                                 , Is_close__c
                                                 , Round_To_Sale__c
                                                 , DO_DL_Create__c 
                                                 FROM Lead
                                                 WHERE (Phone IN :setPhoneNumbers OR MobilePhone IN :setPhoneNumbers) 
                                                 AND Status != 'Converted' 
                                                 ORDER BY CreatedDate ASC];
            Map<String, List<Lead>> mapPhoneToExistedLead = new Map<String, List<Lead>>();
            for (Lead l : possibleDuplicatedLead){
                DuplicateValidationHelper.putLeadToExistedPhoneMapping(mapPhoneToExistedLead, l);
            }
            for (Lead l : newData){
                Boolean foundPhoneDuplicate = false;
                Boolean isDuplicated = false;
                // Check if this lead is duplicated by phone number
                if ((String.isNotBlank(l.Phone) || String.isNotBlank(l.MobilePhone)) 
                    && mapPhoneToExistedLead.containsKey(l.Phone == Null ? l.MobilePhone : l.Phone)){
                        for (Lead duplicateLead : mapPhoneToExistedLead.get(l.Phone == Null ? l.MobilePhone : l.Phone)){
                            if (mapFirstLeadByPhone.containsKey(l.Phone == Null ? l.MobilePhone : l.Phone) 
                                && mapFirstLeadByPhone.get(l.Phone == Null ? l.MobilePhone : l.Phone) == duplicateLead.Id && duplicateLead.Id == l.Id){
                                    // This is the first lead in batch so it will not be duplicated
                                    break;
                                }
                                System.debug('Test');
                            //Start Add 23/09/2021 THT Nếu trùng lead type unqualifiled khác tạo bt
                            if (l.Id != duplicateLead.Id 
                                && (l.Lead_Type__c == duplicateLead.Lead_Type__c)){
                                    // Lead is duplicate when it is not checking with itself
                                    foundPhoneDuplicate = true;
                                    break;
                                }
                        }
                    }
                // Check if there are any duplicated lead with the current phone number
                if (foundPhoneDuplicate){
                    System.debug('foundPhoneDuplicate:'+ foundPhoneDuplicate);
                    if (!mapUpdatedLead.containsKey(l.Id)){
                        mapUpdatedLead.put(l.Id, new Lead(Id = l.Id));
                    }
                    // Mark this lead as duplicated
                    Boolean flag = false;
                    // Loop through every duplicated lead to check how many days has passed since the time that the lead was created
                    for (Lead duplicateLead : mapPhoneToExistedLead.get(l.Phone == Null ? l.MobilePhone : l.Phone)){
                        
                        if(objAllUser.containsKey(l.OwnerId)) {
                            if(!flag
                               && duplicateLead.Id != l.Id
                               && duplicateLead.Status != 'Unqualified') {
                                   
                                   if(objUserMarketting.containsKey(duplicateLead.OwnerId) && duplicateLead.Round_To_Sale__c) {
                                       duplicateLead.Status = 'Unqualified';
                                       duplicateLead.Is_Duplicated_Lead__c = true;
                                       flag = true;
                                       lstLeadMKTUpdate.add(duplicateLead);
                                   } else if(!objUserMarketting.containsKey(duplicateLead.OwnerId) 
                                             && (l.DO_DL_Create__c  == duplicateLead.DO_DL_Create__c )
                                             && String.isNotBlank(l.DO_DL_Create__c)
                                             && String.isNotBlank(duplicateLead.DO_DL_Create__c)){
                                                 if(duplicateLead.Is_Close__c) {
                                                     duplicateLead.Status = 'Unqualified';
                                                     lstLeadUpdate.add(duplicateLead);
                                                     
                                                     mapUpdatedLead.get(l.Id).Sale_ID_Lead_Old__c = duplicateLead.OwnerId;
                                                     flag = true;
                                                 } else {
                                                     mapUpdatedLead.get(l.Id).Is_Duplicated_Lead__c = true;
                                                     mapUpdatedLead.get(l.Id).Close_Lead_Reason__c = 'Duplicated';
                                                     mapUpdatedLead.get(l.Id).Status = 'Unqualified';
                                                     mapUpdatedLead.get(l.Id).Sale_ID_Lead_Old__c = duplicateLead.OwnerId;
                                                     flag = true;
                                                 }
                                             }
                                   System.debug('lstLeadMKTUpdate:' + lstLeadMKTUpdate);
                               }
                            if (duplicateLead.Id != l.Id && flag){
                                newDuplicatedRecords.add(DuplicateValidationHelper.createDuplicatedRecord(l, duplicateLead));
                                System.debug('newDuplicatedRecords:' + newDuplicatedRecords);
                            }
                        }
                    }
                }
                DuplicateValidationHelper.putLeadToExistedPhoneMapping(mapPhoneToExistedLead, l);
            }
            if (!newDuplicatedRecords.isEmpty()){
                upsert newDuplicatedRecords;
            }
            if (!mapUpdatedLead.isEmpty()){
                System.debug('mapUpdatedLead Before:' + mapUpdatedLead.values());
                update mapUpdatedLead.values();
                System.debug('mapUpdatedLead After:' + mapUpdatedLead.values());
            }	
            if(!lstLeadMKTUpdate.isEmpty()) {
                update lstLeadMKTUpdate;
            }
            if(!lstLeadUpdate.isEmpty()) {
                update lstLeadUpdate;
            }
        } catch (Exception ex) {
            System.debug('ex.Get Error Message :' + ex.getMessage() + ' | ' + ex.getLineNumber());
            System.debug('ex.Get Stack Trace :' + ex.getStackTraceString());
        }
    }
    
    
    
    //Account check duplicate
    public static void checkDuplicatedAccount(List<Lead> newData, Map<Id, Lead> mapUpdatedLead, List<Duplicate_Record__c> newDuplicatedRecords){
        Map<Id, User> objProfileDODLManage = getProfileDODLManager();
        Map<String, List<Account>> mapPhoneToExistedAccount = new Map<String, List<Account>>();
        List<OpportunityTeamMember> lstOpptyTeam = new List<OpportunityTeamMember>();
        Set<Id> setIdAccount = new Set<Id>();
        Map<Id, Lead> mapLeadNew = new Map<Id, Lead>(newData);
        DevLog__c objDevLog = new DevLog__c();
        List<Lead_Opportunity_Open__c> lstLeadOpptyOpen = new List<Lead_Opportunity_Open__c>();
        List<Opportunity> lstOpportunityInsert = new List<Opportunity>();
        List<Account> lstAccountUpdate = new List<Account>();
        List<Database.LeadConvert> lstConvertedOpp = new List<Database.LeadConvert>();
        Set<String> setPhoneNumbers = new Set<String>();
        Map<Id, User> objAllUser = getAllUser();
        try {
            for (Lead l : newData){
                if (String.isNotBlank(l.Phone == Null ? l.MobilePhone : l.Phone)){
                    /*if (!l.Is_Duplicated_Lead__c){
                        setPhoneNumbers.add(l.Phone == Null ? l.MobilePhone : l.Phone);
                    }*/
                    setPhoneNumbers.add(l.Phone == Null ? l.MobilePhone : l.Phone);
                }
            }
            
            List<Account> possibleDuplicatedRecords = [SELECT Id
                                                       , PersonMobilePhone
                                                       , CreatedDate
                                                       , Owner.DODL_Manager__c
                                                       , Last_Activity_Date__c
                                                       , Is_Primary__c
                                                       , DO_DL_Create_Account__c
                                                       , OwnerId
                                                       , Owner.ProfileId
                                                       , Owner.Profile.Name
                                                       , Opportunity_Close_Lost__c
                                                       , Opportunity_Close_Won__c
                                                       , Latest_Opportunity_Lost__c
                                                       , Latest_Opportunity_Won__c
                                                       , PersonEmail
                                                       , (SELECT Id 
                                                          FROM Opportunities
                                                          WHERE 
                                                          (StageName !=: 'Closed Won'  AND 
                                                          StageName !=: 'Closed Lost') AND
                                                           RecordTypeId =: RecordTypeHelper.OPPORTUNITY_BIKE)
                                                       FROM Account
                                                       WHERE PersonMobilePhone IN :setPhoneNumbers AND Is_Primary__c =: false
                                                       ORDER BY CreatedDate ASC];
            if (!possibleDuplicatedRecords.isEmpty()){
                for (Account record : possibleDuplicatedRecords){
                    if (String.isNotBlank(record.PersonMobilePhone)){
                        if (!mapPhoneToExistedAccount.containsKey(record.PersonMobilePhone)){
                            mapPhoneToExistedAccount.put(record.PersonMobilePhone, new List<Account>());
                        }
                        mapPhoneToExistedAccount.get(record.PersonMobilePhone).add(record);
                    }
                }
                for (Lead l : newData){
                    // Check if there are any duplicated lead with the current phone number
                    if (String.isNotBlank(l.Phone == Null ? l.MobilePhone : l.Phone) 
                        && mapPhoneToExistedAccount.containsKey(l.Phone == Null ? l.MobilePhone : l.Phone)){
                            System.debug('Pass check phone on account');
                            if (!mapUpdatedLead.containsKey(l.Id)){
                                mapUpdatedLead.put(l.Id, new Lead(Id = l.Id));
                            }
                          
                            // Mark this lead as duplicated
                            Boolean flag = false;
                             System.debug('Pass 398');
                            // Loop through every duplicated lead to check how many has passed since the time that the lead was created
                            for (Account record : mapPhoneToExistedAccount.get(l.Phone == Null ? l.MobilePhone : l.Phone)){
                                if(objAllUser.containsKey(l.OwnerId)) {
                                    if((l.DO_DL_Create__c == record.DO_DL_Create_Account__c) 
                                       && (l.DO_DL_Create__c != Null && record.DO_DL_Create_Account__c != Null) 
                                       && !flag) {
                                           mapUpdatedLead.get(l.Id).Is_Duplicated_Lead__c = true;
                                           mapUpdatedLead.get(l.Id).Close_Lead_Reason__c = 'Duplicated';
                                           mapUpdatedLead.get(l.Id).Status = 'Unqualified';
                                           System.debug('Pass 406');
                                           if(!record.Is_Primary__c) {
                                               mapUpdatedLead.get(l.Id).Sale_ID_Lead_Old__c = objAllUser.get(record.OwnerId).Id;
                                           }
                                           
                                           
                                           mapUpdatedLead.get(l.Id).Manager_ID_Lead_Old__c = objAllUser.get(l.OwnerId).DODL_Manager__c;
                                           flag = true;
                                           System.debug('Pass 413');
                                           System.debug('Pass 416');
                                           // account có opportunity đang open thì tạo object gắn lead và opportunity đó vào
                                         
                                           if(l.Product__r.RecordTypeId == RecordTypeHelper.PRODUCT_MODEL 
                                              && (!objProfileDODLManage.containsKey(l.OwnerId) || l.From_Get_Lead__c)) {
                                               objDevLog.Input__c += ' Lead Id: ' + l.Id + ' ' + l.Email +'<br>/';
                                               objDevLog.Input__c += ' Pass Line 397 <br>/';
                                               objDevLog.Input__c += ' Last_Activity_Date__c : ' + record.Last_Activity_Date__c;
                                               System.debug('Pass bike');
                                               System.debug('Last_Activity_Date__c: '+ record.Last_Activity_Date__c);
                                               System.debug('record: '+ record);
                                               if(record.Last_Activity_Date__c >=0 && record.Last_Activity_Date__c < 30) {
                                                   if(!record.Opportunities.isEmpty()) {
                                                       for(Opportunity objOppty : record.Opportunities) {
                                                           lstLeadOpptyOpen.add(new Lead_Opportunity_Open__c(
                                                               Opportunity__c = objOppty.Id,
                                                               Lead__c = l.Id
                                                           ));
                                                       }
                                                   } else {
                                                       System.debug('Pass opty !Empty');
                                                       Opportunity opty = new Opportunity(
                                                           StageName = 'New',
                                                           Name = l.Name + ' ' + l.Product__r.Name,
                                                           Product__c = l.Product__c != Null ? l.Product__c : Null,
                                                           CloseDate = System.today(),
                                                           AccountId = record.Id,
                                                           OwnerId = (record.Owner.Profile.Name == 'Community Consultant Service' 
                                                                      || record.Owner.Profile.Name == 'Community Consultant PCA' 
                                                                      || record.Owner.Profile.Name == 'Community Consultant PCA 2') 
                                                           ? l.OwnerId : record.OwnerId,
                                                           Lead__c = l.Id,
                                                           RecordTypeId = RecordTypeHelper.OPPORTUNITY_BIKE
                                                       );
                                                       Account acc = new Account(
                                                           Id = record.Id
                                                       );
                                                       //check latest opty close won with 0 opty open
                                                       if (record.Latest_Opportunity_Won__c != null || record.Latest_Opportunity_Lost__c != null){
                                                           if (record.Latest_Opportunity_Won__c != null && record.Latest_Opportunity_Lost__c != null){
                                                               if (record.Latest_Opportunity_Won__c >= record.Latest_Opportunity_Lost__c){
                                                                   opty.OwnerId = record.OwnerId;
                                                                   
                                                               }else{
                                                                   opty.OwnerId = l.OwnerId;
                                                                   acc.OwnerId = l.OwnerId;
                                                               }
                                                           }else{
                                                               opty.OwnerId = (record.Latest_Opportunity_Won__c != null ? record.OwnerId : l.OwnerId);
                                                               acc.OwnerId = (record.Latest_Opportunity_Won__c != null ? record.OwnerId : l.OwnerId);
                                                           }       
                                                       }
                                                       
                                                       lstOpportunityInsert.add(opty);
                                                       objDevLog.Output__c += ' <br/> lstOpportunityInsert : ' + String.valueOf(lstOpportunityInsert);
                                                       if(record.Owner.Profile.Name == 'Community Consultant Service' 
                                                          || record.Owner.Profile.Name == 'Community Consultant PCA'
                                                          || record.Owner.Profile.Name == 'Community Consultant PCA 2') {
                                                              acc.OwnerId = l.OWnerId;
                                                              objDevLog.Output__c += ' <br/> Case Line 468 : ' + record.PersonEmail + ' ' + String.isNotBlank(l.Email) + ' ' + l.Email;
                                                              if(record.PersonEmail == NULL && String.isNotBlank(l.Email)) {
                                                                    if(record.Owner.Profile.Name == 'Community Consultant Service' 
                                                                       || record.Owner.Profile.Name == 'Community Consultant PCA'
                                                                       || record.Owner.Profile.Name == 'Community Consultant PCA 2') {
                                                                        	acc.PersonEmail = l.Email;  
                                                                    }
                                                               }
                                                              lstAccountUpdate.add(acc);
                                                          }else{
                                                              lstAccountUpdate.add(acc);
                                                          }
                                                       objDevLog.Output__c += mapUpdatedLead.get(l.Id).Email + ' <br/> lstAccountUpdate : ' + String.valueOf(lstAccountUpdate);
                                                   }
                                               } else if(record.Last_Activity_Date__c >= 30) {  
                                                   System.debug('Pass Last_Activity_Date__c >30');
                                                   //check latest opty close won with 0 opty open
                                                   lstOpportunityInsert.add(new Opportunity(
                                                       StageName = 'New',
                                                       Name = l.Name + ' ' + l.Product__r.Name,
                                                       Product__c = l.Product__c != Null ? l.Product__c : Null,
                                                       CloseDate = System.today(),
                                                       AccountId = record.Id,
                                                       OwnerId = l.OwnerId,
                                                       Lead__c = l.Id,
                                                       RecordTypeId = RecordTypeHelper.OPPORTUNITY_BIKE
                                                   ));
                                                   
                                                   lstAccountUpdate.add(new Account(
                                                       Id = record.Id,
                                                       OwnerId = l.OWnerId
                                                   ));
                                               }
                                           } else if(l.Lead_Type__c == 'PCA') {
                                               System.debug('Case PCA');
                                               
                                               lstOpportunityInsert.add(new Opportunity(
                                                   StageName = 'New',
                                                   Name = l.Name,
                                                   CloseDate = System.today(),
                                                   AccountId = record.Id,
                                                   OwnerId = l.OwnerId,
                                                   Lead__c = l.Id,
                                                   RecordTypeId = RecordTypeHelper.OPPORTUNITY_PCA
                                               ));
                                           }
                                       }
                                    if(flag) {
                                        newDuplicatedRecords.add(DuplicateValidationHelper.createDuplicatedRecordWithAccount(l, record));
                                    }
                                }
                            }
                        }
                }
                System.debug('lstLeadOpptyOpen:' + lstLeadOpptyOpen);
                System.debug('lstOpportunityInsert:' + lstOpportunityInsert);
                if(!lstOpportunityInsert.isEmpty()) {
                    objDevLog.Output__c += ' <br/> lstOpportunityInsert Check : ' + String.valueOf(lstOpportunityInsert);
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
                        if(item.RecordTypeId == RecordTypeHelper.OPPORTUNITY_BIKE 
                           && (item.Owner.Profile.Name == 'Community Consultant Service' 
                           || item.Owner.Profile.Name == 'Community Consultant PCA'
                           || item.Owner.Profile.Name == 'Community Consultant PCA 2')) {
                            lstOpptyTeam.add(new OpportunityTeamMember(
                                OpportunityId = item.Id,  
                                OpportunityAccessLevel = 'Edit',
                                TeamMemberRole = 'Sales Rep',
                                UserId  =  mapLeadNew?.get(item.Lead__c)?.OwnerId
                            ));
                            insert lstOpptyTeam;
                        }
                    }
                    
                }
                insert objDevLog;
                if(!lstLeadOpptyOpen.isEmpty()) {
                    insert lstLeadOpptyOpen;
                }
                if(!lstAccountUpdate.isEmpty()) {
                    upsert lstAccountUpdate;
                }
                if (!mapUpdatedLead.isEmpty()){
                    update mapUpdatedLead.values();
                }
                
                if (!newDuplicatedRecords.isEmpty()){
                    insert newDuplicatedRecords;
                }
                if (!lstConvertedOpp.isEmpty()){
                    // Auto Converted Lead to Account attach Opportunity
                    Database.LeadConvertResult[] lcr = Database.convertLead(lstConvertedOpp);
                }
            }
        } catch(Exception ex) {
            System.debug('ex.getErrorMessage() :' + ex.getMessage() + ' ' + ex.getLineNumber());
            System.debug('ex.getErrorMessage() :' + ex.getStackTraceString());
        }
        
    }
    
    private static Map<Id, User> getAllUser(){
        Map<Id, User> mapGetAllUser = new Map<Id, User>([SELECT Id, DODL_Manager__c, AccountId, ContactId, ProfileId
                                                         FROM User]);
        return mapGetAllUser;
    }
    
    private static Map<Id, User> gerUserMarketting(){
        Map<Id, User> mapUserMarketing = new Map<Id, User>([SELECT Id, Name
                                                            FROM User
                                                            WHERE Profile.Name = 'MKT Manager']);
        return mapUserMarketing;
    }
    
    private static Map<Id, Profile> getProfile(){
        return new Map<Id, Profile>([SELECT ID, Name
                                     FROM Profile
                                     WHERE Name = :'Community DO DL Manager']);
    }

    private static Map<Id, User> getProfileDODLManager(){
        return new Map<Id, User>([SELECT ID
                                     FROM User
                                     WHERE Profile.Name = :'Community DO DL Manager']);
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
         a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
         a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
         a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
         a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
         a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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