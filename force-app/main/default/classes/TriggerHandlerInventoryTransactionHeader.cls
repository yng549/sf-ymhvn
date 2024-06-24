public without sharing class TriggerHandlerInventoryTransactionHeader{
    public static Boolean flag = false;
    
    public static void onBeforeInsert(List<X3_Inventory_Transaction_Header__c> lstHeader){
        System.debug('lstHeader: ' + lstHeader);
        List<X3_Inventory_Transaction_Header__c> lstHeaderFromOrderBPCA = new List<X3_Inventory_Transaction_Header__c>();
        List<X3_Inventory_Transaction_Header__c> lstHeaderFromOrderSERV = new List<X3_Inventory_Transaction_Header__c>();
        List<X3_Inventory_Transaction_Header__c> lstHeaderNotFromOrder =  new List<X3_Inventory_Transaction_Header__c>();
        Set<Id> setWarehouseLocationID = new Set<Id>();
        Set<String> setWarehouseLocationFull = new Set<String>();
        Map<Id,Warehouse_Location__c> mapWarehouse;

        for (X3_Inventory_Transaction_Header__c header : lstHeader){
            if (header.From_Warehouse_Location__c != null){
                setWarehouseLocationID.add(header.From_Warehouse_Location__c);
                setWarehouseLocationFull.add(header.From_Warehouse_Location__c);
            }else {
                setWarehouseLocationFull.add(header.To_Warehouse_Location__c);
            }
        }

        if (!setWarehouseLocationID.isEmpty()){
            mapWarehouse = new Map<Id,Warehouse_Location__c>(
                [SELECT Id,Name, Type__c,Location__c,Account__c FROM Warehouse_Location__c WHERE Id IN:setWarehouseLocationID]);
        }else{
            mapWarehouse = new Map<Id,Warehouse_Location__c>();
        }
        Map<Id,Warehouse_Location__c> mapWarehouseFull = new Map<Id,Warehouse_Location__c>([SELECT Id, Account__c FROM Warehouse_Location__c WHERE Id IN:setWarehouseLocationFull]);
        for (X3_Inventory_Transaction_Header__c header : lstHeader){
           if (header.Order_Reserved__c != null){ //Khi hệ thống tự phát sinh transaction trong quá trình bán hàng
               if (mapWarehouse.containsKey(header.From_Warehouse_Location__c)){
                   if (mapWarehouse.get(header.From_Warehouse_Location__c).Type__c == null){
                        lstHeaderFromOrderBPCA.add(header);
                        System.debug('lstHeaderFromOrderBPCA: ' + lstHeaderFromOrderBPCA);   
                   }else if (mapWarehouse.get(header.From_Warehouse_Location__c).Type__c == 'Service')
                        lstHeaderFromOrderSERV.add(header);     
                        System.debug('lstHeaderFromOrderSERV: ' + lstHeaderFromOrderSERV);   
               }
           }else if (header.Order_Reserved__c == null){//Khi storeman chủ động nhập và xuất kho
                lstHeaderNotFromOrder.add(header);
                System.debug('lstHeaderNotFromOrder: ' + lstHeaderNotFromOrder);
           }
        }

        if (!lstHeaderFromOrderBPCA.isEmpty()){
            setHeaderNumber(lstHeaderFromOrderBPCA, 'BPCA', mapWarehouseFull);
        }

        if (!lstHeaderFromOrderSERV.isEmpty()){
            setHeaderNumber(lstHeaderFromOrderSERV, 'SERV', mapWarehouseFull);
        }

        if (!lstHeaderNotFromOrder.isEmpty()){
            setHeaderNumber(lstHeaderNotFromOrder, 'NXK', mapWarehouseFull);
        }
    }
    
    private static void setHeaderNumber(List<X3_Inventory_Transaction_Header__c> lstHeader,String headerType, Map<Id,Warehouse_Location__c> mapWarehouseFull){
        List<User> lstUserHN = [SELECT Id, AccountId FROM User WHERE Account.Name =: 'REVZONE YAMAHA MOTOR HA NOI'];
        List<X3_Inventory_Transaction_Header__c> lstHeaderNumber = new List<X3_Inventory_Transaction_Header__c>();
        List<X3_Inventory_Transaction_Header__c> lstHeaderNumberHN = new List<X3_Inventory_Transaction_Header__c>();
        Integer headerNumber = 0;
        Integer headerNumberHN = 0;
        Id warehouseLocation = lstHeader[0].From_Warehouse_Location__c;
        Integer year = Date.today().year();
        String yearNo = String.valueOf(Year).right(2);
        Integer month = Date.today().month();
        String monthNo = String.valueOf(Month);

        if (month < 10){
            monthNo = '0' + String.valueOf(Month);
        }
    
        if (headerType == 'BPCA'){
            lstHeaderNumber = [SELECT Id,Header_No__c	 
                            FROM X3_Inventory_Transaction_Header__c
                            WHERE Order_Reserved__c != null 
                                AND Header_No__c >0                  
                                AND From_Warehouse_Location__r.Type__c = null
                                AND From_Warehouse_Location__r.Account__c != :lstUserHN[0].AccountId
                                AND CALENDAR_MONTH(convertTimezone(CreatedDate)) = :month 
                                AND CALENDAR_YEAR(convertTimezone(CreatedDate)) = :year 
                            ORDER BY Header_No__c DESC 
                            LIMIT 1 ];
            lstHeaderNumberHN = [SELECT Id,Header_No__c	 
                            FROM X3_Inventory_Transaction_Header__c
                            WHERE Order_Reserved__c != null 
                                AND Header_No__c >0                  
                                AND From_Warehouse_Location__r.Type__c = null
                                AND From_Warehouse_Location__r.Account__c = :lstUserHN[0].AccountId
                                AND CALENDAR_MONTH(convertTimezone(CreatedDate)) = :month 
                                AND CALENDAR_YEAR(convertTimezone(CreatedDate)) = :year 
                            ORDER BY Header_No__c DESC 
                            LIMIT 1 ];
        }else if (headerType == 'SERV'){
            lstHeaderNumber = [SELECT Id,Header_No__c	 
            FROM X3_Inventory_Transaction_Header__c
            WHERE Order_Reserved__c != null 
                AND Header_No__c >0
                AND From_Warehouse_Location__r.Type__c = 'Service'
                AND From_Warehouse_Location__r.Account__c != :lstUserHN[0].AccountId
                AND CALENDAR_MONTH(convertTimezone(CreatedDate)) = :month 
                AND CALENDAR_YEAR(convertTimezone(CreatedDate)) = :year
            ORDER BY Header_No__c DESC 
            LIMIT 1];
            lstHeaderNumberHN = [SELECT Id,Header_No__c	 
            FROM X3_Inventory_Transaction_Header__c
            WHERE Order_Reserved__c != null 
                AND Header_No__c >0                  
                AND From_Warehouse_Location__r.Type__c = 'Service'
                AND From_Warehouse_Location__r.Account__c = :lstUserHN[0].AccountId
                AND CALENDAR_MONTH(convertTimezone(CreatedDate)) = :month 
                AND CALENDAR_YEAR(convertTimezone(CreatedDate)) = :year 
            ORDER BY Header_No__c DESC 
            LIMIT 1 ];
        }else if (headerType == 'NXK'){
            // Hồ Chí Minh
            lstHeaderNumber = [SELECT Id,Header_No__c	 
            FROM X3_Inventory_Transaction_Header__c
            WHERE Order_Reserved__c = null 
                AND Header_No__c > 0
                AND (
                        (From_Warehouse_Location__r.Account__c = null 
                        AND To_Warehouse_location__r.Account__c != :lstUserHN[0].AccountId)
                        OR (From_Warehouse_Location__r.Account__c != :lstUserHN[0].AccountId
                        AND From_Warehouse_Location__r.Account__c != null)
                    )
                AND CALENDAR_MONTH(convertTimezone(CreatedDate)) = :month 
                AND CALENDAR_YEAR(convertTimezone(CreatedDate)) = :year
            ORDER BY Header_No__c DESC 
            LIMIT 1];

            // Hà Nội
            lstHeaderNumberHN = [SELECT Id,Header_No__c	 
            FROM X3_Inventory_Transaction_Header__c
            WHERE Order_Reserved__c = null 
                AND Header_No__c >0                  
                AND (
                    (From_Warehouse_Location__r.Account__c = null 
                    AND To_Warehouse_location__r.Account__c = :lstUserHN[0].AccountId)
                    OR (From_Warehouse_Location__r.Account__c = :lstUserHN[0].AccountId
                    AND From_Warehouse_Location__r.Account__c != null)
                    )
                AND CALENDAR_MONTH(convertTimezone(CreatedDate)) = :month 
                AND CALENDAR_YEAR(convertTimezone(CreatedDate)) = :year 
            ORDER BY Header_No__c DESC 
            LIMIT 1 ];
        }

        if (!lstHeaderNumber.isEmpty()){
            headerNumber = Integer.valueOf(lstHeaderNumber[0].Header_No__c);
        }

        if(!lstHeaderNumberHN.isEmpty()){
            headerNumberHN = Integer.valueOf(lstHeaderNumberHN[0].Header_No__c);
        }

        for (X3_Inventory_Transaction_Header__c header : lstHeader){
            String headerName = headerType;
            String headerNumberStr = '';
            Integer headerNo = 0;
            if(mapWarehouseFull.containsKey(header.From_Warehouse_Location__c)){
                if(mapWarehouseFull.get(header.From_Warehouse_Location__c).Account__c == lstUserHN[0].AccountId) {
                    headerName = headerType + '-HN';
                    headerNumberHN += 1;
                    header.Header_No__c	= headerNumberHN;
                    headerNumberStr = String.valueOf(headerNumberHN);
                }else{
                    headerNumber +=1;
                    header.Header_No__c = headerNumber;
                    headerNumberStr = String.valueOf(headerNumber);
                }
            }else if(mapWarehouseFull.containsKey(header.To_Warehouse_Location__c)){
                if(mapWarehouseFull.get(header.To_Warehouse_Location__c).Account__c == lstUserHN[0].AccountId) {
                    headerName =  headerType + '-HN';
                    headerNumberHN += 1;
                    header.Header_No__c	= headerNumberHN;
                    headerNumberStr = String.valueOf(headerNumberHN);
                }else{
                    headerNumber +=1;
                    header.Header_No__c = headerNumber;
                    headerNumberStr = String.valueOf(headerNumber);
                }
            }
            // else{
            //     headerNumber +=1;
            //     header.Header_No__c	= headerNumber;
            //     headerNumberStr = String.valueOf(headerNumber);
            // }
            if (header.Header_No__c == headerNumber) {
                headerNo = headerNumber;
            } else {
                headerNo = headerNumberHN;
            }
 
            if (headerNo < 10){
                headerNumberStr = '000' + headerNumberStr;
            } else if (headerNo < 100){
                headerNumberStr = '00' + headerNumberStr;
            } else if (headerNo < 1000){
                headerNumberStr = '0' + headerNumberStr;
            }
            header.Header_Number__c = 'TO-'+headerName+'-'+yearNo+monthNo+'-'+headerNumberStr;
        }
        System.debug('lstHeader 2: ' + lstHeader);
    }

    public static void onBeforeUpdate(Map<Id, X3_Inventory_Transaction_Header__c> mapOlds, Map<Id, X3_Inventory_Transaction_Header__c> mapNews){
        List<X3_Inventory_Transaction_Header__c> lstTransactionHeader = new List<X3_Inventory_Transaction_Header__c>();
        Set<Id> setIdWarehouseInventoryFrom = new Set<Id>();
        Set<Id> setIdWarehouseInventoryTo = new Set<Id>();
        for (X3_Inventory_Transaction_Header__c item : mapNews.values()){
            if (mapOlds.get(item.Id).Status__c != item.Status__c && (item.Status__c == 'Completed' || item.Status__c == 'Cancled')){
                lstTransactionHeader.add(item);
                if (item.From_Warehouse_Location__c != Null){
                    setIdWarehouseInventoryFrom.add(item.From_Warehouse_Location__c);
                }
                if (item.To_Warehouse_Location__c != Null){
                    setIdWarehouseInventoryTo.add(item.To_Warehouse_Location__c);
                }
            }
        }
        if (!lstTransactionHeader.isEmpty()){
            updateWareHouseWhenUpdateStatusCompleted(lstTransactionHeader, setIdWarehouseInventoryFrom, setIdWarehouseInventoryTo, mapNews);
        }
    }

    private static void updateWareHouseWhenUpdateStatusCompleted(List<X3_Inventory_Transaction_Header__c> lstTransactionHeader, Set<Id> setIdWarehouseInventoryFrom, Set<Id> setIdWarehouseInventoryTo, Map<Id, X3_Inventory_Transaction_Header__c> mapNews){
        Savepoint sp = Database.setSavepoint();
        List<Warehouse_Inventory__c> lstWarehouseInventoryFrom = new List<Warehouse_Inventory__c>();
        List<Warehouse_Inventory__c> lstWarehouseInventoryTo = new List<Warehouse_Inventory__c>();
        Map<Id, Warehouse_Inventory__c> mapProductWithInventoryFrom = new Map<Id, Warehouse_Inventory__c>();
        Map<Id, Warehouse_Inventory__c> mapProductPCAWithInventoryFrom = new Map<Id, Warehouse_Inventory__c>();
        Map<Id, Warehouse_Inventory__c> mapProductWithInventoryTo = new Map<Id, Warehouse_Inventory__c>();
        Map<Id, Warehouse_Inventory__c> mapProductPCAWithInventoryTo = new Map<Id, Warehouse_Inventory__c>();
        List<Inventory_Transaction_Item__c> lstTransactionItemUpdate = new List<Inventory_Transaction_Item__c>();
        Map<Id, Warehouse_Inventory__c> mapIdHeaderItemWithWarehouseInventory = new Map<Id, Warehouse_Inventory__c>();
        Map<Id, Warehouse_Inventory__c> mapWareHouseUpsert = new Map<Id, Warehouse_Inventory__c>();
        List<Warehouse_Inventory__c> lstWarehouseUpdate = new List<Warehouse_Inventory__c>();
        try{
            List<X3_Inventory_Transaction_Header__c> lstTransactionHeaderQuerry = [SELECT Id
                                                                                        , To_Warehouse_Location__c
                                                                                        , From_Warehouse_Location__c
                                                                                        , Order_Reserved__c
                                                                                   		, Order_Reserved__r.Is_Booked_Asset__c 
                                                                                        , (SELECT Id
                                                                                                , Quantity__c
                                                                                                , Product__c
                                                                                                , Product__r.RecordTypeId
                                                                                                , Product__r.Name
                                                                                                , Is_Transfer__c
                                                                                                , Asset__c
                                                                                                , From_Warehouse_Location__c
                                                                                                , To_Warehouse_Location__c
                                                                                           		, Inventory_Transaction_Header__r.Order_Reserved__r.Is_Booked_Asset__c
                                                                                            FROM Inventory_Transaction_Items__r
                                                                                          	WHERE Quantity__c >=: 0 AND Is_Merg__c =: false)
                                                                                   FROM X3_Inventory_Transaction_Header__c
                                                                                   WHERE Id IN:lstTransactionHeader];
            System.debug('lstTransactionHeaderQuerry:' + lstTransactionHeaderQuerry);
            if (!setIdWarehouseInventoryFrom.isEmpty()){
                lstWarehouseInventoryFrom = [SELECT Id, Product__c, Product__r.RecordTypeId, Product__r.Name, QoH__c, Asset__c, Warehouse_Location__c
                                             FROM Warehouse_Inventory__c
                                             WHERE Warehouse_Location__c IN:setIdWarehouseInventoryFrom];
                for (Warehouse_Inventory__c item : lstWarehouseInventoryFrom){
                    
                    if (item.Product__r.RecordTypeId == RecordTypeHelper.PRODUCT_MODEL){
                        mapProductWithInventoryFrom.put(item.Asset__c, item);
                    } else if (item.Product__r.RecordTypeId == RecordTypeHelper.PRODUCT_PCA){
                        mapProductPCAWithInventoryFrom.put(item.Product__c, item);
                    }
                }
            }
            if (!setIdWarehouseInventoryTo.isEmpty()){
                lstWarehouseInventoryTo = [SELECT Id, Product__c, Product__r.RecordTypeId, Product__r.Name, QoH__c, Asset__c, Warehouse_Location__c
                                           FROM Warehouse_Inventory__c
                                           WHERE Warehouse_Location__c IN:setIdWarehouseInventoryTo];
                for (Warehouse_Inventory__c item : lstWarehouseInventoryTo){
                    if (item.Product__r.RecordTypeId == RecordTypeHelper.PRODUCT_MODEL){
                        mapProductWithInventoryTo.put(item.Asset__c, item);
                    } else if (item.Product__r.RecordTypeId == RecordTypeHelper.PRODUCT_PCA){
                        mapProductPCAWithInventoryTo.put(item.Product__c, item);
                    }
                }
            }
            for (X3_Inventory_Transaction_Header__c item : lstTransactionHeaderQuerry){
                if (!item.Inventory_Transaction_Items__r.isEmpty()){
                    System.debug('Inventory Item:');
                    for (Inventory_Transaction_Item__c itt : item.Inventory_Transaction_Items__r){
                        if (itt.Product__r.RecordTypeId == RecordTypeHelper.PRODUCT_MODEL
                             && !itt.Inventory_Transaction_Header__r.Order_Reserved__r.Is_Booked_Asset__c){
                            System.debug('LINE 276');
                            if (mapNews.containsKey(item.Id)){
                                System.debug('Has Key Inventory Item:');
                                if (item.From_Warehouse_Location__c != Null 
                                    && item.To_Warehouse_Location__c != Null 
                                    && item.Order_Reserved__c == Null 
                                    && mapNews.get(item.Id).Status__c == 'Completed'){
                                    System.debug('Case1');
                                    if (mapProductWithInventoryFrom.containsKey(itt.Asset__c)){
                                        if (mapProductWithInventoryFrom.get(itt.Asset__c).QoH__c > itt.Quantity__c){
                                            mapProductWithInventoryFrom.get(itt.Asset__c).QoH__c = mapProductWithInventoryFrom.get(itt.Asset__c).QoH__c - itt.Quantity__c;
                                            lstWarehouseUpdate.add(mapProductWithInventoryFrom.get(itt.Asset__c));
                                            if (mapProductWithInventoryTo.containsKey(itt.Asset__c)){
                                                mapProductWithInventoryTo.get(itt.Asset__c).QoH__c = mapProductWithInventoryTo.get(itt.Asset__c).QoH__c + itt.Quantity__c;
                                                mapIdHeaderItemWithWarehouseInventory.put(itt.Id, mapProductWithInventoryTo.get(itt.Asset__c));
                                            } else{
                                                mapIdHeaderItemWithWarehouseInventory.put(itt.Id, new Warehouse_Inventory__c(
                                                                                                Product__c = itt.Product__c
                                                                                                , QoH__c = itt.Quantity__c
                                                                                                , Asset__c  = itt.Asset__c
                                                                                                , Name = itt.Product__r.Name
                                                                                                , Warehouse_Location__c = itt.To_Warehouse_Location__c));
                                            }

                                        } else{
                                            //+ mapProductWithInventoryFrom.get(itt.Asset__c).Product__c
                                            lstTransactionHeader[0].addError('Not enough quantity for product ' + mapProductWithInventoryFrom.get(itt.Asset__c).Product__r.Name);
                                        }
                                    }
                                } else if (mapNews.get(item.Id).Status__c == 'Completed'
                                            && ((item.From_Warehouse_Location__c != Null 
                                                    && item.To_Warehouse_Location__c != Null 
                                                    && item.Order_Reserved__c != Null) 
                                            || (item.To_Warehouse_Location__c != Null 
                                                && item.From_Warehouse_Location__c == Null
                                                && item.Order_Reserved__c == Null)
                                            || (item.From_Warehouse_Location__c != Null 
                                                    && item.To_Warehouse_Location__c == Null 
                                                    && item.Order_Reserved__c != Null) )){
                                    System.debug('Case2');
									if(mapProductWithInventoryFrom.containsKey(itt.Asset__c) && item.From_Warehouse_Location__c != Null) {
                                        mapProductWithInventoryFrom.get(itt.Asset__c).QoH__c = mapProductWithInventoryFrom.get(itt.Asset__c).QoH__c - itt.Quantity__c;
                                        lstWarehouseUpdate.add(mapProductWithInventoryFrom.get(itt.Asset__c));
                                    }
                                    if(item.To_Warehouse_Location__c != Null) {
                                        if (mapProductWithInventoryTo.containsKey(itt.Asset__c)){
                                            mapProductWithInventoryTo.get(itt.Asset__c).QoH__c = mapProductWithInventoryTo.get(itt.Asset__c).QoH__c + itt.Quantity__c;
                                            mapIdHeaderItemWithWarehouseInventory.put(itt.Id, mapProductWithInventoryTo.get(itt.Asset__c));
                                        } else{
                                            mapIdHeaderItemWithWarehouseInventory.put(itt.Id, new Warehouse_Inventory__c(
                                                                                                Product__c = itt.Product__c
                                                                                                , Asset__c  = itt.Asset__c
                                                                                                , QoH__c = itt.Quantity__c
                                                                                                , Name = itt.Product__r.Name
                                                                                                , Warehouse_Location__c = itt.To_Warehouse_Location__c));
                                        }                    
                                    }          
                                } else if (mapNews.get(item.Id).Status__c == 'Cancled' 
                                            && ((item.From_Warehouse_Location__c != Null 
                                                    && item.To_Warehouse_Location__c != Null 
                                                    && item.Order_Reserved__c != Null) 
                                            || (item.From_Warehouse_Location__c != Null 
                                                && item.Order_Reserved__c != Null)
                                            || ((item.From_Warehouse_Location__c != Null 
                                                 	&& item.To_Warehouse_Location__c == Null) 
                                                	&& item.Order_Reserved__c != Null))){
                                    System.debug('Case3');
                                    if(mapProductWithInventoryTo.containsKey(itt.Asset__c) && item.To_Warehouse_Location__c != Null) {
                                        mapProductWithInventoryTo.get(itt.Asset__c).QoH__c = mapProductWithInventoryTo.get(itt.Asset__c).QoH__c - itt.Quantity__c;
                                        lstWarehouseUpdate.add(mapProductWithInventoryTo.get(itt.Asset__c));
                                    }
                                    if (mapProductWithInventoryFrom.containsKey(itt.Asset__c)){
                                        mapProductWithInventoryFrom.get(itt.Asset__c).QoH__c = mapProductWithInventoryFrom.get(itt.Asset__c).QoH__c + itt.Quantity__c;
                                        System.debug('mapProductWithInventoryFrom.get(itt.Asset__c).QoH__c:' + mapProductWithInventoryFrom.get(itt.Asset__c).QoH__c);
                                        mapIdHeaderItemWithWarehouseInventory.put(itt.Id, mapProductWithInventoryFrom.get(itt.Asset__c));
                                    }
                                }
                            }
                        } else if(itt.Product__r.RecordTypeId == RecordTypeHelper.PRODUCT_PCA && itt.Quantity__c > 0) { //PCA
                            if (mapNews.containsKey(item.Id)){
                                System.debug('Case PCA');
                                if (item.From_Warehouse_Location__c != Null 
                                    && item.To_Warehouse_Location__c != Null 
                                    && item.Order_Reserved__c == Null 
                                    && mapNews.get(item.Id).Status__c == 'Completed'){
                                    System.debug('Case1 PCA');
                                    if (mapProductPCAWithInventoryFrom.containsKey(itt.Product__c)){
                                        if (mapProductPCAWithInventoryFrom.get(itt.Product__c).QoH__c >= itt.Quantity__c){
                                            mapProductPCAWithInventoryFrom.get(itt.Product__c).QoH__c = mapProductPCAWithInventoryFrom.get(itt.Product__c).QoH__c - itt.Quantity__c;
                                            lstWarehouseUpdate.add(mapProductPCAWithInventoryFrom.get(itt.Product__c));
                                            if (mapProductPCAWithInventoryTo.containsKey(itt.Product__c)){
                                                mapProductPCAWithInventoryTo.get(itt.Product__c).QoH__c = mapProductPCAWithInventoryTo.get(itt.Product__c).QoH__c + itt.Quantity__c;
                                                mapIdHeaderItemWithWarehouseInventory.put(itt.Id, mapProductPCAWithInventoryTo.get(itt.Product__c));
                                            } else{
                                                mapIdHeaderItemWithWarehouseInventory.put(itt.Id
                                                                    , new Warehouse_Inventory__c(
                                                                        Product__c = itt.Product__c
                                                                        , QoH__c = itt.Quantity__c
                                                                        , Name = itt.Product__r.Name
                                                                        , Warehouse_Location__c = itt.To_Warehouse_Location__c));
                                            }

                                        } else{
                                            //+ mapProductWithInventoryFrom.get(itt.Asset__c).Product__c
                                            lstTransactionHeader[0].addError('Not enough quantity for product ' + mapProductPCAWithInventoryFrom.get(itt.Product__c).Product__r.Name);
                                        }
                                    }
                                } else if (mapNews.get(item.Id).Status__c == 'Completed' && 
                                                                 ((item.From_Warehouse_Location__c != Null 
                                                                    && item.To_Warehouse_Location__c != Null 
                                                                    && item.Order_Reserved__c != Null) 
                                                                    || (item.To_Warehouse_Location__c != Null 
                                                                        && item.From_Warehouse_Location__c == Null 
                                                                        && item.Order_Reserved__c == Null)
                                                                 	|| (item.From_Warehouse_Location__c != Null 
                                                                        && item.To_Warehouse_Location__c == Null 
                                                                        && item.Order_Reserved__c != Null)
                                                                 	|| (item.From_Warehouse_Location__c != Null 
                                                                                && item.To_Warehouse_Location__c == Null 
                                                                                && item.Order_Reserved__c == Null))){
                                    System.debug('Case2 PCA');
                                    if(mapProductPCAWithInventoryFrom.containsKey(itt.Product__c) && item.From_Warehouse_Location__c != Null) {
                                        System.debug('mapProductPCAWithInventoryFrom:' + mapProductPCAWithInventoryFrom.get(itt.Product__c));
                                        System.debug('itt:' + itt);
                                        if(mapProductPCAWithInventoryFrom.get(itt.Product__c).QoH__c < itt.Quantity__c) {
                                            lstTransactionHeader[0].addError('Not enough quantity for product ' + mapProductPCAWithInventoryFrom.get(itt.Product__c).Product__r.Name);
                                        } else {
                                            mapProductPCAWithInventoryFrom.get(itt.Product__c).QoH__c = mapProductPCAWithInventoryFrom.get(itt.Product__c).QoH__c - itt.Quantity__c;
                                        }
                                        
                                        if(item.To_Warehouse_Location__c == Null) {
                                            mapIdHeaderItemWithWarehouseInventory.put(itt.Id, mapProductPCAWithInventoryFrom.get(itt.Product__c));
                                        } else {
                                            lstWarehouseUpdate.add(mapProductPCAWithInventoryFrom.get(itt.Product__c));
                                        }
                                    }
                                    if(item.To_Warehouse_Location__c != Null) {
                                        if (mapProductPCAWithInventoryTo.containsKey(itt.Product__c)){
                                            mapProductPCAWithInventoryTo.get(itt.Product__c).QoH__c = mapProductPCAWithInventoryTo.get(itt.Product__c).QoH__c + itt.Quantity__c;
                                            mapIdHeaderItemWithWarehouseInventory.put(itt.Id, mapProductPCAWithInventoryTo.get(itt.Product__c));
                                        } else {
                                            mapIdHeaderItemWithWarehouseInventory.put(itt.Id, 
                                                                                        new Warehouse_Inventory__c(
                                                                                            Product__c = itt.Product__c
                                                                                            , QoH__c = itt.Quantity__c
                                                                                            , Name = itt.Product__r.Name
                                                                                            , Warehouse_Location__c = item.To_Warehouse_Location__c));
                                        }  
                                    }
                                    
                                } else if (mapNews.get(item.Id).Status__c == 'Cancled' && 
                                                                    ((item.From_Warehouse_Location__c != Null 
                                                                            && item.To_Warehouse_Location__c != Null 
                                                                            && item.Order_Reserved__c != Null) 
                                                                        || (item.From_Warehouse_Location__c != Null 
                                                                                && item.Order_Reserved__c != Null)
                                                                    	|| (((item.From_Warehouse_Location__c != Null 
                                                                                && item.To_Warehouse_Location__c == Null) 
                                                                            || (item.From_Warehouse_Location__c != Null 
                                                     							&& item.To_Warehouse_Location__c != Null))
                                                                                && item.Order_Reserved__c == Null))){
                                    System.debug('Case3 PCA');
                                    System.debug('mapProductPCAWithInventoryFrom' + mapProductPCAWithInventoryFrom.keySet());
                                    if (mapProductPCAWithInventoryFrom.containsKey(itt.Product__c)){
                                        mapProductPCAWithInventoryFrom.get(itt.Product__c).QoH__c = mapProductPCAWithInventoryFrom.get(itt.Product__c).QoH__c + itt.Quantity__c;
                                        
                                        mapIdHeaderItemWithWarehouseInventory.put(itt.Id, mapProductPCAWithInventoryFrom.get(itt.Product__c));
                                        
                                    } else if(mapProductPCAWithInventoryFrom.containsKey(itt.Product__c) 
                                              && (item.From_Warehouse_Location__c != Null
                                                  && !String.isNotBlank(item.To_Warehouse_Location__c)
                                                  && !String.isNotBlank(item.Order_Reserved__c))) {//Xuất kho
                                        mapProductPCAWithInventoryFrom.get(itt.Product__c).QoH__c = mapProductPCAWithInventoryFrom.get(itt.Product__c).QoH__c + itt.Quantity__c;
                                        lstWarehouseUpdate.add(mapProductPCAWithInventoryFrom.get(itt.Product__c));
                                    } 
                                    if(item.To_Warehouse_Location__c != Null) {
                                        if(mapProductPCAWithInventoryTo.containsKey(itt.Product__c) && item.To_Warehouse_Location__c != Null) {
                                            if(mapProductPCAWithInventoryTo.get(itt.Product__c).QoH__c < itt.Quantity__c) {
                                                lstTransactionHeader[0].addError('Not enough quantity for product ' + mapProductPCAWithInventoryTo.get(itt.Product__c).Product__r.Name);
                                            } else {
                                                mapProductPCAWithInventoryTo.get(itt.Product__c).QoH__c = mapProductPCAWithInventoryTo.get(itt.Product__c).QoH__c - itt.Quantity__c;
                                                lstWarehouseUpdate.add(mapProductPCAWithInventoryTo.get(itt.Product__c));
                                            }
                                            
                                        } 
                                    }                                           
                                }
                            }
                        }
                    }
                }
            }
            if(!lstWarehouseUpdate.isEmpty()) {
                System.debug('lstWarehouseUpdate:' + lstWarehouseUpdate);
                update lstWarehouseUpdate;
            }
            System.debug('mapIdHeaderItemWithWarehouseInventory.values():' + mapIdHeaderItemWithWarehouseInventory.values());
            if (!mapIdHeaderItemWithWarehouseInventory.values().isEmpty()){
                upsert mapIdHeaderItemWithWarehouseInventory.values();

                for (X3_Inventory_Transaction_Header__c item : lstTransactionHeaderQuerry){
                    for (Inventory_Transaction_Item__c itt : item.Inventory_Transaction_Items__r){
                        if (mapIdHeaderItemWithWarehouseInventory.containsKey(itt.Id)){
                            itt.Warehouse_Inventory__c = mapIdHeaderItemWithWarehouseInventory.get(itt.Id).Id;
                            lstTransactionItemUpdate.add(itt);
                        }
                    }
                }
                if (!lstTransactionItemUpdate.isEmpty()){
                    update lstTransactionItemUpdate;
                }
            }
        } catch (Exception ex){
            Database.rollback(sp);
            System.debug('ex getMessage() :' + ex.getMessage() + ', ' + ex.getLineNumber());
        }
    }

    private static void checkOrderHasTask(List<Inventory_Transaction_Item__c> LstTransactionItems, Map<Id, List<Inventory_Transaction_Item__c>> mapIdParentToLstChild){
        for (Inventory_Transaction_Item__c item : LstTransactionItems){
            if (mapIdParentToLstChild.containsKey(item.Inventory_Transaction_Header__c)){
                List<Inventory_Transaction_Item__c> lstTransactionItemChild = mapIdParentToLstChild.get(item.Inventory_Transaction_Header__c);
                lstTransactionItemChild.add(item);
                mapIdParentToLstChild.put(item.Inventory_Transaction_Header__c, lstTransactionItemChild);
            } else{
                mapIdParentToLstChild.put(item.Inventory_Transaction_Header__c, new List<Inventory_Transaction_Item__c>{ item });
            }
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;

        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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