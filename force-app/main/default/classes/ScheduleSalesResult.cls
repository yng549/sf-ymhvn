/*
 *  System.schedule('Sales result stock DO', '0 0 06 * * ?', new ScheduleSalesResult());
*/
global class ScheduleSalesResult implements Schedulable {
    global void execute(SchedulableContext ctx) {
        createReportSalesResult();
    }
    public void createReportSalesResult() {
        Date dateon = Date.Today();
        CreateSaleReportDashboard.getSaleReportDashboard(string.valueOf(dateon.year()), 'RY01A', true);
        CreateSaleReportDashboard.getSaleReportDashboard(string.valueOf(dateon.year()), 'RY02A', true);
    }
}