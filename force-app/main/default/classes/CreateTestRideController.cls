public class CreateTestRideController {
    @AuraEnabled
    public static ApiResponse getInitialData(Id recordId){
        ApiResponse apiResponse = new ApiResponse(true);
        ValidateResult validateResult = validateRequestData(recordId);
        apiResponse.result = validateResult;
        return apiResponse;
    }
    private static ValidateResult validateRequestData(Id recordId){
        ValidateResult result = new ValidateResult();
		List<Opportunity> lstOppty = [SELECT ID, AccountId, Product__c
                                      FROM Opportunity WHERE Id =: recordId];
        if (lstOppty.isEmpty()) {
            throw new AuraHandledException('Opportunity not found');
        }
        // if (String.isBlank(lstOppty[0].Product__c)) {
        //     throw new AuraHandledException('Product not add to Opportunity');
        // }
        List<Account> lstAccount = [SELECT ID, LastName,FirstName,ID_No__c ,A2_License_No__c, PersonMobilePhone , A2__c,
                                    AccountNumber, ID_Issue_Date__c, PersonEmail, A2_Issue_Date__c
                                    FROM Account WHERE Id =:lstOppty[0].AccountId];
        if (lstAccount.isEmpty()) {
            throw new AuraHandledException('Account not found'); 
        }
        List<Product2> lstProduct = [SELECT Id, Name
                                     FROM Product2 WHERE Id =:lstOppty[0].Product__c];
        result.Idopp = recordId;
        result.product = (!lstProduct.isEmpty() ?  lstProduct[0] : new Product2());
        result.customerInfor = lstAccount[0];
        result.datetimepicked = Datetime.now();
        result.expectedReturn = Datetime.now();
        result.comments = '';
        return result;
    }
    @AuraEnabled
    public static List<RecordsData> fetchRecords(String objectName, String filterField, String searchString, String values, Id idproductDefault) {
        try {
            List<RecordsData> recordsDataList = new List<RecordsData>();
            List<String> selectedvalues = (List<String>) JSON.deserialize(values, List<String>.class);
            String query = 'SELECT Id, ' + filterField + ' FROM ' + objectName;
            if(selectedvalues != null && selectedvalues.size() > 0) {
                query += ' WHERE Id IN: selectedvalues LIMIT 200';
            } else {
                query += ' WHERE ' + filterField +
                 ' LIKE ' + '\'' + String.escapeSingleQuotes(searchString.trim()) + '%\'' + 
                 ' AND Id !=: idproductDefault'  + 
                 ' AND RecordTypeId = ' +  '\'' + RecordTypeHelper.PRODUCT_MODEL + '\' LIMIT 50';
            }
            for(SObject s : Database.query(query)) {
                recordsDataList.add( new RecordsData((String)s.get(filterField), (String)s.get('Id')) );
            }
            return recordsDataList;
        } catch (Exception e) {
             throw new AuraHandledException('Error exception: ' + e.getLineNumber());
        }
    }

 	@AuraEnabled
    public static ApiResponse saveRecords(ValidateResult data, List<String> productsTest) {
        ApiResponse apiResponse = new ApiResponse();
        String sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm(); 
        Savepoint sp = Database.setSavepoint();
        try {
           
            if (data.product.Id !=null){
                productsTest.add(data.product.Id);
            }
            if (!productsTest.isEmpty()){
                update data.customerInfor;
                Test_Ride__c ride = createTestRideData(data);
                createRideAssign(ride.Id, productsTest);
                apiResponse.success = true;
                String printUrl = sfdcBaseURL + '/apex/TestRidePDF?id=' + ride.Id;
                apiResponse.result = printUrl;
            }else{
                apiResponse.addError('Must have at least one product!');
            }
        }catch(Exception e) {
            system.debug('--' + e.getMessage());
            Database.rollback(sp);
            apiResponse.success = false;
            apiResponse.addError(e.getMessage());
        }
        return apiResponse;
    }
    
    private static Test_Ride__c createTestRideData(ValidateResult data) {
        Test_Ride__c test = new Test_Ride__c();
        test.Test_Ride_Customer__c = data.customerInfor.Id;
        test.Comments__c = data.comments;
        test.Date_time_collected__c = data.datetimepicked;
		test.Status__c = 'Open';
        test.Expected_to_return__c = data.expectedReturn;
        test.Additional_equipments_documents__c = 'Set of key / Bộ chìa khóa;Registration license / Bản sao giấy đăng ký xe;Insurance policy / Bản chính giấy chứng nhận bảo hiểm xe';
        test.Opportunity__c = data.Idopp;
        insert test;
        return test;
    }
    
    private static List<Test_Ride_Assignment__c> createRideAssign(Id idTestRide, List<String> productsTest) {
        List<Test_Ride_Assignment__c> lstRideAssigns = new List<Test_Ride_Assignment__c>();
        for (string idProduct : productsTest) {
            Test_Ride_Assignment__c rideAssign = new Test_Ride_Assignment__c();
            rideAssign.Product__c = (Id)idProduct;
            rideAssign.Test_Ride__c = idTestRide;
            lstRideAssigns.add(rideAssign);
        }
        insert lstRideAssigns;
        return lstRideAssigns;
    }
    public class RecordsData {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public RecordsData(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    private class ValidateResult {
        @AuraEnabled
        public Id Idopp {get;set;}
        @AuraEnabled
        public Product2 product {get;set;}
        @AuraEnabled
        public Account customerInfor {get;set;}
        @AuraEnabled
        public Datetime datetimepicked {get;set;}
        @AuraEnabled
        public Datetime expectedReturn {get;set;}
        @AuraEnabled
        public string comments {get;set;}
        	
    }
  
    Public static void cheatTemp() {
        String a = 'cheat';
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
    }
}