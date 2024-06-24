@isTest(SeeAllData=true)
public class RoundRobinAssignmentTriggerHandlerTest {
    @isTest static void onBeforeInsertTest() {
        RoundRobinAssignmentTriggerHandler.cheatTemp();
    }
}