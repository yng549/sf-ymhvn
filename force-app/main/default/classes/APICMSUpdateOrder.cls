/*******************************************************************************
 ** Class Name: APICMSUpdateOrder
 ** Description: Test class APIOrderAndOrderItemTest
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class APICMSUpdateOrder {
    
    private static final Map<String, Integer> status = new Map<String, Integer> {
        'Trạng thái đơn hàng' => 0,
        'Đặt hàng thành công' => 1,
        'DO/DL tiếp nhận thông tin' => 2, 
        'Đang xử lý' => 3, 
        'Hoàn thành' => 4, 
        'Chưa thanh toán' => 5,
        'Hủy thành công' => 6,
        'Thanh toán thất bại' => 7,
        'Thanh toán thành công' => 8
    };
    public class UpdateStatusOrder implements Queueable, Database.AllowsCallouts {
     	List<Id> orderIds;
        public UpdateStatusOrder(List<Id> orderIds){
            this.orderIds = orderIds;
        }
        public void execute(QueueableContext context) {
            if(orderIds.isEmpty()){
                return;
            }
           
            try{
                List<Id> queryorderIds = orderIds;
               
                String orderSoql = 'SELECT Id, Name, Status__c, Order_ID_CMS__c, Web_Source_PCA__c';
                orderSoql += ' FROM Order_WebCommercal__c';
                orderSoql += ' WHERE Id IN :queryorderIds';
               
                List<Order_WebCommercal__c> updatedOrders = new List<Order_WebCommercal__c>();
                for (Order_WebCommercal__c o : Database.query(orderSoql)) {
                    string strMessage = '';
                    Order_WebCommercal__c updateOrder = new Order_WebCommercal__c(Id = o.Id);
                    HttpResponse response = new HttpResponse(); 
                    try {
                        List<Data> orderRequestData = convertOrderCMS(o);
                        string jsondata = JSON.serialize(orderRequestData);
                        response = o.Web_Source_PCA__c == 'Revzone' ? requestApiCMS(jsondata) : requestWorkShopCMS(jsondata);
                        ResponseBody result = (ResponseBody)JSON.deserialize(response.getBody(), ResponseBody.class);
                        string strOutput = JSON.serialize(result);
                        logError('APICMSUpdateOrder.UpdateStatusOrder', '', jsondata, trimErrorMessage(strOutput), o.Name);
                        updateOrder.Log_CMS__c = result.message + '_' + result.code;
                        if(response.getStatusCode() == 200) {
                            updateOrder.Log_CMS__c = result.status + '_' + result.message;
                            if(result.status == '200') updateOrder.Log_CMS__c = 'Success';
                        }
                    }catch(Exception e) {
                        updateOrder.Log_CMS__c = e.getMessage();
                        strMessage = e.getMessage() + ' - ' + e.getLineNumber();
                        logError('APICMSUpdateOrder.UpdateStatusOrder', strMessage, trimErrorMessage(response.getBody()), o.Id, o.Name);
                    }
                    updatedOrders.add(updateOrder);
                }
                update updatedOrders;
            } catch(Exception e){
                system.debug('error' + e.getMessage() + e.getLineNumber());
                logError('APICMSUpdateOrder.UpdateStatusOrder', e.getMessage() + ' - ' + e.getLineNumber(), JSON.serialize(orderIds), '', '');
            }
        }
    }
    public static List<Data> convertOrderCMS(Order_WebCommercal__c order) {
        Data data = new Data();
        data.web_order_id = order.Order_ID_CMS__c;
        data.sf_order_id = order.Id;
        data.order_status = status.get(order.Status__c);
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
        public string code{
            get;
            set;
        }
        public string message {
            get;
            set;
        }
    }
    public static HttpResponse requestApiCMS(String reqBody) {
		Http http = new Http();
		HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:API_CMS/updateOrderStatus');
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
        request.setBody(reqBody);
        request.setTimeout(120000);
        return http.send(request);
	}
    public static HttpResponse requestWorkShopCMS(String reqBody) {
		Http http = new Http();
		HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:CMS_WORKSHOP/updateOrderStatus');
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', '{!$Credential.Password}');
        request.setBody(reqBody);
        request.setTimeout(120000);
        return http.send(request);
	}
	public class Data {
        public string web_order_id;
        public string sf_order_id;
        public integer order_status;
    }
}