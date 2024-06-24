/*******************************************************************************
 ** Class Name: SyncDMSOrderHelper
 ** Description: Class sync Order to DMS base on recordtype Order.
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class SyncDMSOrderHelper {
	public class CreateOrderQueue implements Queueable, Database.AllowsCallouts {
     	List<Id> orderIds;
        String urlCreateOrder;
        public CreateOrderQueue(List<Id> orderIds, String urlCreateOrder){
            this.orderIds = orderIds;
            this.urlCreateOrder = urlCreateOrder;
        }
        public void execute(QueueableContext context) {
            if(orderIds.isEmpty()){
                return;
            }
            Date dateFrom = date.today();
            Date dateTo = date.today();
            string strMessage = '';
            string strInput = JSON.serialize(orderIds);
            string strOutput = '';
            string strURL = '';
            try{
                List<Id> queryOrderIds = orderIds;
                Map<String, Schema.SObjectField> orderFieldMap = Order.sObjectType.getDescribe().fields.getMap();
                List<string> orderSelectFields = new List<String>(orderFieldMap.keySet());
                orderSelectFields.add('DO_DL__r.Branch__r.DO_DL_Code__c');
                orderSelectFields.add('Account.Account_Is_Primary__c');
                orderSelectFields.add('Asset__r.Frame_Number__c');
                orderSelectFields.add('Asset__r.Make_Model__c');
                orderSelectFields.add('Asset__r.Plate_No__c');
                orderSelectFields.add('DO_DL__r.DO_DL_Code__c');
                orderSelectFields.add('Province__r.Province_Code__c');
                orderSelectFields.add('District__r.District_Code__c');
                orderSelectFields.add('Cashier__r.Staff_Code__c');
                orderSelectFields.add('Cashier__r.Name');
                orderSelectFields.add('Mechanic__r.Staff_Code__c');
                orderSelectFields.add('Account.PersonEmail');
                orderSelectFields.add('Account.DOB__pc');
                orderSelectFields.add('Account.FirstName');
                orderSelectFields.add('Account.LastName');
                orderSelectFields.add('Account.Gender__c');
                orderSelectFields.add('Account.PersonMobilePhone');  
                String orderSoql = 'SELECT ' + String.join(orderSelectFields, ',');
                orderSoql += ' FROM Order';
                orderSoql += ' WHERE Id IN :queryOrderIds';            
                List<Order> orders = Database.query(orderSoql); 
                if(orders.isEmpty()){
                    return;
                }
                Map<String, Schema.SObjectField> orderItemFieldMap = OrderItem.sObjectType.getDescribe().fields.getMap();  
                List<string> orderItemSelectFields = new List<String>(orderItemFieldMap.keySet());
                orderItemSelectFields.add('Symptom_Condition__r.Name');
                orderItemSelectFields.add('Product2.Recordtype.Name');
                orderItemSelectFields.add('Product2.Superseding_Parts_Code__c');
                orderItemSelectFields.add('Product2.PartID__c');
                orderItemSelectFields.add('Product2.Job_ID__c');
                orderItemSelectFields.add('Product2.Name');
                orderItemSelectFields.add('Product2.ProductCode');
                orderItemSelectFields.add('Product2.ProductLineCode__c'); 
                String orderItemSoql = 'SELECT ' + String.join(orderItemSelectFields, ',');
                orderItemSoql += ' FROM OrderItem';
                orderItemSoql += ' WHERE OrderId IN :queryOrderIds'; 
                List<OrderItem> orderItems = Database.query(orderItemSoql);
                Map<Id, List<OrderItem>> mapOrderToItem = new Map<Id, List<OrderItem>>();
                for(OrderItem oi : orderItems){
                    if(!mapOrderToItem.containsKey(oi.OrderId)){
                        mapOrderToItem.put(oi.OrderId, new List<OrderItem>());
                    }
                    mapOrderToItem.get(oi.OrderId).add(oi);
                }
                
                Map<String, Schema.SObjectField> faultItemFieldMap = MotorcycleSituation__c.sObjectType.getDescribe().fields.getMap();  
                List<string> faultItemSelectFields = new List<String>(faultItemFieldMap.keySet());
                faultItemSelectFields.add('Symptom__r.Name');
                // Bổ sung section code
                faultItemSelectFields.add('Symptom__r.Section_Code__c');
                faultItemSelectFields.add('Condition__r.Name');
                faultItemSelectFields.add('Part_Name__r.ProductCode');
                String faultItemSoql = 'SELECT ' + String.join(faultItemSelectFields, ',');
                faultItemSoql += ' FROM MotorcycleSituation__c';
                faultItemSoql += ' WHERE Order__c IN :queryOrderIds';
                List<MotorcycleSituation__c> faultItems = Database.query(faultItemSoql);
                Map<Id, List<MotorcycleSituation__c>> mapFaultItem = new Map<Id, List<MotorcycleSituation__c>>();
                for(MotorcycleSituation__c fi : faultItems){
                    if(!mapFaultItem.containsKey(fi.Order__c)){
                        mapFaultItem.put(fi.Order__c, new List<MotorcycleSituation__c>());
                    }
                    mapFaultItem.get(fi.Order__c).add(fi);
                }
                
                List<Order> updatedOrders = new List<Order>();
                List<DevLog__c> logs = new List<DevLog__c>();
                
                for(Order o : orders){
                    Order updateOrder = new Order(Id = o.Id);
                    DevLog__c log = new DevLog__c(Order__c = o.Id, 
                                                  Name = o.Id,
                                                  Function__c = 'SyncApiDmsHelper.CreateOrderQueue' + '(' + urlCreateOrder + ')');
                    try {
                        if(!mapOrderToItem.containsKey(o.Id)) continue;
                        List<OrderItem> lstOrderItem = mapOrderToItem.get(o.Id);
                        List<MotorcycleSituation__c> lstFaultItem = mapFaultItem.containsKey(o.Id) ? mapFaultItem.get(o.Id) : new List<MotorcycleSituation__c> ();
                        HttpResponse response = new HttpResponse();
                        Object orderRequestData; 
                        if (urlCreateOrder.equals('proformaorder')) {
                            orderRequestData = (SObjectAPIDMSRespone.Proformaorder)SyncDMSHelper.convertProformaoOrderToRequestData(o, lstOrderItem);
                            log.Input__c = JSON.serialize(orderRequestData);
                        }
                        if (urlCreateOrder.equals('partssalesorder')) {
                            orderRequestData = (SObjectAPIDMSRespone.Partssalesorder)SyncDMSHelper.convertPartOrderRequestData(o, lstOrderItem);
                           	log.Input__c = JSON.serialize(orderRequestData);
                        }
                        if (urlCreateOrder.equals('mcsalesorder')) {
                            orderRequestData = (SObjectAPIDMSRespone.Modelcsalesorder)SyncDMSHelper.convertModelSaleRequestData(o, lstOrderItem);
                            log.Input__c = JSON.serialize(orderRequestData);
                        }
                        if (urlCreateOrder.equals('svwarrantyorder') || urlCreateOrder.equals('svrecallorder')) {
                            orderRequestData = (SObjectAPIDMSRespone.SVWarrantyRecallOrder)SyncDMSHelper.convertWarrantyRecallOrder(o, lstOrderItem, lstFaultItem);
                            log.Input__c = JSON.serialize(orderRequestData);
                        }
                        if (urlCreateOrder.equals('svfreecouponsorder')) {
                            orderRequestData = (SObjectAPIDMSRespone.SVFreeCouponOrder)SyncDMSHelper.convertFreeCouponOrderToRequestData(o, lstOrderItem);
                            log.Input__c = JSON.serialize(orderRequestData);
                        }
                        if (urlCreateOrder.equals('0kmsvwarrantyorder') || urlCreateOrder.equals('0kmsvrecallorder')) {
                            orderRequestData = (SObjectAPIDMSRespone.SVOKMWarrantyRecallOrder)SyncDMSHelper.convert0KMWarrantyRecallOrder(o, lstOrderItem, lstFaultItem);
                            log.Input__c = JSON.serialize(orderRequestData);
                        }
                        response = SyncDMSHelper.requestApiDMS(urlCreateOrder, JSON.serialize(orderRequestData), dateFrom, dateTo, o.DO_DL__r.Branch__r.DO_DL_Code__c);
                        if(response.getStatusCode() == 200) {
                            ResponseBody result = (ResponseBody)JSON.deserialize(response.getBody(), ResponseBody.class);
                            if(result.code == 200) {
                                updateOrder.Is_Sync__c = true;
                                updateOrder.YMHVN_Log__c = result.msg;
                            } else {
                                updateOrder.YMHVN_Log__c = result.code + ' - ' + result.msg;
                            }
                            log.Output__c = Json.serialize(result);
                            log.Message__c = result.msg;
                            strOutput = JSON.serialize(result);
                        } else {
                            updateOrder.YMHVN_Log__c = response.getStatus();
                            strOutput = response.getStatus();
                            log.Output__c = strOutput;
                            log.Message__c = 'Fail exception';
                        } 
                        logs.add(log);
                    } catch(Exception e){
                        updateOrder.YMHVN_Log__c = e.getMessage();
                        strMessage = e.getMessage() + ' - ' + e.getLineNumber();
                        logs.add(new DevLog__c(Function__c = 'SyncApiDmsHelper.CreateOrderQueue' + '(' + urlCreateOrder + ')',
                                               Message__c = strMessage,
                                               Input__c = o.Id,
                                               Name = o.Id,
                                               Order__c = o.Id));
                    }
                    updateOrder.Last_Sync__c = Datetime.now();
                    updatedOrders.add(updateOrder);
                }
                
                if(!updatedOrders.isEmpty()){
                    update updatedOrders;
                }
                
                if(!logs.isEmpty())
                    insert logs;
            } catch(Exception e){
                strMessage = e.getMessage() + ' - ' + e.getLineNumber();
                system.debug('error' + strMessage);
                SyncDMSHelper.logError('SyncApiDmsHelper.CreateOrderQueue' + urlCreateOrder, e.getMessage() + ' - ' + e.getLineNumber(), JSON.serialize(orderIds), null, null);
            }
            SyncDMSHelper.logError('SyncApiDmsHelper.CreateOrderQueue' + urlCreateOrder, strMessage, strInput, strOutput, urlCreateOrder);
        }
    }
    public class ResponseBody {
        public string msg {
            get;
            set;
        }
        public integer code {
            get;
            set;
        }
        public List<Object> data {
            get;
            set;
        }
    }
}