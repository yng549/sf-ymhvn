public class TriggerHandlerSalesReport {
    public static final String SUFFIXFIELD = '__c';
    public static final Map<Integer, String> MONTHMAP = new Map<Integer, String>{
        1 => 'Jan',
        2 => 'Feb',
        3 => 'Mar',
        4 => 'Apr',
        5 => 'May',
        6 => 'Jun',
        7 => 'Jul',
        8 => 'Aug',
        9 => 'Sep',
        10 => 'Oct',
        11 => 'Nov',
        12 => 'Dec'
    };
    public static void onAfterInsert(List<Sales_Report__c> newData) {
        generateSalesReportMonth(newData);
    }    
    public static void onBeforeUpdate(List<Sales_Report__c> newData, Map<Id, Sales_Report__c> newMap, Map<Id, Sales_Report__c> oldMap) {
        generateSalesReportMonth(newData);
    }
    private static void generateSalesReportMonth(List<Sales_Report__c> newData) {
        List<Sales_Report_Month__c> relateChilds = new List<Sales_Report_Month__c>();
        for(Sales_Report__c s : newData) {
            Integer yearValue = s.Date_Scheduled__c.year();
            for(Integer i :MONTHMAP.keySet()) {
				string monthFieldName = MONTHMAP.get(i) + SUFFIXFIELD;
                Date monthDate = Date.newInstance(yearValue, i, 01);
                Sales_Report_Month__c sm = new Sales_Report_Month__c();
                sm.Value__c = s.get(monthFieldName) != null ? (Decimal)s.get(monthFieldName) : null ;
                sm.DO_Code__c = s.DO_Code__c;
                sm.Name = s.Name;
				sm.Sales_Report__c = s.Id;
                sm.DateScheduled__c = monthDate;
                sm.External_Key__c = MONTHMAP.get(i) + '/' + s.Name + '/' + s.DO_Code__c + '/' + string.valueOf(monthDate);
                relateChilds.add(sm);
            } 
        }
        upsert relateChilds External_Key__c;
    }
}