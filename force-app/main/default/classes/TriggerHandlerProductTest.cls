@isTest
private class TriggerHandlerProductTest {
    @TestSetup
    static void setupTestData() {
        Policy__c policy = new Policy__c(
            Policy_Name__c = 'Test Policy',
            Price__c = 20
        );
        insert policy;

        Id priceBookId = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(
            Id = priceBookId,
            Policy__c = policy.Id,
            Type__c = 'PCAService'
        );
        update pb;

        Product2 p1 = new Product2(
            Name = 'Test Product 1',
            ExternalID_DMS__c = '111111',
            SupersedingPart__c = '222222',
            VAT__c = 15,
            Retail_Price__c = 100
        );
        Product2 p2 = new Product2(
            Name = 'Test Product 2',
            ExternalID_DMS__c = null,
            VAT__c = 20,
            Retail_Price__c = 200
        );
        insert new List<Product2>{ p1, p2 };

        PricebookEntry pbe1 = new PricebookEntry(
            Product2Id = p1.Id,
            UnitPrice = 100,
            Pricebook2Id = priceBookId
        );
        PricebookEntry pbe2 = new PricebookEntry(
            Product2Id = p2.Id,
            UnitPrice = 200,
            Pricebook2Id = priceBookId
        );
        insert new List<PricebookEntry>{ pbe1, pbe2 };
    }

    @isTest
    static void testOnBeforeUpdateSupersedingPart() {
        Product2 p = [
            SELECT Id, ExternalID_DMS__c, SupersedingPart__c
            FROM Product2
            WHERE ExternalID_DMS__c = '111111'
            LIMIT 1
        ];

        Test.startTest();
        p.SupersedingPart__c = '222222,333333';
        update p;
        Test.stopTest();

        Product2 updatedProduct = [
            SELECT SupersedingPart__c
            FROM Product2
            WHERE Id = :p.Id
        ];
        System.assertEquals(
            '222222,333333',
            updatedProduct.SupersedingPart__c,
            'Superseding part should be updated correctly'
        );
    }

    @isTest
    static void testOnAfterUpdateRetailPrice() {
        Product2 p = [
            SELECT Id, Retail_Price__c
            FROM Product2
            WHERE ExternalID_DMS__c = NULL
            LIMIT 1
        ];

        Test.startTest();
        p.Retail_Price__c = 250;
        update p;
        Test.stopTest();

        PricebookEntry updatedPBE = [
            SELECT UnitPrice
            FROM PricebookEntry
            WHERE Product2Id = :p.Id
            LIMIT 1
        ];
        Decimal expectedPrice = ((250 * 20) / 100) + ((250 * 20 * 20) / 100);
        System.assertEquals(
            expectedPrice.setScale(2),
            updatedPBE.UnitPrice.setScale(2),
            'PricebookEntry UnitPrice should be updated based on new Retail Price'
        );
    }
}
