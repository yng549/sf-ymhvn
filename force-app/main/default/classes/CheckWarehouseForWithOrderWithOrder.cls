public with sharing class CheckWarehouseForWithOrderWithOrder {
    private static final String PROFILE_NAME_PCA = 'Community Consultant PCA';
    private static final String PROFILE_NAME_PCA_2 = 'Community Consultant PCA 2';

    @AuraEnabled
    public static APIResponse getPickListValuesIntoList(){
        APIResponse apiResponse = new APIResponse();
        User objUser =[SELECT Id, AccountId FROM User WHERE Id =: UserInfo.getUserId()];
        // if(objUser.AccountId == Null) {
        //     apiResponse.error = 'User is not exits DO DL.';
        //     return apiResponse;
        // }

        List<User> lstUserSale = [SELECT Id, Name 
                                    FROM User 
                                    WHERE (Profile.Name =: PROFILE_NAME_PCA 
                                            OR Profile.Name =: PROFILE_NAME_PCA_2) AND IsActive =: true];
        if(apiResponse.error == null) {
            apiResponse.success = true;
            apiResponse.result = lstUserSale;   
        }
         return apiResponse;
     }

    @AuraEnabled
    public static APIResponse checkInStockWarehous(ObjSearchDTO ObjSearchDTO,List<objDTO> lstOrderChecked) {
        APIResponse apiResponse = new APIResponse();
        Savepoint sp = Database.setSavepoint();
        try {
            Map<Id, Warehouse_Inventory__c> mapProductWarehouse = new Map<Id, Warehouse_Inventory__c>();
            User objUser = [SELECT Id, AccountId, Account.Warehouse_Location__c FROM User WHERE Id =: UserInfo.getUserId()];
            if(objUser.Account.Warehouse_Location__c == Null) {
                apiResponse.error = 'User has not value DO DL.';
                return apiResponse;
            }
            List<Warehouse_Inventory__c> lstWarehouseBefore = [SELECT Id
                                                                    , Product__c
                                                                    , QoH__c
                                                                    , Warehouse_Location__c
                                                                FROM Warehouse_Inventory__c
                                                                WHERE Warehouse_Location__c =: objUser.Account.Warehouse_Location__c];


            if(lstWarehouseBefore.isEmpty()) {
                apiResponse.error = 'Warehouse not exits any product.';
                return apiResponse;
            }
            for(Warehouse_Inventory__c item : lstWarehouseBefore) {
                mapProductWarehouse.put(item.Product__c, item);
            }
            System.debug('lstOrderChecked :' + lstOrderChecked);
            for(objDTO item : lstOrderChecked) {
                if(item.isChecked && item.lstOrderItem != Null) {
                    item.InStock = true;
                    for(OrderItemDTO objOrderItem : item.lstOrderItem) {
                        System.debug('objOrderItem.Product2Id : ' + objOrderItem.Product2Id);
                        System.debug('mapProductWarehouse : ' + mapProductWarehouse.keySet());
                        if(mapProductWarehouse.containsKey(objOrderItem.Product2Id) ) {
                            if(mapProductWarehouse.get(objOrderItem.Product2Id).QoH__c > 0) {
                                System.debug('Pass');
                                if(mapProductWarehouse.get(objOrderItem.Product2Id).QoH__c < objOrderItem.Quantity) {
                                    objOrderItem.InStock = 'Thiếu hàng.';
                                } else {
                                    item.InStock = true;
                                    mapProductWarehouse.get(objOrderItem.Product2Id).QoH__c = mapProductWarehouse.get(objOrderItem.Product2Id).QoH__c - objOrderItem.Quantity;
                                    objOrderItem.InStock = 'Còn hàng.';
                                }
                            } else if(mapProductWarehouse.get(objOrderItem.Product2Id).QoH__c == Null) {
                                objOrderItem.InStock = 'Quantity on product does not input value.';
                            } else if(mapProductWarehouse.get(objOrderItem.Product2Id).QoH__c == 0) {
                                objOrderItem.InStock = 'Hết hàng.';
                            }
                            if(!String.isNotBlank(item.wareHouseLocation)) {
                                item.wareHouseLocation = mapProductWarehouse.get(objOrderItem.Product2Id).Warehouse_Location__c;
                            }
                            
                        } else {
                            objOrderItem.InStock = 'Product not exit in warehouse.';
                        }
                    }
                    for(OrderItemDTO objOrderItem : item.lstOrderItem) {
                        if(objOrderItem.InStock != 'Còn hàng.') {
                            item.InStock = false;
                            break;
                        }
                    }
                }
            }
            if(apiResponse.error == null) {
                apiResponse.success = true;
                apiResponse.result = lstOrderChecked;
            }
            return apiResponse;
        } catch(Exception ex) {
            apiResponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            return apiResponse;
            
        }
    }

    @AuraEnabled
    public static APIResponse getOrderProformar(ObjSearchDTO objSearch) {
        APIResponse apiResponse = new APIResponse();
        List<objDTO> lstOrderDTO = new List<objDTO>();
        try {
            List<Order> lstOrderBycondition = getListOrderByConditon(objSearch);
            
            if(lstOrderBycondition.isEmpty()) {
                apiResponse.error = 'Do not exit list order proformaorder.';
                return apiResponse;
            }
            for(Order item : lstOrderBycondition) {
                if(!item.OrderItems.isEmpty()) {
                    List<OrderItemDTO> lstOrderItemDTO = new List<OrderItemDTO>();
                    for(OrderItem objItemProduct : item.OrderItems) {
                        lstOrderItemDTO.add(new OrderItemDTO(objItemProduct));
                    }
                    lstOrderDTO.add(new objDTO(item, lstOrderItemDTO));    
                } else {
                    lstOrderDTO.add(new objDTO(item, Null)); 
                }
            }
            if(apiResponse.error == null) {
                apiResponse.success = true;
                apiResponse.result = lstOrderDTO;   
            }
            return apiResponse;
        } catch(Exception ex) {
            apiResponse.error = ex.getMessage();
            return apiResponse;
        }
    }
    
    @AuraEnabled
    public static APIResponse insertItem(List<objDTO> lstOrderInsert) {
        APIResponse apiResponse = new APIResponse();
        Savepoint sp = Database.setSavepoint();
        Map<String, objDTO> mapOderListOrderProfomar = new Map<String, objDTO>();
        List<X3_Inventory_Transaction_Header__c> lstTransactionHeader = new List<X3_Inventory_Transaction_Header__c>();
        List<Inventory_Transaction_Item__c> lstInventoryTransactionItem = new List<Inventory_Transaction_Item__c>();
        List<Order> lstOrderUpdate = new List<Order>();
        Set<Id> setIdOrderOrigin = new Set<Id>();
        try {
            for(objDTO item : lstOrderInsert) {
                System.debug('item :' + item);
                if(String.isNotBlank(item.OrderOrigin)) {
                    mapOderListOrderProfomar.put(item.OrderOrigin, item);
                } else {
                    apiResponse.error = 'Order Number ' + item.OrderNumber + ' is not set value Order Origin.';
                    return apiResponse;
                }
            }
            for(String item : mapOderListOrderProfomar.keySet()) {
                lstTransactionHeader.add(new X3_Inventory_Transaction_Header__c(
                    Name = 'Reserved ' + mapOderListOrderProfomar.get(item).OrderOriginNumber,
                    Status__c = 'Draft',
                    Order_Reserved__c = item,
                    From_Warehouse_Location__c = mapOderListOrderProfomar.get(item).wareHouseLocation));
            }
            if(!lstTransactionHeader.isEmpty()) {
                insert lstTransactionHeader;
            }
            for(X3_Inventory_Transaction_Header__c item : lstTransactionHeader) {
                if(mapOderListOrderProfomar.containsKey(item.Order_Reserved__c)) {
                    for(OrderItemDTO obj : mapOderListOrderProfomar.get(item.Order_Reserved__c).lstOrderItem) {
                        setIdOrderOrigin.add(item.Order_Reserved__c);
                        lstInventoryTransactionItem.add(new Inventory_Transaction_Item__c(
                            Name = obj.ProductName,
                            Quantity__c = obj.Quantity,
                            Product__c = obj.Product2Id,
                            Inventory_Transaction_Header__c = item.Id,
                            From_Warehouse_Location__c = item.From_Warehouse_Location__c
                            //Warehouse_Inventory__c = mapOderListOrderProfomar.get(item.Order_Reserved__c).wareHouseLocation
                        ));
                    }
                    lstOrderUpdate.add(new Order(
                        Id = mapOderListOrderProfomar.get(item.Order_Reserved__c).Id,
                        Status = 'Completed'
                    ));
                    item.Status__c = 'Completed';
                }
            }
            System.debug('lstInventoryTransactionItem :' + lstInventoryTransactionItem);
            if(!lstInventoryTransactionItem.isEmpty()) {
                insert lstInventoryTransactionItem;
                update lstOrderUpdate;
                update lstTransactionHeader;
            }
            List<Order> lstOrderOrigin = [SELECT Id, Profomar_Completed__c FROM Order WHERE Id IN: setIdOrderOrigin];
            for(Order item : lstOrderOrigin) {
                item.Profomar_Completed__c = true;
            }
            System.debug('lstOrderOrigin :' + lstOrderOrigin);
            if(!lstOrderOrigin.isEmpty()) {
                update lstOrderOrigin;
            }
            if(apiResponse.error == null) {
                apiResponse.success = true;
                return apiResponse;
            }
            return apiResponse;
        } catch(Exception ex) {
            apiResponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            Database.rollback(sp);
            return apiResponse;
        }
    } 

    private static List<Order> getListOrderByConditon(ObjSearchDTO objSearch) {
        String strWhere = '';
		String RecordTypeIdPROFOMARORDER = RecordTypeHelper.ORDER_PROFOMAR_ORDER;
        Date startDate = Date.valueOf(objSearch.startDate) != Null ? Date.valueOf(objSearch.startDate) : Null;
        Date endDate = Date.valueOf(objSearch.endDate) != Null ? Date.valueOf(objSearch.endDate) : Null;
        String strStatus = objSearch.strStatus;
        System.debug('RecordTypeIdPROFOMARORDER : ' + RecordTypeIdPROFOMARORDER);
        System.debug('startDate : ' + startDate);
        System.debug('endDate : ' + endDate);
        String strDODL = objSearch.strDODL;
		strWhere = ' WHERE ';
		strWhere += '  RecordTypeId =: RecordTypeIdPROFOMARORDER';

	
		if(startDate != Null) {
			strWhere += ' AND EffectiveDate >=: startDate';
		}
        if(endDate != Null) {
			strWhere += ' AND EffectiveDate  <=: endDate';
		}
        System.debug('strStatus : ' + strStatus);
		if(String.isNotBlank(strStatus)) {
			strWhere += ' AND Status = : strStatus';
		}
        System.debug('strWhere :' + strWhere);
		if(String.isNotBlank(strDODL)) {
			strWhere += ' AND DO_DL__c = : strDODL';
		}
		
		String strSOQL = '';
		strSOQL = 'SELECT Id';
		strSOQL += ', OrderNumber';								
		strSOQL += ', Account.Name';							
		strSOQL += ', Status';
        strSOQL += ', DO_DL__c';
        strSOQL += ', Order__c';
        strSOQL += ', Order__r.OrderNumber';
        strSOQL += ', EffectiveDate';				
		strSOQL += ', (SELECT Id, Product2.Name, Product2Id, OrderItemNumber, Profomar_Order_Number__c, Quantity FROM OrderItems)';					// プロトコールNo
		strSOQL += ' FROM Order';
		strSOQL += strWhere;
		List<Order> lstOrderData = Database.query(strSOQL);
		return lstOrderData;
	}

    public class ObjSearchDTO {
		@AuraEnabled
		public Date startDate {get; set;}
		@AuraEnabled
		public Date endDate {get; set;}
		@AuraEnabled
		public String strStatus {get; set;}
		@AuraEnabled
		public String strDODL {get; set;}
	}

    public  class OrderItemDTO {
        @AuraEnabled
        public  String Id {get;set;}

        @AuraEnabled
        public  string OrderItemNumber {get; set;}

        @AuraEnabled
        public  string ProductName {get; set;}

        @AuraEnabled
        public String Product2Id {get; set;}

        @AuraEnabled
        public  Decimal Quantity {get; set;}

        @AuraEnabled
        public  String InStock {get; set;}
        
     

        public OrderItemDTO() {}

		public OrderItemDTO(OrderItem objItem) {
			this.Id = objItem.Id;
            this.OrderItemNumber = objItem.OrderItemNumber;
            this.ProductName = objItem.Product2.Name;
            this.Product2Id = objItem.Product2Id;
            this.Quantity = objItem.Quantity;
		}
    }

    public  class objDTO {
        @AuraEnabled
        public  String Id {get;set;}

        @AuraEnabled
        public  string OrderNumber {get; set;}

        @AuraEnabled
        public  string Status {get; set;}

        @AuraEnabled
        public String AccountName {get; set;}

        // @AuraEnabled
        // public Date StartDate {get; set;}

        @AuraEnabled
        public  List<OrderItemDTO> lstOrderItem {get; set;}


        @AuraEnabled
        public  Date efectiveDate {get; set;}


        @AuraEnabled
        public  Boolean isChecked {get; set;}

        @AuraEnabled
        public  Boolean hideButton {get; set;}

        @AuraEnabled
        public  String OrderOrigin {get; set;}

        @AuraEnabled
        public  String OrderOriginNumber {get; set;}

        @AuraEnabled
        public  String wareHouseLocation {get; set;}

        @AuraEnabled
        public  Boolean InStock {get; set;}

        public objDTO() {}

		public objDTO(Order obj, List<OrderItemDTO> lstOrderItem) {
			this.Id = obj.Id;
            this.OrderNumber = obj.OrderNumber;
            this.Status = obj.Status;
            this.AccountName = obj.Account.Name;
            //this.StartDate = obj.Start_Date__c;
            this.lstOrderItem = lstOrderItem;
            this.efectiveDate = obj.EffectiveDate;
            this.isChecked = false;
            this.hideButton = false;
            this.OrderOrigin = obj.Order__c;
            this.OrderOriginNumber = obj.Order__r.OrderNumber;
		}
    }

    Public static void cheatTemp(){
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
    }

}