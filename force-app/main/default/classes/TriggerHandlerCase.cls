public without sharing class TriggerHandlerCase {
    private static Map<Id, User> mapUserGetAll = mapUserGetAll();
    
    public static void onAfterUpsert(List<Case> lstCaseNew) {
        updateFieldSaleAdmin(lstCaseNew);
        
    }
    
    public static void onAfterUpdate(Map<Id, Case> mapOld, Map<Id, Case> mapNew) {        
        List<Case> lstCaseCondition = new List<Case>();
        Set<Id> setIdAsset = new Set<Id>();
        for(Case item : mapNew.values()) {
            if(mapOld.get(item.Id).AssetId != item.AssetId && item.AssetId != Null) {
                System.debug('Oassa');
                setIdAsset.add(item.assetId);
                lstCaseCondition.add(item);
            }
        }
        if(!lstCaseCondition.isEmpty()) {
            updateAssetNotAvailable(lstCaseCondition, setIdAsset);
        }
    }
    
                                   
    private static void updateAssetNotAvailable(List<Case> lstCaseNews, Set<Id> setIdAsset) {
        List<Case> lstCaseQuerry = [SELECT Id, OwnerId, Sales_Admin__c, PCA_Sup__c, Service_Manager__c FROM Case WHERE Id IN: lstCaseNews];
        List<Asset> lstAssetQuerry = [SELECT Id, Inventory_Status__c FROM Asset WHERE Id IN: setIdAsset];
        for(Asset item : lstAssetQuerry) {
            item.Inventory_Status__c = 'Not Available';
        }
        update lstAssetQuerry;
    }
    
    private static void updateFieldSaleAdmin(List<Case> lstCaseNews) {
        List<Case> lstCaseQuerry = [SELECT Id, OwnerId, Sales_Admin__c, PCA_Sup__c, Service_Manager__c FROM Case WHERE Id IN: lstCaseNews];
        for(Case item : lstCaseQuerry) {
            if(mapUserGetAll.containsKey(item.OwnerId)) {
                item.Sales_Admin__c = mapUserGetAll.get(item.OwnerId).Sales_Admin__c;
                item.PCA_Sup__c = mapUserGetAll.get(item.OwnerId).PCA_Sup__c;
                item.Service_Manager__c = mapUserGetAll.get(item.OwnerId).Service_Manager__c;
            }
        }
        update lstCaseQuerry;
    }
    
    private static Map<Id, User> mapUserGetAll() {
        return new Map<Id, User>([SELECT Id, Sales_Admin__c, PCA_Sup__c, Service_Manager__c FROM User]);
    }
}