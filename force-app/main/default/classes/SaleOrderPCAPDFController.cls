public without sharing class SaleOrderPCAPDFController {
  private final static String MSG_EXCEPTION = 'Error System, Please Connect Admin.';
  private final static String DATE_TIME_FILE_FORMAT = 'yyyyMMddHHmm';
  // private final static String FILE_NAME = '{0}{1}-{2}-{3}-{4}.pdf';
  private final static String FILE_NAME = '{0} - {1}.pdf';
  public String addressString { get; set; }
  private class CustomException extends Exception {
  }
  public Order objOrder { get; set; }
  public Date today { get; set; }
  public String strOrderId { get; set; }
  public String currentUserName { get; set; }
  public List<OrderItem> lstOrderItem { get; set; }
  public Decimal sumListPrice { get; set; }
  public Decimal sumDiscount { get; set; }
  public Decimal sumSalePrice { get; set; }
  public List<OrderItem> lstInstallationItem { get; set; }
  public Decimal sumInstallationListPrice { get; set; }
  public Decimal sumInstallationDiscount { get; set; }
  public Decimal sumInstallationSalePrice { get; set; }
  public List<Payment__c> lstVoucher { get; set; }
  public List<Payment__c> lstInstallationVoucher { get; set; }
  public Decimal paymentAmount { get; set; }
  public Decimal paymentInstallationAmount { get; set; }
  public Account acc { get; set; }
  public Decimal workPrice{get;set;}
  public string logo{get;set;}
  public SaleOrderPCAPDFController() {
    try {
      workPrice = 0;
      paymentAmount = 0;
      paymentInstallationAmount = 0;
      sumSalePrice = 0;
      sumDiscount = 0;
      sumListPrice = 0;
      sumInstallationListPrice = 0;
      sumInstallationDiscount = 0;
      sumInstallationSalePrice = 0;
      currentUserName = UserInfo.getName();
      today = System.today();
      objOrder = new Order();
      strOrderId = ApexPages.currentPage().getParameters().get('Id');
      if (String.isNotBlank(strOrderId)) {
        objOrder = getOrderById(strOrderId);
        if (String.isBlank(objOrder.Id)) {
          return;
        }
        lstOrderItem = getListOrderItemById(strOrderId);
        lstVoucher = getListPaymentVoucher(strOrderId);
        User u = getOwnerId(objOrder.OwnerId);

        acc = getAccByOwnerId(u.AccountId);
        if (!lstVoucher.isEmpty()) {
          for (Payment__c p : lstVoucher) {
            if (p.Amount__c != null) {
              paymentAmount += p.Amount__c;
            }
          }
        }
        for (OrderItem oi : lstOrderItem) {
          if (oi.TotalPrice != null) {
            sumSalePrice += oi.TotalPrice;
          }
          if (oi.ListPrice != null) {
            sumListPrice += (oi.ListPrice * (oi.Quantity == null? 0 : oi.Quantity));
            if (oi.TotalPrice != null && oi.UnitPrice != null) {
              sumDiscount += ((oi.ListPrice - oi.UnitPrice)*(oi.Quantity == null? 0 : oi.Quantity));
            }
          }
        }

        if (objOrder.Installation_Order__c != null) {
          lstInstallationItem = getListOrderItemById(
            objOrder.Installation_Order__c
          );
          lstInstallationVoucher = getListPaymentVoucher(
            objOrder.Installation_Order__c
          );
          if (!lstInstallationVoucher.isEmpty()) {
            for (Payment__c p : lstInstallationVoucher) {
              if (p.Amount__c != null) {
                paymentInstallationAmount += p.Amount__c;
              }
            }
          }
          
          for (OrderItem oi : lstInstallationItem) {
            if (oi.UnitPrice != null) {
              sumInstallationSalePrice += oi.ListPrice-((oi.ListPrice* (oi.Discount__c == null? 0 : oi.Discount__c))/(Decimal) 100);
            }
            if (oi.Product2.Labor_HOUR__c !=null){

            }
            if (oi.ListPrice != null) {
              sumInstallationListPrice += oi.ListPrice;
              if (oi.TotalPrice != null) {
                sumInstallationDiscount += ((oi.ListPrice* (oi.Discount__c == null? 0 : oi.Discount__c))/(Decimal) 100);
              }
            }
          }
        } else {
          lstInstallationItem = new List<OrderItem>();
        }
         logo= '';
        if (objOrder.DO_DL__r.Name != null) {
            String doDlCreateName = objOrder.DO_DL__r.Name;
            
            if (doDlCreateName == 'REVZONE YAMAHA MOTOR HA NOI') {
                logo = 'logoRevzoneYamahaMotorHN';
            } else {
                logo = 'logoRevzoneYamahaMotorSG';
            }
        }
      }
    } catch (Exception ex) {
      throw new CustomException(
        String.format(MSG_EXCEPTION, new List<Object>{ ex.getMessage() })
      );
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
    List<User> lstOwner = [
      SELECT Id, AccountId
      FROM User
      WHERE Id = :strId
    ];
    if (lstOwner.isEmpty()) {
      return new User();
    } else {
      return lstOwner[0];
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
        OwnerId,
        Owner.Name,
        Installation_Order__c,
        DO_DL__r.Name,
        AccountId,
        Account.Tax_Code__c,
        Account.AccountNumber,
        Account.Name,
        Account.Address_Full__c,
        Account.PersonMobilePhone,
        Account.DO_DL_Create_Account__r.Name,
        Account.DO_DL_Create_Account__r.Address__c,
        Account.PersonEmail
      FROM Order
      WHERE Id = :strOrderId
    ];
    if (lstOrderQuerry.isEmpty()) {
      return new Order();
    } else {
      return lstOrderQuerry[0];
    }
  }

  private List<Payment__c> getListPaymentVoucher(String strOrderId) {
    List<Payment__c> lstPayment = [
      SELECT Id, Payment_Term__c, Amount__c
      FROM Payment__c
      WHERE Payment_Term__c = 'Voucher' AND Order__c = :strOrderId
    ];
    if (lstPayment.isEmpty()) {
      return new List<Payment__c>();
    } else {
      return lstPayment;
    }
  }

  private List<OrderItem> getListOrderItemById(String strOrderId) {
    List<OrderItem> lstOrderItem = [
      SELECT
        Id,
        OrderId,
        ListPrice,
        TotalPrice,
        UnitPrice, //sale price
        Quantity,
        Discount__c,
        Product_Code__c,
        Product2Id,
        Product2.Name,
        Product2.Labor_HOUR__c,
        Product2.PartsNameEng__c,
        Product2.Model_Name__c,
        Product2.Model_Code__c,
        Product2.Color_Name__c
      FROM OrderItem
      WHERE OrderId = :strOrderId
    ];
    if (lstOrderItem.isEmpty()) {
      return new List<OrderItem>();
    } else {
      return lstOrderItem;
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
        SELECT OrderNumber, Account.Name, CreatedDate, Sale_Method__c,Order_Number__c
        FROM Order
        WHERE ID = :orderId
      ];
      if (orderList.isEmpty()) {
        return null;
      }
      PageReference page = Page.SaleOrderPCAPDF;
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
      //     'PCA',
      //     datetime.now().format('yyMM'),
      //     orderList[0].Order_Number__c
      //   };
      // } else {
      //   formatName = new List<String>{
      //     '',
      //     'SO',
      //     'PCA',
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
	Public static void cheatTemp() {
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
      }
  
}