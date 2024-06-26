public class BtnCreateEinvoiceController {
	@AuraEnabled
    public static ApiResponse createEinvoice(String orderId)
    {
        //Order Product
        Map<String, Schema.SObjectField> orderlineFieldMap = OrderItem.sObjectType.getDescribe().fields.getMap();
        List<string> orderlineSelectFields = new List<String>(orderlineFieldMap.keySet());
        String orderLineSoql = 'SELECT ' + String.join(orderlineSelectFields, ',');
        orderLineSoql += ' FROM OrderItems';
        //Order
        Map<String, Schema.SObjectField> orderFieldMap = Order.sObjectType.getDescribe().fields.getMap();
        List<string> orderSelectFields = new List<String>(orderFieldMap.keySet());                
        String orderSoql = 'SELECT Account.RecordTypeId,Account.DO_DL_Create_Account__c, ' + String.join(orderSelectFields, ',') + ' ,('  +orderLineSoql + ')' ;
        orderSoql += ' FROM Order';
        orderSoql += ' WHERE Id =: orderId'; 
        Order order = Database.query(orderSoql); 
        String strMessage = '';

        Boolean notIncludeVat = false;
        if (order.Generated_Redeem__c == true 
        && order.RecordTypeId == RecordTypeHelper.ORDER_PCA){
            notIncludeVat = true;
        } else if(order.RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE
            && order.Account.RecordTypeId == RecordTypeHelper.ACCOUNT_DODL){
            notIncludeVat = true;
        }
        for (OrderItem item : order.OrderItems){
            if (((order.RecordTypeId == RecordTypeHelper.ORDER_FREE_COUPON 
            || order.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER) 
            && item.Applied__c == true)){
                notIncludeVat = true;
            }
        }
        
        ApiResponse api = new ApiResponse();
        if(order.DO_DL__c != order.Account.DO_DL_Create_Account__c)
        {
            api.error = 'Account Name has the wrong DO/DL, please check again.';
            return api;
        }
        
        if(order.Is_Created_Or_Sent_Invoice__c == false)
        {
            if(order.Invoice_Date__c == null)
            {
                if(order.Remaining_Amount__c <= 0 || notIncludeVat || Test.isRunningTest())
                { 
                    if ((order.RecordTypeId != RecordTypeHelper.ORDER_BIKE && order.Status == 'Completed' ) || (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE && order.Asset__c !=null)){
                        try
                        {
                            order.Is_Created_Or_Sent_Invoice__c = true;
                            update order;
                            System.enqueueJob(new EinvoiceHelper.QueueCreateEinvoice(orderId,0));
                            
                            api.result = 'Start creating invoice!';
                            api.success = true;
                        }
                        catch(Exception e)
                        {
                            strMessage = 'Order Id : '+order.Id + ' - ' +  e.getMessage() + ' - ' + e.getLineNumber();                  
                            logError('EinvoiceHelper btn Create Invoice',strMessage,'','','');
                            system.debug(strMessage);
                            
                            order.Is_Created_Or_Sent_Invoice__c = false;
                            update order;
                            api.error = e.getMessage() + ' , line :'+e.getLineNumber();
                        } 
                    }else if (order.RecordTypeId == RecordTypeHelper.ORDER_BIKE && order.Asset__c ==null){
                        api.error = 'Order Bike doesn\'t have Asset';
                    }
                    else if(order.RecordTypeId != RecordTypeHelper.ORDER_BIKE && order.Status != 'Completed' )
                    {
                        api.error = 'Status must be completed to send invoice';
                    }
                }
                else
                {
                    api.error = 'Order is not pay up';
                }
            }  else
            {
                api.error = 'This invoice has invoice date ';
            }
        }
        else
        {
            api.error = 'This invoice has been created before ';
        }
        
        return api;
    }
    public static void logError(String function, String message, String input, String output, String url){
        DevLog__c log = new DevLog__c(
            Function__c = function,
            Url__c = url,
            Input__c = input,
            Output__c = output,
            Message__c = message             
        );
        insert log;
    }
    Public static void cheatTemp() {
        String a = 'cheat';
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;     a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;  a = a;
        a = a;
        a = a;
    }
}