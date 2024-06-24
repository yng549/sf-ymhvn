@isTest
public class AddProductPartsOrderTest {
    private static Pricebook2 pbWarranty;
    static{
     	pbWarranty = new Pricebook2(Name = 'Warranty Pricebook Internal', Description = 'Warranty Pricebook Internal', Type__c = 'Warranty', IsActive = true );
        insert pbWarranty;
        createModelData();
    }
    @isTest 
    static void insertOpp() {
        AddProductPartsOrder.cheatTemp();
    }
    private static void createModelData() {
        String jsonData = '[{\"ModelType\":null,\"ModelTypeName\":null,\"ModelCode\":\"1DB400\",\"ModelName\":\"NouvoSXSTD1DB1\",\"EffectiveDate\":\"20121205\",\"OutEffectiveDate\":\"99991231\",\"ProductCode\":\"1DB400\",\"ProductSalesName\":\"NouvoSXSTD1DB1\",\"ColorCode\":\"010A\",\"ColorName\":\"ĐenĐỏ\",\"RegisteredModel\":\"1DB4\",\"ModelYear\":\"2012\",\"Displacement\":\"125\",\"StdRetailPrice\":null,\"DealerCode\":\"YT03\",\"PointCode\":\"YT03A\",\"ModelId\":\"ba91c22a-f01b-4dd8-8925-ab96de4ca23e\",\"UpdateDate\":\"20200424\"},{\"ModelType\":null,\"ModelTypeName\":null,\"ModelCode\":\"16S700\",\"ModelName\":\"Taurus16S2\",\"EffectiveDate\":\"20111031\",\"OutEffectiveDate\":\"99991231\",\"ProductCode\":\"16S700\",\"ProductSalesName\":\"Taurus16S2\",\"ColorCode\":\"010A\",\"ColorName\":\"Đỏ\",\"RegisteredModel\":\"16S7\",\"ModelYear\":\"2010\",\"Displacement\":\"115\",\"StdRetailPrice\":null,\"DealerCode\":\"YT03\",\"PointCode\":\"YT03A\",\"ModelId\":\"3931a885-7ef9-4b3a-a9a6-f0e70b9380f1\",\"UpdateDate\":\"20200904\"},{\"ModelType\":null,\"ModelTypeName\":null,\"ModelCode\":\"15C400\",\"ModelName\":\"Lexam15C2\",\"EffectiveDate\":\"20111031\",\"OutEffectiveDate\":\"99991231\",\"ProductCode\":\"15C400\",\"ProductSalesName\":\"Lexam15C2\",\"ColorCode\":\"010A\",\"ColorName\":\"Đỏ\",\"RegisteredModel\":\"15C4\",\"ModelYear\":\"2011\",\"Displacement\":\"115\",\"StdRetailPrice\":null,\"DealerCode\":\"YT03\",\"PointCode\":\"YT03A\",\"ModelId\":\"6c1baead-1fa7-4a8c-88f3-03ae18ad116c\",\"UpdateDate\":\"20200904\"}]';
        Map<String, Product2> modelMap = new Map<String, Product2>();
        List<SObjectAPIDMSRespone.ModelData> partsList = (List<SObjectAPIDMSRespone.ModelData>)JSON.deserialize(jsonData, List<SObjectAPIDMSRespone.ModelData>.class);
        for (SObjectAPIDMSRespone.ModelData modelItem : partsList) {
        if (String.isBlank(modelItem.ProductCode) || String.isBlank(modelItem.ColorCode) || String.isBlank(modelItem.ModelName)) continue;
              Product2 model = new Product2();
              model.Name = modelItem.ModelName;
              model.Model_Name__c = modelItem.ModelName;
              model.Model_Code__c = modelItem.ProductCode;
              model.ProductCode = modelItem.ProductCode;
              model.RecordTypeId = RecordTypeHelper.PRODUCT_MODEL;
              model.Model_Type__c = modelItem.ModelType;
              model.Model_Type_Name__c = modelItem.ModelTypeName;
         	  model.Bike_Type__c = 'Yamaha';
         	  model.Bike_Type_2__c = 'New';
         	  model.Engince_cc__c =String.isNotBlank(modelItem.Displacement) ? Decimal.valueOf(modelItem.Displacement) : 0;
              if (String.isNotBlank(modelItem.ModelYear)) model.Model_Year__c = Decimal.valueOf(modelItem.ModelYear);
              model.Color_Code__c = modelItem.ColorCode;
			  model.Color_Name__c = modelItem.ColorName;
			  model.Model__c = 'Yamaha';
			  model.IsActive = true;
			  model.Bike_cc__c = String.isNotBlank(modelItem.Displacement) && Integer.valueOf(modelItem.Displacement) > 400 ? '>400cc' : '<400cc';
			  model.RegisteredModel__c = modelItem.RegisteredModel;
			  model.Model_Id__c = modelItem.ModelId;
			  model.ExternalID_DMS__c = modelItem.ProductCode + modelItem.ColorCode;
			  modelMap.put(model.ExternalID_DMS__c, model);
		}
        Upsert modelMap.values() ExternalID_DMS__c;
        createPricebookEntireStandard(modelMap);
    }
    private static void createPricebookEntireStandard(Map<String, Product2> productCodeMap) {
        //Instantiate the Pricebook2 record with StandardPricebookId
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Map<String , Id> mapExternalId = new Map<String , Id>();
        List<PricebookEntry> lstPBEStarndard = new List<PricebookEntry>();
        for (PricebookEntry entry : [SELECT Id, ServiceJob_Key__c
                                     FROM PricebookEntry
                                     WHERE ServiceJob_Key__c IN: productCodeMap.keySet() AND Pricebook2Id =: standardPricebook.Id]) {
            mapExternalId.put(entry.ServiceJob_Key__c, entry.Id);
         }
        for (String key : productCodeMap.keySet()) {
            PricebookEntry pricingStandard = createPriceBookEntry(standardPricebook.Id, productCodeMap.get(key).Id, 0);
            pricingStandard.Id = mapExternalId.get(key);
            lstPBEStarndard.add(pricingStandard);
        }
        Upsert lstPBEStarndard;
    }
    public static PricebookEntry createPriceBookEntry(Id pricebookId, Id proid, Decimal unitprice) {
        PricebookEntry pbe = new PricebookEntry(
                            Pricebook2Id = pricebookId,
                            Product2Id = proid,
                            UnitPrice = unitprice,
                            IsActive = true
        );
        return pbe;
    }
}