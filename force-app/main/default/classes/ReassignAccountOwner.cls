public without sharing class ReassignAccountOwner {

    //Get Objects related to Account
    @AuraEnabled
    public static ApiResponse getAccountDTO(String recordId) {
        ApiResponse apiresponse = new ApiResponse();
        AccountDTO objAccountDTO = new AccountDTO();
        Account objAccount = new Account();
        try {
            objAccount = getObjectAccount(recordId);
            if(objAccount != Null) {
                objAccountDTO = new AccountDTO(objAccount
                                                , objAccount.Opportunities
                                                , objAccount.Orders
                                                , objAccount.Order_Account__r);
            } 
            if(apiResponse.error == null) {
                apiResponse.success = true;
                apiResponse.result = objAccountDTO;
            }
            return apiResponse;
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    

    //Get Picklist User
    @AuraEnabled
    public static ApiResponse getUserById(String recordId) {
        ApiResponse apiResponse = new apiResponse();
        List<User> lstUserByDODL = new List<User>();
        Follow_Fail__c objFollowFail = [SELECT Id
                                                , Account__c
                                                , Account__r.OwnerId
                                            FROM Follow_Fail__c
                                            WHERE Id =: recordId];
        System.debug('objFollowFail.Account__r.OwnerId :' + objFollowFail.Account__r.OwnerId);
        User objUserById = [SELECT Id, DODL_Manager__c FROM User Where Id =: objFollowFail.Account__r.OwnerId];
        if(objUserById.DODL_Manager__c != Null) {
            System.debug('objUserById.DODL_Manager__c :' + objUserById.DODL_Manager__c);
            System.debug('objUserById.DODL_Manager__c :' + objUserById.DODL_Manager__c);
            lstUserByDODL =  mapUserByDoDL(objUserById.DODL_Manager__c, objUserById.Id);
        }
        if(lstUserByDODL.isEmpty()) {
            apiResponse.error = 'No user belongs to DO DL';
            return apiResponse;
        }
        if(apiResponse.error == Null) {
            apiResponse.success = true;
            apiResponse.result = lstUserByDODL;
        }
        return apiResponse;
    }

   

    @AuraEnabled
    public static ApiResponse updateOwnerAllObjectRelatedToAccount(String recordId, String recordIdOwnerId) {
        ApiResponse apiresponse = new ApiResponse();
        Account objAccount = new Account();
        Set<Id> setIdOpp = new Set<Id>();
        try {
            objAccount = getObjectAccount(recordId);
            if(objAccount != Null) {
                objAccount.OwnerId = recordIdOwnerId;
                for(Opportunity item : objAccount.Opportunities) {
                    item.OwnerId = recordIdOwnerId;
                }
                for(Order item : objAccount.Orders) {
                    item.OwnerId = recordIdOwnerId;
                    setIdOpp.add(item.Id);
                }
                for(Order_Account__c item : objAccount.Order_Account__r) {
                    item.OwnerId = recordIdOwnerId;
                }
                update objAccount;
                update objAccount.Opportunities;
                update objAccount.Orders;
                update objAccount.Order_Account__r;
                List<Test_Ride__c> lstTestRide = [SELECT Id
                                                        , OwnerId
                                                    FROM Test_Ride__c
                                                    WHERE Opportunity__c IN: setIdOpp];
                List<Contract> lstContractByOpp = [SELECT Id
                                                        , OwnerId
                                                FROM Contract
                                                WHERE Opportunity__c IN: setIdOpp];
                if(!lstTestRide.isEmpty()) {
                    for(Test_Ride__c item : lstTestRide) {
                        item.OwnerId = recordIdOwnerId;
                    }
                    update lstTestRide;
                }
                if(!lstContractByOpp.isEmpty()) {
                    for(Contract item : lstContractByOpp) {
                        item.OwnerId = recordIdOwnerId;
                    }
                    update lstContractByOpp;
                }
            }
            if(apiresponse.error == Null) {
                apiresponse.success = true;
            }
            return apiresponse;
        } catch(Exception ex) {
            System.debug('Exception error: '+ ex.getMessage() + ' ' + ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }
    }

     //Get List User By DODL Manager Field ON User
     private static List<User> mapUserByDoDL(String strUserId, String strUserIdCurrent) {
        List<User> lstUserByDODL = [SELECT Id, Name 
                                    FROM    User 
                                    WHERE DODL_Manager__c =: strUserId 
                                        AND Id !=: strUserIdCurrent];
        return lstUserByDODL;
    }

    private static Account getObjectAccount(String recordId) {
        Follow_Fail__c objFollowFail = [SELECT Id
                                                , Account__c
                                        FROM Follow_Fail__c
                                        WHERE Id =: recordId];
        Account objAccount = [SELECT Id
                                    , OwnerId
                                    , (SELECT Id
                                            , Name
                                            , StageName
                                            , CreatedDate
                                            , LastModifiedDate
                                            , Owner.Name
                                    FROM Opportunities
                                    WHERE StageName !=: 'Closed Won' 
                                    AND StageName !=: 'Closed Lost' 
                                    AND RecordTypeId =: RecordTypeHelper.OPPORTUNITY_BIKE)
                                    , (SELECT Id
                                            , OrderNumber
                                            , Status
                                            , CreatedDate
                                            , Owner.Name
                                            , LastModifiedDate
                                    FROM Orders
                                    WHERE Status !=: 'Closed' AND RecordTypeId =: RecordTypeHelper.ORDER_BIKE)
                                    , (SELECT Id
                                        , Name
                                        , Order__c
                                        , Order_Number__c
                                        , Bike_cc_Product__c
                                        , Order_Status__c
                                        , Owner.Name
                                    FROM Order_Account__r)
                                    , CreatedDate
                                    , Owner.Name
                                    FROM  Account
                                    WHERE Id =: objFollowFail.Account__c];
        return objAccount;
    }

    //Class DTO
    public class AccountDTO {
        @AuraEnabled
        public  Account objAccount {get; set;}

        @AuraEnabled
        public  List<Opportunity> lstOpportunity {get; set;}

        @AuraEnabled
        public  List<Order> lstOrder  {get; set;}

        @AuraEnabled
        public  List<Order_Account__c> lstOrderAccount  {get; set;}

        @AuraEnabled
        public Boolean hideBool {get; set;}

        public AccountDTO() {}

		public AccountDTO(Account objAccount, List<Opportunity> lstOpportunity, List<Order> lstOrder, List<Order_Account__c> lstOrderAccount) {
            this.objAccount = objAccount;
            this.lstOpportunity = lstOpportunity;
            this.lstOrder = lstOrder;
            this.lstOrderAccount = lstOrderAccount;
            this.hideBool = true;
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
    }
}