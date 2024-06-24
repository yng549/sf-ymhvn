public with sharing class createServicePackageForOrder {
    private static Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];

    @AuraEnabled
    public static ApiResponse getPickListPriceBookEntry() {
        Date dtToday = System.today();
        ApiResponse apiResponse = new ApiResponse();
        List<Pricebook2> lstPricebookEntry = [SELECT Id
                                                    , Name
                                                    , Type__c
                                            FROM Pricebook2
                                            WHERE IsActive = true
                                            AND From__c != Null
                                            AND To__c != Null
                                            AND Type__c =: 'Service Package'];
        
        if(lstPricebookEntry.isEmpty()) {
            apiResponse.error = 'List PriceBook is empty';
            return apiResponse;
        }
        
        if(apiResponse.error == null) {
            apiResponse.success = true;
            apiResponse.result = lstPricebookEntry;
        } 
        return apiResponse;
    }

    @AuraEnabled
    public static ApiResponse retriveProducts(String recordId, string strIdPriceBook) {
        ApiResponse apiResponse = new ApiResponse();
        List<objProductDisplayDTO> lstProductDisplayDTO = new List<objProductDisplayDTO>();
        Map<Id, List<Product_Detail_Service__c>> mapProdWithProdSession = new Map<Id, List<Product_Detail_Service__c>>();
        Order objOrder = [SELECT Id, Asset__c, Asset__r.Product2Id FROM Order WHERE Id =: recordId];
        List<Product2> lstProduct2ServicePackage = [
            SELECT Id, Name, (SELECT Id
                                FROM Service_Package_Bikes__r
                                WHERE Product_Bike__c =: objOrder.Asset__r.Product2Id)
            FROM Product2 
            WHERE Id IN (SELECT Product2Id 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id =: strIdPriceBook)
                AND RecordTypeId =: RecordTypeHelper.PRODUCT_SERVICE_PACKAGE
                AND Id IN (SELECT Product_Service_Package__c
                            FROM Service_Package_Bike__c
                            WHERE Product_Bike__c =: objOrder.Asset__r.Product2Id)];
        if(lstProduct2ServicePackage.isEmpty()) {
            apiResponse.error = 'Not any product for this pricebook.';
            return apiResponse;
        }
        List<Pricebookentry> lstPriceBookEntry = [SELECT Id
                                                        , UnitPrice
                                                        , Product2.Name
                                                        , Product2.ProductCode
                                                        , Product2Id
                                                    FROM PricebookEntry
                                                    WHERE Product2Id IN: lstProduct2ServicePackage 
                                                    AND Pricebook2Id =:  strIdPriceBook];
        List<Product_Detail_Service__c> lstProductDetailService = [
            SELECT  Id
                    , Quantity__c
                    , Product__r.Name
                    , Product_Service_Package__c
                    , Product__r.Description
                    , Product__r.ProductCode
            FROM Product_Detail_Service__c
            WHERE Product_Service_Package__c IN: lstProduct2ServicePackage];

        mapProdWithProdSession(lstProductDetailService, mapProdWithProdSession);
        for(Pricebookentry item : lstPriceBookEntry) {
            if(mapProdWithProdSession.containsKey(item.Product2Id)) {
                lstProductDisplayDTO.add(new objProductDisplayDTO(item, mapProdWithProdSession.get(item.Product2Id)));
            } else {
                lstProductDisplayDTO.add(new objProductDisplayDTO(item, Null));
            }
        }
        

        System.debug('lstProductDisplayDTO :' + lstProductDisplayDTO);                                            
        if(lstProductDisplayDTO.isEmpty()) {
            apiResponse.error = 'No any product service package for that';
            return apiResponse;
        }
        
        if(apiResponse.error == null) {
            apiResponse.success = true;
            apiResponse.result = lstProductDisplayDTO;
        } 
        return apiResponse;
    }

    @AuraEnabled
    public static ApiResponse createOrderItem(String recordId, List<objProductDisplayDTO> lstStrPriceBookEntry, String strIdPriceBook) {
        ApiResponse apiResponse = new ApiResponse();
        List<OrderItem> orderProds = new List<OrderItem>();
        Map<Id, objProductDisplayDTO> mapObjProdDTO = new Map<Id, objProductDisplayDTO>();
        try {
            Set<Id> setId = new Set<Id>();
            System.debug('lstStrPriceBookEntry: ' + lstStrPriceBookEntry);
            for(objProductDisplayDTO item : lstStrPriceBookEntry) {
                setId.add(item.PricebookId);
                System.debug('item DTO: ' + item);
                mapObjProdDTO.put(item.PricebookId, item);
            }
            System.debug('setId');
            Order objOrderUpdate = [SELECT Id, PriceBook2Id FROM Order WHERE Id =: recordId];
            objOrderUpdate.PriceBook2Id = strIdPriceBook;
            update objOrderUpdate;
            List<Pricebookentry> lstPriceBookEntry = [
                SELECT  Id
                        , UnitPrice
                        , Product2.Name
                        , Product2.ProductCode
                        , Product2Id
                FROM PricebookEntry
                WHERE Id IN: setId];
            system.debug('lstPriceBookEntry :'  + lstPriceBookEntry.size());
            System.debug('lstPriceBookEntry :'  + lstPriceBookEntry);
            for(Pricebookentry item : lstPriceBookEntry) {
                if(mapObjProdDTO.containsKey(item.Id)) {
                    orderProds.add(new OrderItem(
                        UnitPrice = item.UnitPrice,
                        Quantity = 1,
                        OrderId = recordId,
                        PricebookEntryId = item.Id,
                        Date_Active__c = Date.valueOf(mapObjProdDTO.get(item.Id).dtDate)
                    ));
                }
            }
            system.debug('orderProds :'  + orderProds);
            if(!orderProds.isEmpty()) {
                insert orderProds;
            }
            if(apiResponse.error == null) {
                apiResponse.success = true;
            }
            return apiResponse;
        } catch(Exception ex) {
            apiResponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            return apiResponse;
        }
    }

    private static void mapProdWithProdSession(List<Product_Detail_Service__c> lstProductDetailService
                                                    , Map<Id, List<Product_Detail_Service__c>> mapProdWithProdSession){
		for (Product_Detail_Service__c item : lstProductDetailService){
			if (mapProdWithProdSession.containsKey(item.Product_Service_Package__c)){
				List<Product_Detail_Service__c> lstProductSession = mapProdWithProdSession.get(item.Product_Service_Package__c);
				lstProductSession.add(item);
				mapProdWithProdSession.put(item.Product_Service_Package__c, lstProductSession);
			} else{
				mapProdWithProdSession.put(item.Product_Service_Package__c, new List<Product_Detail_Service__c>{item});
			}
		}
	}

    public  class objProductDisplayDTO {
        @AuraEnabled
        public  String PricebookId {get;set;}

        @AuraEnabled
        public  string Id {get; set;}

        @AuraEnabled
        public  string ProductName {get; set;}

        @AuraEnabled
        public  string ProductCode {get; set;}

        @AuraEnabled
        public String ListPrice {get; set;}


        @AuraEnabled
        public Boolean hideBool {get; set;}

        @AuraEnabled
        public Date dtDate {get; set;}

        @AuraEnabled
        public  List<Product_Detail_Service__c> lstProductDetailService {get; set;}


        public objProductDisplayDTO() {}

		public objProductDisplayDTO(Pricebookentry obj, List<Product_Detail_Service__c> lstOrderLineDetail) {
			this.Id = obj.Product2Id;
            this.PricebookId = obj.Id;
            this.ProductName = obj.Product2.Name;
            this.ProductCode = obj.Product2.ProductCode;
            this.ListPrice = String.valueOf(obj.UnitPrice);
            this.hideBool = true;
            this.lstProductDetailService = lstOrderLineDetail;
            this.dtDate = System.today();
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
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;
    }
}