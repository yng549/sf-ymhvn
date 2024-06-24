/*
	This schedule will run every day at 4AM

    This class will start all the batch job to send sms every day
    Check the user timezone that run this schedule, we want to run this in Vietnam timezone (GMT+7)

    System.schedule('Sync DMS PSI', '0 30 6 * * ?', new ScheduleSyncDMSPSI());
*/
public class ScheduleSyncDMSPSI implements Schedulable{
	public void execute(SchedulableContext ctx) {
        Database.executeBatch(new BatchPSICRMToDMS(false, null));
   	}
}