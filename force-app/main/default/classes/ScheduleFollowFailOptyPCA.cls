// System.schedule('ScheduleFollowFailOptyPCA Everyday at 1:00', '0 0 1 * * ?', new ScheduleFollowFailOptyPCA());
public with sharing class ScheduleFollowFailOptyPCA implements Schedulable{
    public void execute(SchedulableContext sc){
        Database.executeBatch(new BatchFollowFailOptyPCA());
    }
}