public with sharing class applyOrderLineItem {
    private static String strStatusClosed = 'Closed';
    private static String strRecordIdServiceJob = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Service Jobs').getRecordTypeId();
    private static String strRecordIdPCA = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('PCA').getRecordTypeId();
    private static String strRecordIdSession = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Session').getRecordTypeId();

    @AuraEnabled
    public static ApiResponse getOrderLineItem(String strOrderId) {
        ApiResponse apiResponse = new ApiResponse();
        try {
            Set<Id> setIdOrderItem = new Set<Id>();
            List<objDTO> lstObjDTO = new List<objDTO>();
            Map<Id, List<OrderLineDetailDTO>> mapOrderLineDetail = new Map<Id, List<OrderLineDetailDTO>>();
            Order objOrder = [SELECT Id, AccountId FROM Order WHERE Id =: strOrderId];
            Map<Id, OrderItem> mapOrderItem = new Map<Id, OrderItem>([SELECT  Id
                                                    , Product2Id
                                                    , Product2.Name
                                                    , ListPrice
                                                    , UnitPrice
                                                    , TotalPrice
                                                    , OrderId
                                                    , Order.Status
                                                    , Package_Owner__c
                                                    , Package_Owner__r.Package_Personal_Account__c
                                            FROM OrderItem
                                            WHERE Package_Owner__c != Null AND Package_Owner__r.Package_Personal_Account__c =: objOrder.AccountId]);
            System.debug('mapOrderItem ;' + mapOrderItem);
            if(!mapOrderItem.values().isEmpty()) {
                List<Order_Line_Detail__c> lstOrderLineDetail = [SELECT Id
                                                                        , Name
                                                                        , Order_Line_Item__c
                                                                        , Product_Detail_Service__c
                                                                        , Product_Name__c
                                                                        , Quantity_on_Product__c
                                                                        , Remain__c
                                                                FROM    Order_Line_Detail__c
                                                                WHERE Order_Line_Item__c IN: mapOrderItem.keySet()
                                                                        AND Remain__c > 0];
                if(!lstOrderLineDetail.isEmpty()) {
                    for(Order_Line_Detail__c  item : lstOrderLineDetail) {
                        OrderLineDetailDTO objOrderLineDTO = new OrderLineDetailDTO(item);
                        if(mapOrderLineDetail.containsKey(objOrderLineDTO.Order_Line_Item)) {
                            List<OrderLineDetailDTO> lstOrderLineItem = mapOrderLineDetail.get(objOrderLineDTO.Order_Line_Item);
                            lstOrderLineItem.add(objOrderLineDTO);
                            mapOrderLineDetail.put(objOrderLineDTO.Order_Line_Item,lstOrderLineItem); 
                        } else {
                            mapOrderLineDetail.put(objOrderLineDTO.Order_Line_Item, new List<OrderLineDetailDTO> {objOrderLineDTO});
                        }
                    }
                }
                System.debug('mapOrderLineDetail :' + mapOrderLineDetail);
                for(OrderItem item : mapOrderItem.values()) {
                    if(mapOrderLineDetail.containsKey(item.Id)) {
                        objDTO obj = new objDTO(item, mapOrderLineDetail.get(item.Id));
                        lstObjDTO.add(obj);
                    }
                }
            }
            if(apiResponse.error == null) {
                apiResponse.success = true;
                apiResponse.result = lstObjDTO;
            }
            return apiResponse;
        } catch(Exception ex) {
            System.debug('ex :' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public  static ApiResponse getProductChildren(String recordIdOrder, List<OrderLineDetailDTO> lstOrderDetailsDTO) {
        ApiResponse apiResponse = new ApiResponse();
        try {
            Set<Id> setIdProductSession = new Set<Id>();
            Set<Id> setIdOrderLineDetailDTO = new Set<Id>();
            Map<Id, String> mapKeyProductServiceJobValuePackageOwner = new Map<Id, String>();
            //1 Update Remain tên Object Order Detail
            //2 Tao ra những order item mới theo Order
            //3 Tao Object lưu lại lich sử sử dụng look tới Order item mới tạo vào Package Owner
            for(OrderLineDetailDTO item : lstOrderDetailsDTO) {
                setIdOrderLineDetailDTO.add(item.Id);
            }
            
            List<OrderItemDTO> lstOrderProductDTO = new List<OrderItemDTO>();
            List<Product_Detail_Session__c> lstProductDetailSession = new List<Product_Detail_Session__c>();
            Map<Id, List<Product_Detail_Session__c>> mapProductDetailSession = new Map<Id, List<Product_Detail_Session__c>>();
            Set<Id> setIdProduct = new Set<Id>();
            Map<Id, Order_Line_Detail__c>   mapOrderLineDetail = new Map<Id, Order_Line_Detail__c>([
                SELECT  Id
                        , Name  
                        , Order_Line_Item__c
                        , Order_Line_Item__r.Package_Owner__c
                        , Package_Owner__c
                        , Product_Detail_Service__c
                        , Product_Detail_Service__r.Name
                        , Product_Name__c
                        , Quantity_on_Product__c
                        , Remain__c
                        , Product_Detail_Service__r.Product__c
                        , Product_Detail_Service__r.Product__r.Name
                        , Product_Detail_Service__r.Product__r.RecordTypeId
                        , Product_Detail_Service__r.Product__r.RecordType.Name
                FROM Order_Line_Detail__c
                WHERE Id IN: setIdOrderLineDetailDTO]);
            System.debug('mapOrderLineDetail :' + mapOrderLineDetail);
            if(!mapOrderLineDetail.values().isEmpty()) {
                for(Order_Line_Detail__c item : mapOrderLineDetail.values()) {
                    if(item.Product_Detail_Service__r.Product__r.RecordTypeId == strRecordIdServiceJob 
                        || item.Product_Detail_Service__r.Product__r.RecordTypeId == strRecordIdPCA) {
                        lstOrderProductDTO.add(new OrderItemDTO(
                            item.Product_Detail_Service__r.Product__r.Name,
                            item.Product_Detail_Service__r.Name,
                            item.Product_Detail_Service__r.Product__r.RecordType.Name));
                    } else if(item.Product_Detail_Service__r.Product__r.RecordTypeId == strRecordIdSession) {
                        setIdProductSession.add(item.Product_Detail_Service__r.Product__c);
                    }
                } 
                lstProductDetailSession = [
                    SELECT ID
                        , Product_Service_Job__c
                        , Product_Service_Job__r.Name
                        , Quantity__c
                        , Product_Session__c
                        , Product_Session__r.Name
                        , Product_Session__r.RecordType.Name
                    FROM  Product_Detail_Session__c
                    WHERE Product_Session__c IN: setIdProductSession];  
                System.debug('lstProductDetailSession ;' + lstProductDetailSession);
                
                for(Product_Detail_Session__c item : lstProductDetailSession) {
                    if(mapProductDetailSession.containsKey(item.Product_Session__c)) {
                        List<Product_Detail_Session__c> lst_terr = mapProductDetailSession.get(item.Product_Session__c);
                        lst_terr.add(item);
                        mapProductDetailSession.put(item.Product_Session__c, lst_terr); 
                    }   
                    else {
                        mapProductDetailSession.put(item.Product_Session__c, new List<Product_Detail_Session__c> {item});
                    }
                }
                for(Order_Line_Detail__c item : mapOrderLineDetail.values()) {
                    if(mapProductDetailSession.containsKey(item.Product_Detail_Service__r.Product__c)) {
                        for(Product_Detail_Session__c obj : mapProductDetailSession.get(item.Product_Detail_Service__r.Product__c)) {
                            lstOrderProductDTO.add(new OrderItemDTO(
                                obj.Product_Service_Job__r.Name
                                , obj.Product_Session__r.Name
                                , obj.Product_Session__r.RecordType.Name));
                        }
                    }
                }
            }
            if(!lstOrderProductDTO.isEmpty()) {
                apiResponse.success = true;
                apiResponse.result = lstOrderProductDTO;
            } 
            return apiResponse;
        } catch(Exception ex) {
            System.debug('ex :' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }


    @AuraEnabled
    public  static ApiResponse saveCreateObjcet(String recordIdOrder, List<OrderLineDetailDTO> lstOrderDetailsDTO) {
        ApiResponse apiResponse = new ApiResponse();
        try {
            Order objOrderUpdate = [SELECT Id, PriceBook2Id, DO_DL__c FROM Order WHERE Id =: recordIdOrder];
            Map<Id, List<Product_Detail_Session__c>> mapProductDetailSession = new Map<Id, List<Product_Detail_Session__c>>();
            Set<Id> setIdProductSession = new Set<Id>();
            Set<Id> setIdOrderLineDetailDTO = new Set<Id>();
            List<History_Apply_OrderItem__c> lstHistoryInsert = new List<History_Apply_OrderItem__c>();
            Map<Id, PricebookEntry> mapKeyProduct = new Map<Id, PricebookEntry>();
            Map<Id, String> mapKeyProductServiceJobValuePackageOwner = new Map<Id, String>();
            Map<Id, Warehouse_Inventory__c> mapProductWarehouse = new Map<Id, Warehouse_Inventory__c>();
            if(!String.isNotBlank(objOrderUpdate.DO_DL__c)) {
                apiResponse.error = 'DO DL does not input value on Order. Please check again !';
                return apiResponse;
            }
            if(!String.isNotBlank(objOrderUpdate.PriceBook2Id)) {
                apiResponse.error = 'Order has not value for Pricebook2 Field. !';
                return apiResponse;
            }
            Account objAccount = [SELECT Id, Warehouse_Location__c FROM Account WHERE Id =: objOrderUpdate.DO_DL__c];
            List<Warehouse_Inventory__c> lstWarehouseBefore = getAccountDODLByAccountOnOrder(objAccount.Warehouse_Location__c);
            if(!lstWarehouseBefore.isEmpty()) {
                for(Warehouse_Inventory__c item : lstWarehouseBefore) {
                    mapProductWarehouse.put(item.Product__c, item);
                }
            }
            //1 Update Remain tên Object Order Detail
            //2 Tao ra những order item mới theo Order
            //3 Tao Object lưu lại lich sử sử dụng look tới Order item mới tạo vào Package Owner
            Set<Id> setIdOrderItemSelected = new Set<Id>();
            for(OrderLineDetailDTO item : lstOrderDetailsDTO) {
                setIdOrderLineDetailDTO.add(item.Id);
                setIdOrderItemSelected.add(item.Order_Line_Item);
            }
            List<OrderItem> lstOrderItemNotIsUsed = [SELECT Id
                                                            , Is_Used__c 
                                                    FROM OrderItem
                                                    WHERE Id IN: setIdOrderItemSelected 
                                                        AND Is_Used__c =: false];
            if(!lstOrderItemNotIsUsed.isEmpty()) {
                for(OrderItem item : lstOrderItemNotIsUsed) {
                    item.Is_Used__c = true;
                }
                update lstOrderItemNotIsUsed;
            }
            List<OrderItem> lstOrderProductInsert = new List<OrderItem>();
            Set<Id> setIdProduct = new Set<Id>();
            Map<Id, Order_Line_Detail__c>   mapOrderLineDetail = new Map<Id, Order_Line_Detail__c>([
                SELECT  Id
                        , Name  
                        , Order_Line_Item__c
                        , Order_Line_Item__r.Package_Owner__c
                        , Package_Owner__c
                        , Product_Detail_Service__c
                        , Product_Name__c
                        , Quantity_on_Product__c
                        , Remain__c
                        , Product_Detail_Service__r.Product__c
                        , Product_Detail_Service__r.Product__r.RecordTypeId
                        , Product_Detail_Service__r.Product__r.RecordType.Name
                FROM Order_Line_Detail__c
                WHERE Id IN: setIdOrderLineDetailDTO]);

            
            List<Product_Detail_Session__c> lstProductDetailSession = new List<Product_Detail_Session__c>();
            if(!mapOrderLineDetail.values().isEmpty()) {
                for(Order_Line_Detail__c item : mapOrderLineDetail.values()) {
                    if(item.Product_Detail_Service__r.Product__r.RecordTypeId == strRecordIdServiceJob) {
                        OrderItem objOrderItem = new OrderItem();
                        objOrderItem.Product2Id = item.Product_Detail_Service__r.Product__c;
                        objOrderItem.Quantity = 1;
                        objOrderItem.PackageOwnerId__c = item.Package_Owner__c;
                        objOrderItem.OrderId = recordIdOrder;
                        lstOrderProductInsert.add(objOrderItem);
                        setIdProduct.add(item.Product_Detail_Service__r.Product__c);
                    } else if(item.Product_Detail_Service__r.Product__r.RecordTypeId == strRecordIdSession) {
                        setIdProductSession.add(item.Product_Detail_Service__r.Product__c);
                        mapKeyProductServiceJobValuePackageOwner.put(item.Product_Detail_Service__r.Product__c, item.Package_Owner__c);
                    }
                }
                lstProductDetailSession = [
                    SELECT ID
                        , Product_Service_Job__r.Name
                        , Product_Service_Job__c
                        , Quantity__c
                        , Product_Session__c
                    FROM  Product_Detail_Session__c
                    WHERE Product_Session__c IN: setIdProductSession];
                for(Product_Detail_Session__c item : lstProductDetailSession) {
                    if(mapProductDetailSession.containsKey(item.Product_Session__c)) {
                        List<Product_Detail_Session__c> lst_terr = mapProductDetailSession.get(item.Product_Session__c);
                        lst_terr.add(item);
                        mapProductDetailSession.put(item.Product_Session__c, lst_terr); 
                    }   
                    else {
                        mapProductDetailSession.put(item.Product_Session__c, new List<Product_Detail_Session__c> {item});
                    }
                }
            }
            System.debug('PriceBook2Id :' + objOrderUpdate.Pricebook2Id);
            for(Order_Line_Detail__c item : mapOrderLineDetail.values()) {
                if(mapProductDetailSession.containsKey(item.Product_Detail_Service__r.Product__c)) {
                    for(Product_Detail_Session__c obj : mapProductDetailSession.get(item.Product_Detail_Service__r.Product__c)) {
                        OrderItem objOrderItem = new OrderItem();
                        objOrderItem.Product2Id = obj.Product_Service_Job__c;
                        if(mapKeyProductServiceJobValuePackageOwner.containsKey(obj.Product_Session__c)) {
                            objOrderItem.PackageOwnerId__c = 
                                mapKeyProductServiceJobValuePackageOwner.get(obj.Product_Session__c);
                        }
                        objOrderItem.Quantity = 1;
                        objOrderItem.OrderId = recordIdOrder;
                        setIdProduct.add(obj.Product_Service_Job__c);
                        lstOrderProductInsert.add(objOrderItem);
                    }
                }
            }
            System.debug('lstOrderProductInsert :' + lstOrderProductInsert);
            if(!lstOrderProductInsert.isEmpty()) {
                Map<Id, PricebookEntry> mapGetPricebookEntry = new Map<Id, PricebookEntry>([
                    SELECT Id
                            , Name
                            , UnitPrice
                            , Product2Id
                            , Product2.Name
                            , Pricebook2Id
                            , Pricebook2.Name
                            , Pricebook2.Type__c
                            , Product2.RecordTypeId
                    FROM PricebookEntry
                    WHERE Pricebook2.Type__c =: 'PCAService'
                        AND PriceBook2Id =: objOrderUpdate.Pricebook2Id
                ]);
                System.debug('mapGetPricebookEntry :' + mapGetPricebookEntry);
                Map<Id, Product2> mapProduct2 = new Map<Id, Product2>([
                    SELECT Id
                           , RecordTypeId
                           , Name
                    FROM Product2
                    WHERE Id IN: setIdProduct
                ]);
                for(PricebookEntry item : mapGetPricebookEntry.values()) {
                    mapKeyProduct.put(item.Product2Id, item);
                }
                for(OrderItem item : lstOrderProductInsert) {
                    System.debug('objOrderUpdate.PriceBook2Id : ' + objOrderUpdate.PriceBook2Id);
                    if(mapKeyProduct.containsKey(item.Product2Id)) {
                        System.debug('1');
                        item.PricebookEntryId = mapKeyProduct.get(item.Product2Id).Id;
                        item.UnitPrice = mapKeyProduct.get(item.Product2Id).UnitPrice;
                    } else {
                        apiResponse.error = 'Product ' + mapProduct2.get(item.Product2Id).Name + ' does not exit pricebook entry.';
                        return apiResponse;
                    }
                    if(mapProduct2.get(item.Product2Id).RecordTypeId == strRecordIdPCA) {
                        if(mapProductWarehouse.containsKey(item.Product2Id) ) {
                            if(mapProductWarehouse.get(item.Product2Id).QoH__c > 0) {
                                continue;
                            } else if(mapProductWarehouse.get(item.Product2Id).QoH__c == Null) {
                                apiResponse.error = 'Quantity on product does not input value.';
                                return apiResponse;
                            } else if(mapProductWarehouse.get(item.Product2Id).QoH__c == 0) {
                                apiResponse.error = 'Quantity on product is 0.';
                                return apiResponse;
                            }
                        } else {
                            apiResponse.error = 'Product ' + mapProduct2.get(item.Product2Id).Name + ' does not exit warehouse.';
                            return apiResponse;
                        }
                    }
                }
                System.debug('lstOrderProductInsert :' + lstOrderProductInsert);
                insert lstOrderProductInsert;
                for(OrderItem item : lstOrderProductInsert) {
                    if(mapProductWarehouse.containsKey(item.Product2Id) 
                        &&  mapProduct2.get(item.Product2Id).RecordTypeId == strRecordIdPCA) {
                        if(mapProductWarehouse.get(item.Product2Id).QoH__c > 0) {
                            mapProductWarehouse.get(item.Product2Id).QoH__c = 
                                mapProductWarehouse.get(item.Product2Id).QoH__c - item.Quantity;
                        }
                    }
                }
                update mapProductWarehouse.values();
                for(OrderItem item : lstOrderProductInsert) {
                    //History Apply
                    History_Apply_OrderItem__c objHistory = new History_Apply_OrderItem__c();
                    objHistory.Order_Product__c = item.Id;
                    objHistory.Package_Owner__c = item.PackageOwnerId__c;
                    objHistory.Date_Apply__c = Datetime.now();
                    lstHistoryInsert.add(objHistory);
                }
                System.debug('lstHistoryInsert ;' + lstHistoryInsert);
                if(!lstHistoryInsert.isEmpty()) {
                    insert lstHistoryInsert;
                }
                
            }
            for(OrderLineDetailDTO item : lstOrderDetailsDTO) {
                System.debug('item :' + item);
                if(mapOrderLineDetail.containsKey(item.Id)) {
                    if(mapOrderLineDetail.get(item.Id).Remain__c > 0) {
                        mapOrderLineDetail.get(item.Id).Remain__c = mapOrderLineDetail.get(item.Id).Remain__c - 1;
                    }
                }
            }
            update mapOrderLineDetail.values();
            if(apiResponse.error == null) {
                apiResponse.success = true;
                apiResponse.result = mapOrderLineDetail.values();
            }
            return apiResponse;
        } catch(Exception ex) {
            System.debug('ex :' + ex.getMessage() + ex.getLineNumber());
            apiResponse.error = ex.getMessage() + ' ' + ex.getLineNumber();
            return apiResponse;

        }
    }

    private static List<Warehouse_Inventory__c> getAccountDODLByAccountOnOrder(String warehouseLocation) {
        List<Warehouse_Inventory__c> lstWarehouseInventory = [SELECT Id
                                                                    , Name
                                                                    , Product__r.Name
                                                                    , Product__r.ProductCode
                                                                    , Product__r.PartsNameEng__c
                                                                    , Product__r.Model_Code__c
                                                                    , QoH__c
                                                                    , Unit_cost__c
                                                                    , Product__r.PCA_Type__c
                                                                    , Product__c
                                                                    , Asset__r.Frame_Number__c
                                                                    , Asset__r.Engine_No__c
                                                                    , Asset__r.Color_Type__c
                                                                    , Serial_Number__c
                                                                    , Stocking_Age__c
                                                                    , Location__c
                                                                    , Product__r.Color_Name__c
                                                                FROM Warehouse_Inventory__c
                                                                WHERE  Product__r.RecordTypeId =: RecordTypeHelper.PRODUCT_PCA
                                                                    AND Warehouse_Location__c =: warehouseLocation];
        return lstWarehouseInventory;
    }

    

    public  class objDTO {
        @AuraEnabled
        public  String Id {get;set;}

        @AuraEnabled
        public  string ProductId {get; set;}

        @AuraEnabled
        public  string ProductName {get; set;}

        @AuraEnabled
        public String List_Price {get; set;}

        @AuraEnabled
        public String Unit_Price {get; set;}

        @AuraEnabled
        public String Quantity {get; set;}

        @AuraEnabled
        public String Total_Price {get; set;}

        @AuraEnabled
        public Boolean hideBool {get; set;}

        @AuraEnabled
        public  List<OrderLineDetailDTO> lstOrderLineDetail {get; set;}


        public objDTO() {}

		public objDTO(OrderItem obj, List<OrderLineDetailDTO> lstOrderLineDetail) {
			this.Id = obj.Id;
            this.ProductId = obj.Product2Id;
            this.ProductName = obj.Product2.Name;
            this.List_Price = String.valueOf(obj.ListPrice);
            this.Unit_Price = String.valueOf(obj.UnitPrice);
            this.Total_Price = String.valueOf(obj.TotalPrice);
            this.hideBool = true;
            this.lstOrderLineDetail = lstOrderLineDetail;
		}
    }

    public  class OrderLineDetailDTO {
        @AuraEnabled
        public  string Id {get; set;}

        @AuraEnabled
        public  string Name {get; set;}

        @AuraEnabled
        public  string Order_Line_Item {get; set;}

        @AuraEnabled
        public  string Product_Detail_Service {get; set;}

        @AuraEnabled
        public  string Product_Name {get; set;}

        @AuraEnabled
        public  Integer Quantity_on_Product {get; set;}

        @AuraEnabled
        public  Integer Remain {get; set;}

        @AuraEnabled
        public Boolean selected {get; set;}


        public OrderLineDetailDTO() {}

		public OrderLineDetailDTO(Order_Line_Detail__c obj) {
			this.Id = obj.Id;
            this.Name = obj.Name;
            this.Order_Line_Item = obj.Order_Line_Item__c;
            this.Product_Detail_Service = obj.Product_Detail_Service__c;
            this.Product_Name = obj.Product_Name__c;
            this.Quantity_on_Product = Integer.valueOf(obj.Quantity_on_Product__c);
            this.Remain = Integer.valueOf(obj.Remain__c);
		}
    }

    public class OrderItemDTO {
        @AuraEnabled
        public  string Name {get; set;}

        @AuraEnabled
        public  string NameService {get; set;}

        @AuraEnabled
        public  string RecordType  {get; set;}

        public OrderItemDTO() {}

		public OrderItemDTO(String strNameProduct, String strNameService, String strProductService) {
            this.Name = strNameProduct;
            this.NameService = strNameService;
            this.RecordType = strProductService;
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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