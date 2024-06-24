@RestResource(urlMapping = '/APIOrderCancle/*')
global class APIOrderCancle {
    // Error code definition : {error code => http status code, error message}
    private static final Map<String, errDef> err = new Map<String, errDef> {
        'SUCCESS'                   => new errDef(200, 'Success'),
        'PARAM_ORDERIDINVALID'     	=> new errDef(400, 'Order Id is required'),
        'PARAM_ORDEREMPTY'     		=> new errDef(400, 'Order Id not founded'),
        'PARAM_REASONINVALID'  		=> new errDef(400, 'Reason cancel is required'),
        'ERROR_EXCEPTION'           => new errDef(500, 'Exception occured')
    };
    public static List<string> getPickListValuesIntoList(){
        List<String> pickListValuesList= new List<String>();
		Schema.DescribeFieldResult fieldResult = Order_WebCommercal__c.Reason_Cancel__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry p : ple){
			pickListValuesList.add(p.getValue());
		}     
		return pickListValuesList;
    }
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
            if (String.isBlank(reqBody.reasoncancel)) {
                createResponse('PARAM_REASONINVALID');
                return;
            }
			List<Order_WebCommercal__c> orders = [SELECT ID, Status__c, Cancel_Time__c
                                                  FROM Order_WebCommercal__c
                                                  WHERE Status__c NOT IN ('Hủy thành công', 'Hoàn thành') AND Id =: reqBody.orderid];
            
            // Check existing 
            if (orders.isEmpty()) {
                createResponse('PARAM_ORDEREMPTY');
                return;
            }
            orders[0].Status__c = 'Hủy thành công';
            orders[0].Reason_Cancel__c = getPickListValuesIntoList().contains(reqBody.reasoncancel) ? reqBody.reasoncancel : 'Lý do khác';
            orders[0].Cancel_Time__c  = Datetime.now();
            update orders;
            
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
        global String reasoncancel {
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