/*
 *  System.schedule('Create report sales contribution stock DO', '0 0 6 * * ?', new ScheduleSalesContributionStock());
*/
global class ScheduleSalesContributionStock implements Schedulable {
	global void execute(SchedulableContext ctx) {
        createReportSalesResult();
    }
    public static void  createReportSalesResult() {
        Date dateon = Date.Today();
        Database.executebatch(new BatchGenSaleStockProduct('RY01A', dateon.year()), 1);
        Database.executebatch(new BatchGenSaleStockProduct('RY02A', dateon.year()), 1);
    }
}