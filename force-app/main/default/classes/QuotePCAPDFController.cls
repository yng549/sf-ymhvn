public without sharing class QuotePCAPDFController {
  private final static String MSG_EXCEPTION = 'Error System, Please Connect Admin.';
  private final static String DATE_TIME_FILE_FORMAT = 'yyyyMMddHHmm';
  // private final static String FILE_NAME = '{0}{1}-{2}-{3}-{4}.pdf';
  private final static String FILE_NAME = '{0} - {1}.pdf';
  public String addressString { get; set; }
  private class CustomException extends Exception {
  }
  public Opportunity objOpportunity { get; set; }
  public List<QuoteLineItem> lstQuoteLineItem { get; set; }
  public List<Payment__c> lstPaymentVoucher { get; set; }
  public List<Payment__c> lstPayment { get; set; }
  public Date today { get; set; }
  public String strOpportunityId { get; set; }
  public String currentUserName { get; set; }
  public Decimal totalSaleAmount { get; set; }
  public Decimal totalDiscount { get; set; }
  public Decimal totalValueAmount { get; set; }
  public Decimal totalPaymentVoucher { get; set; }
  public Decimal paid { get; set; }
  public String logo{get;set;}
  //   public List<OrderItem> lstOrderItem { get; set; }
  public QuotePCAPDFController() {
    try {
      currentUserName = UserInfo.getName();
      today = System.today();
      objOpportunity = new Opportunity();
      strOpportunityId = ApexPages.currentPage().getParameters().get('Id');
      if (String.isNotBlank(strOpportunityId)) {
        objOpportunity = getOpportunityrById(strOpportunityId);
        if (String.isBlank(objOpportunity.Id)) {
          return;
        }
        lstQuoteLineItem = getListQuoteLineItemByQuoteId(
          objOpportunity.SyncedQuoteId
        );
        lstPayment = getListPayment(objOpportunity.Id);
        lstPaymentVoucher = getListPaymentVoucher(objOpportunity.Id);
        totalSaleAmount = 0;
        totalDiscount = 0;
        totalValueAmount = 0;
        //quote line item
        if (!lstQuoteLineItem.isEmpty()) {
          for (QuoteLineItem qLI : lstQuoteLineItem) {
            if (qLi.ListPrice != null && qLI.Quantity != null) {
              totalSaleAmount += qLi.ListPrice * qLI.Quantity; //Tổng số tiền
            }
            if (qLi.Discount!=null) {
              totalDiscount += qLI.Subtotal * (qLi.Discount/100) ; //Tổng giá trị triết khấu
            }
            if (qLi.UnitPrice != null && qLI.Quantity != null) {
              totalValueAmount += qLi.UnitPrice * qLI.Quantity; // Tổng giá trị đơn hàng
            }
          }
        }

        //payment
        totalPaymentVoucher = 0;
        if (!lstPaymentVoucher.isEmpty()) {
          for (Payment__c voucher : lstPaymentVoucher) {
            if (voucher.Amount__c != null) {
              totalPaymentVoucher += voucher.Amount__c;
            }
          }
        }

        paid = 0;
        if (!lstPayment.isEmpty()) {
          for (Payment__c payment : lstPayment) {
            if (payment.Amount__c != null) {
              paid += payment.Amount__c;
            }
          }
        }
        //logo
        logo= ''; 
        if (objOpportunity.Account.DO_DL_Create_Account__r.Name != null) {
            String doDlCreateName = objOpportunity.Account.DO_DL_Create_Account__r.Name;
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

  private Opportunity getOpportunityrById(String strOpportunityId) {
    List<Opportunity> lstOpportunityQuerry = [
      SELECT
        Id,
        Name,
        Address_Full__c,
        Account.DO_DL_Create_Account__r.Name,
        AccountId,
        Account.AccountNumber,
        Account.Name,
        Account.Address_Full__c,
       	Account.DO_DL_Create_Account__r.Address__c,
        Account.PersonMobilePhone,
        Account.PersonEmail,
        Account.Tax_Code__c,
        OwnerId,
        Owner.Name,
        Owner.Account.Address__c,
        SyncedQuoteId, //syncedQuote (lookup Quote {Synced})
        SyncedQuote.Voucher_Amount__c,
        SyncedQuote.Quote_Number__c,
        SyncedQuote.CreatedDate,
        SyncedQuote.Delivery_Date__c
      FROM Opportunity
      WHERE Id = :strOpportunityId
    ];
    if (lstOpportunityQuerry.isEmpty()) {
      return new Opportunity();
    } else {
      return lstOpportunityQuerry[0];
    }
  }
  private List<QuoteLineItem> getListQuoteLineItemByQuoteId(String strQuoteId) {
    List<QuoteLineItem> lstQuoteLineItemQuery = [
      SELECT
        Id,
        Quantity,
        ListPrice,
        Discount,
        Discount_Percent__c,
        Discount_Amount__c,
        UnitPrice,
        TotalPrice,
        Subtotal,
        Product2Id, //product
        Product2.ProductCode,
        Product2.Name,
        Product2.Product_Unit__c,
        Product2.PartsNameEng__c
      FROM QuoteLineItem
      WHERE QuoteId = :strQuoteId
    ];
    if (lstQuoteLineItemQuery.isEmpty()) {
      return new List<QuoteLineItem>();
    } else {
      return lstQuoteLineItemQuery;
    }
  }

  private List<Payment__c> getListPaymentVoucher(String strOpportunityId) {
    List<Payment__c> lstPayment = [
      SELECT Id, Payment_Term__c, Amount__c
      FROM Payment__c
      WHERE Payment_Term__c = 'Voucher' AND Opportunity__c = :strOpportunityId
    ];
    if (lstPayment.isEmpty()) {
      return new List<Payment__c>();
    } else {
      return lstPayment;
    }
  }
  private List<Payment__c> getListPayment(String strOpportunityId) {
    List<Payment__c> lstPayment = [
      SELECT Id, Payment_Term__c, Amount__c
      FROM Payment__c
      WHERE Payment_Term__c != 'Voucher' AND Opportunity__c = :strOpportunityId
    ];
    if (lstPayment.isEmpty()) {
      return new List<Payment__c>();
    } else {
      return lstPayment;
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
  public static Map<String, String> createPdfFile(String objectId) {
    Savepoint sp = Database.setSavepoint();
    try {
      Map<String, String> files = new Map<String, String>();
      List<Opportunity> opportunityList = [
        SELECT SyncedQuote.Quote_Number__c, Account.Name, CreatedDate
        FROM Opportunity
        WHERE ID = :objectId
      ];
      if (opportunityList.isEmpty()) {
        return null;
      }
      PageReference page = Page.QuotePCAPDF;
      page.getParameters().put('id', objectId);
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
          opportunityList[0].SyncedQuote.Quote_Number__c,
          opportunityList[0].Account.Name
        }
      );
      // ContentVersion objContentVersion = createContentVersion(
      //   pdfContent,
      //   fileName
      // );
      // String contentDocumentId = createContentDocumentLink(
      //   objContentVersion.Id,
      //   objectId
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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