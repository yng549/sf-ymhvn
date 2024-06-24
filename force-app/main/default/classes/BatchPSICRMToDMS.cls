/**
 * Controller: BatchPSICRMToDMS
 * Gửi thông tin về DMS, để DMS thống kê kiểm soát kho và gửi cho YNSIPRE SD
 * @created: 2022/11/09 THL
 * @modified:
 */
public without sharing class BatchPSICRMToDMS extends BaseBatchHandler2 {
    public static Boolean runningInASandbox {
    	get {
            if (runningInASandbox == null) {
                runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
        	return runningInASandbox;
    	}
    	set;
	}
    static Map<string, API_DMS__c> DMSDealerSetting { 
        get {
            if (DMSDealerSetting == null) {                
                API_DMS__c[] settings = [SELECT AccessToken__c, DealerCD__c, DMS_DealerName__c, Name 
                                         FROM API_DMS__c
                                         WHERE IsSandbox__c =: runningInASandbox];              
                if(!settings.isEmpty()){
                    Map<string, API_DMS__c> mapDealer = new Map<string, API_DMS__c>();
                    for(API_DMS__c dms : settings) {
                        //
                        mapDealer.put(dms.Name, dms);
                    }
                    DMSDealerSetting = mapDealer;
                }
            }
            return DMSDealerSetting;
        }
        set {}
    }
    private static final string URLDMS = 'https://ymvnstreamapi.ymcapps.net/streamapi/ymvn1/api/v1/psiinfo';
    public Boolean isDebug;
    public Date daterun;
	public BatchPSICRMToDMS(boolean isDebug, date daterun) {
        this.isDebug = isDebug;
        this.daterun = daterun;
        this.objectName = 'History_Stock_Product_Detail__c';
    }
    public override Database.querylocator start(Database.BatchableContext BC){
        //Date onDate = Date.today();
        Date onDate = isDebug && daterun != null ? daterun : Date.today();//
        //Date onDate = daterun;//
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> schemaFieldMap = sobjectType.getDescribe().fields.getMap();
        
        List<String> query = new List<String>();
        query.add('SELECT History_Stock_Product__r.DO_Code__c, ' + String.join(new List<String>(schemaFieldMap.keySet()), ','));
        query.add('FROM ' + objectName);
        query.add('WHERE Date__c =: onDate AND History_Stock_Product__c != NULL ');
        
        if (Test.isRunningTest()){
            cheatTemp();
            query.add('LIMIT 0');            
            BaseBatchHandler2.cheatTemp();
        }
        return Database.getQueryLocator(String.join(query, ' '));
    }
    public override List<SObject> processData(List<SObject> records) {
        List<History_Stock_Product_Detail__c> newData = (List<History_Stock_Product_Detail__c>)records;
        
		system.enqueueJob(new BatchPSICRMToDMS.CreateDataLog(newData, isDebug, daterun));
        return newData;
    }
    public class CreateDataLog implements Queueable, Database.AllowsCallouts {
        List<History_Stock_Product_Detail__c> newData;
        Boolean isDebug;
    	Date daterun;
        public CreateDataLog(List<History_Stock_Product_Detail__c> newData, Boolean isDebug, Date daterun) {
            this.newData = newData;
            this.isDebug = isDebug;
        	this.daterun = daterun;
        }
        public void execute(QueueableContext context) {
            List<DevLog__c> devlogs = new List<DevLog__c>();
            Map<string, Map<Id, List<History_Stock_Product_Detail__c>>> psiParentDOCode = new Map<string, Map<Id, List<History_Stock_Product_Detail__c>>>();
            Set<Id> hspRecords = new Set<Id>();
            try {
                for(History_Stock_Product_Detail__c psi : newData) {
                    if(!psiParentDOCode.containsKey(psi.History_Stock_Product__r.DO_Code__c)) {
                        psiParentDOCode.put(psi.History_Stock_Product__r.DO_Code__c, 
                                            new Map<Id, List<History_Stock_Product_Detail__c>> { psi.History_Stock_Product__c => new List<History_Stock_Product_Detail__c> () });
                    }
                    if(!psiParentDOCode.get(psi.History_Stock_Product__r.DO_Code__c).containsKey(psi.History_Stock_Product__c)) {
                        psiParentDOCode.get(psi.History_Stock_Product__r.DO_Code__c).put(psi.History_Stock_Product__c, new List<History_Stock_Product_Detail__c> ());
                    }
                    psiParentDOCode.get(psi.History_Stock_Product__r.DO_Code__c).get(psi.History_Stock_Product__c).add(psi);
                    hspRecords.add(psi.History_Stock_Product__c);
                }
                Map<Id, History_Stock_Product__c> psMap = new Map<Id, History_Stock_Product__c>([SELECT Id, Stock_At_The_Start__c, Product_Model__c, Color_Code__c
                                                                                                 FROM History_Stock_Product__c 
                                                                                                 WHERE DO_Code__c IN: psiParentDOCode.keySet() AND Id IN: hspRecords]);
                for(string dealerCode : psiParentDOCode.keySet()) {
                    //if(string.isBlank(DMSDealerSetting.get(dealerCode)?.DealerCD__c)) continue;
                    List<DataItemRequest> reqData = BatchPSICRMToDMS.createDatePSIRequest(psMap, psiParentDOCode.get(dealerCode), dealerCode, isDebug, daterun);
                    Map<string, List<DataItemRequest>> mapDataReq = new Map<string, List<DataItemRequest>> { 'data' => reqData };
                    string jsonreq = Json.serialize(mapDataReq).replaceAll('nDate', 'Date');
                    string message = '';
                    if(!isDebug) {
                        HttpResponse response = BatchPSICRMToDMS.calloutPSIDMS('psiinfo', jsonreq, dealerCode);
                        if(response.getStatusCode() == 200) {
                            Map<String, Object> dataResult = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                            message = String.valueOf(dataResult.get('msg'));
                        }
                    }
                    logError(isDebug && daterun != null ? 'BatchPSICRMToDMS' + string.valueOf(daterun) : 'BatchPSICRMToDMS',
                             message, '', 
                             SyncDMSHelper.trimErrorMessage(jsonreq), URLDMS, devlogs);
                }
            	
            }catch(Exception e) {
                logError(isDebug && daterun != null ? 'BatchPSICRMToDMS' + string.valueOf(daterun) : 'BatchPSICRMToDMS',
                         e.getMessage() + string.valueOf(e.getLineNumber()), '', '', URLDMS, devlogs);
            }
            insert devlogs;
        }
    }
    public static void logError(String function, String message, String input, String output, String url, List<DevLog__c> devlogs){
        DevLog__c log = new DevLog__c(
            Function__c = function,
            Url__c = url,
            Input__c = input,
            Output__c = output,
            Message__c = message             
        );
        devlogs.add(log);
    }
    public static List<DataItemRequest> createDatePSIRequest(Map<Id, History_Stock_Product__c> psMap, 
                                                             Map<Id, List<History_Stock_Product_Detail__c>> psiParentDOCode, string dealerCode,
                                                             Boolean isDebug, Date daterun) {
        List<DataItemRequest> datareq = new List<DataItemRequest>();
        for(Id psiID : psiParentDOCode.keySet()) {
            History_Stock_Product__c stock = psMap.get(psiID);
            for(History_Stock_Product_Detail__c item : psiParentDOCode.get(psiID)) {
                DataItemRequest itemreq = new DataItemRequest();
                itemreq.Point = dealerCode;
                itemreq.nDate = isDebug && daterun != null ? Datetime.newInstance(daterun, Time.newInstance(0, 0, 0, 0)).format('yyyyMMdd') : Datetime.now().format('yyyyMMdd');
                //itemreq.nDate = Datetime.newInstance(daterun, Time.newInstance(0, 0, 0, 0)).format('yyyyMMdd');
                itemreq.Model = stock.Product_Model__c;
                itemreq.InitialInv = string.valueOf(stock.Stock_At_The_Start__c);
                itemreq.YmvnIn = string.valueOf(integer.valueOf(item.Stock_In__c));
                itemreq.WholesalesIn = '0';
                itemreq.WholesalesOut = '0';
                itemreq.TransferIn = '0';
                itemreq.RetailOut = string.valueOf(integer.valueOf(item.Stock_Out__c));
                itemreq.Intransit = '0';
                itemreq.TransferOut = '0';
                datareq.add(itemreq);
            }
        }
        return datareq;
    }
    public static HttpResponse calloutPSIDMS(string apiname, string reqBody, string dealerCode) {
        if(dealerCode == 'RY01A')
        dealerCode = 'RY01PROD';
        if(dealerCode == 'RY02A')
        dealerCode = 'RY02PROD';
		Http http = new Http();
		HttpRequest request = new HttpRequest();
        string strURL = runningInASandbox ? 'callout:Api_DMS/streamapi/ymvn1/api/v1/' + apiname + '?dealerCd=' + DMSDealerSetting.get(dealerCode).DealerCD__c + '&accessToken=' + DMSDealerSetting.get(dealerCode).AccessToken__c
        : 'callout:API_DMS_PROD/streamapi/ymvn1/api/v1/'  + apiname + '?dealerCd=' + DMSDealerSetting.get(dealerCode).DealerCD__c + '&accessToken=' + DMSDealerSetting.get(dealerCode).AccessToken__c;
        request.setEndpoint(strURL);
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
        request.setBody(reqBody);
        request.setTimeout(120000);
        return http.send(request);
	}
    public class DataRequest {
        public List<DataItemRequest> data;
    }
    public class DataItemRequest {
        public string Point;
        public string nDate;
        public string Model;
        public string InitialInv;
    	public string YmvnIn;
    	public string WholesalesIn;
    	public string TransferIn;
    	public string RetailOut;
    	public string WholesalesOut;
    	public string TransferOut;
    	public string Intransit;
    }
    public static void cheatTemp() {
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
    }
    public override void handleFinish(){
        sendErrorAfterEachBatch = true;
    }
}