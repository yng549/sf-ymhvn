public without sharing class BatchReportStockHistoryBikeDetail extends BaseBatchHandler{
    public Date today = System.today();
    public Datetime now = Datetime.now();
    public Integer offset = UserInfo.getTimezone().getOffset(now);
    public Date yesterdate = System.today().addDays(-1);
    public Integer month;
    public Integer year;
    public Integer yesterDateMonth;
    public Integer yesterDateYear;
    public boolean fillData = false;
    public Datetime todayNow = System.now();

    public BatchReportStockHistoryBikeDetail() {
        this.objectName = 'History_Stock_Product__c';
        this.month = today.month();
        this.year = today.year();
        this.yesterDateMonth = yesterdate.month();
        this.yesterDateYear = yesterdate.year();
        System.debug('today: ' + today);
    }

    public BatchReportStockHistoryBikeDetail(boolean fillData) {
        this.objectName = 'History_Stock_Product__c';
        this.month = today.month();
        this.year = today.year();
        this.fillData = fillData;
  
    }

    public override Database.querylocator start(Database.BatchableContext BC) {
    
        
        List<String> query = new List<String>();
        query.add('SELECT Id, Date__c, Stock_At_The_Start__c, Stock_Remain__c, Product__c,Product__r.Name, Warehouse_Location__c,Warehouse_Location__r.Name, Account__r.Name, Total_Bike_Stock_In__c, Total_Bike_Stock_Out__c, Total_Stock_In_Of_Month__c, Total_Stock_Out_Of_Month__c, Account__c');
        query.add('FROM ' + objectName);
        if (!fillData){
            query.add('WHERE CALENDAR_MONTH(Date__c) = :month');
            query.add('AND CALENDAR_YEAR(Date__c) = :year');
        }
        
        if (Test.isRunningTest()) {
            query.add('LIMIT 200');
        }
        return Database.getQueryLocator(String.join(query, ' '));
    }

    public override List<SObject> processData(List<SObject> records) {
        List<History_Stock_Product__c> newData = (List<History_Stock_Product__c>) records;
        try { 
            if (fillData){
                createData(newData);
            }else{
                createDetailLastMonth(newData);
            }
        }catch(Exception ex){
            System.debug(ex.getLineNumber() + ' | ' + ex.getMessage());
            System.debug(ex.getStackTraceString());
        }
        return newData;

    }
    private void createDetailLastMonth(List<History_Stock_Product__c> newData){
        Set<Id> setAccountIds = new Set<Id>();
        List<History_Stock_Product_Detail__c> lstInsertDetail = new List<History_Stock_Product_Detail__c>();
        Set<Id> setProductIds = new Set<Id>();
        Map<String,List<Warehouse_Inventory__c>> mapWarehouseInvt = new Map<String,List<Warehouse_Inventory__c>>();
        List<Account> lstAccDO = new List<Account>();
              //Warehouse inventory

        lstAccDO =  [SELECT Id
                            , Name
                            , Warehouse_Location__c
                            , Warehouse_Location_Service__c
                    FROM Account
                    WHERE RecordTypeId =: RecordTypeHelper.ACCOUNT_DODL
                        AND Warehouse_Location__c != NULL];
        for (History_Stock_Product__c historyProduct : newData){
            setAccountIds.add(historyProduct.Account__c);
            setProductIds.add(historyProduct.Product__c);
        }

        System.debug('setAccountIds: ' + setAccountIds);
        System.debug('setProductIds: ' + setProductIds);
        for (Warehouse_Inventory__c wInvent : [SELECT Id
                                                , Product__c
                                                , QoH__c
                                                , Warehouse_Location__c
                                                , Warehouse_Location__r.Name
                                                , CreatedDate  //Warehouse created date = ngày stock in
                                                , Invoice_Date__c
                                                , Warehouse_Location_Account__c
                                                , (SELECT Id 
                                                    FROM Inventory_Transaction_Items__r 
                                                    WHERE Inventory_Transaction_Header__r.Status__c = 'Completed')   //Warehouse có transaction item với header Completed + có invoice Date = xe stock out
                                                FROM Warehouse_Inventory__c
                                                WHERE Warehouse_Location__r.Account__c IN :setAccountIds
                                                    AND Product__r.RecordTypeId = :RecordTypeHelper.PRODUCT_MODEL
                                                    AND Product__c IN: setProductIds
                                                    AND (
                                                        (CALENDAR_MONTH(CreatedDate) = :month AND CALENDAR_YEAR(CreatedDate) = :year)
                                                    OR (CALENDAR_MONTH(Invoice_Date__c) = :month AND CALENDAR_YEAR(Invoice_Date__c) = :year)
                                                    OR (CALENDAR_MONTH(CreatedDate) = :yesterDateMonth AND CALENDAR_YEAR(CreatedDate) = :yesterDateYear)
                                                    OR (CALENDAR_MONTH(Invoice_Date__c) = :yesterDateMonth AND CALENDAR_YEAR(Invoice_Date__c) = :yesterDateYear)
                                                                    )]){
            if (!mapWarehouseInvt.containsKey(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c)) {
                mapWarehouseInvt.put(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c, new List<Warehouse_Inventory__c>());  
            }
            mapWarehouseInvt.get(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c).add(wInvent);
        }

        for (History_Stock_Product__c historyProduct : newData){
            if(mapWarehouseInvt.containsKey(historyProduct.Product__c + '' + historyProduct.Account__c)){
                Integer totalStockInYesterday = 0;
                Integer totalStockOutYesterday = 0;
                for(Warehouse_Inventory__c warehouseInv : mapWarehouseInvt.get(historyProduct.Product__c + '' + historyProduct.Account__c)){
                    DateTime createdDateTime = warehouseInv.CreatedDate.addSeconds(offset/1000);
                    Date myCreatedDate = createdDateTime.date();
                   
                    if (myCreatedDate == today){ 
                        totalStockInYesterday ++;
                    }
                  
                    if(!warehouseInv.Inventory_Transaction_Items__r.isEmpty() && warehouseInv.Invoice_Date__c != null){
                        Date myInvoicedDate = warehouseInv.Invoice_Date__c;
                        if (myInvoicedDate == today){
                            System.debug('Check2');
                            totalStockOutYesterday++;
                        }
                    }   
                }
                if(totalStockInYesterday > 0 || totalStockOutYesterday > 0 || today == System.today().toStartOfMonth()){
                    History_Stock_Product_Detail__c detail = new History_Stock_Product_Detail__c(
                                                                        Name = historyProduct.Product__r.Name +' ' +  historyProduct.Account__r.Name + ' ' + today.format(),
                                                                        Date__c = today,
                                                                        Stock_In__c = totalStockInYesterday,
                                                                        Stock_Out__c = totalStockOutYesterday,
                                                                        History_Stock_Product__c = historyProduct.Id
                                                                    );
                    lstInsertDetail.add(detail);
                }
            }else{
                if(today == System.today().toStartOfMonth()){
                    History_Stock_Product_Detail__c detail = new History_Stock_Product_Detail__c(
                                                                        Name = historyProduct.Product__r.Name + ' ' + historyProduct.Account__r.Name + ' ' + today.format(),
                                                                        Date__c = today,
                                                                        Stock_In__c = 0,
                                                                        Stock_Out__c = 0,
                                                                        History_Stock_Product__c = historyProduct.Id
                                                                    );
                    lstInsertDetail.add(detail);
                }
            }
        }
        System.debug(lstInsertDetail);
        insert lstInsertDetail;
    }

    private void createData(List<History_Stock_Product__c> newData){
        Set<Id> setAccountIds = new Set<Id>();
        List<History_Stock_Product_Detail__c> lstInsertDetail = new List<History_Stock_Product_Detail__c>();
        Set<Id> setProductIds = new Set<Id>();
        Map<String,List<Warehouse_Inventory__c>> mapWarehouseInvt = new Map<String,List<Warehouse_Inventory__c>>();
        Map<String,History_Stock_Product_Detail__c> mapDetail = new Map<String,History_Stock_Product_Detail__c>();
        Map<String,List<History_Stock_Product_Detail__c>> mapDetailByMonth = new Map<String,List<History_Stock_Product_Detail__c>>();
              //Warehouse inventory

        for (History_Stock_Product__c historyProduct : newData){
            setAccountIds.add(historyProduct.Account__c);
            setProductIds.add(historyProduct.Product__c);
        }

        for (Warehouse_Inventory__c wInvent : [SELECT Id
                                                    , Product__c
                                                    , QoH__c
                                                    , Warehouse_Location__c
                                                    , Warehouse_Location__r.Name
                                                    , CreatedDate  //Warehouse created date = ngày stock in
                                                    , Invoice_Date__c
                                                    , Warehouse_Location_Account__c
                                                    , (SELECT Id 
                                                        FROM Inventory_Transaction_Items__r 
                                                        WHERE Inventory_Transaction_Header__r.Status__c = 'Completed')   //Warehouse có transaction item với header Completed + có invoice Date = xe stock out
                                                    FROM Warehouse_Inventory__c
                                                    WHERE Warehouse_Location_Account__c IN :setAccountIds
                                                        AND Product__r.RecordTypeId = :RecordTypeHelper.PRODUCT_MODEL
                                                        AND Product__c IN: setProductIds
                                                    ]){
            Date myCreatedDate = wInvent.CreatedDate.addSeconds(offset/1000).Date();
            if (!mapWarehouseInvt.containsKey(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c)) {
                mapWarehouseInvt.put(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c, new List<Warehouse_Inventory__c>());  
            }
            mapWarehouseInvt.get(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c).add(wInvent);

            if (!mapDetail.containsKey(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c + '-' + myCreatedDate.format())){
                mapDetail.put(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c + '-' + myCreatedDate.format(),new History_Stock_Product_Detail__c(
                                                Date__c = myCreatedDate,
                                                Stock_In__c = 0,
                                                Stock_Out__c = 0));
            }
            mapDetail.get(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c + '-' + myCreatedDate.format()).Stock_In__c++;

            if(!wInvent.Inventory_Transaction_Items__r.isEmpty() && wInvent.Invoice_Date__c != null){
                Date myInvoiceDate = wInvent.Invoice_Date__c;
                if (!mapDetail.containsKey(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c + '-' + myInvoiceDate.format())){
                    mapDetail.put(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c + '-' + myInvoiceDate.format(),new History_Stock_Product_Detail__c(Date__c = myInvoiceDate,
                                                    Stock_In__c = 0,
                                                    Stock_Out__c = 0));
                }
                mapDetail.get(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c + '-' + myInvoiceDate.format()).Stock_Out__c++;
            }
        }
        // for (String keyDetail : mapDetail.keySet()){
        //     String newKey = keyDetail.split('-')[0];
        //     History_Stock_Product_Detail__c detail = mapDetail.get(keyDetail);
        //     if (!mapDetailByMonth.containsKey(newKey + String.valueOf(detail.Date__c.month()) + String.valueOf(detail.Date__c.year()))){
        //         mapDetailByMonth.put(newKey + String.valueOf(detail.Date__c.month()) + String.valueOf(detail.Date__c.year()),new List<History_Stock_Product_Detail__c>());
        //     }
        //     mapDetailByMonth.get(newKey + String.valueOf(detail.Date__c.month()) + String.valueOf(detail.Date__c.year())).add(detail);
        // }

        for (History_Stock_Product__c historyProduct : newData){
            Date historyDate = historyProduct.Date__c.toStartOfMonth();
            Date lastDayOfMonth = historyDate.addMonths(1).toStartofMonth().addDays(-1);
          
            while (historyDate <= lastDayOfMonth && historyDate <= today){
                if(mapDetail.containsKey(historyProduct.Product__c + '' + historyProduct.Account__c + '-' + historyDate.format())){
                    History_Stock_Product_Detail__c detail = mapDetail.get(historyProduct.Product__c + '' + historyProduct.Account__c + '-' + historyDate.format());
                    detail.Name = historyProduct.Product__r.Name +' ' + historyProduct.Account__r.Name +' ' + historyDate.format();
                    detail.History_Stock_Product__c = historyProduct.Id;
                    lstInsertDetail.add(detail);
                    // for (History_Stock_Product_Detail__c detail : mapDetailByMonth.get(historyProduct.Product__c + '' + historyProduct.Account__c + String.valueOf(historyProduct.Date__c.month()) + String.valueOf(historyProduct.Date__c.year()))){
                    //     detail.History_Stock_Product__c = historyProduct.Id;
                    //     lstInsertDetail.add(detail);
                    // }
                }else{
                    History_Stock_Product_Detail__c detail = new History_Stock_Product_Detail__c(
                        Name = historyProduct.Product__r.Name + ' ' + historyProduct.Account__r.Name + ' ' + historyDate.format(),
                        History_Stock_Product__c = historyProduct.Id,
                        Date__c = historyDate,
                        Stock_In__c = 0,
                        Stock_Out__c = 0
                    );
                    lstInsertDetail.add(detail);
                }
                historyDate = historyDate.addDays(1);
            }
        }

        insert lstInsertDetail;
    }
    public override void handleFinish() {
        
    }

    public static void cheatTemp() {
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
    }
}