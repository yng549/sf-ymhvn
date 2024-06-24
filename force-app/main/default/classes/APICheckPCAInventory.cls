/*******************************************************************************
 ** Class Name: APICheckPCAInventory
 ** Description: API check pca for CMS website
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
@RestResource(urlMapping = '/APICheckPCAInventory/*')
global without sharing class APICheckPCAInventory {
  // Error code definition : {error code => http status code, error message}
    private static final Map<String, errDef> err = new Map<String, errDef> {
        'SUCCESS'                   	=> new errDef(200, 'Success'),
        'PARAM_LIMITEXCEED'     		=> new errDef(400, 'List request is maximum 20'),
        'PARAM_PARTNOINVALID'     		=> new errDef(400, 'Parts No is required'),
        'PARAM_PARTNOINVENTORYEMPTY'  	=> new errDef(400, 'PCA Inventory not found'),
        'ERROR_EXCEPTION'           	=> new errDef(500, 'Exception occured')
    };
    // http request 
    private static RestRequest req = RestContext.request;
    private static RestResponse res = RestContext.response;
    private static requestBody reqBody = new requestBody();
    private static responseBody resBody = new responseBody();
    private static Map<String, List<AggregateResult>> mapPCAInventory = new Map<String, List<AggregateResult>>();
    @HttpPost
    global static void run() {
        Service_Request__c serviceWarranty;
        try {
            reqBody = (requestBody)JSON.deserialize(req.requestBody.toString(), requestBody.class);
            if (reqBody.productCodes.isEmpty()) {
                createResponse('PARAM_PARTNOINVALID');
                return;
            }
			if (reqBody.productCodes.size() >= 20) {
                createResponse('PARAM_LIMITEXCEED');
                return;
            }
            for (AggregateResult pcaInventory : [SELECT Product__r.ProductCode pcano, Warehouse_Location__r.Account__r.DO_DL_Code__c dealer, Sum(QoH__c) QoH
                                                 FROM Warehouse_Inventory__c
                                                 WHERE Product_Code__c IN: reqBody.productCodes AND Product__r.RecordTypeId =: RecordTypeHelper.PRODUCT_PCA
                                                 AND  Warehouse_Location__r.Type__c = null AND QoH__c > 0
                                                 GROUP BY Product__r.ProductCode, Warehouse_Location__r.Account__r.DO_DL_Code__c]) {
                if (mapPCAInventory.containsKey((string)pcaInventory.get('pcano'))) {
                    mapPCAInventory.get((string)pcaInventory.get('pcano')).add(pcaInventory);
                    continue;
                }
                mapPCAInventory.put((string)pcaInventory.get('pcano') , new List<AggregateResult> {pcaInventory});
            }
            if (mapPCAInventory.isEmpty()) {
                createResponse('PARAM_PARTNOINVENTORYEMPTY');
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
    private static List<Data> createDataRespone(Map<String, List<AggregateResult>> mapPCAInventory) {
        List<Data> data = new List<Data>();
        for (String modelcode : mapPCAInventory.keySet()) {
            Data inventory = new Data();
            inventory.modelcode = modelcode;
            List<InventoryDetail> inventorys = new List<InventoryDetail>();
            for (AggregateResult detailItem : mapPCAInventory.get(modelcode)) {
                InventoryDetail mcInventory = new InventoryDetail();
                mcInventory.dealercode = (string)detailItem.get('dealer');
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
        resBody.data = createDataRespone(mapPCAInventory);
		if (ex != null) {
			resBody.responseMessage += + ex.getLineNumber() +  ' - ' + ex.getMessage();
		}
        res.addHeader('Access-Control-Allow-Origin', '*');
        res.addHeader('Content-Type', 'application/json');     
        res.statusCode = err.get(code).statusCode;
        res.responseBody = Blob.valueOf(JSON.Serialize(resBody));
    }
    global class requestBody {
        global List<string> productCodes{
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