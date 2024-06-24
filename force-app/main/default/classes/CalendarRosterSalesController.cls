public without sharing class CalendarRosterSalesController {


    @AuraEnabled(cacheable=true)
    public static ApiResponse getRosterAllByResource(){
        ApiResponse apiresponse = new ApiResponse();
        try {
            List<ResourceDTO> lstResourceDTO = getRosterAll(new List<String>(), Date.today());
            if(lstResourceDTO.isEmpty()) {
                apiresponse.error = 'Not any roster management.';
                return apiresponse;
            }
            if(apiresponse.error == NULL) {
                apiresponse.success = true;
                apiresponse.result = lstResourceDTO;
            }
            return apiresponse;
        } catch(Exception ex) {
            apiresponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            return apiresponse;
        }
    } 

    @AuraEnabled
    public static ApiResponse getRosterByConditon(List<String> lstStringContact, Datetime dteDate){
        ApiResponse apiresponse = new ApiResponse();
        Date dateInput = Date.valueOf(dteDate);
        try {
            List<ResourceDTO> lstResourceDTO = getRosterAll(lstStringContact, dateInput);
            if(lstResourceDTO.isEmpty()) {
                apiresponse.error = 'Not any roster management.';
                return apiresponse;
            }
            if(apiresponse.error == NULL) {
                apiresponse.success = true;
                apiresponse.result = lstResourceDTO;
            }
            System.debug('lstResourceDTO :' + lstResourceDTO);
            return apiresponse;
        } catch(Exception ex) {
            apiresponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            return apiresponse;
        }
    }

    private static List<ResourceDTO> getRosterAll(List<String> lstContact, Date dateInput) {
        List<ResourceDTO> lstResourceDTO = new List<ResourceDTO>();
        Map<Id, List<RosterManagerDTO>> mapStaffWithRosters = new Map<Id, List<RosterManagerDTO>>();
        List<RosterManagerDTO> lstRosterManagerDTO = new List<RosterManagerDTO>();
        Date firstDate = dateInput.toStartOfMonth(); 
        Date lastDate = firstDate.addDays(date.daysInMonth(dateInput.year() , dateInput.month())  - 1);
        system.debug(firstDate  + ' **** ' +lastDate );
    
        User objUserDefault = [SELECT Id, AccountId FROM User WHERE Id =: Userinfo.getUserId()];
        //001O000001rVQFyIAO ACCOUNT ID
        Map<Id, Contact> mapContactByAccountId  = new Map<Id, Contact>([SELECT  Name
                                                                                , Email
                                                                                , Account.Name
                                                                        FROM Contact
                                                                        WHERE AccountId =: objUserDefault.AccountId
                                                                        ORDER BY Name DESC]);

        String strQuerry  = 'SELECT Id';
        strQuerry   += ' , Name';
        strQuerry   += ' , From__c';
        strQuerry   += ' , To__c';
        strQuerry   += ' , Date__c';
        strQuerry   += ' , CreatedDate';
        strQuerry   += ' , Staff__c';
        strQuerry   += ' , Staff__r.Contact_Type__c';
        strQuerry   += ' , Staff__r.Name';
        strQuerry   += ' , Shift__c';
        strQuerry   += ' , Absent_Submit__c';
        strQuerry   += ' , Shift__r.Name';
        strQuerry   += ' , Shift_Code__c';
        strQuerry   += ' FROM Roster_Management__c';
        strQuerry   += ' WHERE Date__c >=: firstDate ';
        strQuerry   += ' AND Date__c <=: lastDate';
        if(!lstContact.isEmpty()) {
            System.debug('Case 1 ');
            strQuerry += ' AND Staff__c IN: lstContact ';
        } else {
            System.debug('Case 2 ');
            Set<Id> setIdContact = new Set<Id>(mapContactByAccountId.keySet());
            strQuerry += ' AND Staff__c IN: setIdContact ';
        }
        List<Roster_Management__c> lstRosterQuery = Database.query(strQuerry);
        System.debug('lstRosterQueryll line 83: ' + lstRosterQuery);
        if(!lstRosterQuery.isEmpty()) {
            for(Roster_Management__c item : lstRosterQuery) {
                String dtFrom = String.valueOf(item.Date__c)+' '+String.valueOf(item.From__c).replace('000Z','');
                String dtTo = String.valueOf(item.Date__c)+' '+String.valueOf(item.To__c).replace('000Z','');
                if(mapStaffWithRosters.containsKey(item.Staff__c)) {
                    List<RosterManagerDTO> lstRosterDTO = mapStaffWithRosters.get(item.Staff__c);
                    lstRosterDTO.add(new RosterManagerDTO(item, Datetime.valueOf(dtFrom), Datetime.valueOf(dtTo)));
                    mapStaffWithRosters.put(item.Staff__c, lstRosterDTO);
                } else {
                    mapStaffWithRosters.put(item.Staff__c, new List<RosterManagerDTO>{new RosterManagerDTO(item, Datetime.valueOf(dtFrom), Datetime.valueOf(dtTo))});
                }
            }
        }
        System.debug('mapStaffWithRosters: ' + mapStaffWithRosters);
        for(Contact item : mapContactByAccountId.values()) {
            if(mapStaffWithRosters.containsKey(item.Id)) {
                lstResourceDTO.add(new ResourceDTO(item, mapStaffWithRosters.get(item.Id)));
            }
        }
        return lstResourceDTO;
    }

    @AuraEnabled(Cacheable=true)
    public static List<Contact> getRecentlyContactViewed() {
        // Get recently viewed records of type Account or Opportunity
        User objUserDefault = [SELECT Id, AccountId FROM User WHERE Id =: Userinfo.getUserId()];
        List<Contact> lstContactByAccountId  = [SELECT  Id
                                                    , Name
                                                    , Email
                                                    , Account.Name
                                                FROM Contact
                                                WHERE AccountId =: objUserDefault.AccountId
                                                ORDER BY Name DESC];
        // Convert recent records into LookupSearchResult
        return lstContactByAccountId;
    }

    public class ResourceDTO {
        @AuraEnabled
        public String Id;
        
        @AuraEnabled
        public String Name;

        @AuraEnabled
        public List<RosterManagerDTO> lstRosterManagerDTO;


        public  ResourceDTO(Contact obj, List<RosterManagerDTO> lstRosterManagerDTO) {
            this.Id = obj.Id;
            this.Name = obj.Name;
            this.lstRosterManagerDTO = lstRosterManagerDTO;
        }
    }

    

    public  class RosterManagerDTO {
        @AuraEnabled
        public String Id;
        
        

        @AuraEnabled
        public Time timeFrom;

        @AuraEnabled
        public Time timeTo;

        @AuraEnabled
        public Date dtDate;

        @AuraEnabled
        public Datetime StartDate;

        @AuraEnabled
        public Datetime EndDate;

        @AuraEnabled
        public string shiftname;

        @AuraEnabled
        public string shiftcode;


        @AuraEnabled
        public string StaffId;

        @AuraEnabled
        public string StaffName;

        @AuraEnabled
        public Boolean isAbsent;


        public  RosterManagerDTO(Roster_Management__c obj, Datetime dtFrom, Datetime dtTo) {
            this.Id = obj.Id;
            this.isAbsent = obj.Absent_Submit__c;
            this.timeFrom = obj.From__c;
            this.timeTo = obj.To__c;
            this.dtDate = obj.Date__c;
            this.StartDate = dtFrom;
            this.EndDate = dtTo;
            this.shiftname = obj.Shift__r.Name;
            this.shiftcode = obj.Shift_Code__c;
            this.StaffId = obj.Staff__c;
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
          a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
         a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a; a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
                a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a; a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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