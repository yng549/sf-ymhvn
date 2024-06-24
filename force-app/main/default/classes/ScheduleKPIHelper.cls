global class ScheduleKPIHelper implements Schedulable	{
	global void execute(SchedulableContext ctx) { 
        
        Date now = Date.today();
        Decimal month = now.month();
        Decimal year = now.year();
        
        List<Monthly_KPI__c> listMonthKPI = [Select Id from Monthly_KPI__c 
                                             where Is_Lock__c = false And Is_Calculating__c = false
                                             AND DO_DL__r.DO_DL_Code__c = 'RY01A - SG'
                                             ORDER BY CreatedDate ASC  ];     
               
        if(!listMonthKPI.isEmpty())
        {
            Monthly_KPI__c monthlyKPI = listMonthKPI[0];
            monthlyKPI.Is_Calculating__c = true;
            update monthlyKPI;
            
            Database.executeBatch(new BatchDeleteOldEmployeeDetail(monthlyKPI.Id), 1000);
        }
    }
    
    global static void startSchedule(String scheduleName)
    {
        System.schedule(scheduleName, '0 0 0 * * ?', new ScheduleKPIHelper());
    }
}