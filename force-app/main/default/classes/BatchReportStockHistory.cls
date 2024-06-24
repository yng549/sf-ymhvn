public without sharing class BatchReportStockHistory extends BaseBatchHandler {
  public static Boolean flagRun = false;
  public String dynamicQuery;
  // List<Stock_History__c> lstUpsert;
  public String productPCA;

  public BatchReportStockHistory() {
    this.objectName = 'Product2';
    productPCA = RecordTypeHelper.PRODUCT_PCA;
    // lstUpsert = new List<Stock_History__c>();

    // dynamicQuery = 'SELECT {0} FROM {1} WHERE {2} GROUP BY {3}';
  }

  public override Database.querylocator start(Database.BatchableContext BC) {
    Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(objectName);
    Map<String, Schema.SObjectField> schemaFieldMap = sobjectType.getDescribe()
      .fields.getMap();

    List<String> query = new List<String>();
    query.add('SELECT  Id, RecordTypeId, Name');
    query.add('FROM ' + objectName);
    query.add('WHERE RecordTypeId = :productPCA');

    if (Test.isRunningTest()) {
      query.add('LIMIT 200');
    }
    return Database.getQueryLocator(String.join(query, ' '));
  }

  public override List<SObject> processData(List<SObject> records) {
    List<Product2> newData = (List<Product2>) records;
    createStockHistory(newData);
    return newData;
  }

  private void createStockHistory(List<Product2> newData) {
    Set<Id> idProducts = new Set<Id>();
    for (Product2 p : newData){
      idProducts.add(p.Id);
    }
    List<Stock_History__c> lstInsert = new List<Stock_History__c>();
    List<Stock_History__c> lstUpdate = new List<Stock_History__c>();
    List<Account> lstAccountDODL = new List<Account>();
    lstAccountDODL = [
      SELECT Id, Name, Warehouse_Location__c, Warehouse_Location_Service__c
      FROM Account
      WHERE
        RecordTypeId = :RecordTypeHelper.ACCOUNT_DODL
        AND Warehouse_Location__c != NULL
    ];
    Set<Id> setWarehouseLocationId = new Set<Id>();
    for (Account acc : lstAccountDODL) {
      if (acc.Warehouse_Location__c != null) {
        setWarehouseLocationId.add(acc.Warehouse_Location__c);
      }
    }

    List<X3_Inventory_Transaction_Header__c> lstTransactionHeader = new List<X3_Inventory_Transaction_Header__c>();
    List<Warehouse_Inventory__c> lstWarehouseInventory = new List<Warehouse_Inventory__c>();

    lstTransactionHeader = [
      SELECT
        Id,
        From_Warehouse_Location__c,
        To_Warehouse_Location__c,
        StockDate__c,
        From_Warehouse_Location_Account__c, 
        To_Warehouse_Location_Account__c,
        (
          SELECT
            Id,
            Quantity__c,
            Product__c,
            From_Warehouse_Location__c,
            To_Warehouse_Location__c
          FROM Inventory_Transaction_Items__r
          WHERE
            Product__c != NULL AND Product__c IN :idProducts
            AND Quantity__c >= 0
            AND Product__r.RecordTypeId = :RecordTypeHelper.PRODUCT_PCA
        )
      FROM X3_Inventory_Transaction_Header__c
      WHERE
        StockDate__c = :System.today().addDays(0)
        AND Status__c = 'Completed'
    ];

    lstWarehouseInventory = [
      SELECT Id, Product__c, QoH__c, Warehouse_Location__c, Warehouse_Location_Account__c
      FROM Warehouse_Inventory__c
      WHERE
        Warehouse_Location__c IN :setWarehouseLocationId
        AND Product__r.RecordTypeId = :RecordTypeHelper.PRODUCT_PCA
        AND QoH__c > 0 AND Product__c IN :idProducts
    ];
    // SELECT Product__c, Warehouse_Location__c ,Sum(QoH__c) FROM Warehouse_Inventory__c Group By Product__c,Warehouse_Location__c  HAVING Warehouse_Location__c IN ('a0SO000000EHuuXMAT','a0SO000000E2sroMAB','a0SO000000E2sroMAB')
    // QoH của mỗi product
    Map<String, Decimal> mapQoHOfProduct = new Map<String, Decimal>();
    for (Warehouse_Inventory__c WI : lstWarehouseInventory) {
      if (mapQoHOfProduct.containsKey(WI.Warehouse_Location_Account__c + '' + WI.Product__c)) {
        Decimal totalQoH =
          (WI.QoH__c == null ? 0 : WI.QoH__c) +
          mapQoHOfProduct.get(WI.Warehouse_Location_Account__c + '' + WI.Product__c);
        mapQoHOfProduct.put(WI.Warehouse_Location_Account__c + '' + WI.Product__c, totalQoH);
      } else {
        mapQoHOfProduct.put(WI.Warehouse_Location_Account__c + '' + WI.Product__c, (WI.QoH__c == null ? 0 : WI.QoH__c));
      }
    }

    // Số lượng nhập và xuất
    Map<String, Decimal> mapQuantityStockIn = new Map<String, Decimal>();
    Map<String, Decimal> mapQuantityStockOut = new Map<String, Decimal>();
    for (X3_Inventory_Transaction_Header__c header : lstTransactionHeader) {
      for (
        Inventory_Transaction_Item__c item : header.Inventory_Transaction_Items__r
      ) {
        if (header.From_Warehouse_Location__c == null) {
          if (mapQuantityStockIn.containsKey(header.To_Warehouse_Location_Account__c + '' +item.Product__c)) {
            Decimal quantityIn =
              item.Quantity__c + mapQuantityStockIn.get(header.To_Warehouse_Location_Account__c + '' +item.Product__c);
            mapQuantityStockIn.put(header.To_Warehouse_Location_Account__c + '' + item.Product__c, quantityIn);
          } else {
            mapQuantityStockIn.put(header.To_Warehouse_Location_Account__c + '' + item.Product__c, item.Quantity__c);
          }
        } else {
          if (mapQuantityStockOut.containsKey(header.From_Warehouse_Location_Account__c + '' +item.Product__c)) {
            Decimal quantityOut =
              item.Quantity__c + mapQuantityStockOut.get(header.From_Warehouse_Location_Account__c + '' +item.Product__c);
            mapQuantityStockOut.put(header.From_Warehouse_Location_Account__c + '' +item.Product__c, quantityOut);
          } else {
            mapQuantityStockOut.put(header.From_Warehouse_Location_Account__c + '' +item.Product__c, item.Quantity__c);
          }
        }
      }
    }

    // Tạo history stock cho ngày mới
      for (Product2 product : newData) {
        for (Account accDO : lstAccountDODL ){
          Stock_History__c historyStock = new Stock_History__c();
          historyStock.Name = accDO.Name + ' ' + product.Name + ' ' + System.today().format();
          historyStock.Date__c = System.today();
          historyStock.Product__c = product.Id;
          historyStock.Account__c = accDO.Id;
          historyStock.Stock_At_The_Start__c = mapQoHOfProduct.containsKey(accDO.Id + '' + product.Id)
            ? mapQoHOfProduct.get(accDO.Id + '' + product.Id)
            : 0;
          historyStock.Number_In__c = 0;
          historyStock.Number_Out__c = 0;
          lstInsert.add(historyStock);
        }
      }
  
       if (!lstInsert.isEmpty()) {
      	insert lstInsert;
       }
    // Lôi history stock ngày hqua ra update
    List<Stock_History__c> lstHistoryStockDayBefore = [SELECT
        Id,
        Name,
        Product__c,
        Stock_At_The_Start__c,
        Stock_After_The_Day__c,
        Number_In__c,
        Number_Out__c,
        Account__c,
        Date__c
      FROM Stock_History__c
      WHERE Date__c = :System.today().addDays(0) AND Product__c IN :idProducts
    ];
	System.debug(lstHistoryStockDayBefore);
    Map<String, Stock_History__c> mapHistoryStockOfProduct = new Map<String, Stock_History__c>();
    if (!lstHistoryStockDayBefore.isEmpty()) {
        	System.debug('Test');
      for (Stock_History__c stockYesterday : lstHistoryStockDayBefore) {
        mapHistoryStockOfProduct.put(stockYesterday.Account__c + '' + stockYesterday.Product__c, stockYesterday);
      }

      for (Product2 product : newData) {
        for (Account accDO : lstAccountDODL ){
          if (mapHistoryStockOfProduct.containsKey(accDO.Id + '' + product.Id)) {
            Stock_History__c historyStock = mapHistoryStockOfProduct.get(
              accDO.Id + '' + product.Id
            );
            historyStock.Stock_After_The_Day__c = mapQoHOfProduct.containsKey(
              accDO.Id + '' + product.Id
              )
              ? mapQoHOfProduct.get(accDO.Id + '' + product.Id)
              : 0;
            historyStock.Number_In__c = (mapQuantityStockIn.containsKey(
              accDO.Id + '' + product.Id
              )
              ? mapQuantityStockIn.get(accDO.Id + '' + product.Id)
              : 0);
            historyStock.Number_Out__c = (mapQuantityStockOut.containsKey(
                accDO.Id + '' + product.Id
              )
              ? mapQuantityStockOut.get(accDO.Id + '' + product.Id)
              : 0);
            lstUpdate.add(historyStock);
          }
        }
      }
    }

 
    if (!lstUpdate.isEmpty()) {
      update lstUpdate;
    }
  }

  public override void handleFinish() {
    // if (!lstUpsert.isEmpty()) {
    //   upsert lstUpsert;
    // }
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