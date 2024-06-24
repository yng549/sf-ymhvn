/*
	This class will get to update model tyoe for MC bike
*/
public class APIGetModelTypeBike implements Queueable, Database.AllowsCallouts {
    private static Map<String, API_DMS__c> settingAPIDMS = API_DMS__c.getAll();
     public static Boolean runningInASandbox {
    	get {
            if (runningInASandbox == null) {
                runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
        	return runningInASandbox;
    	}
    	set;
	}
    private static final string URLDMS = 'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/modeltype';
    public static final String BODYEMPTY = '{}';
    string dealercode;
    public APIGetModelTypeBike(string dealercode) {
        this.dealercode = dealercode;
    }
    public void execute(QueueableContext context) {
        try{
            HttpResponse response = requestPaginationDMS();
            if(response.getStatusCode() == 200) {
                Map<string, Object> dataResult = (Map<string, Object>) JSON.deserializeUntyped(response.getBody());
                String message = String.valueOf(dataResult.get('msg'));
                if (dataResult.get('code') ==  200) {
                    string jsonData = JSON.serialize(dataResult.get('data'));
                    List<ModelType> modelTypes = (List<ModelType>)JSON.deserialize(jsonData, List<ModelType>.class);
                    Map<string, string> externalCodeModelType = new Map<string, string>();
                    for(ModelType mt : modelTypes) {
                        externalCodeModelType.put(mt.ModelCode, mt.ModelType);
                    }
                    List<Product2> products = [SELECT Id, Model_Type__c, ExternalID_DMS__c  FROM Product2 WHERE ExternalID_DMS__c IN: externalCodeModelType.keySet() AND Model_Type__c = NUll];
                    for(Product2 p : products) {
                        p.Model_Type__c = externalCodeModelType.get(p.ExternalID_DMS__c);
                    }
                    update products;
                }
                SyncDMSHelper.logError('modeltype', message, '', SyncDMSHelper.trimErrorMessage(response.getBody()), URLDMS);
            }
        }catch(Exception e) {
             SyncDMSHelper.logError('modeltype', '', '', e.getMessage() + e.getLineNumber(), URLDMS);
        }
    }
    public HttpResponse requestPaginationDMS() {
		Http http = new Http();
		HttpRequest request = new HttpRequest();
		string strURL = runningInASandbox ? 'callout:Api_DMS/streamapi/ymvn1/api/v1/modeltype' + '?dealerCd=' + settingAPIDMS.get(dealercode).DealerCD__c + '&accessToken=' + settingAPIDMS.get(dealercode).AccessToken__c :
        'callout:API_DMS_PROD/streamapi/ymvn1/api/v1/modeltype' + '?dealerCd=' + settingAPIDMS.get(dealercode + 'PROD').DealerCD__c + '&accessToken=' + settingAPIDMS.get(dealercode + 'PROD').AccessToken__c;
        request.setEndpoint(strURL);
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
        request.setBody(BODYEMPTY);
        request.setTimeout(120000);
        return http.send(request);
	}
    public class ModelType {
        public string ModelCode;
        public string ModelType;
    }
}