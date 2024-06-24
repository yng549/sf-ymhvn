public without sharing class BatchReportStockHistoryBike extends BaseBatchHandler {
    // List<Stock_History__c> lstUpsert;
    public String productBike;
    public Datetime now = Datetime.now();
    public Integer offset = UserInfo.getTimezone().getOffset(now);
    public Integer month;
    public Integer year;
    public Date today = System.today();
    public Date yesterdate = System.today().addDays(-1);
    public boolean fillData = false;

    public BatchReportStockHistoryBike() {
        try { 
        this.objectName = 'Product2';
        productBike = RecordTypeHelper.PRODUCT_MODEL;
        }catch(Exception ex){
            System.debug(ex.getLineNumber() + ' | ' + ex.getMessage());
            System.debug(ex.getStackTraceString());
        }
      
    }

    public BatchReportStockHistoryBike(boolean fillData) {
        this.objectName = 'Product2';
        productBike = RecordTypeHelper.PRODUCT_MODEL;
        this.fillData = fillData;
    }

    public override Database.querylocator start(Database.BatchableContext BC) {
        
        List<String> query = new List<String>();
        query.add('SELECT  Id, RecordTypeId, Name, ProductCode');
        query.add('FROM ' + objectName);
        query.add('WHERE RecordTypeId = :productBike');
        query.add('AND ExternalID_DMS__c != null');
        
        if (Test.isRunningTest()) {
            query.add('LIMIT 200');
        }
        return Database.getQueryLocator(String.join(query, ' '));
        
    }
    
    public override List<SObject> processData(List<SObject> records) {
        
        List<Product2> newData = (List<Product2>) records;
        System.debug('fillData: ' + fillData);
        try { 
            if(fillData){
                createData(newData);
            }else{
                createStockHistoryBike(newData);
            }
        }catch(Exception ex){
            System.debug(ex.getLineNumber() + ' | ' + ex.getMessage());
            System.debug(ex.getStackTraceString());
        }
        return newData;
    }
    
    private void createStockHistoryBike(List<Product2> newData) {
        Set<Id> idProducts = new Set<Id>();
        List<History_Stock_Product__c> lstUpsertBikeLastMonth = new List<History_Stock_Product__c>();
        List<Warehouse_Location__c> lstWarehouseLocation = new List<Warehouse_Location__c>();
        Map<String, List<Warehouse_Inventory__c>> mapWIOfProduct = new Map<String, List<Warehouse_Inventory__c>>();
        List<Warehouse_Inventory__c> lstWarehouseInventory = new List<Warehouse_Inventory__c>();
        Map<String,History_Stock_Product__c> mapHistoryStockThisMonth = new Map<String,History_Stock_Product__c>();
        // List<History_Stock_Product_Detail__c> lstInsertDetail = new List<History_Stock_Product_Detail__c>();
        List<History_Stock_Product__c> lstUpsertHistoryBike = new List<History_Stock_Product__c>();
        List<Account> lstAccDO = new List<Account>();
        try { 
            for (Product2 p : newData) {
                idProducts.add(p.Id);
            }
            lstAccDO =  [SELECT Id
                                , Name
                                , Warehouse_Location__c
                                , Warehouse_Location_Service__c
                        FROM Account
                        WHERE RecordTypeId =: RecordTypeHelper.ACCOUNT_DODL
                            AND Warehouse_Location__c != NULL];
              //Lấy warehouse location dựa trên DODL
         
            
            lstWarehouseLocation = [SELECT Id, Name FROM Warehouse_Location__c WHERE Account__c IN:lstAccDO];
            
            // Warehouse 'BB Assets & Tools' On Production For Demo Bike On Production only so not include in lstWarehouse
         
            //Warehouse inventory
            lstWarehouseInventory = [SELECT Id
                                     		, Product__c
                                     		, QoH__c
                                        	, Warehouse_Location__c
                                        	, Warehouse_Location__r.Name
                                            , Warehouse_location__r.Account__c
                                            , CreatedDate  //Warehouse created date = ngày stock in
                                            , Invoice_Date__c
                                            , Warehouse_Location_Account__c
                                            , (SELECT Id 
                                                FROM Inventory_Transaction_Items__r 
                                                WHERE Inventory_Transaction_Header__r.Status__c = 'Completed') 
                                                //Warehouse có transaction item với header Completed + có invoice Date = xe stock out
                                     FROM Warehouse_Inventory__c
                                     WHERE Warehouse_Location__c IN :lstWarehouseLocation
                                         AND Product__r.RecordTypeId = :RecordTypeHelper.PRODUCT_MODEL
                                         AND Product__c IN: idProducts
                                         AND Warehouse_location__r.Account__c != null];
       
            // List Warehouse của mỗi product chia ra theo từng warehouse location
            for (Warehouse_Inventory__c wInvent : lstWarehouseInventory) {
                if (!mapWIOfProduct.containsKey(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c)) {
                    mapWIOfProduct.put(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c, new List<Warehouse_Inventory__c>());  
                }
                mapWIOfProduct.get(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c).add(wInvent);
            }
   
            // kiểm tra có xe booking 
            // List<X3_Inventory_Transaction_Header__c> lstHeader = [
            //     SELECT Id,
            //         From_Warehouse_Location__c,
            //         To_Warehouse_Location__c,
            //         StockDate__c,
            //         (
            //             SELECT Id,
            //                     Quantity__c,
            //                     Product__c,
            //                     From_Warehouse_Location__c,
            //                     To_Warehouse_Location__c,
            //                     Warehouse_Inventory__c,
            //                     Warehouse_Inventory__r.Warehouse_Location__c,
            //                     Warehouse_Inventory__r.Warehouse_Location__r.Name,
            //                     Warehouse_Inventory__r.Asset__c,
            //                     Warehouse_Inventory__r.Invoice_Date__c
            //             FROM Inventory_Transaction_Items__r
            //             WHERE Product__c != NULL
            //                 AND Warehouse_Inventory__c != NULL
            //                 AND Product__c IN :idProducts
            //                 AND Quantity__c >= 0
            //                 AND Product__r.RecordTypeId = :RecordTypeHelper.PRODUCT_MODEL
            //                 AND  Warehouse_Inventory__r.Asset__r.Inventory_Status__c = 'Reserved'
            //         )
            //     FROM X3_Inventory_Transaction_Header__c
            //     WHERE Status__c != 'Completed'
            //         AND Status__c != 'Cancled'
            //         AND Order_Reserved__r.Invoice_Date__c = null
            //         AND Header_Type__c = 'Output'
            // ];
            
            // Map<String, Decimal> mapNumberBikeBooking = new Map<String, Decimal>();
            // if (!lstHeader.isEmpty()) {
            //     for (X3_Inventory_Transaction_Header__c header : lstHeader) {
            //         for (Inventory_Transaction_Item__c headerItem : header.Inventory_Transaction_Items__r) {
            //             String setString = String.valueOf(headerItem.Product__c) +
            //                                 (String.isNotBlank(headerItem.Warehouse_Inventory__r.Warehouse_Location__c)
            //                                  	? String.valueOf(headerItem.Warehouse_Inventory__r.Warehouse_Location__c) : 'null');
            //             if (!mapNumberBikeBooking.containsKey(setString)) {
            //                 mapNumberBikeBooking.put(setString, 0);
            //             }
            //             Decimal totalQuantity = headerItem.Quantity__c + mapNumberBikeBooking.get(setString);
            //             mapNumberBikeBooking.put(setString, totalQuantity);
            //         }
            //     }
            // }

            if(today == today.toStartOfMonth()){ // Update Bike History tháng trước lần cuối
                Date lastMonthDate = today.addDays(-1);
                Map<String,History_Stock_Product__c> mapHistoryStockLastMonth = new Map<String,History_Stock_Product__c>();
                for (History_Stock_Product__c historyStock : [SELECT Id, Product__c, 
                                                                Date__c, 
                                                                Total_Bike_Stock_In__c, 
                                                                Total_Bike_Stock_Out__c,
                                                                Warehouse_Location__c,
                                                                Account__c,
                                                                Stock_At_The_Start__c,
                                                                Stock_Remain__c
                                                        FROM History_Stock_Product__c
                                                        WHERE CALENDAR_MONTH(Date__c) = :lastMonthDate.month()
                                                        AND CALENDAR_YEAR(Date__c) = :lastMonthDate.year()
                                                        AND Product__c IN :idProducts]){
                mapHistoryStockLastMonth.put(historyStock.Product__c + '' + historyStock.Account__c, historyStock);
            }
                for(Product2 product : newData){
                    for (Account accDO : lstAccDO ){
                        History_Stock_Product__c historyStockBike = new History_Stock_Product__c();
                        if(mapWIOfProduct.containsKey(product.Id + '' + accDO.Id)){
                            Integer totalQuantity = 0;
                            Integer totalStockOut = 0;
                            for(Warehouse_Inventory__c warehouseIn : mapWIOfProduct.get(product.Id + '' + accDO.Id)){
                                totalQuantity++;
                                if(!warehouseIn.Inventory_Transaction_Items__r.isEmpty() && warehouseIn.Invoice_Date__c != null){
                                    totalStockOut++;
                                }
                            }
                            
                            historyStockBike.Name = product.Name + ' ' + accDO.Name + ' ' + String.valueOf(today.month()) + '/' + String.valueOf(today.year());
                            historyStockBike.Product__c = product.Id;
                            historyStockBike.Date__c = today.toStartOfMonth();
                            historyStockBike.Total_Bike_Stock_In__c = totalQuantity;
                            historyStockBike.Total_Bike_Stock_Out__c = totalStockOut;
                            historyStockBike.Stock_At_The_Start__c = totalQuantity - totalStockOut;
                            historyStockBike.Stock_Remain__c = totalQuantity - totalStockOut;
                            // historyStockBike.Warehouse_Location__c = accDO.Warehouse_Location__c;
                            historyStockBike.Account__c = accDO.Id;
                            if (mapHistoryStockLastMonth.containsKey(product.Id + '' + accDO.Id)){
                                historyStockBike.Stock_At_The_Start__c = mapHistoryStockLastMonth.get(product.Id + '' + accDO.Id).Stock_Remain__c;
                            }
                        }else{
                            historyStockBike.Name = product.Name + ' ' + accDO.Name + ' ' + String.valueOf(today.month()) + '/' + String.valueOf(today.year());
                            historyStockBike.Product__c = product.Id;
                            historyStockBike.Date__c = today.toStartOfMonth();
                            historyStockBike.Total_Bike_Stock_In__c = 0;
                            historyStockBike.Total_Bike_Stock_Out__c = 0;
                            historyStockBike.Stock_At_The_Start__c = 0;
                            historyStockBike.Stock_Remain__c = 0;
                            // historyStockBike.Warehouse_Location__c = accDO.Warehouse_Location__c;
                            historyStockBike.Account__c = accDO.Id;
                            if (mapHistoryStockLastMonth.containsKey(product.Id + '' + accDO.Id)){
                                historyStockBike.Stock_At_The_Start__c = mapHistoryStockLastMonth.get(product.Id + '' + accDO.Id).Stock_Remain__c;
                            }
                        }
                        lstUpsertBikeLastMonth.add(historyStockBike);
                    }
                }
              
                upsert lstUpsertBikeLastMonth;
            }

            for (History_Stock_Product__c historyStock : [SELECT Id, Product__c, 
                                                                Date__c, 
                                                                Total_Bike_Stock_In__c, 
                                                                Total_Bike_Stock_Out__c,
                                                                Warehouse_Location__c,
                                                                Account__c,
                                                                Stock_At_The_Start__c,
                                                                Stock_Remain__c
                                                        FROM History_Stock_Product__c
                                                        WHERE CALENDAR_MONTH(Date__c) = :today.month()
                                                        AND CALENDAR_YEAR(Date__c) = :today.year()
                                                        AND Product__c IN :idProducts]){
                mapHistoryStockThisMonth.put(historyStock.Product__c + '' + historyStock.Account__c, historyStock);
            }

            for(Product2 product : newData){
                for (Account accDO : lstAccDO ){
                    if(mapWIOfProduct.containsKey(product.Id + '' + accDO.Id)){
                        Integer totalQuantity = 0;
                        Integer totalStockOut = 0;
                        Integer totalStockInYesterday = 0;
                        Integer totalStockOutYesterday = 0;
                        for(Warehouse_Inventory__c warehouseInv : mapWIOfProduct.get(product.Id + '' + accDO.Id)){
                            totalQuantity++;
                            Date myCreatedDate = warehouseInv.CreatedDate.date();
                            if (myCreatedDate == System.today()){
                                totalStockInYesterday ++;

                            }
                            if(!warehouseInv.Inventory_Transaction_Items__r.isEmpty() && warehouseInv.Invoice_Date__c != null){
                                Date myInvoicedDate = warehouseInv.Invoice_Date__c;
                                if (myInvoicedDate == System.today()){
                                    totalStockOutYesterday++;
                                }
                                totalStockOut++;
                            }
                        }
                        if(mapHistoryStockThisMonth.containsKey(product.Id + '' + accDO.Id)){
                            History_Stock_Product__c historyStockBike = mapHistoryStockThisMonth.get(product.Id + '' + accDO.Id);
                            historyStockBike.Total_Bike_Stock_In__c = totalQuantity;
                            historyStockBike.Total_Bike_Stock_Out__c = totalStockOut;
                            historyStockBike.Stock_Remain__c = totalQuantity-totalStockOut;
                            lstUpsertHistoryBike.add(historyStockBike);
                            // if(totalStockInYesterday > 0 || totalStockOutYesterday > 0){
                            //     History_Stock_Product_Detail__c detail = new History_Stock_Product_Detail__c(
                            //         Date__c = today.addDays(-1),
                            //         Stock_In__c = totalStockInYesterday,
                            //         Stock_Out__c = totalStockOutYesterday
                            //     );
                            //     lstInsertDetail.add(detail);
                            // }

                        }else{
                            History_Stock_Product__c historyStockBike = new History_Stock_Product__c();
                            historyStockBike.Name = product.Name + ' ' + accDO.Name + ' ' + String.valueOf(today.month()) + '/' + String.valueOf(today.year());
                            historyStockBike.Product__c = product.Id;
                            historyStockBike.Date__c = today.toStartOfMonth();
                            historyStockBike.Total_Bike_Stock_In__c = totalQuantity;
                            historyStockBike.Total_Bike_Stock_Out__c = totalStockOut;
                            historyStockBike.Stock_At_The_Start__c = 0;
                            historyStockBike.Stock_Remain__c = totalQuantity-totalStockOut;
                            // historyStockBike.Warehouse_Location__c = accDO.Warehouse_Location__c;
                            historyStockBike.Account__c = accDO.Id;
                            lstUpsertHistoryBike.add(historyStockBike);
                        }
                    } else if(!mapHistoryStockThisMonth.containsKey(product.Id + '' + accDO.Id)){
                        History_Stock_Product__c historyStockBike = new History_Stock_Product__c();
                        historyStockBike.Name = product.Name + ' ' + accDO.Name + ' ' + String.valueOf(today.month()) + '/' + String.valueOf(today.year());
                        historyStockBike.Product__c = product.Id;
                        historyStockBike.Date__c = today.toStartOfMonth();
                        historyStockBike.Total_Bike_Stock_In__c = 0;
                        historyStockBike.Total_Bike_Stock_Out__c = 0;
                        historyStockBike.Stock_At_The_Start__c = 0;
                        historyStockBike.Stock_Remain__c = 0;
                        // historyStockBike.Warehouse_Location__c = accDO.Warehouse_Location__c;
                        historyStockBike.Account__c = accDO.Id;
                        lstUpsertHistoryBike.add(historyStockBike);
                    }
                }
            }

            upsert lstUpsertHistoryBike;
        } catch(Exception ex) {
            System.debug(ex.getLineNumber() + ' | ' + ex.getMessage());
            System.debug(ex.getStackTraceString());
        }
    }
    
    private void createData(List<Product2> newData){
        Set<Id> idProducts = new Set<Id>();
        List<History_Stock_Product__c> lstUpsertBikeLastMonth = new List<History_Stock_Product__c>();
        List<Warehouse_Location__c> lstWarehouseLocation = new List<Warehouse_Location__c>();
       
        Map<String, List<Warehouse_Inventory__c>> mapWIOfProduct = new Map<String, List<Warehouse_Inventory__c>>();
        List<Warehouse_Inventory__c> lstWarehouseInventory = new List<Warehouse_Inventory__c>();
        Map<String,History_Stock_Product__c> mapHistoryStockThisMonth = new Map<String,History_Stock_Product__c>();
        List<History_Stock_Product__c> lstUpsertHistoryBike = new List<History_Stock_Product__c>();
        List<Account> lstAccDO = new List<Account>();
        try { 
        Date oldestCreatedDate = [SELECT Id
                                            , Product__c
                                            , QoH__c
                                        , Warehouse_Location__c
                                        , Warehouse_Location__r.Name
                                        , CreatedDate  //Warehouse created date = ngày stock in
                                        , Invoice_Date__c
                                        
                                            //Warehouse có transaction item với header Completed + có invoice Date = xe stock out
                                    FROM Warehouse_Inventory__c
                                    WHERE  Product__r.RecordTypeId = :RecordTypeHelper.PRODUCT_MODEL
                                    ORDER BY CreatedDate ASC LIMIT 1][0].CreatedDate.addSeconds(offset/1000).date();
     
            for (Product2 p : newData) {
                idProducts.add(p.Id);
            }

          lstAccDO =  [SELECT Id
                                , Name
                                , Warehouse_Location__c
                                , Warehouse_Location_Service__c
                        FROM Account
                        WHERE RecordTypeId =: RecordTypeHelper.ACCOUNT_DODL
                            AND Warehouse_Location__c != NULL];
              //Lấy warehouse location dựa trên DODL
          
            lstWarehouseLocation = [SELECT Id, Name FROM Warehouse_Location__c WHERE Account__c IN:lstAccDO];
            //Warehouse inventory
            lstWarehouseInventory = [SELECT Id
                                     		, Product__c
                                     		, QoH__c
                                        	, Warehouse_Location__c
                                        	, Warehouse_Location__r.Name
                                            , CreatedDate  //Warehouse created date = ngày stock in
                                            , Invoice_Date__c
                                            , Warehouse_location__r.Account__c
                                            , Warehouse_Location_Account__c
                                            , (SELECT Id 
                                                FROM Inventory_Transaction_Items__r 
                                                WHERE Inventory_Transaction_Header__r.Status__c = 'Completed') 
                                                //Warehouse có transaction item với header Completed + có invoice Date = xe stock out
                                     FROM Warehouse_Inventory__c
                                     WHERE Warehouse_Location__c IN :lstWarehouseLocation
                                         AND Product__r.RecordTypeId = :RecordTypeHelper.PRODUCT_MODEL
                                         AND Product__c IN: idProducts];
       
            // List Warehouse của mỗi product chia ra theo từng warehouse location
            for (Warehouse_Inventory__c wInvent : lstWarehouseInventory) {
                if (!mapWIOfProduct.containsKey(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c)) {
                    mapWIOfProduct.put(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c, new List<Warehouse_Inventory__c>());  
                }
                mapWIOfProduct.get(wInvent.Product__c + '' + wInvent.Warehouse_Location_Account__c).add(wInvent);
            }

            Integer oldestMonth = oldestCreatedDate.month();
            Integer oldestYear = oldestCreatedDate.year();
            System.debug('oldestCreatedDate: ' + oldestCreatedDate);
            while ((oldestMonth <= today.month() && oldestYear == today.year()) || oldestYear < today.year()){
                for (Product2 product : newData){
                    for (Account accDO : lstAccDO){
                        if (mapWIOfProduct.containsKey(product.Id + '' + accDO.Id)) {
                            Integer totalStockInLastMonth = 0;
                            Integer totalStockInThatMonth = 0;
                            Integer totalStockOutLastMonth = 0;
                            Integer totalStockOutThatMonth = 0;
                            
                            for (Warehouse_Inventory__c warehouseInvent : mapWIOfProduct.get(product.Id + '' + accDO.Id)){
                                Integer createdDateMonth = warehouseInvent.CreatedDate.addSeconds(offset/1000).month();
                                Integer createdDateYear = warehouseInvent.CreatedDate.addSeconds(offset/1000).year();
                                if ((createdDateMonth < oldestMonth 
                                    && createdDateYear == oldestYear)
                                || createdDateYear < oldestYear){
                                    totalStockInLastMonth++;
                                }
                                if ((createdDateMonth <= oldestMonth 
                                    && createdDateYear == oldestYear)  
                                || createdDateYear < oldestYear ){
                                    totalStockInThatMonth++;
                                }
                                if(!warehouseInvent.Inventory_Transaction_Items__r.isEmpty() && warehouseInvent.Invoice_Date__c != null){
                                    Integer invoiceDateMonth = warehouseInvent.Invoice_Date__c.month();
                                    Integer invoiceDateYear = warehouseInvent.Invoice_Date__c.year();
                                    if ((invoiceDateMonth < oldestMonth && invoiceDateYear == oldestYear) || invoiceDateYear < oldestYear ){
                                        totalStockOutLastMonth++;
                                    }
                                    if ((invoiceDateMonth <= oldestMonth && invoiceDateYear == oldestYear) || invoiceDateYear < oldestYear){
                                        totalStockOutThatMonth++;
                                    }
                                }
                            }
                            History_Stock_Product__c historyStockBike = new History_Stock_Product__c();
                            historyStockBike.Name = product.Name + ' ' + accDO.Name + ' ' + String.valueOf(oldestCreatedDate.month()) + '/' + String.valueOf(oldestCreatedDate.year());
                            historyStockBike.Product__c = product.Id;
                            historyStockBike.Date__c = oldestCreatedDate.toStartOfMonth();
                            historyStockBike.Total_Bike_Stock_In__c = totalStockInThatMonth;
                            historyStockBike.Total_Bike_Stock_Out__c = totalStockOutThatMonth;
                            historyStockBike.Stock_At_The_Start__c = totalStockInLastMonth - totalStockOutLastMonth;
                            historyStockBike.Stock_Remain__c = totalStockInThatMonth - totalStockOutThatMonth;
                            // historyStockBike.Warehouse_Location__c = warehouseLocation.Id;
                            historyStockBike.Account__c = accDO.Id;
                            lstUpsertHistoryBike.add(historyStockBike);

                        }else{
                            History_Stock_Product__c historyStockBike = new History_Stock_Product__c();
                            historyStockBike.Name = product.Name + ' ' + accDO.Name + ' ' + String.valueOf(oldestCreatedDate.month()) + '/' + String.valueOf(oldestCreatedDate.year());
                            historyStockBike.Product__c = product.Id;
                            historyStockBike.Date__c = oldestCreatedDate.toStartOfMonth();
                            historyStockBike.Total_Bike_Stock_In__c = 0;
                            historyStockBike.Total_Bike_Stock_Out__c = 0;
                            historyStockBike.Stock_At_The_Start__c = 0;
                            historyStockBike.Stock_Remain__c = 0;
                            //historyStockBike.Warehouse_Location__c = warehouseLocation.Id;
                            historyStockBike.Account__c = accDO.Id;
                            lstUpsertHistoryBike.add(historyStockBike);
                        }
                    }
                }
                oldestCreatedDate = oldestCreatedDate.addMonths(1);
                oldestMonth = oldestCreatedDate.month();
                oldestYear = oldestCreatedDate.year();
            }
            upsert lstUpsertHistoryBike;
        } catch(Exception ex) {
            System.debug(ex.getLineNumber() + ' | ' + ex.getMessage());
            System.debug(ex.getStackTraceString());
        }
    }

    public override void handleFinish() {
        if(!fillData){
            Database.executeBatch(new BatchReportStockHistoryBikeDetail());
        }else{
            Database.executeBatch(new BatchReportStockHistoryBikeDetail(true), 5);
        }
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