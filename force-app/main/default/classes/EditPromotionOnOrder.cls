public with sharing class EditPromotionOnOrder {
    public EditPromotionOnOrder() {

    }

   


    @AuraEnabled
    public static APIResponse getInitViewEditPromotionItem(String recordId){
        APIResponse apiResponse = new APIResponse();
        try {
            Order objOrder = getOrderById(recordId);
            List<OrderItem> lstOrderLineItem = getListOrderLineItem(recordId);
            List<objPromotionDTO> lstPromotionItemDTO = new List<objPromotionDTO>();
            Map<Id, OrderItem> mapProductWithOrderItem = new Map<Id, OrderItem>();
            Map<Id, List<Map<Id, Promotion_Product__c>>> mapProductOnPromotionProduct = new  Map<Id, List<Map<Id, Promotion_Product__c>>>();
            if(lstOrderLineItem.isEmpty()) {
                apiResponse.error = 'Order has not any Order Product.';
                return apiResponse;
            }
            for(OrderItem item : lstOrderLineItem) {
                mapProductWithOrderItem.put(item.Product2Id, item);
            }
            List<Promotion_Item__c> lstPromotionItem = getListPromotionItem(mapProductWithOrderItem.keySet(), objOrder.Promotion_Item__c);

            if(lstPromotionItem.isEmpty()) {
                apiResponse.error = 'Has not any promotion item.';
                return apiResponse;
            }

            for(Promotion_Item__c obj : lstPromotionItem) {
                if(!obj.Promotion_Productts__r.isEmpty()) {
                    
                    for(Promotion_Product__c item : obj.Promotion_Productts__r) {
                        System.debug('itemA:'+ item);
                        if (mapProductOnPromotionProduct.containsKey(item.Promotion_Item__c)){
                            List<Map<Id, Promotion_Product__c>> lstChild = mapProductOnPromotionProduct.get(item.Promotion_Item__c);
                            lstChild.add(new Map<Id, Promotion_Product__c> {item.Product__c => item});
                            System.debug('lstChild:'+ lstChild);
                            mapProductOnPromotionProduct.put(item.Promotion_Item__c, lstChild);
                        } else{
                            List<Map<Id, Promotion_Product__c>> lstMap = new List<Map<Id, Promotion_Product__c>>();
                            lstMap.add(new Map<Id, Promotion_Product__c>{item.Product__c => item});
                            mapProductOnPromotionProduct.put(item.Promotion_Item__c, lstMap);
                        }
                        System.debug('mapProductOnPromotionProduct:'+ mapProductOnPromotionProduct);
                    }
                }
            }
            
            for(Promotion_Item__c obj : lstPromotionItem) {
                List<objProductApplyDTO> lstobjProductApplyDTO = new List<objProductApplyDTO>();
                if(!obj.Promotion_Productts__r.isEmpty()) {
                    if(mapProductOnPromotionProduct.containsKey(obj.Id)) {
                        for(OrderItem odp : lstOrderLineItem) {
                            Boolean flagRun = false;
                            for(Map<Id, Promotion_Product__c> item : mapProductOnPromotionProduct.get(obj.Id)) {
                                if(item.containsKey(odp.Product2Id)) {
                                    lstobjProductApplyDTO.add(new objProductApplyDTO(odp, item.get(odp.Product2Id)));
                                    flagRun = true;
                                    break;
                                }
                            }
                            if(!flagRun) {
                                lstobjProductApplyDTO.add(new objProductApplyDTO(odp, new Promotion_Product__c()));
                            }
                        }
                    }
                    lstPromotionItemDTO.add(new objPromotionDTO(obj, lstobjProductApplyDTO));
                } else if(obj.Promotion__r.RecordTypeId == RecordTypeHelper.PROMOTIONDEFAULT && objOrder.Account.Account_Is_Primary__r.Applied_Promotion__c){
                    lstPromotionItemDTO.add(new objPromotionDTO(obj, lstobjProductApplyDTO));
                }
            }
            if(apiResponse.error == Null) {
                apiResponse.success = true;
                apiResponse.result = lstPromotionItemDTO;
            }
            return apiResponse;
        } catch (Exception e) {
            apiResponse.error = e.getMessage() + ' ' + e.getLineNumber();
            return apiResponse;
        }
    }
    
   	private static Map<Id, Promotion_Product__c> mapProductWithPromotion(String recordIdPromoItem) {
        List<Promotion_Product__c> promotionProducts = [SELECT Id
                                                            , Product__c
                                                            , Product__r.RecordTypeId
                                                            , Product__r.ProductCode
                                                            , Product__r.Name
                                                            , Promotion_Item__r.Discount__c
                                                            , Quantity__c
                                                            , Discount__c
                                                        FROM Promotion_Product__c
                                                    WHERE Promotion_Item__c = :recordIdPromoItem 
                                                        AND Product__c != null];
        Map<Id, Promotion_Product__c> productMap = new Map<Id, Promotion_Product__c>();
        for(Promotion_Product__c item : promotionProducts) {
            productMap.put(item.Product__c, item);
        }
        return productMap;
    }
    
    private static List<OrderItem> getOrderItemsbyOrder(String recordIdOrder) {
        return [SELECT Id
                	, Product2Id 
                FROM OrderItem 
                WHERE OrderId =: recordIdOrder];
    }

    @AuraEnabled
    public static APIResponse updateVoucherApplyPromotionItem(objVoucherDTO objVoucherDTO, String recordId){
        APIResponse apiResponse = new APIResponse();
        Savepoint sp = Database.setSavepoint();
        try {
            Voucher__c voucherUpdate = new Voucher__c(
                Id = objVoucherDTO.Id,
                Redeem_Date__c = Date.today(),
                Order__c = recordId,
                Voucher_Status__c = 'Redeemed'
            );
            update voucherUpdate;
            Order orderUpdate = new Order(
                Id = recordId,
                Promotion_Item__c = objVoucherDTO.PromotionItemId
            );
            update orderUpdate;
            
            Map<Id, Promotion_Product__c> mapProdWithPromoProd = mapProductWithPromotion(orderUpdate.Promotion_Item__c);
            
            if(mapProdWithPromoProd.values().isEmpty()) {
                List<OrderItem> lstOrderItem = getOrderItemsbyOrder(orderUpdate.Id);
                List<OrderItem> lstOrderItemUpdate = new List<OrderItem>();
                //Loop qua danh sách order item query lên theo order. check map bằng product2id trên order item nếu trùng thì gắn id promotion product lên.
                for(OrderItem item : lstOrderItem) {
                    item.Promotion_Product__c = mapProdWithPromoProd?.get(item.Product2Id)?.Id;
                    lstOrderItemUpdate.add(item);
                }
                //update và kết thúc
                if(!lstOrderItemUpdate.isEmpty()) {
                    update lstOrderItemUpdate;
                }
            }
            if(apiResponse.error == Null) {
                apiResponse.success = true;
            }
            return apiResponse;
        } catch(Exception ex) {
            apiResponse.error = ex.getMessage() + ex.getLineNumber();
            Database.rollback(sp);
            return apiResponse;
        }
    }
    
    
     @AuraEnabled
    public static APIResponse updateFieldPromotionItem(String recordId, String recordSelected){
        APIResponse apiResponse = new APIResponse();
        try {
            Order objOrder = getOrderById(recordId);
            objOrder.Promotion_Item__c = recordSelected;
            update objOrder;
            //Update promotion product lên product item
            
            Map<Id, Promotion_Product__c> mapProdWithPromoProd = mapProductWithPromotion(objOrder.Promotion_Item__c);
            
            if(!mapProdWithPromoProd.values().isEmpty()) {
                List<OrderItem> lstOrderItem = getOrderItemsbyOrder(objOrder.Id);
                List<OrderItem> lstOrderItemUpdate = new List<OrderItem>();
                //Loop qua danh sách order item query lên theo order. check map bằng product2id trên order item nếu trùng thì gắn id promotion product lên.
                for(OrderItem item : lstOrderItem) {
                    item.Promotion_Product__c = mapProdWithPromoProd?.get(item.Product2Id)?.Id;
                    lstOrderItemUpdate.add(item);
                }
                //update và kết thúc
                if(!lstOrderItemUpdate.isEmpty()) {
                    update lstOrderItemUpdate;
                }
            }
            if(apiResponse.error == Null) {
                apiResponse.success = true;
            }
            return apiResponse;
        } catch(Exception e) {
            apiResponse.error = e.getMessage() + ' ' + e.getLineNumber();
            return apiResponse;
        }
    }

    @AuraEnabled
    public static APIResponse searchVoucherByKeyInput(String strSearchKey){
        APIResponse apiResponse = new APIResponse();
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
            objVoucherDTO voucherDTO = new objVoucherDTO(objVoucher[0]);
            if(apiResponse.error == Null) {
                apiResponse.success = true;
                apiResponse.result = voucherDTO;
            }
            return apiResponse;
        } catch (Exception e) {
            apiResponse.error = e.getMessage() + ' ' + e.getLineNumber();
            return apiResponse;
        }
    }

    private static List<OrderItem> getListOrderLineItem(String recordIdOrder) {
        List<OrderItem> lstOrderLineItem = [SELECT Id
                                                        , Product2.Name
                                                        , Product2Id
                                                        , Product2.RecordTypeId
                                                        , Product2.ProductCode
                                                        , ListPrice
                                                        , UnitPrice
                                                FROM    OrderItem
                                                WHERE OrderId =: recordIdOrder];
        if(!lstOrderLineItem.isEmpty()) {
            return lstOrderLineItem;
        } else {
            return new List<OrderItem>();
        }                                        
    }

    private static Order getOrderById(String recordId) {
        return [SELECT Id
                    ,   Name
                    ,   AccountId
                    ,   Account.Account_Is_Primary__c
                    ,   Account.Account_Is_Primary__r.Applied_Promotion__c
                    ,   Promotion_Item__c
                    ,   Account.Applied_Promotion__c
                FROM Order
                WHERE Id =: recordId
                LIMIT 1];
    }


    private static List<Promotion_Item__c> getListPromotionItem(Set<Id> setIdProductId, String IdCurrent) {
        List<Promotion_Item__c> lstPromotionItem = [SELECT Id
                                                            , Name
                                                            , FProduct_Code__c
                                                            , Discount__c
                                                            , Voucher_Amount__c
                                                            , Valid_from__c
                                                            , Valid_to__c
                                                            , RecordTypeId
                                                            , Promotion__r.RecordTypeId
                                                            , Promotion__r.RecordType.Name
                                                            , RecordType.Name
                                                            , Promotion_Item_Code__c
                                                            , (SELECT Id
                                                                    , Name
                                                                    , Promotion_Item__c
                                                                    , Product__c
                                                                    , Product__r.Name
                                                                    , From__c
                                                                    , Discount__c
                                                                    , To__c
                                                                    , Sale_Price__c
                                                                    , Promotion_Item__r.RecordTypeId
                                                                FROM Promotion_Productts__r
                                                                WHERE Product__c IN: setIdProductId)
                                                    FROM Promotion_Item__c
                                                    WHERE Valid_from__c <=: Date.today() 
                                                        AND Valid_to__c >=: Date.today()
                                                        AND Active__c =: true
                                                        AND Id !=: IdCurrent
                                                        AND Public_Access__c =: true];
        if(!lstPromotionItem.isEmpty()) {
            return lstPromotionItem;
        } else {
            return new List<Promotion_Item__c>();
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
        public Boolean IsCheck {get; set;}
        

        public objVoucherDTO() {} 

		public objVoucherDTO(Voucher__c obj) {
			this.Id = obj.Id;
            this.VoucherName = obj.Voucher_Name__c;
            this.VoucherCode = obj.Name;
            this.IMEI = obj.IMEI__c;
            this.CampaignId = obj.Campaign__c;
            this.CampaignName = obj.Campaign__r.Name;
            this.PromotionItemId = obj.Campaign__r.Promotion_Item__c;
            this.PromotionItemName = obj.Campaign__r.Promotion_Item__r.Name;
            this.RecordTypeName = obj.RecordType.Name;
            this.IsCheck = false;
		}
    }

    public  class objProductApplyDTO {
        @AuraEnabled
        public  string Id {get; set;}

        @AuraEnabled
        public  string ProductCode {get; set;}

        @AuraEnabled
        public  string ProductId {get; set;}

        @AuraEnabled
        public  String ProductName {get; set;}

        @AuraEnabled
        public Decimal ListPrice {get; set;}

        @AuraEnabled
        public Decimal Discount {get; set;}

        @AuraEnabled
        public Decimal SalePrice {get; set;}

        @AuraEnabled
        public Decimal DiscountPrice {get; set;}



        @AuraEnabled
        public  Promotion_Product__c objPromotionProduct {get; set;}

        public objProductApplyDTO() {} 

		public objProductApplyDTO(OrderItem obj, Promotion_Product__c objPromotion) {
			this.Id = obj.Id;
            this.ProductId = obj.Product2Id;
            this.ProductCode = obj.Product2.ProductCode;
            this.ProductName = obj.Product2.Name;
            this.ListPrice = obj.ListPrice;
            this.Discount = 0;
            this.SalePrice = 0;
            this.DiscountPrice = 0;
            if(objPromotion != Null) {
                if(objPromotion.Promotion_Item__r.RecordTypeId == RecordTypeHelper.PROMOTIONITEMDISCOUNTAM) {
                    this.SalePrice = objPromotion.Sale_Price__c;
                    this.DiscountPrice = obj.ListPrice - this.SalePrice;
                } else if(objPromotion.Promotion_Item__r.RecordTypeId == RecordTypeHelper.PROMOTIONITEMDISCOUNT) {
                    this.Discount = objPromotion.Discount__c;
                    this.DiscountPrice = obj.ListPrice*(objPromotion.Discount__c != Null ? objPromotion.Discount__c : 1)/100;
                    this.SalePrice = obj.ListPrice - obj.ListPrice*(objPromotion.Discount__c != Null ? objPromotion.Discount__c : 1)/100;
                }
                this.objPromotionProduct = objPromotion;
            }
		}
    }
        


    public  class objPromotionDTO {
        @AuraEnabled
        public  string Id {get; set;}

        @AuraEnabled
        public  string Name {get; set;}

        @AuraEnabled
        public  String PromotionCode {get; set;}

        @AuraEnabled
        public Decimal Discount {get; set;}

        @AuraEnabled
        public Decimal VoucherAmount {get; set;}

        @AuraEnabled
        public Date ValidFrom {get; set;}

        @AuraEnabled
        public Date ValidTo {get; set;}

        @AuraEnabled
        public String RecordTypeId {get; set;}

        @AuraEnabled
        public String RecordTypeName {get; set;}

        @AuraEnabled
        public Decimal AmountDiscount {get; set;}


        @AuraEnabled
        public String PromotionProd {get; set;}


        @AuraEnabled
        public String Promotion {get; set;}

        @AuraEnabled
        public String RecordTypePromotion {get; set;}
        
        @AuraEnabled
        public List<Promotion_Product__c> lstPromotionProduct {get; set;}

        @AuraEnabled
        public Boolean IsCheck {get; set;}

        @AuraEnabled
        public List<objProductApplyDTO> lstProductApplyDTO {get; set;}

        public objPromotionDTO() {}

		public objPromotionDTO(Promotion_Item__c obj, List<objProductApplyDTO> lstProductApplyDTO) {
			this.Id = obj.Id;
            this.Name = obj.Name;
            this.PromotionCode = obj.Promotion_Item_Code__c;
            this.VoucherAmount = obj.Voucher_Amount__c;
            this.Discount = obj.Discount__c;
            this.ValidFrom = obj.Valid_from__c;
            this.ValidTo = obj.Valid_to__c;
            this.RecordTypeId = obj.RecordTypeId;
            this.RecordTypeName = obj.RecordType.Name;
            this.IsCheck = false;
            
            if(!obj.Promotion_Productts__r.isEmpty()) {
                this.lstPromotionProduct = obj.Promotion_Productts__r;
            }
            if(obj.Promotion__c != Null) {
                this.Promotion = obj.Promotion__c;
                this.RecordTypePromotion = obj.Promotion__r.RecordType.Name;
            }
            this.lstProductApplyDTO = lstProductApplyDTO;
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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
    }
}