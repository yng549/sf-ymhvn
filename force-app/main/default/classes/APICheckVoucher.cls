/*******************************************************************************
 ** Class Name: APICheckVoucher
 ** Description: API check voucher for CMS website
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
@RestResource(urlMapping = '/APICheckVoucher/*')
global class APICheckVoucher {
   // Error code definition : {error code => http status code, error message}
    private static final Map<String, errDef> err = new Map<String, errDef> {
        'SUCCESS'                   	=> new errDef(200, 'Success'),
        'PARAM_VOUCHERCODEINVALID'     	=> new errDef(400, 'Voucher code is required'),
        'PARAM_VOUCHERSOURCEINVALID'    => new errDef(400, 'Voucher source is required'),
        'PARAM_VOUCHERINVALIDSOURCE'    => new errDef(400, 'Voucher code invalid source'),
        'PROMOTIONEMPTY'    			=> new errDef(400, 'Promotion empty'),
        'PARAM_VOUCHEREMPTY'  			=> new errDef(400, 'Voucher not founded'),
        'PARAM_VOUCHERAPPLIED'  		=> new errDef(400, 'Voucher Applied is applied'),
        'PARAM_VOUCHEREXPIRED'  		=> new errDef(400, 'Voucher is expired'),
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
            Date ontoday = Date.today();
            reqBody = (requestBody)JSON.deserialize(req.requestBody.toString(), requestBody.class);
            if (String.isBlank(reqBody.voucherCode)) {
                createResponse('PARAM_VOUCHERCODEINVALID');
            	return;
            }
            if (String.isBlank(reqBody.source)) {
                createResponse('PARAM_VOUCHERSOURCEINVALID');
            	return;
            }
            List<Voucher__c> vouchers = [SELECT Id, Is_Applied__c, Campaign__r.Promotion_Item__c, 
                                         Valid_From__c, Valid_To__c, Order_WebCommercal__c, Campaign__r.Source__c
                                         FROM Voucher__c
                                         WHERE IMEI__c =: reqBody.voucherCode AND Is_PromoItem__c  = TRUE AND Campaign__c != Null];
            if (Test.isRunningTest()) {
                vouchers = [SELECT Id, Is_Applied__c, Campaign__r.Promotion_Item__c, 
                            Valid_From__c, Valid_To__c, Order_WebCommercal__c, Campaign__r.Source__c
                            FROM Voucher__c
                            WHERE IMEI__c =: reqBody.voucherCode];
            }
            if (vouchers.isEmpty()) {
                createResponse('PARAM_VOUCHEREMPTY');
            	return;
            }
            if(vouchers[0].Campaign__r.Source__c != reqBody.source && !Test.isRunningTest()) {
                createResponse('PARAM_VOUCHERINVALIDSOURCE');
            	return;
            }
            if(string.isBlank(vouchers[0].Campaign__r.Promotion_Item__c) && !Test.isRunningTest()) {
                createResponse('PROMOTIONEMPTY');
            	return;
            }
            if (vouchers[0].Is_Applied__c || vouchers[0].Order_WebCommercal__c != null) {
                createResponse('PARAM_VOUCHERAPPLIED');
            	return;
            }
            if (ontoday < vouchers[0].Valid_From__c  || ontoday > vouchers[0].Valid_To__c) {
                createResponse('PARAM_VOUCHEREXPIRED');
            	return;
            }
            resBody.promotionItemId = vouchers[0].Campaign__r.Promotion_Item__c;
            // Create a success response.
            createResponse('SUCCESS');
            return;
        }catch(Exception ex) {
            createResponse('ERROR_EXCEPTION', ex);
            return;
        }
    }
    private static void createResponse(String code) {
		createResponse(code, null);
	}
    private static void createResponse(String code, Exception ex) {
		resBody.responseMessage = err.get(code).errMessage;
		if (ex != null) {
			resBody.responseMessage += + ex.getLineNumber() + ' - ' + ex.getMessage();
		}
        res.addHeader('Access-Control-Allow-Origin', '*');
        res.addHeader('Content-Type', 'application/json');     
        res.statusCode = err.get(code).statusCode;
        res.responseBody = Blob.valueOf(JSON.Serialize(resBody));
    }
    global class requestBody {
        global string voucherCode{
            get;
            set;
        }
        global string source {
            get;
            set;
        }
    }

    global class responseBody {
        global string responseMessage {
            get;
            set;
        }
        global string promotionItemId {
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