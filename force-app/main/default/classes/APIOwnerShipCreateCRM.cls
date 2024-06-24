@RestResource(urlMapping = '/APIOwnerShipCreateCRM/*')
global class APIOwnerShipCreateCRM {
    // Error code definition : {error code => http status code, error message}
    private static final Map<String, errDef> err = new Map<String, errDef> {
        'SUCCESS'                   	=> new errDef(200, 'Success'),
        'PARAM_NORECORDTYPENAME'  		=> new errDef(400, 'RecordType invalid'),
        'PARAM_NODEALERCODE'  			=> new errDef(400, 'Dealer code required'),
        'PARAM_NOPOINTCODE'       		=> new errDef(400, 'ApplicationPointCode required'),
        'PARAM_NOFRAMENO'       		=> new errDef(400, 'FrameNo required'),
        'PARAM_FRAMENOTFOUND'       	=> new errDef(400, 'FrameNo not founded'),   
        'PARAM_NOORDERIDCRM'       		=> new errDef(400, 'Order ID CRM required'),
        'PARAM_BRANCHNOTFOUND' 			=> new errDef(404, 'Dealer or Point not found'),
        'PARAM_ORDERCRMNOTFOUND' 		=> new errDef(404, 'Order CRM not found'),
        'ERROR_EXCEPTION'           	=> new errDef(500, 'Exception occured')
    };    
    // http request 
    private static RestRequest req = RestContext.request;
    private static RestResponse res = RestContext.response;
    private static requestBody reqBody = new requestBody();
    private static responseBody resBody = new responseBody();
    
    @HttpPost
    global static void run() {
        List<Account> owners = new List<Account>();
        List<Account> internalYNS = new List<Account>();
        List<Order> orderCRM = new List<Order>();
        try {
            reqBody = (requestBody)JSON.deserialize(req.requestBody.toString(), requestBody.class);
            if (String.isBlank(reqBody.DealerCode)) {
                createResponse('PARAM_NODEALERCODE');
           		return;
            }
            if (String.isBlank(reqBody.PointCode)) {
                createResponse('PARAM_NOPOINTCODE');
           		return;
            }
            if (String.isBlank(reqBody.Frameno)) {
                createResponse('PARAM_NOFRAMENO');
           		return;
            }
            if (String.isBlank(reqBody.OrderIDCRM)) {
                createResponse('PARAM_NOORDERIDCRM');
           		return;
            }
            if (Schema.SObjectType.OwnerShip__c.getRecordTypeInfosByDeveloperName().get(reqBody.RecordTypeName) == Null) {
                createResponse('PARAM_NORECORDTYPENAME');
           		return;
            }
            List<Asset> assets = [SELECT Id, Account_Primary_Owner__c FROM Asset WHERE Frame_Number__c =: reqBody.Frameno AND Account_Primary_Owner__c != null];
            if (assets.isEmpty()) {
                createResponse('PARAM_FRAMENOTFOUND');
                return;
            }
            if (String.isBlank(reqBody.CRMConsumerId)  || assets[0].Account_Primary_Owner__c != reqBody.CRMConsumerId) {
                Account accPrimary = createAccountPersonal();
                assets[0].Account_Primary_Owner__c = accPrimary.Id;
                update assets;
                // Assign variable ID account to Property CRM Consumer Id
                reqBody.CRMConsumerId = accPrimary.Id;
            }
			internalYNS = [SELECT ID FROM ACCOUNT 
                           WHERE (DO_DL_Code__c =: reqBody.DealerCode AND RecordTypeId =: RecordTypeHelper.ACCOUNT_BRANCH) 
                           OR (DO_DL_Code__c =: reqBody.PointCode AND RecordTypeId =: RecordTypeHelper.ACCOUNT_DODL) Order BY RecordType.Name];
            if (internalYNS.size() != 2) {
                createResponse('PARAM_BRANCHNOTFOUND');
                return;
            }
            orderCRM  = [SELECT ID FROM ORDER WHERE Id =: reqBody.OrderIDCRM];
            if (orderCRM.isEmpty() && reqBody.RecordTypeName == 'CRM') {
                createResponse('PARAM_ORDERCRMNOTFOUND');
                return;
            }
            
            createOwnerShipping(reqBody, internalYNS, orderCRM);
            // Create a success response.
            createResponse('SUCCESS');
            return;
        }
        catch (Exception ex) {
            createResponse('ERROR_EXCEPTION', ex);
            return;
        }        
    }
    private static Account createAccountPersonal() {
        List<Province__c> provinces = [SELECT Id, (SELECT Id FROM Districts__r
                                                   WHERE Province__r.Province_Code__c =: reqBody.ProvinceCode
                                                   AND District_Code__c  =: reqBody.districtcode) 
                                       FROM Province__c WHERE Province_Code__c =: reqBody.ProvinceCode];
        List<User> usermkt = [SELECT Id FROM User WHERE Profile.Name = 'MKT Manager'];
        Account acc = new Account(
          RecordTypeID = RecordTypeHelper.ACCOUNT_CUSTOMER,
          FirstName = reqBody.firstname,
          LastName =  reqBody.Middlename + reqBody.lastname,
          PersonMailingStreet = reqBody.Mail,
          Province__c = !provinces.isEmpty() ? provinces[0].Id : null,
          District__c =  !provinces.isEmpty() && !provinces[0].Districts__r.isEmpty() ? provinces[0].Districts__r[0].Id : null,
          Gender__c = reqBody.gender,
          Address_No__c = reqBody.Address,
          Is_Primary__c = true,
          PersonEmail = reqBody.Mail,
          PersonHomePhone = reqBody.MobilePhone,
          OwnerId = usermkt[0].Id,
          PersonMobilePhone = reqBody.MobilePhone 
        );
        insert acc;
        return acc;
    }
    private static void createOwnerShipping(requestBody reqBody, List<Account> internalYNS, List<Order> orderCRM) {
        OwnerShip__c membership = new OwnerShip__c();
        membership.RecordTypeId = reqBody.RecordTypeName == 'CRM' ? RecordTypeHelper.CRMOWNERSHIP : RecordTypeHelper.DMSOWNERSHIP;
        membership.CustomerID__c = reqBody.CRMConsumerId;
        membership.Account_Owner__c = reqBody.CRMConsumerId;
        membership.Advisor__c = internalYNS[0].Id;
        membership.Point__c = internalYNS[1].Id; 
        membership.DataType__c = reqBody.DataType;
        membership.Frameno__c = reqBody.Frameno;
        membership.Engine_no__c = reqBody.Engineno;
        membership.Model_Code__c = reqBody.ModelCode;
        membership.Model_Name__c = reqBody.ModelName;
        if (String.isNotBlank(reqBody.Salesdate)) membership.Sales_date__c = Date.valueOf(reqBody.Salesdate);
        membership.First_name__c = reqBody.Firstname;
        membership.Middle_name__c = reqBody.Middlename;
        membership.Last_name__c = reqBody.Lastname;
        membership.Gender__c = reqBody.Gender;
        if (String.isNotBlank(reqBody.Birthday)) membership.Birthday__c = Date.valueOf(reqBody.Birthday);
        membership.Mobile_Phone__c = reqBody.MobilePhone;
        membership.Mail__c = reqBody.Mail;
        membership.Address__c = reqBody.Address;
        membership.Relation_Type__c = reqBody.RelationType;
        if (!orderCRM.isEmpty()) membership.Order_ID__c = reqBody.OrderIDCRM;
        membership.Order_ID_DMS__c  = reqBody.OrderIDDMS;
		membership.Active__c = true;
        insert membership;
    }
    
    private static void createResponse(String code) {
		createResponse(code, null);
	}

    private static void createResponse(String code, Exception ex) {
		resBody.responseMessage = err.get(code).errMessage;
		if (ex != null) {
			resBody.responseMessage += ex.getLineNumber() + ' - ' + ex.getMessage();
		}
        res.addHeader('Access-Control-Allow-Origin', '*');
        res.addHeader('Content-Type', 'application/json');     
        res.statusCode = err.get(code).statusCode;
        res.responseBody = Blob.valueOf(JSON.Serialize(resBody));
    }
    global class requestBody {
        global String CRMConsumerId {
            get;
            set;
        }
        global String RecordTypeName {
            get;
            set;
        }
        global String DealerCode {
            get;
            set;
        }
        global String PointCode {
            get;
            set;
        }
        global String DataType {
            get;
            set;
        }
        global String Frameno {
            get;
            set;
        }
        global String Engineno {
            get;
            set;
        }
        global String ModelCode {
            get;
            set;
        }
        global String ModelName {
            get;
            set;
        }
        global String Salesdate {
            get;
            set;
        }
        global String Firstname {
            get;
            set;
        }
        global String Middlename {
            get;
            set;
        }
        global String Lastname {
            get;
            set;
        }
        global String Gender {
            get;
            set;
        }
        global String Birthday {
            get;
            set;
        }
        global String ProvinceCode {
            get;
            set;
        }
        global String DistrictCode {
            get;
            set;
        }
        global String MobilePhone {
            get;
            set;
        }
        global String Mail {
            get;
            set;
        }
        global String Address {
            get;
            set;
        }
        global String RelationType {
            get;
            set;
        }
        global String OrderIdDMS {
            get;
            set;
        }
        global String OrderIDCRM {
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