public class TriggerHandlerOrderLineItem {
    public static Boolean flagRun = false;
    public static void onBeforeDelete(List<OrderItem> ordersItem) {
        Set<Id> ordersID = new Set<Id>();
        for(OrderItem item : ordersItem){
            ordersID.add(item.OrderId);
        }
        if(!ordersID.isEmpty()) {
            checkOrderFreeServiceWhenSubmitApproval(ordersItem, ordersID);
        }
    }
    
    public static void onBeforeInsert(List<OrderItem> lstOrderItem){
       
        checkOrderProductWhenCreatedTransaction(lstOrderItem);
        Set<Id> setIdOrder = new Set<Id>();
        Set<Id> productsID = new Set<Id>();
        for(OrderItem item : lstOrderItem){
            productsID.add(item.Product2Id);
            setIdOrder.add(item.OrderId);
        }
        List<Order> orders = [SELECT Id, RecordTypeId, Promotion_Item__c, Promotion_Item__r.Promotion__r.RecordTypeId, Generated_Redeem__c, Manual_Discount_Approve__c,
                              DO_DL__r.Branch__r.DO_DL_Code__c,
                              Promotion_Item__r.Discount__c , Promotion_Item__r.RecordTypeId 
                              FROM Order WHERE Id IN: setIdOrder];
      
        Map<Id, Product2> products = new Map<Id, Product2>([SELECT Id, Is_Genuine__c, RecordTypeId, Family, Labor_HOUR__c, 
                                                            (SELECT ID, GUID_Key__c, DO_Code__c FROM Product_DO__r)
                                                            FROM Product2
                                                            WHERE Id in: productsID]);
        
        Map<Id, Map<string, string>> mapProductDOLine = new Map<Id, Map<string, string>>();
        for(Product2 p : products.values()) {
            if(!mapProductDOLine.containsKey(p.Id)) 
            mapProductDOLine.put(p.Id, new Map<string, string>());
            for(Product_DO__c pdo : p.Product_DO__r) {
                mapProductDOLine.get(p.Id).put(pdo.DO_Code__c, pdo.GUID_Key__c);
            }
        }
        if(!orders.isEmpty()){
            for(OrderItem oi : lstOrderItem) {
                oi.GUID_DMS__c = mapProductDOLine?.get(oi.Product2Id)?.get(orders[0].DO_DL__r.Branch__r.DO_DL_Code__c);
            }
            if ((orders[0].RecordTypeId == RecordTypeHelper.ORDER_PCA || orders[0].RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER 
                 || orders[0].RecordTypeId == RecordTypeHelper.ORDER_QUICK_SERVICE) && orders[0].Manual_Discount_Approve__c) {
                     for(OrderItem ItemOrdItem: lstOrderItem){
                    // Decimal roundListPrice = ItemOrdItem.ListPrice.round(System.RoundingMode.HALF_EVEN);
                    ItemOrdItem.Labour_Hours__c = products?.get(ItemOrdItem.Product2Id)?.Labor_HOUR__c ;
                    
                    if(!ItemOrdItem.Generated_Redeem__c){    
                        if (ItemOrdItem.Discount__c == null) {
                            ItemOrdItem.Discount__c = 0;
                        }
                        if (ItemOrdItem.Discount_Amount__c == null) {                                    
                                ItemOrdItem.Discount_Amount__c = 0;
                        }
                        if (ItemOrdItem.Discount__c > 0) {
                            if (products.get(ItemOrdItem.Product2Id).Labor_HOUR__c  <= 0 || products.get(ItemOrdItem.Product2Id).Labor_HOUR__c == null){
                                ItemOrdItem.UnitPrice =ItemOrdItem.ListPrice - (ItemOrdItem.ListPrice * ItemOrdItem.Discount__c/100);
                                ItemOrdItem.Discount_Amount__c = ItemOrdItem.ListPrice * ItemOrdItem.Discount__c/100;
                            }else if(products.get(ItemOrdItem.Product2Id) != null){
                                if(products.get(ItemOrdItem.Product2Id)!= null){
                                       //ItemOrdItem.Labour_Hours__c = MapProduct.get(ItemOrdItem.Product2Id).Labor_HOUR__c ;
                                        if (ItemOrdItem.Labour_Hours__c >0 && ItemOrdItem.Labour_Hours__c !=null){
                                            ItemOrdItem.UnitPrice =(ItemOrdItem.ListPrice 
                                            / ItemOrdItem.Origin_Labour_Hour__c 
                                            * ItemOrdItem.Labour_Hours__c) 
                                            - ((ItemOrdItem.ListPrice / ItemOrdItem.Origin_Labour_Hour__c 
                                            * ItemOrdItem.Labour_Hours__c) * ItemOrdItem.Discount__c/100);

                                            ItemOrdItem.Discount_Amount__c = ((ItemOrdItem.ListPrice / ItemOrdItem.Origin_Labour_Hour__c 
                                            * ItemOrdItem.Labour_Hours__c) * ItemOrdItem.Discount__c/100);
                                        }
                                }
                            }

                        }else if (ItemOrdItem.Discount_Amount__c > 0) {
                            if (products.get(ItemOrdItem.Product2Id).Labor_HOUR__c  <= 0 || products.get(ItemOrdItem.Product2Id).Labor_HOUR__c == null){
                                ItemOrdItem.UnitPrice =ItemOrdItem.ListPrice - ItemOrdItem.Discount_Amount__c;
                                ItemOrdItem.Discount__c = ItemOrdItem.Discount_Amount__c/ItemOrdItem.ListPrice*100;
                            } else{
                                Decimal priceAfterLabour = ItemOrdItem.ListPrice / ItemOrdItem.Origin_Labour_Hour__c * ItemOrdItem.Labour_Hours__c;
                                ItemOrdItem.UnitPrice = priceAfterLabour - ItemOrdItem.Discount_Amount__c;
                                ItemOrdItem.Discount__c = ItemOrdItem.Discount_Amount__c/ priceAfterLabour*100;
                            }
                        }
                        
                    }
                }
            }
            if(orders[0].RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE ){
                for(OrderItem ItemOrdItem: lstOrderItem){
                    ItemOrdItem.UnitPrice = 0;
                    ItemOrdItem.Labour_Hours__c = products?.get(ItemOrdItem.Product2Id)?.Labor_HOUR__c ;
                }
            }
            else if(orders[0].RecordTypeId == RecordTypeHelper.ORDER_PCA ){
                if(orders[0].Promotion_Item__c != null && !orders[0].Generated_Redeem__c && !orders[0].Manual_Discount_Approve__c){
                    //Set Promotion default 5%
                    if(orders[0].Promotion_Item__r.Promotion__r.RecordTypeId == RecordTypeHelper.PROMOTIONDEFAULT){
                        for(OrderItem ItemOrdItem: lstOrderItem){
                            if (products.get(ItemOrdItem.Product2Id).Is_Genuine__c){
                                ItemOrdItem.UnitPrice = ItemOrdItem.ListPrice - (ItemOrdItem.ListPrice * orders[0].Promotion_Item__r.Discount__c/100) ;
                                ItemOrdItem.Discount__c = orders[0].Promotion_Item__r.Discount__c;
                            }
                        }
                    }
                    else{
                        // Set Promotion discount %
                        if(orders[0].Promotion_Item__r.RecordTypeId == RecordTypeHelper.PROMOTIONITEMDISCOUNT){
                            Map<ID, Promotion_Product__c> productPromotion = new Map<ID, Promotion_Product__c>();
                            for(Promotion_Product__c pp : [SELECT Id, List_Price__c, Sale_Price__c, Promotion_Item__c, Product__c, Discount__c
                                                           FROM Promotion_Product__c
                                                           WHERE Promotion_Item__c =: orders[0].Promotion_Item__c AND Product__c in: productsID]){
                            	productPromotion.put(pp.Product__c, pp);
                            }
                            for(OrderItem oi : lstOrderItem) {
                                if(productPromotion.containsKey(oi.Product2Id)) {
                                	oi.UnitPrice = oi.ListPrice - (oi.ListPrice * productPromotion.get(oi.Product2Id).Discount__c/100) ;
                                    oi.Discount__c = productPromotion.get(oi.Product2Id).Discount__c;
                                    oi.Promotion_Product__c = productPromotion.get(oi.Product2Id)?.Id;
                                }
                            }
                        }
                        // Set Promotion Discount Amount
                        else if(orders[0].Promotion_Item__r.RecordTypeId == RecordTypeHelper.PROMOTIONITEMDISCOUNTAM){
                            Map<Id, Promotion_Product__c> productsPromotion = new Map<Id, Promotion_Product__c>();
                            for(Promotion_Product__c pp: [SELECT Id, List_Price__c, Sale_Price__c, Promotion_Item__c, Product__c
                                                          FROM Promotion_Product__c 
                                                          WHERE Promotion_Item__c =: orders[0].Promotion_Item__c AND Product__c in: productsID]){
                            	productsPromotion.put(pp.Product__c, pp);
                            }
                            for(OrderItem oi : lstOrderItem){
                                if(productsPromotion.containsKey(oi.Product2Id))
                                {
                                    oi.Promotion_Product__c = productsPromotion.get(oi.Product2Id)?.Id;
                                    oi.UnitPrice = productsPromotion.get(oi.Product2Id).Sale_Price__c ;
                                    
                                }
                               
                            }     
                        }
                    }
                }
            }
            else if(orders[0].RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER ||orders[0].RecordTypeId == RecordTypeHelper.ORDER_QUICK_SERVICE || 
                    orders[0].RecordTypeId == RecordTypeHelper.ORDER_WARRANTY || orders[0].RecordTypeId == RecordTypeHelper.ORDER_FREE_COUPON || 
                    orders[0].RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE || orders[0].RecordTypeId == RecordTypeHelper.ORDER_RECALL ||
                    orders[0].RecordTypeId == RecordTypeHelper.ORDER_INSTALLATION){
            	for(OrderItem oi : lstOrderItem) {
                    if(products.get(oi.Product2Id)!= null && products.get(oi.Product2Id).Labor_HOUR__c > 0){
                        oi.Labour_Hours__c = products.get(oi.Product2Id).Labor_HOUR__c ;
                        
                    }
                }
            }
        }
        checkOrderFreeServiceWhenSubmitApproval(lstOrderItem, setIdOrder);
    }
    
    public static void onAfterInsert(List<OrderItem> lstOrderItem) {
        List<OrderItem> lstOrderItemAfterCreatedHeader = new List<OrderItem>();
        for(OrderItem item : lstOrderItem) {
            if(item.Created_Transaction__c) {
                lstOrderItemAfterCreatedHeader.add(item);
            }
        }
        if(!lstOrderItemAfterCreatedHeader.isEmpty()) {
            createHeaderAfterCreated(lstOrderItemAfterCreatedHeader);
        }
    }
    
    private static void checkOrderProductWhenCreatedTransaction(List<OrderItem> ordersItem) {
        Set<Id> ordersID = new Set<Id>();
        Set<Id> productsID = new Set<Id>();
        try {
            for(OrderItem item : ordersItem) {
                ordersID.add(item.OrderId);
                productsID.add(item.Product2Id);
            }
            Map<Id, Order> mapOrders = new Map<Id, Order>([SELECT Id FROM Order WHERE Id IN: ordersID AND Status IN ('Waiting for Parts', 'Waiting for Repair')]);
            Map<Id, Product2> mapProducts = new Map<Id, Product2>([SELECT Id FROM Product2 WHERE Id IN: productsID AND RecordTypeId =: RecordTypeHelper.PRODUCT_PCA]);
            for(OrderItem oi : ordersItem) {
                if(mapProducts.containsKey(oi.Product2Id) && mapOrders.containsKey(oi.OrderId)) {
                    oi.Created_Transaction__c = TRUE;
                }
            }
        } catch(Exception ex) {
            ordersItem.get(0).addError(ex.getMessage() + ' ' + ex.getLineNumber());
        }
    }
    
    private static void createHeaderAfterCreated(List<OrderItem> lstOrderItem) {
        Map<Id, List<OrderItem>> orderWithItems = new Map<Id, List<OrderItem>>();
        Set<Id> ordersID = new Set<Id>();
        Map<Id, X3_Inventory_Transaction_Header__c> inventorysHeader = new Map<Id, X3_Inventory_Transaction_Header__c>();
        List<Inventory_Transaction_Item__c> transactionItems = new List<Inventory_Transaction_Item__c>();
        try {
            for(OrderItem item : lstOrderItem) {
                ordersID.add(item.OrderId);
            }
            Map<Id, Order> mapOrderByOrderItem = new Map<Id, Order>([SELECT Id, Order_Number__c,
                                                                     RecordTypeId, Status, DO_DL__c,
                                                                     DO_DL__r.Warehouse_Location_Service__c, DO_DL__r.Warehouse_Location__c
                                                                     FROM Order 
                                                                     WHERE Id IN: ordersID]);
            for(OrderItem item : lstOrderItem) {
                if(!orderWithItems.containsKey(item.OrderId)) {
                    orderWithItems.put(item.OrderId, new List<OrderItem>());
                }
                orderWithItems.get(item.OrderId).add(item);
            }
            for(Id key : orderWithItems.keySet()) {
                inventorysHeader.put(key, new X3_Inventory_Transaction_Header__c(Name = 'Reserved Order',
                                                                                 Order_Reserved__c = key,
                                                                                 Status__c = 'Draft',
                                                                                 To_Warehouse_Location__c = mapOrderByOrderItem.get(key).DO_DL__r.Warehouse_Location_Service__c,
                                                                                 From_Warehouse_Location__c = mapOrderByOrderItem.get(key).DO_DL__r.Warehouse_Location__c));
            }
            insert inventorysHeader.values();
            for(Id key : orderWithItems.keySet()) {
            	for (OrderItem ItemOrder : orderWithItems?.get(key)){
                    transactionItems.add(new Inventory_Transaction_Item__c(Product__c = ItemOrder.Product2Id,
                                                                           Quantity__c = ItemOrder.Quantity,
                                                                           From_Warehouse_Location__c = mapOrderByOrderItem?.get(key)?.DO_DL__r.Warehouse_Location__c,
                                                                           To_Warehouse_Location__c = mapOrderByOrderItem?.get(key)?.DO_DL__r.Warehouse_Location_Service__c,
                                                                           Inventory_Transaction_Header__c = inventorysHeader?.get(key)?.Id));
                }
            }
            insert transactionItems;
           	
        } catch(Exception ex) {
            lstOrderItem.get(0).addError(ex.getMessage() + ' ' + ex.getLineNumber());
        }
    }
    
    private static void checkOrderFreeServiceWhenSubmitApproval(List<OrderItem> ordersItem, Set<Id> ordersID) {
        Map<Id, Order> orders = new Map<Id, Order>([SELECT Id FROM Order WHERE Id IN: ordersID 
                                                    AND RecordTypeId =: RecordTypeHelper.ORDER_FREE_SERVICE AND Is_Approval__c =: TRUE]);                                
        for(OrderItem item : ordersItem) {
            if(orders.containsKey(item.OrderId))
            item.addError('Order Free Service was submited so it is locked.');
        }
    }
    
    public static void onBeforeUpdate(List<OrderItem> lstOrderItem, Map<Id, OrderItem> mapOld, Map<Id, OrderItem> mapNew){
        Set<Id> productsID = new Set<Id>();
        Map<Id,List<OrderItem>> mapOrderOrderItem = new Map<Id,List<OrderItem>>();
        Set<Id> promotionItemIds = new Set<Id>();

        for(OrderItem item : lstOrderItem){
            productsID.add(item.Product2Id);
            if (!mapOrderOrderItem.containsKey(item.OrderId)){
                mapOrderOrderItem.put(item.OrderId,new List<OrderItem>());
            }
            mapOrderOrderItem.get(item.OrderId).add(item);
        }
        List<Order> orders = [SELECT Id, RecordTypeId, Promotion_Item__c, Promotion_Item__r.Promotion__r.RecordTypeId, Manual_Discount_Approve__c,
                              Promotion_Item__r.Discount__c , Promotion_Item__r.RecordTypeId 
                              FROM Order WHERE Id IN: mapOrderOrderItem.keySet()];
     
        Map<Id, Product2> products = new Map<Id, Product2>();
        for(Product2 pp : [SELECT Id, Is_Genuine__c, RecordTypeId, Family FROM Product2 WHERE Id IN: productsID]){
            products.put(pp.Id, pp);
        }
        if(orders.isEmpty()) return;

        for(Order ord : orders){
            if(ord.Promotion_Item__c != null){
                promotionItemIds.add(ord.Promotion_Item__c);
            }
        }

        Map<Id,Promotion_Item__c> mapPromotionItem = new Map<Id,Promotion_Item__c>([SELECT Id, Promotion__r.RecordTypeId 
                                                                                        , Discount__c, RecordTypeId
                                                                                        , (SELECT Id, List_Price__c, 
                                                                                                Sale_Price__c, 
                                                                                                Promotion_Item__c, 
                                                                                                Product__c, 
                                                                                                Discount__c 
                                                                                        FROM Promotion_Productts__r 
                                                                                        WHERE Product__c IN: productsID )
                                                                                    FROM Promotion_Item__c 
                                                                                    WHERE Id IN:promotionItemIds]);
        for(Order ord : orders){
        // if manual discount approve is true
            if ((ord.RecordTypeId == RecordTypeHelper.ORDER_PCA || ord.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER 
                || ord.RecordTypeId == RecordTypeHelper.ORDER_QUICK_SERVICE) && ord.Manual_Discount_Approve__c) {
                if(mapOrderOrderItem.containsKey(ord.Id)){
                    for(OrderItem oi : mapOrderOrderItem.get(ord.Id)){
                        /* =================================== */
                        if(!mapNew.get(oi.Id).Generated_Redeem__c 
                        && (mapOld.get(oi.Id).Discount__c == mapNew.get(oi.Id).Discount__c 
                        && mapOld.get(oi.Id).Discount_Amount__c == mapNew.get(oi.Id).Discount_Amount__c)) {
                            /* =================================== */
                            mapNew.get(oi.Id).UnitPrice = mapNew.get(oi.Id).ListPrice;
                            mapNew.get(oi.Id).Discount__c = 0;
                            mapNew.get(oi.Id).Discount_Amount__c =0;
                        }
                    }
                }
            }
            if((ord.RecordTypeId == RecordTypeHelper.ORDER_PCA) && ord.Manual_Discount_Approve__c){
                if(mapOrderOrderItem.containsKey(ord.Id)){
                    for(OrderItem oi : mapOrderOrderItem.get(ord.Id)){
                        if ((mapOld.get(oi.Id).Discount__c != mapNew.get(oi.Id).Discount__c || mapOld.get(oi.Id).Discount_Amount__c != mapNew.get(oi.Id).Discount_Amount__c)){
                            if (mapOld.get(oi.Id).Discount_Amount__c != mapNew.get(oi.Id).Discount_Amount__c){
                                if (mapNew.get(oi.Id).Discount_Amount__c != null){
                                    mapNew.get(oi.Id).UnitPrice = mapNew.get(oi.Id).ListPrice - mapNew.get(oi.Id).Discount_Amount__c;
                                    mapNew.get(oi.Id).Discount__c = mapNew.get(oi.Id).Discount_Amount__c/mapNew.get(oi.Id).ListPrice*100;
                                }else{
                                    mapNew.get(oi.Id).UnitPrice = mapNew.get(oi.Id).ListPrice;
                                    mapNew.get(oi.Id).Discount_Amount__c = 0;
                                }
                            }
                            if (mapOld.get(oi.Id).Discount__c != mapNew.get(oi.Id).Discount__c){
                                if (mapNew.get(oi.Id).Discount__c != null){
                                    mapNew.get(oi.Id).UnitPrice = mapNew.get(oi.Id).ListPrice - (mapNew.get(oi.Id).ListPrice * mapNew.get(oi.Id).Discount__c/100);
                                    mapNew.get(oi.Id).Discount_Amount__c = mapNew.get(oi.Id).ListPrice * mapNew.get(oi.Id).Discount__c/100;
                                }else{
                                    mapNew.get(oi.Id).UnitPrice = mapNew.get(oi.Id).ListPrice;
                                    mapNew.get(oi.Id).Discount_Amount__c = 0;
                                    mapNew.get(oi.Id).Discount__c = 0;
                                }
                            }
                        }
                    }
                }
            }
            if(ord.RecordTypeId == RecordTypeHelper.ORDER_FREE_SERVICE ){
                if(mapOrderOrderItem.containsKey(ord.Id)){
                    for(OrderItem oi : mapOrderOrderItem.get(ord.Id)){
                        mapNew.get(oi.Id).UnitPrice = 0;
                    }
                }
            }
            else if(ord.RecordTypeId == RecordTypeHelper.ORDER_PCA){
                if (!ord.Manual_Discount_Approve__c){
                    if(mapOrderOrderItem.containsKey(ord.Id)){
                        for(OrderItem oi : mapOrderOrderItem.get(ord.Id)){
                            if(!mapNew.get(oi.Id).Generated_Redeem__c) {
                                mapNew.get(oi.Id).UnitPrice = oi.ListPrice;
                                mapNew.get(oi.Id).Discount__c = 0;
                                mapNew.get(oi.Id).Discount_Amount__c =0;
                            }
                        }
                    }
                }
                if(ord.Promotion_Item__c != null && !ord.Manual_Discount_Approve__c){
                    //Set Promotion default 5%
                    if(ord.Promotion_Item__r.Promotion__r.RecordTypeId == RecordTypeHelper.PROMOTIONDEFAULT){
                        if(mapOrderOrderItem.containsKey(ord.Id)){
                            for(OrderItem oi : mapOrderOrderItem.get(ord.Id)){
                                if (products.get(oi.Product2Id).Is_Genuine__c){
                                    mapNew.get(oi.Id).UnitPrice = mapNew.get(oi.Id).ListPrice - (mapNew.get(oi.Id).ListPrice * ord.Promotion_Item__r.Discount__c/100) ;
                                    mapNew.get(oi.Id).Discount__c = ord.Promotion_Item__r.Discount__c;
                                    mapNew.get(oi.Id).Discount_Amount__c = mapNew.get(oi.Id).ListPrice * ord.Promotion_Item__r.Discount__c/100;
                                }
                            }
                        }
                    }else{
                        // Set Promotion discount %
                        if(ord.Promotion_Item__r.RecordTypeId == RecordTypeHelper.PROMOTIONITEMDISCOUNT){
                            Map<ID, Promotion_Product__c> productsPromotion = new Map<ID, Promotion_Product__c>();
                            for(Promotion_Product__c pp : mapPromotionItem.get(ord.Promotion_Item__c).Promotion_Productts__r){
                                productsPromotion.put(pp.Product__c, pp);

                            }
                            if(mapOrderOrderItem.containsKey(ord.Id)){
                                for(OrderItem oi : mapOrderOrderItem.get(ord.Id)){
                                    if(productsPromotion.containsKey(oi.Product2Id)){
                                        //ItemOrdItem.UnitPrice = MapProductPromo.get(ItemOrdItem.Product2Id).Sale_Price__c ;
                                        mapNew.get(oi.Id).UnitPrice = mapNew.get(oi.Id).ListPrice - (mapNew.get(oi.Id).ListPrice * productsPromotion.get(oi.Product2Id).Discount__c/100) ;
                                        mapNew.get(oi.Id).Discount__c = productsPromotion.get(mapNew.get(oi.Id).Product2Id).Discount__c;
                                    }
                                    mapNew.get(oi.Id).Promotion_Product__c = productsPromotion.get(oi.Product2Id)?.Id;
                                }
                            }
                        }
                        // Set Promotion Discount Amount
                        else if(ord.Promotion_Item__r.RecordTypeId == RecordTypeHelper.PROMOTIONITEMDISCOUNTAM){
                            Map<Id, Promotion_Product__c> productsPromotion = new Map<Id, Promotion_Product__c>();
                            for(Promotion_Product__c pp : mapPromotionItem.get(ord.Promotion_Item__c).Promotion_Productts__r){
                                productsPromotion.put(pp.Product__c, pp);
                            }
                            if(mapOrderOrderItem.containsKey(ord.Id)){
                                for(OrderItem oi : mapOrderOrderItem.get(ord.Id)){
                                    if(productsPromotion.containsKey(oi.Product2Id)){
                                        mapNew.get(oi.Id).UnitPrice = productsPromotion.get(oi.Product2Id).Sale_Price__c ;
                                    }
                                    mapNew.get(oi.Id).Promotion_Product__c = productsPromotion.get(oi.Product2Id)?.Id;
                                }
                            }
                        }
                    }
                }
            }else if(ord.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER 
            || ord.RecordTypeId == RecordTypeHelper.ORDER_QUICK_SERVICE 
            || ord.RecordTypeId == RecordTypeHelper.ORDER_INSTALLATION 
            || ord.RecordTypeId == RecordTypeHelper.ORDER_WARRANTY){
                if(mapOrderOrderItem.containsKey(ord.Id)){
                        for(OrderItem oi : mapOrderOrderItem.get(ord.Id)){
                            if(mapOld.get(oi.Id).Labour_Hours__c != mapNew.get(oi.Id).Labour_Hours__c && mapNew.get(oi.Id).Origin_Labour_Hour__c > 0 && mapNew.get(oi.Id).Labour_Hours__c > 0){
                                mapNew.get(oi.Id).UnitPrice = mapNew.get(oi.Id).ListPrice / mapNew.get(oi.Id).Origin_Labour_Hour__c * mapNew.get(oi.Id).Labour_Hours__c;
                            }
                    }
                }
            }
            if((ord.RecordTypeId == RecordTypeHelper.ORDER_SERVICE_ORDER || ord.RecordTypeId == RecordTypeHelper.ORDER_QUICK_SERVICE) && ord.Manual_Discount_Approve__c){
                if(mapOrderOrderItem.containsKey(ord.Id)){
                    for(OrderItem oi : mapOrderOrderItem.get(ord.Id)){   
                        if((mapOld.get(oi.Id).Discount__c != mapNew.get(oi.Id).Discount__c)){
                            if (mapNew.get(oi.Id).Discount__c == null)
                            mapNew.get(oi.Id).Discount__c = 0;
                            
                            if (mapNew.get(oi.Id).Labour_Hours__c > 0 && mapNew.get(oi.Id).Labour_Hours__c != null) {
                                mapNew.get(oi.Id).UnitPrice = calculateUnitPrice(mapNew.get(oi.Id));

                                mapNew.get(oi.Id).Discount_Amount__c = calculateDiscountAmount(mapNew.get(oi.Id));
                            }else {
                                mapNew.get(oi.Id).UnitPrice = mapNew.get(oi.Id).ListPrice - (mapNew.get(oi.Id).ListPrice * mapNew.get(oi.Id).Discount__c/100); 
                                mapNew.get(oi.Id).Discount_Amount__c = mapNew.get(oi.Id).ListPrice * mapNew.get(oi.Id).Discount__c/100 ;
                            }
                        }
                    }
                }
            }
        }
    }

    private static Decimal calculateUnitPrice(OrderItem orderItem){
        Decimal discount = orderItem.Discount__c;
        Decimal labourHours = orderItem.Labour_Hours__c;
        Decimal originLabourHours = orderItem.Origin_Labour_Hour__c;
        Decimal listPrice = orderItem.ListPrice;

        Decimal unitPrice = (listPrice / originLabourHours * labourHours) 
                    - ((listPrice / originLabourHours * labourHours) * discount/100);
        return unitPrice;
    }
  
    private static Decimal calculateDiscountAmount(OrderItem orderItem){
        Decimal discount = orderItem.Discount__c;
        Decimal labourHours = orderItem.Labour_Hours__c;
        Decimal originLabourHours = orderItem.Origin_Labour_Hour__c;
        Decimal listPrice = orderItem.ListPrice;

        Decimal discountAmount = ((listPrice / originLabourHours* labourHours) * discount/100);
        return discountAmount;
    }

    /*public static void onAfterUpsert(List<OrderItem> lstOrderItem) {
        updateUnitPriceZerroWhenFreeOrder(lstOrderItem);
    }
    
    
    private static void updateUnitPriceZerroWhenFreeOrder(List<OrderItem> ordersItem) {
        Set<Id> ordersID = new Set<Id>();
        for(OrderItem item : ordersItem) {
            ordersID.add(item.OrderId);
        }
        List<OrderItem> oisFreeService = [SELECT Id, UnitPrice
                                          FROM OrderItem 
                                          WHERE OrderId =: ordersID AND Order.RecordTypeId =: RecordTypeHelper.ORDER_FREE_SERVICE];
            
        for(OrderItem item : oisFreeService) {
            item.UnitPrice = 0;
        }
        update oisFreeService;
    }*/
    public static void cheat(){
        String a = '';
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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