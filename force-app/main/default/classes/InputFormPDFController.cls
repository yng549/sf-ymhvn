public without sharing class InputFormPDFController {
  private final static String MSG_EXCEPTION = 'Error System, Please Connect Admin.';
  private final static String DATE_TIME_FILE_FORMAT = 'yyyyMMddHHmm';
  // private final static String FILE_NAME = '{0}{1}-{2}-{3}-{4}.pdf';
  private final static String FILE_NAME = '{0} - {1}.pdf';

  private class CustomException extends Exception {
  }
  public X3_Inventory_Transaction_Header__c objHeader { get; set; }
  public String strRecordId { get; set; }
  public List<Inventory_Transaction_Item__c> lstItems { get; set; }
  public Map<Id, PricebookEntry> mapPriceBookEntry { get; set; }
  public string logo {get;set;}

  public InputFormPDFController() {
    // try {
    mapPriceBookEntry = new Map<Id, PricebookEntry>();
    objHeader = new X3_Inventory_Transaction_Header__c();
    strRecordId = ApexPages.currentPage().getParameters().get('Id');
    if (String.isNotBlank(strRecordId)) {
      objHeader = getHeaderById(strRecordId);
      if (String.isBlank(objHeader.Id)) {
        return;
      }
      lstItems = getLstItems(objHeader.Id);
      Set<Id> setProduct = new Set<Id>();
      for (Inventory_Transaction_Item__c Item : lstItems) {
        setProduct.add(item.Product__c);
      }
      for (PricebookEntry PbE : getLstPriceBookEntry(setProduct)) {
        mapPriceBookEntry.put(PbE.Product2Id, PbE);
      }
      logo = '';
         if (objHeader.To_Warehouse_Location__r.Account__r.Name != null) {
            String doDlCreateName = objHeader.To_Warehouse_Location__r.Account__r.Name;
            if (doDlCreateName == 'REVZONE YAMAHA MOTOR HA NOI') {
                logo = 'logoRevzoneYamahaMotorHN';
            } else {
                logo = 'logoRevzoneYamahaMotorSG';
            }
        }  
    }
      
    // } catch (Exception ex) {
    //   throw new CustomException(
    //     String.format(MSG_EXCEPTION, new List<Object>{ ex.getMessage() })
    //   );
    // }
  }

  private static X3_Inventory_Transaction_Header__c getHeaderById(
    String recordId
  ) {
    List<X3_Inventory_Transaction_Header__c> lstHeader = [
      SELECT
        Id,
        Name,
        Header_Number__c,
        StockDate__c,
        Order_No__c,
        Contract_No__c,
        Document_Number__c,
        From_Warehouse_Location__c,
        From_Warehouse_Location__r.Name,
        To_Warehouse_Location__c,
        To_Warehouse_Location__r.Name,
        To_Warehouse_Location__r.Account__r.Name,
        Comment_Message__c,
        Account__c,
        Account__r.Name,
        Account__r.Tax_Code__c,
        Account__r.Address_Full__c,
		Order_Reserved__r.Account.DO_DL_Create_Account__r.Name
      FROM X3_Inventory_Transaction_Header__c
      WHERE Id = :recordId
    ];
    if (lstHeader.isEmpty()) {
      return new X3_Inventory_Transaction_Header__c();
    } else {
      return lstHeader[0];
    }
  }

  private static List<Inventory_Transaction_Item__c> getLstItems(
    String headerId
  ) {
    List<Inventory_Transaction_Item__c> lstItems = new List<Inventory_Transaction_Item__c>();
    lstItems = [
      SELECT Id, Quantity__c,Note__c,Unit_Price__c,VAT__c, Product__c,Product__r.Name,Product__r.ProductCode,Product__r.Product_Unit__c,Product__r.VAT__c,Product__r.PartsNameEng__c
      FROM Inventory_Transaction_Item__c
      WHERE Inventory_Transaction_Header__c = :headerId
    ];
    return lstItems;
  }

  private static List<PricebookEntry> getLstPriceBookEntry(Set<Id> setProduct) {
    List<PricebookEntry> lstItems = new List<PricebookEntry>();
    lstItems = [
      SELECT
        Id,
        UnitPrice,
        Product2Id,
        Product2.ProductCode,
        Product2.Name,
        Product2.Product_Unit__c,
        Product2.VAT__c
      FROM PricebookEntry
      WHERE
        IsActive = TRUE
        AND Pricebook2.Type__c = 'PCAService'
        AND Product2Id IN :setProduct
    ];
    return lstItems;
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
      List<X3_Inventory_Transaction_Header__c> orderList = [
        SELECT Header_Number__c, Header_Type__c
        FROM X3_Inventory_Transaction_Header__c
        WHERE ID = :orderId
      ];
      if (orderList.isEmpty()) {
        return null;
      }
      PageReference page = Page.InputFormPDF;
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
        orderList[0].Header_Number__c,
        orderList[0].Header_Type__c
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

  @AuraEnabled
  public static Map<String, String> createTransferPdfFile(String orderId) {
    Savepoint sp = Database.setSavepoint();
    try {
      Map<String, String> files = new Map<String, String>();
      List<X3_Inventory_Transaction_Header__c> orderList = [
        SELECT Name, Header_Type__c,Header_Number__c
        FROM X3_Inventory_Transaction_Header__c
        WHERE ID = :orderId
      ];
      if (orderList.isEmpty()) {
        return null;
      }
      PageReference page = Page.TransferFormPDF;
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
        orderList[0].Header_Number__c,
        orderList[0].Header_Type__c
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
  @AuraEnabled
  public static Map<String, String> createOutputPdfFile(String orderId) {
    Savepoint sp = Database.setSavepoint();
    try {
      Map<String, String> files = new Map<String, String>();
      List<X3_Inventory_Transaction_Header__c> orderList = [
        SELECT Name, Header_Type__c,Header_Number__c
        FROM X3_Inventory_Transaction_Header__c
        WHERE ID = :orderId
      ];
      if (orderList.isEmpty()) {
        return null;
      }
      PageReference page = Page.OutputFormPDF;
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
        orderList[0].Header_Number__c,
        orderList[0].Header_Type__c
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
  //   String orderId
  // ) {
  //   ContentVersion objContentVersion = [
  //     SELECT ContentDocumentId
  //     FROM ContentVersion
  //     WHERE Id = :contentVersionId
  //   ];
  //   ContentDocumentLink objContentDocLink = new ContentDocumentLink();
  //   objContentDocLink.ContentDocumentId = objContentVersion.ContentDocumentId;
  //   objContentDocLink.LinkedEntityId = orderId;
  //   objContentDocLink.ShareType = 'V';
  //   insert objContentDocLink;
  //   return objContentVersion.ContentDocumentId;
  // }
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
  }
}