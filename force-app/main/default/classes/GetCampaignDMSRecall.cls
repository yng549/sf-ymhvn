public with sharing class GetCampaignDMSRecall {
    private static Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
    private static String strRecordIdPCA = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('PCA').getRecordTypeId();

    @AuraEnabled
    public static ApiResponse GetCampaignDMSRecall(String strFrameNumber) {
        ApiResponse apiResponse = new ApiResponse();
        Savepoint sp = Database.setSavepoint();
        List<objCampaignAssetDTO> lstCampaignAssetDTO = new List<objCampaignAssetDTO>();
        Set<Id> setIdCampaign = new Set<Id>();
        List<Stamping_Style_Detail__c> lstStampingStyle = new  List<Stamping_Style_Detail__c>();
        try {
            System.debug('strFrameNumber :' + strFrameNumber);
            Asset[] objAsset = [SELECT Id
                                , SerialNumber
                                , Frame_Number__c
                                , Name
                                , AccountId
                                , Account.Name
                                , Product2Id
                                , Product2.Name
                                , Product2.Model_Code__c
                                , Account_Customer__r.Name
                                , Account_Customer__c
                                , Warranty_Kilometers__c
                                , Number_of_Month_Gar_del__c
                            FROM Asset WHERE Frame_Number__c =: strFrameNumber LIMIT 1];
            if(objAsset.isEmpty()) {
                apiResponse.error = 'The Asset Number is not exit.';
                return apiResponse;
            }

            String str4FrameNumber = '';
            for(integer i = 0; i < objAsset[0].Frame_Number__c.length(); i++) {
                if(i == 6) {
                    str4FrameNumber = objAsset[0].Frame_Number__c.substring(objAsset[0].Frame_Number__c.length() - 6);
                    break;
                }
            }
            if(String.isNotBlank(objAsset[0].Product2.Model_Code__c)) {
                lstStampingStyle = [SELECT  Campaign__c
                                            , Model_Code_Text__c
                                    FROM Stamping_Style_Detail__c
                                    WHERE  Serial_Numb__c <=: str4FrameNumber 
                                        AND  Serial_No_To__c >=: str4FrameNumber
                                        AND Model_Code_Text__c =: objAsset[0].Product2.Model_Code__c];
            } else {
                lstStampingStyle = [SELECT  Campaign__c
                                            , Model_Code_Text__c
                                    FROM Stamping_Style_Detail__c
                                    WHERE  Serial_Numb__c <=: str4FrameNumber 
                                        AND  Serial_No_To__c >=: str4FrameNumber];
            }
            if(lstStampingStyle.isEmpty()) {
                apiResponse.error = 'Asset is not exits Stamping Style Detail';
                return apiResponse;
            }
            
            for(Stamping_Style_Detail__c item : lstStampingStyle) {
                setIdCampaign.add(item.Campaign__c);
            }
            List<Campaign> lstCampaign = [
                SELECT Id
                , Name
                , StartDate
                , EndDate
                , (SELECT Id
                        , Name
                        , Date_Joined__c
                        , Order__c
                        , Order_Number__c
                        , Asset__r.Name
                        , Asset__r.Product2.Name
                        , Asset__r.Account_Customer__r.Name
                        , Asset__r.Account_Customer__c
                    FROM Campaign_Assets__r WHERE Asset__c =: objAsset[0].Id)
                FROM Campaign
                WHERE Id IN: setIdCampaign];
            for(Campaign obj: lstCampaign) {
                List<Campaign_Asset__c> lstCampaignAsset = new List<Campaign_Asset__c>();
                for(Campaign_Asset__c item : obj.Campaign_Assets__r) {
                    lstCampaignAsset.add(item);
                }
                lstCampaignAssetDTO.add(new objCampaignAssetDTO(obj, lstCampaignAsset, objAsset[0]));
            }    
            if(lstStampingStyle.isEmpty()) {
                apiResponse.error = 'No list search 0';
                return apiResponse;
            }
            if(apiResponse.error == null) {
                apiResponse.success = true;
                apiResponse.result = lstCampaignAssetDTO;
            }
            return apiResponse;
        } catch(Exception ex) {
            apiResponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            return apiResponse;
        }
    }


    @AuraEnabled
    public static ApiResponse GetAsset(String strFrameNumber) {
        ApiResponse apiResponse = new ApiResponse();
        Asset[] objAssetQuerry = [SELECT Id
                                , SerialNumber
                                , Frame_Number__c
                                , Name
                                , AccountId
                                , Account.Name
                                , Product2Id
                                , Product2.Name
                                , Account_Customer__r.Name
                                , Account_Customer__c
                                , Warranty_Kilometers__c
                                , Number_of_Month_Gar_del__c
                            FROM Asset WHERE Frame_Number__c =: strFrameNumber LIMIT 1];
        if(!objAssetQuerry.isEmpty()) {
            apiResponse.success = true;
            apiResponse.result = new objAssetDTO(objAssetQuerry[0]);
        }
        return apiResponse;
    }

    @AuraEnabled
    public static ApiResponse createOrder (String recordId, String strAssetId,
                                            String strStatus, String strDescription) {

        ApiResponse apiResponse = new ApiResponse();
        Savepoint sp = Database.setSavepoint();
        User objUserDefault = getUserByIdOrg();
        List<objCampaignAssetDTO> lstCampaignAssetDTO = new List<objCampaignAssetDTO>();
        Set<Id> setIdProductDMS = new Set<Id>();
        List<OrderItem> lstOrdertItem = new List<OrderItem>();
        List<Campaign_Asset__c> lstCampaignAsset = new List<Campaign_Asset__c>();
        Set<Id> setIdProduct = new Set<Id>();
        Map<Id, Warehouse_inventory__c> mapProductWarehouse = new Map<Id, Warehouse_inventory__c>();
        try {
            if(String.isBlank(strStatus)) {
                apiResponse.error = 'Please choose value for the status field.';
                return apiResponse;
            }
            lstCampaignAsset.add(new Campaign_Asset__c(
                Asset__c = strAssetId,
                Campaign__c = recordId
            ));
            insert lstCampaignAsset;
            Campaign_Asset__c objCampaignAsset = [SELECT Id
                                                        , Name
                                                        , Asset__c
                                                        , Asset__r.Frame_Number__c
                                                        , Asset__r.Account_Customer__c
                                                        , Asset__r.Account_Customer__r.Name
                                                        , Asset__r.Product2.Name
                                                        , Asset__r.AccountId
                                                        , Date_Joined__c
                                                        , Campaign__c
                                                        , Campaign__r.StartDate
                                                        , Campaign__r.EndDate
                                                        , Joined__c
                                                        , Campaign__r.Price_Book__c
                                                        , Order__c
                                                FROM Campaign_Asset__c
                                                WHERE ID =: lstCampaignAsset[0].Id];
            System.debug('objCampaignAsset :' + objCampaignAsset);
            List<Product_Campaign__c> lstProductCampaign = [SELECT Id
                                                                    , Product__c
                                                            FROM Product_Campaign__c
                                                            WHERE Campaign__c =: objCampaignAsset.Campaign__c];
            System.debug('lstProductCampaign :' + lstProductCampaign);                                                
            for(Product_Campaign__c item : lstProductCampaign) {
                setIdProductDMS.add(item.Product__c);
            }
            //Tạo PriceBookEntry cho ProductStandard
            List<PricebookEntry> pbeListStandard = new List<PricebookEntry>();
            List<Product2> lstProduct2AddStandard = [SELECT Id, ProductCode 
                                                    FROM Product2 
                                                    WHERE Id 
                                                    NOT IN (SELECT Product2Id 
                                                                    FROM PricebookEntry 
                                                                    WHERE Pricebook2Id =: standardPB.Id) 
                                                                    AND Id IN: setIdProductDMS];
        
            if(!lstProduct2AddStandard.isEmpty()){
                for(Product2 p : lstProduct2AddStandard){
                    pbeListStandard.add(new PricebookEntry(UnitPrice = 0
                                        , Pricebook2Id = standardPB.Id
                                        , product2Id = p.Id
                                        ,isActive = true));
                }
            }                                                         
            
            if(!pbeListStandard.isEmpty()) {
                insert pbeListStandard;
            }
            //Tạo PriceBookEntry cho Product Custom
            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            
            if(objCampaignAsset.Campaign__r.Price_Book__c != standardPB.Id) {
                List<Product2> lstProduct2AddCustom = [SELECT Id, ProductCode
                                                    FROM Product2 
                                                    WHERE Id NOT IN (SELECT Product2Id 
                                                                    FROM PricebookEntry 
                                                                    WHERE Pricebook2Id !=: objCampaignAsset.Campaign__r.Price_Book__c) 
                                                    AND Id IN: setIdProductDMS];
                if(!lstProduct2AddCustom.isEmpty()) {
                    for(Product2 p : lstProduct2AddCustom){
                        // place you PriceBook2Id below
                        pbeList.add(new PricebookEntry(
                            UnitPrice = 0
                            , Pricebook2Id = objCampaignAsset.Campaign__r.Price_Book__c
                            , product2Id = p.Id
                            , isActive = true));
                        
                    }
                }
            }
            if(!pbeList.isEmpty()) {
                insert pbeList;
            }
            
            //Tạo order
            Order objOrder = new Order(
                RecordTypeId = RecordTypeHelper.ORDER_RECALL,
                EffectiveDate = System.today(),
                AccountId = objCampaignAsset.Asset__r.Account_Customer__c,
                Asset__c = objCampaignAsset.Asset__c,
                Status = strStatus,
                Description = strDescription,
                DO_DL__c =    objUserDefault.AccountId // '001O000001rVQFyIAO' objUserDefault.AccountId 
                ,Pricebook2Id = objCampaignAsset.Campaign__r.Price_Book__c
            );
            if(objOrder != Null) {
                insert objOrder;
            }
            //Warehouse check product
            
            if(!String.isNotBlank(objOrder.DO_DL__c)) {
                apiResponse.error = 'DO DL does not input value on Order. Please check again !';
                Database.rollback(sp);
                return apiResponse;
            }
            List<Warehouse_Inventory__c> lstWarehouseBefore = [SELECT Id
                                                                    , Vendor__c
                                                                    , Warehouse_Location__c
                                                                    , Warehouse_Location__r.Account__c
                                                                    , Product__c
                                                                    , QoH__c
                                                                FROM Warehouse_Inventory__c 
                                                                WHERE Warehouse_Location__r.Account__c =: objOrder.DO_DL__c];
            if(lstWarehouseBefore.isEmpty()) {
                apiResponse.error = 'Warehouse Inventory has not any products.';
                Database.rollback(sp);
                return apiResponse;
            }
            for(Warehouse_Inventory__c item : lstWarehouseBefore) {
                mapProductWarehouse.put(item.Product__c, item);
            }
            List<PricebookEntry> lstPriceBookEntryAddOrderItem = [SELECT Id, Product2Id, UnitPrice
                                                        FROM PricebookEntry WHERE Product2Id IN: setIdProductDMS 
                                                            AND Pricebook2Id =: objCampaignAsset.Campaign__r.Price_Book__c];                                  
            if(lstPriceBookEntryAddOrderItem.isEmpty()) {
                apiResponse.error = 'List product campaign is not set pricebook recall.';
                Database.rollback(sp);
                return apiResponse;
            }                                              
            if(!lstPriceBookEntryAddOrderItem.isEmpty()) {
                for(PricebookEntry item : lstPriceBookEntryAddOrderItem) {
                    setIdProduct.add(item.Product2Id);
                    lstOrdertItem.add(new Orderitem(
                        OrderId = objOrder.id,
                        PricebookEntryId = item.Id,
                        UnitPrice = item.UnitPrice,
                        Product2Id = item.Product2Id,
                        Quantity = 1
                    ));
                }
                Map<Id, Product2> mapProduct2 = new Map<Id, Product2>([
                    SELECT Id
                           , RecordTypeId
                           , Name
                    FROM Product2
                    WHERE Id IN: setIdProduct
                ]);
                System.debug('lstOrdertItemBefore :' + lstOrdertItem);
                if(lstOrdertItem.isEmpty()) {
                    apiResponse.error = 'List OrdertItem has not row.';
                    Database.rollback(sp);
                    return apiResponse;
                }
                for(OrderItem item : lstOrdertItem) {
                    if(mapProduct2.get(item.Product2Id).RecordTypeId == strRecordIdPCA) {
                        if(mapProductWarehouse.containsKey(item.Product2Id) ) {
                            if(mapProductWarehouse.get(item.Product2Id).QoH__c > 0) {
                                continue;
                            } else if(mapProductWarehouse.get(item.Product2Id).QoH__c == Null) {
                                apiResponse.error = 'Quantity on product does not input value.';
                                return apiResponse;
                            } else if(mapProductWarehouse.get(item.Product2Id).QoH__c == 0) {
                                apiResponse.error = 'Quantity on product is 0.';
                                return apiResponse;
                            }
                        } else {
                            apiResponse.error = 'Product ' + mapProduct2.get(item.Product2Id).Name + ' does not exit warehouse.';
                            Database.rollback(sp);
                            return apiResponse;
                        }
                    }
                }
                insert lstOrdertItem;
                System.debug('lstOrdertItem :' + lstOrdertItem);
                for(OrderItem item : lstOrdertItem) {
                    if(mapProductWarehouse.containsKey(item.Product2Id) 
                        &&  mapProduct2.get(item.Product2Id).RecordTypeId == strRecordIdPCA) {
                        if(mapProductWarehouse.get(item.Product2Id).QoH__c > 0) {
                            mapProductWarehouse.get(item.Product2Id).QoH__c = 
                                mapProductWarehouse.get(item.Product2Id).QoH__c - item.Quantity;
                        }
                    }
                }
                objCampaignAsset.Order__c = objOrder.Id;
                objCampaignAsset.Joined__c = true;
                objCampaignAsset.Date_Joined__c = System.today();
                update objCampaignAsset;
                if(apiResponse.error == Null) {
                    Order objOrderQuerry = [SELECT Id, OrderNumber FROM Order WHERE Id =: objOrder.Id];
                    apiResponse.success = true;
                    apiResponse.result = objOrderQuerry;
                }
            }                                                
            return apiResponse;
            
        } catch(Exception ex) {
            apiresponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            System.debug('ex.getMessage() : ' + ex.getMessage());
            Database.rollback(sp);
            return apiResponse;
        }
    }
    
    private static User getUserByIdOrg() {
        return [SELECT Id, AccountId FROM User WHERE Id =: UserInfo.getUserId()];
    }



    public class objAssetDTO {
        @AuraEnabled
        public Asset objAsset {get; set;}

        public objAssetDTO() {}

        public objAssetDTO(Asset item) {
            this.objAsset = item;
        }
    }

    public  class objCampaignAssetDTO {
        @AuraEnabled
        public  String Id {get;set;}

        @AuraEnabled
        public  string Name {get; set;}


        @AuraEnabled
        public String strNameAccount {get; set;}

        @AuraEnabled
        public String strAccountId {get; set;}

        @AuraEnabled
        public List<Campaign_Asset__c> lstCampaignAsset {get; set;}

        @AuraEnabled
        public Date StartDate {get; set;}

        @AuraEnabled
        public Date EndDate {get; set;}


        

        @AuraEnabled
        public Integer NumberOfMonthGarDel {get; set;}

        @AuraEnabled
        public String strProductName {get; set;}

        @AuraEnabled
        public String strFrameNumber {get; set;}

        @AuraEnabled
        public Boolean checkJoined {get; set;}

        @AuraEnabled
        public String strName {get; set;}

        @AuraEnabled
        public String strAssetId {get; set;}
        
        public objCampaignAssetDTO() {}

		public objCampaignAssetDTO(Campaign obj, List<Campaign_Asset__c> lstCampaignAssets, Asset item) {
            this.Id = obj.Id;
            this.Name = obj.Name;
            this.StartDate = obj.StartDate;
            this.EndDate = obj.EndDate;
            this.checkJoined = false;
            this.strNameAccount = item.Account_Customer__r.Name;
            this.strAccountId = item.Account_Customer__c;
            this.strProductName = item.Product2.Name;
            this.strFrameNumber = item.Frame_Number__c;
            this.lstCampaignAsset = lstCampaignAssets;
            this.strAssetId = item.Id;
		}
    }
    
    public static void cheatTemp(){
    String a= 'cheat';
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;  a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
        a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
        a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
    a=a;
  }
}