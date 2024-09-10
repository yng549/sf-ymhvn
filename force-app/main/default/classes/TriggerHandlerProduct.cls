/*******************************************************************************
 ** Class Name: TriggerHandlerProduct
 ** Description: Handle suppersending part
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class TriggerHandlerProduct {
    public static void onBeforeUpdate(
        List<Product2> newData,
        Map<Id, Product2> newMap,
        Map<Id, Product2> oldMap
    ) {
        List<Id> productCMS = new List<Id>();
        List<Id> productUpdateVAT = new List<Id>();
        for (Product2 p : newData) {
            if (
                string.isNotBlank(p.ExternalID_DMS__c) &&
                string.isNotBlank(p.SupersedingPart__c)
            )
                productCMS.add(p.Id);
            if (
                p.VAT__c != null &&
                p.VAT__c != oldMap.get(p.Id).Vat__c &&
                p.RecordtypeId == RecordTypeHelper.PRODUCT_PCA
            )
                //if (p.VAT__c != null && p.RecordtypeId == RecordTypeHelper.PRODUCT_PCA)
                productUpdateVAT.add(p.Id);
        }
        if (!productCMS.isEmpty()) {
            handlerSuppersendingPart(productCMS, newMap, oldMap);
        }
        if (!productUpdateVAT.isEmpty()) {
            handlerVATUpdatePBE(newMap, productUpdateVAT);
        }
    }

    public static void onAfterUpdate(
        List<Product2> newData,
        Map<Id, Product2> newMap,
        Map<Id, Product2> oldMap
    ) {
        System.debug('I am in on after event');
        List<Id> productUpdateRetailPrice = new List<Id>();
        for (Product2 p : newData) {
            Boolean isExternalProduct = p.ExternalID_DMS__c == null;
            Boolean isRetailPriceChanged =
                p.Retail_Price__c != oldMap.get(p.Id).Retail_Price__c;
            if (isExternalProduct && isRetailPriceChanged) {
                productUpdateRetailPrice.add(p.Id);
            }
        }
        if (!productUpdateRetailPrice.isEmpty()) {
            handlerUnitPriceUpdatePBE(newMap, productUpdateRetailPrice);
        }
    }
    private static void handlerUnitPriceUpdatePBE(
        Map<Id, Product2> newMap,
        List<Id> productUpdateRetailPrice
    ) {
        List<PricebookEntry> pbesUpdate = new List<PricebookEntry>();
        for (PricebookEntry pbe : [
            SELECT Id, UnitPrice, Product2Id, Pricebook2.Policy__r.Price__c
            FROM PricebookEntry
            WHERE
                Product2Id IN :productUpdateRetailPrice
                AND Pricebook2.Policy__c != NULL
        ]) {
            Decimal productVAT = newMap.get(pbe.Product2Id).VAT__c;
            Decimal newRetailPrice = newMap.get(pbe.Product2Id).Retail_Price__c;
            Double policyPrice = pbe.Pricebook2.Policy__r.Price__c;
            // (New Retail Price * % Policy) + (New Retail Price * % Policy * VAT__c)
            Decimal totalPrice = (((newRetailPrice * policyPrice) / 100) +
            ((newRetailPrice * policyPrice * productVAT) / 100));
            pbe.UnitPrice =
                ((newRetailPrice * policyPrice) / 100) +
                ((newRetailPrice * policyPrice * productVAT) / 100);
            pbesUpdate.add(
                new PricebookEntry(
                    Id = pbe.Id,
                    UnitPrice = pbe.UnitPrice.round(System.RoundingMode.HALF_UP)
                )
            );
        }
        update pbesUpdate;
    }
    private static void handlerVATUpdatePBE(
        Map<Id, Product2> newData,
        List<Id> productUpdateVAT
    ) {
        List<PricebookEntry> pbesUpdate = new List<PricebookEntry>();
        for (PricebookEntry pbe : [
            SELECT Id, UnitPrice, Product2Id
            FROM PricebookEntry
            WHERE
                Product2Id IN :productUpdateVAT
                AND Pricebook2.IsStandard = FALSE
                AND Pricebook2.Type__c = 'PCAService'
        ]) {
            pbe.UnitPrice =
                newData.get(pbe.Product2Id).Retail_Price__c +
                ((newData.get(pbe.Product2Id).Retail_Price__c *
                newData.get(pbe.Product2Id).Vat__c) / 100);
            pbesUpdate.add(
                new PricebookEntry(
                    Id = pbe.Id,
                    UnitPrice = pbe.UnitPrice.round(System.RoundingMode.HALF_UP)
                )
            );
        }
        update pbesUpdate;
    }
    private static void handlerSuppersendingPart(
        List<Id> productCMS,
        Map<Id, Product2> newMap,
        Map<Id, Product2> oldMap
    ) {
        for (Id productId : productCMS) {
            string oldPart = oldMap.get(productId).SupersedingPart__c;
            string newPart = newMap.get(productId).SupersedingPart__c;
            List<string> supPartsOlds = string.isNotBlank(oldPart)
                ? oldPart.split(',')
                : new List<string>();
            List<string> supPartsNews = newPart.split(',');
            for (string spNewPart : supPartsNews) {
                if (supPartsOlds.contains(spNewPart))
                    continue;
                supPartsOlds.add(spNewPart);
            }
            newMap.get(productId).SupersedingPart__c = String.join(
                supPartsOlds,
                ','
            );
        }
    }
}
