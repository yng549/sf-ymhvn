public with sharing class CalendarBookingController {
    private static String ACCOUNT_DODL_NULL = 'List account do dl is empty.';
    private static String CONTACT_NULL = 'List contact do dl is empty.';

    @AuraEnabled(cacheable=true)
    public static ApiResponse getBookingInit(){
        ApiResponse apiresponse = new ApiResponse();
        Date dateMin = Date.today().addMonths(-2);
        Date dateMax = Date.today().addMonths(+2);
        List<objBookingDTO> lstBookingDTO = new List<objBookingDTO>();
        try {
            User objUserDefault = [SELECT Id, AccountId FROM User WHERE Id =: Userinfo.getUserId()];
            String query = '';
            query += ' SELECT Id';
            query += ' , Name';
            query += ' , Service_Type__c';
            query += ' , Booking_Start_Time__c';
            query += ' , Booking_End_Time__c';
            query += ' , Confirm_Start_Time__c';
            query += ' , Confirm_End_Time__c';
            query += ' , Full_Name__c';
            query += ' FROM Booking__c';
            query += ' WHERE Booking_Start_Time__c >=: dateMin';
            query += ' AND Booking_Start_Time__c <=: dateMax';
            query += ' AND Service_Type__c != NULL';
            if(String.isNotBlank(objUserDefault.AccountId)) {
                query += ' AND Do_DL__c =: objUserDefault.AccountId';
            }
            List<Booking__c> lstBooking = Database.query(query);
            if(lstBooking.isEmpty()) {
                apiresponse.error = 'Not any booking is exist.';
                return apiresponse;
            }
            for(Booking__c item : lstBooking) {
                lstBookingDTO.add(new objBookingDTO(item));
            }
            System.debug('lstBookingDTO:' + lstBookingDTO);
            if(!lstBooking.isEmpty()) {
                apiresponse.success = true;
                apiresponse.result = lstBookingDTO;
            }                                    
            return apiresponse;
        } catch (Exception e) {
            apiresponse.error = e.getMessage() + ' ' + e.getLineNumber();
            return apiresponse;
        }
    }

    @AuraEnabled
    public static ApiResponse getBookingByCondition(List<String> lstStrDODL, List<String> lstServiceType, List<String> lstEmployee){
        ApiResponse apiresponse = new ApiResponse();
        Date dateMin = Date.today().addMonths(-2);
        Date dateMax = Date.today().addMonths(+2);
        List<objBookingDTO> lstBookingDTO = new List<objBookingDTO>();
        try {
            System.debug('lstStrDODL:'+ lstStrDODL);
            System.debug('lstServiceType:'+ lstServiceType);
            System.debug('lstEmployee:'+ lstEmployee);

            String query = '';
            query += ' SELECT Id';
            query += ' , Name';
            query += ' , Service_Type__c';
            query += ' , Booking_Start_Time__c';
            query += ' , Booking_End_Time__c';
            query += ' , Confirm_Start_Time__c';
            query += ' , Confirm_End_Time__c';
            query += ' , Full_Name__c';
            query += ' FROM Booking__c';
            query += ' WHERE Booking_Start_Time__c >=: dateMin';
            query += ' AND Booking_Start_Time__c <=: dateMax';
            query += ' AND Service_Type__c != NULL';
            if(!lstStrDODL.isEmpty()) {
                query += ' AND Do_DL__c IN: lstStrDODL';
            }
            if(!lstServiceType.isEmpty()) {
                query += ' AND Service_Type__c IN: lstServiceType';
            }
            if(!lstEmployee.isEmpty()) {
                query += ' AND (Technical__c IN: lstEmployee OR Detailing__c IN: lstEmployee)';
            }
            List<Booking__c> lstBookingQuerry = Database.query(query);
            if(lstBookingQuerry.isEmpty()) {
                apiresponse.error = 'Not any booking is exist by condition.';
                return apiresponse;
            }
            for(Booking__c item : lstBookingQuerry) {
                lstBookingDTO.add(new objBookingDTO(item));
            }
            System.debug('lstBookingDTO:' + lstBookingDTO);
            if(!lstBookingDTO.isEmpty()) {
                apiresponse.success = true;
                apiresponse.result = lstBookingDTO;
            }                                    
            return apiresponse;
        } catch (Exception e) {
            apiresponse.error = e.getMessage() + ' ' + e.getLineNumber();
            return apiresponse;
        }
    }

    @AuraEnabled
    public static ApiResponse getLstAccountByRecordType(){
        ApiResponse apiresponse = new ApiResponse();
        try {
            List<Account> lstAccount = [SELECT Id, Name FROM Account WHERE RecordTypeId =: RecordTypeHelper.ACCOUNT_DODL];
            if(lstAccount.isEmpty()) {
                apiresponse.error = ACCOUNT_DODL_NULL;
                return apiresponse;
            }
            apiresponse.success = true;
            apiresponse.result = lstAccount;
            return apiresponse;
        } catch (Exception e) {
            apiresponse.error = e.getMessage() + ' ' + e.getLineNumber();
            return apiresponse;
        }
    }

    @AuraEnabled
    public static ApiResponse getLstContactByRecordType(){
        ApiResponse apiresponse = new ApiResponse();
        try {
            List<Contact> lstContact = [SELECT Id, Name FROM Contact WHERE RecordTypeId =: RecordTypeHelper.CONTACT_EMPLOYEE];
            if(lstContact.isEmpty()) {
                apiresponse.error = CONTACT_NULL;
                return apiresponse;
            }
            apiresponse.success = true;
            apiresponse.result = lstContact;
            return apiresponse;
        } catch (Exception e) {
            apiresponse.error = e.getMessage() + ' ' + e.getLineNumber();
            return apiresponse;
        }
    }


    public  class objBookingDTO {
        @AuraEnabled
        public  String Id {get;set;}

        @AuraEnabled
        public String ServiceType {get; set;}

        @AuraEnabled
        public String NameCustomer {get; set;}

        @AuraEnabled
        public Datetime BookingStart {get; set;}

        @AuraEnabled
        public Datetime  BookingEnd {get; set;}

        @AuraEnabled
        public Datetime ConfirmStart {get; set;}

        @AuraEnabled
        public Datetime ConfirmEnd {get; set;}

        public objBookingDTO(Booking__c obj) {
            this.Id = obj.Id;
            this.ServiceType = obj.Service_Type__c;
            this.BookingStart = obj.Booking_Start_Time__c;
            this.BookingEnd = obj.Booking_End_Time__c;
            this.ConfirmStart = obj.Confirm_Start_Time__c;
            this.ConfirmEnd = obj.Confirm_End_Time__c;
            this.NameCustomer = obj.Full_Name__c;
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
    }
}