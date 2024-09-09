@IsTest
public with sharing class GenerateOpportunityFlowHandlerTest {
    @isTest
    private static void testHandleGenerate() {
        // Perform Test
        Test.startTest();
        // Test.getStandardPricebookId();
        Map<String, Id> testData = setupDataToTest();
        GenerateOpportunityFlowHandler.handleGenerate(testData.get('empInsId'));

        List<Opportunity> opty = [
            SELECT Id
            FROM Opportunity
            WHERE
                Product__c = :testData.get('prodId')
                AND AccountId = :testData.get('accId')
                AND Pricebook2Id = :testData.get('pbId')
            LIMIT 1
        ];
        Test.stopTest();

        // Verify Test
        System.assertNotEquals(opty, null, 'Result should not be null');
        System.assertEquals(opty.size(), 1, 'Result should be 1');
        System.assertEquals(
            opty[0].Is_Employee__c,
            true,
            'This value should be true'
        );
        System.assertEquals(
            opty[0].SNS__c,
            'Test Instruction',
            'Result should be the same'
        );
    }

    private static Map<String, Id> setupDataToTest() {
        Map<String, Id> result = new Map<String, Id>();
        // Create Province
        Province__c province = new Province__c(Province_Code__c = 'test');
        insert province;
        // Create district
        District__c district = new District__c(District_Code__c = 'test');
        insert district;
        // record type Id of Account
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('DODLR')
            .getRecordTypeId();
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Customer',
            Gender__c = 'Male',
            DO_DL_Code__c = 'Test',
            Phone = '0909090909',
            RecordTypeId = accRecordTypeId
        );
        insert testAccount;
        result.put('accId', testAccount.Id);

        // Create Employee Instruction
        EmployeeInstruction__c testEmpIns = new EmployeeInstruction__c(
            EmployeeCode__c = 'Test Instruction',
            PurchaseType__c = 'Test Instruction',
            EmployeeName__c = testAccount.Name,
            AP44Price__c = 1000,
            SNS__c = 'Test Instruction',
            ModelCode__c = 'Test Instruction',
            Mobile__c = '090909090909',
            DealerCode__c = 'Test',
            FirstName__c = 'Test',
            LastName__c = 'Account',
            Gender__c = 'Male',
            Birthday__c = String.valueOf(Date.today()),
            Province__c = 'HCM',
            ProvinceCode__c = 'test',
            District__c = '3',
            DistrictCode__c = 'test',
            Address__c = 'Test Instruction'
        );
        insert testEmpIns;
        result.put('empInsId', testEmpIns.Id);

        // Create Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'Test Product',
            Model_Code__c = 'Test Instruction',
            WholesaleStandardPrice__c = 3
        );
        insert testProduct;
        result.put('prodId', testProduct.Id);

        // Create Standard PriceBook
        Pricebook2 stdPricebook = new Pricebook2(
            // Pricebook2Id = testPricebook.Id,
            // Product2Id = testProduct.Id,
            IsActive = true,
            Name = 'Test Std Pricebook'
        );
        insert stdPricebook;

        // Create Pricebook
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true,
            Price_Book_Origin__c = stdPricebook.Id
        );
        insert testPricebook;
        result.put('pbId', testPricebook.Id);

        Id standardPBId = Test.getStandardPricebookId();
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPBId,
            Product2Id = testProduct.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert standardPBE;

        // Create PriceBookEntry
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert testPricebookEntry;
        result.put('pbeId', testPricebookEntry.Id);

        return result;
    }
}
