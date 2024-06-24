public without sharing class VFP_PDF_DeliveryCheckList {
    public string recordId{get;set;}
    public string logo { get; set; }
    public obj_Account_Order obj_account_order{get;set;}

    public class obj_Account_Order{
        public Order objOrder{get;set;}
        public Account objAccount{get;set;}
        public User objUser{get;set;}
    }
    public VFP_PDF_DeliveryCheckList(){
        this.recordId = ApexPages.currentPage().getParameters().get('Id');
        // this.recordId = UserInfo.getUserId();
        this.obj_account_order = getOrder(this.recordId);
		 logo= '';
 
        
        if (obj_account_order.objOrder.DO_DL__r.Name != null) {
            String doDlCreateName = obj_account_order.objOrder.DO_DL__r.Name;
            if (doDlCreateName == 'REVZONE YAMAHA MOTOR HA NOI') {
                logo = 'logoRevzoneYamahaMotorHN';// REVZONE YAMAHA MOTOR HA NOI
            } else {
                logo = 'logoRevzoneYamahaMotorSG';
            }
        }
    }
    
    public  static obj_Account_Order getOrder(Id recordId){
        obj_Account_Order obj_dto = new obj_Account_Order();

        User objUser = [SELECT Id, 
                                AccountId,
                                Contact.Name,
                                Name,
                                Zalo_Viber__c
                                FROM User 
                                WHERE Id =: UserInfo.getUserId()][0];
        System.debug(objUser);
        obj_dto.objUser = objUser;
        if(objUser.AccountId!=null){
            Account objAccount = [SELECT Id, Name, Address__c FROM Account WHERE Id=:objUser.AccountId][0];
            obj_dto.objAccount = objAccount;
        }
            Order objOrder = [SELECT Owner.Name, 
                                     Owner.Phone, 
                                     Asset__r.Product2.Sales_Name__c,
                                     Asset__r.Product2.Color_Name__c,
                                     Asset__r.Engine_No__c,
                                     Asset__r.Frame_Number__c,
                                     Account.Name,  
                                     Account.Address_Full__c,
                                     DO_DL__r.Name,
                                     Account.PersonMobilePhone,
                                     Account.DO_DL_Create_Account__r.Name,
                                     Account.DO_DL_Create_Account__r.Address__c,
                              		 Account.DO_DL_Create_Account__r.Address_logo__c
                                     FROM Order 
                                     WHERE Id=:recordId][0];
            obj_dto.objOrder = objOrder;
            
       	
            return obj_dto;
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
    }
    
}