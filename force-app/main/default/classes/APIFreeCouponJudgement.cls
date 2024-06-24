/*******************************************************************************
 ** Class Name: APIFreeCouponJudgement
 ** Description: Web service class to update request coupon from DMS.
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
@RestResource(urlMapping = '/APIFreeCouponJudgement/*')
global class APIFreeCouponJudgement {
    // Error code definition : {error code => http status code, error message}
    private static final Map<String, errDef> err = new Map<String, errDef> {
        'SUCCESS'                   => new errDef(200, 'Success'),
        'PARAM_NOCAMREQUESTNO.'     => new errDef(400, 'Request No. is required'),
        'PARAM_INVALIDPOINTCODE'  	=> new errDef(400, 'Point Code is required'),
        'PARAM_INVALIDDEALERCODE'   => new errDef(400, 'Dealer code is required'),
        'PARAM_INVALIDFRAMENO'      => new errDef(400, 'Frame No is required'),
        'PARAM_SALEDATE'      		=> new errDef(400, 'Sale Date is required'),
        'PARAM_FAILUREDATE'      	=> new errDef(400, 'Failure Date is required'),
        'PARAM_RECEIPTNO'           => new errDef(400, 'Receipt No is required'),
		'PARAM_RECEIPTDATE'         => new errDef(400, 'Receipt Date is required'),
        'PARAM_SERVICENOFOUND'      => new errDef(404, 'Service Request not found'),
        'PARAM_NOJOBPART'      		=> new errDef(404, 'Jobs/Parts not found'),
        'ERROR_EXCEPTION'           => new errDef(500, 'Exception occured')
    };
    // http request 
    private static RestRequest req = RestContext.request;
    private static RestResponse res = RestContext.response;
    private static requestBody reqBody = new requestBody();
    private static responseBody resBody = new responseBody();
    @HttpPost
    global static void run() {
        List<Service_Request__c> requests = new List<Service_Request__c>();
        List<Symptom_Condition__c> sympconditons;
        Map<String, Job_Part_Detail__c> mapCodePartJobs = new Map<String, Job_Part_Detail__c>();
        try {
            reqBody = (requestBody)JSON.deserialize(req.requestBody.toString(), requestBody.class);
     		if (String.isBlank(reqBody.CouponApplicationNo)) {
                createResponse('PARAM_NOCAMREQUESTNO.');
                return;
            }
			requests = [SELECT ID, Request_No__c FROM Service_Request__c
                        WHERE Request_No__c =: reqBody.CouponApplicationNo AND RecordTypeId =: RecordTypeHelper.COUPON];
            
            // Check existing service request
            if (requests.isEmpty()) {
                createResponse('PARAM_SERVICENOFOUND');
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
            
			// Check parameters - Receipt No
            if (String.isBlank(reqBody.YnspireReceiptNo)) {
                createResponse('PARAM_RECEIPTNO');
                return;            
            }
            // Check parameters - Receipt Date
            if (String.isBlank(reqBody.YnspireReceiptDate)) {
                createResponse('PARAM_RECEIPTDATE');
                return;            
            }
            updateWarrantyRequest(requests[0], reqBody);
            // Create a success response.
            createResponse('SUCCESS');
            return;
        }catch(Exception ex) {
            system.debug(ex.getLineNumber());
            createResponse('ERROR_EXCEPTION', ex);
            return;
        }
    }
    private static void updateWarrantyRequest(Service_Request__c warrantyQuery, requestBody reqbody) {
        List<Account> lstPointCode = [SELECT Id, DO_DL_Code__c
                                      FROM Account
                                      WHERE RecordTypeId =: RecordTypeHelper.ACCOUNT_DODL AND DO_DL_Code__c =: reqbody.ApplicationPointCode];
        List<Account> lstDealerCode = [SELECT Id, DO_DL_Code__c 
                                        FROM Account
                                        WHERE RecordTypeId =: RecordTypeHelper.ACCOUNT_BRANCH AND DO_DL_Code__c =: reqbody.ApplicationDealerCode];
        Service_Request__c reqCoupon = new Service_Request__c(Id = warrantyQuery.Id);
        reqCoupon.Request_No__c = reqbody.CouponApplicationNo;
        reqCoupon.CouponApplicationNo__c = reqbody.CouponApplicationNo;
        reqCoupon.YnspireReceiptNo__c = reqbody.YnspireReceiptNo;
        reqCoupon.YnspireReceiptDate__c = Date.valueOf(reqbody.YnspireReceiptDate);
        if (!lstPointCode.isEmpty()) reqCoupon.PointCode__c = lstPointCode[0].Id;
		if (!lstDealerCode.isEmpty()) reqCoupon.DealerCode__c = lstDealerCode[0].Id;
        reqCoupon.CouponStatusCode__c = reqbody.YnspireReceiptNo;
        reqCoupon.CouponStatusName__c = reqbody.CouponStatusName;
        if (String.isNotBlank(reqbody.PaymentLaborAmount)) reqCoupon.Payment_Labor_Total_Amount__c = Decimal.valueOf(reqbody.PaymentLaborAmount);
        reqCoupon.Frame_No__c = reqbody.FrameNo;
        reqCoupon.CouponLevel__c = reqbody.CouponLevel;
        reqCoupon.CouponServiceDate__c = Date.valueOf(reqbody.CouponServiceDate);
        if (String.isNotBlank(reqbody.Mileage)) reqCoupon.Mileage__c = Decimal.valueOf(reqbody.Mileage);
        reqCoupon.AccountingMonth__c = reqbody.AccountingMonth;
        reqCoupon.CouponAdujudicationMessage__c = reqbody.CouponAdujudicationMessage;
        update reqCoupon;
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
        global String CouponApplicationNo {
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
		global String YnspireReceiptNo {
            get;
            set;
        }
		global String YnspireReceiptDate {
            get;
            set;
        }
		global String CouponStatusCode {
            get;
            set;
        }
		global String CouponStatusName {
            get;
            set;
        }
        global String PaymentLaborAmount {
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
		global String AccountingMonth {
            get;
            set;
        }
        global String CouponAdujudicationMessage {
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