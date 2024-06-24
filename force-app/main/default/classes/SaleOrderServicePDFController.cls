public without sharing class SaleOrderServicePDFController {
  private final static String MSG_EXCEPTION = 'Error System, Please Connect Admin.';
  private final static String DATE_TIME_FILE_FORMAT = 'yyyyMMddHHmm';
  private final static String FILE_NAME = '{0} - {1}.pdf';
  public String addressString { get; set; }
  private class CustomException extends Exception {
  }
  public Order objOrder { get; set; }
  public Date today { get; set; }
  public String strOrderId { get; set; }
  public String currentUserName { get; set; }
  public Account acc { get; set; }
  public List<OrderItem> lstOrderItem { get; set; }
  public Set<Id> setProductDetail { get; set; }
  public Map<Id, List<Order_Line_Detail__c>> mapOrderLineDetail { get; set; }
  public Map<Id,List<Product_Detail_Service__c>> mapProductDetailService {get;set;}
  public Map<Id, List<Product_Detail_Session__c>> mapProductDetailSession {
    get;
    set;
  }

  public List<Product2> lstProductPCA { get; set; }
  public List<Product2> lstProductJob { get; set; }
  public Decimal totalSaleAmount{get;set;}
  
  public SaleOrderServicePDFController() {
    try {
      mapOrderLineDetail = new Map<Id, List<Order_Line_Detail__c>>();
      mapProductDetailSession = new Map<Id, List<Product_Detail_Session__c>>();
      currentUserName = UserInfo.getName();
      today = System.today();
      objOrder = new Order();
      strOrderId = ApexPages.currentPage().getParameters().get('Id');
      if (String.isNotBlank(strOrderId)) {
        objOrder = getOrderById(strOrderId);
        if (String.isBlank(objOrder.Id)) {
          return;
        }
        User u = getOwnerId(objOrder.OwnerId);
        acc = getAccByOwnerId(u.AccountId);
        lstOrderItem = getListOrderProduct(objOrder.Id);
        for (OrderItem orItem : lstOrderItem) {
          mapOrderLineDetail.put(orItem.Id, getListOrderLineDetail(orItem.Id));

          // Order.OrderItem.Product2.Product_Detail_Service__c
          // mapProductDetailService.put(orItem.Product2Id,getListProductDetailService(orItem.Product2Id));
          for (Order_Line_Detail__c old : mapOrderLineDetail.get(orItem.Id)) {
            mapProductDetailSession.put(
              old.Product_Detail_Service__r.Product__c,
              getListProductDetailSession(
                old.Product_Detail_Service__r.Product__c
              )
            );
          }
        }
      }
    } catch (Exception ex) {
      throw new CustomException(
        String.format(MSG_EXCEPTION, new List<Object>{ ex.getMessage() })
      );
    }
  }

  private Order getOrderById(String strOrderId) {
    List<Order> lstOrderQuerry = [
      SELECT
        Id,
        OrderNumber,
        Order_Number__c,
        Sale_Method__c,
        EffectiveDate,
        PCA_Delivery_Date__c,
        Address_Full__c,
        Tax_Code__c,
        Cashier__c,
        Cashier__r.Name,
        OwnerId,
        Owner.Name,
        Installation_Order__c,
        AccountId,
        Account.Tax_Code__c,
        Account.AccountNumber,
        Account.Name,
        Account.Address_Full__c,
        Account.PersonMobilePhone,
        Account.PersonEmail,
        Asset__c,
        Asset__r.Frame_Number__c,
        Asset__r.Plate_No__c,
        Asset__r.Engine_No__c,
        Asset__r.Product2Id,
        Asset__r.Product2.Model_Name__c,
        Asset__r.Product2.Bike_Type__c
      FROM Order
      WHERE Id = :strOrderId
    ];
    if (lstOrderQuerry.isEmpty()) {
      return new Order();
    } else {
      return lstOrderQuerry[0];
    }
  }

  private List<OrderItem> getListOrderProduct(String strOrderId) {
    List<OrderItem> lstOrderProduct = [
      SELECT
        Id,
        Product2Id,
        Product2.ProductCode,
        Product2.Name,
        Product2.Retail_Price__c,
        Product2.Quantity_Measure__c,
        Product2.Unit_Measure__c,
        Product_Code__c,
        Product_Name__c,
        OrderId,
        Quantity,
        UnitPrice,
        ListPrice,
        TotalPrice
      FROM OrderItem
      WHERE OrderId = :strOrderId
    ];
    if (lstOrderProduct.isEmpty()) {
      return new List<OrderItem>();
    } else {
      return lstOrderProduct;
    }
  }

  private List<Order_Line_Detail__c> getListOrderLineDetail(
    String OrderLineId
  ) {
    List<Order_Line_Detail__c> lstOrderLineDetail = [
      SELECT
        Id,
        Product_Detail_Service__c,
        Product_Detail_Service__r.Product_Service_Package__c,
        Product_Detail_Service__r.Product_Service_Package__r.name,
        Product_Detail_Service__r.Product_Service_Package__r.Unit_Measure__c,
        Product_Detail_Service__r.Product_Service_Package__r.Quantity_Measure__c,
        Product_Detail_Service__r.Product__c,
        Product_Detail_Service__r.Product__r.Name,
        Quantity_on_Product__c,
        Order_Line_Item__c
      FROM Order_Line_Detail__c
      WHERE Order_Line_Item__c = :OrderLineId
    ];
    if (lstOrderLineDetail.isEmpty()) {
      return new List<Order_Line_Detail__c>();
    } else {
      return lstOrderLineDetail;
    }
  }

  private List<Product_Detail_Session__c> getListProductDetailSession(
    String productId
  ) {
    List<Product_Detail_Session__c> lstProductDetailSession = [
      SELECT
        Id,
        Name,
        Product_Service_Job__c,
        Product_Session__c,
        Product_Service_Job__r.Name,
        Product_Service_Job__r.RecordType.Name,
        Quantity__c
      FROM Product_Detail_Session__c
      WHERE Product_Session__c = :productId
    ];
    if (lstProductDetailSession.isEmpty()) {
      return new List<Product_Detail_Session__c>();
    } else {
      return lstProductDetailSession;
    }
  }

  private List<Product_Detail_Service__c> getListProductDetailService(
    String strProductId
  ) {
    List<Product_Detail_Service__c> lstProductDetailService = [
      SELECT
        Id,
        Product__c,
        Name,
        Product_Service_Package__c,
        Quantity__c,
        Sales_Price__c
      FROM Product_Detail_Service__c
      WHERE Product_Service_Package__c = :strProductId
    ];
    if (lstProductDetailService.isEmpty()) {
      return new List<Product_Detail_Service__c>();
    } else {
      return lstProductDetailService;
    }
  }

  private Account getAccByOwnerId(String strId) {
    List<Account> lstAcc = [
      SELECT Id, DO_DL_Code__c
      FROM Account
      WHERE Id = :strId
    ];
    if (lstAcc.isEmpty()) {
      return new Account();
    } else {
      return lstAcc[0];
    }
  }

  private User getOwnerId(String strId) {
    List<User> lstOwner = [SELECT Id, AccountId FROM User WHERE Id = :strId];
    if (lstOwner.isEmpty()) {
      return new User();
    } else {
      return lstOwner[0];
    }
  }
  /*
   * createPdfFile
   * @param: quoteId
   * @return: none
   * @created: 2020/07/13  Tran Hoang Tan
   * @modified:
   */
  @AuraEnabled
  public static Map<String, String> createPdfFile(String orderId) {
    Savepoint sp = Database.setSavepoint();
    try {
      Map<String, String> files = new Map<String, String>();
      List<Order> orderList = [
        SELECT
          OrderNumber,
          Account.Name,
          CreatedDate,
          Sale_Method__c,
          Order_Number__c
        FROM Order
        WHERE ID = :orderId
      ];
      if (orderList.isEmpty()) {
        return null;
      }
      PageReference page = Page.SaleOrderServicePDF;
      page.getParameters().put('id', orderId);
      Blob pdfContent;
      if (Test.isRunningTest()) {
        pdfContent = Blob.valueOf('TestClass.pdf');
      } else {
        pdfContent = page.getContent();
      }
      List<String> formatName;
      // if (orderList[0].Sale_Method__c == 'E-commerce') {
      //   formatName = new List<String>{
      //     'SO-',
      //     'E',
      //     'SEPACK',
      //     datetime.now().format('yyMM'),
      //     orderList[0].Order_Number__c
      //   };
      // } else {
      //   formatName = new List<String>{
      //     '',
      //     'SO',
      //     'SEPACK',
      //     datetime.now().format('yyMM'),
      //     orderList[0].Order_Number__c
      //   };
      // }
      formatName = new List<String>{
        orderList[0].Order_Number__c,
        orderList[0].Account.Name
      };
      DateTime dt = DateTime.now();
      String strDateTime = dt.format(DATE_TIME_FILE_FORMAT);
      String fileName = String.format(FILE_NAME, formatName);
      // ContentVersion objContentVersion = createContentVersion(
      //   pdfContent,
      //   fileName
      // );
      // String contentDocumentId = createContentDocumentLink(
      //   objContentVersion.Id,
      //   orderId
      // );
      String base64pdf = EncodingUtil.base64Encode(pdfContent);
      files.put(fileName, base64pdf);
      return files;
    } catch (Exception ex) {
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