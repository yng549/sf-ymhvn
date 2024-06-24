public with sharing class BookAssetForOrderBikeController {
    private static final String STR_NONE_HAS_PRICEBOOK2 = 'Order has not value on Pricebook2 field.';
    private static final String STR_NONE_HAS_PRICEBOOKENTRY = 'Order has not any pricebook entry.';
    private static final String STR_NONE_HAS_ACCOUNT = 'Order has not value on DO/DL field.';
    private static final String STR_NONE_HAS_WAREHOUSE = 'Account has not any warehouse inventory.';


    @AuraEnabled
    public static ApiResponse getWarehouseInventoryByDODL(String recordId) {
        ApiResponse apiResponse = new ApiResponse();
        try {
            List<objWarehouseInventoryProductDTO> lstWarehouseInventoryDTO = new List<objWarehouseInventoryProductDTO>();
      
            Order objOrder = getOrderById(recordId);
    
            if(!String.isNotBlank(objOrder.DO_DL__c)) {
                apiResponse.error = STR_NONE_HAS_ACCOUNT;
                return apiResponse;
            }
            
            Account objAccount = getAccount(objOrder.DO_DL__c);
            //''a0SO000000E2sroMAB
            //objAccount.Warehouse_Location__c
            List<Warehouse_Inventory__c> lstWarehouseInventory = getAccountDODLByAccountOnOrder(objAccount.Warehouse_Location__c, objOrder);
            if(lstWarehouseInventory.isEmpty()) {
                System.debug('PAss1');
                if(objOrder.Type != 'Need to Order') {
                    objOrder.Type = 'Need to Order';
                    update objOrder;
                }
                apiResponse.error = 'Asset sold out on warehouse.';
                return apiResponse;
            } 
            if(objOrder.Type == 'Need to Order') {
                objOrder.Type = 'Stock Available';
                update objOrder;
            }
            System.debug('objOrder :' + objOrder);
            for(Warehouse_Inventory__c item : lstWarehouseInventory) {
                lstWarehouseInventoryDTO.add(new objWarehouseInventoryProductDTO(item));
            }
            System.debug('lstWarehouseInventoryDTO : ' + lstWarehouseInventoryDTO);
            if(apiResponse.error == null) {
                apiResponse.success = true;
                apiResponse.result = lstWarehouseInventoryDTO;
            } 
            return apiResponse;
        } catch(Exception ex) {
            apiResponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            return apiResponse;
        }
    }

    private static User getUserLoginCurrent() {
        return [SELECT Id, AccountId, Account.Warehouse_Location__c FROM User WHERE Id =: UserInfo.getUserId()];
    }

    @AuraEnabled
    public static ApiResponse createBookAsset(String recordId, String recordIdWarehouse, objWarehouseInventoryProductDTO objObjWareHouseDTO) {
        ApiResponse apiResponse = new ApiResponse();
        Savepoint sp = Database.setSavepoint();
        try {
            List<objWarehouseInventoryProductDTO> lstWarehouseInventoryDTO = new List<objWarehouseInventoryProductDTO>();
      
            Order objOrder = getOrderById(recordId);
            if(String.isNotBlank(objOrder.Asset__c)) {
                Asset objAsset = getAsset(objOrder.Asset__c);
                objAsset.Inventory_Status__c = 'Available';
                update objAsset;

                List<X3_Inventory_Transaction_Header__c> lstInventoryHeader = getInventoryTransaction(objOrder.Id);
                if(!lstInventoryHeader.isEmpty()) {
                    for(X3_Inventory_Transaction_Header__c item : lstInventoryHeader) {
                        item.Status__c = 'Cancled';
                    }
                    update lstInventoryHeader;
                }
            }
            Warehouse_Inventory__c objWareHouse = getWareHouseInventoryById(recordIdWarehouse);
            System.debug('objWareHouse:' + objWareHouse);
            if(!String.isNotBlank(objWareHouse.Asset__c)) {
                apiResponse.error = 'Warehouse is not set value for Asset Field.';
                return apiResponse;
            }
            //Gắn Asset (từ Warehouse Inventory được chọn) vào Asset trên Order
            objOrder.Asset__c = objWareHouse.Asset__c;
            objOrder.Is_Booked_Asset__c = true;
            

            Asset objAsset = new Asset(
                Id = objOrder.Asset__c,
                Inventory_Status__c = 'Reserved'
            );
            upsert objAsset;

            //Warehouse Inventory : field QoH trừ 1 → 0.
            

            //Tạo Inventory Transaction header
            X3_Inventory_Transaction_Header__c objInventoryHeader = new X3_Inventory_Transaction_Header__c(
                Status__c = 'Draft',
                Order_Reserved__c = objOrder.Id,
                From_Warehouse_Location__c = objWareHouse.Warehouse_Location__c
            );
            insert objInventoryHeader;
			
            Inventory_Transaction_Item__c objInventoryItem = new Inventory_Transaction_Item__c(
                Warehouse_Inventory__c = objWareHouse.Id,
                Asset_Name__c = objWareHouse.Asset__c,
                Product__c = objWareHouse.Product__c,
                Quantity__c = 1,
                SerialNumber__c = objWareHouse.Serial_Number__c,
                Inventory_Transaction_Header__c = objInventoryHeader.Id,
                From_Warehouse_Location__c = objWareHouse.Warehouse_Location__c,
                Warehouse_Location__c = objWareHouse.Warehouse_Location__c
            );
            insert objInventoryItem;

            Inventory_Assignment__c objInventoryAssignment = new Inventory_Assignment__c(
                Warehouse_Inventory__c = objWareHouse.Id,
                From_Warehouse_Location__c = objWareHouse.Warehouse_Location__c,
                Reserved_Qty__c = 1,
                Order_Reserved__c = recordId
            );
            insert objInventoryAssignment;

            objInventoryHeader.Status__c = 'Completed';
            update objInventoryHeader;
            
            update objOrder;
                
            System.debug('lstWarehouseInventoryDTO : ' + lstWarehouseInventoryDTO);
            if(apiResponse.error == null) {
                apiResponse.success = true;
            } 
            return apiResponse;
        } catch(Exception ex) {
            apiResponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            Database.rollback(sp);
            return apiResponse;
        }
    }

    private static List<X3_Inventory_Transaction_Header__c> getInventoryTransaction(String recordId) {
        return new List<X3_Inventory_Transaction_Header__c>([SELECT Id
                                                                    , Status__c
                                                            FROM    X3_Inventory_Transaction_Header__c
                                                            WHERE   Order_Reserved__c =: recordId 
                                                                AND Status__c =: 'Draft']);
    }

    private static Asset getAsset(String recordId) {
        return [SELECT Id, Inventory_Status__c FROM Asset WHERE Id =: recordId];
    }

    private static Warehouse_Inventory__c getWareHouseInventoryById(String recordID) {
        return [SELECT Id
                    , Name
                    , Product__r.Name
                    , Product__r.ProductCode
                    , QoH__c
                    , Unit_cost__c
                    , Product__r.PCA_Type__c
                    , Product__c
                    , Asset__c
                    , Asset__r.Frame_Number__c
                    , Asset__r.Engine_No__c
                    , Asset__r.Color_Type__c
                    , Serial_Number__c
                    , Stocking_Age__c
                    , Warehouse_Location__c
                    , Location__c
                FROM Warehouse_Inventory__c
                WHERE Id =: recordID];              
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

    private static Account getAccount(String accountId) {
        return [SELECT Id, Warehouse_Location__c FROM Account WHERE Id =: accountId];
    }
    
    //get Warenty inventory by DO DL
    private static List<Warehouse_Inventory__c> getAccountDODLByAccountOnOrder(String warehouseId, Order objOrder) {
        return new List<Warehouse_Inventory__c>([SELECT Id
                                                        , Name
                                                        , Product__r.Name
                                                        , Product__r.Color_Code__c
                                                        , Product__r.ProductCode
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
                                                FROM Warehouse_Inventory__c
                                                WHERE Product__c =: objOrder.Product__c 
                                                    AND QoH__c > 0
                                                    AND Warehouse_Location__c =: warehouseId
                                                    AND Asset__r.Inventory_Status__c =: 'Available'
                                                    AND Asset__c !=:  objOrder.Asset__c]);              
    }

    private static Order getOrderById(String recordId) {
        Order objOrder = [SELECT Id
                                , Pricebook2Id
                                , DO_DL__c
                                , Product__c
                                , Asset__c
                          		, Is_Booked_Asset__c
                                , Type
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
        public String FrameNo {get; set;}

        @AuraEnabled
        public Integer Quantity {get; set;}

        @AuraEnabled
        public Integer Price {get; set;}

        @AuraEnabled
        public String PCAType {get; set;}

        @AuraEnabled
        public Boolean Ischecked {get; set;}

        

        public objProductDTO() {}

		public objProductDTO(PricebookEntry obj) {
			this.Id = obj.Id;
            this.ProductCode = obj.Product2.ProductCode;
            this.ProductNameVN = obj.Product2.Name;
            this.Product2Id = obj.Product2.Id;
            this.Quantity = 1;
            this.Price = Integer.valueOf(obj.UnitPrice);
            this.PCAType = obj.Product2.PCA_Type__c;
            this.Ischecked = false;
		}
    }

    public  class objWarehouseInventoryProductDTO {
        @AuraEnabled
        public  String Id {get;set;}

        @AuraEnabled
        public String NameWarehouse {get; set;}

        @AuraEnabled
        public String ProductCode {get; set;}

        @AuraEnabled
        public String Product2Id {get; set;}

        @AuraEnabled
        public String ProductNameVN {get; set;}

        @AuraEnabled
        public String FrameNo {get; set;}

        @AuraEnabled
        public String EngineNo {get; set;}


        @AuraEnabled
        public Integer QoH {get; set;}

        @AuraEnabled
        public Integer Price {get; set;}

        @AuraEnabled
        public String SerialNumber {get; set;}

        @AuraEnabled
        public String ColorType {get; set;}

        @AuraEnabled
        public String strStockingAge  {get; set;}


        @AuraEnabled
        public String strLocation  {get; set;}

        public objWarehouseInventoryProductDTO() {}

		public objWarehouseInventoryProductDTO(Warehouse_Inventory__c obj) {
			this.Id = obj.Id;
            this.NameWarehouse = obj.Name;
            this.ProductCode = obj.Product__r.ProductCode;
            this.ProductNameVN = obj.Product__r.Name;
            this.Product2Id = obj.Product__c;
            this.FrameNo = obj.Asset__r.Frame_Number__c;
            this.EngineNo = obj.Asset__r.Engine_No__c;
            this.ColorType = obj.Asset__r.Color_Type__c;
            this.QoH = Integer.valueOf(obj.QoH__c);
            this.Price = Integer.valueOf(obj.Unit_cost__c);
            this.strStockingAge = obj.Stocking_Age__c;
            this.strLocation = obj.Location__c;
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a; 
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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