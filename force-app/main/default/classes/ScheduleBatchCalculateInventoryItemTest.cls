@isTest
public class ScheduleBatchCalculateInventoryItemTest {
	@isTest
    static void test()
    {
        System.schedule('Test Batch Caclculate Invenetory Item For KPI', '0 0 23 * * ?', new ScheduleBatchCalculateInventoryItem());
    }
}