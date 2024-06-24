/*******************************************************************************
 ** Class Name: APIResignTestDrive
 ** Description: API Resign Form Test Drving.
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
@RestResource(urlMapping = '/APIResignTestDrive/*')
global class APIResignTestDrive {
    private final static string TIME_MORNING = 'Sáng';
	// Error code definition : {error code => http status code, error message}
    private static final Map<String, errDef> err = new Map<String, errDef> {
        'SUCCESS'                   	=> new errDef(200, 'Success'),
        'PARAM_NOMODEL'  				=> new errDef(400, 'Model invalid'),
        'RESIGNERNAME'     				=> new errDef(400, 'Resigner Name required'),
        'MODELSIGNNOTFOUND'     		=> new errDef(400, 'Model not found'),
        'MOBILEPHONE'     				=> new errDef(400, 'MobilePhone required'),
        'DODLBLANK'  					=> new errDef(400, 'Dealer required'),
        'DODLEMPTY'  					=> new errDef(400, 'Dealer not found'),
        'ERROR_EXCEPTION'           	=> new errDef(500, 'Exception occured')
    };
    // http request 
    private static RestRequest req = RestContext.request;
    private static RestResponse res = RestContext.response;
    private static requestBody reqBody = new requestBody();
    private static responseBody resBody = new responseBody();
    @HttpPost
    global static void run() {
        try {
            reqBody = (requestBody)JSON.deserialize(req.requestBody.toString(), requestBody.class);
            if (String.isBlank(reqBody.ProductCode)) {
                createResponse('PARAM_NOMODEL');
            	return;
            }
            if (String.isBlank(reqBody.FullName)) {
                createResponse('RESIGNERNAME');
            	return;
            }
            if (String.isBlank(reqBody.Mobile)) {
                createResponse('MOBILEPHONE');
            	return;
            }
            if (String.isBlank(reqBody.Email)) {
                createResponse('PARAM_NOBRAND');
            	return;
            }
            if (String.isBlank(reqBody.DoDL)) {
                createResponse('DODLBLANK');
            	return;
            }
            List<Product2> productSign = [SELECT Id FROM Product2 WHERE ProductCode =: reqBody.ProductCode];
            if (productSign.isEmpty()) {
                createResponse('MODELSIGNNOTFOUND');
            	return;
            }
            reqBody.Mobile = StringHelper.normalizePhoneNumber(reqBody.Mobile);
            List<Account> dealerBooking = [SELECT Id FROM Account WHERE DO_DL_Code__c = : reqBody.DoDL];
            if (dealerBooking.isEmpty()) {
                createResponse('DODLEMPTY');
            	return;
            }
            createTestRide(dealerBooking[0], productSign[0].Id);
            // Create a success response.
            createResponse('SUCCESS');
            return;
        }catch(Exception ex) {
            createResponse('ERROR_EXCEPTION', ex);
            return;
        }
    }
    
    private static void createTestRide(Account dealerBooking, Id product) {
        string phoneconvert = StringHelper.normalizePhoneNumber(reqBody.Mobile);
        Date datepicked = Date.valueOf(reqBody.BookingDate);
        Datetime dtPicked = Datetime.newInstance(datepicked.year(), datepicked.month(), datepicked.day(), 0, 0, 0);
        Lead l = new Lead();
        l.LastName = !dealerBooking.Accounts2__r.isEmpty() ? dealerBooking.Accounts2__r[0].Id : null;
        l.SpecifiedTimeTD__c = dealerBooking.Id;
        l.BookingDate__c = Date.valueOf(reqBody.BookingDate);
        l.SpecifiedTimeTD__c = reqBody.BookingTime;
        l.Phone = phoneconvert;
        l.LastName = reqBody.Fullname;
        l.DO_DL_Create__c = dealerBooking.Id;
        l.Product__c = product;
        l.DO_DL_Code__c = reqBody.DoDL;
        l.Email = reqBody.Email;
        l.BookingAddress__c = reqBody.Address;
        l.MobilePhone = phoneconvert;
        l.LicenseA2__c = reqBody.License == '1' ? true : false;

        l.LeadSource = 'Website';
        insert l;
        resBody.leadID = l.Id;
    }
    
    private static void createResponse(String code) {
		createResponse(code, null);
	}

    private static void createResponse(String code, Exception ex) {
		resBody.responseMessage = err.get(code).errMessage;
        
		if (ex != null) {
			resBody.responseMessage += ' - ' + ex.getMessage();
		}
        res.addHeader('Access-Control-Allow-Origin', '*');
        res.addHeader('Content-Type', 'application/json');     
        res.statusCode = err.get(code).statusCode;
        res.responseBody = Blob.valueOf(JSON.Serialize(resBody));
    }
    global class requestBody {
        global string ProductCode{
            get;
            set;
        }
        global string Fullname{
            get;
            set;
        }
        global string Mobile{
            get;
            set;
        }
        global string Email{
            get;
            set;
        }
        global string Address{
            get;
            set;
        }
        global string BookingDate{
            get;
            set;
        }
        global string BookingTime{
            get;
            set;
        }
        global string ServiceType{
            get;
            set;
        }
        global string License{
            get;
            set;
        }
        global string DoDL{
            get;
            set;
        }
    }

    global class responseBody {
        global string responseMessage {
            get;
            set;
        }
        global string leadID {
            get;
            set;
        }
    }
    
    private class errDef {
        Integer statusCode;
        String errMessage;
        errDef (Integer a, String b) {
            statusCode = a;
            errMessage = b;
        }
    }
}