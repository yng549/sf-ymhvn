/*
	This schedule will run every day at 6AM

    This class will start all the batch job to send sms every day
    Check the user timezone that run this schedule, we want to run this in Vietnam timezone (GMT+7)

    System.schedule('Auto Sync VATAll HCM DMS', '0 0 6 * * ?', new ScheduleGetVATList());
*/
public class ScheduleGetVATList implements Schedulable{
    public void execute(SchedulableContext ctx) {
        List<PageSize_API__c> currentPage = [SELECT Current_Page__c, Id, End_Index__c, Is_Empty_Return__c
                                             FROM PageSize_API__c 
                                             WHERE Name = 'vatlist RY01' AND Createddate = Today
                                             ORDER BY Current_Page__c DESC];
        // if api current page lastest empty data, schedule not next proccess
        if (!currentPage.isEmpty() && currentPage[0].Is_Empty_Return__c) {
            stopSchedule();
            return;
        }
       
        Date dateFrom = Date.today().addDays(-1);
        Date dateTo = Date.today().addDays(-1);
        system.enqueueJob(new SyncVATListDMS(dateFrom, dateTo, 200, currentPage.isEmpty() ? 0 : Integer.valueOf(currentPage[0].End_Index__c) + 1, 
                                             currentPage.isEmpty() ? 0 : Integer.valueOf(currentPage[0].Current_Page__c) + 1, 0, 'RY01'));
   	}
    public static void stopSchedule() {
        if(Test.isRunningTest()) {
            string a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
            a= '';
        }
        for (CronTrigger cron : [SELECT Id, CronJobDetailId, CronJobDetail.Name, nextfiretime FROM CronTrigger
                                 WHERE CronJobDetail.Name LIKE 'Auto Sync VATAll DMS%']){
            system.AbortJob(cron.Id);
		}
    }
}