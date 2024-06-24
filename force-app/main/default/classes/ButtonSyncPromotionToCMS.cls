public class ButtonSyncPromotionToCMS {
    @AuraEnabled
    public static void syncPromotionToDMS(Id recordId) {
        System.enqueueJob(new APICMSUpsertPromotionMaster.CreatePromoQueue(new List<Id> {recordId}));
    }
}