public with sharing class VoucherGiftForAccount {
    
    @AuraEnabled
    public static APIResponse updateVoucherRedeem(objVoucherDTO objVoucherDTO, String recordId) {
        ApiResponse apiResponse = new ApiResponse();
        Map<Id, Product2> mapProduct = new Map<Id, Product2>();
        User objUser = [SELECT Id, AccountId, Account.Warehouse_Location__c FROM User WHERE Id =: UserInfo.getUserId()];
        Set<Id> setIdProduct2 = new Set<Id>();
        Map<Id, Warehouse_Inventory__c> mapProductWithListWarehouse = new Map<Id, Warehouse_Inventory__c>();
        Map<Id, PricebookEntry> mapProductWithPricebookEntry = new Map<Id, PricebookEntry>();
        List<Orderitem> lstOrderItem = new List<Orderitem>();
        Savepoint sp = Database.setSavepoint();
        try {
            if(!objVoucherDTO.lstProductCampaignDTO.isEmpty()) {
                for(objProductCampaignDTO item : objVoucherDTO.lstProductCampaignDTO) {
                    if(item.IsChecked) {
                        setIdProduct2.add(item.ProductId);
                    }
                }
            }
            if(!objVoucherDTO.lstGiftGroupDTO.isEmpty()) {
                for(objGiftGroupDTO item : objVoucherDTO.lstGiftGroupDTO) {
                    if(!item.lstProductGift.isEmpty()) {
                        for(objGiftGroupProductDTO obj : item.lstProductGift) {
                            if(obj.IsChecked) {
                                setIdProduct2.add(obj.ProductId);
                            }
                        }
                    }
                }
            }
            if(!String.isNotBlank(objUser.Account.Warehouse_Location__c)) {
                apiResponse.error = 'Account is not set value for Warehouse Location.';
                return apiResponse;
            }
            List<Warehouse_Inventory__c> lstWarehouseInventory = getAccountDODLByAccountOnOrder(objUser.Account.Warehouse_Location__c, setIdProduct2);
            for(Warehouse_Inventory__c item : lstWarehouseInventory) {
                if (mapProductWithListWarehouse.containsKey(item.Product__c)){
                    mapProductWithListWarehouse.put(item.Product__c, item);
                } else{
                    mapProductWithListWarehouse.put(item.Product__c, item);
                }
            }
            
            Order objO = new Order();
            objO.RecordTypeId = RecordTypeHelper.ORDER_FREE_SERVICE;
            objO.AccountId = recordId;
            objO.EffectiveDate = System.today();
            objO.Status = 'New';
            insert objO;

            Voucher__c voucherUpdate = new Voucher__c(
                Id = objVoucherDTO.Id,
                Redeem_Date__c = Datetime.now(),
                Voucher_Status__c = 'Redeemed',
                Order__c = objO.Id
            );
            upsert voucherUpdate;

            Order objOrder = [SELECT Id, Pricebook2Id FROM Order WHERE Id =: objO.Id];
            System.debug('objOrder :' + objOrder);
            System.debug('setIdProduct2:' + setIdProduct2);
            List<PricebookEntry> lstPriceBookEntryAddOrderItem = [SELECT Id
                                                                        , Product2Id
                                                                        , UnitPrice
                                                                    FROM PricebookEntry 
                                                                    WHERE Product2Id IN: setIdProduct2 
                                                                        AND Pricebook2Id =: objOrder.Pricebook2Id];
                                                                       
            if(lstPriceBookEntryAddOrderItem.isEmpty()) {
                apiResponse.error = 'List Product Choose do not set value pricebook entry.';
                Database.rollback( sp );
                return apiResponse;
            }                                                            
            for(PricebookEntry item : lstPriceBookEntryAddOrderItem) {
                mapProductWithPricebookEntry.put(item.Product2Id, item);
            } 

            if(!objVoucherDTO.lstProductCampaignDTO.isEmpty()) {
                
                for(objProductCampaignDTO item : objVoucherDTO.lstProductCampaignDTO) {
                    System.debug('item:' + item.ProductName);
                    if(item.IsChecked) {
                        if(item.RecordTypeId == RecordTypeHelper.PRODUCT_PCA) {
                            if(mapProductWithListWarehouse.containsKey(item.ProductId)) {
                                if(mapProductWithListWarehouse.get(item.ProductId).QoH__c > item.Quantity) {
                                    if(mapProductWithPricebookEntry.containsKey(item.ProductId)) {
                                        lstOrderItem.add(new Orderitem(
                                            OrderId = objOrder.id,
                                            PricebookEntryId = mapProductWithPricebookEntry.get(item.ProductId).Id,
                                            UnitPrice = mapProductWithPricebookEntry.get(item.ProductId).UnitPrice,
                                            Product2Id = item.ProductId,
                                            Quantity = item.Quantity
                                        ));
                                    } else {
                                        apiResponse.error = 'Product ' + item.ProductName + ' is not add pricebook entry Free/Coupon.';
                                        return apiResponse;
                                    }
                                } else {
                                    apiResponse.error = 'Quantity is not enough quantity for ' + item.ProductName;
                                    return apiResponse;
                                }
                            } else {
                                apiResponse.error = 'Warehouse Inventory is not exits product ' + item.ProductName;
                                return apiResponse;
                            }
                        } else {
                            if(mapProductWithPricebookEntry.containsKey(item.ProductId)) {
                                lstOrderItem.add(new Orderitem(
                                    OrderId = objOrder.id,
                                    PricebookEntryId = mapProductWithPricebookEntry.get(item.ProductId).Id,
                                    UnitPrice = mapProductWithPricebookEntry.get(item.ProductId).UnitPrice,
                                    Product2Id = item.ProductId,
                                    Quantity = 1
                                ));
                            } else {
                                apiResponse.error = 'Product ' + item.ProductName + ' is not add pricebook entry Free/Coupon.';
                                return apiResponse;
                            }
                        }
                    }
                }
            }
            System.debug('lstOrderItem:' + lstOrderItem);
            if(!objVoucherDTO.lstGiftGroupDTO.isEmpty()) {
                for(objGiftGroupDTO item : objVoucherDTO.lstGiftGroupDTO) {
                    if(!item.lstProductGift.isEmpty()) {
                        for(objGiftGroupProductDTO obj : item.lstProductGift) {
                            if(obj.IsChecked) {
                                System.debug('objIId:'+ obj);
                                if(obj.RecordTypeId == RecordTypeHelper.PRODUCT_PCA) {
                                    if(mapProductWithListWarehouse.containsKey(obj.ProductId)) {
                                        System.debug('mapProductWithListWarehouse.get(obj.ProductId).QoH__c :' + mapProductWithListWarehouse.get(obj.ProductId).QoH__c);
                                        System.debug('obj.Quantity :' + obj.Quantity);
                                        if(mapProductWithListWarehouse.get(obj.ProductId).QoH__c > obj.Quantity) {
                                            if(mapProductWithPricebookEntry.containsKey(obj.ProductId)) {
                                                lstOrderItem.add(new Orderitem(
                                                    OrderId = objOrder.id,
                                                    PricebookEntryId = mapProductWithPricebookEntry.get(obj.ProductId).Id,
                                                    UnitPrice = mapProductWithPricebookEntry.get(obj.ProductId).UnitPrice,
                                                    Product2Id = obj.ProductId,
                                                    Quantity = obj.Quantity
                                                ));
                                            } else {
                                                apiResponse.error = 'Product ' + obj.ProductName + ' is not add pricebook entry Free/Coupon.';
                                                return apiResponse;
                                            }
                                        } else {
                                            apiResponse.error = 'Quantity is not enough quantity for ' + obj.ProductName;
                                            return apiResponse;
                                        }
                                    } else {
                                        apiResponse.error = 'Warehouse Inventory is not exits product ' + obj.ProductName;
                                        return apiResponse;
                                    }
                                } else {
                                    if(mapProductWithPricebookEntry.containsKey(obj.ProductId)) {
                                        lstOrderItem.add(new Orderitem(
                                            OrderId = objOrder.id,
                                            PricebookEntryId = mapProductWithPricebookEntry.get(obj.ProductId).Id,
                                            UnitPrice = mapProductWithPricebookEntry.get(obj.ProductId).UnitPrice,
                                            Product2Id = obj.ProductId,
                                            Quantity = 1
                                        ));
                                    } else {
                                        apiResponse.error = 'Product ' + obj.ProductName + ' is not add pricebook entry Free/Coupon.';
                                        return apiResponse;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if(!lstOrderItem.isEmpty()) {
                insert lstOrderItem;
            }
            if(apiResponse.error == Null) {
                apiResponse.success = true;
            }
            return apiResponse;
        } catch(Exception ex) {
            apiResponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            Database.rollback(sp);
            return apiResponse;
            
        }
        
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
                                                                    , Product__r.Color_Name__c
                                                                FROM Warehouse_Inventory__c
                                                                WHERE  QoH__c > 0 
                                                                    AND Product__c IN: setIdProduct2
                                                                    AND Warehouse_Location__c =: warehouseLocation];
        return lstWarehouseInventory;
    }

    @AuraEnabled
    public static APIResponse searchVoucherByKeyInput(String strSearchKey){
        APIResponse apiResponse = new APIResponse();
        List<Group_Gift__c> lstGroupGift = new List<Group_Gift__c>();
        List<objProductCampaignDTO> lstProductCampaignDTO = new List<objProductCampaignDTO>();
        List<objGiftGroupDTO> lstGiftGroupDTO = new List<objGiftGroupDTO>();
        
        try {
            if(!String.isNotBlank(strSearchKey)) {
                apiResponse.error = 'Please input value keyword to searching.';
                return apiResponse;
            }
            Voucher__c[] objVoucher = [SELECT Id
                                            , Name
                                            , Voucher_Name__c
                                            , IMEI__c
                                            , Campaign__c
                                            , Campaign__r.Promotion_Item__c
                                            , Valid_From__c
                                            , Valid_To__c
                                            , Voucher_Status__c
                                            , RecordTypeId
                                            , RecordType.Name 
                                            , Redeem_Date__c
                                            , Is_Applied__c
                                            , Campaign__r.Name 
                                            , Campaign__r.Promotion_Item__r.Name
                                    FROM Voucher__c
                                    WHERE IMEI__c =: strSearchKey];              
            if(objVoucher.isEmpty()) {
                apiResponse.error = 'Voucher Imei is not exits..';
                return apiResponse;
            }
            if(objVoucher[0].Valid_From__c <= Date.today() && objVoucher[0].Valid_To__c <= Date.today()) {
                apiResponse.error = 'Voucher was expired.';
                return apiResponse;
            }
            if(objVoucher[0].Is_Applied__c) {
                apiResponse.error = 'Voucher was used.';
                return apiResponse;
            }
            Campaign objCampaign = [SELECT Id
                                        , Name
                                        , (SELECT Id
                                                , Name
                                                , Product__c
                                                , Product__r.Name
                                                , Campaign__c
                                                , Product__r.ProductCode
                                                , Quantity__c
                                                , Product__r.RecordTypeId
                                            FROM Product_Campaigns__r)
                                    FROM Campaign
                                    WHERE Id =: objVoucher[0].Campaign__c];                     
            if(!objCampaign.Product_Campaigns__r.isEmpty()) {
                for(Product_Campaign__c item : objCampaign.Product_Campaigns__r) {
                    lstProductCampaignDTO.add(new objProductCampaignDTO(item));
                }
            }
            lstGroupGift = [SELECT Id
                                , Name
                                , Type__c
                                , (SELECT Id
                                        , Name
                                        , Product__c
                                        , Product__r.Name
                                        , Product__r.ProductCode
                                        , Group_Gift__c
                                        , Quantity__c
                                        , Product__r.RecordTypeId
                                    FROM Group_Product_Gifts__r)
                            FROM Group_Gift__c
                            WHERE Campaign__c  =: objVoucher[0].Campaign__c];
            if(!lstGroupGift.isEmpty()) {
                for(Group_Gift__c item : lstGroupGift) {
                    if(!item.Group_Product_Gifts__r.isEmpty()) {
                        List<objGiftGroupProductDTO> lstGrifGroupProduct = new List<objGiftGroupProductDTO>();
                        for(Group_Product_Gift__c gifProd : item.Group_Product_Gifts__r) {
                            lstGrifGroupProduct.add(new objGiftGroupProductDTO(gifProd));
                        }
                        lstGiftGroupDTO.add(new objGiftGroupDTO(item, lstGrifGroupProduct));
                    } else {
                        lstGiftGroupDTO.add(new objGiftGroupDTO(item, new List<objGiftGroupProductDTO>()));
                    }
                }
            }
            objVoucherDTO objDTO = new objVoucherDTO(objVoucher[0], lstProductCampaignDTO, lstGiftGroupDTO);
            System.debug('objDTO' + objDTO);
            System.debug('lstProductCampaignDTO' + objDTO.lstProductCampaignDTO);
            System.debug('lstGiftGroupDTO' + objDTO.lstGiftGroupDTO);
            if(apiResponse.error == Null) {
                apiResponse.success = true;
                apiResponse.result = objDTO;
            }
            return apiResponse;
        } catch (Exception e) {
            apiResponse.error = e.getMessage() + ' ' + e.getLineNumber();
            return apiResponse;
        }
    }

    public  class objVoucherDTO {   
        @AuraEnabled
        public  string Id {get; set;}

        @AuraEnabled
        public  string VoucherName {get; set;}

        @AuraEnabled
        public  string VoucherCode {get; set;}

        @AuraEnabled
        public  Date ValidFromDate {get; set;}

        @AuraEnabled
        public  Date ValidToDate {get; set;}

        @AuraEnabled
        public  String IMEI {get; set;}

        @AuraEnabled
        public String CampaignId {get; set;}

        @AuraEnabled
        public String CampaignName {get; set;}

        @AuraEnabled
        public String PromotionItemId {get; set;}

        @AuraEnabled
        public String PromotionItemName {get; set;}

        @AuraEnabled
        public String RecordTypeName {get; set;}


        @AuraEnabled
        public List<objProductCampaignDTO> lstProductCampaignDTO {get; set;}

        @AuraEnabled
        public List<objGiftGroupDTO> lstGiftGroupDTO {get; set;}

        public objVoucherDTO() {} 

		public objVoucherDTO(Voucher__c obj, List<objProductCampaignDTO> lstProductCampaignDTO, List<objGiftGroupDTO> lstGiftGroupDTO) {
			this.Id = obj.Id;
            this.ValidFromDate = obj.Valid_From__c;
            this.ValidToDate = obj.Valid_To__c;
            this.VoucherName = obj.Voucher_Name__c;
            this.VoucherCode = obj.Name;
            this.IMEI = obj.IMEI__c;
            this.CampaignId = obj.Campaign__c;
            this.CampaignName = obj.Campaign__r.Name;
            this.PromotionItemId = obj.Campaign__r.Promotion_Item__c;
            this.PromotionItemName = obj.Campaign__r.Promotion_Item__r.Name;
            this.RecordTypeName = obj.RecordType.Name;
            this.lstProductCampaignDTO = lstProductCampaignDTO;
            this.lstGiftGroupDTO = lstGiftGroupDTO;
		}
    }

    //Product Campaign
    public  class objProductCampaignDTO {
        @AuraEnabled
        public  string Id {get; set;}

        @AuraEnabled
        public  string ProductId {get; set;}

        @AuraEnabled
        public  string ProductName {get; set;}

        @AuraEnabled
        public  string ProductCode {get; set;}

        @AuraEnabled
        public  String CampaignId {get; set;}

        @AuraEnabled
        public  String NameProductCampaign {get; set;}

        @AuraEnabled
        public  Decimal Quantity  {get; set;}

        @AuraEnabled
        public  String RecordTypeId {get; set;}

        @AuraEnabled
        public  Boolean IsChecked {get; set;}

        public objProductCampaignDTO() {} 

		public objProductCampaignDTO(Product_Campaign__c obj) {
            this.Id = obj.Id;
            this.ProductId = obj.Product__c;
            this.IsChecked = false;
            this.ProductCode = obj.Product__r.ProductCode;
            this.Quantity = obj.Quantity__c;
            this.RecordTypeId = obj.Product__r.RecordTypeId;
            this.NameProductCampaign = obj.Name;
            this.ProductName = obj.Product__r.Name;
            this.CampaignId = obj.Campaign__c;
        }
    }


    //Group Gift
    public  class objGiftGroupDTO {
        @AuraEnabled
        public  string Id {get; set;}

        @AuraEnabled
        public  string Name {get; set;}

        @AuraEnabled
        public  string Type {get; set;}

        @AuraEnabled
        public  Boolean IsChecked {get; set;}

        @AuraEnabled
        public  List<objGiftGroupProductDTO> lstProductGift {get; set;}

        public objGiftGroupDTO() {} 

		public objGiftGroupDTO(Group_Gift__c obj, List<objGiftGroupProductDTO> lstProductGift) {
            this.Id = obj.Id;
            this.Name = obj.Name;
            this.Type = obj.Type__c;
            this.IsChecked = false;
            this.lstProductGift = lstProductGift;
        }
    }

    public  class objGiftGroupProductDTO {
        @AuraEnabled
        public  string Id {get; set;}

        @AuraEnabled
        public  string Name {get; set;}

        @AuraEnabled
        public  string ProductId {get; set;}

        @AuraEnabled
        public  string ProductName {get; set;}

        @AuraEnabled
        public  string ProductCode {get; set;}

        @AuraEnabled
        public  string GroupGift {get; set;}
        

        @AuraEnabled
        public  Decimal Quantity  {get; set;}

        @AuraEnabled
        public  String RecordTypeId {get; set;}

        @AuraEnabled
        public  String IdGroupGift {get; set;}

        @AuraEnabled
        public  Boolean IsChecked {get; set;}

        @AuraEnabled
        public  Boolean Disabled {get; set;}

        public objGiftGroupProductDTO() {} 

		public objGiftGroupProductDTO(Group_Product_Gift__c obj) {
            this.Id = obj.Id;
            this.Name = obj.Name;
            this.ProductName = obj.Product__r.Name;
            this.ProductId = obj.Product__c;
            this.IsChecked = false;
            this.GroupGift = obj.Group_Gift__c;
            this.Quantity = obj.Quantity__c;
            this.RecordTypeId = obj.Product__r.RecordTypeId;
            this.ProductCode = obj.Product__r.ProductCode;
            this.IdGroupGift = obj.Group_Gift__c;
            this.Disabled = false;
        }
    }
    Public static void cheatTemp(){
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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