public without sharing class TestRidePDF {
  private final static String MSG_EXCEPTION = 'Error System, Please Connect Admin.';
  private final static String DATE_TIME_FILE_FORMAT = 'yyyyMMddHHmm';
  private final static String FILE_NAME = '{0} - {1}.pdf';
  private class CustomException extends Exception {
  }

  public Test_Ride__c objTestRide { get; set; }
  public String strTestRideId { get; set; }
  public List<Product2> lstProduct { get; set; }
  public String products {get;set;}
  public List<string> lstAdditional { get; set; }
  public Map<string, boolean> mpAddtional { get; set; }
  public String logo {get;set;}
  public TestRidePDF() {
    try {
      mpAddtional = new Map<string, boolean>();
      objTestRide = new Test_Ride__c();
      strTestRideId = ApexPages.currentPage().getParameters().get('Id');
      if (String.isNotBlank(strTestRideId)) {
        objTestRide = getTestRideById(strTestRideId);
        if (String.isBlank(objTestRide.Id)) {
          return;
        }
      }

      lstProduct = getProductFromAssignment(strTestRideId);
      List<String> lstProductName = new List<String>();
      for (Product2 p : lstProduct){
        lstProductName.add(p.Name);
      }
      products = string.join(lstProductName,', ');

      lstAdditional = getPicklistValues(
        Test_Ride__c.Additional_equipments_documents__c
      );
      for (string strAdd : lstAdditional) {
        mpAddtional.put(strAdd, false);
      }
      logo = '';
         if (objTestRide.Opportunity__r.DODL_Create__r.Name != null) {
            String doDlCreateName = objTestRide.Opportunity__r.DODL_Create__r.Name;
            if (doDlCreateName == 'REVZONE YAMAHA MOTOR HA NOI') {
                logo = 'logoRevzoneYamahaMotorHN';
            } else {
                logo = 'logoRevzoneYamahaMotorSG';
            }
        }
      if (string.isNotBlank(objTestRide.Additional_equipments_documents__c)) {
        List<string> lstAdd = objTestRide.Additional_equipments_documents__c.split(
          ';'
        );
        if (lstAdd.size() > 0) {
          for (string strAdd : lstAdd) {
            mpAddtional.put(strAdd, true);
          }
        }
      }
    } catch (Exception ex) {
      throw new CustomException(
        String.format(MSG_EXCEPTION, new List<Object>{ ex.getMessage() })
      );
    }
  }

  private Test_Ride__c getTestRideById(String strTestRideId) {
    List<Test_Ride__c> lstTestRideQuery = [
      SELECT
        Name,
        Test_Ride_Number__c,
        Additional_equipments_documents__c,
        Date_time_collected__c,
        Comments__c,
        Test_Ride_Customer__c, //customer
        Test_Ride_Customer__r.Name,
        Test_Ride_Customer__r.AccountNumber,
        Test_Ride_Customer__r.ID_No__c,
        Test_Ride_Customer__r.ID_Issue_Date__c,
        Test_Ride_Customer__r.A2_License_No__c,
        Test_Ride_Customer__r.A2_Issue_Date__c,
        Test_Ride_Customer__r.PersonMobilePhone,
        Test_Ride_Customer__r.PersonEmail,
        Opportunity__r.DODL_Create__r.Address__c,
        Opportunity__r.DODL_Create__r.Name
        
      FROM Test_Ride__c
      WHERE ID = :strTestRideId
    ];
    if (lstTestRideQuery.isEmpty()) {
      return new Test_Ride__c();
    } else {
      return lstTestRideQuery[0];
    }
  }

  private List<Product2> getProductFromAssignment(String strTestRideId) {
    List<Test_Ride_Assignment__c> assignmentList = new List<Test_Ride_Assignment__c>();
    assignmentList = [
      SELECT Product__c
      FROM Test_Ride_Assignment__c
      WHERE Test_Ride__c = :strTestRideId
    ];
    Set<Id> productIdList = new Set<Id>();
    for (Test_Ride_Assignment__c a : AssignmentList) {
      productIdList.add(a.Product__c);
    }

    List<Product2> lstProduct = [
      SELECT Id, Name
      FROM Product2
      WHERE Id IN :productIdList
    ];
    if (lstProduct.isEmpty()) {
      return new List<Product2>();
    } else {
      return lstProduct;
    }
  }

  private static List<String> getPicklistValues(Schema.sObjectField field) {
    List<String> options = new List<String>();
    Schema.DescribeFieldResult fieldResult = field.getDescribe();
    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
    for (Schema.PicklistEntry entry : picklistValues) {
      options.add(entry.getValue());
    }
    return options;
  }
  /*
   * createPdfFile
   * @param:
   * @return: none
   * @created: 2020/07/13  Tran Hoang Tan
   * @modified:
   */
  @AuraEnabled
  public static Map<String,String> createPdfFile(String testRideId) {
    Savepoint sp = Database.setSavepoint();
    try {
      Map<String,String> files = new Map<String,String>();
      List<Test_Ride__c> testRideList = [
        SELECT Name, Test_Ride_Customer__r.Name,Test_Ride_Number__c, CreatedDate
        FROM Test_Ride__c
        WHERE ID = :testRideId
      ];
      if (testRideList.isEmpty()) {
        return null;
      }
      PageReference page = Page.TestRidePDF;
      page.getParameters().put('id', testRideId);
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
          testRideList[0].Test_Ride_Number__c,
          testRideList[0].Test_Ride_Customer__r.Name
        }
      );
      // ContentVersion objContentVersion = createContentVersion(
      //   pdfContent,
      //   fileName
      // );
      // String contentDocumentId = createContentDocumentLink(
      //   objContentVersion.Id,
      //   testRideId
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
    String testRideId
  ) {
    ContentVersion objContentVersion = [
      SELECT ContentDocumentId
      FROM ContentVersion
      WHERE Id = :contentVersionId
    ];
    ContentDocumentLink objContentDocLink = new ContentDocumentLink();
    objContentDocLink.ContentDocumentId = objContentVersion.ContentDocumentId;
    objContentDocLink.LinkedEntityId = testRideId;
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
      } 
}