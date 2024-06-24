/*
	This schedule will run every day at 7:30AM

    This class will start all the batch job to send sms every day
    Check the user timezone that run this schedule, we want to run this in Vietnam timezone (GMT+7)

    System.schedule('Auto Sync JobPrice HCM DMS', '0 30 6 * * ?', new ScheduleServiceJobPrice());
*/
public class ScheduleServiceJobPrice implements Schedulable{
	public void execute(SchedulableContext ctx) {
        // if api current page lastest empty data, schedule not next proccess
        Date dateFrom = Date.today().addDays(-1);
        Date dateTo = Date.today().addDays(-1);
        system.enqueueJob(new SyncServiceJobPriceDMS(dateFrom, dateTo, 'RY01'));
   	}
}