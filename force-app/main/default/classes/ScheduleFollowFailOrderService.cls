// System.schedule('ScheduleFollowFailOrderService Everyday at 1:00', '0 0 1 * * ?', new ScheduleFollowFailOrderService());
public with sharing class ScheduleFollowFailOrderService implements Schedulable{
    public void execute(SchedulableContext sc){
        Database.executeBatch(new BatchFollowFailOrderService());
    }
}