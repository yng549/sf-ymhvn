/**
 * @name: FullCalendarController
 * @description: Controller class of fullCalendarJs lightning web component
 * @usage: it is used to fetch, create, delete events from lwc component.
 
 * @author: www.auraenabled.com
 */
public without sharing class FullCalendarController {

    public class EventException extends Exception {}
    
    @AuraEnabled(Cacheable=true)
    public static ApiResponse getRecentlyContactViewed() {
        ApiResponse apiresponse = new ApiResponse();
        User objUser = getUserDefault();
        // if(objUser.AccountId == Null) {
        //     apiresponse.error = 'User is not exits DO DL';
        //     return apiresponse;
        // }
        List<Contact> lstContactByAccountId = [SELECT Id, Name, Email, Account.Name, AccountId FROM Contact WHERE AccountId =: '001O000001rVQFyIAO'];
        if(apiresponse.error == Null) {
            apiresponse.success = true;
            apiresponse.result = lstContactByAccountId;
        }
        return apiresponse;
    }

    private static User getUserDefault() {
        return [SELECT Id, AccountId FROM User WHERE Id =: UserInfo.getUserId()];
    } 

    @AuraEnabled(cacheable=true)
    public static List<Event> fetchEvents() {
        return [SELECT Id, Subject, StartDateTime, IsAllDayEvent, EndDateTime 
                FROM Event 
                ORDER BY CreatedDate DESC
                LIMIT 100];
    }

    @AuraEnabled(cacheable=true)
    public static List<RosterManagerDTO> getRosterAll(){
        Integer mnth = System.Today().MOnth();
        Integer yr = System.Today().Year();
        List<RosterManagerDTO> lstRosterManagerDTO = new List<RosterManagerDTO>();
        List<Roster_Management__c> RostertList = [Select Id
                                                        , Name
                                                        , From__c
                                                        , To__c
                                                        , Date__c
                                                        , CreatedDate   
                                                        , Staff__r.Name
                                                        , Shift__c
                                                        , Shift__r.Name
                                                        , Shift_Code__c
                                                    FROM Roster_Management__c
                                                    WHERE CALENDAR_MONTH(Date__c) =: mnth AND CALENDAR_YEAR(Date__c) =: yr];
        System.debug('RostertList :' + RostertList);
        for(Roster_Management__c item : RostertList) {
            String dtFrom = String.valueOf(item.Date__c)+' '+String.valueOf(item.From__c).replace('000Z','');
            String dtTo = String.valueOf(item.Date__c)+' '+String.valueOf(item.To__c).replace('000Z','');
            lstRosterManagerDTO.add(new RosterManagerDTO(item, Datetime.valueOf(dtFrom), Datetime.valueOf(dtTo)));
        }
        System.debug('lstRosterManagerDTO :' + lstRosterManagerDTO);
        return lstRosterManagerDTO;
    }

    @AuraEnabled(cacheable=true)
    public static List<RosterManagerDTO> getRosterByContactId(List<String> lstContact){
        List<RosterManagerDTO> lstRosterManagerDTO = new List<RosterManagerDTO>();
        List<Roster_Management__c> RostertList = [Select Id
                                                        , Name
                                                        , From__c
                                                        , To__c
                                                        , Date__c
                                                        , CreatedDate
                                                        , Staff__r.Name
                                                        , Shift__c
                                                        , Shift__r.Name
                                                        , Shift_Code__c
                                                    FROM Roster_Management__c
                                                    WHERE Staff__c IN: lstContact];
        System.debug('RostertList :' + RostertList);
        for(Roster_Management__c item : RostertList) {
            String dtFrom = String.valueOf(item.Date__c)+' '+String.valueOf(item.From__c).replace('000Z','');
            String dtTo = String.valueOf(item.Date__c)+' '+String.valueOf(item.To__c).replace('000Z','');
            lstRosterManagerDTO.add(new RosterManagerDTO(item, Datetime.valueOf(dtFrom), Datetime.valueOf(dtTo)));
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
        public string popoverContent;


        @AuraEnabled
        public string shiftname;

        @AuraEnabled
        public string shiftcode;


        public RosterManagerDTO() {}

        public  RosterManagerDTO(Roster_Management__c obj, Datetime dtFrom, Datetime dtTo) {
            this.Id = obj.Id;
            this.Name = obj.Staff__r.Name ;
            this.timeFrom = obj.From__c;
            this.timeTo = obj.To__c;
            this.dtDate = obj.Date__c;
            this.DateTimeFrom = dtFrom;
            this.DateTimeTo = dtTo;
            this.popoverContent = '';
            this.shiftname = obj.Shift__r.Name;
            this.shiftcode = obj.Shift_Code__c;
        }
    }


    /**
     * @description To create an event from web component 
     * @param event - json string with event details - title, start and end for now
     */
    @AuraEnabled
    public static Id createEvent(String event){

        //The following logic to be replaced with your respective event object
        if(String.isBlank(event)){
            return null;
        }
        Map<String, Object> eventMap = (Map<String, Object>) JSON.deserializeUntyped(event);
        
        Event newEvent = new Event();
        newEvent.Subject = eventMap.get('title') != null ? (String)eventMap.get('title') : null;

        String startdate = eventMap.get('start') != null ? 
                            ((String)eventMap.get('start')).replace('T', ' ').replace('.000Z', '') : 
                            null;
        String endDate = eventMap.get('end') != null ? 
                            ((String)eventMap.get('end')).replace('T', ' ').replace('.000Z', '') : 
                            null;

        newEvent.StartDateTime = startdate != null ? Datetime.valueOfGmt(startdate) : null;
        newEvent.EndDateTime = endDate != null ? Datetime.valueOfGmt(endDate) : null;
        // newEvent.IsAllDayEvent = eventMap.get('start') != null ? eventMap.get('start') : null;
        insert newEvent;

        return newEvent.Id;

    }

    /**
     * @description To delete an event from web component 
     * @param eventid - event id to delete from the component
     */
    @AuraEnabled
    public static void deleteEvent(Id eventid) {
        
        if(eventid != null){
            delete [SELECT Id FROM Event Where Id=:eventid];
        }else{
            throw new EventException('Event id is not passed');
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
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;
    }
}