@RestResource(urlMapping='/EmployeeInstruction/*')
global with sharing class EmployeeInstructionManager {
    @HttpPost
    global static void createEmployeeInstruction(
        String DealerCode,
        String ModelCode,
        String LastName,
        String FirstName,
        String Mobile,
        String EmployeeCode,
        String EmployeeName,
        String AP44Price,
        String MiddleName,
        String SNS,
        String Gender,
        String Birthday,
        String Province,
        String ProvinceCode,
        String District,
        String DistrictCode,
        String Address,
        String Email,
        String PurchaseType,
        String DmsOrderId
    ) {
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        List<String> errList = new List<String>{};

        if (DealerCode == null || DealerCode.length() == 0) {
            errList.add('Missing field DealerCode');
        }
        if (ModelCode == null || ModelCode.length() == 0) {
            errList.add('Missing field ModelCode');
        }
        if (LastName == null || LastName.length() == 0) {
            errList.add('Missing field LastName');
        }
        if (FirstName == null || FirstName.length() == 0) {
            errList.add('Missing field FirstName');
        }
        if (Mobile == null || Mobile.length() == 0) {
            errList.add('Missing field Mobile');
        }
        if (EmployeeCode == null || EmployeeCode.length() == 0) {
            errList.add('Missing field EmployeeCode');
        }
        if (EmployeeName == null || EmployeeName.length() == 0) {
            errList.add('Missing field EmployeeName');
        }
        if (AP44Price == null || AP44Price.length() == 0) {
            errList.add('Missing field AP44Price');
        }
        if (!errList.isEmpty()) {
            res.statusCode = 400;
            String errorMessage = String.join(errList, ', ');
            Map<String, String> resBody = new Map<String, String>{
                'responseMessage' => errorMessage
            };
            res.responseBody = Blob.valueOf(JSON.Serialize(resBody));
        } else if (Schema.SObjectType.EmployeeInstruction__c.isCreateable()) {
            try {
                EmployeeInstruction__c newEmpIns = new EmployeeInstruction__c(
                    DealerCode__c = DealerCode,
                    ModelCode__c = ModelCode,
                    LastName__c = LastName,
                    FirstName__c = FirstName,
                    Mobile__c = Mobile,
                    EmployeeCode__c = EmployeeCode,
                    EmployeeName__c = EmployeeName,
                    AP44Price__c = Decimal.valueOf(AP44Price)
                );
                newEmpIns.MiddleName__c = MiddleName;
                newEmpIns.SNS__c = SNS;
                newEmpIns.Gender__c = Gender;
                newEmpIns.Birthday__c = Birthday;
                newEmpIns.Province__c = Province;
                newEmpIns.ProvinceCode__c = ProvinceCode;
                newEmpIns.District__c = District;
                newEmpIns.DistrictCode__c = DistrictCode;
                newEmpIns.Address__c = Address;
                newEmpIns.Email__c = Email;
                newEmpIns.PurchaseType__c = PurchaseType;
                newEmpIns.DmsOrderId__c = DmsOrderId;

                insert newEmpIns;

                res.statusCode = 201;
                Map<String, String> resBody = new Map<String, String>{
                    'id' => newEmpIns.Id
                };
                res.responseBody = blob.valueOf(JSON.serialize(resBody));
            } catch (Exception e) {
                res.statusCode = 400;
                String errMess = e.getMessage();
                Map<String, String> resBody = new Map<String, String>{
                    'responseMessage' => errMess
                };
                res.responseBody = blob.valueOf(JSON.serialize(resBody));
            }
        } else {
            throw new DmlException('User do not have permission');
        }
    }
}
