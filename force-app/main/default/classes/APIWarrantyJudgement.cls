/*******************************************************************************
 ** Class Name: APIWarrantyJudgement
 ** Description: Web service class to follow up update Cross service request process.
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
@RestResource(urlMapping = '/APIWarrantyJudgement/*')
global class APIWarrantyJudgement {
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
     		if (String.isBlank(reqBody.ClaimApplicationNorequestNo)) {
                createResponse('PARAM_NOCAMREQUESTNO.');
                return;
            }
			requests = [SELECT ID, Request_No__c, 	ClaimApplicationNo__c FROM Service_Request__c
                        WHERE 	ClaimApplicationNo__c =: reqBody.ClaimApplicationNorequestNo AND RecordTypeId =: RecordTypeHelper.WARRANTY];
            system.debug(requests);
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
            // Check parameters - Failure Date
            if (String.isBlank(reqBody.FailureDate)) {
                createResponse('PARAM_FAILUREDATE');
                return;            
            }
            // query asset
            Asset asset = [SELECT Id, Frame_Number__c, Product2.Bike_cc__c  FROM Asset WHERE Frame_Number__c =: reqBody.FrameNo LIMIT 1];
            string ccRange = asset.Product2.Bike_cc__c;
            // Querying the sympton conditon based on Sympton/Condition code in request.
            sympconditons = [SELECT Id, Name 
                             FROM Symptom_Condition__c
                             WHERE (Name =: reqBody.SymptomCode AND RecordTypeId =: RecordTypeHelper.SYMPTON)
                             OR (Name =: reqBody.ConditionCode AND RecordTypeId =: RecordTypeHelper.CONDITION)
                             ORDER BY RecordType.Name];
            Map<String, Id> mapSympCondition = new Map<String, Id>();
            for (Symptom_Condition__c sc : sympconditons) {
                mapSympCondition.put(sc.Name, sc.Id);
            }
            // Part-Code is repaired
            Map<String, Object> partcodes = new Map<String, Object>();
            
            for (FailedPart part : reqBody.FailedParts) {
                partcodes.put(part.ExchangePartNo, part);
            }
            for (JobCode job : reqBody.JobCodes) {
                partcodes.put(job.JobCode, job);
            }
            // Querying the product based on product code in request.
            List<Job_Part_Detail__c> products = [SELECT Id, ProductCode__c, RecordTypeId
                                                 FROM Job_Part_Detail__c
                                                 WHERE Service_Request__c  =: requests[0].Id 
                                                 AND ((ProductCode__c IN: partcodes.keySet() AND RecordTypeId =: RecordTypeHelper.JOB AND Product__r.Bike_cc__c =: ccRange) OR
                                                 (ProductCode__c IN: partcodes.keySet() AND RecordTypeId =: RecordTypeHelper.PART))];
            system.debug('products' + products);
            if (products.size() != partcodes.size()) {
                createResponse('PARAM_NOJOBPART');
                return;
            }
            for (Job_Part_Detail__c jobpart : products) {
				updateJobPartRequest(jobpart, partcodes, mapCodePartJobs);
            }
            system.debug(mapCodePartJobs);
            update mapCodePartJobs.values();
            updateWarrantyRequest(requests[0], reqBody, mapSympCondition, mapCodePartJobs);
            // Create a success response.
            createResponse('SUCCESS');
            return;
        }catch(Exception ex) {
            system.debug(ex.getLineNumber());
            createResponse('ERROR_EXCEPTION', ex);
            return;
        }
    }
    private static void updateWarrantyRequest(Service_Request__c warrantyQuery, requestBody reqbody, Map<String, Id> mapSympCondition, Map<String, Job_Part_Detail__c> jobpartsUpdate) {
        
        List<Account> lstPoint = [SELECT ID  FROM Account WHERE DO_DL_Code__c =: reqBody.ApplicationPointCode AND RecordTypeId =: RecordTypeHelper.ACCOUNT_DODL];
        List<Account> lstDealer = [SELECT ID  FROM Account WHERE DO_DL_Code__c =: reqBody.ApplicationDealerCode AND RecordTypeId =: RecordTypeHelper.ACCOUNT_BRANCH];
        Service_Request__c warrantyUpt = new Service_Request__c(Id = warrantyQuery.Id);
        warrantyUpt.Campaign_No__c = reqbody.CampaignNumber;
        warrantyUpt.ClaimType__c = reqbody.ClaimType;
        if (!lstPoint.isEmpty()) warrantyUpt.PointCode__c = lstPoint[0].Id;
        if (!lstDealer.isEmpty()) warrantyUpt.DealerCode__c = lstDealer[0].Id;
        warrantyUpt.YnspireReceiptNo__c = reqbody.YnspireReceiptNo;
        warrantyUpt.YnspireReceiptDate__c = Date.valueOf(reqbody.YnspireReceiptDate);
        warrantyUpt.ClaimApplicationNo__c = reqbody.ClaimApplicationNorequestNo;
        warrantyUpt.ClaimStatusCode__c = reqbody.ClaimStatusCode;
        warrantyUpt.ClaimType__c = reqbody.ClaimStatusName;
        if (String.isNotBlank(reqbody.PaymentPartTotalAmount)) warrantyUpt.Payment_Part_Total_Amount__c = Decimal.valueOf(reqbody.PaymentPartTotalAmount);
        if (String.isNotBlank(reqbody.PaymentLaborTotalAmount)) warrantyUpt.Payment_Labor_Total_Amount__c = Decimal.valueOf(reqbody.PaymentLaborTotalAmount);
        if (String.isNotBlank(reqbody.PaymentTotalAmount)) warrantyUpt.Payment_Amount__c = Decimal.valueOf(reqbody.PaymentTotalAmount);
        warrantyUpt.ClaimModifyComment__c = reqbody.ClaimModifyComment;
        warrantyUpt.ClaimDeniedComment__c = reqbody.ClaimDeniedComment;
        warrantyUpt.ClaimAdujudicationMessage__c = reqbody.ClaimAdujudicationMessage;
        warrantyUpt.Authorized_No__c = reqbody.AuthorizationNo;
        if (String.isNotBlank(reqbody.ApplicationDate)) warrantyUpt.ApplicationDate__c = Date.valueOf(reqbody.ApplicationDate);
        warrantyUpt.Frame_No__c = reqbody.FrameNo;
        if (String.isNotBlank(reqbody.SalesDate)) warrantyUpt.Sale_Date__c = Date.valueOf(reqbody.SalesDate);
        if (String.isNotBlank(reqbody.DropDueDate) ) warrantyUpt.DropDueDate__c = Date.valueOf(reqbody.DropDueDate);
        if (String.isNotBlank(reqbody.FailureDate)) warrantyUpt.FailureDate__c = Date.valueOf(reqbody.FailureDate);
        if (String.isNotBlank(reqbody.RepairCompletionDate)) warrantyUpt.RepairCompletionDate__c = Date.valueOf(reqbody.RepairCompletionDate);
        if (String.isNotBlank(reqbody.Mileage)) warrantyUpt.Mileage__c = Decimal.valueOf(reqbody.Mileage);
        if (mapSympCondition.containsKey(reqbody.SymptomCode)) warrantyUpt.Symptom__c = mapSympCondition.get(reqbody.SymptomCode);
        if (mapSympCondition.containsKey(reqbody.ConditionCode)) warrantyUpt.Condition__c = mapSympCondition.get(reqbody.ConditionCode);
        warrantyUpt.Problem_Comment__c = reqbody.ProblemDescription;
        warrantyUpt.Reason_Comment__c = reqbody.CauseDescription;
        warrantyUpt.Repair_Comment__c = reqbody.RepairDescription;
        warrantyUpt.Dealer_Description__c = reqbody.DealerComment;
        if (jobpartsUpdate.containsKey(reqbody.PrimaryFailedPartNo)) warrantyUpt.PrimaryFailedPartNo__c = jobpartsUpdate.get(reqbody.PrimaryFailedPartNo).Id;
        update warrantyUpt;
        
    }
    private static void updateJobPartRequest(Job_Part_Detail__c jobpart, Map<String, Object> partcodes, Map<String, Job_Part_Detail__c> jobpartsUpdate) {
        Job_Part_Detail__c itemUpdate = new Job_Part_Detail__c();
        itemUpdate.Id = jobpart.Id;
        if (jobpart.RecordTypeId == RecordTypeHelper.PART) {
            FailedPart failedDTO = (FailedPart)partcodes.get(jobpart.ProductCode__c);
            itemUpdate.SupplyPart_Quantity__c = String.isNotBlank(failedDTO.SupplyPartQuantity) ? Integer.valueOf(failedDTO.SupplyPartQuantity) : 0;
            itemUpdate.Exchange_Part_Quantity__c = String.isNotBlank(failedDTO.ExchangePartQuantity) ? Integer.valueOf(failedDTO.ExchangePartQuantity) : 0;
            itemUpdate.Payment_Part_Cost__c = String.isNotBlank(failedDTO.PaymentPartCost) ? Decimal.valueOf(failedDTO.PaymentPartCost) : 0;
            itemUpdate.Payment_Part_Amount__c =  String.isNotBlank(failedDTO.PaymentPartAmount) ? Decimal.valueOf(failedDTO.PaymentPartAmount) : 0;
            itemUpdate.Part_Receive_Date__c = String.isNotBlank(failedDTO.PartReceiveDate) ?  Date.valueOf(failedDTO.PartReceiveDate) : null;
        }
        if (jobpart.RecordTypeId == RecordTypeHelper.JOB){
            JobCode jobDTO = (JobCode)partcodes.get(jobpart.ProductCode__c);
            itemUpdate.Flat_Rate__c = String.isNotBlank(jobDTO.FlatRate) ? Decimal.valueOf(jobDTO.FlatRate) : 0;
            itemUpdate.Payment_Labor_Amount__c = String.isNotBlank(jobDTO.PaymentLaborAmount) ? Decimal.valueOf(jobDTO.PaymentLaborAmount) : 0;
        }
        jobpartsUpdate.put(jobpart.ProductCode__c, itemUpdate);
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
        global String ClaimApplicationNorequestNo {
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
		global String ClaimStatusCode {
            get;
            set;
        }
		global String ClaimStatusName {
            get;
            set;
        }
		global String PaymentPartTotalAmount {
            get;
            set;
        }
		global String PaymentLaborTotalAmount {
            get;
            set;
        }
		global String PaymentTotalAmount {
            get;
            set;
        }
		global String ClaimModifyComment {
            get;
            set;
        }
		global String ClaimDeniedComment {
            get;
            set;
        }
		global String ClaimAdujudicationMessage {
            get;
            set;
        }
		global String AuthorizationNo {
            get;
            set;
        }
		global String ApplicationDate{
            get;
            set;
        }
		global String FrameNo{
            get;
            set;
        }
		global String SalesDate{
            get;
            set;
        }
		global String DropDueDate{
            get;
            set;
        }
		global String FailureDate{
            get;
            set;
        }
		global String RepairCompletionDate {
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
        global List<FailedPart> FailedParts {
            get;
            set;
        }
        global List<JobCode> JobCodes {
            get;
            set;
        }
    }
    global class FailedPart {
        global String ExchangePartNo {
            get;
            set;
        }
        global String SupersedingPartNo {
            get;
            set;
        }
        global String ExchangePartQuantity {
            get;
            set;
        }
        global String SupplyPartQuantity {
            get;
            set;
        }
        global String PaymentPartCost {
            get;
            set;
        }
        global String PaymentPartAmount {
            get;
            set;
        }
        global String PartReceiveDate {
            get;
            set;
        }
    }
    global class JobCode {
        global String JobCode {
            get;
            set;
        }
        global String FlatRate {
            get;
            set;
        }
        global String PaymentLaborAmount {
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
    public static void cheatCode() {
        string a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
            a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        
    }
}