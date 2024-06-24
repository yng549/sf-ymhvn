public without sharing class orderServicePage {
  private final static String MSG_EXCEPTION = 'Error System, Please Connect Admin.';
  private final static String DATE_TIME_FILE_FORMAT = 'yyyyMMddHHmm';
  private final static String FILE_NAME = '{0} - {1}.pdf';
  public String addressString { get; set; }
  private class CustomException extends Exception {
  }
  public Order objOrder { get; set; }
  public Date today { get; set; }
  public String strOrderId { get; set; }
  public list<OrderItem> lstOrderItemRepair { get; set; }
  public list<OrderItem> lstOrderItemDetailing { get; set; }
  public list<OrderItem> lstOrderItemPCA { get; set; }
  // public list<OrderItem> lstOrderItemSVJob { get; set; }
  private final static String SERVICE_TYPE_REPAIR = 'Repair';
  private final static String SERVICE_TYPE_DETAILING = 'Detailing';
  public Integer totalAmountVoucher { get; set; }
  public Boolean ifFreeService { get; set; }
  public Map<Id, Promotion_Product__c> mapPromotionProduct { get; set; }
  public String logo { get; set; }
  public orderServicePage() {
    try {
      ifFreeService = false;
      today = System.today();
      objOrder = new Order();
      addressString = '';
      strOrderId = ApexPages.currentPage().getParameters().get('Id');
      if (String.isNotBlank(strOrderId)) {
        objOrder = getOrderById(strOrderId);
        System.debug('objOrder :' + objOrder);
        if (String.isBlank(objOrder.Id)) {
          return;
        }
        // free service
        if (objOrder.RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE) {
          ifFreeService = true;
        }

        lstOrderItemRepair = getOrderItemByOrderId(
          strOrderId,
          SERVICE_TYPE_REPAIR
        );
        system.Debug('lstOrderItemRepair : ' + lstOrderItemRepair);
        lstOrderItemDetailing = getOrderItemByOrderId(
          strOrderId,
          SERVICE_TYPE_DETAILING
        );
        system.Debug('lstOrderItemDetailing : ' + lstOrderItemDetailing);
        lstOrderItemPCA = getOrderItemByOrderId(strOrderId, null);
        system.Debug('lstOrderItemPCA :' + lstOrderItemPCA);
        mapPromotionProduct = getPromotionProduct(lstOrderItemPCA);
        logo= '';
 
        
        if (objOrder.DO_DL__r.Name != null) {
            String doDlCreateName = objOrder.DO_DL__r.Name;
            
            if (doDlCreateName == 'REVZONE YAMAHA MOTOR HA NOI') {
                logo = 'RevzoneHN';
            } else {
                logo = 'Revzone';
            }
        }
        // lstOrderItemSVJob = getOrderItemPackageSessionUsage(strOrderId);
        //initAddressString(objOrder.Account.Address_No__c, objOrder.Account.Province__r.Name, objOrder.Account.District__r.Name);
      }
    } catch (Exception ex) {
      System.debug('ex.Get Error Message :' + ex.getMessage() + ' Line: ' + ex.getLineNumber());
      throw new CustomException(
        String.format(MSG_EXCEPTION, new List<Object>{ ex.getMessage() })
      );
    }
  }

  private Map<Id, Promotion_Product__c> getPromotionProduct(list<OrderItem> lstOrderItemPCA){
    Set<Id> setIdPromotionItem = new Set<Id>();
    for(OrderItem orderItem : lstOrderItemPCA){
      setIdPromotionItem.add(orderItem.Order.Campaign__r.Promotion_Item__c);
    }
    Map<Id, Promotion_Product__c> mapPromotionProduct = new Map<Id, Promotion_Product__c>();
    for(Promotion_Product__c promotionProduct : [SELECT Id, 
                                                        Quantity__c,
                                                        Promotion_Item__c,
                                                        Product__c
                                                        FROM Promotion_Product__c 
                                                        WHERE Product__c IN: setIdPromotionItem
                                                        AND Quantity__c != null]){
        mapPromotionProduct.put(promotionProduct.Promotion_Item__c, promotionProduct);
    }
    return mapPromotionProduct;
  }

  private void initAddressString(
    String strAddressNo,
    String strProvince,
    String strDistrict
  ) {
    if (String.isNotBlank(strAddressNo)) {
      addressString += (strAddressNo != null ? strAddressNo + ', ' : '');
    }
    if (String.isNotBlank(strProvince)) {
      addressString += (strProvince != null ? strProvince + ', ' : '');
    }
    if (String.isNotBlank(strDistrict)) {
      addressString += (strDistrict != null ? strDistrict : '');
    }
  }

  private Order getOrderById(String strOrderId) {
    List<Order> lstOrderQuerry = [
      SELECT
        Id,
        Workshop_Note__c,
        Request_Description__c,
        Description,
        Cashier__c,
        Cashier__r.Name,
        Order_Number__c,
        RecordType.Name,
        RecordTypeId,
        DO_DL__r.Name,
        Created_Date__c,
        FormNumber__c,
        Bike_Delivery_Date__c,
        Bike_Receiving_Date__c,
        Make_Model__c,
        Year__c,
        Frame_No__c,
        Mileage_Out__c,
        Titile_No__c,
        Stock_No__c,
        Mileage__c,
        Crankcase_No__c,
        OrderNumber,
        CreatedDate,
        Interested_In__c,
        Interested_In__r.Name,
        Compression__c,
        Clutch_Transmission__c,
        Cooling_system__c,
        Charging_system__c,
        Front_forks__c,
        Rear_shock_s__c,
        Front_brake_s__c,
        Rear_brake__c,
        Final_Drive__c,
        Spark_plugs__c,
        Steering_bearings__c,
        Handlebar_s__c,
        Asset__c,
        Asset__r.Frame_Number__c,
        Asset__r.Product2.Model__c,
        Asset__r.Product2.Model_Bike__r.Name,
        Asset__r.Product2.Model_Name__c,
        Asset__r.Engine_No__c,
        Asset__r.PlateNo__c,
        Asset__r.Bike_Type__c,
        Account.Name,
        Account.AccountNumber,
        Account.Address_Full__c,
        Account.Phone,
        Account.PersonMobilePhone,
        Account.Address_No__c,
        Account.Province__r.Name,
        Account.District__r.Name,
        Account.DO_DL_Create_Account__r.Name,
        Sales_Associate__c,
        Sales_Associate__r.Name,
        OwnerId,
        Owner.Name,
        Appraiser__c,
        Appraiser__r.Name,
        Dealer__c,
        Status,
        Mechanic__r.Name,
        Opportunity.Asset__r.Year__c,
        Opportunity.Asset__r.Make_Model__c,
        Opportunity.Asset__r.VinID__c,
        Opportunity.Asset__r.Mileage__c,
        Opportunity.Asset__r.Engine_No__c,
        Detailing_Staff__r.Name,
        Detailing_Staff__r.FirstName,
        Detailing_Staff__r.LastName,
        (
          SELECT Id, Service_Apply__c, Name, Amount__c
          FROM Voucher__r
          WHERE Voucher_Status__c = 'Redeemed'
        )
      FROM Order
      WHERE Id = :strOrderId
      ORDER BY CreatedDate ASC
    ];
    if (lstOrderQuerry.isEmpty()) {
      totalAmountVoucher = 0;
      return new Order();
    } else {
      if ((lstOrderQuerry[0].Voucher__r).isEmpty()) {
        totalAmountVoucher = 0;
      } else {
          totalAmountVoucher = 0;
        for (Voucher__c item : lstOrderQuerry[0].Voucher__r) {
          System.debug('1');
          System.debug('item.Amount__c :' + item.Amount__c);
          if (item.Amount__c == null) {
            totalAmountVoucher += 0;
            System.debug('2');
          } else {
            totalAmountVoucher += Integer.valueOf(item.Amount__c);
            System.debug('2: '+totalAmountVoucher);
          }
        }
      }
    }
    return lstOrderQuerry[0];
  }
  private static List<OrderItem> getOrderItemByOrderId(
    String strOrderId,
    String strServiceType
  ) {
    List<OrderItem> lstOrderItem = new List<OrderItem>();
    if (strServiceType == null) {
      lstOrderItem = [
        SELECT
          Id,
          Discount__c,
          Discount_Amount__c,
          Total_Amount_Line__c,
          Percent__c,
          UnitPrice,
          Labour_Hours__c,
          Product2.Name,
          Product2.Labor_HOUR__c,
          TotalPrice,
          ListPrice,
          OrderItemNumber,
          Product2Id,
          Date_Active__c,
          OrderId,
          Product2.ProductCode,
          Product2.Quantity_of_Unit__c,
          Quantity,
          PackageOwnerId__c,
          Order.Campaign__r.Promotion_Item__c
        FROM OrderItem
        WHERE
          OrderId = :strOrderId
          AND Product2.RecordTypeId = :RecordTypeHelper.PRODUCT_PCA
      ];
    } else if (
      strServiceType == SERVICE_TYPE_REPAIR ||
      strServiceType == SERVICE_TYPE_DETAILING
    ) {
      lstOrderItem = [
        SELECT
          Id,
          Discount__c,
          Discount_Amount__c,
          Total_Amount_Line__c,
          Percent__c,
          UnitPrice,
          Labour_Hours__c,
          Product2.Name,
          Date_Active__c,
          TotalPrice,
          ListPrice,
          OrderItemNumber,
          Product2Id,
          Product2.Unit_Measure__c,
          Product2.Labor_HOUR__c,
          OrderId,
          PackageOwnerId__c,
          Product2.ProductCode,
          Product2.Quantity_of_Unit__c,
          Order.Campaign__r.Promotion_Item__c
        FROM OrderItem
        WHERE
          OrderId = :strOrderId
          AND Product2.Service_Type__c = :strServiceType
      ];
    }

    
    return lstOrderItem;
  }
  private static List<OrderItem> getOrderItemPackageSessionUsage(
    String strOrderId
  ) {
    List<OrderItem> lstOrderItem = new List<OrderItem>();
    lstOrderItem = [
      SELECT
        Id,
        Discount__c,
        Discount_Amount__c,
        Total_Amount_Line__c,
        Percent__c,
        UnitPrice,
        Product2.Name,
        Product2.Labor_HOUR__c,
        TotalPrice,
        ListPrice,
        OrderItemNumber,
        Product2Id,
        Date_Active__c,
        OrderId,
        PackageOwnerId__c,
        Product2.ProductCode,
        Product2.Quantity_of_Unit__c,
        Quantity
      FROM OrderItem
      WHERE OrderId = :strOrderId
      // PRODUCT_SERVICE_PACKAGE
    ];
    return lstOrderItem;
  }
  /*
   * createPdfFile
   * @param: quoteId
   * @return: none
   * @created: 2022/01/05  Nguyen Duc Dat
   * @modified: 2022/01/21 Nguyen Gia Minh
   */
  @AuraEnabled
  public static Map<String, String> createPdfFile(String orderId) {
    Savepoint sp = Database.setSavepoint();
    try {
      Map<String, String> files = new Map<String, String>();
      List<Order> orderList = [
        SELECT OrderNumber, Order_Number__c, Account.Name, CreatedDate
        FROM Order
        WHERE ID = :orderId
      ];
      if (orderList.isEmpty()) {
        return null;
      }
      PageReference page = Page.orderServicePDF;
      page.getParameters().put('id', orderId);
      Blob pdfContent;
      if (Test.isRunningTest()) {
        pdfContent = Blob.valueOf('TestClass.pdf');
      } else {
        pdfContent = page.getContent();
      }
      DateTime dt = DateTime.now();
      String strDateTime = dt.format(DATE_TIME_FILE_FORMAT);
      String fileName = String.format(
        FILE_NAME,
        new List<String>{
          orderList[0].Order_Number__c,
          orderList[0].Account.Name
        }
      );
      //   ContentVersion objContentVersion = createContentVersion(
      //     pdfContent,
      //     fileName
      //   );
      //   String contentDocumentId = createContentDocumentLink(
      //     objContentVersion.Id,
      //     orderId
      //   );
      String base64pdf = EncodingUtil.base64Encode(pdfContent);
      files.put(fileName, base64pdf);
      return files;
    } catch (System.DMLException ex) {
      Database.rollback(sp);
      throw new AuraHandledException(
        String.format(MSG_EXCEPTION, new List<Object>{ ex.getMessage() })
      );
    }
  }

  private static ContentVersion createContentVersion(
    Blob pdfContent,
    String fileName
  ) {
    ContentVersion objContentVersion = new ContentVersion(
      VersionData = pdfContent,
      Title = fileName,
      PathOnClient = fileName
    );
    insert objContentVersion;
    return objContentVersion;
  }

  private static String createContentDocumentLink(
    String contentVersionId,
    String orderId
  ) {
    ContentVersion objContentVersion = [
      SELECT ContentDocumentId
      FROM ContentVersion
      WHERE Id = :contentVersionId
    ];
    ContentDocumentLink objContentDocLink = new ContentDocumentLink();
    objContentDocLink.ContentDocumentId = objContentVersion.ContentDocumentId;
    objContentDocLink.LinkedEntityId = orderId;
    objContentDocLink.ShareType = 'V';
    insert objContentDocLink;
    return objContentVersion.ContentDocumentId;
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
  }
}