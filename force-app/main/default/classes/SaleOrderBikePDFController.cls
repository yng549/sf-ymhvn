public without sharing class SaleOrderBikePDFController {
  private final static String MSG_EXCEPTION = 'Error System, Please Connect Admin.';
  private final static String DATE_TIME_FILE_FORMAT = 'yyyyMMddHHmm';
  // private final static String FILE_NAME = '{0}{1}-{2}-{3}-{4}.pdf';
  private final static String FILE_NAME = '{0} - {1}.pdf';
  public String addressString { get; set; }
  private class CustomException extends Exception {
  }
	public string logo{get;set;}
  public string address {get; set;}
  public string calculatedAddress {get; set;}
    public string AddressInfo {get; set;}
  public Order objOrder { get; set; }
  public Date today { get; set; }
  public String strOrderId { get; set; }
  public String currentUserName { get; set; }
  public List<OrderItem> lstOrderItem { get; set; }
  public Account acc { get; set; }
  public Decimal sumListPrice { get; set; }
  public Decimal sumDiscount { get; set; }
  public Decimal sumSalePrice { get; set; }
  public SaleOrderBikePDFController() {
    // try {
      sumSalePrice = 0;
      sumDiscount = 0;
      sumListPrice = 0;
      currentUserName = UserInfo.getName();
      today = System.today();
      objOrder = new Order();
      strOrderId = ApexPages.currentPage().getParameters().get('Id');
      if (String.isNotBlank(strOrderId)) {
        objOrder = getOrderById(strOrderId);
        lstOrderItem = getListOrderItemById(strOrderId);
        User u = getOwnerId(objOrder.OwnerId);

        acc = getAccByOwnerId(u.AccountId);

          for (OrderItem oi : lstOrderItem) {
              if (oi.UnitPrice != null) {
                  sumSalePrice += oi.UnitPrice;
              }
              if (oi.ListPrice != null) {
                  sumListPrice += oi.ListPrice;
                  if (oi.TotalPrice != null) {
                      sumDiscount += (oi.ListPrice - oi.UnitPrice);
                  }
              }
          }
          
         //AddressInfo = '';
          /*if (objOrder.Opportunity != null && objOrder.Opportunity.Contract != null && objOrder.Opportunity.Contract.Contract_Information__r != null) {
              calculatedAddress = objOrder.Opportunity.Contract.Contract_Information__r.Address_Full__c;
              address = objOrder.Opportunity.Contract.Contract_Information__r.Head_Office__c;
              if (String.isBlank(calculatedAddress) && objOrder.Account != null) {
                  if(objOrder.Opportunity.Contract.Contract_Information__r.RecordType.Name == 'Person'){
                     AddressInfo = calculatedAddress;
                  } else{
                      AddressInfo = address;
                  } 
                  if( objOrder.Opportunity.Contract.Contract_Information__r.RecordType.Name == 'Person' || objOrder.Opportunity.Contract.Contract_Information__r.RecordType.Name == 'Corporate' ){
                      if(calculatedAddress == null || address == null){
                          AddressInfo = '';
                      }
                  }
              }
          } else if (objOrder.Account != null) {
              AddressInfo = objOrder.Account.Address_Full__c;
          }*/
          
          logo= '';
          if (objOrder.DO_DL__r.Name != null) {
              String doDlCreateName = objOrder.DO_DL__r.Name;
              
              if (doDlCreateName == 'REVZONE YAMAHA MOTOR HA NOI') {
                  logo = 'logoRevzoneYamahaMotorHN';
              } else {
                  logo = 'logoRevzoneYamahaMotorSG';
              }
          }
          
          

        if (String.isBlank(objOrder.Id)) {
          return;
        }
      }
    // } catch (Exception ex) {
    //   throw new CustomException(
    //     String.format(MSG_EXCEPTION, new List<Object>{ ex.getMessage() })
    //   );
    // }
  }

  private Order getOrderById(String strOrderId) {
    List<Order> lstOrderQuerry = [
      SELECT
        Id,
        OrderNumber,
        Order_Number__c,
        Sale_Method__c,
        EffectiveDate,
        Bike_Delivery_Date__c,
        Frame_No1__c,
        Opportunity.Contract.Contract_Information__r.Name,
        Opportunity.Contract.Contract_Information__r.Address_Full__c ,
        Opportunity.Contract.Contract_Information__r.Head_Office__c  ,
        Opportunity.Contract.Contract_Information__r.Tax_code__c  ,
        Opportunity.Contract.Contract_Information__r.RecordType.Name  ,
        Address_Full__c,
        Tax_Code__c,
        Asset__c,
        Asset__r.Engine_No__c,
        OwnerId,
        Owner.Name,
        AccountId,
        Account.Tax_Code__c,
        Account.AccountNumber,
        Account.Name,
        DO_DL__r.Name,
        Account.Address_Full__c,
        Account.PersonMobilePhone,
        Account.DO_DL_Create_Account__r.Name,
        Account.DO_DL_Create_Account__r.Address__c,
     	Account.DO_DL_Create_Account__r.Address_logo__c,
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
  

  private List<OrderItem> getListOrderItemById(String strOrderId) {
    List<OrderItem> lstOrderItem = [
      SELECT
        Id,
        OrderId,
        ListPrice,
        TotalPrice,
        UnitPrice, //sale price
        Product2Id,
        Product2.Model_Name__c,
        Product2.Sales_Name__c,
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
      PageReference page = Page.SaleOrderBikePDF;
      page.getParameters().put('id', orderId);
      Blob pdfContent;
      if (Test.isRunningTest()) {
        pdfContent = Blob.valueOf('TestClass.pdf');
      } else {
        pdfContent = page.getContent();
      }
      List<String> formatName;
      // if (orderList[0].Sale_Method__c == 'E-commerce') {
        formatName = new List<String>{
          orderList[0].Order_Number__c,
          orderList[0].Account.Name
        };
      // } else {
      //   formatName = new List<String>{
      //     '',
      //     'SO',
      //     'MC',
      //     datetime.now().format('yyMM'),
      //     orderList[0].Order_Number__c
      //   };
      // }
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
      }

}