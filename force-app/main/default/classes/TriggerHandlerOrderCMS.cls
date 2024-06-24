/*******************************************************************************
 ** Class Name: TriggerHandlerOrderCMS
 ** Description: Handle on Order e commerce
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class TriggerHandlerOrderCMS {
    public static PriceBook2 PRICEBOOKPCA = [SELECT Id FROM PriceBook2 WHERE Type__c = 'PCAService' AND IsActive = True];
    public static PriceBook2 PRICEBOOKMC = [SELECT Id, Type__c FROM PriceBook2 WHERE Type__c = 'Bike' AND IsActive = true];
    
    public static void onAfterInsert(List<Order_WebCommercal__c> newData, Boolean isCallout) {
        List<Id> orderBikes = new List<Id>();
        List<Id> orderPCAs = new List<Id>();
        for(Order_WebCommercal__c order : newData) {
            if (isCallout) {
                if (order.Order_Type__c == 'Bike')
            	orderBikes.add(order.Id);
                if (order.Order_Type__c == 'PCA')
                orderPCAs.add(order.Id);
            }
        }
        if (!orderBikes.isEmpty() || !orderPCAs.isEmpty()) {
            createOrderBike(orderBikes, orderPCAs);
        }
    }
    
    public static void createGenericOrderType(List<Id> ordersTypeId, Map<string, id> mapMcPCAExsting, Map<Id, Order_WebCommercal__c> ordersEcommerce,
                                               Map<string, Map<string, Account>> mapAccountDealer, Map<String, Id> mapProvince, Map<String, District__c> mapDistrict) {
        Map<String, Schema.SObjectField> orderFieldMap = Order_WebCommercal__c.sObjectType.getDescribe().fields.getMap();
        List<string> orderSelectFields = new List<String>(orderFieldMap.keySet());
        orderSelectFields.add('(SELECT ID, Product_Code__c, color_code__c, quantity__c  FROM OrderItem_Web_Commercal__r)');
        String orderSoql = 'SELECT ' + String.join(orderSelectFields, ',');
        orderSoql += ' FROM Order_WebCommercal__c';
        orderSoql += ' WHERE Id IN:ordersTypeId';
        // List Dealer Code
        Map<string, Id> dealersId = new Map<string, Id>();
        Map<string, string> dealerCodeAccount = new Map<string, string>();
        List<Account> accountDelears = new List<Account>();
        for (Order_WebCommercal__c order : Database.query(orderSoql)) {
            if (order.OrderItem_Web_Commercal__r.isEmpty()) continue;
            for (Order_Item_WebCommercal__c orderItem : order.OrderItem_Web_Commercal__r) {
                if (order.Order_Type__c == 'Bike')
            	mapMcPCAExsting.put(orderItem.Product_Code__c + orderItem.color_code__c, null);  
                else if (order.Order_Type__c == 'PCA')
            	mapMcPCAExsting.put(orderItem.Product_Code__c, null);    
            }
            mapProvince.put(order.recevie_province__c, null);
            dealersId.put(order.dealer_code__c, null);
            mapDistrict.put(order.receive_district__c, new District__c());
            ordersEcommerce.put(order.Id, order);
            if (mapAccountDealer.containsKey(order.Customer_id__c)) {
                if (!mapAccountDealer.get(order.Customer_id__c).containsKey(order.dealer_code__c)) {
                    mapAccountDealer.get(order.Customer_id__c).put(order.dealer_code__c, null);
                }
                continue;
            }
            mapAccountDealer.put(order.Customer_id__c, new Map<string, Account> {order.dealer_code__c => null});
        }
        // Query province base on Province Code
        for (Province__c p : [SELECT Id, Province_Code__c FROM Province__c WHERE Province_Code__c IN: mapProvince.keySet()])
            mapProvince.put(p.Province_Code__c, p.Id);
        
        // Query district base on District Code
        for (District__c d : [SELECT Id,Province__c, District_Code__c  FROM District__c WHERE District_Code__c IN : mapDistrict.keySet()]) 
            mapDistrict.put(d.District_Code__c, new District__c(Id = d.Id, Province__c = d.Province__c , District_Code__c = d.District_Code__c));
        
        // Query Dealer base on dealer code
        for (Account acc : [SELECT Id, DO_DL_Code__c FROM Account WHERE DO_DL_Code__c IN: dealersId.keySet()])
            dealersId.put(acc.DO_DL_Code__c, acc.Id);
        for (Product2 p : [SELECT Id, ExternalID_DMS__c FROM Product2 WHERE ExternalID_DMS__c IN: mapMcPCAExsting.keySet()])
            mapMcPCAExsting.put(p.ExternalID_DMS__c, p.Id);
        
        Map<string, Account> mapAccountPrimary = new Map<string, Account>([SELECT Id, FirstName, LastName, PersonMobilePhone, OwnerId, Address_No__c, Address_No__pc, Gender__c,
                                                                           DOB__pc, PersonEmail, Province__c, Province__pc, District__pc, District__c, Address__c, RecordTypeId,
                                                                           DO_DL_Create_Account__r.DO_DL_Code__c, Owner.Profile.Name, NonResident__c
                                                                           FROM Account
                                                                           WHERE Id IN: mapAccountDealer.keySet()]);
        
        for (Account acc : [SELECT Id, DO_DL_Create_Account__r.DO_DL_Code__c, Account_Is_Primary__c, OwnerId, Owner.Profile.Name, NonResident__c
                            FROM Account
                            WHERE Account_Is_Primary__c IN: mapAccountDealer.keySet() AND DO_DL_Create_Account__r.DO_DL_Code__c != null]) {
             if (mapAccountDealer.get(acc.Account_Is_Primary__c).containskey(acc.DO_DL_Create_Account__r.DO_DL_Code__c))
             mapAccountDealer.get(acc.Account_Is_Primary__c).put(acc.DO_DL_Create_Account__r.DO_DL_Code__c, acc);
        }
        for (string accID : mapAccountDealer.keySet()) {
            for (string dealerCode : mapAccountDealer.get(accID).keySet()) {
                if (mapAccountDealer.get(accID).get(dealerCode) == null) {
                	Account acc = mapAccountPrimary.get(accID).clone(false, false, false, false);
                    acc.LastName = acc.LastName.replaceAll('Primary', '');
                	acc.Account_Is_Primary__c = accID;
                    if (dealersId.containsKey(dealerCode) && dealersId.get(dealerCode) != null) {
                        acc.DO_DL_Create_Account__c = dealersId.get(dealerCode);
                        dealerCodeAccount.put(acc.DO_DL_Create_Account__c, dealerCode);
                    }
                	accountDelears.add(acc);    
                }  
            }                
        }
        insert accountDelears;
        // Put Id Account New at Dealer 
        for (Account accDealer : accountDelears) 
            mapAccountDealer.get(accDealer.Account_Is_Primary__c).put(dealerCodeAccount.get(accDealer.DO_DL_Create_Account__c), accDealer);
    }
    public static List<Round_Robin_Assignment__c> runAssignment(Set<string> dealerCode){
        return [
            SELECT 
                Id, For_Object__c, Last_Assignee_Index__c, Description__c,
                Assignment_Rule_Type__c, Custom_Assignment_Rule_Order__c, 
                Auto_Reassign_Rule_Type__c, Custom_Auto_Reassign_Rule_Order__c,
                (
                    SELECT Id, Assignee__c, Last_Assignment_Date__c
                    FROM Round_Robin_Assignee__r
                    WHERE 
                        Is_Active__c = true
                        AND Assignee__c != NULL
                    ORDER BY Sort_Order__c ASC
                )
            FROM Round_Robin_Assignment__c
            WHERE 
            	Description__c IN: dealerCode
                AND For_Object__c = 'Opportunity'
                AND Is_Active__c = true
            ORDER BY Sort_Order__c ASC
        ];
    }
    
    public static void createOrderBike(List<Id> orderBikes, List<Id> orderPCAs) {
        checkAccountHasAccountIsPrimary.flagRun = TRUE;
        Map<string, id> mapMcPCAExsting = new Map<string, id>();
        
        Map<Id, Order_WebCommercal__c> ordersEcommerce = new Map<Id, Order_WebCommercal__c>(); 
        Map<string, Map<string, Account>> mapAccountDealer = new Map<string, Map<string, Account>>();
        
        // Province Districe Code
        Map<String, Id> mapProvince = new Map<String , Id>();
        Map<String, District__c> mapDistrict = new Map<String , District__c>();
        if (!orderBikes.isEmpty()) {
            Map<Id, Opportunity> orderEcommerceopps = new Map<Id, Opportunity>();
            List<Id> accountIsOwnerSales = new List<Id>();
            createGenericOrderType(orderBikes, mapMcPCAExsting, ordersEcommerce, mapAccountDealer, mapProvince, mapDistrict);
            for (Order_WebCommercal__c o : ordersEcommerce.values())
            	createOpportunity(o, mapMcPCAExsting, mapAccountDealer, mapProvince, mapDistrict, orderEcommerceopps, accountIsOwnerSales);
        
        	insert orderEcommerceopps.values();
        	Map<Id, PricebookEntry> mapMcPriceBookEntry = new Map<Id, PricebookEntry>();
        	for (PricebookEntry p: [SELECT Id, UnitPrice, Pricebook2Id, Product2Id FROM PricebookEntry 
                                    WHERE Product2.ExternalID_DMS__c IN: mapMcPCAExsting.keySet() AND Pricebook2Id =: PRICEBOOKMC.Id]) 
                mapMcPriceBookEntry.put(p.Product2Id, p);
            Map<Id, Quote> mapOppquotes = new Map<Id, Quote>();
            Map<Id, QuoteLineItem> mapOppquoteItems = new Map<Id, QuoteLineItem>();
            Map<string, Map<string, List<Id>>> mapDOAccountOrders = new Map<string, Map<string, List<Id>>>();
            
        	for (Id order : orderEcommerceopps.keySet()) {
            	Opportunity o = orderEcommerceopps.get(order);
                Order_WebCommercal__c orderCMS = ordersEcommerce.get(order);
            	if (mapMcPriceBookEntry.containsKey(o.Product__c))
            	createQuoteToQuoteLine(o.Id, mapMcPriceBookEntry.get(o.Product__c), mapOppquotes, mapOppquoteItems, orderCMS.Promotion_Item__c);
                // If Owner Account Profile Sales not excute round robin for record Opportunity.
                if (accountIsOwnerSales.contains(o.AccountId)) continue;
                // Create Map by dealer with customer Id and Opportunities.
                if(mapDOAccountOrders.containsKey(orderCMS.dealer_code__c)) {
                    if(mapDOAccountOrders.get(orderCMS.dealer_code__c).containsKey(o.AccountId)) 
                        mapDOAccountOrders.get(orderCMS.dealer_code__c).get(o.AccountId).add(o.Id);
                    else 
                        mapDOAccountOrders.get(orderCMS.dealer_code__c).put(o.AccountId, new List<Id> {o.Id});
                    continue;
                }
                mapDOAccountOrders.put(orderCMS.dealer_code__c, new Map<string, List<Id>> {o.AccountId => new List<Id> {o.Id}});
       		}
        	insert mapOppquotes.values();
        	for(Id oppId : mapOppquoteItems.keySet()) mapOppquoteItems.get(oppId).put('QuoteId', mapOppquotes.get(oppId).Id);
        	insert mapOppquoteItems.values();
            // Start reassign for sales team based on DO Delear Code
            reassignOwnerSalesTeamDO(mapDOAccountOrders);
            
            // Reset variable common reuse for PCA order CMS.
            mapMcPCAExsting.clear();
            ordersEcommerce.clear();
            mapAccountDealer.clear();
            mapProvince.clear();
            mapDistrict.clear();
        }
        if (!orderPCAs.isEmpty()) {
            List<OrderItem> orderItems = new List<OrderItem>();
            createGenericOrderType(orderPCAs, mapMcPCAExsting, ordersEcommerce, mapAccountDealer, mapProvince, mapDistrict);
            Map<Id, Order> mapOrderIdCMSToCRM = new Map<Id, Order>();
            Map<Id, PricebookEntry> mapMcPriceBookEntry = new Map<Id, PricebookEntry>();
        	for (PricebookEntry p: [SELECT Id, UnitPrice, Pricebook2Id, Product2Id, Product2.ExternalID_DMS__c
                                    FROM PricebookEntry 
                                    WHERE Product2.ExternalID_DMS__c IN: mapMcPCAExsting.keySet() AND Pricebook2Id =: PRICEBOOKPCA.Id]) 
                mapMcPriceBookEntry.put(p.Product2Id, p);
            for (Order_WebCommercal__c o : ordersEcommerce.values())
            	createOrderPCA(o, mapAccountDealer, mapProvince, mapDistrict, mapOrderIdCMSToCRM);
            // Create Order PCA FROM order CMS PCA.
            insert mapOrderIdCMSToCRM.values();
            
            for (Id orderCMSID : ordersEcommerce.keySet()) {
                for (Order_Item_WebCommercal__c orderItemCMS : ordersEcommerce.get(orderCMSID).OrderItem_Web_Commercal__r) {
                    if (mapMcPCAExsting.get(orderItemCMS.Product_Code__c) == null) continue;
                    createOrderItemPCA(mapOrderIdCMSToCRM.get(orderCMSID).Id, orderItemCMS, mapMcPCAExsting.get(orderItemCMS.Product_Code__c), mapMcPriceBookEntry, orderItems);
                }
            }
            // Create OrderItem From Order Item CMS.
            insert orderItems;
        }
    }
    private static void reassignOwnerSalesTeamDO(Map<string, Map<string, List<Id>>> mapDOAccountOrders) {
        List<Opportunity> assignedRecords = new List<Opportunity>();        
        Map<Id, Integer> updateAssignmentIndex = new Map<Id, Integer>();
        Map<Id, Datetime> updateAssigneeLastAssignmentDate = new Map<Id, Datetime>();
        
        for(Round_Robin_Assignment__c assignment : runAssignment(mapDOAccountOrders.keySet())) {
            if(assignment.Round_Robin_Assignee__r == null || assignment.Round_Robin_Assignee__r.isEmpty()){
                // Do not run the assignment rule if there are no assignee available
                continue;
            }
            Boolean canUpdateAssignment = false;
            Integer lastAssigneeIndex = assignment.Last_Assignee_Index__c == null ? -1 : assignment.Last_Assignee_Index__c.intValue();
            for(string doCode : mapDOAccountOrders.get(assignment.Description__c).keySet()) {
                Integer currentAssigneeIndex = RoundRobinAssignmentHelper.getAssigneeIndex(lastAssigneeIndex, assignment.Round_Robin_Assignee__r, null);
                for (Id recordId : mapDOAccountOrders.get(assignment.Description__c).get(doCode)) {
                    Opportunity o = new Opportunity(Id = recordId, OwnerId = assignment.Round_Robin_Assignee__r.get(currentAssigneeIndex).Assignee__c);
                    assignedRecords.add(o);
                }
                // Update assignee assignment date
                updateAssigneeLastAssignmentDate.put(assignment.Round_Robin_Assignee__r.get(currentAssigneeIndex).Id, Datetime.now());
                lastAssigneeIndex = currentAssigneeIndex;
                canUpdateAssignment = true;
            }
            if(canUpdateAssignment){                
                updateAssignmentIndex.put(assignment.Id, lastAssigneeIndex);
            }
        } 
        if(!assignedRecords.isEmpty()){
            for (Opportunity opportunity : assignedRecords) {
                opportunity.put('Last_Run_Date__c', Datetime.now());  
            }
            update assignedRecords;
        }
        if(!updateAssignmentIndex.isEmpty()){
            List<Round_Robin_Assignment__c> updateAssignments = new List<Round_Robin_Assignment__c>();
            for(Id key : updateAssignmentIndex.keySet()){
                updateAssignments.add(new Round_Robin_Assignment__c(
                    Id = key,
                    Last_Assignee_Index__c = updateAssignmentIndex.get(key)
                ));
            }
            update updateAssignments;
        }
        if(!updateAssigneeLastAssignmentDate.isEmpty()){
            List<Round_Robin_Assignee__c> updateAssignee = new List<Round_Robin_Assignee__c>();
            for(Id key : updateAssigneeLastAssignmentDate.keySet()){
                updateAssignee.add(new Round_Robin_Assignee__c(
                    Id = key,
                    Last_Assignment_Date__c = updateAssigneeLastAssignmentDate.get(key)
                ));
            }
            update updateAssignee;
        }
    }
    private static void createOrderItemPCA(Id orderId, Order_Item_WebCommercal__c orderItemCMS, Id prodcutId, Map<Id, PricebookEntry> mapMcPriceBookEntry, List<OrderItem> orderItems) {
        OrderItem orderItem = new OrderItem();
        orderItem.Quantity = orderItemCMS.quantity__c;
        orderItem.OrderId = orderId;
        orderItem.Product2Id = prodcutId;
        orderItem.UnitPrice = mapMcPriceBookEntry.get(prodcutId).UnitPrice;
        orderItem.PricebookEntryId = mapMcPriceBookEntry.get(prodcutId).Id;
        orderItems.add(orderItem);
    }
    private static void createOrderPCA(Order_WebCommercal__c order, Map<string, Map<string, Account>> mapAccountDealer,
                                       Map<string, Id> mapProvince, Map<string, District__c> mapDistrict, Map<Id, Order> mapOrderIdCMSToCRM) {
        
        Order orderCRM = new Order();
        orderCRM.AccountId = mapAccountDealer.get(order.Customer_id__c).get(order.dealer_code__c).Id;
        orderCRM.Pricebook2Id = PRICEBOOKPCA.Id;
        if(string.isNotBlank(order.Web_Source_PCA__c))
        orderCRM.Order_Web_Source__c = order.Web_Source_PCA__c;
        orderCRM.DO_DL__c = mapAccountDealer.get(order.Customer_id__c).get(order.dealer_code__c).DO_DL_Create_Account__c;
        orderCRM.EffectiveDate = Date.today();
        orderCRM.RecordTypeId = RecordTypeHelper.ORDER_PCA;
        orderCRM.Status = 'Draft';
        orderCRM.Promotion_Item__c = order.Promotion_Item__c;
        orderCRM.Order_Ecommerce__c = order.Id;
        orderCRM.Order_Source__c = 'E-Commerce';
        orderCRM.Address_No__c = String.valueOf(order.receive_ward__c  + ' ' + order.Receive_address__c).replaceAll('null', '');
        orderCRM.Province__c = mapProvince.get(order.recevie_province__c);
		orderCRM.District__c = mapProvince.get(order.recevie_province__c) != null 
            					&& mapDistrict.get(order.receive_district__c).Province__c != null 
            					&& mapProvince.get(order.recevie_province__c).equals(mapDistrict.get(order.receive_district__c).Province__c) ? mapDistrict.get(order.receive_district__c).Id : null;
        
       mapOrderIdCMSToCRM.put(order.Id, orderCRM);
    }
    private static void createOpportunity(Order_WebCommercal__c order, Map<string, id> mapMcPCAExsting, Map<string, Map<string, Account>> mapAccountDealer, 
                                          Map<string, Id> mapProvince, Map<string, District__c> mapDistrict, Map<Id, Opportunity> orderEcommerceopps, List<Id> accountIsOwnerSales) {
        Account accountDO = mapAccountDealer.get(order.Customer_id__c).get(order.dealer_code__c);
        Opportunity opp = new Opportunity();
        opp.Product__c = mapMcPCAExsting.get(order.OrderItem_Web_Commercal__r[0].Product_Code__c + order.OrderItem_Web_Commercal__r[0].color_code__c);
        opp.StageName = 'New';
        opp.Name = 'Omni1 Solution Bike';
        opp.Order_WebCommercal__c = order.Id;
        opp.AccountId = accountDO.Id;
        opp.CloseDate = Date.today().addDays(30);
        opp.Is_CMS__c = TRUE;
        if (accountDO.Owner.Profile.Name == 'Community Sale Profile' || accountDO.Owner.Profile.Name == 'Community Sale Sup') {
        	accountIsOwnerSales.add(accountDO.Id);
            opp.OwnerId = mapAccountDealer.get(order.Customer_id__c).get(order.dealer_code__c).OwnerId;
        }
        
        opp.Province_Receive__c = mapProvince.get(order.recevie_province__c);
		opp.district_receive__c = mapProvince.get(order.recevie_province__c) != null 
            					&& mapDistrict.get(order.receive_district__c).Province__c != null 
            					&& mapProvince.get(order.recevie_province__c).equals(mapDistrict.get(order.receive_district__c).Province__c) ? mapDistrict.get(order.receive_district__c).Id : null;
   		opp.Ward_Receive__c = order.receive_ward__c;
        opp.Address_Receive__c = order.Receive_address__c;
		orderEcommerceopps.put(order.Id, opp);
   }
   
   private static void createQuoteToQuoteLine(Id opportunity, PricebookEntry priceBookEntry, Map<Id, Quote> mapOppquotes, Map<Id, QuoteLineItem> mapOppquoteItems, Id promotionItemId) { 
       DateTime today = DateTime.now();
       string formattedToday = today.formatGMT('ddMMyyyy');
       string quoteNameFormat = '-';
       quoteNameFormat += 'A';
       
       Quote q = new Quote();
       q.OwnerId = [SELECT Id FROM User WHERE Profile.Name = 'Community DO DL Manager' AND IsActive = True][0].Id;
       q.Promotion_Item__c = promotionItemId;
       q.RecordTypeId = RecordTypeHelper.QUOTE_SALES_BIKE;
       q.Delivery_Date__c = Date.today().addMonths(1);
       q.Name = formattedToday + quoteNameFormat;
       q.Pricebook2Id = priceBookEntry.Pricebook2Id;
       q.OpportunityId = opportunity;
       mapOppquotes.put(q.OpportunityId, q);
       
       QuoteLineItem item = new QuoteLineItem();
       item.QuoteId = q.Id;
       item.Quantity = 1;
       item.UnitPrice = priceBookEntry.UnitPrice;
       item.PricebookEntryId = priceBookEntry.Id;
       mapOppquoteItems.put(opportunity, item);
   }
   public static void onAfterUpdate(List<Order_WebCommercal__c> newData, Map<Id, Order_WebCommercal__c> newMap, Map<Id, Order_WebCommercal__c> oldMap) {
        syncStatusToCMS(newData, newMap, oldMap);
   }
   private static void syncStatusToCMS(List<Order_WebCommercal__c> newData, Map<Id, Order_WebCommercal__c> newMap, Map<Id, Order_WebCommercal__c> oldMap) {
        List<Id> orderIds = new List<Id>();
        for (Order_WebCommercal__c o : newData) {
            if (newMap.get(o.Id).Status__c != oldMap.get(o.Id).Status__c) 
                orderIds.add(o.Id);
        }
        if (!orderIds.isEmpty()) {
            system.enqueueJob(new APICMSUpdateOrder.UpdateStatusOrder(orderIds));
        }
    }
}