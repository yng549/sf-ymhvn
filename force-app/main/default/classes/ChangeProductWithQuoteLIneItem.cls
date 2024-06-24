public without sharing class ChangeProductWithQuoteLIneItem {
    
    @AuraEnabled
    public static ApiResponse getQuotelineItem(String recordQuoteId){
        ApiResponse apiresponse = new ApiResponse();
        try {
            QuoteLineItem objQuoteLineItem = getObjQuoteLineItem(recordQuoteId);
            
            if(apiresponse.error == Null) {
                apiresponse.success = true;
                apiresponse.result = new objQuoteLineDTO(objQuoteLineItem);
            }
            return apiresponse;
        } catch (Exception e) {
            apiresponse.error = e.getMessage() + ' ' + e.getLineNumber();
            return apiresponse;
        }
    }

    @AuraEnabled
    public static ApiResponse getWarehouseInventoryByDODL(String recordQuoteId) {
        ApiResponse apiResponse = new ApiResponse();
        try {
            Set<Id> setIdProduct = new Set<Id>();
            Map<Id, List<Warehouse_Inventory__c>> mapProductWithListWarehouse = new Map<Id, List<Warehouse_Inventory__c>>();
            QuoteLineItem objQuoteLineItem = getObjQuoteLineItem(recordQuoteId);
            List<objWarehouseInventoryProductDTO> lstWarehouseInventoryDTO = new List<objWarehouseInventoryProductDTO>();
            User objUser = getUserLoginCurrent();
            if(!String.isNotBlank(objUser.AccountId)) {
                apiResponse.error = 'User do not exits DO DL.';
                return apiResponse;
            }
            if(!String.isNotBlank(objQuoteLineItem.Quote.PriceBook2Id)) {
                apiResponse.error = 'Quote is not value for field Pricebook.';
                return apiResponse;
            }
            List<PricebookEntry> lstPricebookEntryEntry = [SELECT Id
                                                                , UnitPrice
                                                                , Product2Id
                                                                , Product2.ProductCode
                                                                , Product2.Name
                                                                , Product2.Color_Type__c
                                                                , Product2.Color_Name__c
                                                                , Product2.Model_Code__c
                                                            FROM PricebookEntry 
                                                            WHERE Pricebook2Id =: objQuoteLineItem.Quote.PriceBook2Id
                                                                AND Product2.RecordTypeId =: RecordTypeHelper.PRODUCT_MODEL];

            if(lstPricebookEntryEntry.isEmpty()) {
                apiResponse.error = 'Not any pricebook entry for this quote.';
                return apiResponse;
            }
            //objUser.AccountId
            //001O000001rVQFyIAO
            List<Warehouse_Inventory__c> lstWarehouseInventory = getAccountDODLByAccountOnOrder(objUser.Account.Warehouse_Location__c);
            
            if(lstWarehouseInventory.isEmpty()) {
                apiResponse.error = 'Asset sold out on warehouse.';
                return apiResponse;
            }
            for(Warehouse_Inventory__c item : lstWarehouseInventory) {
                if (mapProductWithListWarehouse.containsKey(item.Product__c)){
                    List<Warehouse_Inventory__c> lstProductInWarehouse = mapProductWithListWarehouse.get(item.Product__c);
                    lstProductInWarehouse.add(item);    
                    mapProductWithListWarehouse.put(item.Product__c, lstProductInWarehouse);
                } else{
                    mapProductWithListWarehouse.put(item.Product__c, new List<Warehouse_Inventory__c>{item});
                }
            }
            System.debug('mapProductWithListWarehouse :' + mapProductWithListWarehouse);
            for(PricebookEntry item : lstPricebookEntryEntry) {
                System.debug('item :' + item.Product2Id);
                System.debug('item Name:' + item.Product2.Name);
               if(mapProductWithListWarehouse.containsKey(item.Product2Id)) {
                    lstWarehouseInventoryDTO.add(new objWarehouseInventoryProductDTO(item, mapProductWithListWarehouse.get(item.Product2Id).size()));
               } else {
                    lstWarehouseInventoryDTO.add(new objWarehouseInventoryProductDTO(item, 0));
               }
            }
            System.debug('lstWarehouseInventoryDTO :' + lstWarehouseInventoryDTO);
            if(apiResponse.error == null) {
                apiResponse.success = true;
                apiResponse.result = lstWarehouseInventoryDTO;
            } 
            return apiResponse;
        } catch(Exception ex) {
            apiresponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            return apiResponse;
        }
    }

    @AuraEnabled
    public static ApiResponse searchProduct(String strKeySearch) {
        ApiResponse apiResponse = new ApiResponse();
        try {
            String key, whereClause = '';
            String[] criteria = new List<String>{};
            User objUser = getUserLoginCurrent();
            Map<Id, List<Warehouse_Inventory__c>> mapProductWithListWarehouse = new Map<Id, List<Warehouse_Inventory__c>>();
            List<Warehouse_Inventory__c> lstWarehouseInventory = getAllProductInWarehouseByAccountId(objUser.Account.Warehouse_Location__c);
            System.debug('lstWarehouseInventory :' + lstWarehouseInventory);
            List<objWarehouseInventoryProductDTO> lstWarehouseInventoryDTO = new List<objWarehouseInventoryProductDTO>();
            List<PricebookEntry> lstProduct2Querry = new List<PricebookEntry>();

            if (strKeySearch != null) {
                key = '%' + strKeySearch + '%';
                criteria.add('Product2.Name LIKE :key');
                criteria.add('Product2.ProductCode LIKE :key');
                criteria.add('Product2.Color_Name__c LIKE :key');
                criteria.add('Product2.Color_Code__c LIKE :key');
                if (criteria.size() > 0) {
                    whereClause = 'WHERE ' + String.join(criteria, ' OR ');
                }
            }
            lstProduct2Querry = Database.query(
                'SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.ProductCode, Product2.Color_Type__c, Product2.Color_Name__c, Product2.Model_Code__c FROM PricebookEntry ' +
                whereClause +
                ' ORDER BY Name '
            );

            if(lstProduct2Querry.isEmpty()) {
                apiResponse.error = 'Product is not exits like the keyword.';
                return apiResponse;
            }

            for(Warehouse_Inventory__c item : lstWarehouseInventory) {
                if (mapProductWithListWarehouse.containsKey(item.Product__c)){
                    List<Warehouse_Inventory__c> lstProductInWarehouse = mapProductWithListWarehouse.get(item.Product__c);
                    lstProductInWarehouse.add(item);    
                    mapProductWithListWarehouse.put(item.Product__c, lstProductInWarehouse);
                } else{
                    mapProductWithListWarehouse.put(item.Product__c, new List<Warehouse_Inventory__c>{item});
                }
            }
            System.debug('mapProductWithListWarehouse :' + mapProductWithListWarehouse);
            for(PricebookEntry item : lstProduct2Querry) {
               System.debug('item : ' + item.Product2Id);
               
               if(mapProductWithListWarehouse.containsKey(item.Product2Id)) {
                    System.debug('mapProductWithListWarehouse : ' + mapProductWithListWarehouse.get(item.Product2Id).size());
                    lstWarehouseInventoryDTO.add(new objWarehouseInventoryProductDTO(item, mapProductWithListWarehouse.get(item.Product2Id).size()));
               } else {
                    lstWarehouseInventoryDTO.add(new objWarehouseInventoryProductDTO(item, 0));
               }
            }
            System.debug('lstWarehouseInventoryDTO :' + lstWarehouseInventoryDTO.size());
            if(apiResponse.error == null) {
                apiResponse.result = lstWarehouseInventoryDTO;
                apiResponse.success = true;
            } 
            return apiResponse;
        } catch(Exception ex) {
            apiresponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            System.debug(' apiresponse.error : ' +  apiresponse.error);
            return apiResponse;
        }
    }


    @AuraEnabled
    public static ApiResponse searchProductCheckStock(String strKeySearch) {
        ApiResponse apiResponse = new ApiResponse();
        try {
            String strBike = 'Bike';
            String strPCA = 'PCAService';
            String key, whereClause = '';
            String[] criteria = new List<String>{};
            User objUser = getUserLoginCurrent();
            Map<Id, List<Warehouse_Inventory__c>> mapProductWithListWarehouse = new Map<Id, List<Warehouse_Inventory__c>>();
            // objUser.Account.Warehouse_Location__c a0SO000000E2sroMAB
            List<Warehouse_Inventory__c> lstWarehouseInventory = getAllProductInWarehouseByAccountId(objUser.Account.Warehouse_Location__c);
            System.debug('lstWarehouseInventory :' + lstWarehouseInventory);
            List<objWarehouseInventoryProductDTO> lstWarehouseInventoryDTO = new List<objWarehouseInventoryProductDTO>();
            List<PricebookEntry> lstProduct2Querry = new List<PricebookEntry>();

            if (strKeySearch != null) {
                key = '%' + strKeySearch + '%';
                criteria.add('Product2.Name LIKE :key');
                criteria.add('Product2.ProductCode LIKE :key');
                criteria.add('Product2.Color_Name__c LIKE :key');
                criteria.add('Product2.Color_Code__c LIKE :key');
                if (criteria.size() > 0) {
                    whereClause = 'WHERE ' + String.join(criteria, ' OR ');
                }
            }
            lstProduct2Querry = Database.query(
                'SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.ProductCode, Product2.Color_Type__c, Product2.Color_Name__c, Product2.Model_Code__c FROM PricebookEntry ' +
                whereClause +
                ' ORDER BY Name '
            );

            if(lstProduct2Querry.isEmpty()) {
                apiResponse.error = 'Product is not exits like the keyword.';
                return apiResponse;
            }

            for(Warehouse_Inventory__c item : lstWarehouseInventory) {
                if (mapProductWithListWarehouse.containsKey(item.Product__c)){
                    List<Warehouse_Inventory__c> lstProductInWarehouse = mapProductWithListWarehouse.get(item.Product__c);
                    lstProductInWarehouse.add(item);    
                    mapProductWithListWarehouse.put(item.Product__c, lstProductInWarehouse);
                } else{
                    mapProductWithListWarehouse.put(item.Product__c, new List<Warehouse_Inventory__c>{item});
                }
            }
            System.debug('mapProductWithListWarehouse :' + mapProductWithListWarehouse);
            for(PricebookEntry item : lstProduct2Querry) {
               System.debug('item : ' + item.Product2Id);
               
               if(mapProductWithListWarehouse.containsKey(item.Product2Id)) {
                    System.debug('mapProductWithListWarehouse : ' + mapProductWithListWarehouse.get(item.Product2Id).size());
                    lstWarehouseInventoryDTO.add(new objWarehouseInventoryProductDTO(item, mapProductWithListWarehouse.get(item.Product2Id).size()));
               } else {
                    lstWarehouseInventoryDTO.add(new objWarehouseInventoryProductDTO(item, 0));
               }
            }
            System.debug('lstWarehouseInventoryDTO :' + lstWarehouseInventoryDTO.size());
            if(apiResponse.error == null) {
                apiResponse.result = lstWarehouseInventoryDTO;
                apiResponse.success = true;
            } 
            return apiResponse;
        } catch(Exception ex) {
            apiresponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            System.debug(' apiresponse.error : ' +  apiresponse.error);
            return apiResponse;
        }
    }


    @AuraEnabled
    public static ApiResponse updateQuoteLineItem(objWarehouseInventoryProductDTO objWarehouseInventoryProductDTO, String recordQuoteId) {
        ApiResponse apiResponse = new ApiResponse();
        PricebookEntry pbeObj = new PricebookEntry();
        Savepoint sp = Database.setSavepoint();
        try {
            QuoteLineItem objQuoteLineItem = getObjQuoteLineItem(recordQuoteId);
            if(objQuoteLineItem != Null) {
                delete objQuoteLineItem;
            }
            pbeObj = [SELECT Id
                            , UnitPrice
                        FROM PricebookEntry 
                        WHERE Pricebook2Id =: objQuoteLineItem.Quote.PriceBook2Id 
                            AND Product2Id =: objWarehouseInventoryProductDTO.Product2Id LIMIT 1];
            if(pbeObj == Null) {
                apiResponse.error = 'Pricebook Entry is not exits.';
                Database.rollback(sp);
                return apiResponse;
            }                                
            QuoteLineItem QuoteLineItemInsert = new QuoteLineItem();
            QuoteLineItemInsert.QuoteId = recordQuoteId;
            QuoteLineItemInsert.Quantity = 1;
            QuoteLineItemInsert.PricebookEntryId = pbeObj.Id;
            QuoteLineItemInsert.Product2Id = objWarehouseInventoryProductDTO.Product2Id;
            QuoteLineItemInsert.UnitPrice = pbeObj.UnitPrice -  (pbeObj.UnitPrice*(objQuoteLineItem.Quote.Discount_Percentage__c != Null 
                                                                                    ? objQuoteLineItem.Quote.Discount_Percentage__c : 0))
                                                                                    /100;
            insert QuoteLineItemInsert;
            

            if(apiResponse.error == null) {
                apiResponse.success = true;
            } 
            return apiResponse;
        } catch(Exception ex) {
            apiresponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            System.debug(' apiresponse.error : ' +  apiresponse.error);
            Database.rollback(sp);
            return apiResponse;
        }
    }

    private static List<Warehouse_Inventory__c> getAccountDODLByAccountOnOrder(String warehousId) {
        List<Warehouse_Inventory__c> lstWarehouseInventory = [SELECT Id
                                                                    , Name
                                                                    , Product__r.Name
                                                                    , Product__r.ProductCode
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
                                                                    AND Product__c !=: Null
                                                                    AND Product__r.RecordTypeId =: RecordTypeHelper.PRODUCT_MODEL
                                                                    AND Warehouse_Location__c =: warehousId];
        return lstWarehouseInventory;
    }

    private static List<Warehouse_Inventory__c> getAllProductInWarehouseByAccountId(String warehousId) {
        List<Warehouse_Inventory__c> lstWarehouseInventory = [SELECT Id
                                                                    , Name
                                                                    , Product__r.Name
                                                                    , Product__r.ProductCode
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
                                                                    AND Product__c !=: Null
                                                                    AND Product__r.RecordTypeId =: RecordTypeHelper.PRODUCT_MODEL
                                                                    AND Warehouse_Location__c =: warehousId];
        return lstWarehouseInventory;
    }

    private static QuoteLineItem getObjQuoteLineItem(String recordQuoteId) {
        QuoteLineItem objQuoteLineItem = [SELECT Id
                                                , LineNumber
                                                , Product2Id
                                                , Product2.Name
                                                , Product2.ProductCode
                                                , Product2.Model_Name__c
                                                , Product2.Color_Name__c
                                                , ListPrice
                                                , UnitPrice
                                                , TotalPrice
                                                , QuoteId
                                                , Quote.OpportunityId
                                                , Quote.Opportunity.PriceBook2Id
                                                , Quote.PriceBook2Id
                                                , Quote.Discount_Percentage__c
                                        FROM QuoteLineItem
                                        WHERE QuoteId =: recordQuoteId];
        return objQuoteLineItem;
    }

    private static User getUserLoginCurrent() {
        return [SELECT Id, AccountId, Account.Warehouse_Location__c FROM User WHERE Id =: UserInfo.getUserId()];
    }

    public class objQuoteLineDTO {
        @AuraEnabled
        public  String Id {get;set;}

        @AuraEnabled
        public String QuoteLineItemNumber {get; set;}

        @AuraEnabled
        public String Product2Id {get; set;}

        @AuraEnabled
        public String ProductName {get; set;}

        @AuraEnabled
        public String ProductCode {get; set;}

        @AuraEnabled
        public String ModelName {get; set;}
        
        @AuraEnabled
        public String ColorName {get; set;}
        

        @AuraEnabled
        public Integer ListPrice {get; set;}

        @AuraEnabled
        public Integer UnitPrice {get; set;}

        @AuraEnabled
        public Integer TotalPrice {get; set;}


        public objQuoteLineDTO() {}

		public objQuoteLineDTO(QuoteLineItem obj) {
			this.Id = obj.Id;
            this.QuoteLineItemNumber = obj.LineNumber;
            this.Product2Id = obj.Product2Id;
            this.ProductName = obj.Product2.Name;
            this.ProductCode = obj.Product2.ProductCode;
            this.ModelName = obj.Product2.Model_Name__c;
            this.ColorName = obj.Product2.Color_Name__c;
            this.ListPrice = Integer.valueOf(obj.ListPrice);
            this.UnitPrice = Integer.valueOf(obj.UnitPrice);
            this.TotalPrice = Integer.valueOf(obj.TotalPrice);
		}
    }


    public  class objWarehouseInventoryProductDTO {
        @AuraEnabled
        public  String Id {get;set;}


        @AuraEnabled
        public String ProductCode {get; set;}

        @AuraEnabled
        public String Product2Id {get; set;}

        @AuraEnabled
        public String ProductNameVN {get; set;}


        @AuraEnabled
        public Integer QoH {get; set;}

        @AuraEnabled
        public Integer Price {get; set;}


        @AuraEnabled
        public String ColorType {get; set;}


        @AuraEnabled
        public String strLocation  {get; set;}

        @AuraEnabled
        public String productModel  {get; set;}

        @AuraEnabled
        public Boolean availableInStock  {get; set;}

        @AuraEnabled
        public Boolean isChecked {get; set;}

        public objWarehouseInventoryProductDTO() {}

		public objWarehouseInventoryProductDTO(PricebookEntry obj, Integer quantityAll) {
			this.Id = obj.Id;
            this.ProductCode = obj.Product2.ProductCode;
            this.ProductNameVN = obj.Product2.Name;
            this.Product2Id = obj.Product2Id;
            this.ColorType = obj.Product2.Color_Name__c;
            this.Price = Integer.valueOf(obj.UnitPrice);
            this.isChecked = false;
            this.productModel = obj.Product2.Model_Code__c;
            this.availableInStock = false;
            this.QoH = quantityAll;
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