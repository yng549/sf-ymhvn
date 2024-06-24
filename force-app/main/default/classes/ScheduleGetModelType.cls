/*
	This schedule will run every day at 6AM

    This class will start all the batch job to send sms every day
    Check the user timezone that run this schedule, we want to run this in Vietnam timezone (GMT+7)

    System.schedule('Auto update model type product', '0 0 7 * * ?', new ScheduleGetModelType());
*/
public with sharing class ScheduleGetModelType implements Schedulable {
    public void execute(SchedulableContext ctx){
        system.enqueueJob(new APIGetModelTypeBike('RY01'));
    }
        
}