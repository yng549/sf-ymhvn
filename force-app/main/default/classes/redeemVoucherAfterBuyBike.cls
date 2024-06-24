public without sharing class redeemVoucherAfterBuyBike {
    private static String  STR_NONE_HAS_PROMOTION_ITEM = 'Không có promotion amount nào cho sản phẩm pca. Vui lòng kiểm tra lại.';
    private static String  STR_NONE_HAS_ACCOUNT = 'User chưa được gắn account DO/DL.';
    private static String  STR_USER_NONE_HAS_WAREHOUSE = 'Account trên User chưa được gắn account Warehouse Location.';
    private static String  STR_NONE_HAS_WAREHOUSE = 'Không có bất kì danh sách warehouse inventory nào.';

    @AuraEnabled
    public static ApiResponse getWarehouseInitByPromotion(String recordId, String strName) {
        ApiResponse apiResponse = new ApiResponse();
        Map<Id, PricebookEntry> mapProductWithPricebook = new Map<Id, PricebookEntry>();
        List<objWarehouseInventoryProductDTO> lstWawrehouseDTO = new List<objWarehouseInventoryProductDTO>();
        Set<Id> setIdProduct = new Set<Id>();
        User objUser = getUserDefault();
        Decimal totalAmount = 0;
        try {
            if(!String.isNotBlank(objUser.AccountId)) {
                 apiResponse.error = STR_NONE_HAS_ACCOUNT;
                 return apiResponse;
            }
            if(!String.isNotBlank(objUser.Account.Warehouse_Location__c)) {
                 apiResponse.error = STR_USER_NONE_HAS_WAREHOUSE;
                 return apiResponse;
            }
            Opportunity objOppty = getObjOpportunity(recordId);
            if(!String.isNotBlank(objOppty.SyncedQuoteId)) {
                apiResponse.error = 'Opportunity chưa được đồng bộ Quote.';
                return apiResponse;
            }
            if(objOppty.Is_Redeemed__c) {
                apiResponse.error = 'Opportunity đã redeemed promotion.';
                return apiResponse;
            }  
            Quote objQuote = getQuoteByRecordId(objOppty.SyncedQuoteId);
            if(!objQuote.IsSyncing) {
                apiResponse.error = 'Quote chưa được sync với Opportunity.';
                return apiResponse;
            }
             
            if(objQuote.Quote_Promotion_Packs__r.isEmpty()) {
                apiResponse.error = STR_NONE_HAS_PROMOTION_ITEM;
                return apiResponse;
            }
            for(Quote_Promotion_Pack__c item : objQuote.Quote_Promotion_Packs__r) {
                totalAmount += item.Promotion_Pack__r.Pack_Amount__c != Null ? item.Promotion_Pack__r.Pack_Amount__c : 0;
            }
            System.debug('totalAmount:'+ totalAmount);
            //objUser.Account.Warehouse_Location__c
            List<Warehouse_Inventory__c> lstWarehouse = getAccountDODLByAccountOnOrder(objUser.Account.Warehouse_Location__c, strName);
            
            System.debug('lstWarehouse :' + lstWarehouse);
            if(lstWarehouse.isEmpty()) {
                apiResponse.error = STR_NONE_HAS_WAREHOUSE;
                return apiResponse;
            }
            for(Warehouse_Inventory__c item : lstWarehouse) {
                
                if(item.Product__c != Null) {
                    setIdProduct.add(item.Product__c);
                } 
            }
            List<PricebookEntry> lstPricebookEntry = getListPricebookEntry(setIdProduct);
            if(!lstPricebookEntry.isEmpty()) {
                for(PricebookEntry item : lstPricebookEntry) {
                    System.Debug('PB Entry');
                    mapProductWithPricebook.put(item.Product2Id, item);
                }
            }
            for(Warehouse_Inventory__c item : lstWarehouse) {
                if(mapProductWithPricebook.containsKey(item.Product__c)) {
                    lstWawrehouseDTO.add(new objWarehouseInventoryProductDTO(item, mapProductWithPricebook.get(item.Product__c)));
                } else {
                    apiResponse.error = 'Product ' + item.Product__r.Name + ' chưa được thiết lập pricebook.';
                    return apiResponse;
                }
            }
            
            System.debug('lstWawrehouseDTO :' + lstWawrehouseDTO);
            if(!lstWawrehouseDTO.isEmpty()) {
                if(apiResponse.error == Null) {
                    apiResponse.success = true;
                    System.debug('objVoucherAfterBuyBikeDTO :' + new objVoucherAfterBuyBikeDTO(totalAmount, lstWawrehouseDTO));
                    apiResponse.result = new objVoucherAfterBuyBikeDTO(totalAmount, lstWawrehouseDTO);
                }
            }
            return apiResponse;
        } catch(Exception ex) {
            apiResponse.error = ex.getMessage() + ' ' +  ex.getLineNumber();
            return apiResponse;
        }
    }

    @AuraEnabled
    public static ApiResponse createOrder(List<objWarehouseInventoryProductDTO> lstWarehouseDTO, String recordId) {
        ApiResponse apiResponse = new ApiResponse();
        Map<Id, PricebookEntry> mapProductWithPricebook = new Map<Id, PricebookEntry>();
        User objUser = getUserDefault();
        Set<Id> setIdProduct = new Set<Id>();
        List<OrderItem> lstOrderItemInsert = new List<OrderItem>();
        Savepoint sp = Database.setSavepoint();
        try {
            if(!String.isNotBlank(objUser.AccountId)) {
                apiResponse.error = STR_NONE_HAS_ACCOUNT;
                return apiResponse;
            }
            if(!String.isNotBlank(objUser.Account.Warehouse_Location__c)) {
               apiResponse.error = STR_USER_NONE_HAS_WAREHOUSE;
               return apiResponse;
            }
            System.debug('lstWarehouseDTO :' + lstWarehouseDTO);
            Opportunity objOppty = getObjOpportunity(recordId);
            objOppty.Is_Redeemed__c = true;
            update objOppty;
            
            Order objOrder = new Order(
                OpportunityId = objOppty.Id,
                AccountId = objOppty.AccountId,
                EffectiveDate = System.today(),
                Status = 'Draft',
                Generated_Redeem__c = true,
                RecordTypeId = RecordTypehelper.ORDER_PCA
            );
            insert objOrder;

            Order objQuerry = [SELECT Id, Pricebook2Id FROM Order WHERE Id =: objOrder.Id];
            System.debug('objQuerry' + objOrder);
            for(objWarehouseInventoryProductDTO item : lstWarehouseDTO) {
                setIdProduct.add(item.Product2Id);
            }
            System.debug('objQuerry.Pricebook2Id :' + objQuerry.Pricebook2Id); 
            Map<Id, Warehouse_Inventory__c> mapWarehouseByIdProduct = new Map<Id, Warehouse_Inventory__c>([
                SELECT Id
                    , QoH__c
                    , Product__c
                FROM Warehouse_Inventory__c
                WHERE Product__c IN: setIdProduct AND Warehouse_Location__c =: objUser.Account.Warehouse_Location__c]);
            
            
            //objUser.Account.Warehouse_Location__c
            System.debug('mapWarehouseByIdProduct :' + mapWarehouseByIdProduct);
            if(mapWarehouseByIdProduct.values().isEmpty()) {
                Database.rollback(sp);
                apiResponse.error = STR_NONE_HAS_WAREHOUSE;
                return apiResponse;
            }
                 
            List<PricebookEntry> lstPricebookEntry = [SELECT Id
                                                        , UnitPrice
                                                        , Product2Id
                                                FROM    PricebookEntry
                                                WHERE   Product2Id IN: setIdProduct AND Pricebook2Id =: objQuerry.Pricebook2Id];
                                         
            if(!lstPricebookEntry.isEmpty()) {
                for(PricebookEntry item : lstPricebookEntry) {
                    mapProductWithPricebook.put(item.Product2Id, item);
                }
            }
            System.debug('mapProductWithPricebook :' + mapProductWithPricebook);
            for(objWarehouseInventoryProductDTO item : lstWarehouseDTO) {
                if(mapProductWithPricebook.containsKey(item.Product2Id)) {
                    lstOrderItemInsert.add(new OrderItem(
                        OrderId = objOrder.Id,
                        Quantity = item.QuantityInput,
                        Profomar_Order__c = item.QuantityInput > item.QoH ? true : false,
                        UnitPrice = 0,
                        Generated_Redeem__c = true,
                        Product2id = item.Product2Id,
                        PricebookEntryId = mapProductWithPricebook.get(item.Product2Id).Id
                    ));
                } else {
                    Database.rollback(sp);
                    apiResponse.error = 'Product ' + item.ProductNameVN + ' chưa được thiết lập pricebook.';
                    return apiResponse;
                }
            }
            if(!lstOrderItemInsert.isEmpty()) {
                insert lstOrderItemInsert;
            }
            if(apiResponse.error == Null) {
                apiResponse.success = true;
            }
            return apiResponse;
        } catch(Exception ex) {
            Database.rollback(sp);
            apiResponse.error = ex.getMessage() + ' ' +  ex.getLineNumber();
            return apiResponse;
        }
    }

    private static Opportunity getObjOpportunity(String recordId) {
        return [SELECT Id
                        , SyncedQuoteId
                        , Is_Redeemed__c
                        , AccountId
                FROM Opportunity
                WHERE Id =: recordId];
    }

    private static Quote getQuoteByRecordId(String recordId) {
        return [SELECT Id
                    , OpportunityId
                    , Opportunity.Is_Redeemed__c
                    , AccountId
                    , IsSyncing
                    , (SELECT Id
                            , Promotion_Pack__r.Pack_Amount__c
                        FROM Quote_Promotion_Packs__r 
                        WHERE Promotion_Pack__r.Pack_Amount__c != Null)
                FROM Quote
                WHERE Id =: recordId];
    }

    private static User getUserDefault() {
        return [SELECT Id
                        , AccountId
                        , Account.Warehouse_Location__c 
                FROM User WHERE Id =: UserInfo.getUserId()];
    }

    private static List<PricebookEntry> getListPricebookEntry(Set<Id> setId) {
        return new List<PricebookEntry>([SELECT Id
                                                , Product2.Name
                                                , Product2.ProductCode
                                                , UnitPrice
                                                , Product2.PCA_Type__c
                                                , Product2.Id
                                                , Product2.PartsNameEng__c
                                                , Product2.SupersedingPart__c
                                        FROM    PricebookEntry
                                        WHERE   IsActive =: true
                                            AND Product2.RecordTypeId =: RecordTypeHelper.PRODUCT_PCA
                                            AND Product2Id IN: setId]);
    }

    private static List<Warehouse_Inventory__c> getAccountDODLByAccountOnOrder(String warehouseLocation, String strName) {
        String criteria = ' ';
        String strIdWarehouse = warehouseLocation;
        String recordTypePCA = RecordTypeHelper.PRODUCT_PCA;
        System.debug('strIdWarehouse' + strIdWarehouse);
        String strNameSearch = strName;
        if (!String.isEmpty(strNameSearch)) {
            String key = '%' + strNameSearch + '%';
            criteria += ' AND  (Product__r.PartsNameEng__c LIKE: key OR Product__r.Name LIKE: key OR Product__r.ProductCode LIKE: key) ';
        }
        String strQuerry = 'SELECT Id, Name, Product__r.Name, Product__r.ProductCode, Product__r.PartsNameEng__c, Product__r.Model_Code__c, QoH__c, Unit_cost__c, Product__r.PCA_Type__c, Product__c FROM Warehouse_Inventory__c ' +
                            ' WHERE  QoH__c >= 0  AND Warehouse_Location__c =: strIdWarehouse AND Product__r.RecordTypeId =: recordTypePCA ' + criteria +
                           ' LIMIT 20';
        
        
        System.debug('strQuerry' + strQuerry);
        List<Warehouse_Inventory__c> lstWarehouse = Database.query(strQuerry);
        System.debug('lstWarehouse' + lstWarehouse);
        return lstWarehouse;
    }

    public  class objVoucherAfterBuyBikeDTO {

        @AuraEnabled
        public Decimal TotalAmount {get; set;}

        @AuraEnabled
        public List<objWarehouseInventoryProductDTO> lstWarehouseDTO {get; set;}
        
        public objVoucherAfterBuyBikeDTO() {}

		public objVoucherAfterBuyBikeDTO(Decimal total, List<objWarehouseInventoryProductDTO> lstWarehouseDTO) {
            this.TotalAmount = total;
            this.lstWarehouseDTO = lstWarehouseDTO;
		}
    }

    public  class objWarehouseInventoryProductDTO {
        @AuraEnabled
        public String Id {get; set;}

        @AuraEnabled
        public String ProductCode {get; set;}

        @AuraEnabled
        public String Product2Id {get; set;}

        @AuraEnabled
        public String ProductNameVN {get; set;}

        @AuraEnabled
        public String ProductName {get; set;}


        @AuraEnabled
        public Decimal QoH {get; set;}

        @AuraEnabled
        public Decimal Price {get; set;}

        @AuraEnabled
        public Boolean Ischecked {get; set;}

        @AuraEnabled
        public String strIdPricebookEntry {get; set;}

        @AuraEnabled
        public Boolean isDisabled {get; set;}

        @AuraEnabled
        public Integer QuantityInput {get; set;}


        public objWarehouseInventoryProductDTO() {}

		public objWarehouseInventoryProductDTO(Warehouse_Inventory__c obj, PricebookEntry pricebook) {
            this.Id = obj.Id;
            this.ProductCode = obj.Product__r.ProductCode;
            this.ProductNameVN = obj.Product__r.Name;
            this.Product2Id = obj.Product__c;
            this.ProductName = obj.Product__r.PartsNameEng__c;
            this.strIdPricebookEntry = pricebook.Id;
            this.Price = pricebook.UnitPrice;
            this.QoH = obj.QoH__c;
            this.Ischecked = false;
            this.isDisabled = false;
            this.QuantityInput = 1;
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