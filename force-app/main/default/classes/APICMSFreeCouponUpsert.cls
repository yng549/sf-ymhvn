/*******************************************************************************
 ** Class Name: APICMSFreeCouponUpsert
 ** Description: API call out to fcs Website.
 ** Test Class : SyncDMSWarrantyFCSTest
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class APICMSFreeCouponUpsert {
    public class UpsertCouponQueue implements Queueable, Database.AllowsCallouts {
     	List<Id> couponIds;
        public UpsertCouponQueue(List<Id> couponIds){
            this.couponIds = couponIds;
        }
        public void execute(QueueableContext context) {
            if(couponIds.isEmpty()){
                return;
            }
           
            try{
                List<Id> querycouponIds = couponIds;
                Map<String, Schema.SObjectField> couponFieldMap = Free_Coupon__c.sObjectType.getDescribe().fields.getMap();
                List<string> couponSelectFields = new List<String>(couponFieldMap.keySet());
              	couponSelectFields.add('Asset__r.Account_Primary_Owner__c');
                couponSelectFields.add('Asset__r.Account_Primary_Owner__r.Website_ID__c');
                couponSelectFields.add('Asset__r.Mileage__c'); 
                couponSelectFields.add('Asset__r.Frame_Number__c ');
                String couponSoql = 'SELECT ' + String.join(couponSelectFields, ',');
                couponSoql += ' FROM Free_Coupon__c';
                couponSoql += ' WHERE Id IN :querycouponIds';
                List<Free_Coupon__c> coupons = Database.query(couponSoql);
                if(coupons.isEmpty()){
                    return;
                }
               
                List<Free_Coupon__c> updatedCoupons = new List<Free_Coupon__c>();
                List<DevLog__c> logs = new List<DevLog__c>();
                for (Free_Coupon__c c : coupons) {
                    string strMessage = '';
                    Free_Coupon__c updateCoupon = new Free_Coupon__c(Id = c.Id);
                    HttpResponse response = new HttpResponse(); 
                    try {
                        List<Data> couponRequestData = convertCouponCMS(c);
                        system.debug('req' + JSON.serialize(couponRequestData));
                        response = requestApiCMS(JSON.serialize(couponRequestData));
                        system.debug('response' + response);
                        ResponseBody result = (ResponseBody)JSON.deserialize(response.getBody(), ResponseBody.class);
                        String strOutput = JSON.serialize(result);
                        if(response.getStatusCode() == 200) { 
                            if(result.status == '200') {
                                system.debug('success');
                                updateCoupon.Is_Sync_CMS__c = true;
                                updateCoupon.Log_CMS__c = 'Success';
                            }
                        }else {
                            if (result.data != null && result.data.status != null && !result.data.data_required.isEmpty()) 
                            system.debug('data error' + result.data);
                            updateCoupon.Log_CMS__c = result.data.status + '_' + result.data.data_required[0][0];
                        }
                        logError('APICMSFreeCouponUpsert.UpsertCouponQueue', '', trimErrorMessage(JSON.serialize(couponRequestData)), c.Id, c.Name);
                    }catch(Exception e) {
                        updateCoupon.Log_CMS__c = e.getMessage();
                        strMessage = e.getMessage() + ' - ' + e.getLineNumber();
                        system.debug('error' + strMessage);
                        logError('APICMSFreeCouponUpsert.UpsertCouponQueue', strMessage, trimErrorMessage(response.getBody()), c.Id, c.Name);
                    }
                    updatedCoupons.add(updateCoupon);
                }
                update updatedCoupons;
            } catch(Exception e){
                system.debug('error' + e.getMessage() + e.getLineNumber());
                logError('APICMSFreeCouponUpsert.UpsertCouponQueue', e.getMessage() + ' - ' + e.getLineNumber(), JSON.serialize(couponIds), null, '');
            }
        }
    }
    public static List<Data> convertCouponCMS(Free_Coupon__c coupon) {
        Data data = new Data();
        data.free_coupon_id = coupon.ApplicationPointCode__c;
        data.sf_account_id = coupon.Asset__r.Account_Primary_Owner__c;
        data.FrameNo = coupon.Asset__r.Frame_Number__c ;
        data.free_coupon_name = coupon.Name;
        if (String.isNotBlank(String.valueOf(coupon.Asset__r.Mileage__c)))
        data.mileage = String.valueOf(coupon.WarrantyMileage__c);
        data.serial_no = coupon.Serial_No__c;
        if (String.isNotBlank(String.valueOf(coupon.WarrantyEffectiveDate__c)))
        data.warranty_effective_date = String.valueOf(coupon.WarrantyEffectiveDate__c);
        if (String.isNotBlank(String.valueOf(coupon.WarrantyExpiredDate__c)))
        data.warranty_expired_date = String.valueOf(coupon.WarrantyExpiredDate__c);
        data.warranty_mileage = String.valueOf(coupon.WarrantyMileage__c);
        data.warranty_policy_type = coupon.WarrantyPolicyType__c;
        if (String.isNotBlank(String.valueOf(coupon.ServiceDate__c)))
        data.service_date = coupon.WarrantyPolicyType__c;
        data.applied = coupon.Applied__c ? '1' : '0';
        data.web_user_id = coupon.Asset__r.Account_Primary_Owner__r.Website_ID__c;
        data.application_dealer_code = 'RY01A';
        system.debug('data' + data);
        return new List<Data> {data};
    }
    private static String trimErrorMessage(String errorMessage){        
        if(errorMessage.length() > 30000){
            errorMessage = errorMessage.substring(0, 30000);
        }
        return errorMessage;
    }
    private static void logError(String function, String message, String input, String output, String url){
        DevLog__c log = new DevLog__c(
            Function__c = function,
            Url__c = url,
            Input__c = input,
            Output__c = output,
            Message__c = message             
        );
        insert log;
    }
    public class ResponseBody {
        public string status {
            get;
            set;
        }
        public string message {
            get;
            set;
        }
        public detailError data {
            get;
            set;
        }
    }
    public class detailError {
        public string status {get;set;}
        public List<List<string>> data_required {get;set;}
    }
    public static HttpResponse requestApiCMS(String reqBody) {
		Http http = new Http();
		HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:API_CMS/updateFreeCoupon');
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
        request.setBody(reqBody);
        request.setTimeout(120000);
        return http.send(request);
	}
	public class Data {
        public string free_coupon_id;
        public string sf_account_id;
        public string FrameNo;
        public string free_coupon_name;
        public string mileage;
        public string serial_no;
        public string warranty_effective_date;
        public string warranty_expired_date;
        public string warranty_mileage;
        public string warranty_policy_type;
        public string service_date;
        public string applied;
        public string web_user_id;
        public string application_dealer_code;
    }
}