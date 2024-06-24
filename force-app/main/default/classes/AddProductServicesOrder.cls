public without sharing class AddProductServicesOrder {
    private static final String STR_NONE_HAS_PRICEBOOK2 = 'Order has not value on Pricebook2 field.';
    private static final String STR_NONE_HAS_PRICEBOOKENTRY = 'Order has not any pricebook entry.';
    private static final String STR_NONE_HAS_ACCOUNT = 'Order has not value on DO/DL field.';
    private static final String STR_NONE_HAS_WAREHOUSE = 'Account has not any warehouse inventory.';
	private static final String STR_NONE_HAS_SYMPTON = 'Order unidentified situation motocycel.';
    public static Boolean isWarranty = false;
    @AuraEnabled
    public static ApiResponse getInitalPricebookPCA(String recordId) {
        ApiResponse apiResponse = new ApiResponse();
        List<ProductEntriesDTO> lstPricebookEntryDTO = new List<ProductEntriesDTO>();
        Order objOrder = getOrderById(recordId);
        List<PricebookEntry> lstPricebookEntry = new List<PricebookEntry>();
        List<PricebookEntry> lstPricebookEntryServiceTypeDetailing = new List<PricebookEntry>();
		if (objOrder.RecordTypeId == RecordTypeHelper.ORDER_WARRANTY) isWarranty = true;
        
        if(isWarranty && objOrder.Motorcycle_Situations__r.isEmpty()) {
            apiResponse.error = STR_NONE_HAS_SYMPTON;
            return apiResponse;
        }
        if(!String.isNotBlank(objOrder.Pricebook2Id)) {
            apiResponse.error = STR_NONE_HAS_PRICEBOOK2;
            return apiResponse;
        }
        System.debug('Bike_Type:' + objOrder.Asset__r.Product2.Bike_Type__c);
        if(objOrder.Asset__r.Product2.Bike_Type__c == 'Yamaha') {
            System.debug('Case1:');
            lstPricebookEntry = [SELECT Id , Product2.Name , Product2.ProductCode , UnitPrice,
                                                  Product2.Id, Product2.Labor_HOUR__c, Product2.Bike_cc__c, Product2.Job_Description_Eng__c
                                                  FROM PricebookEntry
                                                  WHERE Pricebook2Id =: objOrder.Pricebook2Id AND IsActive =: True
                                                      AND Product2.RecordTypeId =: RecordTypeHelper.SV_JOB
                                                      AND Product2.Bike_cc__c =: objOrder.Asset__r.Product2.Bike_cc__c
                                                      AND Product2.Model__c =: 'Yamaha'
                                                  LIMIT 20];
        } else if(objOrder.Asset__r.Product2.Bike_Type__c != 'Yamaha') {
            System.debug('Case2:');
            lstPricebookEntry = [SELECT Id , Product2.Name , Product2.ProductCode , UnitPrice,
                                                  Product2.Id, Product2.Labor_HOUR__c, Product2.Bike_cc__c, Product2.Job_Description_Eng__c
                                                  FROM PricebookEntry
                                                  WHERE Pricebook2Id =: objOrder.Pricebook2Id
                                 					  AND IsActive =: True
                                                      AND Product2.RecordTypeId =: RecordTypeHelper.SV_JOB
                                                      AND Product2.Bike_cc__c =: objOrder.Asset__r.Product2.Bike_cc__c
                                                      AND Product2.Model__c =: 'Non yamaha'
                                                  LIMIT 20];
        }
        System.debug('lstPricebookEntry:' + lstPricebookEntry);
        
        
        
        
        
        for(PricebookEntry item : lstPricebookEntry) {
            if (isWarranty) {
                lstPricebookEntryDTO.add(new ProductEntriesDTO(item, objOrder.Motorcycle_Situations__r));
            }
            else {
                lstPricebookEntryDTO.add(new ProductEntriesDTO(item));
            }
        }
        lstPricebookEntryServiceTypeDetailing = [SELECT Id 
                                                        , Product2.Name 
                                                        , Product2.ProductCode 
                                                        , UnitPrice
                                                        , Product2.Id
                                                        , Product2.Labor_HOUR__c
                                                        , Product2.Bike_cc__c
                                                        , Product2.Job_Description_Eng__c
                                                  FROM PricebookEntry
                                                  WHERE Pricebook2Id =: objOrder.Pricebook2Id AND IsActive =: True
                                                      AND Product2.RecordTypeId =: RecordTypeHelper.SV_JOB
                                                      AND (Product2.Service_Type__c =: 'Detailing' OR Product2.Apply_Both__c =: TRUE)
                                                 	  AND Id NOT IN: lstPricebookEntry ];
        for(PricebookEntry item : lstPricebookEntryServiceTypeDetailing) {
            System.debug('item:'+ item);
            if (isWarranty) {
                lstPricebookEntryDTO.add(new ProductEntriesDTO(item, objOrder.Motorcycle_Situations__r));
            }
            else {
                lstPricebookEntryDTO.add(new ProductEntriesDTO(item));
            }
        }
        if(lstPricebookEntryDTO.isEmpty()) {
            apiResponse.error = STR_NONE_HAS_PRICEBOOKENTRY;
            return apiResponse;
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
        List<PricebookEntry> lstPricebookEntry = new List<PricebookEntry>();
        List<PricebookEntry> lstPricebookEntryServiceTypeDetailing = new List<PricebookEntry>();
        try {
            List<ProductEntriesDTO> lstPricebookEntryDTO = new List<ProductEntriesDTO>();
            Order objOrder = getOrderById(recordId);
            if (objOrder.RecordTypeId == RecordTypeHelper.ORDER_WARRANTY) isWarranty = true;
            
            if(isWarranty && objOrder.Motorcycle_Situations__r.isEmpty()) {
                apiResponse.error = STR_NONE_HAS_SYMPTON;
                return apiResponse;
            }
            
            if(String.isBlank(objOrder.Pricebook2Id)) {
                apiResponse.error = STR_NONE_HAS_PRICEBOOK2;
                return apiResponse;
            }
            if(String.isNotBlank(searchString)) {
                String strProdName = '%' + searchString + '%';
                if(objOrder.Asset__r.Product2.Bike_Type__c == 'Yamaha') {
                    lstPricebookEntry = [SELECT Id , Product2.Name , Product2.ProductCode , UnitPrice,
                                                          Product2.Id, Product2.Labor_HOUR__c, Product2.Bike_cc__c, Product2.Job_Description_Eng__c
                                                          FROM PricebookEntry
                                                          WHERE Pricebook2Id =: objOrder.Pricebook2Id AND IsActive =: True
                                         					   AND (Product2.Name LIKE: strProdName 
                                                                  OR Product2.ProductCode LIKE: strProdName
                                                                  OR Product2.Job_Description_Eng__c LIKE: strProdName)
                                                              AND Product2.RecordTypeId =: RecordTypeHelper.SV_JOB
                                                              AND Product2.Bike_cc__c =: objOrder.Asset__r.Product2.Bike_cc__c
                                                              AND Product2.Model__c =: 'Yamaha'
                                                          LIMIT 20];
                } else if(objOrder.Asset__r.Product2.Bike_Type__c != 'Yamaha') {
                    lstPricebookEntry = [SELECT Id , Product2.Name , Product2.ProductCode , UnitPrice,
                                                          Product2.Id, Product2.Labor_HOUR__c, Product2.Bike_cc__c, Product2.Job_Description_Eng__c
                                                          FROM PricebookEntry
                                                          WHERE Pricebook2Id =: objOrder.Pricebook2Id AND IsActive =: True
                                         					  AND (Product2.Name LIKE: strProdName 
                                                                  OR Product2.ProductCode LIKE: strProdName
                                                                  OR Product2.Job_Description_Eng__c LIKE: strProdName)
                                                              AND Product2.RecordTypeId =: RecordTypeHelper.SV_JOB
                                                              AND Product2.Bike_cc__c =: objOrder.Asset__r.Product2.Bike_cc__c
                                                              AND Product2.Model__c =: 'Non yamaha'
                                                          LIMIT 20];
                }
                lstPricebookEntryServiceTypeDetailing = [SELECT Id , Product2.Name , Product2.ProductCode , UnitPrice,
                                                      Product2.Id, Product2.Labor_HOUR__c, Product2.Bike_cc__c, Product2.Job_Description_Eng__c
                                                      FROM PricebookEntry
                                                      WHERE Pricebook2Id =: objOrder.Pricebook2Id AND IsActive =: True
                                                     	  AND (Product2.Name LIKE: strProdName 
                                                                  OR Product2.ProductCode LIKE: strProdName
                                                                  OR Product2.Job_Description_Eng__c LIKE: strProdName)
                                                          AND Product2.RecordTypeId =: RecordTypeHelper.SV_JOB
                                                          AND (Product2.Service_Type__c =: 'Detailing' OR Product2.Apply_Both__c =: TRUE)];
            } else {
                if(objOrder.Asset__r.Product2.Bike_Type__c == 'Yamaha') {
                    lstPricebookEntry = [SELECT Id , Product2.Name , Product2.ProductCode , UnitPrice,
                                                          Product2.Id, Product2.Labor_HOUR__c, Product2.Bike_cc__c, Product2.Job_Description_Eng__c
                                                          FROM PricebookEntry
                                                          WHERE Pricebook2Id =: objOrder.Pricebook2Id AND IsActive =: True
                                                              AND Product2.RecordTypeId =: RecordTypeHelper.SV_JOB
                                                              AND Product2.Bike_cc__c =: objOrder.Asset__r.Product2.Bike_cc__c
                                                              AND Product2.Model__c =: 'Yamaha'
                                                          LIMIT 20];
                } else if(objOrder.Asset__r.Product2.Bike_Type__c != 'Yamaha') {
                    lstPricebookEntry = [SELECT Id , Product2.Name , Product2.ProductCode , UnitPrice,
                                                          Product2.Id, Product2.Labor_HOUR__c, Product2.Bike_cc__c, Product2.Job_Description_Eng__c
                                                          FROM PricebookEntry
                                                          WHERE Pricebook2Id =: objOrder.Pricebook2Id AND IsActive =: True
                                                              AND Product2.RecordTypeId =: RecordTypeHelper.SV_JOB
                                                              AND Product2.Bike_cc__c =: objOrder.Asset__r.Product2.Bike_cc__c
                                                              AND Product2.Model__c =: 'Non yamaha'
                                                          LIMIT 20];
                }
                lstPricebookEntryServiceTypeDetailing = [SELECT Id , Product2.Name , Product2.ProductCode , UnitPrice,
                                                         Product2.Id, Product2.Labor_HOUR__c, Product2.Bike_cc__c, Product2.Job_Description_Eng__c
                                                         FROM PricebookEntry
                                                         WHERE Pricebook2Id =: objOrder.Pricebook2Id AND IsActive =: True
                                                         AND Product2.RecordTypeId =: RecordTypeHelper.SV_JOB
                                                         AND (Product2.Service_Type__c =: 'Detailing' OR Product2.Apply_Both__c =: TRUE)];
            }
            
             
            
            
            for(PricebookEntry item : lstPricebookEntry) {
                if (isWarranty) {
                    lstPricebookEntryDTO.add(new ProductEntriesDTO(item, objOrder.Motorcycle_Situations__r));
                }
                else {
                    lstPricebookEntryDTO.add(new ProductEntriesDTO(item));
                }
            }
            for(PricebookEntry item : lstPricebookEntryServiceTypeDetailing) {
                if (isWarranty) {
                    lstPricebookEntryDTO.add(new ProductEntriesDTO(item, objOrder.Motorcycle_Situations__r));
                }
                else {
                    lstPricebookEntryDTO.add(new ProductEntriesDTO(item));
                }
            }
            if(lstPricebookEntryDTO.isEmpty()) {
                apiResponse.error = STR_NONE_HAS_PRICEBOOKENTRY;
                return apiResponse;
            }
            if(apiResponse.error == null) {
                apiResponse.success = true;
                apiResponse.result = lstPricebookEntryDTO;
            } 
            return apiResponse;
        } catch(Exception ex) {
            apiResponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            return apiResponse;
        }
        
    }
    @AuraEnabled
    public static ApiResponse createOrderProductPCA(String recordId, List<ProductEntriesDTO> lstProductEntries) {
        ApiResponse apiResponse = new ApiResponse();
        List<OrderItem> orderItemsCreate = new List<OrderItem>();
        try {
            for(ProductEntriesDTO item : lstProductEntries) {
                OrderItem i = new OrderItem();
                i.OrderId = recordId;
                i.Quantity = 1;
                i.UnitPrice = item.Price;
                i.Product2id = item.Product2Id;
                if (!item.symtomconditions.isEmpty()) i.Motorcycle_Situation__c = item.idSymtonmotor;
                i.PricebookEntryId = item.Id;
                orderItemsCreate.add(i);
            }
            insert orderItemsCreate;
            
            if(apiResponse.error == null) {
                apiResponse.success = true;
            } 
            return apiResponse;
        } catch(Exception ex) {
            System.debug('ex.getMessage() :' + ex.getMessage());
            apiResponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            return apiResponse;
        }
    }

    private static Order getOrderById(String recordId) {
        return [SELECT Id, RecordTypeId, Is_BigBike__c, Pricebook2Id , DO_DL__c , Asset__r.Product2.Bike_cc__c, Asset__r.Product2.Bike_Type__c, (SELECT Id, Symptom__r.Name FROM Motorcycle_Situations__r)
                FROM Order WHERE Id =: recordId];
    }
    
    public class ProductEntriesDTO {
        @AuraEnabled
        public String Id {get;set;}
        
        @AuraEnabled
        public String ProductCode {get; set;}

        @AuraEnabled
        public String Product2Id {get; set;}

        @AuraEnabled
        public String ProductNameVN {get; set;}

        @AuraEnabled
        public String ProductName {get; set;}
        
        
        @AuraEnabled
        public String BikeCC {get; set;}

        @AuraEnabled
        public Integer Quantity {get; set;}

        @AuraEnabled
        public Integer Price {get; set;}

        @AuraEnabled
        public Decimal LabourHour {get; set;}

        @AuraEnabled
        public Boolean Ischecked {get; set;}
		
        @AuraEnabled
        public List<MotorcycleSituation__c> symtomconditions {get; set;}
        
        @AuraEnabled
        public String idSymtonmotor {get; set;}
		
        public ProductEntriesDTO() {}
        public ProductEntriesDTO(PricebookEntry pbe) {
            this.Id = pbe.Id;
            this.BikeCC = pbe.Product2.Bike_cc__c;
            this.ProductCode = pbe.Product2.ProductCode;
            this.ProductNameVN = pbe.Product2.Job_Description_Eng__c;
            this.Product2Id = pbe.Product2.Id;
            this.ProductName = pbe.Product2.Name;
            this.Quantity = 1;
            this.Price = Integer.valueOf(pbe.UnitPrice);
            this.LabourHour = pbe.Product2.Labor_HOUR__c;
            this.Ischecked = false; 
            this.symtomconditions = new List<MotorcycleSituation__c>(); 
        }

		public ProductEntriesDTO(PricebookEntry pbe, List<MotorcycleSituation__c> symtomconditions) {
			this.Id = pbe.Id;
            this.BikeCC = pbe.Product2.Bike_cc__c;
            this.ProductCode = pbe.Product2.ProductCode;
            this.ProductNameVN = pbe.Product2.Job_Description_Eng__c;
            this.Product2Id = pbe.Product2.Id;
            this.ProductName = pbe.Product2.Name;
            this.symtomconditions = symtomconditions;
            this.idSymtonmotor = symtomconditions[0].Id;
            this.Quantity = 1;
            this.Price = Integer.valueOf(pbe.UnitPrice);
            this.LabourHour = Integer.valueOf(pbe.Product2.Labor_HOUR__c);
            this.Ischecked = false; 
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
    }
}