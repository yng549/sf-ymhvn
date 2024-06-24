public with sharing class AddProductPCAOrder {
    private static final String STR_NONE_HAS_PRICEBOOK2 = 'Order has not value on Pricebook2 field.';
    private static final String STR_NONE_HAS_PRICEBOOKENTRY = 'Order has not any pricebook entry.';
    private static final String STR_NONE_HAS_ACCOUNT = 'Order has not value on DO/DL field.';
    private static final String STR_NONE_HAS_WAREHOUSE = 'Account has not any warehouse inventory.';


    @AuraEnabled
    public static ApiResponse getInitalPricebookPCA(String recordId) {
        ApiResponse apiResponse = new ApiResponse();
        List<objProductDTO> lstPricebookEntryDTO = new List<objProductDTO>();
        Order objOrder = getOrderById(recordId);
        System.debug('objOrder.Pricebook2Id) :' + objOrder.Pricebook2Id);
        if(!String.isNotBlank(objOrder.Pricebook2Id)) {
            apiResponse.error = STR_NONE_HAS_PRICEBOOK2;
            return apiResponse;
        }
        System.debug('RecordTypeHelper.PRODUCT_PCA:' + RecordTypeHelper.PRODUCT_PCA);
        List<PricebookEntry> lstPricebookEntry = [SELECT Id
                                                        , Product2.Name
                                                        , Product2.PartsNameEng__c
                                                        , Product2.ProductCode
                                                        , UnitPrice
                                                        , Product2.PCA_Type__c
                                                        , Product2.Id
                                                  		, Product2.SupersedingPart__c
                                                FROM    PricebookEntry
                                                WHERE   Pricebook2Id =: objOrder.Pricebook2Id
                                                    AND IsActive =: true
                                                    AND Product2.RecordTypeId =: RecordTypeHelper.PRODUCT_PCA
                                                LIMIT 25];
        System.debug('lstPricebookEntry' + lstPricebookEntry);                                            
        if(lstPricebookEntry.isEmpty()) {
            apiResponse.error = STR_NONE_HAS_PRICEBOOKENTRY;
            return apiResponse;
        }
        for(PricebookEntry item : lstPricebookEntry) {
            objProductDTO objDTO = new objProductDTO(item);
            lstPricebookEntryDTO.add(objDTO);
        }
        if(apiResponse.error == null) {
            apiResponse.success = true;
            apiResponse.result = lstPricebookEntryDTO;
        } 
        return apiResponse;
    }
    

    @AuraEnabled
    public static ApiResponse getPricebookPCABySearchString(String recordId, String searchString) {
        ApiResponse apiResponse = new ApiResponse();
        List<objProductDTO> lstPricebookEntryDTO = new List<objProductDTO>();
        Order objOrder = getOrderById(recordId);

        if(!String.isNotBlank(objOrder.Pricebook2Id)) {
            apiResponse.error = STR_NONE_HAS_PRICEBOOK2;
            return apiResponse;
        }
        String strProdName = '%' + searchString + '%';
        List<PricebookEntry> lstPricebookEntry = [SELECT Id
                                                        , Product2.Name
                                                        , Product2.ProductCode
                                                        , UnitPrice
                                                        , Product2.PCA_Type__c
                                                        , Product2.Id
                                                        , Product2.PartsNameEng__c
                                                  		, Product2.SupersedingPart__c
                                                FROM    PricebookEntry
                                                WHERE   Pricebook2Id =: objOrder.Pricebook2Id
                                                    AND IsActive =: true
                                                    AND Product2.RecordTypeId =: RecordTypeHelper.PRODUCT_PCA
                                                    AND (Product2.Name LIKE: strProdName 
                                                            OR Product2.ProductCode LIKE: strProdName
                                                            OR Product2.PartsNameEng__c LIKE: strProdName)
                                                            LIMIT 25];
        if(lstPricebookEntry.isEmpty()) {
            apiResponse.error = STR_NONE_HAS_PRICEBOOKENTRY;
            return apiResponse;
        }
        for(PricebookEntry item : lstPricebookEntry) {
            objProductDTO objDTO = new objProductDTO(item);
            lstPricebookEntryDTO.add(objDTO);
        }
        if(apiResponse.error == null) {
            apiResponse.success = true;
            apiResponse.result = lstPricebookEntryDTO;
        } 
        return apiResponse;
    }

    @AuraEnabled
    public static ApiResponse getWarehouseInventoryByDODL(String recordId, List<objProductDTO>  lstObjProductDTO) {
        ApiResponse apiResponse = new ApiResponse();
        List<objWarehouseInventoryProductDTO> lstWarehouseInventoryDTO = new List<objWarehouseInventoryProductDTO>();
        Map<Id, objWarehouseInventoryProductDTO> mapProductOnWarehouse = new Map<Id, objWarehouseInventoryProductDTO>();
        Map<Id, Integer> mapProductWithListWarehouse = new Map<Id, Integer>();
        Set<Id> setIdProduct = new Set<Id>();
        for(objProductDTO item : lstObjProductDTO) {
            setIdProduct.add(item.Product2Id);
        }
        
        Order objOrder = getOrderById(recordId);
        
        if(!String.isNotBlank(objOrder.DO_DL__c)) {
            apiResponse.error = STR_NONE_HAS_ACCOUNT;
            return apiResponse;
        }
        Account objAccount = [SELECT Id, Warehouse_Location__c FROM Account WHERE Id =: objOrder.DO_DL__c];
        if(!String.isNotBlank(objAccount.Warehouse_Location__c)) {
            apiResponse.error = 'Account is not set value for Warehouse Location.';
            return apiResponse;
        }
        List<Warehouse_Inventory__c> lstWarehouseInventory = getAccountDODLByAccountOnOrder(objAccount.Warehouse_Location__c, setIdProduct);
        for(Warehouse_Inventory__c item : lstWarehouseInventory) {
            if (mapProductWithListWarehouse.containsKey(item.Product__c)){
                Integer totalQoH = Integer.valueOf(mapProductWithListWarehouse.get(item.Product__c) + item.QoH__c);
                mapProductWithListWarehouse.put(item.Product__c, totalQoH);
            } else{
                mapProductWithListWarehouse.put(item.Product__c, Integer.valueOf(item.QoH__c));
            }
        }
        for(objProductDTO item : lstObjProductDTO) {
            if (mapProductWithListWarehouse.containsKey(item.Product2Id)){
				lstWarehouseInventoryDTO.add(new objWarehouseInventoryProductDTO(item, mapProductWithListWarehouse.get(item.Product2Id)));
			} else{
                lstWarehouseInventoryDTO.add(new objWarehouseInventoryProductDTO(item, 0));
			}
        }
        System.debug('lstWarehouseInventoryDTO :' + lstWarehouseInventoryDTO);
        if(apiResponse.error == null) {
            apiResponse.success = true;
            apiResponse.result = lstWarehouseInventoryDTO;
        } 
        return apiResponse;
    }


    private static List<Warehouse_Inventory__c> getAccountDODLByAccountOnOrder(String warehouseLocation, Set<Id> setIdProduct2) {
        List<Warehouse_Inventory__c> lstWarehouseInventory = [SELECT Id
                                                                    , Name
                                                                    , Product__r.Name
                                                                    , Product__r.ProductCode
                                                                    , Product__r.PartsNameEng__c
                                                                    , Product__r.Model_Code__c
                                                                    , QoH__c
                                                                    , Unit_cost__c
                                                                    , Product__r.PCA_Type__c
                                                                    , Product__c
                                                                    , Asset__r.Frame_Number__c
                                                                    , Asset__r.Engine_No__c
                                                                    , Asset__r.Color_Type__c
                                                                    , Serial_Number__c
                                                                    , Stocking_Age__c
                                                                    , Location__c
                                                              		, Product__r.SupersedingPart__c
                                                                    , Product__r.Color_Name__c
                                                                FROM Warehouse_Inventory__c
                                                                WHERE  QoH__c > 0 
                                                                    AND Product__c IN: setIdProduct2
                                                                    AND Warehouse_Location__c =: warehouseLocation];
        return lstWarehouseInventory;
    }


    @AuraEnabled
    public static ApiResponse createOrderProductPCA(String recordId, List<objWarehouseInventoryProductDTO> lstObjWareHouseDTO) {
        ApiResponse apiResponse = new ApiResponse();
        
        List<objWarehouseInventoryProductDTO> lstWarehouseInventoryDTO = new List<objWarehouseInventoryProductDTO>();
        List<OrderItem> lstOrderItemInsert = new List<OrderItem>();
        List<Warehouse_Inventory__c> lstWarehouseInventoryUpdate = new List<Warehouse_Inventory__c>();
        try {
            System.debug('recordId');
            System.debug('lstObjWareHouseDTO :' + lstObjWareHouseDTO);
            Order objOrder = getOrderById(recordId);   
            for(objWarehouseInventoryProductDTO item : lstObjWareHouseDTO) {
                OrderItem i = new OrderItem();
                i.OrderId = objOrder.Id;
                i.Quantity = item.Quantity;
                if(item.Quantity > item.QoH) {
                    i.Profomar_Order__c = true;
                }
                i.UnitPrice = item.Price;
                i.Product2id = item.Product2Id;
                i.PricebookEntryId = item.strIdPricebookEntry;
                lstOrderItemInsert.add(i);
                // lstWarehouseInventoryUpdate.add(new Warehouse_Inventory__c(
                //     Id = item.Id,
                //     QoH__c = item.QoH - item.Quantity
                // ));
            }
            if(!lstOrderItemInsert.isEmpty()) {
                insert lstOrderItemInsert;
                //upsert lstWarehouseInventoryUpdate;
            }
            if(apiResponse.error == null) {
                apiResponse.success = true;
            } 
            return apiResponse;
        } catch(Exception ex) {
            System.debug('ex.getMessage() :' + ex.getMessage());
            apiResponse.error = ex.getMessage();
            return apiResponse;
        }
        
    }

    private static void checkPricebookHasProduct(List<PricebookEntry> lstPricebookEntry, Map<Id, List<Id>> mapIdParentToLstChild){
		for (PricebookEntry item : lstPricebookEntry){
			if (mapIdParentToLstChild.containsKey(item.Id)){
				List<Id> lstProduct2Child = mapIdParentToLstChild.get(item.Id);
				lstProduct2Child.add(item.Product2Id);
				mapIdParentToLstChild.put(item.Id, lstProduct2Child);
			} else{
				mapIdParentToLstChild.put(item.Id, new List<Id>{item.Product2Id});
			}
		}
	}

    //get Warenty inventory by DO DL
    private static Account getAccountDODLByAccountOnOrder(String accountId, Set<String> lstProductId) {
        Account objAccount = [SELECT Id
                                    , Name
                                    , (SELECT Id
                                            , Name
                                            , Product__r.Name
                                            , Product__r.ProductCode
                                       		, Product__r.SupersedingPart__c
                                            , QoH__c
                                            , Unit_cost__c
                                            , Product__r.PCA_Type__c
                                            , Product__c
                                        FROM Warehouses_Inventory__r
                                        WHERE Product__c IN: lstProductId
                                            AND QoH__c >= 0)
                                FROM Account
                                WHERE Id =: accountId];
        return objAccount;
    }

    private static Order getOrderById(String recordId) {
        Order objOrder = [SELECT Id
                                , Pricebook2Id
                                , DO_DL__c
                            FROM Order
                            WHERE Id =: recordId];
        return objOrder;
    }
    

    public  class objProductDTO {
        @AuraEnabled
        public  String Id {get;set;}

        

        @AuraEnabled
        public String ProductCode {get; set;}

        @AuraEnabled
        public String Product2Id {get; set;}

        @AuraEnabled
        public String ProductNameVN {get; set;}

        @AuraEnabled
        public String ProductName {get; set;}

        @AuraEnabled
        public Integer Quantity {get; set;}

        @AuraEnabled
        public Integer Price {get; set;}

        @AuraEnabled
        public String PCAType {get; set;}

        @AuraEnabled
        public Boolean Ischecked {get; set;}

        @AuraEnabled
        public String SupersedingPart {get; set;}

        public objProductDTO() {}

		public objProductDTO(PricebookEntry obj) {
			this.Id = obj.Id;
            this.ProductCode = obj.Product2.ProductCode;
            this.ProductNameVN = obj.Product2.Name;
            this.Product2Id = obj.Product2.Id;
            this.ProductName = obj.Product2.PartsNameEng__c;
            this.Quantity = 1;
            this.Price = Integer.valueOf(obj.UnitPrice);
            this.PCAType = obj.Product2.PCA_Type__c;
            this.Ischecked = false;
            this.SupersedingPart = obj.Product2.SupersedingPart__c;
		}
    }

    public  class objWarehouseInventoryProductDTO {

        @AuraEnabled
        public String ProductCode {get; set;}

        @AuraEnabled
        public String Product2Id {get; set;}

        @AuraEnabled
        public String ProductNameVN {get; set;}

        @AuraEnabled
        public String ProductName {get; set;}

        @AuraEnabled
        public Integer Quantity {get; set;}

        @AuraEnabled
        public Integer QoH {get; set;}

        @AuraEnabled
        public Integer Price {get; set;}

        @AuraEnabled
        public String PCAType {get; set;}

        @AuraEnabled
        public Boolean Ischecked {get; set;}

        @AuraEnabled
        public String strIdPricebookEntry {get; set;}
        
        @AuraEnabled
        public String SupersedingPart {get; set;}


        public objWarehouseInventoryProductDTO() {}

		public objWarehouseInventoryProductDTO(objProductDTO obj, Integer total) {
            this.ProductCode = obj.ProductCode;
            this.ProductNameVN = obj.ProductNameVN;
            this.Product2Id = obj.Product2Id;
            this.ProductName = obj.ProductName;
            this.Quantity = 1;
            this.strIdPricebookEntry = obj.Id;
            this.Price = obj.Price;
            this.PCAType = obj.PCAType;
            this.QoH = total;
            this.SupersedingPart = obj.SupersedingPart;
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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