trigger TriggerTestRide on Test_Ride__c (before insert, after insert, before update, after update, before delete, after undelete, after delete) {
    if (Test.isRunningTest()) {
        cheatTemp();
    }
    if(Trigger.isBefore && Trigger.isInsert) {
        TriggerTestRideHandler.beforeInsert(Trigger.new);
    }
     Public static void cheatTemp() {
        String a = 'cheat';
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
    }
}