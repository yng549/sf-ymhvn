/*******************************************************************************
 ** Class Name: APICheckingAccountWebsite
 ** Description: This class which accessed from call out CMS system. After that found record's account CRM existing?
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
@RestResource(urlMapping = '/APICheckingAccountWebsite/*')
global without sharing class APICheckingAccountWebsite {
  // Error code definition : {error code => http status code, error message}
    private static final Map<String, errDef> err = new Map<String, errDef> {
        'SUCCESS'                   	=> new errDef(200, 'Success'),
        'PARAM_PHONEINVALID.'     		=> new errDef(400, 'Number Phone is required'),
        'PARAM_WEBSITEIDVALID'     		=> new errDef(400, 'Website ID & Workshop is required'),
        'PARAM_ADDRESSINVALID'     		=> new errDef(400, 'Address is required'),
        'PARAM_ADDRESSEMPTY'     		=> new errDef(400, 'Address not founded'),
        'PARAM_ACCOUNTEMPTY'  			=> new errDef(400, 'Account not found'),
        'ERROR_EXCEPTION'           	=> new errDef(500, 'Exception occured')
    };
    // http request 
    private static RestRequest req = RestContext.request;
    private static RestResponse res = RestContext.response;
    private static requestBody reqBody = new requestBody();
    private static responseBody resBody = new responseBody();
    private static Account actPrimary = new Account();
    private static List<Free_Coupon__c> lstCoupons;
    @HttpPost
    global static void run() {
        try {
            reqBody = (requestBody)JSON.deserialize(req.requestBody.toString(), requestBody.class);
            lstCoupons = new List<Free_Coupon__c>();
            if (String.isBlank(reqBody.phoneNo)) {
                createResponse('PARAM_PHONEINVALID');
                return;
            }
            if (String.isBlank(reqBody.websiteID) && String.isBlank(reqBody.workshopID)) {
                createResponse('PARAM_WEBSITEIDVALID');
                return;
            }
         	reqBody.phoneNo = normalizePhoneNumber(reqBody.phoneNo);
            
			List<Account> actsPrimary = [SELECT Id, Province__r.Name, Province__r.Province_Code__c, Applied_Promotion__c,
                                         District__r.District_Code__c, District__r.Name, Address_No__c, Is_Membership__c, Website_ID__c
                                         FROM Account
                                         WHERE PersonMobilePhone =: reqBody.phoneNo AND Is_Primary__c = True];
            
            if (actsPrimary.isEmpty()) {
                actsPrimary = new List<Account> {createAccountPersonal()};
            }else {
                if(string.isNotBlank(reqBody.workshopID))
                actsPrimary[0].Workshop_ID__c = reqBody.workshopID;
                if(string.isNotBlank(reqBody.websiteID))
				actsPrimary[0].Website_ID__c = reqBody.websiteID;
                update actsPrimary;
            }
            
            actPrimary = actsPrimary[0];
            
            for (Asset ast : [SELECT Id, (SELECT ID, Asset__r.Frame_Number__c, WarrantyExpiredDate__c, WarrantyEffectiveDate__c,
                                          WarrantyPolicyType__c, CouponCategoryLevel__c, ServiceDate__c, Mileage__c, Coupon_Application_No__c 
                                          FROM Free_Coupons__r)
                              FROM Asset WHERE Account_Primary_Owner__c =: actsPrimary[0].Id]) {
                if (!ast.Free_Coupons__r.isEmpty()) {
                    lstCoupons.addAll(ast.Free_Coupons__r);
                }
            }
            // Create a success response.
            createResponse('SUCCESS');
            return;
        }catch(Exception ex) {
            createResponse('ERROR_EXCEPTION', ex);
            return;
        }
    }
    public static String normalizePhoneNumber(String phone){
        if(String.isBlank(phone)){
            return '';
        }

        if(phone.startsWith('0')) {
            phone = phone.replaceFirst('0', '+84');
        } else if (phone.startsWith('84')){
            phone = '+' + phone;
        } else if (!phone.startsWith('+84')) {
            phone = '+84' + phone;
        }

        return phone;
    }

    private static Account createAccountPersonal() {
        List<Province__c> provinces = [SELECT Id, (SELECT Id FROM Districts__r
                                                   WHERE Province__r.Province_Code__c =: reqBody.provincecode
                                                   AND District_Code__c  =: reqBody.districtcode) 
                                       FROM Province__c WHERE Province_Code__c =: reqBody.provincecode];
          List<User> usermkt = [SELECT Id FROM User WHERE Profile.Name = 'MKT Manager'];
          Account acc = new Account(
          RecordTypeID = RecordTypeHelper.ACCOUNT_CUSTOMER ,
          FirstName = reqBody.firstname,
          LastName = reqBody.lastname,
          Province__c = !provinces.isEmpty() ? provinces[0].Id : null,
          District__c =  !provinces.isEmpty() && !provinces[0].Districts__r.isEmpty() ? provinces[0].Districts__r[0].Id : null,
          Gender__c = reqBody.gender,
          Address_No__c = reqBody.addressno,
          Website_ID__c = reqBody.websiteID,
          Workshop_ID__c = reqBody.workshopID,
          Is_Primary__c = true,
          PersonEmail = reqBody.email,
          PersonHomePhone = reqBody.phoneNo,
          OwnerId = usermkt[0].Id,
          Applied_Promotion__c = false,
          PersonMobilePhone = reqBody.phoneNo 
        );
        insert acc;
        acc = [SELECT Id, Province__r.Province_Code__c, District__r.District_Code__c,
               Province__r.Name, District__r.Name, Address_No__c, Is_Membership__c, 
               Workshop_ID__c, Website_ID__c, Applied_Promotion__c
               FROM Account
               WHERE Id =: acc.Id];
        return acc;
    }
    private static Data createDataRespone(Account acc, List<Free_Coupon__c> lstCoupons) {
        Data data = new Data();
        data.accountId = acc.Id;
        data.membership = String.valueOf(acc.Is_Membership__c);
        data.address = acc.Address_No__c;
        data.Isappliedpromo = acc.Applied_Promotion__c;
        data.province = acc.Province__r.Name;
        data.provincecode = acc.Province__r.Province_Code__c;
        data.district = acc.District__r.Name;
        data.districtcode = acc.District__r.District_Code__c;
        List<UnitCoupon> unitcoupons = new List<UnitCoupon>();
        for (Free_Coupon__c copItem : lstCoupons) {
            UnitCoupon unitc = new UnitCoupon();
            unitc.imei = copItem.Coupon_Application_No__c;
            unitc.FrameNo = copItem.Asset__r.Frame_Number__c;
            unitc.WarrantyEffectiveDate = String.valueOf(copItem.WarrantyEffectiveDate__c);
            unitc.WarrantyExpiredDate = String.valueOf(copItem.WarrantyExpiredDate__c);
            unitc.WarrantyPolicyType = copItem.WarrantyPolicyType__c;
            unitc.CouponCategoryLevel = copItem.CouponCategoryLevel__c;
            unitc.ServiceDate = String.valueOf(copItem.ServiceDate__c);
            unitc.Mileage = String.valueOf(copItem.Mileage__c);
            unitcoupons.add(unitc);
        }
        data.unitcoupons = unitcoupons;
        return data;
    }
    private static void createResponse(String code) {
		createResponse(code, null);
	}

    private static void createResponse(String code, Exception ex) {
		resBody.responseMessage = err.get(code).errMessage;
        if (String.isNotBlank(actPrimary.Id)) {
            resBody.data = createDataRespone(actPrimary, lstCoupons);
        }
        
		if (ex != null) {
			resBody.responseMessage += ex.getLineNumber() +  ' - ' + ex.getMessage();
		}
        res.addHeader('Access-Control-Allow-Origin', '*');
        res.addHeader('Content-Type', 'application/json');
        res.statusCode = err.get(code).statusCode;
        res.responseBody = Blob.valueOf(JSON.Serialize(resBody));
    }
    global class requestBody {
        global string phoneNo{
            get;
            set;
        }
        global string districtcode{
            get;
            set;
        }
        global string provincecode{
            get;
            set;
        }
        global string addressno{
            get;
            set;
        }
        global string gender{
            get;
            set;
        }
        global string firstname{
            get;
            set;
        }
        global string lastname{
            get;
            set;
        }
        global string email{
            get;
            set;
        }
        global string workshopID{
            get;
            set;
        }
        global string websiteID{
            get;
            set;
        }
    }
	global class Data {
        global boolean Isappliedpromo {
            get;
            set;
        }
        global string accountId {
            get;
            set;
        }
        global string membership {
            get;
            set;
        }
        global string address {
            get;
            set;
        }
        global string province {
            get;
            set;
        }
        global string district {
            get;
            set;
        }
        global string districtcode{
            get;
            set;
        }
        global string provincecode{
            get;
            set;
        }
        global List<UnitCoupon> unitcoupons {
            get;
            set;
        }
    }
    global class UnitCoupon {
        global String FrameNo {
            get;
            set;
        }
        global String imei {
            get;
            set;
        }
        global String WarrantyEffectiveDate {
            get;
            set;
        }
        global String WarrantyExpiredDate {
            get;
            set;
        }
        global String WarrantyMileage {
            get;
            set;
        }
        global String WarrantyPolicyType {
            get;
            set;
        }
        global String CouponCategoryLevel {
            get;
            set;
        }
        
        global String ServiceDate {
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
        global Data data {
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