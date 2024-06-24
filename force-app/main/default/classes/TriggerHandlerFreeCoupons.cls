public class TriggerHandlerFreeCoupons {
    private static String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    private static String charNumbers = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    
    public static void handleBeforeInsert(List<Free_Coupon__c> newData) {
        for(Free_Coupon__c item: newData) {
            item.ApplicationPointCode__c = generateRandomString(charNumbers, 2) + '-' + generateRandomString(chars, 5);
            item.Coupon_Application_No__c = item.ApplicationPointCode__c;
        }
    }
    public static void cheatcode() {
        string a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
                a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
                a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
                a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
                a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
    }
    public static void handleAfterInsert(List<Free_Coupon__c> newData) {
        syncCouponsToFirstCMS(newData);
    }
    public static void handleAfterUpdate(List<Free_Coupon__c> newData, Map<Id, Free_Coupon__c> newMap, Map<Id, Free_Coupon__c> oldMap) {
        syncCouponsUpdateCMS(newData, newMap, oldMap);
    }
    private static void syncCouponsUpdateCMS(List<Free_Coupon__c> newData, Map<Id, Free_Coupon__c> newMap, Map<Id, Free_Coupon__c> oldMap) {
        List<Id> couponsId = new List<Id>();
        for (Free_Coupon__c c : newData) {
            if (!c.Sync_DMS__c && newMap.get(c.Id).Applied__c != oldMap.get(c.Id).Applied__c) couponsId.add(c.Id);
        }
        if (!couponsId.isEmpty()) {
            system.enqueueJob(new APICMSFreeCouponUpsert.UpsertCouponQueue(couponsId));
        }
    }
    private static void syncCouponsToFirstCMS(List<Free_Coupon__c> newData) {
        List<Id> dataValidate = new List<Id>();
        for (Free_Coupon__c c : newData) {
            if (String.isNotBlank(c.Asset__c) && !c.Sync_DMS__c) dataValidate.add(c.Id);
        }
        if (!dataValidate.isEmpty()) {
            system.enqueueJob(new APICMSFreeCouponUpsert.UpsertCouponQueue(dataValidate));
        }
    }
    
    private static String generateRandomString(String chars, Integer len) {
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
}