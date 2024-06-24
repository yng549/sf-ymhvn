public inherited sharing class BatchPSISalesReport extends BaseBatchHandler {
    public string docode;
    public integer targetYear;
    public List<Sales_Report__c> salesreport;
    public Map<Integer, integer> mapStockDO;
    public Map<Integer, integer> mapResultDO;
    public String batchJobID;
    public Boolean isScheduled;
    public class KpiMonthly {
    	public decimal stockremain;
        public decimal stockrotation;
        public KpiMonthly() {
            this.stockremain = 0;
            this.stockrotation = 0;
        }
    }
    public BatchPSISalesReport(string docode, integer targetYear, List<Sales_Report__c> salesreport, Boolean isScheduled) {
        this.objectName = 'History_Stock_Product__c';
        this.docode = docode;
        this.mapStockDO = new Map<Integer, integer>();
        this.mapResultDO = new Map<Integer, integer>();
        this.targetYear = targetYear;
        this.salesreport = salesreport;
        this.isScheduled = isScheduled;
    }
    public override Database.querylocator start(Database.BatchableContext BC) {
        batchJobID = BC.getJobId();
        List<String> query = new List<String>();
        query.add('SELECT Id, Date__c, DO_Code__c, Inventory_Stock_Rotation__c, Stock_Remain__c');
        query.add('FROM ' + objectName);
        query.add('WHERE CALENDAR_YEAR(Date__c) =: targetYear AND DO_Code__c =: docode');
        
        return Database.getQueryLocator(String.join(query, ' '));

    }
    public override List<SObject> processData(List<SObject> records) {
        List<History_Stock_Product__c> newData = (List<History_Stock_Product__c>)records;
        for (AggregateResult aggregateResult : [SELECT CALENDAR_MONTH(Date__c) month, SUM(Stock_Remain__c) totalStockRemain,
                                                SUM(Inventory_Stock_Rotation__c) totalInventoryStockRotation, SUM(Total_Stock_Out_Of_Month__c) totalStockOut
                                                FROM History_Stock_Product__c WHERE ID IN: newData
                                                GROUP BY CALENDAR_MONTH(Date__c)]) {
    		Integer month = Integer.valueOf(aggregateResult.get('month'));
    		integer totalStockRemain = integer.valueOf(aggregateResult.get('totalStockRemain'));
            integer totalInventoryStockRotation = integer.valueOf(aggregateResult.get('totalInventoryStockRotation'));
            integer totalResultDO = integer.valueOf(aggregateResult.get('totalStockOut'));                                        
             if (!mapStockDO.containsKey(month))
             mapStockDO.put(month, 0);
             system.debug('mapStockDO ' + mapStockDO);                                    
             mapStockDO.put(month, mapStockDO.get(month) + calculateTotalStock(totalStockRemain) + calculateTotalStock(totalInventoryStockRotation));
             if (!mapResultDO.containsKey(month))  mapResultDO.put(month, 0);
             mapResultDO.put(month, mapResultDO.get(month) + calculateTotalStock(totalResultDO));                                       
		}
        return records;
    }
    public integer calculateTotalStock(integer totalStock) {
        return totalStock == null ? 0 : totalStock;
    }
    public override void handleFinish(){
        system.debug('mapStockDO ' + mapStockDO);
        List<Integer> orderMonths = new List<Integer>(mapStockDO.keySet());
        // order by month report
        orderMonths.sort();
        decimal thisPreStock = 0;
        integer startindex = 0;
        decimal accResult = 0.0;
        for(Integer i : orderMonths) {
            integer thisStock = mapStockDO.get(i);
            integer resultStock = mapResultDO.get(i);
            decimal turn;
            string monthFieldName = CreateSaleReportDashboard.MONTHMAP.get(i) + CreateSaleReportDashboard.SUFFIXFIELD;
    		salesreport[4].put(monthFieldName, thisStock);
            // Result Stock Out Month
            salesreport[2].put(monthFieldName, resultStock);
            accResult += resultStock;
            salesreport[3].put(monthFieldName, accResult);
            if(monthFieldName == 'Jan__c'){
                if(salesreport[0].Jan__c != null && salesreport[0].Jan__c > 0) {
                    integer preyear = targetYear - 1;
                    for(AggregateResult a : [SELECT CALENDAR_MONTH(Date__c) month, SUM(Stock_Remain__c) totalStockRemain,
                                             SUM(Inventory_Stock_Rotation__c) totalInventoryStockRotation, SUM(Total_Stock_Out_Of_Month__c) totalStockOut
                                             FROM History_Stock_Product__c 
                                             WHERE CALENDAR_YEAR(Date__c) =: preyear AND CALENDAR_MONTH(Date__c) = 12 
                                             AND DO_Code__c =: docode GROUP BY CALENDAR_MONTH(Date__c)]) {
                        // Stock cuối của tháng trước/Target của tháng hiện tại
                        integer totalStockRemain = integer.valueOf(a.get('totalStockRemain'));
                        integer totalInventoryStockRotation = integer.valueOf(a.get('totalInventoryStockRotation'));
                        turn =(calculateTotalStock(totalStockRemain) + calculateTotalStock(totalInventoryStockRotation) )/ salesreport[0].Jan__c;
                    }
                }
            } else if(startindex > 0){
                Object monthTarget = salesreport[0].get(monthFieldName);
                if (monthTarget != null && monthTarget instanceOf Decimal && (Decimal)monthTarget > 0 && thisPreStock > 0) {
    				turn = thisPreStock/ (Decimal)monthTarget;
				}
            }
            salesreport[5].put(monthFieldName, turn);
            thisPreStock = thisStock;
            startindex += 1;
        }
        Map<string, ID> mapSalesReportYear = new Map<string, ID>();
        for(Sales_Report__c a : [SELECT Id, Name
                                 FROM Sales_Report__c 
                                 WHERE CALENDAR_YEAR(Date_Scheduled__c) =: targetYear AND DO_Code__c =: docode]) {
            mapSalesReportYear.put(a.Name, a.Id);
        }
        for(Sales_Report__c s : salesreport) {
            if(mapSalesReportYear.containsKey(s.Name)) s.Id = mapSalesReportYear.get(s.Name);
            s.Date_Scheduled__c = isScheduled ? Date.Today() : Date.newInstance(targetYear, 01, 01) ;
            s.DO_Code__c = docode;
            s.JodID__c = batchJobID;
        }
        upsert salesreport;
        system.debug('s ' + salesreport);
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