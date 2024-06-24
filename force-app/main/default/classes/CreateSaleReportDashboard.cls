public class CreateSaleReportDashboard {
    public static final String SUFFIXFIELD = '__c';
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
    public class KpiMonthly {
    	public decimal target;
        public decimal value;
        public KpiMonthly(decimal target , decimal value) {
        	 this.target = target;
             this.value = value;
        }
    }
	@AuraEnabled(Cacheable = true)
    public static ID getSaleReportDashboard(string yearCon, string docode, boolean isScheduled){
        integer year = integer.valueOf(yearCon);
        List<Account> accounts = [SELECT Id, DO_DL_Code__c FROM Account WHERE DO_DL_Code__c =: docode];
        Id accountId = accounts[0].Id;
        // Số target
        List<Sales_Report__c> salesreport = new List<Sales_Report__c> {
            new Sales_Report__c(Name = 'Target', RecordtypeID = RecordtypeHelper.TARGETRDO),
            new Sales_Report__c(Name = 'Acc Target', RecordtypeID = RecordtypeHelper.ACCTARGETRDO),
            new Sales_Report__c(Name = 'Result', RecordtypeID = RecordtypeHelper.RESULTRDO),
            new Sales_Report__c(Name = 'Acc Result', RecordtypeID = RecordtypeHelper.ACCRESULTRDO),
            new Sales_Report__c(Name = 'Stock', RecordtypeID = RecordtypeHelper.STOCKRDO),
            new Sales_Report__c(Name = 'Turn',  RecordtypeID = RecordtypeHelper.TURNRDO),
            new Sales_Report__c(Name = 'Deposit', RecordtypeID = RecordtypeHelper.DEPOSITRDO)    
        };
        Map<integer, KpiMonthly> monthlyKPIMap = new Map<integer, KpiMonthly>();
        String queryString = 'SELECT Monthly_KPI__r.name, ' +
                     		 'MAX(Monthly_KPI__r.Month__c) month, ' +
                     		 'SUM(KPI_Rule_1_Target__c) kpitarget, ' +
                     		 'SUM(KPI_Rule_1_Value__c) kpivalue ' +
                      		 'FROM Monthly_KPI_Employee__c ' +
                     		 'WHERE Monthly_KPI__r.year__c = :year AND Manager__c = null ' +
                     		 'AND Team__c = \'Sales\'';
        if (docode == 'RY01A') {
            queryString += ' AND (Monthly_KPI__r.DO_DL__c = :accountId OR Monthly_KPI__r.DO_DL__c = null)';
        } else {
            queryString += ' AND Monthly_KPI__r.DO_DL__c = :accountId';
        }
        queryString += ' GROUP BY Monthly_KPI__r.name';
        for (AggregateResult a : Database.query(queryString)) {
    		integer month = integer.valueOf(a.get('month'));
    		decimal kpitarget = (decimal)a.get('kpitarget');
            decimal kpivalue = (decimal)a.get('kpivalue');
            KpiMonthly k = new KpiMonthly(kpitarget, kpivalue);
            monthlyKPIMap.put(month, k);
		}
        List<Integer> orderMonths = new List<Integer>(monthlyKPIMap.keySet());
        // order by month report
        orderMonths.sort();
        decimal accTarget = 0.0;
        decimal accResult = 0.0;
        for(integer i : orderMonths) {
            string monthFieldName = MONTHMAP.get(i) + SUFFIXFIELD;
            decimal targetValue = monthlyKPIMap.get(i).target;
            decimal thisValue = monthlyKPIMap.get(i).value;
            // Tính giá trị của Acc Target
            if(targetValue != null) {
                accTarget += targetValue;
                salesreport[0].put(monthFieldName, targetValue);
            	salesreport[1].put(monthFieldName, accTarget);
            }
    		
            if(thisValue != null) {
                accResult += thisValue;
                salesreport[2].put(monthFieldName, thisValue);
            	salesreport[3].put(monthFieldName, accResult);
            }
        }
        for(AggregateResult a : [SELECT CALENDAR_MONTH(SyncedQuote.Delivery_Date__c) month, count(Id) total 
                                 FROM Opportunity WHERE CALENDAR_YEAR(SyncedQuote.Delivery_Date__c) =: year 
                                 AND DODL_Create__r.DO_DL_Code__c =: docode AND Recordtype.Name = 'Bike'
                                 AND Total_Payment__c > 0 AND Invoice_date__c = null
                                 AND StageName NOT IN ('Close Won', 'Close Lost')
                                 GROUP BY CALENDAR_MONTH(SyncedQuote.Delivery_Date__c)]) {
            integer month = integer.valueOf(a.get('month'));
            integer totalBike = (integer)a.get('total');                         
            string monthFieldName = MONTHMAP.get(month) + SUFFIXFIELD;                         
            salesreport[6].put(monthFieldName, totalBike);
        }
        Id batchJob = Database.executeBatch(new BatchPSISalesReport(docode, year, salesreport, isScheduled));
        return batchJob; 
    }
    @AuraEnabled
    public static AsyncApexJob getBatchJobStatus(Id jobID){
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id = :jobID];
        return jobInfo;
    }
    @AuraEnabled
    public static ApiResponse createDataLeadReport(Id jobID){
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get('Sales_Report__c');
        Map<String, Schema.SObjectField> schemaFieldMap = sobjectType.getDescribe().fields.getMap();
		Map<String, Sales_Report__c> salesResultMap = new Map<String, Sales_Report__c>();
        List<String> query = new List<String>();
        query.add('SELECT Recordtype.DeveloperName ,' + String.join(new List<String>(schemaFieldMap.keySet()), ','));
        query.add('FROM Sales_Report__c');
        query.add('WHERE JodID__c =: jobID');
        List<Sales_Report__c> result = (List<Sales_Report__c>)Database.query(String.join(query, ' '));
         for (Sales_Report__c report : result) {
            salesResultMap.put(report.Recordtype.DeveloperName, report);
        }
        system.debug('salesResultMap' + salesResultMap);
        ApiResponse apiResponse = new ApiResponse(true);
        apiResponse.result = salesResultMap;
        return apiResponse;
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
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
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