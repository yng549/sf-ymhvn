/*******************************************************************************
 ** Class Name: APIOrderAndOrderItem
 ** Description: Converted Order Ecommerce to CRM base on order Type
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
@RestResource(urlMapping = '/APIOrderAndOrderItemModel/*')
global class APIOrderAndOrderItem {
  // Error code definition : {error code => http status code, error message}
    private static final Map<String, errDef> err = new Map<String, errDef> {
        'SUCCESS'                   	=> new errDef(200, 'Success'),
        'PARAM_DATAEMPTY'     			=> new errDef(400, 'Data request not empty'),
        'PARAM_ORDERTYPEEMPTY'     		=> new errDef(400, 'Order Type is required'),
        'PARAM_CUSTORMERINVALID'     	=> new errDef(400, 'Customer id is required'),
        'PARAM_ADDRESSINVALID'  		=> new errDef(400, 'Address is required'),
        'PARAM_INVOICENOINVALID'  		=> new errDef(400, 'Invoice No is required'),
        'PARAM_PAYMENTMETHODINVALID'  	=> new errDef(400, 'Payment method is required'),
        'PARAM_ORDERPRODUCTINVALID'  	=> new errDef(400, 'Product list is required'),
        'DUPLICATEDRULES'           	=> new errDef(400, 'Find duplicate records'),
        'ERROR_EXCEPTION'           	=> new errDef(500, 'Exception occured')
    };
    // http request 
    private static RestRequest req = RestContext.request;
    private static RestResponse res = RestContext.response;
    private static requestBody reqBody = new requestBody();
    private static responseBody resBody = new responseBody();
    @HttpPost
    global static void run() {
        Savepoint sp = Database.setSavepoint();
        try {
            List<OrderRespone> responsecontent = new List<OrderRespone>();
            reqBody = (requestBody)JSON.deserialize(req.requestBody.toString(), requestBody.class);
            Map<String, List<String>> mapOrderVoucherCodes = new Map<String, List<String>>();
            Map<String, Order_WebCommercal__c> mapIdCMSToCRM = new Map<String, Order_WebCommercal__c>();
            List<string> vouchersReq = new List<String>();
            if (reqBody.orders.isEmpty()) {
                createResponse('PARAM_DATAEMPTY');
            	return; 
            }
            for (order o : reqBody.orders) {
                if (String.isBlank(o.customer_id)) {
                    createResponse('PARAM_CUSTORMERINVALID');
                    return;
            	}
                if (String.isBlank(o.order_type)) {
                    createResponse('PARAM_ORDERTYPEEMPTY');
                    return;
                }
                if (String.isBlank(o.receive_address) || String.isBlank(o.recevie_province) || string.isBlank(o.receive_district)) {
                    createResponse('PARAM_ADDRESSINVALID');
                    return;
                }
                if (String.isBlank(o.invoice_require)) {
                    createResponse('PARAM_INVOICENOINVALID');
                    return;
                }
                if (String.isBlank(o.payment_method)) {
                    createResponse('PARAM_PAYMENTMETHODINVALID');
                    return;
                }
                if (o.orderProducts.isEmpty()) {
                    createResponse('PARAM_ORDERPRODUCTINVALID');
                    return;
                }
                Order_WebCommercal__c order = new Order_WebCommercal__c();
                order.Customer_id__c = o.customer_id;
                order.ID_Primary_Order__c = o.order_primary_id;
                order.Order_Type__c = o.order_type;
                if(o.order_type == 'PCA') {
                    order.Status__c = 'DO/DL tiếp nhận thông tin';
                }
                if(string.isNotBlank(o.order_source))
                order.Web_Source_PCA__c = o.order_source;
                // consideration DO or Non resident 
                order.Non_Resident__c = o.guest == 1 ? True : False;
                if(string.isNotBlank(o.receive_phone)) 
                order.Phone__c = APICheckingAccountWebsite.normalizePhoneNumber(o.receive_phone);
                order.Email__c = o.receive_email;
                order.Name__c = o.receive_name;
                order.Receive_address__c = o.receive_address;
                order.receive_district__c = o.receive_district;
                order.recevie_province__c = o.recevie_province;
                order.receive_ward__c = o.receive_ward;
                order.invoice_require__c = o.invoice_require;
                order.tax_number__c = o.tax_number;
                order.company_info__c = o.company_info;
                order.dealer_code__c = o.dealer_code;
                order.payment_method__c = o.payment_method;
                order.promotion_code__c = o.promotion_code;
                order.Promotion_Item__c = o.promotion_itemID;
                order.Order_ID_CMS__c = o.web_order_id;
                order.company_address__c = o.company_address;
                mapIdCMSToCRM.put(o.web_order_id, order);
                if (!o.vouchers.isEmpty())
                mapOrderVoucherCodes.put(o.web_order_id, o.vouchers);
                vouchersReq.addAll(o.vouchers);
            }
            // Find Duplicated rules for order Ecommerce
            List<Object> duplicateRecords = new List<Object>();
            Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(mapIdCMSToCRM.values());
            for (Datacloud.FindDuplicatesResult findDupeResult : results) {
              for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                  for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                      for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                          duplicateRecords.add(matchRecord.getRecord());
                      }
                  }
              }
            }
            // if duplicate records diff null
            if (!duplicateRecords.isEmpty()) {
                resBody.data = duplicateRecords;
                createResponse('DUPLICATEDRULES');
            	return;
            }
            // Create a success response.
            responsecontent = createOrderProductCommercal(reqBody, mapIdCMSToCRM, mapOrderVoucherCodes, vouchersReq);
            resBody.data = responsecontent;
            createResponse('SUCCESS');
            return;
        }catch(Exception ex) {
            Database.rollback(sp);
            createResponse('ERROR_EXCEPTION', ex);
            return;
        }
    }
    private static List<OrderRespone> createOrderProductCommercal(requestBody req, Map<String, Order_WebCommercal__c> mapIdCMSToCRM, Map<String, List<String>> mapOrderVoucherCodes,
                                                                 List<string> vouchersReq) {
        List<OrderRespone> ordersReturn = new List<OrderRespone>();
        insert mapIdCMSToCRM.values();
        List<Voucher__c> vouchersApplied = new List<Voucher__c>();
		List<Order_Item_WebCommercal__c> orderItems = new List<Order_Item_WebCommercal__c>();        
        Map<String, VoucherDTO> mapVouchersCode = new Map<String, VoucherDTO>();
        for (Voucher__c voucher : [SELECT Id, IMEI__c FROM Voucher__c WHERE IMEI__c IN:vouchersReq AND Order_WebCommercal__c = null AND Is_Applied__c = false]) {
            VoucherDTO v = new VoucherDTO();
            v.voucherId = voucher.Id;
            v.isApplied = false;
            mapVouchersCode.put(voucher.IMEI__c, v);
        }
        for (order o :  req.orders) {
            OrderRespone oRes = new OrderRespone();
            Id orderId = mapIdCMSToCRM.get(o.web_order_id).Id;
            oRes.orderId = orderId;
            for (String voucherNo : o.vouchers) {
                if (mapVouchersCode.containsKey(voucherNo) && !mapVouchersCode.get(voucherNo).isApplied) {
                    mapVouchersCode.get(voucherNo).isApplied = true;
                    vouchersApplied.add(new Voucher__c (Id = mapVouchersCode.get(voucherNo).voucherId,
                                                        Order_WebCommercal__c = orderId,
                                                        Voucher_Status__c = 'Redeemed',
                                                        Redeem_Date__c = System.today()));
                }  
            }
            for (OrderDetail product : o.orderProducts) {
                Order_Item_WebCommercal__c orderItem = new Order_Item_WebCommercal__c();
                orderItem.Product_Code__c = product.productcode;
                orderItem.color_code__c = product.colorcode;
                orderItem.quantity__c = product.quantity;
                orderItem.size_code__c = product.sizecode; 
                orderItem.price__c = product.price;
                orderItem.sale_off__c = product.sale_off;
                orderItem.Order_WebCommercal__c = orderId;
                orderItems.add(orderItem);
        	}
            ordersReturn.add(oRes);
        }
        
		update vouchersApplied;
        insert orderItems;
        // Convert order web ecommerce to Opportuniy base on order type. Proccess will run asynchronous which do not happening or done at the same time or speed
        TriggerHandlerOrderCMS.onAfterInsert(mapIdCMSToCRM.values(), true);
        return ordersReturn;
    }
    private class VoucherDTO {
        private Id voucherId;
        private boolean isApplied;
    }
    private static void createResponse(String code) {
		createResponse(code, null);
	}

    private static void createResponse(String code, Exception ex) {
		resBody.responseMessage = err.get(code).errMessage;
		if (ex != null) {
			resBody.responseMessage +=  ex.getLineNumber() + ' - ' + ex.getMessage();
		}
        res.addHeader('Access-Control-Allow-Origin', '*');
        res.addHeader('Content-Type', 'application/json');     
        res.statusCode = err.get(code).statusCode;
        res.responseBody = Blob.valueOf(JSON.Serialize(resBody));
    }
    global class order {
        global integer guest{
            get;
            set;
        }
        global string receive_name{
            get;
            set;
        }
        global string receive_phone{
            get;
            set;
        }
        global string receive_email{
            get;
            set;
        }
        global string order_source{
            get;
            set;
        }
        global string customer_id{
            get;
            set;
        }
        global string web_order_id{
            get;
            set;
        }
        global string receive_address{
            get;
            set;
        }
        global string order_primary_id{
            get;
            set;
        }
        global string recevie_province{
            get;
            set;
        }
        global string receive_district{
            get;
            set;
        }
        global string order_type{
            get;
            set;
        }
        global string receive_ward{
            get;
            set;
        }
        global string invoice_require{
            get;
            set;
        }
        global string tax_number{
            get;
            set;
        }
        global string company_info{
            get;
            set;
        }
        global string company_address{
            get;
            set;
        }
        global string dealer_code{
            get;
            set;
        }
        global string payment_method{
            get;
            set;
        }
        global string promotion_code{
            get;
            set;
        }
        global string promotion_itemID{
            get;
            set;
        }
        global List<String> vouchers{
            get;
            set;
        }
        global List<OrderDetail> orderProducts{
            get;
            set;
        }
    }
    global class requestBody {
		List<order> orders;
    }
    global class OrderDetail {
        public string productcode {
            get;
            set;
        }
        public Integer quantity {
            get;
            set;
        }
        public string sizecode {
            get;
            set;
        }
        public string colorcode {
            get;
            set;
        }
        public decimal price {
            get;
            set;
        }
        public decimal sale_off {
            get;
            set;
        }
    }
    global class responseBody {
        global string responseMessage {
            get;
            set;
        }
        global List<Object> data {
            get;
            set;
        }
    }
    global class OrderRespone {
         global string orderId {
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