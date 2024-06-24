/*
	This schedule will run every day at 6AM

    This class will start all the batch job to send sms every day
    Check the user timezone that run this schedule, we want to run this in Vietnam timezone (GMT+7)

    System.schedule('Auto Sync MCInvenory HN', '0 0 6 * * ?', new ScheduleMCInventoryHN());
*/
public class ScheduleMCInventoryHN implements Schedulable{
	public void execute(SchedulableContext ctx) {
        List<PageSize_API__c> currentPage = [SELECT Current_Page__c, Id, End_Index__c, Is_Empty_Return__c
                                             FROM PageSize_API__c 
                                             WHERE Name = 'mcinventory RY02' AND Createddate = Today
                                             ORDER BY Current_Page__c DESC];
        // if api current page lastest empty data, schedule not next proccess
        if (!currentPage.isEmpty() && currentPage[0].Is_Empty_Return__c) return;
        
        Date dateFrom = Date.today().addDays(-1);
        Date dateTo = Date.today().addDays(-1);
        system.enqueueJob(new APIDMSMcInventory(dateFrom, dateTo, 200, currentPage.isEmpty() ? 0 : Integer.valueOf(currentPage[0].End_Index__c) + 1, 0, 0, 'RY02'));
   	}
}