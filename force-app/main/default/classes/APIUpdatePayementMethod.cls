@RestResource(urlMapping = '/APIUpdatePayementMethod/*')
global class APIUpdatePayementMethod {
    // Error code definition : {error code => http status code, error message}
    private static final Map<String, errDef> err = new Map<String, errDef> {
        'SUCCESS'                   => new errDef(200, 'Success'),
        'PARAM_ORDERIDINVALID'     	=> new errDef(400, 'Order Id is required'),
        'PARAM_ORDEREMPTY'     		=> new errDef(400, 'Order Id not founded'),
        'PARAM_PAYMENTMETHOD'  		=> new errDef(400, 'Payment Method is required'),
        'ERROR_EXCEPTION'           => new errDef(500, 'Exception occured')
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
     		if (String.isBlank(reqBody.orderid)) {
                createResponse('PARAM_ORDERIDINVALID');
                return;
            }
            if (String.isBlank(reqBody.paymentmethod)) {
                createResponse('PARAM_PAYMENTMETHOD');
                return;
            }
			List<Order_WebCommercal__c> orders = [SELECT ID, payment_method__c
                                                  FROM Order_WebCommercal__c
                                                  WHERE Status__c NOT IN ('Hủy thành công', 'Hoàn thành') AND Id =: reqBody.orderid];
            
            // Check existing 
            if (orders.isEmpty()) {
                createResponse('PARAM_ORDEREMPTY');
                return;
            }
            orders[0].Payment_Status__c = 'Thanh toán thành công';
            orders[0].payment_method__c = reqBody.paymentmethod;
            Update orders;
            
            // Create a success response.
            createResponse('SUCCESS');
            return;
        }catch(Exception ex) {
            system.debug(ex.getLineNumber());
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
			resBody.responseMessage += ' - ' + ex.getMessage();
		}
        res.addHeader('Access-Control-Allow-Origin', '*');
        res.addHeader('Content-Type', 'application/json');     
        res.statusCode = err.get(code).statusCode;
        res.responseBody = Blob.valueOf(JSON.Serialize(resBody));
    }
    global class requestBody {
        global String orderid {
            get;
            set;
        } 
        global String paymentmethod {
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