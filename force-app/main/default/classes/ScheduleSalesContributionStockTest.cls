@isTest
public class ScheduleSalesContributionStockTest {
	@isTest static void onAfterUpsert() {
        System.schedule('Test Batch Caclculate Inventory Item For KPI', '0 0 23 * * ?', new ScheduleSalesContributionStock());
    }
}