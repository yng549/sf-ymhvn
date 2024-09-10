@IsTest
public with sharing class EmployeeInstructionManagerTest {
    @isTest
    static void testCreateEmployeeInstruction() {
        RestResponse res = new RestResponse();
        RestContext.response = res;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            EmployeeInstructionManager.createEmployeeInstruction(
                'DealerCode',
                'ModelCode',
                'LastName',
                'FirstName',
                'Mobile',
                'EmployeeCode',
                'EmployeeName',
                '1',
                'MiddleName',
                'SNS',
                'Gender',
                'Birthday',
                'Province',
                'ProvinceCode',
                'District',
                'DistrictCode',
                'Address',
                'Email@email.com',
                'PurchaseType',
                null
            );
            Test.stopTest();

            EmployeeInstruction__c newEmpIns = [
                SELECT
                    Id,
                    DealerCode__c,
                    ModelCode__c,
                    LastName__c,
                    FirstName__c,
                    Mobile__c,
                    EmployeeCode__c,
                    EmployeeName__c,
                    AP44Price__c,
                    MiddleName__c,
                    SNS__c,
                    Gender__c,
                    Birthday__c,
                    Province__c,
                    ProvinceCode__c,
                    District__c,
                    DistrictCode__c,
                    Address__c,
                    Email__c,
                    PurchaseType__c,
                    DmsOrderId__c
                FROM EmployeeInstruction__c
            ];

            System.assertEquals(
                'DealerCode',
                newEmpIns.DealerCode__c,
                'DealerCode should match'
            );
            System.assertEquals(
                'ModelCode',
                newEmpIns.ModelCode__c,
                'ModelCode should match'
            );
            System.assertEquals(
                'LastName',
                newEmpIns.LastName__c,
                'LastName should match'
            );
            System.assertEquals(
                'FirstName',
                newEmpIns.FirstName__c,
                'FirstName should match'
            );
            System.assertEquals(
                'Mobile',
                newEmpIns.Mobile__c,
                'Mobile should match'
            );
            System.assertEquals(
                'EmployeeCode',
                newEmpIns.EmployeeCode__c,
                'EmployeeCode should match'
            );
            System.assertEquals(
                'EmployeeName',
                newEmpIns.EmployeeName__c,
                'EmployeeName should match'
            );
            System.assertEquals(
                Long.valueOf('1'),
                newEmpIns.AP44Price__c,
                'AP44Price should match'
            );
            System.assertEquals(
                'MiddleName',
                newEmpIns.MiddleName__c,
                'MiddleName should match'
            );
            System.assertEquals('SNS', newEmpIns.SNS__c, 'SNS should match');
            System.assertEquals(
                'Gender',
                newEmpIns.Gender__c,
                'Gender should match'
            );
            System.assertEquals(
                'Birthday',
                newEmpIns.Birthday__c,
                'Birthday should match'
            );
            System.assertEquals(
                'Province',
                newEmpIns.Province__c,
                'Province should match'
            );
            System.assertEquals(
                'ProvinceCode',
                newEmpIns.ProvinceCode__c,
                'ProvinceCode should match'
            );
            System.assertEquals(
                null,
                newEmpIns.DmsOrderId__c,
                'DmsOrderId__c should match'
            );
        }
    }
    @isTest
    static void testCreateEmployeeInstructionWithMissingFields() {
        RestResponse res = new RestResponse();
        RestContext.response = res;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            EmployeeInstructionManager.createEmployeeInstruction(
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                'test',
                'SNS',
                'Gender',
                'Birthday',
                'Province',
                'ProvinceCode',
                'District',
                'DistrictCode',
                'Address',
                'email@email.com',
                'PurchaseType',
                'DmsOrderId_1'
            );
            Test.stopTest();

            System.assertEquals(
                400,
                res.statusCode,
                'Expected status code to be 400'
            );
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
                res.responseBody.toString()
            );
            System.assertEquals(
                'Missing field DealerCode, Missing field ModelCode, Missing field LastName, Missing field FirstName, Missing field Mobile, Missing field EmployeeCode, Missing field EmployeeName, Missing field AP44Price',
                responseMap.get('responseMessage'),
                'Expected error message'
            );
        }
    }
    @isTest
    static void testCreateEmployeeInstructionMithInvalidEmail() {
        RestResponse res = new RestResponse();
        RestContext.response = res;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            EmployeeInstructionManager.createEmployeeInstruction(
                'DealerCode',
                'ModelCode',
                'LastName',
                'FirstName',
                'Mobile',
                'EmployeeCode',
                'EmployeeName',
                '1',
                'MiddleName',
                'SNS',
                'Gender',
                'Birthday',
                'Province',
                'ProvinceCode',
                'District',
                'DistrictCode',
                'Address',
                'email.com',
                'PurchaseType',
                null
            );
            Test.stopTest();

            System.assertEquals(
                400,
                res.statusCode,
                'Expected status code to be 400'
            );
        }
    }

    @isTest
    static void testCreateEmployeeInstructionWithDmsOrderId() {
        RestResponse res = new RestResponse();
        RestContext.response = res;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            EmployeeInstructionManager.createEmployeeInstruction(
                'DealerCode',
                'ModelCode',
                'LastName',
                'FirstName',
                'Mobile',
                'EmployeeCode',
                'EmployeeName',
                '1',
                'MiddleName',
                'SNS',
                'Gender',
                'Birthday',
                'Province',
                'ProvinceCode',
                'District',
                'DistrictCode',
                'Address',
                'Email@email.com',
                'PurchaseType',
                'DmsOrderId_1'
            );
            Test.stopTest();

            EmployeeInstruction__c newEmpIns = [
                SELECT Id, DmsOrderId__c
                FROM EmployeeInstruction__c
            ];

            System.assertEquals(
                'DmsOrderId_1',
                newEmpIns.DmsOrderId__c,
                'DmsOrderId should match'
            );
        }
    }
}
