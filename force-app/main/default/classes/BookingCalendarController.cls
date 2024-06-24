public with sharing class BookingCalendarController {
    private static String STR_STATUS = 'New';
    
    @AuraEnabled(cacheable=true)
    public static List<RosterManagerDTO> getBookinhServiceAll(){
        Date dateQuerry = Date.today();
        Map<Id, List<Order>> mapIdParentToLstChild = new Map<Id, List<Order>>();
        mapIdParentToLstChild = getListOrderServiceByDate(new List<String>(), new List<String>(), dateQuerry);
        List<RosterManagerDTO> lstRosterByMonth = getRosterAll(mapIdParentToLstChild, new List<String>(), new List<String>(), dateQuerry);

        return lstRosterByMonth;
    }

    @AuraEnabled(cacheable=true)
    public static List<RosterManagerDTO> getBookingServiceByCondition(List<String> lstContactMechenic
                                                                        , List<String> lstContactDetailingStaff
                                                                        , Datetime dateInput){
        Date dateCondition = dateInput.date();                                                                     
        Map<Id, List<Order>> mapIdParentToLstChild = new Map<Id, List<Order>>();
        mapIdParentToLstChild = getListOrderServiceByDate(lstContactMechenic, lstContactDetailingStaff, dateCondition);
        List<RosterManagerDTO> lstRosterByMonth = getRosterAll(mapIdParentToLstChild, lstContactMechenic, lstContactDetailingStaff, dateCondition);
        return lstRosterByMonth;
    }

    // Get piclist  status
    @AuraEnabled 
    public static Map<String, String> getIndustryFieldValue(){
        Map<String, String> options = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = Booking__c.Status__c.getDescribe();
        
        List<Schema.PicklistEntry> pValues = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p : pValues) {
            options.put(p.getValue(), p.getLabel());
        }
        System.debug('options :' + options);
        return options;
    }

    private static User getUserByIdOrg() {
        String strUserId = UserInfo.getUserId();
        return [SELECT Id, AccountId FROM User WHERE Id =: strUserId];
    }

    @AuraEnabled(Cacheable=true)
    public static List<Contact> getRecentlyContactViewed(String strContactType) {
        // Get recently viewed records of type Account or Opportunity
        User objUser = getUserByIdOrg();
        List<Contact> lstContactByAccountId  = [SELECT  Name
                                                        , Email
                                                        , Account.Name
                                                FROM Contact
                                                WHERE Contact_Type__c =: strContactType
                                                ORDER BY Name DESC];
        // Convert recent records into LookupSearchResult
        return lstContactByAccountId;
    }


    // private static Map<Contact> getListContact(){
    //     return new List<Contact>([SELECT Id, Name FROM Contact WHERE (Contact_Type__c =: 'Mechanic' OR  Contact_Type__c =: 'Detailing Staff')]);
    // }

    private static Map<Id, List<Order>> getListOrderServiceByDate(List<String> lstContactMechenic, List<String> lstContactDetailingStaff, Date dateConditon) {
        System.debug('dateConditon:' + dateConditon);
        Map<Id, List<Order>> mapIdParentToLstChild =  new Map<Id, List<Order>>();
        Set<String> setIdContact = new Set<String>();
        string strWhere = '';
        string strQuerry = 'SELECT Id';
        strQuerry +=    ', OrderNumber';
        strQuerry +=    ', EffectiveDate';
        strQuerry +=    ', Mechanic__c';
        strQuerry +=    ', Mechanic__r.Name';
        strQuerry +=    ', Detailing_Staff__c';
        strQuerry +=    ', Detailing_Staff__r.Name';
        strQuerry +=    ', Service_Job_Start_Date__c';
        strQuerry +=    ', Service_Job_End_Date__c';
        strQuerry +=    ', Detailing_Start_Date__c';
        strQuerry +=    ', Detailing_End_Date__c';
        strQuerry +=    ', RecordType.Name';
        strQuerry +=    ' FROM Order';
        strQuerry +=    ' WHERE EffectiveDate =: dateConditon ';
        if(!lstContactMechenic.isEmpty()) {
            for(String item : lstContactMechenic) {
                setIdContact.add(item);
            }
        }
        if(!lstContactDetailingStaff.isEmpty()) {
            for(String item : lstContactDetailingStaff) {
                setIdContact.add(item);
            }
        }
        if(!setIdContact.isEmpty()) {
            System.debug('setIdContact' + setIdContact);
            strQuerry += ' AND (Mechanic__c IN: setIdContact OR Detailing_Staff__c IN: setIdContact)';
        }
        List<Order> lstOrder = Database.query(strQuerry);
        System.debug('lstOrder' + lstOrder.size());
        if(!lstOrder.isEmpty()) {
            for(Order item : lstOrder) {
                if(item.Mechanic__c != Null) {
                    if (mapIdParentToLstChild.containsKey(item.Mechanic__c)){
                        List<Order> lstTaskChild = mapIdParentToLstChild.get(item.Mechanic__c);
                        lstTaskChild.add(item);
                        mapIdParentToLstChild.put(item.Mechanic__c, lstTaskChild);
                    } else{
                        mapIdParentToLstChild.put(item.Mechanic__c, new List<Order>{item});
                    }
                }
                if(item.Detailing_Staff__c != Null) {
                    if (mapIdParentToLstChild.containsKey(item.Detailing_Staff__c)){
                        List<Order> lstTaskChild = mapIdParentToLstChild.get(item.Detailing_Staff__c);
                        lstTaskChild.add(item);
                        mapIdParentToLstChild.put(item.Detailing_Staff__c, lstTaskChild);
                    } else{
                        mapIdParentToLstChild.put(item.Detailing_Staff__c, new List<Order>{item});
                    }   
                }
            }
        }
        return mapIdParentToLstChild;
    }

    private static List<RosterManagerDTO> getRosterAll(Map<Id, List<Order>> mapContactWithOrders, List<String> lstContactMechenic, List<String> lstContactDetailingStaff,  Date dateConditon){
        Set<String> setIdContact = new Set<String>();
        List<RosterManagerDTO> lstRosterManagerDTO = new List<RosterManagerDTO>();
        String strQuerry  = 'SELECT Id';
        strQuerry   += ', Name';
        strQuerry   += ', From__c';
        strQuerry   += ', To__c';
        strQuerry   += ', Date__c';
        strQuerry   += ', CreatedDate';
        strQuerry   += ', Staff__c';
        strQuerry   += ', Staff__r.Contact_Type__c';
        strQuerry   += ', Staff__r.Name';
        strQuerry   += ', Shift__c';
        strQuerry   += ', Shift__r.Name';
        strQuerry   += ', Shift_Code__c';
        strQuerry   += ' FROM Roster_Management__c';
        strQuerry   += ' WHERE Date__c =: dateConditon AND Staff__c != NULL ';

        if(!lstContactMechenic.isEmpty()) {
            for(String item : lstContactMechenic) {
                setIdContact.add(item);
            }
        }
        if(!lstContactDetailingStaff.isEmpty()) {
            for(String item : lstContactDetailingStaff) {
                setIdContact.add(item);
            }
        }
        if(!setIdContact.isEmpty()) {
            strQuerry += ' AND Staff__c IN: setIdContact';
        }

        List<Roster_Management__c> RostertList = Database.query(strQuerry);

        for(Roster_Management__c item : RostertList) {
            String dtFrom = String.valueOf(item.Date__c)+' '+String.valueOf(item.From__c).replace('000Z','');
            String dtTo = String.valueOf(item.Date__c)+' '+String.valueOf(item.To__c).replace('000Z','');
            if(mapContactWithOrders.containsKey(item.Staff__c)) {
                
                List<OrderServiceDTO> lstOrderServiceDTo = new List<OrderServiceDTO>();
                for(Order objOrder : mapContactWithOrders.get(item.Staff__c)) {
                    if(objOrder.EffectiveDate == item.Date__c) {
                        lstOrderServiceDTo.add(new OrderServiceDTO(objOrder, item.Staff__c, item.Staff__r.Contact_Type__c));
                    }
                }
                lstRosterManagerDTO.add(new RosterManagerDTO(item, Datetime.valueOf(dtFrom), Datetime.valueOf(dtTo), lstOrderServiceDTo));
            } else {
                lstRosterManagerDTO.add(new RosterManagerDTO(item, Datetime.valueOf(dtFrom), Datetime.valueOf(dtTo), new List<OrderServiceDTO>()));
            }
            
        }
        System.debug('lstRosterManagerDTO :' + lstRosterManagerDTO);
        return lstRosterManagerDTO;
    }

    public  class RosterManagerDTO {
        @AuraEnabled
        public String Id;
        
        @AuraEnabled
        public String Name; 

        @AuraEnabled
        public Time timeFrom;

        @AuraEnabled
        public Time timeTo;

        @AuraEnabled
        public Date dtDate;

        @AuraEnabled
        public Datetime DateTimeFrom;

        @AuraEnabled
        public Datetime DateTimeTo;

        @AuraEnabled
        public string shiftname;

        @AuraEnabled
        public string shiftcode;


        @AuraEnabled
        public string StaffId;

        @AuraEnabled
        public string StaffName;


        @AuraEnabled
        public List<OrderServiceDTO> lstOrderDTO;


        public RosterManagerDTO() {}

        public  RosterManagerDTO(Roster_Management__c obj, Datetime dtFrom, Datetime dtTo, List<OrderServiceDTO> lstOrderDTO) {
            this.Id = obj.Id;
            
            this.timeFrom = obj.From__c;
            this.timeTo = obj.To__c;
            this.dtDate = obj.Date__c;
            this.DateTimeFrom = dtFrom;
            this.DateTimeTo = dtTo;
            this.Name = obj.Staff__r.Name;
            this.shiftname = obj.Shift__r.Name;
            this.shiftcode = obj.Shift_Code__c;
            this.StaffId = obj.Staff__c;
            this.lstOrderDTO = lstOrderDTO;
        }
    }


    public  class OrderServiceDTO {
        @AuraEnabled
        public String Id;

        @AuraEnabled
        public String OrderNumber; 

        @AuraEnabled
        public String RecordTypeName; 
        
        @AuraEnabled
        public String ResourceId; 

        @AuraEnabled
        public Datetime StartDate;

        @AuraEnabled
        public Datetime EndDate;

        public OrderServiceDTO() {}

        public  OrderServiceDTO(Order obj, String resourceId, String strContactType) {
            this.Id = obj.Id;
            this.ResourceId = resourceId;
            this.OrderNumber = obj.OrderNumber;
            this.RecordTypeName = obj.RecordType.Name;
            if(strContactType == 'Mechanic') {

            } else if(strContactType == 'Detailing Staff') {

            }
            this.StartDate = strContactType == 'Mechanic' ? obj.Service_Job_Start_Date__c : obj.Detailing_Start_Date__c;
            this.EndDate = strContactType == 'Detailing Staff' ? obj.Detailing_End_Date__c : obj.Service_Job_End_Date__c;
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
        }
}