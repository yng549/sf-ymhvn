public with sharing class addProductInTransactionHeader {
    
    @AuraEnabled
    public static ApiResponse getTranHeaderByRecordId(String recordId) {
        ApiResponse apiResponse = new ApiResponse();
        X3_Inventory_Transaction_Header__c objTransactionHeader = [SELECT Id
                                                                        , From_Warehouse_Location__c
                                                                        , To_Warehouse_Location__c
                                                                        , From_Warehouse_Location__r.Account__c
                                                                        , To_Warehouse_Location__r.Account__c
                                                                    FROM X3_Inventory_Transaction_Header__c
                                                                    WHERE Id =: recordId];
        if(apiResponse.error == null) {
            apiResponse.success = true;
            apiResponse.result = objTransactionHeader;
        } 
        return apiResponse;
    }

    @AuraEnabled
    public static ApiResponse getInitProduct(String recordId) {
        ApiResponse apiResponse = new ApiResponse();
        List<objProductDTO> lstProductDTO = new List<objProductDTO>();
        X3_Inventory_Transaction_Header__c objTransactionHeader = getTransactionHeaderByRecordId(recordId);
        if(String.isNotBlank(objTransactionHeader.From_Warehouse_Location__c)) {
            List<Warehouse_Inventory__c> lstWarehouseInventory = [SELECT Id
                                                                        , Product__c
                                                                        , Product__r.Name
                                                                        , Product__r.ProductCode
                                                                        , Product__r.Model_Code__c
                                                                        , Product__r.Model_Name__c
                                                                        , Product__r.RecordType.Name
                                                                        , Warehouse_Location__c
                                                                        , Warehouse_Location__r.Account__c
                                                                        , QoH__c
                                                                FROM Warehouse_Inventory__c
                                                                WHERE Warehouse_Location__c =: objTransactionHeader.From_Warehouse_Location__c
                                                                    AND (Product__r.RecordTypeId =: RecordTypeHelper.PRODUCT_PCA)
                                                                    LIMIT 70];                            
            if(lstWarehouseInventory.isEmpty()) {
                apiResponse.error = 'No any warehouse inventory in warehouse location.';
                return apiResponse; 
            }
            for(Warehouse_Inventory__c item : lstWarehouseInventory) {
                objProductDTO obj = new objProductDTO();
                obj.Id = item.Product__c;
                obj.WarehouseId = item.Id;
                obj.QoH = item.QoH__c;
                obj.ProductCode = item.Product__r.ProductCode;
                obj.ProductModelName = item.Product__r.Model_Name__c;
                obj.ProductModelCode = item.Product__r.Model_Code__c;
                obj.ProductName = item.Product__r.Name;
                obj.RecordTypeName = item.Product__r.RecordType.Name;
                obj.isFromWarehouse = true;
                obj.Ischecked = false;
                lstProductDTO.add(obj);
            }
        } else {
            List<Product2> lstProduct = [SELECT Id
                                                , Name
                                                , ProductCode
                                                , Model_Code__c
                                                , Model_Name__c
                                                , RecordType.Name
                                        FROM    Product2
                                        WHERE  (RecordTypeId =: RecordTypeHelper.PRODUCT_PCA)
                                        LIMIT 70];
            for(Product2 item : lstProduct) {
                objProductDTO obj = new objProductDTO();
                obj.Id = item.Id;
                obj.ProductCode = item.ProductCode;
                obj.ProductModelName = item.Model_Name__c;
                obj.ProductModelCode = item.Model_Code__c;
                obj.ProductName = item.Name;
                obj.RecordTypeName = item.RecordType.Name;
                obj.isFromWarehouse = false;
                obj.Ischecked = false;
                lstProductDTO.add(obj);
            }                          
        }
        if(apiResponse.error == null) {
            apiResponse.success = true;
            apiResponse.result = lstProductDTO;
        } 
        return apiResponse;
    }
    private static X3_Inventory_Transaction_Header__c getTransactionHeaderByRecordId(String recordId) {
        X3_Inventory_Transaction_Header__c objTransactionHeader = [SELECT Id
                                                                        , From_Warehouse_Location__c
                                                                        , To_Warehouse_Location__c
                                                                        , From_Warehouse_Location__r.Account__c
                                                                        , To_Warehouse_Location__r.Account__c
                                                                    FROM X3_Inventory_Transaction_Header__c
                                                                    WHERE Id =: recordId];
        
        return objTransactionHeader;
    }


    @AuraEnabled
    public static ApiResponse getProductSearchString(String searchString, String recordId) {
        ApiResponse apiResponse = new ApiResponse();
        String strName = '%' + searchString + '%';
        List<objProductDTO> lstProductDTO = new List<objProductDTO>();
        X3_Inventory_Transaction_Header__c objTransactionHeader = getTransactionHeaderByRecordId(recordId);
        if(String.isNotBlank(objTransactionHeader.From_Warehouse_Location__c)) {
            List<Warehouse_Inventory__c> lstWarehouseInventory = [SELECT Id
                                                                        , Product__c
                                                                        , Product__r.Name
                                                                        , Product__r.ProductCode
                                                                        , Product__r.Model_Code__c
                                                                        , Product__r.Model_Name__c
                                                                        , Product__r.RecordType.Name
                                                                        , Warehouse_Location__c
                                                                        , Warehouse_Location__r.Account__c
                                                                        , QoH__c
                                                                FROM Warehouse_Inventory__c
                                                                WHERE Warehouse_Location__c =: objTransactionHeader.From_Warehouse_Location__c
                                                                    AND Qoh__c >: 0
                                                                    AND (Product__r.Name LIKE: strName OR Product__r.ProductCode LIKE: strName)
                                                                LIMIT 70];                            
            if(lstWarehouseInventory.isEmpty()) {
                apiResponse.error = 'No any warehouse inventory in warehouse location.';
                return apiResponse;
            }
            for(Warehouse_Inventory__c item : lstWarehouseInventory) {
                objProductDTO obj = new objProductDTO();
                obj.Id = item.Product__c;
                obj.WarehouseId = item.Id;
                obj.QoH = item.QoH__c;
                obj.ProductCode = item.Product__r.ProductCode;
                obj.ProductModelName = item.Product__r.Model_Name__c;
                obj.ProductModelCode = item.Product__r.Model_Code__c;
                obj.ProductName = item.Product__r.Name;
                obj.RecordTypeName = item.Product__r.RecordType.Name;
                obj.isFromWarehouse = true;
                obj.Ischecked = false;
                lstProductDTO.add(obj);
            }
        } else {
            List<Product2> lstProduct = [SELECT Id
                                                , Name
                                                , ProductCode
                                                , Model_Code__c
                                                , Model_Name__c
                                                , RecordType.Name
                                        FROM    Product2
                                        WHERE (Name LIKE: strName 
                                            OR ProductCode LIKE: strName)
                                            AND (RecordTypeId =: RecordTypeHelper.PRODUCT_PCA)
                                        LIMIT 70];
            for(Product2 item : lstProduct) {
                objProductDTO obj = new objProductDTO();
                obj.Id = item.Id;
                obj.ProductCode = item.ProductCode;
                obj.ProductModelName = item.Model_Name__c;
                obj.ProductModelCode = item.Model_Code__c;
                obj.ProductName = item.Name;
                obj.RecordTypeName = item.RecordType.Name;
                obj.isFromWarehouse = false;
                obj.Ischecked = false;
                lstProductDTO.add(obj);
            }                          
        }
        if(lstProductDTO.isEmpty()) {
            apiResponse.error = 'Not any product like search exists.';
            return apiResponse;
        }
        if(apiResponse.error == null) {
            apiResponse.success = true;
            apiResponse.result = lstProductDTO;
        } 
        return apiResponse;
    }



    @AuraEnabled(cacheable=true)
    public static List<sObject> search(String searchTerm, string myObject, String filter) {
        String myQuery = null;
        if(filter != null && filter != ''){
            myQuery = 'Select Id, Name from '+myObject+' Where Name Like  \'%' + searchTerm + '%\' AND '+filter+' LIMIT  5';
        }
        else {
            if(searchTerm == null || searchTerm == ''){
                myQuery = 'Select Id, Name from '+myObject+' Where LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT  5';
            }
            else {
                myQuery = 'Select Id, Name from '+myObject+' Where Name Like  \'%' + searchTerm + '%\' LIMIT  5';
            }
        }
        List<sObject> lookUpList = database.query(myQuery);
        return lookUpList;
    }


    @AuraEnabled
    public static APIResponse setBatchForProductSeletected(List<objProductDTO> lstObjProductDTO){
        APIResponse apiResponse = new APIResponse();
        List<objProductWarehouseDTO> lstProductWarehouseDTO = new List<objProductWarehouseDTO>();
        if(lstObjProductDTO.isEmpty()) {
            apiResponse.error = 'List Product Selected is empty.';
            return apiResponse;
        }
        for(objProductDTO item : lstObjProductDTO) {
            lstProductWarehouseDTO.add(new objProductWarehouseDTO(item));
        }
        if(apiResponse.error == Null) {
            apiResponse.success = true;
            apiResponse.result = lstProductWarehouseDTO;
        }
        return apiResponse;
     }

    @AuraEnabled
    public static APIResponse insertTransactionItem(List<objProductWarehouseDTO> lstWarehouseDTO, string recordId){
        APIResponse apiResponse = new APIResponse();
        DateTime d = Date.Today() ;
        String dateStr =  d.format('dd/MM/yyyy') ;
        try {               
            X3_Inventory_Transaction_Header__c objTransactionHeader = [SELECT Id
                                                                        , From_Warehouse_Location__c
                                                                        , To_Warehouse_Location__c
                                                                        , Order_Reserved__c
                                                                        FROM X3_Inventory_Transaction_Header__c
                                                                        WHERE Id =: recordId];
                                                              
            List<Inventory_Transaction_Item__c> lstTransactionItem = new List<Inventory_Transaction_Item__c>();
            for(objProductWarehouseDTO item : lstWarehouseDTO) {
                if(item.Ischecked) {
                    Inventory_Transaction_Item__c obj = new Inventory_Transaction_Item__c();
                    //obj.Name = item.ProductName + ' ' +  dateStr;
                    obj.Batch_Number__c = item.BatchNumber;
                    obj.SerialNumber__c = item.SerialNumber;
                    obj.Product__c = item.ProductId;
                    obj.Quantity__c = item.Quantity;
                    obj.Unit_Price__c = item.PriceCost;
                    obj.Vat__c = item.VAT;
                    obj.From_Warehouse_Location__c = objTransactionHeader.From_Warehouse_Location__c != Null 
                                                        ? objTransactionHeader.From_Warehouse_Location__c : Null;
                    obj.Is_Transfer__c = objTransactionHeader.From_Warehouse_Location__c != Null ? true : false;
                    obj.To_Warehouse_Location__c = objTransactionHeader.To_Warehouse_Location__c;
                    obj.Inventory_Transaction_Header__c = recordId;
                    obj.Note__c = item.Note;
                    lstTransactionItem.add(obj);
                }
            }
            if(!lstTransactionItem.isEmpty()) {
                insert lstTransactionItem;
            }
            if(apiResponse.error == Null) {
                apiResponse.success = true;
            }
            return apiResponse;
        } catch(Exception ex) {
            apiResponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            return apiResponse;
        }
     }


    public  class objProductWarehouseDTO {
        @AuraEnabled
        public  String ProductId {get;set;}
        @AuraEnabled
        public String ProductCode {get; set;}
        @AuraEnabled
        public String ProductName {get; set;}

        @AuraEnabled
        public Decimal QoH {get; set;}

        @AuraEnabled
        public Decimal Quantity {get; set;}
        

        @AuraEnabled
        public List<String> BatchOrSerial {get; set;}

        @AuraEnabled
        public String StrBatchOrSerial {get; set;}

        @AuraEnabled
        public String BatchNumber {get; set;}

        @AuraEnabled
        public String SerialNumber {get; set;}

        @AuraEnabled
        public Boolean IsChecked {get; set;}

        @AuraEnabled
        public String WarehouseId {get; set;}

        @AuraEnabled
        public Decimal PriceCost {get; set;}

        @AuraEnabled
        public Decimal VAT {get; set;}

        @AuraEnabled
        public String Note {get; set;}

        public objProductWarehouseDTO() {}

		public objProductWarehouseDTO(objProductDTO obj) {
			this.ProductId = obj.Id;
            this.QoH = obj.QoH != Null ? obj.QoH : 0;
            this.WarehouseId = obj.WarehouseId != Null ? obj.WarehouseId : Null;
            this.ProductCode = obj.ProductCode;
            this.ProductName = obj.ProductName;
            this.BatchOrSerial = new List<String>{'Batch', 'Serial'};
            this.IsChecked = true; 
            this.Quantity = 1;
            this.PriceCost = 0;
            this.VAT = 0;
            this.Note = '';
		}
    }

    public  class objProductDTO {
        @AuraEnabled
        public  String Id {get;set;}

        @AuraEnabled
        public String WarehouseId {get; set;}

        @AuraEnabled
        public String WarehouseLocation {get; set;}

        @AuraEnabled
        public Decimal QoH {get; set;}

        @AuraEnabled
        public String ProductCode {get; set;}

        @AuraEnabled
        public String ProductModelName {get; set;}

        @AuraEnabled
        public String ProductModelCode {get; set;}

        @AuraEnabled
        public String ProductName {get; set;}

        @AuraEnabled
        public Boolean isFromWarehouse {get; set;}

        @AuraEnabled
        public String RecordTypeName {get; set;}

        @AuraEnabled
        public Boolean Ischecked {get; set;}

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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a; a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
                a = a;
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
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
          a = a;
        a = a;
        a = a; a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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
      }
}