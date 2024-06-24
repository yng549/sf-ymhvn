/*
	This schedule will run every day at 7:30AM

    This class will start all the batch job to send sms every day
    Check the user timezone that run this schedule, we want to run this in Vietnam timezone (GMT+7)

    System.schedule('Auto Sync JobPrice HN', '0 30 6 * * ?', new ScheduleServiceJobPriceHN());
*/
public class ScheduleServiceJobPriceHN implements Schedulable{
	public void execute(SchedulableContext ctx) {
        // if api current page lastest empty data, schedule not next proccess
        Date dateFrom = Date.today().addDays(-1);
        Date dateTo = Date.today().addDays(-1);
        system.enqueueJob(new SyncServiceJobPriceDMS(dateFrom, dateTo, 'RY02'));
   	}
}