// System.schedule('ScheduleAfterSalePCA Everyday at 1:00', '0 0 1 * * ?', new ScheduleAfterSalePCA());
public without sharing class ScheduleAfterSalePCA implements Schedulable{
    public void execute(SchedulableContext sc){
        Database.executeBatch(new BatchAfterSalePCA());
    }
   
}