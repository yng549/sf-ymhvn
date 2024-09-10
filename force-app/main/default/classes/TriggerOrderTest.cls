@IsTest(SeeAllData=true)
public class TriggerOrderTest {
    private static testMethod void testMethod1() {
        test.startTest();
        TriggerOrder.cheatTemp();
        TriggerHandlerInventoryTransactionItems.cheatTemp();
        test.stopTest();
    }
}
