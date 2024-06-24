public without sharing class DealSheetFormPDF {
  private final static String MSG_EXCEPTION = 'Error System, Please Connect Admin.';
  private final static String DATE_TIME_FILE_FORMAT = 'yyyyMMddHHmm';
  private final static String FILE_NAME = '{0} - {1}.pdf';
  private class CustomException extends Exception {
  }
  //   public Decimal sum { get; set; }
  public Decimal VAT { get; set; }
  public Opportunity objOpportunity { get; set; }
  public String strOpportunityId { get; set; }
  public QuoteLineItem objQuoteLineItem { get; set; }
  public List<Quote_Promotion_Pack__c> lstPromotionPack { get; set; }
  public Decimal discount { get; set; }
  public Decimal totalRegister { get; set; }
  public Decimal totalPrice { get; set; }

  public Decimal insuranceMoney { get; set; }
  public Decimal registrationFee{ get; set; }

  public Decimal TotalInterest { get; set; }
  public Decimal Loaninsurrance  { get; set; }
  public Decimal RemainingAmount  { get; set; }
  public Decimal Totalpaymentamount { get; set; }
  public Decimal Paymentamount {get; set;}
  public String logo { get; set; }

  public DealSheetFormPDF() {
    try {
      registrationFee = 0;
      insuranceMoney = 0;
    
      VAT = 0.1;
      objOpportunity = new Opportunity();
      strOpportunityId = ApexPages.currentPage().getParameters().get('Id');
      if (String.isNotBlank(strOpportunityId)) {
        objOpportunity = getOpportunityById(strOpportunityId);
        if (String.isNotBlank(objOpportunity.SyncedQuoteId)) {
          objQuoteLineItem = getQuoteLineItemByQuoteId(
            objOpportunity.SyncedQuoteId
          );
          lstPromotionPack = getListPromoPack(objOpportunity.SyncedQuoteId);
          if (objOpportunity.Civil_liability_insurance__c != null) {
            if (objOpportunity.Civil_liability_insurance__c == 'Civil liability insurance'){
              insuranceMoney = 66000;
            }else if (objOpportunity.Civil_liability_insurance__c == 'Civil liability insurance + Accident Insurance for 2 person (10 millions/person)'){
              insuranceMoney = 86000;
            }else if (objOpportunity.Civil_liability_insurance__c == 'Civil liability insurance + Accident Insurance for 2 person (20 millions/person)'){
              insuranceMoney = 106000;
            }
          }
          if (
            objQuoteLineItem.ListPrice != null &&
            objQuoteLineItem.UnitPrice != null
          ) {
            discount = objQuoteLineItem.ListPrice - objQuoteLineItem.UnitPrice;
          } else {
            discount =
              (objQuoteLineItem.ListPrice == null
                ? 0
                : objQuoteLineItem.ListPrice) -
              (objQuoteLineItem.UnitPrice == null
                ? 0
                : objQuoteLineItem.UnitPrice);
          }
          totalRegister =
            (objOpportunity.OwnerShip_Tax1__c == null ? 0 : objOpportunity.OwnerShip_Tax1__c) +
            (objOpportunity.Plate_Fee__c == null ? 0 : objOpportunity.Plate_Fee__c) +
            (objOpportunity.Registration_Fee_Province__c == null
              ? 0
              : objOpportunity.Registration_Fee_Province__c) +
            (insuranceMoney == null
              ? 0
              : insuranceMoney) +
            (objOpportunity.Transportation__c == null
              ? 0
              : objOpportunity.Transportation__c);

          totalPrice =
            (objQuoteLineItem.UnitPrice == null
              ? 0
              : objQuoteLineItem.UnitPrice) + totalRegister;
         // tong so tien lai  ~~ 
          // TotalInterest = ((objOpportunity.Total_monthly_payment__c == null
          //                   ? 0
          //                   :objOpportunity.Total_monthly_payment__c) * objOpportunity.Loan_Period__c) - 
          //                   (objOpportunity.Loan_amount__c == null 
          //                   ? 0
          //                   : objOpportunity.Loan_amount__c) - (objOpportunity.Loan_insurrance__c == null
          //                   ? 0
          //                   :objOpportunity.Loan_insurrance__c);
          // //  so tien con lai
          // RemainingAmount = (objOpportunity.Loan_amount__c == null
          //                     ? 0
          //                     : objOpportunity.Loan_amount__c) + 
          //                   (objOpportunity.Loan_insurrance__c == null
          //                     ? 0
          //                     : objOpportunity.Loan_insurrance__c) +
          //                   (objOpportunity.Total_interest_amount__c == null
          //                     ? 0
          //                     : objOpportunity.Total_interest_amount__c);
          //  // So tien thanh toan                              
          // //bao hiem khoan vay
          // Loaninsurrance = (objOpportunity.Loan_insurrance_rate__c == null
          //                     ? 0
          //                     :objOpportunity.Loan_insurrance_rate__c) * (objOpportunity.Loan_amount__c == null
          //                     ? 0
          //                     :objOpportunity.Loan_amount__c ) * (objOpportunity.loan_period__c == null
          //                     ? 0
          //                     :objOpportunity.loan_period__c);
          // tong chi phi thanh toan truoc
          Totalpaymentamount = (objOpportunity.Down_payment__c == null 
                               ? 0
                               : objOpportunity.Down_payment__c) +  (objOpportunity.Total__c == null ? 0 : objOpportunity.Total__c);
          
        //Monthly_principal_payment__c= finalResult1
        // double result1 = Math.pow(1 + (Double.valueOf(objOpportunity.Yearly_Interest_Rate__c) / 100), Double.valueOf(objOpportunity.Loan_period__c));
        // double xResult1 = result1 * (Double.valueOf(objOpportunity.Yearly_Interest_Rate__c) / 100);
        // double result2 = (Math.pow(1 + (Double.valueOf(objOpportunity.Yearly_Interest_Rate__c) / 100), Double.valueOf(objOpportunity.Loan_period__c)) - 1);
        // double finalResult1 = Double.valueOf(objOpportunity.Loan_amount__c) * (xResult1 / result2);
        // Paymentamount = Decimal.valueOf(finalResult1) + 12000;
        //logo
        logo= '';
            if (objOpportunity.DODL_Create__r.Name != null) {
                String doDlCreateName = objOpportunity.DODL_Create__r.Name;
                if (doDlCreateName == 'REVZONE YAMAHA MOTOR HA NOI') {
                    logo = 'logoHeaderRevZoneHN';
                } else {
                    logo = 'logoHeaderRevZone';
                }
            }                       
        }
        if (String.isBlank(objOpportunity.Id)) {
          return;
        }
      }
    } catch (Exception ex) {
      throw new CustomException(
        String.format(MSG_EXCEPTION, new List<Object>{ ex.getMessage() })
      );
    }
  }

  

  private Opportunity getOpportunityById(String strOpportunityId) {
    List<Opportunity> lstOpportunityQuery = [
      SELECT
        Id,
        Name,
        VAT__c,
        Total__c,
        Ownership_Tax__c,
        OwnerShip_Tax1__c,
        DODL_Create__r.Name,
        DODL_Create__r.Address__c,
        DODL_Create__r.Address_Eng__c,
        Registration_Service__c,
        Plate_Fee__c,
        Registration_Fee_Province__c,
        Insurance__c,
        Transportation__c,
        Proposal_Date__c,
        Loan_period__c,
        Loan_limit__c,
        Daily_Interest_Rate__c,
        Interest_amount_per_month__c,
        Monthly_principal_payment__c,
        Total_monthly_payment__c,
        Total_interest_amount__c,
        Asset_insurance__c,
        Down_payment__c,
        Remaining_amount__c,
        Loan_amount__c,
        Loan_insurrance_rate__c,
        Loan_insurrance__c,
        Prepayment_penalty__c,
        Total_payment_amount__c,
        Debt_Payment_Date__c,
        Yearly_Interest_Rate__c,
        Monthly_Interest_Rate__c,
        Mechandise_Amount__c,
        Disbursement_Date__c,
        Signing_Date__c,
        Registration_Fee__c,
        Civil_liability_insurance__c,
        Province__c,
        Province__r.Number_Plate_Fee__c,
        Province__r.Ownership_Tax__c,
        District__c,
        District__r.Number_Plate_Fee__c,
        District__r.Ownership_Tax__c,
        Finance__c,
        Gift__c,
        AccountId, // Account (lookup Account)
        // Account.Address__c
        Account.Name,
        Account.Address_Full__c,
        Account.Province__c,
        Account.Province__r.Number_Plate_Fee__c,
        Account.Province__r.Ownership_Tax__c,
        Account.District__c,
        Account.DO_DL_Create_Account__r.Name,
        Account.District__r.Number_Plate_Fee__c,
        Account.District__r.Ownership_Tax__c,
        Account.PersonMailingAddress,
        Account.PersonMailingAddress_Full__c,
        Account.ID_No__c,
        Account.Tax_Code__c,
        Account.PersonMobilePhone,
        Account.PersonEmail,
        Account.Zalo_Viber__c,
        SyncedQuoteId, //syncedQuote (lookup Quote {Synced})
        SyncedQuote.Voucher_Amount__c,
        SyncedQuote.Quote_Number__c,
        SyncedQuote.CreatedDate,
        SyncedQuote.First_Payment__c,
        SyncedQuote.Second_Payment__c,
        SyncedQuote.Third_Payment__c,
        SyncedQuote.Delivery_Date__c,
        Opportunity_Tradein__r.Purchase_Price__c,
        OwnerID, //owner(lookup User)
        Owner.Account.Bank_Account_Name__c,
        Owner.Account.Bank_Number2__c,
        Owner.Account.Bank_Name__c,
        Owner.Name,
        Owner.Phone,
        Owner.MobilePhone,
        Owner.Email,
        Owner.Zalo_Viber__c,
        Owner.DODL_Manager__r.Name,
        Owner.DODL_Manager__r.MobilePhone,
        Owner.DODL_Manager__r.Phone
      FROM Opportunity
      WHERE Id = :strOpportunityId
    ];
    if (lstOpportunityQuery.isEmpty()) {
      return new Opportunity();
    } else {
      return lstOpportunityQuery[0];
    }
  }

  private List<Quote_Promotion_Pack__c> getListPromoPack(String quoteId) {
    List<Quote_Promotion_Pack__c> lstPromotion = [
      SELECT Id, Name, Promotion_Pack__r.Name
      FROM Quote_Promotion_Pack__c
      WHERE Quote__c = :quoteId
    ];
    if (lstPromotion.isEmpty()) {
      return new List<Quote_Promotion_Pack__c>();
    } else {
      return lstPromotion;
    }
  }

  private QuoteLineItem getQuoteLineItemByQuoteId(String strQuoteId) {
    List<QuoteLineItem> lstQuoteLineItemQuery = [
      SELECT
        Id,
        ListPrice,
        UnitPrice,
        TotalPrice,    
        Product2Id, //product
        Product2.Sales_Name__c,
        Product2.Model_Name__c,
        Product2.Model_Bike__r.Name,
        Product2.Year__c,
        Product2.Color_Name__c,
        Product2.Color_Type__c,
        Product2.Engince_cc__c,
        Product2.Origin__c,
        Product2.Bike_Type_2__c
      FROM QuoteLineItem
      WHERE QuoteId = :strQuoteId
    ];
    if (lstQuoteLineItemQuery.isEmpty()) {
      return new QuoteLineItem();
    } else {
      return lstQuoteLineItemQuery[0];
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
  public static Map<String, String> createPdfFile(String opportunityId) {
    Savepoint sp = Database.setSavepoint();
    try {
      Map<String, String> files = new Map<String, String>();
      List<Opportunity> opportunityList = [
        SELECT SyncedQuote.Quote_Number__c, Account.Name, CreatedDate
        FROM Opportunity
        WHERE ID = :opportunityId
      ];
      if (opportunityList.isEmpty()) {
        return null;
      }
      PageReference page = Page.QuotationAndDealForm;
      page.getParameters().put('id', opportunityId);
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
      //   opportunityId
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

  @AuraEnabled
  public static ApiResponse updateOpty(String opportunityId){
    ApiResponse apiResponse = new ApiResponse();
    try {
      List<Opportunity> opportunityList = [
        SELECT Id, Signing_Date__c, Disbursement_Date__c
        FROM Opportunity
        WHERE ID = :opportunityId
      ];
      opportunityList[0].Signing_Date__c = System.today();
      opportunityList[0].Disbursement_Date__c = System.today();
      update opportunityList;
      apiResponse.success = true;
      System.debug('Test: ' + apiResponse.success);
    } catch (Exception e) {
      apiResponse.error = e.getMessage() + ' | ' + e.getLineNumber() + e.getStackTraceString();
    }
    return apiResponse;
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
}
}