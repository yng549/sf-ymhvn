/*******************************************************************************
 ** Class Name: APIServicesRequestData
 ** Description: Web service class to initiate Cross service request process.
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
@RestResource(urlMapping = '/APIServicesRequestWarrantyData/*')
global class APIServicesRequestData {
    // Error code definition : {error code => http status code, error message}
    private static final Map<String, errDef> err = new Map<String, errDef> {
        'SUCCESS'                   => new errDef(200, 'Success'),
        'PARAM_NOCAMREQUESTNO'     	=> new errDef(400, 'Request No is required'),
        'PARAM_INVALIDPOINTCODE'  	=> new errDef(400, 'Point Code is required'),
        'PARAM_INVALIDDEALERCODE'   => new errDef(400, 'Dealer code is required'),
        'PARAM_INVALIDFRAMENO'      => new errDef(400, 'Frame No is required'),
        'PARAM_FRAMENONOTFOUND'     => new errDef(400, 'Frame No not found'),
        'PARAM_SALEDATE'      		=> new errDef(400, 'Sale Date is required'),
        'PARAM_INVALIDSYMCON'       => new errDef(400, 'Sympton/Condition is required'),
        'PARAM_NOSYMCON'       		=> new errDef(400, 'Sympton/Condition not found'),
        'PARAM_NOORDER'       		=> new errDef(400, 'Order not found'),
        'ERROR_EXCEPTION'           => new errDef(500, 'Exception occured')
    };
    // http request 
    private static RestRequest req = RestContext.request;
    private static RestResponse res = RestContext.response;
    private static requestBody reqBody = new requestBody();
    private static responseBody resBody = new responseBody();
    @HttpPost
    global static void run() {
        List<Symptom_Condition__c> sympconditons;
        Map<String, Job_Part_Detail__c> junctionServices = new Map<String, Job_Part_Detail__c>();
        Service_Request__c serviceWarranty;
        try {
             reqBody = (requestBody)JSON.deserialize(req.requestBody.toString(), requestBody.class);
            // Check parameters - Request No
            if (String.isBlank(reqBody.RequestNo)) {
                createResponse('PARAM_NOCAMREQUESTNO');
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
            // Querying asset based on frame no
            List<Asset> assets = [SELECT Id, Product2.Bike_cc__c FROM Asset WHERE Frame_Number__c =: reqBody.FrameNo];
            
            if (assets.isEmpty()) {
                createResponse('PARAM_FRAMENONOTFOUND');
                return;
            }
            // Select range bike
            string ccRange = assets[0].Product2.Bike_cc__c;
            // Check parameters - Sales Date
            if (String.isBlank(reqBody.SalesDate)) {
                createResponse('PARAM_SALEDATE');
                return;            
            }
            
            // Check parameters - Sympton/Condition
            if ((String.isBlank(reqBody.SymptomCode) && string.isBlank(reqBody.SectionCode))|| String.isBlank(reqBody.ConditionCode)) {
                createResponse('PARAM_INVALIDSYMCON');
            }
            // Querying the sympton conditon based on Sympton/Condition code in request.
            sympconditons = [SELECT Id, Name 
                             FROM Symptom_Condition__c
                             WHERE (Name =: reqBody.SymptomCode AND Section_Code__c =: reqBody.SectionCode AND RecordTypeId =: RecordTypeHelper.SYMPTON)
                             OR (Name =: reqBody.ConditionCode AND RecordTypeId =: RecordTypeHelper.CONDITION)
                             ORDER BY RecordType.Name];
            if (sympconditons.size() != 2) {
                createResponse('PARAM_NOSYMCON');
                return;
            }
            // Insert warranty request from body request
			serviceWarranty = createSWarranty(reqBody, sympconditons, assets);
            
            // Part-Code is repaired
            Map<String, Object> partcodes = new Map<String, Object>();
            
            // Service-Job is repaired
            Map<String, Object> serviceJobs = new Map<String, Object>();
            
            for (JobDetail job : reqBody.JobDetails) {
                serviceJobs.put(job.JobCode, job);
            }
            for (PartsDetail part : reqBody.PartsDetails) {
                partcodes.put(part.ExchangePartNo, part);
            }
            // Querying the product based on product code in request.
            List<Product2> products = [SELECT Id, ProductCode,RecordTypeId
                                       FROM Product2
                                       WHERE (ProductCode IN: serviceJobs.keySet() AND RecordTypeId =: RecordTypeHelper.SV_JOB AND Bike_cc__c =: ccRange) OR
                                       (ProductCode IN: partcodes.keySet() AND RecordTypeId =: RecordTypeHelper.PRODUCT_PCA)];
            for (Product2 product : products) {
                Job_Part_Detail__c jobpart = new Job_Part_Detail__c();
                jobpart.Service_Request__c = serviceWarranty.Id;
                jobpart.Product__c = product.Id;
                if (product.RecordTypeId == RecordTypeHelper.SV_JOB) {
                    jobpart.RecordTypeId =  RecordTypeHelper.JOB;
                }else {
                    PartsDetail part = (PartsDetail)partcodes.get(product.ProductCode);
                    jobpart.Exchange_Part_Quantity__c = Integer.valueOf(part.ExchangePartQuantity);
                    jobpart.RecordTypeId =  RecordTypeHelper.PART;
                }
                junctionServices.put(product.ProductCode, jobpart);
            }
            // Insert part-job junction from part-job codes
            insert junctionServices.values();
            
			// Update primary failed part No            
            if (String.isNotBlank(reqBody.PrimaryFailedPartNo) && junctionServices.containsKey(reqBody.PrimaryFailedPartNo)) {
                Service_Request__c requestUpdate = new Service_Request__c(Id = serviceWarranty.Id,
                                                                          PrimaryFailedPartNo__c = junctionServices.get(reqBody.PrimaryFailedPartNo).Id);
                update requestUpdate;
            }
            // Create a success response.
            createResponse('SUCCESS');
            return;
        }catch(Exception ex) {
            createResponse('ERROR_EXCEPTION', ex);
            return;
        }
    }
    private static Service_Request__c createSWarranty(requestBody reqBody, List<Symptom_Condition__c> sympconditons, List<Asset> assets) {
        List<Account> lstPoint = [SELECT ID  FROM Account WHERE DO_DL_Code__c =: reqBody.ApplicationPointCode  AND RecordTypeId =: RecordTypeHelper.ACCOUNT_DODL ];
        List<Account> lstDealer = [SELECT ID  FROM Account WHERE DO_DL_Code__c =: reqBody.ApplicationDealerCode AND RecordTypeId =: RecordTypeHelper.ACCOUNT_BRANCH];
        List<Order> orders = [SELECT Id 
                              FROM Order
                              WHERE ID = :reqBody.OrderCRMNo];
        Service_Request__c warranty = new Service_Request__c();
        if (!lstPoint.isEmpty()) warranty.PointCode__c = lstPoint[0].Id;
        if (!lstDealer.isEmpty()) warranty.DealerCode__c = lstDealer[0].Id;
        warranty.Request_No__c = reqBody.RequestNo;
        warranty.Authorized_No__c = reqBody.AuthorizationNo;
        if (String.isNotBlank(reqBody.ApplicationDate)) warranty.ApplicationDate__c = Date.valueOf(reqBody.ApplicationDate);
        warranty.Frame_No__c = reqBody.FrameNo;
        warranty.Asset__c = assets[0].Id;
        warranty.Sale_Date__c = Date.valueOf(reqBody.SalesDate);
        if (String.isNotBlank(reqBody.FailureDate)) warranty.FailureDate__c = Date.valueOf(reqBody.FailureDate);
        if (String.isNotBlank(reqBody.Mileage)) warranty.Mileage__c = Decimal.valueOf(reqBody.Mileage);
        warranty.Condition__c = sympconditons[0].Id;
        warranty.Symptom__c = sympconditons[1].Id;
        warranty.Problem_Comment__c = reqBody.ProblemDescription;
        warranty.Reason_Comment__c = reqBody.CauseDescription;
        warranty.Repair_Comment__c	= reqBody.RepairDescription;
        warranty.Dealer_Description__c = reqBody.DealerComment;
        warranty.ClaimType__c = reqBody.ClaimType;
        warranty.Campaign_No__c = reqBody.CampaignNumber;
        warranty.ClaimApplicationNo__c = reqBody.ClaimApplicationNo;
        if (String.isNotBlank(reqBody.RepairCompletionDate)) warranty.RepairCompletionDate__c = Date.valueOf(reqBody.RepairCompletionDate);
        if(!orders.isEmpty()) warranty.Order__c = orders[0].Id;
       	warranty.RecordTypeId = RecordTypeHelper.WARRANTY;
        insert warranty;
        return warranty;
    }
    private static void createResponse(String code) {
		createResponse(code, null);
	}

    private static void createResponse(String code, Exception ex) {
		resBody.responseMessage = err.get(code).errMessage;
		if (ex != null) {
			resBody.responseMessage += ex.getLineNumber()  + ' - ' + ex.getMessage();
		}
        res.addHeader('Access-Control-Allow-Origin', '*');
        res.addHeader('Content-Type', 'application/json');     
        res.statusCode = err.get(code).statusCode;
        res.responseBody = Blob.valueOf(JSON.Serialize(resBody));
    }
    global class requestBody {
        global String SectionCode {
            get;
            set;
        }
        global String RequestNo {
            get;
            set;
        }
        global String ApplicationPointCode {
            get;
            set;
        }
        global String AuthorizationNo {
            get;
            set;
        }
        global String ApplicationDealerCode {
            get;
            set;
        }
        global String ApplicationDate {
            get;
            set;
        }
        global String FrameNo {
            get;
            set;
        }
        global String SalesDate {
            get;
            set;
        }
        global String FailureDate  {
            get;
            set;
        }
        global String Mileage {
            get;
            set;
        }
        global String SymptomCode {
            get;
            set;
        }
        global String ConditionCode {
            get;
            set;
        }
        global String ProblemDescription {
            get;
            set;
        }
        global String CauseDescription {
            get;
            set;
        }
        global String RepairDescription {
            get;
            set;
        }
        global String DealerComment {
            get;
            set;
        }
        global String PrimaryFailedPartNo {
            get;
            set;
        }
        global String CampaignNumber {
            get;
            set;
        }
        global String ClaimType {
            get;
            set;
        }
        global String ClaimApplicationNo {
            get;
            set;
        }
		global String RepairCompletionDate {
            get;
            set;
        }
        global List<JobDetail> JobDetails {
            get;
            set;
        }
        global List<PartsDetail> PartsDetails {
            get;
            set;
        }
        global String OrderCRMNo {
            get;
            set;
        }
    }

    global class JobDetail {
        global String JobCode {
            get;
            set;
        }
    }
    global class PartsDetail {
        global String ExchangePartNo {
            get;
            set;
        }
        global String ExchangePartQuantity {
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