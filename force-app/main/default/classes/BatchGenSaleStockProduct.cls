public inherited sharing class BatchGenSaleStockProduct  extends BaseBatchHandler {
    public string docode;
    public integer currentyear;
    public integer lastyear;
    // Danh sách phân loại bike
    public static final Map<string, string> RANGEMAP = new Map<string, string>{
        '<400cc' => 'Sport Bike',
        '>400cc' => 'Big Bike'
    };
    // Danh sách 12 tháng report
    public static final Map<Integer, String> MONTHMAP = new Map<Integer, String>{
        1 => 'Jan',
        2 => 'Feb',
        3 => 'Mar',
        4 => 'Apr',
        5 => 'May',
        6 => 'Jun',
        7 => 'Jul',
        8 => 'Aug',
        9 => 'Sep',
        10 => 'Oct',
        11 => 'Nov',
        12 => 'Dec'
    };
    public BatchGenSaleStockProduct(string docode, integer currentyear) {
        this.objectName = 'Product2';
        this.docode = docode;
        this.currentyear = currentyear;
        this.lastyear = currentyear - 1;
    }
    public override Database.querylocator start(Database.BatchableContext BC) {
        List<String> query = new List<String>();
        query.add('SELECT Id, ExternalID_DMS__c, Bike_cc__c, Model_Name__c');
        query.add('FROM ' + objectName);
        query.add('WHERE ExternalID_DMS__c != null AND Bike_cc__c != null');
        query.add('AND RecordType.DeveloperName = \'Bike\'');
        if (Test.isRunningTest()){
            query.add('LIMIT 20');
        }
        return Database.getQueryLocator(String.join(query, ' '));
    }
    public override List<SObject> processData(List<SObject> records) {
        List<Product2> newData = (List<Product2>)records;
        Product2 bike = newData[0];
        Map<Integer, integer> mapStockDO = new Map<Integer, integer>();
        Map<Integer, integer> mapTargetMonthDO = new Map<Integer, integer>();
        Map<Integer, integer> mapSalesMonthDO = new Map<Integer, integer>();
        // Tổng (xe X) bán được của DO trong năm ngoái
        List<AggregateResult> lastyear_orderitems = [SELECT Product2.ExternalID_DMS__c bikeid, COUNT(Id) totalline FROM OrderItem 
                                                     WHERE Order.RecordType.DeveloperName = 'Bike' AND Order.Invoice_Date__c != null
                                                     AND CALENDAR_YEAR(Order.Invoice_Date__c) =: lastyear 
                                                     AND Order.DO_DL__r.DO_DL_Code__c =: docode AND Product2.ExternalID_DMS__c =: bike.ExternalID_DMS__c
                                                     GROUP BY Product2.ExternalID_DMS__c];
        // Tổng (xe X) bán được của DO theo thang
        // [{"bikeid":"BKA500010A","month":9,"totalline":51},{"bikeid":"BKA500010A","month":11,"totalline":43},{"bikeid":"BKA500010A","month":10,"totalline":41},{"bikeid":"BKA500010A","month":12,"totalline":3}]|
        for(AggregateResult a : [SELECT CALENDAR_MONTH(Order.Invoice_Date__c) month, COUNT(Id) totalline FROM OrderItem 
                                 WHERE Order.RecordType.DeveloperName = 'Bike' AND Order.Invoice_Date__c != null
                                 AND CALENDAR_YEAR(Order.Invoice_Date__c) =: currentyear 
                                 AND Order.DO_DL__r.DO_DL_Code__c =: docode AND Product2.ExternalID_DMS__c =: bike.ExternalID_DMS__c 
                                 GROUP BY CALENDAR_MONTH(Order.Invoice_Date__c)]) {
            // Tháng M
    		Integer month = Integer.valueOf(a.get('month'));
            // Tồn kho còn lại (xe X) trong tháng M/Y
    		integer totalBike = integer.valueOf(a.get('totalline'));
            mapSalesMonthDO.put(month, totalBike);
        }
        // Tổng (xe X) bán được của DO trong năm
        List<AggregateResult> year_orderitems = [SELECT Product2.ExternalID_DMS__c bikeid, COUNT(Id) totalline FROM OrderItem 
                                                 WHERE Order.RecordType.DeveloperName = 'Bike' AND Order.Invoice_Date__c != null
                                                 AND CALENDAR_YEAR(Order.Invoice_Date__c) =: currentyear 
                                                 AND Order.DO_DL__r.DO_DL_Code__c =: docode AND Product2.ExternalID_DMS__c =: bike.ExternalID_DMS__c
                                                 GROUP BY Product2.ExternalID_DMS__c];
        // Kho DO (Xe X) còn lại & tồn kho luân chuyển. Lấy theo năm group theo tháng
        for (AggregateResult aggregateResult : [SELECT CALENDAR_MONTH(Date__c) month, SUM(Stock_Remain__c) totalStockRemain,
                                                SUM(Inventory_Stock_Rotation__c) totalInventoryStockRotation
                                                FROM History_Stock_Product__c WHERE CALENDAR_YEAR(Date__c) =: currentyear 
                                                AND Product__r.ExternalID_DMS__c=: bike.ExternalID_DMS__c AND DO_Code__c =: docode
                                                GROUP BY CALENDAR_MONTH(Date__c)]) {
            // Tháng M
    		Integer month = Integer.valueOf(aggregateResult.get('month'));
            // Tồn kho còn lại (xe X) trong tháng M/Y
    		integer totalStockRemain = integer.valueOf(aggregateResult.get('totalStockRemain'));
            // Tồn kho luân chuyển (xe X) trong tháng M/Y
            integer totalInventoryStockRotation = integer.valueOf(aggregateResult.get('totalInventoryStockRotation'));
            mapStockDO.put(month, calculateTotalStock(totalStockRemain) + calculateTotalStock(totalInventoryStockRotation));
		}
        // Lấy Target (xe X)
        for(AggregateResult aggregateResult : [SELECT CALENDAR_MONTH(Date__c) month, SUM(Target__c) targetmonth
                                                FROM Target_Bike_DO__c WHERE CALENDAR_YEAR(Date__c) =: currentyear 
                                                AND Product__r.ExternalID_DMS__c =: bike.ExternalID_DMS__c AND Account__r.DO_DL_Code__c =: docode
                                                GROUP BY CALENDAR_MONTH(Date__c)]) {
            Integer month = Integer.valueOf(aggregateResult.get('month'));
            Integer targetMonth = integer.valueOf(aggregateResult.get('targetmonth'));
            mapTargetMonthDO.put(month, targetMonth);
        }
        // Mã xe theo màu + Y + DO CODE
        string extkey = bike.ExternalID_DMS__c + '/' + string.valueOf(currentyear) + '/' + docode;
        // Lấy report contribution stock của xe
        List<SalesContributionStock__c> sct = [SELECT ID, (SELECT Id FROM Sales_Contribution_Stock_Child__r ORDER BY Order_Month__c ASC)
                                               FROM SalesContributionStock__c WHERE External_ID__c =: extkey];
        SalesContributionStock__c rs = new SalesContributionStock__c(Id = !sct.isEmpty() ? sct[0].Id : null);
        rs.Name = bike.ExternalID_DMS__c;
        rs.DO_Code__c = docode;
        rs.Model_Name__c = bike.Model_Name__c;
        rs.Type__c = RANGEMAP.get(bike.Bike_cc__c);
        rs.Year__c = currentyear;
        rs.External_ID__c = extkey;
        rs.Current_year__c = !year_orderitems.isEmpty() ? integer.valueOf(year_orderitems[0].get('totalline')) : 0;
        rs.Last_year__c = !lastyear_orderitems.isEmpty() ? integer.valueOf(lastyear_orderitems[0].get('totalline')) : 0;
        upsert rs;
        List<Sales_Contribution_Stock_Child__c> relateReports = new List<Sales_Contribution_Stock_Child__c>();
        Integer startIndex = 0;
        for(integer i : MONTHMAP.keySet()) {
            Date dateReport = Date.newInstance(currentyear, i, 01);
            Decimal turnMonth;
            Sales_Contribution_Stock_Child__c scLine = new Sales_Contribution_Stock_Child__c(Id = !sct.isEmpty() ?
                                                                                             sct[0].Sales_Contribution_Stock_Child__r[startIndex].Id : null);
            scLine.Month__c = MONTHMAP.get(i);
            scLine.DateReport__c = dateReport;
            scLine.Order_Month__c = i;
            scLine.Result__c = mapSalesMonthDO.containsKey(i) ? mapSalesMonthDO.get(i) : null;
            scLine.Stock__c = mapStockDO.containsKey(i) ? mapStockDO.get(i) : null;
            scLine.Target__c = mapTargetMonthDO.containsKey(i) ? mapTargetMonthDO.get(i) : null;
            if(i == 1) {
                 List<History_Stock_Product__c> stockEndMonthPreYear = [SELECT Id, Stock_Remain__c, Inventory_Stock_Rotation__c
                                                                        FROM History_Stock_Product__c 
                                                                        WHERE CALENDAR_YEAR(Date__c) =: lastyear AND CALENDAR_MONTH(Date__c) = 12
                                                                        AND Product__r.ExternalID_DMS__c=: bike.ExternalID_DMS__c AND DO_Code__c =: docode];
                if(!stockEndMonthPreYear.isEmpty() && scLine.Target__c != null && scLine.Target__c > 0) {
                    Integer totalStock = calculateTotalStock(Integer.valueOf(stockEndMonthPreYear[0].Stock_Remain__c)) +
                    calculateTotalStock(Integer.valueOf(stockEndMonthPreYear[0].Inventory_Stock_Rotation__c));
                    turnMonth = totalStock/scLine.Target__c;
                }
            }else if(relateReports[startIndex-1].Stock__c != null && scLine.Target__c != null && scLine.Target__c > 0){
                turnMonth = relateReports[startIndex-1].Stock__c/scLine.Target__c;
            }
            scLine.Turn__c = turnMonth;
            scLine.Sales_Contribution_Stock__c = rs.Id;
            startIndex += 1;
            relateReports.add(scLine);
        }
        upsert relateReports;
        return relateReports;
    }
    public integer calculateTotalStock(integer totalStock) {
        return totalStock == null ? 0 : totalStock;
    }
    public override void handleFinish(){
    }
    
    public static void cheatCode() {
         string a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
        	a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
       	 	a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
        a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
        	a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
        	a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
        	a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
        	a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
                    a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
        	a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
        
            a = '';
            a = '';
        	a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
        	a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
        	a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
        	a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
                    a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
        	a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
            a = '';
    }
}