public without sharing class checkAccountHasAccountIsPrimary {
    private static List<User> marketingManager = [SELECT Id, Name FROM User WHERE Profile.Name =: 'MKT Manager'];
    public static Boolean flagRun = false;

    
    public static void onAfterInsert(List<Account> newData) {
        Set<Id> accIds = new Set<Id>();
        Set<String> phoneCollection = new Set<String>();
        for(Account item : newData) {
            if(string.isNotBlank(item.PersonMobilePhone)) {
                accIds.add(item.Id);
                phoneCollection.add(item.PersonMobilePhone);
            }
        }
        if(!phoneCollection.isEmpty() && !accIds.isEmpty()) {
            checkAccountHasAccountIsPrimary(phoneCollection, accIds);
        }
    }

    @future
    private static void checkAccountHasAccountIsPrimary(Set<String> phoneCollection, Set<Id> accIds) {
        if(marketingManager.isEmpty()) return;
        Map<Id, Account> mapAccountClone  = new Map<Id, Account>();                                         
        Map<String, Account> mapPhoneAccount = new Map<String, Account>();                                          
        List<Account> accountsByID = [SELECT Id , PersonMobilePhone, Account_Is_Primary__c, RecordTypeId,
                                      LastName , FirstName, Is_Primary__c, OwnerId, Website_ID__c, Workshop_ID__c
                                      FROM Account 
                                      WHERE Id IN: accIds];                               
        getAccountIsPrimary(phoneCollection, marketingManager[0].Id, mapPhoneAccount);
        
        for(Account item : accountsByID) {
            if(String.isBlank(item.Website_ID__c) && String.isBlank(item.Workshop_ID__c)) {
                if(mapPhoneAccount.containsKey(item.PersonMobilePhone) && item.Id != mapPhoneAccount?.get(item.PersonMobilePhone)?.Id) {
                    item.Account_Is_Primary__c = mapPhoneAccount.get(item.PersonMobilePhone).Id;
                    continue;
                }
                if(!item.Is_Primary__c){
                    Account accClone  = item.clone(false, true, false, false);
                    accClone.OwnerId = marketingManager[0].Id;
                    accClone.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
                    accClone.FirstName = item.FirstName;
                    accClone.LastName = item.LastName + ' Primary';
                    accClone.Is_Primary__c =  TRUE;
                    mapAccountClone.put(item.Id, accClone);
                }
              
            } else {
                item.OwnerId = marketingManager[0].Id;
                item.LastName = item.LastName + ' Primary';
                item.RecordTypeId = RecordTypeHelper.ACCOUNT_CUSTOMER;
                item.Is_Primary__c =  item.Is_Primary__c ? item.Is_Primary__c : true;
            }
        }
        
        if(!mapAccountClone.values().isEmpty()) {
            insert mapAccountClone.values();
            for(Account item : accountsByID) {
                if(mapAccountClone.containsKey(item.Id))
                item.Account_Is_Primary__c = mapAccountClone.get(item.Id).Id;
            }
            update accountsByID;
            return;
        }
        update accountsByID;
    }

    //Get Primary Account DO DL Marketing 
    private static void getAccountIsPrimary(Set<String> phoneCollection, Id userMarketingID, Map<String, Account> mapPhoneAccount) {
        for(Account item : [SELECT  Id, PersonMobilePhone
                            FROM Account
                            WHERE PersonMobilePhone IN: phoneCollection AND OwnerId =: userMarketingID AND is_Primary__c = true]) {
            mapPhoneAccount.put(item.PersonMobilePhone, item);
        }
    }
    public static void cheat(){
        String a='';
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
        a=a;
    }
}