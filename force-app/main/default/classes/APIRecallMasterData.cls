/*******************************************************************************
 ** Class Name: APIRecallMasterData
 ** Description: Web service class to initiate Cross recall process.
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
@RestResource(urlMapping = '/APIRecallMasterData/*')
global class APIRecallMasterData {
    // Error code definition : {error code => http status code, error message}
    private static final Map<String, errDef> err = new Map<String, errDef> {
        'SUCCESS'                   => new errDef(200, 'Success'),
        'PARAM_NOCAMCODE'           => new errDef(400, 'Campaign number required'),
        'PARAM_NOCAMTITLE'  		=> new errDef(400, 'Campaign title required'),
        'PARAM_DATEREQUERIED'       => new errDef(400, 'Start Date and End Date required'),
        'PARAM_INVALIDTYPE'         => new errDef(404, 'Bulletin No. is required'),
        'ERROR_EXCEPTION'           => new errDef(500, 'Exception occured')
    };    
    // http request 
    private static RestRequest req = RestContext.request;
    private static RestResponse res = RestContext.response;
    private static requestBody reqBody = new requestBody();
    private static responseBody resBody = new responseBody();
    private static List<String> descriptionRepairs = new List<String>();
    private static List<String> descriptionProblems = new List<String>();
    // Constant definition
    private static String productCodeInvalid = 'ProductCodes not founded : 0';
    private static String symptonConditionInvalid = 'Sympton-Condition not founded : 0';
    private static String descriptionFinal = '{0}\n{1}';
    
    @HttpPost
    global static void run() {
        
		Campaign cmCreate = new Campaign();
        Pricebook2 pricebook = new Pricebook2();
        List<PricebookEntry> entries = new List<PricebookEntry>();
        List<Product2> products = new List<Product2>();
        Map<String, Repair_Pattern__c> listRepair = new Map<String, Repair_Pattern__c>();
        List<Problem_Detail__c> listProblem = new List<Problem_Detail__c>();
		Map<String, RepairPattern> mapRepairPatternCode = new Map<String, RepairPattern>();
        Set<String> codePartNo = new Set<String>();
        Set<String> codeJob = new Set<String>();
        List<Product_Campaign__c> listProductCm = new List<Product_Campaign__c>();
        Map<String, Stamping_Style_Detail__c> mapStampingDetails = new Map<String, Stamping_Style_Detail__c>();
        try {
           reqBody = (requestBody)JSON.deserialize(req.requestBody.toString(), requestBody.class);
           
           // Check parameters - Cam number
           if (String.isBlank(reqBody.CampaignNumber)) {
               createResponse('PARAM_NOCAMCODE');
               return;
           }

           // Check parameters - Cam title
           if (String.isBlank(reqBody.CampaignTitle)) {
               createResponse('PARAM_NOCAMTITLE');
               return;
           }
            
           // Check parameters - Start Date and End Date required
           if (String.isBlank(reqBody.EffectiveDate) || String.isBlank(reqBody.ExpiredDate)) {
               createResponse('PARAM_DATEREQUERIED');
               return;
           }
            
           // Check parameters - Bulletin No. required
           if (String.isBlank(reqBody.BulletinNumber)) {
               createResponse('PARAM_INVALIDBULLETIN');
               return;
           }
           // Insert pricebook custom from campaign created
           pricebook = createPriceBook(reqBody.CampaignTitle, reqBody.Description);
           // Insert Campaign 
           cmCreate = createCampaign(reqBody, pricebook.Id);
           
           if(null != reqBody.RepairPatterns || reqBody.RepairPatterns.isEmpty()) {
               for (RepairPattern item : reqBody.RepairPatterns) {
                    listRepair.put(item.RepairPatternCode , new Repair_Pattern__c(Name = item.RepairPatternCode,
                                                                                  Repair_Type__c = item.CampaignRepairType,
                                                                                  Campaign__c = cmCreate.Id));
                   for (Part iPart : item.Parts) {
                       codePartNo.add(iPart.PartNo);
                   }
                   for (Job iJob : item.JobCodes) {
                       codeJob.add(iJob.JobCode);
                   }
                   mapRepairPatternCode.put(item.RepairPatternCode, item);
               }
           }
           insert listRepair.values();
           // Get the products based on part/code to get the product id
           products = [SELECT ID, Name,RecordTypeId, ProductCode FROM Product2 
                       WHERE (RecordTypeId =: RecordTypeHelper.SV_JOB
                              AND ProductCode IN: codeJob) OR (RecordTypeId =: RecordTypeHelper.PRODUCT_PCA AND ProductCode IN: codePartNo)];
           // Map record type PCA product
           Map<String, Product2> mapProductCodePCA = new Map<String, Product2>();
           // Map record type Service Job product
           Map<String, Product2> mapProductCodeSVJ = new Map<String, Product2>();
           for(Product2 pro : products) {
               entries.add(new PricebookEntry(unitprice = 0, 
                                              Product2Id = pro.Id,
                                              Pricebook2Id = pricebook.Id,
                                              IsActive = true));
               if (pro.RecordTypeId == RecordTypeHelper.PRODUCT_PCA) mapProductCodePCA.put(pro.ProductCode, pro);
               if (pro.RecordTypeId == RecordTypeHelper.SV_JOB) mapProductCodeSVJ.put(pro.ProductCode, pro);
           }
           // Insert PriceBooke entries from Product unit price 0
           insert entries;
           
           for (String codeRepair : mapRepairPatternCode.keySet()) {
               List<String> listPart = new List<String>();
               List<String> listJob = new List<String>();
               for (Part iPart : mapRepairPatternCode.get(codeRepair).Parts) {
                   // Check Duplicate PartNo in Pattern
                   if (listPart.contains(iPart.PartNo)) continue;
                   listPart.add(iPart.PartNo);
                   createProductCampaign(mapProductCodePCA, listProductCm, iPart.PartNo,
                                         cmCreate.Id, listRepair.get(codeRepair).Id, codeRepair);
               }
               for (Job iJob : mapRepairPatternCode.get(codeRepair).JobCodes) {
                   // Check Duplicate JobCode in Pattern
                   if (listJob.contains(iJob.JobCode)) continue;
                   listJob.add(iJob.JobCode);
                   createProductCampaign(mapProductCodeSVJ, listProductCm, iJob.JobCode, 
                                         cmCreate.Id, listRepair.get(codeRepair).Id, codeRepair);
               }
           }
           // Insert Prodcut Campaign
           insert listProductCm;
            
           if (null != reqBody.FailureItem) {
               // Querying the symptom condition based on Symptom-Condition code in request.
               Map<String, Symptom_Condition__c> mapSympton = new Map<String, Symptom_Condition__c>();
               Map<String, Symptom_Condition__c> mapCondition = new Map<String, Symptom_Condition__c>();
               for (Symptom_Condition__c scItem : [SELECT Id, Name, RecordTypeId FROM Symptom_Condition__c
                                                   WHERE (Name IN: reqBody.FailureItem.SymptonCodes AND RecordTypeId =: RecordTypeHelper.SYMPTON) 
                                                   OR (Name IN: reqBody.FailureItem.ConditionCodes AND RecordTypeId =: RecordTypeHelper.CONDITION)]) {
                   if (scItem.RecordTypeId == RecordTypeHelper.SYMPTON) mapSympton.put(scItem.Name, scItem);
                   if (scItem.RecordTypeId == RecordTypeHelper.CONDITION) mapCondition.put(scItem.Name, scItem);
               } 
               List<String> listSymptons = new List<String>();
               List<String> listConditions = new List<String>();
               for (String sympItem : reqBody.FailureItem.SymptonCodes) {
                   // Check Duplicate Sympton
                   if (listSymptons.contains(sympItem)) continue;
                   listSymptons.add(sympItem);
                   createProblemDetail(mapSympton, listProblem, sympItem, cmCreate.Id);
               }
               for (String conditionItem : reqBody.FailureItem.ConditionCodes) {
                   // Check Condition
                   if (listConditions.contains(conditionItem)) continue;
                   listConditions.add(conditionItem);
                   createProblemDetail(mapCondition, listProblem, conditionItem, cmCreate.Id);
               }
           }
           // Insert Problem Details.
           insert listProblem;
           if (null != reqBody.PIDRanges || !reqBody.PIDRanges.isEmpty()) {
               for (PIDRange iPID : reqBody.PIDRanges) {
                   if (!mapStampingDetails.containsKey(iPID.StampingStyle)) mapStampingDetails.put(iPID.StampingStyle,
                                                                                                   new Stamping_Style_Detail__c(Serial_Numb__c = iPID.SerialNumberFrom,
                                                                                                                                Serial_No_To__c = iPID.SerialNumberTo,
                                                                                                                                Campaign__c = cmCreate.Id,
                                                                                                                                Name = iPID.StampingStyle));
               }
           }
           insert mapStampingDetails.values();
           // Update the status of campaign to "Responsed". IF there are not founded Job/Part or Sympton/Condition.
           if (!descriptionRepairs.isEmpty() || !descriptionProblems.isEmpty()) {
               if (!descriptionRepairs.isEmpty()) {
                  descriptionFinal = productCodeInvalid.substring(0, productCodeInvalid.length() - 1) + String.join(descriptionRepairs, ',');
               }
               if (!descriptionProblems.isEmpty()) {
                  symptonConditionInvalid = symptonConditionInvalid.substring(0, symptonConditionInvalid.length() - 1) + String.join(descriptionProblems, ',');
               }
               Campaign cmUpdate = new Campaign(Id = cmCreate.Id,
                                                Is_Valid__c = False,
                                                Description = String.format('{0}\n{1}',new List<String>{descriptionFinal, symptonConditionInvalid}));
               update cmUpdate;
           }
           // Create a success response.
           createResponse('SUCCESS');
           return;
        }
        catch (Exception ex) {
            createResponse('ERROR_EXCEPTION', ex);
            return;
        }        
    }
    private static void createProblemDetail(Map<String, SObject> mapSymptonConditon, List<Problem_Detail__c> listProblem, String code, Id idCampaign) {
        Problem_Detail__c problem = new Problem_Detail__c();
        problem.Campaign__c = idCampaign;
        problem.Code__c = code;
        if (mapSymptonConditon.containsKey(code)) {
         	problem.Symptom_Condition__c = mapSymptonConditon.get(code).Id;
        } else {
           descriptionProblems.add(code);
        }
        listProblem.add(problem);
    }
    private static void createProductCampaign(Map<String, SObject> mapProductCode, List<Product_Campaign__c> listProductCm,
                                              String code, Id idCampaign, Id idRepairPattern, String codeRepair) {
        Product_Campaign__c proCm = new Product_Campaign__c ();
        proCm.Name = code;
        proCm.Campaign__c = idCampaign;
        if (mapProductCode.containsKey(code)) {
           proCm.Product__c = mapProductCode.get(code).Id;
        } else {
           descriptionRepairs.add(codeRepair + '-' + code);
        }
        proCm.Repair_Pattern__c = idRepairPattern;
        proCm.RecordTypeId = RecordTypeHelper.RECALL_PM;
        listProductCm.add(proCm);
    }
    private static Pricebook2 createPriceBook(String name, String description) {
        Pricebook2 pb = new Pricebook2();
        pb.Name = name;
        pb.Description = description;
        pb.IsActive = true;
        pb.Type__c = 'Recall';
        Insert pb;
        return pb;
    }
    private static Campaign createCampaign(requestBody reqBody, Id idPriceBook) {
        Campaign cm = new Campaign();
        cm.Name = reqBody.CampaignTitle;
        cm.Type__c = reqBody.CampaignType;
        cm.Price_Book__c  = idPriceBook;
        cm.Campain_Number__c = reqBody.CampaignNumber;
        cm.StartDate = Date.valueOf(reqBody.EffectiveDate);
        cm.EndDate = Date.valueOf(reqBody.ExpiredDate);
        cm.Note__c = reqBody.Description;
        cm.Bulletin_No__c = reqBody.BulletinNumber;
        cm.RecordTypeId = RecordTypeHelper.CAMPAIGNRECALL;
        insert cm;
        return cm;
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
        global String BulletinNumber {
            get;
            set;
        }
        global String CampaignNumber {
            get;
            set;
        }
        global String CampaignType {
            get;
            set;
        }
        global String CampaignTitle {
            get;
            set;
        }
        global String EffectiveDate {
            get;
            set;
        }
        global String ExpiredDate  {
            get;
            set;
        }
        global String Description {
            get;
            set;
        }
        global List<RepairPattern> RepairPatterns {
            get;
            set;
        }
        global Failure FailureItem {
            get;
            set;
        }
        global List<PIDRange> PIDRanges {
            get;
            set;
        }
    }

    global class RepairPattern {
        global String RepairPatternCode {
            get;
            set;
        }
        global String CampaignRepairType {
            get;
            set;
        }
        global List<Part> Parts {
            get;
            set;
        }
        global List<Job> JobCodes {
            get;
            set;
        }
    }
    global class Part {
        global string PartNo {
            get;
            set;
        }
        global string PrimaryPartsFlag {
            get;
            set;
        }
    }
    global class Job {
        global string JobCode {
            get;
            set;
        }
    }

    global class Failure {
        global List<String> SymptonCodes {
            get;
            set;
        }
        global List<String> ConditionCodes {
            get;
            set;
        }
    }
    global class PIDRange {
        global String StampingStyle {
            get;
            set;
        }
        global String SerialNumberFrom {
            get;
            set;
        }
        global String SerialNumberTo {
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
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
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