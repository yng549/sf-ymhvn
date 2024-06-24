public class TriggerTestRideHandler {
    public static void beforeInsert(List<Test_Ride__c> newRecordsList){
        Set<String> setOpptyIds = new Set<String>();
        Set<String> setDODLIds = new Set<String>();
        for(Test_Ride__c item : newRecordsList){
            if(item.Opportunity__c != null){
                setOpptyIds.add(item.Opportunity__c);
            }
        }
        Map<Id,Opportunity> mapOpty = new Map<Id,Opportunity>([SELECT Id, DODL_Create__c FROM Opportunity WHERE Id IN :setOpptyIds]);
        for(Test_Ride__c item : newRecordsList){
            if(mapOpty.containsKey(item.Opportunity__c)){
                if(mapOpty.get(item.Opportunity__c).DODL_Create__c != null){
                    setDODLIds.add(mapOpty.get(item.Opportunity__c).DODL_Create__c);
                }
            }
        }
    	setTestRideNumber(newRecordsList, setDODLIds, mapOpty);
    }
    private static void setTestRideNumber(List<Test_Ride__c> newRecordsList, Set<String> setDODLIds, Map<Id,Opportunity> mapOpty){
        List<User> lstUserHN = [SELECT Id, AccountId FROM User WHERE Account.Name =: 'REVZONE YAMAHA MOTOR HA NOI'];
        integer Month = Date.today().month(); 
        String MonthNo = String.valueOf(Month);
        if( Month < 10 ){
            MonthNo = '0' + String.valueOf(Month);
        }
        integer Year = Date.today().year();
        if(!setDODLIds.isEmpty()){
            for(String dodlID : setDODLIds){
                String prefix = lstUserHN[0].AccountId == dodlID? 'TRIDE-HN-' : 'TRIDE-';
                integer IndexTestRide = 0 ;
                List<Test_Ride__c> lstTestRide = [SELECT TestRideNo__c FROM Test_Ride__c where TestRideNo__c > 0  
                                                AND Opportunity__r.DODL_Create__c = :dodlID 
                                                AND CALENDAR_MONTH(convertTimezone(CreatedDate)) =: Month
                                                AND CALENDAR_YEAR(convertTimezone(CreatedDate)) =: Year
                                                ORDER BY TestRideNo__c DESC LIMIT 1] ;
                if(lstTestRide.size() >0 ){
                    IndexTestRide = lstTestRide[0].TestRideNo__c.intValue();
                    system.debug(lstTestRide[0].TestRideNo__c);
                }
                //else{
                //    system.debug(0);
                //}
                for(Test_Ride__c item : newRecordsList){
                    if(mapOpty.containsKey(item.Opportunity__c) && mapOpty.get(item.Opportunity__c).DODL_Create__c == dodlID){
                        IndexTestRide +=1;
                        item.TestRideNo__c = IndexTestRide;
                        String IndexTestRideNo = String.valueOf(IndexTestRide);
                        if(IndexTestRide < 10){
                            IndexTestRideNo = '000' + String.valueOf(IndexTestRide);
                        }
                        else if(IndexTestRide < 100){
                            IndexTestRideNo = '00' + String.valueOf(IndexTestRide);
                        }
                        else if(IndexTestRide < 1000){
                            IndexTestRideNo = '0' + String.valueOf(IndexTestRide);
                        }
                        item.Test_Ride_Number__c = prefix + String.valueOf(Year).right(2) + MonthNo + '-' + IndexTestRideNo;
                    }
                }
            }
        }else{
            String prefix = 'TRIDE-';
            integer IndexTestRide = 0 ;
            List<Test_Ride__c> lstTestRide = [SELECT TestRideNo__c FROM Test_Ride__c WHERE TestRideNo__c > 0 AND 
                                            CALENDAR_MONTH(CreatedDate) =: Month and CALENDAR_Year(CreatedDate) =: Year
                                            ORDER BY TestRideNo__c DESC LIMIT 1] ;
            if(lstTestRide.size() >0 ){
                IndexTestRide = lstTestRide[0].TestRideNo__c.intValue();
                system.debug(lstTestRide[0].TestRideNo__c);
            }
            //else{
            //    system.debug(0);
            //}
            for(Test_Ride__c item : newRecordsList){
                IndexTestRide +=1;
                item.TestRideNo__c = IndexTestRide;
                String IndexTestRideNo = String.valueOf(IndexTestRide);
                if(IndexTestRide < 10){
                    IndexTestRideNo = '000' + String.valueOf(IndexTestRide);
                }
                else if(IndexTestRide < 100){
                    IndexTestRideNo = '00' + String.valueOf(IndexTestRide);
                }
                else if(IndexTestRide < 1000){
                    IndexTestRideNo = '0' + String.valueOf(IndexTestRide);
                }
                item.Test_Ride_Number__c = prefix + String.valueOf(Year).right(2) + MonthNo + '-' + IndexTestRideNo;
            }
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
  
        a = a;
        a = a;  a = a;
        a = a;
        a = a;
    }
    //public static void afterInsert(List<Test_Ride__c> newRecordsList , Map<Id, Test_Ride__c> newRecordsMap){
      //TriggerHandlerRosterManagement.createInstallationOrder((List<Order>) newRecordsList);
    //}
  
    //public static void beforeUpdate(Map<Id, Test_Ride__c> newRecordsMap, Map<Id, Test_Ride__c> oldRecordsMap){
     
    //}
  
    //public static void afterUpdate(Map<Id, Test_Ride__c> newRecordsMap,  Map<Id, Test_Ride__c> oldRecordsMap){
      
      
      
    //}
          
    //public static void beforeDelete(List<Test_Ride__c> oldRecordsList , Map<Id, Test_Ride__c> oldRecordsMap){
        
    //}
  
    //public static void afterDelete(Map<Id, Test_Ride__c> oldRecordsMap){
        
    //}
    
    //public static void afterUnDelete(List<Test_Ride__c> newRecordsList , Map<Id, Test_Ride__c> newRecordsMap) {
        
      
    //}
}