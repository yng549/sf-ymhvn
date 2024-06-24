public without sharing class HandOverRecordPDF {
  private final static String MSG_EXCEPTION = 'Error System, Please Connect Admin.';
  private final static String DATE_TIME_FILE_FORMAT = 'yyyyMMddHHmm';
  private final static String FILE_NAME = '{0} - {1} - {2}.pdf';
  private class CustomException extends Exception {
  }
  public Date today { get; set; }
  public Order objOrder { get; set; }
  public String strOrderId { get; set; }
  public String logo{get;set;}

  public HandOverRecordPDF() {
    try {
      today = System.today();
      strOrderId = ApexPages.currentPage().getParameters().get('Id');
      if (String.isNotBlank(strOrderId)) {
        objOrder = getOrderById(strOrderId);
        if (String.isBlank(objOrder.Id)) {
          return;
        }
      }
    logo = '';
    if (objOrder.DO_DL__r.Name != null) {
            String doDlCreateName = objOrder.DO_DL__r.Name;
            
            if (doDlCreateName == 'REVZONE YAMAHA MOTOR HA NOI') {
                logo = 'logoRevzoneYamahaMotorHN';
            } else {
                logo = 'logoRevzoneYamahaMotorSG';
            }
        }
    } catch (Exception ex) {
      throw new CustomException(
       String.format(MSG_EXCEPTION, new List<Object>{ ex.getMessage() })
      );
   }
  }

  private Order getOrderById(String strOrderId) {
    List<Order> lstOrder = [
      SELECT
        Id,
        Order_Number__c,
        OrderNumber,
        Invoice_No__c,
        AccountId,
        DO_DL__r.Name,
        Account.Gender__c,
        Account.Name,
        Account.PersonMobilePhone,
        Account.PersonBirthdate,
        Account.DOB__pc,
        Account.Address_Full__c,
        Account.DO_DL_Create_Account__r.Address_No__c,
        Account.DO_DL_Create_Account__r.Address_logo__c,
        Account.DO_DL_Create_Account__r.Name,
        Asset__c,
        Asset__r.Frame_Number__c,
        Asset__r.Engine_No__c
      FROM Order
      WHERE Id = :strOrderId
    ];
    if (lstOrder.isEmpty()) {
      return new Order();
    } else {
      return lstOrder[0];
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
  public static Map<String, String> createPdfFile(String orderId) {
    Savepoint sp = Database.setSavepoint();
    try {
      Map<String, String> files = new Map<String, String>();
      List<Order> orderList = [
        SELECT Order_Number__c, Account.Name, CreatedDate
        FROM Order
        WHERE ID = :orderId
      ];
      if (orderList.isEmpty()) {
        return null;
      }
      PageReference page = Page.HandOverRecordPDF;
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
          'Handover',
          orderList[0].Account.Name
        }
      );
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
  //   String opportunityId
  // ) {
  //   ContentVersion objContentVersion = [
  //     SELECT ContentDocumentId
  //     FROM ContentVersion
  //     WHERE Id = :contentVersionId
  //   ];
  //   ContentDocumentLink objContentDocLink = new ContentDocumentLink();
  //   objContentDocLink.ContentDocumentId = objContentVersion.ContentDocumentId;
  //   objContentDocLink.LinkedEntityId = opportunityId;
  //   objContentDocLink.ShareType = 'V';
  //   insert objContentDocLink;
  //   return objContentVersion.ContentDocumentId;
  // }
 
}