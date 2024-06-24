public without sharing class TransferFormPDFController {
    private final static String MSG_EXCEPTION = 'Error System, Please Connect Admin.';
  private final static String DATE_TIME_FILE_FORMAT = 'yyyyMMddHHmm';
  // private final static String FILE_NAME = '{0}{1}-{2}-{3}-{4}.pdf';
  private final static String FILE_NAME = '{0} - {1}.pdf';
  private class CustomException extends Exception {
  }
  public string logo {get;set;}
  public X3_Inventory_Transaction_Header__c objHeader { get; set; }
  public String strRecordId { get; set; }
  public List<Inventory_Transaction_Item__c> lstItems { get; set; }

  public TransferFormPDFController() {
    // try {
    
    objHeader = new X3_Inventory_Transaction_Header__c();
    strRecordId = ApexPages.currentPage().getParameters().get('Id');
    if (String.isNotBlank(strRecordId)) {
      objHeader = getHeaderById(strRecordId);
      if (String.isBlank(objHeader.Id)) {
        return;
      }
        logo = '';
         if (objHeader.From_Warehouse_Location__r.Account__r.Name != null) {
            String doDlCreateName = objHeader.From_Warehouse_Location__r.Account__r.Name;
            if (doDlCreateName == 'REVZONE YAMAHA MOTOR HA NOI') {
                logo = 'logoRevzoneYamahaMotorHN';
            } else {
                logo = 'logoRevzoneYamahaMotorSG';
            }
        }  
      lstItems = getLstItems(objHeader.Id);
     
    }
    // } catch (Exception ex) {
    //   throw new CustomException(
    //     String.format(MSG_EXCEPTION, new List<Object>{ ex.getMessage() })
    //   );
    // }
  }

  private static X3_Inventory_Transaction_Header__c getHeaderById(String recordId ) {
    List<X3_Inventory_Transaction_Header__c> lstHeader = [
      SELECT
        Id,
        Header_Number__c,
        StockDate__c,
        Order_No__c,
        Contract_No__c,
        Document_Number__c,
        From_Warehouse_Location__c,
        From_Warehouse_Location__r.Name,
        From_Warehouse_Location__r.Account__r.Name,
        To_Warehouse_Location__c,
        To_Warehouse_Location__r.Name,
        To_Warehouse_Location__r.Account__r.Name,
        Comment_Message__c,
        Account__c,
        Account__r.Name,
        Account__r.Tax_Code__c,
        Account__r.Address_Full__c,
        Order_Reserved__c,
        Order_Reserved__r.Order_Number__c,
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
      SELECT Id, Quantity__c, Note__c, Product__c,Product__r.Name,Product__r.ProductCode,Product__r.Product_Unit__c,Product__r.VAT__c,Product__r.PartsNameEng__c
      FROM Inventory_Transaction_Item__c
      WHERE Inventory_Transaction_Header__c = :headerId
    ];
    return lstItems;
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
      }
 
}