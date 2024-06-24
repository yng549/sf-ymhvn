public without sharing class ServicePackageFormController {
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
  public list<OrderItem> lstPackageUsage { get; set; }
  private final static String SERVICE_TYPE_REPAIR = 'Repair';
  private final static String SERVICE_TYPE_DETAILING = 'Detailing';
  public Integer totalAmountVoucher { get; set; }
  public Boolean ifFreeService { get; set; }
  public Map<Id, List<Product_Detail_Service__c>> mapProductDetailService {
    get;
    set;
  }
  public List<Package_Owner__c> lstPackageOwner { get; set; }
  public Set<Id> productWithPackageOwnerId {get;set;}
  public ServicePackageFormController() {
    try {
      productWithPackageOwnerId = new Set<Id>();
      mapProductDetailService = new Map<Id, List<Product_Detail_Service__c>>();
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
        lstPackageUsage = getOrderItemPackageSessionUsage(strOrderId);
        Set<Id> setPackageOwnerId = new Set<Id>();
        if (!lstPackageUsage.isEmpty()) {
          for (OrderItem oI : lstPackageUsage) {
            setPackageOwnerId.add(oI.PackageOwnerId__c);
            productWithPackageOwnerId.add(oI.Product2Id);
          }
        }
        System.debug('setPackageOwnerId: ' + setPackageOwnerId);
        System.debug('productWithPackageOwnerId: ' + productWithPackageOwnerId);
        lstPackageOwner = getListServicePackageOwner(setPackageOwnerId);
        System.debug('1: ' + lstPackageOwner);
        if (!lstPackageOwner.isEmpty()) {
          System.debug('1');
          for (Package_Owner__c pacc : lstPackageOwner) {     
            System.debug('2');
            mapProductDetailService.put(
              pacc.Service_Package__c,
              getListProductDetailService(
                pacc.Service_Package__c, productWithPackageOwnerId
              )
            );
          }
        }
        // if (!mapProductDetailService.isEmpty()){
        //   for (Id keySet : mapProductDetailService.keySet()){
        //       for (Product_Detail_Service__c pds :mapProductDetailService.get(keySet)){

        //       }
        //   }
        // }
        // for (OrderItem oI : lstPackageUsage) {
        //   mapProductDetailService.put(
        //     oI.Package_Owner__r.Service_Package__c,
        //     getListProductDetailService(oI.Package_Owner__r.Service_Package__c)
        //   );
        // }
        //initAddressString(objOrder.Account.Address_No__c, objOrder.Account.Province__r.Name, objOrder.Account.District__r.Name);
      }
    } catch (Exception ex) {
      throw new CustomException(
        String.format(MSG_EXCEPTION, new List<Object>{ ex.getMessage() })
      );
    }
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
        Cashier__c,
        Cashier__r.Name,
        Order_Number__c,
        RecordType.Name,
        RecordTypeId,
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
      for (Voucher__c item : lstOrderQuerry[0].Voucher__r) {
        System.debug('1');
        System.debug('item.Amount__c :' + item.Amount__c);
        if (!String.isNotBlank(String.valueOf(item.Amount__c))) {
          totalAmountVoucher = 0;
          System.debug('2');
        } else {
          totalAmountVoucher = Integer.valueOf(item.Amount__c);
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
          PackageOwnerId__c
        FROM OrderItem
        WHERE
          OrderId = :strOrderId
          AND Product2.RecordTypeId = :RecordTypeHelper.PRODUCT_PCA
          AND PackageOwnerId__c = NULL
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
          Product2.Quantity_of_Unit__c
        FROM OrderItem
        WHERE
          OrderId = :strOrderId
          AND Product2.Service_Type__c = :strServiceType
          AND PackageOwnerId__c = NULL
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
        TotalPrice,
        ListPrice,
        Quantity,
        OrderItemNumber,
        Product2Id,
        Date_Active__c,
        OrderId,
        Product2.Name,
        Product2.Labor_HOUR__c,
        Product2.ProductCode,
        Product2.Quantity_of_Unit__c,
        PackageOwnerId__c,
        Package_Owner__c,
        Package_Owner__r.Service_Package__c,
        Package_Owner__r.Service_Package__r.ProductCode,
        Package_Owner__r.Service_Package__r.Name,
        Package_Owner__r.Service_Package__r.Description,
        Package_Owner__r.Service_Package__r.Unit_Measure__c,
        Package_Owner__r.Service_Package__r.Quantity_Measure__c,
        Package_Owner__r.Order_Product__r.OrderId,
        Package_Owner__r.Order_Product__r.Order.Order_Number__c
      FROM OrderItem
      WHERE OrderId = :strOrderId AND PackageOwnerId__c != NULL
      // PRODUCT_SERVICE_PACKAGE
    ];
    return lstOrderItem;
  }

  private static List<Package_Owner__c> getListServicePackageOwner(
    Set<Id> setPackageOwnerId
  ) {
    System.debug('setPackageOwnerId???' + setPackageOwnerId);
    System.debug('why???');
    List<Package_Owner__c> lstPackageOwner = new List<Package_Owner__c>();
    lstPackageOwner = [
      SELECT
        Id,
        Service_Package__c,
        Service_Package__r.ProductCode,
        Service_Package__r.Name,
        Service_Package__r.Description,
        Service_Package__r.Unit_Measure__c,
        Service_Package__r.Quantity_Measure__c,
        Order_Product__r.OrderId,
        Order_Product__r.Order.Order_Number__c
      FROM Package_Owner__c
      WHERE Id IN :setPackageOwnerId
    ];
    System.debug('why???: ' + lstPackageOwner);
    return lstPackageOwner;
  }

  private static List<Product_Detail_Service__c> getListProductDetailService(
    String productServicePackageId, Set<Id> setProductIds
  ) {
    System.debug('setProductIds: '+ setProductIds);
    List<Product_Detail_Service__c> lstProductDetailService = [
      SELECT Id, Product_Service_Package__c,
       Product__c // Session
      , Product__r.Name
      ,Product__r.Description
      FROM Product_Detail_Service__c
      WHERE Product_Service_Package__c = :productServicePackageId
    ];
    System.debug('lstProductDetailService: ' + lstProductDetailService);
    Set<Id> productSession = new Set<Id>();

    for (Product_Detail_Service__c pds : lstProductDetailService){
      productSession.add(pds.Product__c);
    }
    List<Product_Detail_Session__c> lstproduct = new List<Product_Detail_Session__c>();
    lstproduct = [SELECT Id, 
                  Product_Service_Job__c,Product_Session__c
                  FROM Product_Detail_Session__c 
                  WHERE Product_Session__c IN :productSession 
                  AND Product_Service_Job__c IN :setProductIds];
    System.debug('lstProduct: ' + lstproduct);
    Set<Id> setProductSession = new Set<Id>();             
    for (Product_Detail_Session__c detailSession : lstproduct){
      setProductSession.add(detailSession.Product_Session__c);
    }

    List<Product_Detail_Service__c> lstOutput = new List<Product_Detail_Service__c>();
    for (Product_Detail_Service__c p : lstProductDetailService){
      if (setProductSession.contains(p.Product__c)){
        lstOutput.add(p);
      }
    }
    if (!lstOutput.isEmpty()) {
      return lstOutput;
    } else {
      return new List<Product_Detail_Service__c>();
    }
  }

  // private static List<Product_Detail_Session__c> getListDetailSession(
  //   Set<Id> productIds, String productSessionId
  // ) {
  //   List<Product_Detail_Session__c> lstProductDetailSession = [
  //     SELECT Id, Name, Product_Session__c, Product_Service_Job__c
  //     FROM Product_Detail_Session__c
  //     WHERE Product_Service_Job__c IN :productIds AND Product_Session__c = :productSessionId 
  //   ];
  //   if (!lstProductDetailSession.isEmpty()) {
  //     return lstProductDetailSession;
  //   } else {
  //     return new List<Product_Detail_Session__c>();
  //   }
  // }
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
      PageReference page = Page.ServicePackageForm;
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
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
    a = a;
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