/*******************************************************************************
 ** Class Name: APICheckMcInventory
 ** Description: API check model inventory for CMS website
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
@RestResource(urlMapping = '/APICheckMcInventory/*')
global without sharing class APICheckMcInventory {
  // Error code definition : {error code => http status code, error message}
    private static final Map<String, errDef> err = new Map<String, errDef> {
        'SUCCESS'                   	=> new errDef(200, 'Success'),
        'PARAM_LIMITEXCEED'     		=> new errDef(400, 'List request is maximum 20'),
        'PARAM_MODELCODEINVALID'     	=> new errDef(400, 'Model Code is required'),
        'PARAM_MCINVENTORYEMPTY'  		=> new errDef(400, 'Model Inventory not found'),
        'ERROR_EXCEPTION'           	=> new errDef(500, 'Exception occured')
    };
    // http request 
    private static RestRequest req = RestContext.request;
    private static RestResponse res = RestContext.response;
    private static requestBody reqBody = new requestBody();
    private static responseBody resBody = new responseBody();
    private static Map<String, List<AggregateResult>> mapMcCodeInventory = new Map<String, List<AggregateResult>>();
    @HttpPost
    global static void run() {
        Service_Request__c serviceWarranty;
        try {
            reqBody = (requestBody)JSON.deserialize(req.requestBody.toString(), requestBody.class);
            if (reqBody.modelCodes.isEmpty()) {
                createResponse('PARAM_MODELCODEINVALID');
                return;
            }
			if (reqBody.modelCodes.size() >= 20) {
                createResponse('PARAM_LIMITEXCEED');
                return;
            }
            for (AggregateResult mcInventory : [SELECT Product__r.ProductCode modelcode, Product__r.Color_Code__c colorcode, 
                                                Warehouse_Location__r.Account__r.DO_DL_Code__c dealer, Sum(QoH__c) QoH
                                                FROM Warehouse_Inventory__c 
                                                WHERE Product_Code__c IN: reqBody.modelCodes
                                                AND Product__r.RecordTypeId =: RecordTypeHelper.PRODUCT_MODEL AND QoH__c > 0
                                                AND  Warehouse_Location__r.Type__c = Null AND Warehouse_Location__c != Null
                                                GROUP BY Product__r.ProductCode, Product__r.Color_Code__c, Warehouse_Location__r.Account__r.DO_DL_Code__c]) {
                if (mapMcCodeInventory.containsKey((string)mcInventory.get('modelcode'))) {
                    mapMcCodeInventory.get((string)mcInventory.get('modelcode')).add(mcInventory);
                    continue;
                }
                mapMcCodeInventory.put((string)mcInventory.get('modelcode') , new List<AggregateResult> {mcInventory});
            }
            if (mapMcCodeInventory.isEmpty()) {
                createResponse('PARAM_MCINVENTORYEMPTY');
                return;
            }
            
            // Create a success response.
            createResponse('SUCCESS');
            return;
        }catch(Exception ex) {
            createResponse('ERROR_EXCEPTION', ex);
            return;
        }
    }
    private static List<Data> createDataRespone(Map<String, List<AggregateResult>> mapMcCodeInventory) {
        List<Data> data = new List<Data>();
        for (String modelcode : mapMcCodeInventory.keySet()) {
            Data inventory = new Data();
            inventory.modelcode = modelcode;
            List<InventoryDetail> inventorys = new List<InventoryDetail>();
            for (AggregateResult detailItem : mapMcCodeInventory.get(modelcode)) {
                InventoryDetail mcInventory = new InventoryDetail();
                mcInventory.dealercode = (string)detailItem.get('dealer') ;
                mcInventory.colorcode = (string)detailItem.get('colorcode');
                mcInventory.status = Integer.valueOf(detailItem.get('QoH')) > 0 ? '1' : '0';
                inventorys.add(mcInventory);
            }
            inventory.inventorys = inventorys;
            data.add(inventory);
        }
        return data;
    }
    private static void createResponse(String code) {
		createResponse(code, null);
	}

    private static void createResponse(String code, Exception ex) {
		resBody.responseMessage = err.get(code).errMessage;
        resBody.data = createDataRespone(mapMcCodeInventory);
		if (ex != null) {
			resBody.responseMessage += ' - ' + ex.getMessage();
		}
        res.addHeader('Access-Control-Allow-Origin', '*');
        res.addHeader('Content-Type', 'application/json');     
        res.statusCode = err.get(code).statusCode;
        res.responseBody = Blob.valueOf(JSON.Serialize(resBody));
    }
    global class requestBody {
        global List<string> modelCodes{
            get;
            set;
        }
    }
	global class Data {
        public string modelcode {
            get;
            set;
        }
        global List<InventoryDetail> inventorys {
            get;
            set;
        }
    }
    global class InventoryDetail {
        public string dealercode {
            get;
            set;
        }
        public string colorcode {
            get;
            set;
        }
        public string status {
            get;
            set;
        }
    }
    global class responseBody {
        global string responseMessage {
            get;
            set;
        }
        global List<Data> data {
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