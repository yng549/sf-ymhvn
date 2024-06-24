/*******************************************************************************
 ** Class Name: APIServicesRequestCouponData
 ** Description: Web service class to initiate Cross service request coupon process.
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
@RestResource(urlMapping = '/APIServicesRequestCouponData/*')
global class APIServicesRequestCouponData {
    // Error code definition : {error code => http status code, error message}
    private static final Map<String, errDef> err = new Map<String, errDef> {
        'SUCCESS'                   => new errDef(200, 'Success'),
        'PARAM_NOCAMREQUESTNO.'     => new errDef(400, 'Request No. is required'),
        'PARAM_INVALIDPOINTCODE'  	=> new errDef(400, 'Point Code is required'),
        'PARAM_INVALIDDEALERCODE'   => new errDef(400, 'Dealer code is required'),
        'PARAM_INVALIDFRAMENO'      => new errDef(400, 'Frame No is required'),
        'PARAM_FRAMENONOTFOUND'     => new errDef(400, 'Frame No not found'),
        'PARAM_SALEDATE'      		=> new errDef(400, 'Sale Date is required'),
        'PARAM_COUPONCODE'          => new errDef(400, 'Coupon Code is required'),
        'ERROR_EXCEPTION'           => new errDef(500, 'Exception occured')
    };
    // http request 
    private static RestRequest req = RestContext.request;
    private static RestResponse res = RestContext.response;
    private static requestBody reqBody = new requestBody();
    private static responseBody resBody = new responseBody();
    @HttpPost
    global static void run() {
        Service_Request__c serviceWarranty;
        try {
            reqBody = (requestBody)JSON.deserialize(req.requestBody.toString(), requestBody.class);
     		if (String.isBlank(reqBody.RequestNo)) {
                createResponse('PARAM_NOCAMREQUESTNO.');
                return;
            }
            
            // Check parameters - Point
            if (String.isBlank(reqBody.ApplicationPointCode)) {
                createResponse('PARAM_INVALIDPOINTCODE');
                return;
            }
            
            // Check parameters - Delear DO Code
            if (String.isBlank(reqBody.ApplicationDealerCode)) {
                createResponse('PARAM_INVALIDDEALERCODE');
                return;
            }
            
            // Check parameters - FrameNo
            if (String.isBlank(reqBody.FrameNo)) {
                createResponse('PARAM_INVALIDFRAMENO');
                return;
            }
            List<Asset> assets = [SELECT Id FROM Asset WHERE Frame_Number__c =: reqBody.FrameNo];
            if (assets.isEmpty()) {
                createResponse('PARAM_FRAMENONOTFOUND');
                return;
            }
			// Check parameters - Coupon Status Code
            if (String.isBlank(reqBody.CouponApplicationNo)) {
                createResponse('PARAM_COUPONCODE');
                return;
            }
            
            createSWarranty(reqBody, assets);
            // Create a success response.
            createResponse('SUCCESS');
            return;
        }catch(Exception ex) {
            createResponse('ERROR_EXCEPTION', ex);
            return;
        }
    }
    private static Service_Request__c createSWarranty(requestBody reqBody, List<Asset> assets) {
        List<Account> lstPoint = [SELECT ID  FROM Account WHERE DO_DL_Code__c =: reqBody.ApplicationPointCode AND RecordTypeId =: RecordTypeHelper.ACCOUNT_DODL];
        List<Account> lstDealer = [SELECT ID  FROM Account WHERE DO_DL_Code__c =: reqBody.ApplicationDealerCode AND RecordTypeId =: RecordTypeHelper.ACCOUNT_BRANCH];
        Service_Request__c sr = new Service_Request__c();
        sr.Request_No__c = reqBody.CouponApplicationNo;
        if (!lstPoint.isEmpty()) sr.PointCode__c = lstPoint[0].Id;
        if (!lstDealer.isEmpty()) sr.DealerCode__c = lstDealer[0].Id;
        sr.Asset__c = assets[0].Id;
        sr.Frame_No__c = reqBody.FrameNo;
        if (String.isNotBlank(reqBody.SalesDate)) sr.Sale_Date__c = Date.valueOf(reqBody.SalesDate);
        sr.Mileage__c = Decimal.valueOf(reqBody.Mileage);
        sr.CouponLevel__c = reqBody.CouponLevel;
        if (String.isNotBlank(reqBody.CouponServiceDate)) sr.CouponServiceDate__c = Date.valueOf(reqBody.CouponServiceDate);
        sr.CouponApplicationNo__c = reqBody.CouponApplicationNo;
       	sr.RecordTypeId = RecordTypeHelper.COUPON;
        insert sr;
        return sr;
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
        global String RequestNo {
            get;
            set;
        }
        global String ApplicationPointCode {
            get;
            set;
        }
        global String ApplicationDealerCode {
            get;
            set;
        }
        global String CouponApplicationNo {
            get;
            set;
        }
        global String SalesDate {
            get;
            set;
        }
        global String FrameNo {
            get;
            set;
        }
        global String CouponLevel {
            get;
            set;
        }
        global String CouponServiceDate {
            get;
            set;
        }
        global String Mileage {
            get;
            set;
        }
    }

    global class responseBody {
        global string responseMessage {
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