public without sharing class ContractFormController {
  private final static String MSG_EXCEPTION = 'Error System, Please Connect Admin.';
  private final static String DATE_TIME_FILE_FORMAT = 'yyyyMMddHHmm';
  private final static String FILE_NAME = '{0} - {1}.pdf';
  private class CustomException extends Exception {
  }

  public Contract objContract { get; set; }
  public String strId { get; set; }
  public List<OpportunityLineItem> lstProduct { get; set; }
  public Decimal sumAmountExcludeTax { get; set; }
  public Decimal sumAmount { get; set; }
  public Decimal taxAmount { get; set; }
  public string total_text_en { get; set; }
  public string total_text_vn { get; set; }
  public String removeVietnameToneText { get; set; }
  public ContractFormController() {
    try {
      sumAmount = 0;
      sumAmountExcludeTax = 0;
      taxAmount = 0;
      objContract = new Contract();
      strId = ApexPages.currentPage().getParameters().get('Id');
      if (String.isNotBlank(strId)) {
        objContract = getContractById(strId);
        if (String.isBlank(objContract.Id)) {
          return;
        }
        lstProduct = getListProduct(objContract.Opportunity__c);
        if (!lstProduct.isEmpty()) {
          for (OpportunityLineItem oli : lstProduct) {
            sumAmount =
              (oli.UnitPrice != null ? oli.UnitPrice : 0) *
              (oli.Quantity != null ? oli.Quantity : 1);
          }
          sumAmountExcludeTax = sumAmount / (Decimal) 1.1;
          taxAmount = sumAmount - sumAmountExcludeTax;
          total_text_en = ConvertCurrencyToWordsEn.english_number(sumAmount);
          total_text_vn = textUppercaseFormat(
            ConvertCurrencyToVietnamese.convertV(sumAmount)
          );
        }
        if (objContract.Contract_Information__r.Name != null) {
          removeVietnameToneText = RemoveVietnameseTone.RemoveTone(
            objContract.Contract_Information__r.Name
          );
        }
      }
    } catch (Exception ex) {
      throw new CustomException(
        String.format(MSG_EXCEPTION, new List<Object>{ ex.getMessage() })
      );
    }
  }

  public String textUppercaseFormat(String name) {
    String result = '';

    if (name != null && name != '') {
      for (String iter : name.split('[ ]+')) {
        if (iter != null && iter != '') {
          if (iter.length() > 1) {
            result +=
              iter.substring(0, 1).toUpperCase() +
              iter.substring(1, iter.length()) +
              ' ';
          } else {
            result += iter.substring(0, 1).toUpperCase() + ' ';
          }
        }
      }
      result = result.substring(0, result.length() - 1);
    }
    return result;
  }

  private Contract getContractById(String strId) {
    List<Contract> lstContract = [
      SELECT
        Id,
        ContractNumber,
        StartDate,
        CreatedDate,
        Remark__c,
        Tentative_Delivery_Date__c,
        Receiver__c,
        Receiver__r.Name,
        Delivery_Time__c,
        AccountId,
        Account.Name,
        Owner.AccountId,
        Owner.Account.Address__c,
        Owner.Account.Address_Eng__c,
        Owner.Account.Head_Office__c,
        Owner.Account.Head_Office_Eng__c,
        Owner.Account.Phone,
        Owner.Account.Fax,
        Owner.Account.Tax_Code__c,
        Owner.Account.Bank_Number2__c,
        Owner.Account.Bank_Account_Name__c,
        Owner.Account.Bank_Name__c,
        Owner.Account.Bank_Name_Eng__c,
        Owner.Account.Represented_by__c,
        Owner.Account.Represented_By_Eng__c,
        Owner.Account.Represented_Title__c,
        Owner.Account.Delivery_Place__c,
        Owner.Account.Address_Full__c,
        Owner.Account.Bank_Account_Name_Eng__c,
        Owner.DODL_Manager__r.AccountId,
        Owner.DODL_Manager__r.Account.Address__c,
        Owner.DODL_Manager__r.Account.Address_Eng__c,
        Owner.DODL_Manager__r.Account.Head_Office__c,
        Owner.DODL_Manager__r.Account.Head_Office_Eng__c,
        Owner.DODL_Manager__r.Account.Phone,
        Owner.DODL_Manager__r.Account.Fax,
        Owner.DODL_Manager__r.Account.Tax_Code__c,
        Owner.DODL_Manager__r.Account.Bank_Number__c,
        Owner.DODL_Manager__r.Account.Bank_Account_Name__c,
        Owner.DODL_Manager__r.Account.Bank_Name__c,
        Owner.DODL_Manager__r.Account.Bank_Name_Eng__c,
        Owner.DODL_Manager__r.Account.Represented_by__c,
        Owner.DODL_Manager__r.Account.Represented_By_Eng__c,
        Owner.DODL_Manager__r.Account.Represented_Title__c,
        Owner.DODL_Manager__r.Account.Delivery_Place__c,
        Owner.DODL_Manager__r.Account.Address_Full__c,
        Account.DO_DL_Create_Account__r.Name,
        Account.DO_DL_Create_Account__r.Head_Office__c,
        Account.DO_DL_Create_Account__r.Head_Office_Eng__c,
        Account.DO_DL_Create_Account__r.Phone,
        Account.DO_DL_Create_Account__r.Fax,
        Account.DO_DL_Create_Account__r.Tax_Code__c,
        Account.DO_DL_Create_Account__r.Bank_Name__c,
        Account.DO_DL_Create_Account__r.Bank_Name_Eng__c,
        Contract_Information__c,
        Contract_Information__r.Name,
        Contract_Information__r.Head_Office__c,
        Contract_Information__r.Head_Office_Eng__c,
        Contract_Information__r.Mobile__c,
        Contract_Information__r.Fax__c,
        Contract_Information__r.Tax_code__c,
        Contract_Information__r.Represented_by__c,
        Contract_Information__r.Represented_By_Eng__c,
        Contract_Information__r.Represented_Title__c,
        Contract_Information__r.Represented_Title_Eng__c,
        Opportunity__c,
        Opportunity__r.Product__r.Model_Name__c,
        Opportunity__r.Product__r.Color_Type__c,
        Opportunity__r.DODL_Create__r.Name,
        Opportunity__r.DODL_Create__r.Represented_By__c ,
        Opportunity__r.DODL_Create__r.Represented_Title__c ,
        Opportunity__r.DODL_Create__r.Represented_By_Eng__c ,
        Opportunity__r.DODL_Create__r.Represented_Title_Eng__c ,
        Opportunity__r.DODL_Create__r.Contract_Company_Name_eng__c  ,
        Opportunity__r.DODL_Create__r.Contract_Company_Name__c ,
        Opportunity__r.DODL_Create__r.Bank_Account_Name__c ,
        Opportunity__r.DODL_Create__r.Bank_Account_Name_Eng__c ,
        Opportunity__r.DODL_Create__r.Bank_Number2__c ,
        Opportunity__r.DODL_Create__r.Address_Eng__c
      FROM Contract
      WHERE ID = :strId
    ];
    if (lstContract.isEmpty()) {
      return new Contract();
    } else {
      return lstContract[0];
    }
  }

  private List<OpportunityLineItem> getListProduct(String strOptyId) {
    List<OpportunityLineItem> lstProduct = [
      SELECT
        Id,
        Product2.Name,
        Product2.Sales_Name__c,
        Product2.Model__c,
        Product2.Color_Type__c,
        Product2.Model_Name__c,
        Product2.Model_Code__c,
        Product2.Color_Name__c,
        Quantity,
        UnitPrice,
        TotalPrice
      FROM OpportunityLineItem
      WHERE OpportunityId = :strOptyId
    ];
    if (lstProduct.isEmpty()) {
      return new List<OpportunityLineItem>();
    } else {
      return lstProduct;
    }
  }

  /*
   * createPdfFile
   * @param:
   * @return: none
   * @created: 2020/07/13  Tran Hoang Tan
   * @modified:
   */
  @AuraEnabled
  public static Map<String, String> createPdfFile(String strId) {
    Savepoint sp = Database.setSavepoint();
    try {
      Map<String, String> files = new Map<String, String>();
      List<Contract> objectList = [
        SELECT Account.Name, ContractNumber, CreatedDate
        FROM Contract
        WHERE ID = :strId
      ];
      if (objectList.isEmpty()) {
        return null;
      }
      PageReference page = Page.ContractForm;
      page.getParameters().put('id', strId);
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
          objectList[0].ContractNumber,
          objectList[0].Account.Name
        }
      );
      // ContentVersion objContentVersion = createContentVersion(
      //   pdfContent,
      //   fileName
      // );
      // String contentDocumentId = createContentDocumentLink(
      //   objContentVersion.Id,
      //   strId
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
  public static Map<String, String> createPdfFilePerson(String strId) {
    Savepoint sp = Database.setSavepoint();
    try {
      Map<String, String> files = new Map<String, String>();
      List<Contract> objectList = [
        SELECT Account.Name, ContractNumber, CreatedDate
        FROM Contract
        WHERE ID = :strId
      ];
      if (objectList.isEmpty()) {
        return null;
      }
      PageReference page = Page.BtnPrintContractForm;
      page.getParameters().put('id', strId);
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
          objectList[0].ContractNumber,
          objectList[0].Account.Name
        }
      );
      // ContentVersion objContentVersion = createContentVersion(
      //   pdfContent,
      //   fileName
      // );
      // String contentDocumentId = createContentDocumentLink(
      //   objContentVersion.Id,
      //   strId
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
  public static Map<String, String> createPdfFile2(String strId) {
    Savepoint sp = Database.setSavepoint();
    try {
      Map<String, String> files = new Map<String, String>();
      List<Contract> objectList = [
        SELECT Account.Name, ContractNumber, CreatedDate
        FROM Contract
        WHERE ID = :strId
      ];
      if (objectList.isEmpty()) {
        return null;
      }
      PageReference page = Page.ContractFormPDF;
      page.getParameters().put('id', strId);
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
          objectList[0].ContractNumber,
          objectList[0].Account.Name
        }
      );
      // ContentVersion objContentVersion = createContentVersion(
      //   pdfContent,
      //   fileName
      // );
      // String contentDocumentId = createContentDocumentLink(
      //   objContentVersion.Id,
      //   strId
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
  public static Map<String, String> createPdfFilePerson2(String strId) {
    Savepoint sp = Database.setSavepoint();
    try {
      Map<String, String> files = new Map<String, String>();
      List<Contract> objectList = [
        SELECT Account.Name, ContractNumber, CreatedDate
        FROM Contract
        WHERE ID = :strId
      ];
      if (objectList.isEmpty()) {
        return null;
      }
      PageReference page = Page.BtnPrintContractFormPDF;
      page.getParameters().put('id', strId);
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
          objectList[0].ContractNumber,
          objectList[0].Account.Name
        }
      );
      // ContentVersion objContentVersion = createContentVersion(
      //   pdfContent,
      //   fileName
      // );
      // String contentDocumentId = createContentDocumentLink(
      //   objContentVersion.Id,
      //   strId
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
  // private static ContentVersion createContentVersion(
  //   Blob pdfContent,
  //   String fileName
  // ) {
  //   ContentVersion objContentVersion = new ContentVersion(
  //     VersionData = pdfContent,
  //     Title = fileName,
  //     PathOnClient = fileName
  //   );
  //   insert objContentVersion;
  //   return objContentVersion;
  // }

  // private static String createContentDocumentLink(
  //   String contentVersionId,
  //   String testRideId
  // ) {
  //   ContentVersion objContentVersion = [
  //     SELECT ContentDocumentId
  //     FROM ContentVersion
  //     WHERE Id = :contentVersionId
  //   ];
  //   ContentDocumentLink objContentDocLink = new ContentDocumentLink();
  //   objContentDocLink.ContentDocumentId = objContentVersion.ContentDocumentId;
  //   objContentDocLink.LinkedEntityId = testRideId;
  //   objContentDocLink.ShareType = 'V';
  //   insert objContentDocLink;
  //   return objContentVersion.ContentDocumentId;
  // }
}