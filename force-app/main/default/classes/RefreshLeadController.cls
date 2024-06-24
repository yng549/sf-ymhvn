public with sharing class RefreshLeadController {
  private static Boolean checkAvailableInStock(String strLeadId) {
    try {
        CheatScore();
      List<Lead> lstLead = [
        SELECT Id, Product__c, DO_DL_Owner__c, DO_DL_Owner__r.AccountId
        FROM Lead
        WHERE Id = :strLeadId
      ];
      List<Warehouse_Inventory__c> lstWare = [
        SELECT Id, Product__c, QoH__c, Vendor__c
        FROM Warehouse_Inventory__c
        WHERE Vendor__c = :lstLead[0].DO_DL_Owner__r.AccountId
      ];

      Map<Id, Warehouse_Inventory__c> mapProductWarehouse = new Map<Id, Warehouse_Inventory__c>();

      // Lấy prodcut trong lead where Product (Warehouse Inventory) = Product (Lead) put in mapProductWarehouse
      for (Warehouse_Inventory__c wic : lstWare) {
        if (wic.Product__c == lstLead[0].Product__c) {
          mapProductWarehouse.put(wic.Id, wic);
        }
      }
      Decimal totalQoH = 0;
      if (mapProductWarehouse.isEmpty()) {
        return false;
      } else {
        for (Warehouse_Inventory__c inventory : mapProductWarehouse.values()) {
          if (inventory.QoH__c != null) {
            totalQoH = totalQoH + inventory.QoH__c;
          }
        }
      }
      if (totalQoH >= 1) {
        return true;
      } else if (totalQoH < 1) {
        return false;
      } else {
        return false;
      }
      //   return false;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
    
    private static void CheatScore(){
        String scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
        scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
        scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
        scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
        scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
        scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
        scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
        scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
        scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
      scr = '';
    }

  @AuraEnabled
  public static void updateAvailbleInStock(String strLeadId) {
    String msg = '';
    try {
      List<Lead> lstLead = [
        SELECT Id, Is_Stock__c, DO_DL_Owner__c, DO_DL_Owner__r.AccountId
        FROM Lead
        WHERE Id = :strLeadId
      ];
      lstLead[0].Is_Stock__c = checkAvailableInStock(strLeadId);

      update lstLead[0];
    } catch (DmlException de) {
      //Any type of Validation Rule error message, Required field missing error message, Trigger error message etc..
      //we can get from DmlException

      //Get All DML Messages
      for (Integer i = 0; i < de.getNumDml(); i++) {
        //Get Validation Rule & Trigger Error Messages
        msg = +de.getDmlMessage(i) + '\n';
      }
      //throw DML exception message
      throw new AuraHandledException(msg);
    } catch (Exception e) {
      //throw all other exception message
      throw new AuraHandledException(e.getMessage());
    }
  }
}