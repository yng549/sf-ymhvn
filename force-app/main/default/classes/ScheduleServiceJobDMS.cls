/*
	This schedule will run every day at 4AM

    This class will start all the batch job to send sms every day
    Check the user timezone that run this schedule, we want to run this in Vietnam timezone (GMT+7)

    System.schedule('Auto Sync Service job HCM DMS', '0 30 6 * * ?', new ScheduleServiceJobDMS());
*/
public class ScheduleServiceJobDMS implements Schedulable{
	public void execute(SchedulableContext ctx) {
		List<PageSize_API__c> currentPage = [SELECT Current_Page__c, Id, End_Index__c, Is_Empty_Return__c
                                             FROM PageSize_API__c 
                                             WHERE Name = 'servicejobinformation RY01' AND Createddate = Today
                                             ORDER BY Current_Page__c DESC];
        // if api current page lastest empty data, schedule not next proccess
        if (!currentPage.isEmpty() && currentPage[0].Is_Empty_Return__c) return;
        
        Date dateFrom = Date.today().addDays(-1);
        Date dateTo = Date.today().addDays(-1);
        system.enqueueJob(new SyncServiceJobDMS(dateFrom, dateTo, 200, currentPage.isEmpty() ? 0 : Integer.valueOf(currentPage[0].End_Index__c) + 1, 0, 0, 'RY01'));
   	}
}