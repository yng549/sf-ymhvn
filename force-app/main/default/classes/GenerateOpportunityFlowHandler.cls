public with sharing class GenerateOpportunityFlowHandler {
    @AuraEnabled(cacheable=false)
    public static void handleGenerate(String recordId) {
        EmployeeInstruction__c empIns = getEmployeeInstructionByIdWithAllFields(
            recordId
        );
        if (empIns.IsGenerated__c) {
            throw new AuraHandledException(
                'This Employee Instruction has been genarated Opportunity!'
            );
        }
        try {
            Account acc = getAccountByPhoneAndDO(empIns);
            Product2 prod = getProductByModelCode(empIns.ModelCode__c);
            if (prod == null) {
                throw new AuraHandledException(
                    'Not found product with current model code, please set up new product.'
                );
            }
            Pricebook2 pbByBike = getPriceBookByName('Bike');
            if (pbByBike == null) {
                throw new AuraHandledException(
                    'Not found pricebook for Bike, please set up new pricebook.'
                );
            }
            Opportunity opty = createOpportunity(
                prod.Id,
                acc,
                empIns,
                pbByBike.Id
            );
            OpportunityLineItem oli = createOpportunityLineItem(
                opty.Id,
                prod.Id
            );
            Quote q = createQuote(opty.Id);
            PricebookEntry pbe = getPricebookEntryByProd(prod.Id, pbByBike.Id);
            System.debug('Price book entry id: ' + pbe.Id);
            QuoteLineItem qli = createQuoteLineItem(q.Id, pbe.Id, prod, empIns);

            empIns.IsGenerated__c = true;
            update empIns;
        } catch (Exception e) {
            throw e;
        }
    }

    private static Opportunity createOpportunity(
        Id prodId,
        Account acc,
        EmployeeInstruction__c empIns,
        Id pbId
    ) {
        Opportunity opty = new Opportunity();
        opty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Bike')
            .getRecordTypeId();
        if (opty.RecordTypeId == null) {
            throw new AuraHandledException(
                'Not found RecordTypeId for Bike in Opportunity, please set up new RecordType.'
            );
        }
        opty.Product__c = prodId;
        opty.Name = 'New Opty';
        opty.DODL_Create__c = acc.DO_DL_Create_Account__c;
        opty.AccountId = acc.Id;
        opty.Is_Employee__c = true;
        opty.Employee_Code__c = empIns.EmployeeCode__c;
        opty.Purchase_Type__c = empIns.PurchaseType__c;
        opty.Employee_Name__c = empIns.EmployeeName__c;
        opty.AP44Price__c = empIns.AP44Price__c;
        opty.SNS__c = empIns.SNS__c;
        opty.StageName = 'New';
        opty.CloseDate = Date.today();
        opty.Pricebook2Id = pbId;
        opty.Employee_Instruction__c = empIns.Id;
        opty.DmsOrderId__c = empIns.DmsOrderId__c;
        try {
            insert opty;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
        return opty;
    }

    private static OpportunityLineItem createOpportunityLineItem(
        Id optyId,
        Id prodId
    ) {
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = optyId;
        oli.Product2Id = prodId;
        oli.Quantity = 1;
        oli.TotalPrice = 0;
        try {
            insert oli;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
        return oli;
    }

    private static Quote createQuote(Id optyId) {
        Quote q = new Quote();
        q.RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName()
            .get('Sales_Bike')
            .getRecordTypeId();
        if (q.RecordTypeId == null) {
            throw new AuraHandledException(
                'Not found RecordTypeId for Sales Bike in Quote, please set up new RecordType.'
            );
        }
        q.OpportunityId = optyId;

        String formattedToday = (Datetime.now()).formatGMT('ddMMyyyy');
        string quoteNameFormat = '-';
        quoteNameFormat += 'A';
        q.Name = formattedToday + quoteNameFormat;
        try {
            insert q;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
        return q;
    }

    private static QuoteLineItem createQuoteLineItem(
        Id quoteId,
        Id pbeId,
        Product2 prod,
        EmployeeInstruction__c empIns
    ) {
        QuoteLineItem qli = new QuoteLineItem();
        qli.QuoteId = quoteId;
        qli.Product2Id = prod.Id;
        qli.Quantity = 1;
        qli.UnitPrice = (empIns.AP44Price__c == null ||
            prod.WholesaleStandardPrice__c == null)
            ? 0
            : empIns.AP44Price__c * prod.WholesaleStandardPrice__c;
        qli.PricebookEntryId = pbeId;
        qli.Is_Generated_With_Opty__c = true;
        try {
            insert qli;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
        return qli;
    }

    private static EmployeeInstruction__c getEmployeeInstructionByIdWithAllFields(
        String empInsId
    ) {
        Map<String, Schema.SObjectField> empInsFieldMap = EmployeeInstruction__c.sObjectType.getDescribe()
            .fields.getMap();
        List<string> empInsSelectFields = new List<String>(
            empInsFieldMap.keySet()
        );
        String queryString = 'SELECT ' + String.join(empInsSelectFields, ',');
        queryString += ' FROM EmployeeInstruction__c';
        queryString += ' WHERE Id = :empInsId';
        EmployeeInstruction__c empIns = Database.query(queryString);
        return empIns;
    }

    private static Product2 getProductByModelCode(String modelCode) {
        List<Product2> prod = [
            SELECT Id, Model_Code__c, WholesaleStandardPrice__c
            FROM Product2
            WHERE Model_Code__c = :modelCode
            LIMIT 1
        ];
        if (prod != null && prod.size() > 0) {
            return prod[0];
        }
        return null;
    }

    private static Account getAccountByDealerCode(String dealerCode) {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('DODLR')
            .getRecordTypeId();

        return [
            SELECT Id
            FROM Account
            WHERE RecordTypeId = :recordTypeId AND DO_DL_Code__c = :dealerCode
            LIMIT 1
        ];
    }

    private static Account getAccountByPhoneAndDO(
        EmployeeInstruction__c empIns
    ) {
        String empInsMobile = StringHelper.normalizePhoneNumber(
            empIns.Mobile__c
        );
        String recoreTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Customer')
            .getRecordTypeId();

        List<Account> acc = [
            SELECT
                Id,
                DO_DL_Create_Account__c,
                DO_DL_Create_Account__r.DO_DL_Code__c,
                DO_DL_Code__c
            FROM Account
            WHERE
                PersonMobilePhone = :empInsMobile
                AND RecordTypeId = :recoreTypeId
                AND DO_DL_Create_Account__r.DO_DL_Code__c = :empIns.DealerCode__c
            LIMIT 1
        ];

        try {
            if (acc != null && acc.size() > 0) {
                return acc[0];
            } else {
                return createNewAccountFromEmInstruction(empIns);
            }
        } catch (Exception e) {
            throw e;
        }
    }

    private static Account createNewAccountFromEmInstruction(
        EmployeeInstruction__c empIns
    ) {
        Province__c prov = [
            SELECT Id
            FROM Province__c
            WHERE Province_Code__c = :empIns.ProvinceCode__c
            LIMIT 1
        ];
        District__c dist = [
            SELECT Id
            FROM District__c
            WHERE District_Code__c = :empIns.DistrictCode__c
            LIMIT 1
        ];
        Account accDLDOR = getAccountByDealerCode(empIns.DealerCode__c);

        Account acc = new Account();
        acc.FirstName = empIns.FirstName__c;
        acc.LastName = empIns.LastName__c;
        if (empIns.Mobile__c != null) {
            acc.PersonMobilePhone = empIns.Mobile__c;
        }
        if (empIns.Gender__c != null) {
            acc.Gender__c = empIns.Gender__c;
        }
        // if (empIns.Birthday__c != null) {
        // acc.Birthda = Date.parse(empIns.Birthday__c);
        // }
        if (empIns.Province__c != null) {
            acc.Province__c = prov.Id;
        }
        // if (empIns.ProvinceCode__c != null) {
        //     acc.Province__pc = prov.Id;
        // }
        if (empIns.District__c != null) {
            acc.District__c = dist.Id;
        }
        // if (empIns.District__c != null) {
        //     acc.District__pc = dist.Id;
        // }
        if (empIns.Address__c != null) {
            acc.Address__c = empIns.Address__c;
        }

        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Customer')
            .getRecordTypeId();
        if (accDLDOR == null) {
            throw new AuraHandledException(
                'Not found DO/DL Account with Dealder Code. Please set up new DO/DL Account'
            );
        }
        acc.DO_DL_Create_Account__c = accDLDOR.Id;

        try {
            insert acc;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
        return acc;
    }

    private static Pricebook2 getPriceBookByName(String name) {
        Pricebook2 priceBook = [
            SELECT Id
            FROM Pricebook2
            WHERE Name = :name
            LIMIT 1
        ];
        return priceBook;
    }

    private static PricebookEntry getPricebookEntryByProd(Id prodId, Id pbId) {
        return [
            SELECT Id
            FROM PricebookEntry
            WHERE Product2Id = :prodId AND Pricebook2Id = :pbId
            LIMIT 1
        ];
    }
}
