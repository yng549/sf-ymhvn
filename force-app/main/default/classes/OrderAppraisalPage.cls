public without sharing class OrderAppraisalPage {
  private final static String MSG_EXCEPTION = 'Error System, Please Connect Admin.';
  private final static String DATE_TIME_FILE_FORMAT = 'yyyyMMddHHmm';
  private final static String FILE_NAME = '{0} - {1}.pdf';
  public String addressString { get; set; }
  private class CustomException extends Exception {
  }
  public Order objOrder { get; set; }
  public Date today { get; set; }
  public String strOrderId { get; set; }
  public String lstOrderItemRepair { get; set; }

  public OrderAppraisalPage() {
    try {
      today = System.today();
      objOrder = new Order();
      addressString = '';
      strOrderId = ApexPages.currentPage().getParameters().get('Id');
      if (String.isNotBlank(strOrderId)) {
        objOrder = getOrderById(strOrderId);
        if (String.isBlank(objOrder.Id)) {
          return;
        }
        // objOrder = getOrderById(strOrderId);
        // 				initAddressString(objOrder.Account.Address_No__c, objOrder.Account.Province__r.Name, objOrder.Account.District__r.Name);
      }
    } catch (Exception ex) {
      throw new CustomException(
        String.format(MSG_EXCEPTION, new List<Object>{ ex.getMessage() })
      );
    }
  }

  // private void initAddressString(
  //   String strAddressNo,
  //   String strProvince,
  //   String strDistrict
  // ) {
  //   if (String.isNotBlank(strAddressNo)) {
  //     addressString += (strAddressNo != null ? strAddressNo + ', ' : '');
  //   }
  //   if (String.isNotBlank(strProvince)) {
  //     addressString += (strProvince != null ? strProvince + ', ' : '');
  //   }
  //   if (String.isNotBlank(strDistrict)) {
  //     addressString += (strDistrict != null ? strDistrict : '');
  //   }
  // }

  private Order getOrderById(String strOrderId) {
    List<Order> lstOrderQuerry = [
      SELECT
        Id,
        Make_Model__c,
        Year__c,
        Frame_No__c,
        Titile_No__c,
        Stock_No__c,
        Mileage__c,
        Crankcase_No__c,
        OrderNumber,
        Order_Number__c,
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
        Tyres__c,
        Tail_light_s__c,
        Clutch_Throtttle_cable__c,
        Brake_Clutch_levers__c,
        Wheels__c,
        Wheel_bearings__c,
        Swing_arm_bearings__c,
        Switches_Housings__c,
        Rearsets_Footpegs__c,
        Indicators__c,
        Headlight_s__c,
        Brake_light__c,
        Main_fairings__c,
        Small_covers__c,
        Rider_seat__c,
        Passenger_seat__c,
        Fuel_tank__c,
        Engine__c,
        Chassis__c,
        Handling__c,
        Fairings__c,
        Accessories__c,
        General_Condition__c,
        Clean_up__c,
        Reconditioning_Total__c,
        Reconditioning_note__c, // Bình Xăng
        Asset__c, //asset
        Asset__r.Frame_Number__c,
        Asset__r.Product2.Model__c,
        Asset__r.Product2.Model_Bike__r.Name,
        Asset__r.Engine_No__c,
        Asset__r.Make_Model__c,
        Asset__r.Year__c,
        Asset__r.Year_Tradein__c,
        Asset__r.Titile_No__c,
        Asset__r.Stock_No__c,
        Asset__r.Crankcase_No__c,
        Asset__r.Mileage__c,
        Asset__r.VinID__c,
        Account.Name, //account
        Account.Address_Full__c,
        Account.Phone,
        Account.PersonMobilePhone,
        Account.Address_No__c,
        Account.Province__r.Name,
        Account.District__r.Name,
        Sales_Associate__c, //Sales_Associate__c
        Sales_Associate__r.Name,
        OwnerId, // Owner
        Owner.Name,
        Appraiser__c, //Appraiser
        Appraiser__r.Name,
        Dealer__c,
        Status,
        Mechanic__r.Name,
        Opportunity.Asset__r.Year__c, // Opportunity
        Opportunity.Asset__r.Make_Model__c,
        Opportunity.Asset__r.VinID__c,
        Opportunity.Asset__r.Mileage__c,
        Opportunity.Asset__r.Engine_No__c,
        DO_DL__r.Address_Full__c,
        DO_DL__r.PersonMobilePhone,
        DO_DL__r.Phone
      FROM Order
      WHERE Id = :strOrderId
    ];
    if (lstOrderQuerry.isEmpty()) {
      return new Order();
    } else {
      return lstOrderQuerry[0];
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
  public static Map<String,String> createPdfFile(String orderId) {
    Savepoint sp = Database.setSavepoint();
    try {
      Map<String,String> files = new Map<String,String>();
      List<Order> orderList = [
        SELECT Order_Number__c, Account.Name, CreatedDate
        FROM Order
        WHERE ID = :orderId
      ];
      if (orderList.isEmpty()) {
        return null;
      }
      PageReference page = Page.OrderAppraisalFormTradeIn;
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

}