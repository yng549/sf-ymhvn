/*
	This schedule will run every day at 4AM

    This class will start all the batch job to send sms every day
    Check the user timezone that run this schedule, we want to run this in Vietnam timezone (GMT+7)

    System.schedule('Scanup data order survey', '0 0 8 1 * * *', new ScheduleSurveySMS());
*/
public class ScheduleSurveySMS implements Schedulable{
	public void execute(SchedulableContext ctx) {
        Database.executeBatch(new BatchSurveySending());
   	}
}