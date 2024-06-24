/**
 * Controller: CheckOrderWarrantyLastModified
 * Check DMS system frameno warranty last modified
 * @created: 2022/10/20 THL
 * @modified: 2021/03/20 THL
 */
public class CheckOrderWarrantyLastModified {
    private static Map<String, API_DMS__c> settingAPIDMS = API_DMS__c.getAll();
    public static final String BODYEMPTY = '{}';
    private static final String APIENDPOINT = 'framenowarranty';
    public static Boolean runningInASandbox {
    	get {
            if (runningInASandbox == null) {
                runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
        	return runningInASandbox;
    	}
    	set;
	}
	@AuraEnabled
    public static ApiResponse getInitialData(Id recordId) {
        ApiResponse apiResponse = new ApiResponse(true);
        apiResponse.result = validateRequestData(recordId);
        return apiResponse;
    }
    
    private static ValidateResult validateRequestData(Id recordId) {
        ValidateResult result = new ValidateResult();
		List<Asset> assets = [SELECT ID, Frame_Number__c, DO_DL_Code__c
                              FROM Asset
                              WHERE Id =: recordId];
        
        if(string.isBlank(assets[0].Frame_Number__c)) {
            throw new AuraHandledException('Frameno is blank');
        }
        result.assetInfo = assets[0];
        return result;
    }
    @AuraEnabled
    public static ApiResponse checkFrameNoDMS(Asset datainit)  {
        ApiResponse apiResponse = new ApiResponse(true);
        try {
            string frameno = datainit.Frame_Number__c;
            // Subcrible topic FCM
            HttpResponse response = calloutWarrantyFrameno(APIENDPOINT, BODYEMPTY, frameno, datainit.DO_DL_Code__c);
            if(response.getStatusCode() == 200) {
                Map<string, Object> dataResult = (Map<string, Object>) JSON.deserializeUntyped(response.getBody());
                DataResponse data = (DataResponse)Json.deserialize(response.getBody(), DataResponse.class);
                // Get successfully status
                if(dataResult.get('code') ==  200) {
                    string jsonData = JSON.serialize(dataResult.get('data'));
                    List<SObjectAPIDMSRespone.WarrantyServiceRequest> warantyRequests = (List<SObjectAPIDMSRespone.WarrantyServiceRequest>)JSON.deserialize(jsonData, 
                                                                                                                                                            List<SObjectAPIDMSRespone.WarrantyServiceRequest>.class);
                    SyncDMSWarrantyFCS.handlerCreateFCSWarranty(warantyRequests);
                }
                apiResponse.result = data.msg;
            }else {
                apiResponse.success = false;
                apiResponse.addError('There was an unknown error while processing. Contact with administrator');
            }
        }catch (Exception e) {
            apiResponse.success = false;
            apiResponse.addError(e.getMessage());
        }
        return apiResponse;
    }
    
    public static HttpResponse calloutWarrantyFrameno(String apiname, String reqBody, String frameNo, string DealerCode) {
		Http http = new Http();
		HttpRequest request = new HttpRequest();
        string strURL = runningInASandbox ? 'callout:Api_DMS/streamapi/ymvn1/api/v1/' + apiname + '?dealerCd=' + settingAPIDMS.get(DealerCode).DealerCD__c + '&accessToken=' + settingAPIDMS.get(DealerCode).AccessToken__c
            			: 'callout:API_DMS_PROD/streamapi/ymvn1/api/v1/' + apiname + '?dealerCd=' + settingAPIDMS.get(DealerCode + 'PROD').DealerCD__c + '&accessToken=' + settingAPIDMS.get(DealerCode + 'PROD').AccessToken__c;
        if(Test.isRunningTest()) {
            frameNo = 'RLCS1FC10DY028886';
        }
        strURL += '&frameNo=' + frameNo;
        request.setEndpoint(strURL);
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
        request.setBody(reqBody);
        request.setTimeout(120000);
        return http.send(request);
	}
    public class DataResponse {
        @AuraEnabled
        public string msg;
    }
    public class ValidateResult {
        @AuraEnabled
        public Asset assetInfo {get;set;}
    }
}