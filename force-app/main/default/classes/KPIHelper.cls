public without sharing class KPIHelper {
    
    public static void startCalculate(String recordId,List<Monthly_KPI_Employee__c> listEmployeeId)
    {
        String recordTypeContactEmployee = RecordTypeHelper.CONTACT_EMPLOYEE;

		
        
        system.debug('Start Calculate');
              
        //Monthly KPI
        Map<String, Schema.SObjectField> monthlyFieldMap = Monthly_KPI__c.sObjectType.getDescribe().fields.getMap();
        List<string> monthlySelectFields = new List<String>(monthlyFieldMap.keySet());                
        String monthlySoql = 'SELECT ' + String.join(monthlySelectFields, ',');
        monthlySoql += ' FROM Monthly_KPI__c';
        monthlySoql += ' WHERE Id =: recordId'; 
       	Monthly_KPI__c monthly = Database.query(monthlySoql);
        String monthlyId = monthly.Id;
        Date fromDate = Date.newInstance( Integer.valueOf(monthly.Year__c), Integer.valueOf(monthly.Month__c), 1);
        Date toDate = Date.newInstance( Integer.valueOf(monthly.Year__c), Integer.valueOf(monthly.Month__c) + 1, 1);
        Date fromDate3Month = Date.newInstance( Integer.valueOf(monthly.Year__c), Integer.valueOf(monthly.Month__c) - 2, 1);
        system.debug('From Date : '+ fromDate);
        system.debug('To Date : '+ toDate);
        
        String DODL = monthly.DO_DL__c;
        
        // Monthly KPI Employee
        Map<String, Schema.SObjectField> employeeSelectFieldMap = Monthly_KPI_Employee__c.sObjectType.getDescribe().fields.getMap();
        List<string> employeeSelectFields = new List<String>(employeeSelectFieldMap.keySet());                
        employeeSelectFields.add('KPI_Category_Management__r.Role__c');
        employeeSelectFields.add('Employee__r.Staff_Code__c');
        employeeSelectFields.add('Employee__r.Contact_Type__c');
        employeeSelectFields.add('Employee__r.Tech_Role__c');
        String employeeSoql = 'SELECT ' + String.join(employeeSelectFields, ',');
        employeeSoql += ' FROM Monthly_KPI_Employee__c';
        employeeSoql += ' WHERE Id in: listEmployeeId'; 
        List<Monthly_KPI_Employee__c> listEmployee = Database.query(employeeSoql); 
        List<String> listContactId = new List<String>();
        for(Monthly_KPI_Employee__c e : listEmployee)
        {
            listContactId.add(e.Employee__c);
        }
        
        // Monthly KPI Employee Detail // Đã chuyển qua dùng batch delete hết old detail trước khi tính toán
        /*Map<String, Schema.SObjectField> employeeDetailSelectFieldMap = Monthly_KPI_Employee_Detail__c.sObjectType.getDescribe().fields.getMap();
        List<string> employeeDetailSelectFields = new List<String>(employeeDetailSelectFieldMap.keySet());                
        String employeeDetailSoql = 'SELECT ' + String.join(employeeDetailSelectFields, ',');
        employeeDetailSoql += ' FROM Monthly_KPI_Employee_Detail__c';
        employeeDetailSoql += ' WHERE Monthly_KPI_Employee__c in: listEmployee'; 
        List<Monthly_KPI_Employee_Detail__c> listEmployeeDetail = Database.query(employeeDetailSoql); */
        
        
        //Contact
        Map<String, Schema.SObjectField> contactSelectFieldMap = Contact.sObjectType.getDescribe().fields.getMap();
        List<string> contactSelectFields = new List<String>(contactSelectFieldMap.keySet());              
        String contactSoql = 'SELECT ' + String.join(contactSelectFields, ',');
        contactSoql += ' FROM Contact';
        contactSoql += ' WHERE Id In: listContactId'; 
        List<Contact> listContact = Database.query(contactSoql);
        Map<String,String> mapManagerId = new Map<String,String>();
        for(Contact c : listContact)
        {
            mapManagerId.put(c.Id,c.Manager__c);
        }
        
        // User
        Map<String, Schema.SObjectField> userSelectFieldMap = User.sObjectType.getDescribe().fields.getMap();
        List<string> userSelectFields = new List<String>(userSelectFieldMap.keySet());                
        String userSoql = 'SELECT ' + String.join(userSelectFields, ',');
        userSoql += ' FROM User';
        userSoql += ' WHERE ContactId != null';
        //employeeSoql += ' WHERE Monthly_KPI_Employee__c in: listOrders'; 
        List<User> listUser = Database.query(userSoql);
        Map<String,String> mapUser = new Map<String,String>();
        for(User u : listUser)
        {            
            mapUser.put(u.Id,u.ContactId);
        }
        
        // Monthly Task 
        Map<String, Schema.SObjectField> mTaskSelectFieldMap = Monthly_Task__c.sObjectType.getDescribe().fields.getMap();       
        List<string> mTaskSelectFields = new List<String>(mTaskSelectFieldMap.keySet());  
        mTaskSelectFields.add('RecordType.Name');
        String mTaskSoql = 'SELECT ' + String.join(mTaskSelectFields, ',');
        mTaskSoql += ' FROM Monthly_Task__c';
        mTaskSoql += ' WHERE Contact__c in: listContact AND Is_Confirm__c = true AND Report_Date__c >=: fromDate AND Report_Date__c <: toDate  '; 
        mTaskSoql += ' AND Contact__r.AccountId =: DODL ';
        List<Monthly_Task__c> listMTask = Database.query(mTaskSoql);
        Map<String,List<Monthly_Task__c>> mapMTask = new Map<String,List<Monthly_Task__c>>();
        for(Monthly_Task__c mTask : listMTask)
        {
            if(!mapMTask.containsKey(mTask.Contact__c))
            {
                mapMTask.put(mTask.Contact__c,new List<Monthly_Task__c>());
            }
            mapMTask.get(mTask.Contact__c).add(mTask);
        }
        //system.debug(mapMTask);
        
        String recordTypeOrderWarranty = RecordTypeHelper.ORDER_WARRANTY;
        String recordTypeOrderFSC = RecordTypeHelper.ORDER_FREE_COUPON;

        //Order có invoice đây trong tháng
        Map<String, Schema.SObjectField> orderFieldMap = Order.sObjectType.getDescribe().fields.getMap();
        List<string> orderSelectFields = new List<String>(orderFieldMap.keySet());       
        orderSelectFields.add('Opportunity.OwnerId');
        orderSelectFields.add('Opportunity.Is_Used_Bike__c');
        orderSelectFields.add('Opportunity.Quote_Changed__c');
        orderSelectFields.add('Opportunity.Owner.Name');
        orderSelectFields.add('Opportunity.Order_WebCommercal__c');
        String orderSoql = 'SELECT ' + String.join(orderSelectFields, ',');
        orderSoql += ' FROM Order';
        orderSoql += ' WHERE ((Invoice_Date__c >=: fromDate AND Invoice_Date__c <: toDate) OR (KPI_Date__c >=: fromDate AND KPI_Date__c <=: toDate AND Status = \'Completed\' AND Is_Surveyed__c = true AND (RecordTypeId =: recordTypeOrderWarranty OR RecordTypeId =: recordTypeOrderFSC)))'; 
        orderSoql += ' AND DO_DL__c =: DODL ';
        //orderSoql += ' AND Opportunity.Is_Employee__c != true '; // YMVN-945       
        //orderSoql += ' AND Promotion_Item__r.Name != \'Employee Price for PCA\' '; // YMVN-945
        //orderSoql += ' AND Campaign__r.Promotion_Item__r.Name != \'Employee Price for PCA\' '; // YMVN-945
        List<Order> listOrders = Database.query(orderSoql); 
        List<Order> listOrdersService = new List<Order>();
        List<Order> listOrdersSale = new List<Order>();
        List<Order> listOrdersPCA = new List<Order>();
        List<Order> listOrdersWarratyFreeCoupon = new List<Order>(); 
        Set<String> setAccountBike = new Set<String>();
        Map<String,list<Order>> mapOrderSale = new Map<String,List<Order>>();
        Map<String,list<Order>> mapOrderService = new Map<String,List<Order>>();
        Map<String,list<Order>> mapOrderPCA = new Map<String,List<Order>>();
        Map<String,Order> mapOrder = new Map<String,Order>();
        for(Order o : listOrders)
        {                
            mapOrder.put(o.Id,o);
            
            if(  o.RecordTypeId == RecordTypeHelper.ORDER_BIKE &&  mapUser.containsKey(o.Opportunity.OwnerId))
            {
                listOrdersSale.add(o);
                setAccountBike.add(o.AccountId);
                
                String currentContractId = mapUser.get(o.Opportunity.OwnerId);
                
                if(!mapOrderSale.containsKey(currentContractId))
                {
                    mapOrderSale.put(currentContractId,new List<Order>());
                }
                mapOrderSale.get(currentContractId).add(o); 
            }
            else if( o.RecordTypeId == RecordTypeHelper.ORDER_PCA)
            {
                String currentContactId = '';
                if(o.Sale_Owner__c != null )
                {
                    currentContactId = mapUser.get(o.Sale_Owner__c);
                }
                else
                {
 					currentContactId = mapUser.get(o.OwnerId) ;                   
                } 
                
                if(!mapOrderPCA.containsKey(currentContactId))
                {
                    mapOrderPCA.put(currentContactId,new List<Order>());
                }
                mapOrderPCA.get(currentContactId).add(o);
                
                listOrdersPCA.add(o);    
            }
            else if(o.RecordTypeId == RecordTypeHelper.ORDER_WARRANTY || o.RecordTypeId == RecordTypeHelper.ORDER_FREE_COUPON )
            {
                listOrdersWarratyFreeCoupon.add(o);
            }           
            
            // cần check lại tất cả record type dùng tính giờ cho service
            if(o.RecordTypeId != RecordTypeHelper.ORDER_APPRAISAL && o.RecordTypeId != RecordTypeHelper.ORDER_BIKE 
              && o.RecordTypeId != RecordTypeHelper.ORDER_PCA && o.RecordTypeId != RecordTypeHelper.ORDER_PROFOMAR_ORDER && o.RecordTypeId != RecordTypeHelper.ORDER_SERVICE_PACKAGE)
            {              
                listOrdersService.add(o);               
                                                              
                if(!mapOrderService.containsKey(o.Cashier__c))
                {
                    mapOrderService.put(o.Cashier__c,new List<Order>());
                }
                mapOrderService.get(o.Cashier__c).add(o);         
            }
        }
        
        
        
        

        //Order Line
        Map<String, Schema.SObjectField> orderItemSelectFieldMap = OrderItem.sObjectType.getDescribe().fields.getMap();       
        List<string> orderItemSelectFields = new List<String>(orderItemSelectFieldMap.keySet());  
        orderItemSelectFields.add('Order.Mechanic__c');
        orderItemSelectFields.add('Order.Detailing_Staff__c');
        orderItemSelectFields.add('Order.Cashier__c');
        orderItemSelectFields.add('Order.OwnerId');
        orderItemSelectFields.add('Order.Sale_Owner__c');
        orderItemSelectFields.add('Order.Invoice_Date__c');
        orderItemSelectFields.add('Order.Order__c');
        orderItemSelectFields.add('Product2.Service_Type__c');
        orderItemSelectFields.add('Product2.PCA_Type__c'); 
        orderItemSelectFields.add('Product2.RecordTypeId');
        orderItemSelectFields.add('Product2.Family'); 
        orderItemSelectFields.add('Order.RecordTypeId');   
        orderItemSelectFields.add('Order.RecordType.Name'); 
        orderItemSelectFields.add('Order.Service_Hours__c'); 
        orderItemSelectFields.add('Order.Detailing_Hours__c');
        orderItemSelectFields.add('Order.Total_Survey_Sales__c'); 
        orderItemSelectFields.add('Order.Total_Survey_Service__c'); 
        orderItemSelectFields.add('Order.Total_Survey_PCA__c'); 
        orderItemSelectFields.add('Order.TSI__c'); 
        orderItemSelectFields.add('Order.Order_Number__c'); 
        orderItemSelectFields.add('Order.Status');     
        
        String orderFreeCouponId = RecordTypeHelper.ORDER_FREE_COUPON;
        String orderFreeServiceId = RecordTypeHelper.ORDER_FREE_SERVICE;
        String orderInternalServiceId = RecordTypeHelper.ORDER_INTERNAL_SERVICE;
        String orderRecallId = RecordTypeHelper.ORDER_RECALL;
        String orderWarrantyId = RecordTypeHelper.ORDER_WARRANTY;
        String orderInstallId = RecordTypeHelper.ORDER_INSTALLATION;
        String orderQuickServiceId = RecordTypeHelper.ORDER_QUICK_SERVICE;
        String orderAppraisalId = RecordTypeHelper.ORDER_APPRAISAL;
        string orderPCAId = RecordTypeHelper.ORDER_PCA;
        String orderServicePackageId = RecordTypeHelper.ORDER_SERVICE_PACKAGE;
            
        String orderItemSoql = 'SELECT ' + String.join(orderItemSelectFields, ',');
        orderItemSoql += ' FROM OrderItem';
        //orderItemSoql += ' WHERE ((Order.Bike_Delivery_Date__c >=: fromDate AND Order.Bike_Delivery_Date__c <: toDate AND (Order.RecordTypeId =: orderFreeCouponId OR Order.RecordTypeId =: orderFreeServiceId OR Order.RecordTypeId =: orderInternalServiceId  OR Order.RecordTypeId =: orderRecallId OR Order.RecordTypeId =: orderWarrantyId))'; //(OrderId in: listOrdersService OR OrderId in: listOrdersPCA) 
        //orderItemSoql += ' OR (Order.Invoice_Date__c >=: fromDate AND Order.Invoice_Date__c <: toDate AND (Order.RecordTypeId =: orderInstallId OR Order.RecordTypeId =: orderQuickServiceId OR Order.RecordTypeId =: orderAppraisalId OR Order.RecordTypeId =: orderPCAId  OR Order.RecordTypeId =: orderServicePackageId  )))';
        orderItemSoql += ' WHERE Order.KPI_Date__c  >=: fromDate AND Order.KPI_Date__c <: toDate AND Order.Status = \'Completed\'';
        orderItemSoql += ' AND Order.DO_DL__c =: DODL ';
		//orderItemSoql += ' AND Order.Opportunity.Is_Employee__c = false '; // YMVN-945
        //orderItemSoql += ' AND Order.Promotion_Item__r.Name = \'Employee Price for PCA\' '; // YMVN-945
        //orderItemSoql += ' AND Order.Campaign__r.Promotion_Item__r.Name != \'Employee Price for PCA\' '; // YMVN-945
        //orderItemSoql += ' AND Order.Is_Employee__c != true '; // YMVN-945
        
        List<OrderItem> listOrderItem = Database.query(orderItemSoql);
        Map<String,List<OrderItem>> mapOrderItemMechanic = new Map<String,List<OrderItem>>();
        Map<String,List<OrderItem>> mapOrderItemDetailing = new Map<String,List<OrderItem>>();
        //Map<String,List<OrderItem>> mapOrderItemService = new Map<String,List<OrderItem>>();
        Map<String,List<OrderItem>> mapOrderItemPCA = new Map<String,List<OrderItem>>();
        List<OrderItem> listOrderItemPerfomar = new List<OrderItem>();
        List<OrderItem> listOrderItemPCAPerfomar = new List<OrderItem>();
        List<OrderItem> listOrderItemService = new List<OrderItem>();
        List<OrderItem> listOrderItemPCA = new List<OrderItem>();
        List<OrderItem> listOrderItemPCAFromServiceOrder = new List<OrderItem>();
        
        for(OrderItem item : listOrderItem)
        {
            if(item.Product2.Service_Type__c == 'Repair'  && (item.Product2.RecordTypeId == RecordTypeHelper.SV_JOB || item.Product2.RecordTypeId == RecordTypeHelper.PRODUCT_SERVICE_PACKAGE ))
            {
                if(!mapOrderItemMechanic.containsKey(item.Order.Mechanic__c))
                {
                    mapOrderItemMechanic.put(item.Order.Mechanic__c,new List<OrderItem>());
                }
                
         		
                mapOrderItemMechanic.get(item.Order.Mechanic__c).add(item);
                
   
                
                /*if(item.Order.Cashier__c != null && !mapOrderItemService.containsKey(item.Order.Cashier__c))
                {
                    mapOrderItemService.put(item.Order.Cashier__c,new List<OrderItem>());
                }
                mapOrderItemService.get(item.Order.Cashier__c).add(item);*/          
                
                listOrderItemService.add(item);
            }
            else if(item.Product2.Service_Type__c == 'Detailing' && (item.Product2.RecordTypeId == RecordTypeHelper.SV_JOB || item.Product2.RecordTypeId == RecordTypeHelper.PRODUCT_SERVICE_PACKAGE))
            {
                if(!mapOrderItemDetailing.containsKey(item.Order.Detailing_Staff__c))
                {
                    mapOrderItemDetailing.put(item.Order.Detailing_Staff__c,new List<OrderItem>());
                }
                mapOrderItemDetailing.get(item.Order.Detailing_Staff__c).add(item);
                
                /*if(item.Order.Cashier__c != null && !mapOrderItemService.containsKey(item.Order.Cashier__c))
                {
                    mapOrderItemService.put(item.Order.Cashier__c,new List<OrderItem>());
                }
                mapOrderItemService.get(item.Order.Cashier__c).add(item);*/
                listOrderItemService.add(item);
            }    
            else if(item.Product2.RecordTypeId == RecordTypeHelper.PRODUCT_PCA)
            {                
                String currentContactId;
                if(item.Order.Sale_Owner__c != null)
                {
                    currentContactId = mapUser.get(item.Order.Sale_Owner__c);
                }
                else
                {
                    currentContactId = mapUser.get(item.Order.OwnerId);
                }
                    
                if(!mapOrderItemPCA.containsKey(currentContactId))
                {
                    mapOrderItemPCA.put(currentContactId,new List<OrderItem>());
                }
                mapOrderItemPCA.get(currentContactId).add(item);
                
                listOrderItemPCA.add(item);
                
                if(item.Order.RecordTypeId != RecordTypeHelper.ORDER_APPRAISAL && item.Order.RecordTypeId != RecordTypeHelper.ORDER_BIKE 
                   && item.Order.RecordTypeId != RecordTypeHelper.ORDER_PCA && item.Order.RecordTypeId != RecordTypeHelper.ORDER_PROFOMAR_ORDER && item.Order.RecordTypeId != RecordTypeHelper.ORDER_SERVICE_PACKAGE)
                {
                    listOrderItemPCAFromServiceOrder.add(item);
                }
                
                
                if(item.Profomar_Order__c == true)
                {
                    listOrderItemPCAPerfomar.add(item);
                }
            }
            /*else if(item.Order.RecordTypeId == RecordTypeHelper.ORDER_PROFOMAR_ORDER)
            {
                if(item.Order.Order__c == null)
                {
                    listOrderItemPerfomar.add(item);
                }
            }*/
        }
        
        String productTypePCAId = RecordTypeHelper.PRODUCT_PCA;
        Map<String, Schema.SObjectField> orderLinePCAFieldMap = OrderItem.sObjectType.getDescribe().fields.getMap();
        List<string> orderLinePCASelectFields = new List<String>(orderLinePCAFieldMap.keySet());       
        String orderLinePCASoql = 'SELECT ' + String.join(orderLinePCASelectFields, ',');
        orderLinePCASoql += ' FROM OrderItem';
        orderLinePCASoql += ' WHERE Order.Invoice_Date__c >=: fromDate AND Order.Invoice_Date__c <: toDate AND Order.AccountId in: setAccountBike AND Product2.RecordTypeId =: productTypePCAId'; 
        orderLinePCASoql += ' AND Order.DO_DL__c =: DODL ';         
        //orderLinePCASoql += ' AND (Order.Promotion_Item__r.Name != \'Employee Price for PCA\' OR Order.Campaign__r.Promotion_Item__r.Name != \'Employee Price for PCA\') '; // YMVN-945
        
        List<OrderItem> listOrdersLinePCAFromBike = Database.query(orderLinePCASoql); 
        
        Decimal newBikeDelivery = 0;
        if(listOrdersSale.size() > 0)
        {
            Decimal amountOrderPCAFromBike = 0;
            Decimal amountOrderSale  = 0;
            
            for(OrderItem o : listOrdersLinePCAFromBike)
            {
                amountOrderPCAFromBike += o.KPI_Amount__c;
            }
            for(Order o : listOrdersSale)
            {
                amountOrderSale += o.Amount__c;
            }
            
            newBikeDelivery =  amountOrderPCAFromBike /  amountOrderSale * 100 ;
        }
        
                  
        
        // Opportunity
        Map<String, Schema.SObjectField> optyFieldMap = Opportunity.sObjectType.getDescribe().fields.getMap();
        List<string> optySelectFields = new List<String>(optyFieldMap.keySet());       
        optySelectFields.add('SyncedQuote.Changed__c');
        optySelectFields.add('Product__r.Bike_Type_2__c');
        optySelectFields.add('Order__r.Invoice_Date__c');
        optySelectFields.add('Order__r.Total_Amount__c');
        optySelectFields.add('Order__r.Amount__c');
        optySelectFields.add('Order__r.Order_Source__c');        
        optySelectFields.add('Order__r.Id');
        optySelectFields.add('Order__r.Status');
        String optySoql = 'SELECT ' + String.join(optySelectFields, ',');
        optySoql += ' FROM Opportunity';
        if(monthly.Month__c == 4 && monthly.Year__c == 2022)
        {
            optySoql += ' WHERE CreatedDate <: toDate '; 
        }
        else
        {
            optySoql += ' WHERE (CreatedDate >=: fromDate and CreatedDate <: toDate)';// yêu cầu thay đổi 26/4/2023 chưa confirm // or (Order__r.Invoice_Date__c != null and Order__r.Status__c = \'Completed\' and Order__r.Invoice_Date__r >=: fromDate and Order__r.Invoice_Date__r <: toDate ') '; 
        }
        optySoql += ' AND DODL_Create__c =: DODL ';
        //optySoql += ' AND Is_Employee__c = false '; // YMVN-945
        
        List<Opportunity> listOpty = Database.query(optySoql); 
        Map<String,list<Opportunity>> mapOpty = new Map<String,List<Opportunity>>();
        for(Opportunity o : listOpty)
        {
            if(mapUser.containsKey(o.OwnerId))
            {
                String currentContactId = mapUser.get(o.OwnerId);
                if(!mapOpty.containsKey(currentContactId))
                {
                    mapOpty.put(currentContactId,new List<Opportunity>());
                }
                mapOpty.get(currentContactId).add(o);         
            }             
        }
        
        //ORDER BIKE
        Map<String, Schema.SObjectField>  orderBikeKPIFieldMap = Order_Bike_KPI__c.sObjectType.getDescribe().fields.getMap();
        List<string> orderBikeKPISelectFields = new List<String>(orderBikeKPIFieldMap.keySet());       
        orderBikeKPISelectFields.add('Opportunity__r.Is_Used_Bike__c');
        orderBikeKPISelectFields.add('Opportunity__r.Order__r.Order_Source__c');
        orderBikeKPISelectFields.add('Opportunity__r.Quote_Changed__c');
        orderBikeKPISelectFields.add('Opportunity__r.Order__c');
        orderBikeKPISelectFields.add('Opportunity__r.Owner.Name');
        orderBikeKPISelectFields.add('Opportunity__r.Order_WebCommercal__c');        
        String orderBikeKPISoql = 'SELECT ' + String.join(orderBikeKPISelectFields, ',');
        orderBikeKPISoql += ' FROM Order_Bike_KPI__c';
        orderBikeKPISoql += ' WHERE Invoice_Date__c >=: fromDate AND Invoice_Date__c <: toDate '; 
        orderBikeKPISoql += ' AND Order__r.DO_DL__c =: DODL ';
        //orderBikeKPISoql += ' AND Opportunity__r.Is_Employee__c = false '; // YMVN-945
        List<Order_Bike_KPI__c> listOrderBikeKPI = Database.query(orderBikeKPISoql); 
        Map<String,List<Order_Bike_KPI__c>> mapOrderBikeKPIByContact = new Map<String,List<Order_Bike_KPI__c>>();
        Map<String,List<Order_Bike_KPI__c>> mapOrderBikeKPIByOppty = new Map<String,List<Order_Bike_KPI__c>>();
        for(Order_Bike_KPI__c ob : listOrderBikeKPI)
        {
            String currentContactId = mapUser.get(ob.Employee__c);
            //mapOrderBikeKPI.put(ob.Order__c+'_'+currentContactId,ob);
            if(!mapOrderBikeKPIByContact.containsKey(currentContactId))
            {
				mapOrderBikeKPIByContact.put(currentContactId,new List<Order_Bike_KPI__c>());
            }
            mapOrderBikeKPIByContact.get(currentContactId).add(ob);
            
            if(!mapOrderBikeKPIByOppty.containsKey(ob.Opportunity__c))
            {
				mapOrderBikeKPIByOppty.put(ob.Opportunity__c,new List<Order_Bike_KPI__c>());
            }
            mapOrderBikeKPIByOppty.get(ob.Opportunity__c).add(ob);
        }
        
        // Opportunity CS Review
        Map<String, Schema.SObjectField> optyCSReviewFieldMap = Opportunity.sObjectType.getDescribe().fields.getMap();
        List<string> optyCSReviewSelectFields = new List<String>(optyCSReviewFieldMap.keySet());       
        optyCSReviewSelectFields.add('SyncedQuote.Changed__c');
        optyCSReviewSelectFields.add('Product__r.Bike_Type_2__c');
        optyCSReviewSelectFields.add('Order__r.Invoice_Date__c');
        String optyCSReviewSoql = 'SELECT ' + String.join(optyCSReviewSelectFields, ',');
        optyCSReviewSoql += ' FROM Opportunity';
        optyCSReviewSoql += ' WHERE CS_Review_Date__c >=: fromDate and CS_Review_Date__c <: toDate AND Wrong_Info__c != null'; 
        optyCSReviewSoql += ' AND DODL_Create__c =: DODL ';
        List<Opportunity> listCSReviewOpty = Database.query(optyCSReviewSoql); 
        Map<String,list<Opportunity>> mapCSReviewOpty = new Map<String,List<Opportunity>>();
        for(Opportunity o : listCSReviewOpty)
        {
            if(mapUser.containsKey(o.OwnerId))
            {
                String currentContactId = mapUser.get(o.OwnerId);
                if(!mapCSReviewOpty.containsKey(currentContactId))
                {
                    mapCSReviewOpty.put(currentContactId,new List<Opportunity>());
                }
                mapCSReviewOpty.get(currentContactId).add(o);         
            }             
        }
        
        //Test Ride
        Map<String, Schema.SObjectField> testRideFieldMap = Test_Ride__c.sObjectType.getDescribe().fields.getMap();       
        List<string> testRideSelectFields = new List<String>(testRideFieldMap.keySet());
        testRideSelectFields.add('Opportunity__r.OwnerId'); 
        String testRideSoql = 'SELECT ' + String.join(testRideSelectFields, ',');
        testRideSoql += ' FROM Test_Ride__c';
        testRideSoql += ' WHERE CreatedDate >=: fromDate and CreatedDate <: toDate '; 
        testRideSoql += ' AND Opportunity__r.DODL_Create__c =: DODL ';
        List<Test_Ride__c> listTestRide = Database.query(testRideSoql); 
        Map<String,List<Test_Ride__c>> mapTestRide = new Map<String,List<Test_Ride__c>>();
        for(Test_Ride__c ride : listTestRide) 
        {
            if(mapUser.containsKey(ride.Opportunity__r.OwnerId))
            {
                String currentContactId = mapUser.get(ride.Opportunity__r.OwnerId);
                if(!mapTestRide.containsKey(currentContactId))
                {
                    mapTestRide.put(currentContactId,new List<Test_Ride__c>());
                }
                mapTestRide.get(currentContactId).add(ride); 
            }            
        }

        
        // Follow Fail
        Map<String, Schema.SObjectField> failFieldMap = Follow_Fail__c.sObjectType.getDescribe().fields.getMap();
        List<string> failSelectFields = new List<String>(failFieldMap.keySet());                
        failSelectFields.add('Lead__r.OwnerId');
        failSelectFields.add('Order__r.OwnerId');
        String failSoql = 'SELECT ' + String.join(failSelectFields, ',');
        failSoql += ' FROM Follow_Fail__c';
        failSoql += ' WHERE CreatedDate >=: fromDate and CreatedDate <: toDate '; 
        failSoql += ' AND Consultant__r.Contact.AccountId =: DODL '; 
        List<Follow_Fail__c> listFail = Database.query(failSoql); 
        Map<String,list<Follow_Fail__c>> mapFail = new Map<String,List<Follow_Fail__c>>();
        for(Follow_Fail__c f : listFail)
        {
            if(f.Lead__r.OwnerId != null && mapUser.containsKey(f.Lead__r.OwnerId))
            {
                String currentContactId = mapUser.get(f.Lead__r.OwnerId);
                if(!mapFail.containsKey(currentContactId))
                {
                    mapFail.put(currentContactId,new List<Follow_Fail__c>());
                }
                mapFail.get(currentContactId).add(f);
            }   
            if(f.Order__c != null && mapUser.containsKey(f.Consultant__c))
            {
                String currentContactId = mapUser.get(f.Consultant__c);
                if(!mapFail.containsKey(currentContactId))
                {
                    mapFail.put(currentContactId,new List<Follow_Fail__c>());
                }
                mapFail.get(currentContactId).add(f);
            }
        }
        
        // Roster Managements
        Map<String, Schema.SObjectField> rosterFieldMap = Roster_Management__c.sObjectType.getDescribe().fields.getMap();
        List<string> rosterSelectFields = new List<String>(rosterFieldMap.keySet());     
        rosterSelectFields.add('Staff__r.Tech_Role__c');
        rosterSelectFields.add('Staff__r.Contact_Type__c');
        String rosterSoql = 'SELECT ' + String.join(rosterSelectFields, ',');
        rosterSoql += ' FROM Roster_Management__c';
        rosterSoql += ' WHERE Date__c >=: fromDate and Date__c <: toDate '; 
        rosterSoql += ' AND DO_DL__c =: DODL ';
        List<Roster_Management__c> listRoster = Database.query(rosterSoql); 
        Map<String,List<Roster_Management__c>> mapRoster = new Map<String,List<Roster_Management__c>>();
        List<Roster_Management__c> listRosterWithoutChief = new List<Roster_Management__c>();
        for(Roster_Management__c r : listRoster)
        {
            if(!mapRoster.containsKey(r.Staff_Code__c)){
                mapRoster.put(r.Staff_Code__c,new list<Roster_Management__c>());
            }
            mapRoster.get(r.Staff_Code__c).add(r);
            
            if(r.Staff__r.Tech_Role__c != 'Chief technician / Detailing expert' && r.Staff__r.Tech_Role__c != null)
            {
                listRosterWithoutChief.add(r);
            }     
        }
        
        // Lay unique acc cua order trong 3 tháng
        /*AggregateResult[] groupedResults
            = [SELECT AccountId
               FROM Order
               Where CreatedDate >=: fromDate3Month and CreatedDate <: toDate
               GROUP BY AccountId];
        
        Set<String> setAccId = new Set<String>();
        for(AggregateResult ar : groupedResults)
        {
            setAccId.add(String.valueOf( ar.get('AccountId')));
        }*/
        
        Integer countCustomerHaveActivity = [Select count() from Account where RecordTypeId =: RecordTypeHelper.ACCOUNT_CUSTOMER and Last_Activity_For_KPI__c >=: fromDate3Month
                                            and Last_Activity_For_KPI__c <: Date.today() and DO_DL_Create_Account__c =: DODL];
        
        Integer countCustomer = [Select count() from Account where RecordTypeId =: RecordTypeHelper.ACCOUNT_CUSTOMER AND DO_DL_Create_Account__r.DO_DL_Code__c != null and DO_DL_Create_Account__c =: DODL];
		//system.debug(setAccId);       
		// Số khách hàng có activity trong 3 tháng / tổng số khách hàng 
		/*if(countCustomer > 0)
        {
            retentionRate = countCustomerHaveActivity / countCustomer;  
        } */
        
        Map<String, Schema.SObjectField> caseFieldMap = Case.sObjectType.getDescribe().fields.getMap();
        List<string> caseSelectFields = new List<String>(caseFieldMap.keySet());                
        String caseSoql = 'SELECT ' + String.join(caseSelectFields, ',');
        caseSoql += ' FROM Case';
        caseSoql += ' WHERE CreatedDate >=: fromDate and CreatedDate <: toDate and Handling_Time__c > 24'; 
        caseSoql += ' AND DO_DL__c  =: DODL '; 
        List<Case> listCase = Database.query(caseSoql); 
        Map<String,List<Case>> mapCase = new Map<String,List<Case>>();
        List<Case> ListServiceCase = new List<Case>();
        for(Case c : listCase)
        {
            if(mapUser.containsKey(c.OwnerId))
            {
                String currentContactId = mapUser.get(c.OwnerId);
                if(!mapCase.containsKey(currentContactId))
                {
                    mapCase.put(currentContactId,new list<case>());
                }
                mapCase.get(currentContactId).add(c);   
                
                if(c.Group__c == 'Service' )
                {
                    listServiceCase.add(c);
                }
            }
        }
        
        /*Map<String, Schema.SObjectField> inventFieldMap = Warehouse_Inventory__c.sObjectType.getDescribe().fields.getMap();
        List<string> inventSelectFields = new List<String>(inventFieldMap.keySet());                
        String inventSoql = 'SELECT ' + String.join(inventSelectFields, ',');
        inventSoql += ' (SELECT  OldValue, NewValue FROM Histories) ';
        inventSoql += ' FROM Warehouse_Inventory__c';
        inventSoql += ' WHERE Stocking_Date__c =: fromDate or Stocking_Date__c =: toDate '; 
        List<Warehouse_Inventory__c> listInventory = Database.query(inventSoql); 
        List<Warehouse_Inventory__c> listStartMonthInventory = new List<Warehouse_Inventory__c>();
        List<Warehouse_Inventory__c> listEndMonthInventory = new List<Warehouse_Inventory__c>();
        Decimal startMonthStock = 0;
        Decimal endMonthStock = 0;
        for(Warehouse_Inventory__c inv : listInventory)
        {
            if(inv.Stocking_Date__c == fromDate)
            {
                startMonthStock += inv.QoH__c * inv.Price_Include_VAT__c;
                listStartMonthInventory.add(inv);
            }
            else if(inv.Stocking_Date__c == toDate)
            {
                endMonthStock += inv.QoH__c * inv.Price_Include_VAT__c;
                listEndMonthInventory.add(inv);
            }
        }     */
        
        Date stockStartDate = fromDate;
        Date stockEndDate = toDate ; // stock đầu ngày của tháng sau
        Decimal startMonthStock = 0;
        Decimal endMonthStock = 0;
        Map<String, Schema.SObjectField> stockHistoryFieldMap = Stock_History__c.sObjectType.getDescribe().fields.getMap();
        List<string> stockHistorySelectFields = new List<String>(stockHistoryFieldMap.keySet());                
        stockHistorySelectFields.add('Product__r.Retail_Price__c');
        stockHistorySelectFields.add('Product__r.KPI_Price__c');        
        String stockHistorySoql = 'SELECT ' + String.join(stockHistorySelectFields, ',');
        stockHistorySoql += ' FROM Stock_History__c';
        if(monthly.Month__c == 4 && monthly.Year__c == 2022)
        {
            stockStartDate = Date.newInstance(2022, 4, 14);
        }
        stockHistorySoql += ' WHERE (Date__c =: stockStartDate or Date__c =: stockEndDate) AND Product__c != null AND Stock_At_The_Start__c > 0 AND Product__r.KPI_Price__c > 0 ';   
        stockHistorySoql += ' AND Account__c =: DODL ';
        List<Stock_History__c> listStockHistory = Database.query(stockHistorySoql); 
        List<Stock_History__c> listStartMonthStockHistory = new List<Stock_History__c>();
        List<Stock_History__c> listEndMonthStockHistory = new List<Stock_History__c>();
        for(Stock_History__c sh : listStockHistory)
        {        
            if(sh.Date__c == stockStartDate)
            {
                listStartMonthStockHistory.add(sh);               
                startMonthStock += sh.Stock_At_The_Start__c * sh.Product__r.KPI_Price__c;
            }
            else if(sh.Date__c == stockEndDate)
            {
                listEndMonthStockHistory.add(sh);                
                endMonthStock += sh.Stock_At_The_Start__c * sh.Product__r.KPI_Price__c;
            }
        } 
        
        List<Warehouse_Inventory__c> listThreeMonthMonthInventory = new List<Warehouse_Inventory__c>();
        List<Inventory_Transaction_Item__c> listThreeMonthInventory = new List<Inventory_Transaction_Item__c>();
        Decimal threeMonthDayStock = 0;
        Map<String, Schema.SObjectField> inventThreeMonthFieldMap = Inventory_Transaction_Item__c.sObjectType.getDescribe().fields.getMap();
        List<string> inventThreeMonthSelectFields = new List<String>(inventThreeMonthFieldMap.keySet());                
        String inventThreeMonthSoql = 'SELECT ' + String.join(inventThreeMonthSelectFields, ',');
        inventThreeMonthSoql += ' FROM Inventory_Transaction_Item__c';
        inventThreeMonthSoql += ' WHERE Stock_Age__c > 180 '; 
        inventThreeMonthSoql += ' AND Quantity_Amount_Remaing_KPI__c > 0 '; 
        inventThreeMonthSoql += ' AND Warehouse_Location__r.Account__c =: DODL ';
        List<Inventory_Transaction_Item__c> listThreeMonthInventoryItem = Database.query(inventThreeMonthSoql); 
        for(Inventory_Transaction_Item__c inv : listThreeMonthInventoryItem)
        {
            threeMonthDayStock += inv.Quantity_Amount_Remaing_KPI__c * inv.Price_Include_VAT__c;
            listThreeMonthInventory.add(inv);
        }
        
        Map<String, Schema.SObjectField> paymentVoucherFieldMap = Payment__c.sObjectType.getDescribe().fields.getMap();
        List<string> paymentVoucherSelectFields = new List<String>(paymentVoucherFieldMap.keySet());                
        String paymentVoucherSoql = 'SELECT ' + String.join(paymentVoucherSelectFields, ',');
        paymentVoucherSoql += ' FROM Payment__c';
        paymentVoucherSoql += ' WHERE (Order__c in: listOrdersService OR Order__c in: listOrdersPCA) and Payment_Term__c = \'Voucher\' '; 
        paymentVoucherSoql += ' AND Order__r.DO_DL__c =: DODL ';
        List<Payment__c> listPaymentVoucher = Database.query(paymentVoucherSoql); 
        Map<String,List<Payment__c>> mapPaymentVoucher = new Map<String,List<Payment__c>>();
        for(Payment__c p : listPaymentVoucher)
        {
            if(!mapPaymentVoucher.containsKey(p.Order__c))
            {
                mapPaymentVoucher.put(p.Order__c,new List<Payment__c>());
            }
           	mapPaymentVoucher.get(p.Order__c).add(p);
        }
        
        List<Monthly_KPI_Employee__c> listSalesConsultant = new List<Monthly_KPI_Employee__c>();
        List<Monthly_KPI_Employee__c> listSalesSupevisor = new List<Monthly_KPI_Employee__c>();
        List<Monthly_KPI_Employee__c> listSalesAM = new List<Monthly_KPI_Employee__c>();
        List<Monthly_KPI_Employee__c> listServiceConsultant = new List<Monthly_KPI_Employee__c>();
        List<Monthly_KPI_Employee__c> listServiceTechnician = new List<Monthly_KPI_Employee__c>();
        List<Monthly_KPI_Employee__c> listServiceAM = new List<Monthly_KPI_Employee__c>();
        List<Monthly_KPI_Employee__c> listPCAConsultant = new List<Monthly_KPI_Employee__c>();
        List<Monthly_KPI_Employee__c> listPCASupervisor = new List<Monthly_KPI_Employee__c>();
        
        Map<String,List<Monthly_KPI_Employee__c>> mapSalesConsultant = new Map<String,List<Monthly_KPI_Employee__c>>();
        Map<String,List<Monthly_KPI_Employee__c>> mapSalesSupevisor = new Map<String,List<Monthly_KPI_Employee__c>>();
        Map<String,List<Monthly_KPI_Employee__c>> mapServiceConsultant = new Map<String,List<Monthly_KPI_Employee__c>>();
        Map<String,List<Monthly_KPI_Employee__c>> mapServiceTechnician = new Map<String,List<Monthly_KPI_Employee__c>>();
        Map<String,List<Monthly_KPI_Employee__c>> mapPCAConsultant = new Map<String,List<Monthly_KPI_Employee__c>>();
        
        List<Monthly_KPI_Employee__c> listSalesChildForAM = new List<Monthly_KPI_Employee__c>();
        List<Monthly_KPI_Employee__c> listServiceChildForAM = new List<Monthly_KPI_Employee__c>();
        List<Monthly_KPI_Employee__c> listPCAChildForAM = new List<Monthly_KPI_Employee__c>();   
        
        for(Monthly_KPI_Employee__c c : listEmployee)
        {
            if(c.KPI_Category_Management__r.Role__c == 'Sales Consultant')
            {
				listSalesConsultant.add(c);
                if(!mapSalesConsultant.containsKey(c.Manager__c))
                {
                    mapSalesConsultant.put(c.Manager__c,new List<Monthly_KPI_Employee__c>());
                }
                mapSalesConsultant.get(c.Manager__c).add(c);
                
                listSalesChildForAM.add(c);
            }
            else if(c.KPI_Category_Management__r.Role__c == 'Sales Supevisor')
            {
                listSalesSupevisor.add(c);
                if(!mapSalesSupevisor.containsKey(c.Manager__c))
                {
                    mapSalesSupevisor.put(c.Manager__c,new List<Monthly_KPI_Employee__c>());
                }
                mapSalesSupevisor.get(c.Manager__c).add(c);
                listSalesChildForAM.add(c);
            }
            else if(c.KPI_Category_Management__r.Role__c == 'Sales AM/Manager')
            {
                listSalesAM.add(c);
            }
            else if(c.KPI_Category_Management__r.Role__c == 'Service Consultant')
            {
                listServiceConsultant.add(c);
                if(!mapServiceConsultant.containsKey(c.Manager__c))
                {
                    mapServiceConsultant.put(c.Manager__c,new List<Monthly_KPI_Employee__c>());
                }
                mapServiceConsultant.get(c.Manager__c).add(c);
                listServiceChildForAM.add(c);
            }
            else if(c.KPI_Category_Management__r.Role__c == 'Service Technician')
            {
                listServiceTechnician.add(c);
                if(!mapServiceTechnician.containsKey(c.Manager__c))
                {
                    mapServiceTechnician.put(c.Manager__c,new List<Monthly_KPI_Employee__c>());
                }
                mapServiceTechnician.get(c.Manager__c).add(c);
                //listServiceChildForAM.add(c);
            }
            else if(c.KPI_Category_Management__r.Role__c == 'Service AM/Sup')
            {
                listServiceAM.add(c);
            }
            else if(c.KPI_Category_Management__r.Role__c == 'PCA Sales Consultant')
            {
                listPCAConsultant.add(c);
                if(!mapPCAConsultant.containsKey(c.Manager__c))
                {
                    mapPCAConsultant.put(c.Manager__c,new List<Monthly_KPI_Employee__c>());
                }
                mapPCAConsultant.get(c.Manager__c).add(c);
                listPCAChildForAM.add(c);
            }
            else if(c.KPI_Category_Management__r.Role__c == 'PCA Supervisor')
            {
                listPCASupervisor.add(c);
            }
        }
        
        List<Monthly_KPI_Employee_Detail__c> listMKPIDetail = new List<Monthly_KPI_Employee_Detail__c>();
        
        for(Monthly_KPI_Employee__c e : listSalesConsultant)
        {         
            List<Order> listCurrentOrder = new List<Order>();
            List<Opportunity> listCurrentOpty = new List<Opportunity>();
            List<Opportunity> listCurrentCSOpty = new List<Opportunity>();
            List<Test_Ride__c> listCurrentTestRide = new List<Test_Ride__c>();
            List<Follow_Fail__c> listCurrentFollowFail = new List<Follow_Fail__c>();
            if(mapOrderSale.containsKey(e.Employee__c))
            {
                listCurrentOrder = mapOrderSale.get(e.Employee__c);
            }
            if(mapOpty.containsKey(e.Employee__c))
            {
                listCurrentOpty = mapOpty.get(e.Employee__c);
            }
            if(mapTestRide.containsKey(e.Employee__c))
            {
                listCurrentTestRide = mapTestRide.get(e.Employee__c);
            }
            if(mapFail.containsKey(e.Employee__c))
            {
                listCurrentFollowFail = mapFail.get(e.Employee__c);
            }
            
            if(mapCSReviewOpty.containsKey(e.Employee__c))
            {
                
                listCurrentCSOpty = mapCSReviewOpty.get(e.Employee__c);
            }
            
            
            
            Decimal totalTestRide = 0;
            Decimal totalContent = 0;
            Decimal currentTSI = 0;
            Decimal avarageTSI = 0;
            Decimal totalFollowFail = 0;
            
            Decimal saleVolume = 0;
            Decimal numberEnquiries = listCurrentOpty.size();
            Decimal quantityOpty = 0;
            Decimal totalOrderSurvey = 0;
            
			Decimal promoIn = 0;
            Decimal promoOut = 0;
            Decimal eCommerce = 0;
            Decimal usedBike = 0;
            
            for(Test_Ride__c tR : listCurrentTestRide)  
            {
                totalTestRide += tR.Total_Test_Ride__c;
                listMKPIDetail.add(createEmployeeRuleDetail(tR.Id,'4',tR.Total_Test_Ride__c,e.Id,'Test Ride','Test Ride',null));
            }
            
            // 20/5/2022 // chạy cho opty có team
            if(mapOrderBikeKPIByContact.containsKey(e.Employee__c))
            {
                List<Order_Bike_KPI__c> listOBK = mapOrderBikeKPIByContact.get(e.Employee__c);
                for(Order_Bike_KPI__c obk : listOBK )
                {
                    if(obk.Opportunity__r.Is_Used_Bike__c)
                    {                        
                        usedBike += obk.Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(obk.Opportunity__c,obk.Opportunity__r.Order__c,null,'Used Bike',obk.Amount__c,e.Id,obk.Opportunity__r.Owner.Name));
                    }
                    else if(obk.Opportunity__r.Order_WebCommercal__c != null)
                    {         
                        eCommerce += obk.Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(obk.Opportunity__c,obk.Opportunity__r.Order__c,null,'E-Commerce',obk.Amount__c,e.Id,obk.Opportunity__r.Owner.Name));
                    }
                    else if(obk.Opportunity__r.Quote_Changed__c)
                    {        
                        promoOut += obk.Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(obk.Opportunity__c,obk.Opportunity__r.Order__c,null,'Promotion Out',obk.Amount__c,e.Id,obk.Opportunity__r.Owner.Name));                      
                    }
                    else
                    {          
                        promoIn += obk.Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(obk.Opportunity__c,obk.Opportunity__r.Order__c,null,'Promotion In',obk.Amount__c,e.Id,obk.Opportunity__r.Owner.Name));     

                    }
                }
            }
            
            for(Order o : listCurrentOrder)
            {
                if(o.Status == 'Completed')
                {
                    saleVolume++;
                    listMKPIDetail.add(createEmployeeRuleDetail(o.Id,'1',null,e.Id,'Order','Order',o.Opportunity.Owner.Name));
                    
                    /*if(o.Total_Survey_Sales__c != 0 || o.Total_Survey_Service__c != 0 || o.Total_Survey_PCA__c != 0)
                    {
                        currentTSI += o.TSI__c;
                        totalOrderSurvey++;
                        listMKPIDetail.add(createEmployeeRuleDetail(o.Id,'6',o.TSI__c,e.Id,'Order','TSI',o.Opportunity.Owner.Name));
                    } */
                                      
                    // 20/5/2022 // chạy cho opty không có team
                    if(!mapOrderBikeKPIByOppty.containsKey(o.OpportunityId))
                    {
                        if(o.Opportunity.Is_Used_Bike__c)
                        {                        
                            usedBike += o.Amount__c;
                            listMKPIDetail.add(createEmployeeCommissionDetail(o.OpportunityId,o.Id,null,'Used Bike',o.Amount__c,e.Id,o.Opportunity.Owner.Name));
                        }
                        else if(o.Opportunity.Order_WebCommercal__c != null)
                        {         
                            eCommerce += o.Amount__c;
                            listMKPIDetail.add(createEmployeeCommissionDetail(o.OpportunityId,o.Id,null,'E-Commerce',o.Amount__c,e.Id,o.Opportunity.Owner.Name));
                        }
                        else if(o.Opportunity.Quote_Changed__c)
                        {        
                            promoOut += o.Amount__c;
                            listMKPIDetail.add(createEmployeeCommissionDetail(o.OpportunityId,o.Id,null,'Promotion Out',o.Amount__c,e.Id,o.Opportunity.Owner.Name));                      
                        }
                        else
                        {          
                            promoIn += o.Amount__c;
                            listMKPIDetail.add(createEmployeeCommissionDetail(o.OpportunityId,o.Id,null,'Promotion In',o.Amount__c,e.Id,o.Opportunity.Owner.Name));
                        }
                    }           
                }                           
            }
            
            
            if(mapMTask.containsKey(e.Employee__c))
            {
                List<Monthly_Task__c> currentListMTask = mapMTask.get(e.Employee__c); 
                for(Monthly_Task__c mT : currentListMTask)
                {
                    if(mT.RecordTypeId == RecordTypeHelper.MONTHLY_CONTENT_CREATION && mT.Is_Confirm__c == true)
                    {
                        totalContent+= 1;                       
                        listMKPIDetail.add(createEmployeeRuleDetail(mT.Id,'5',null,e.Id,'Monthly Task','Coontent Creation',null));
                    }
                }
            }           
            
            for(Opportunity opty : listCurrentOpty)
            {
                Monthly_KPI_Employee_Detail__c eDetail = new Monthly_KPI_Employee_Detail__c();
                listMKPIDetail.add(createEmployeeRuleDetail(opty.Id,'2',null,e.Id,'Opportunity','Opportunity',null)); 
            }
            
            for(Opportunity opty : listCurrentCSOpty)
            {
                quantityOpty++;     
                listMKPIDetail.add(createEmployeeRuleDetail(opty.Id, '3',null,e.Id,'Opportunity','Opportunity Wrong Infomation',null));
            }
            
            avarageTSI = SurveyCalculateHelper.calculatePoint(listCurrentOrder,e.KPI_Rule_6_Target__c,e,listMKPIDetail,'6');

            
            if(listCurrentFollowFail != null)
            {
                totalFollowFail =  listCurrentFollowFail.size();
                for(Follow_Fail__c f : listCurrentFollowFail)
                {
                    listMKPIDetail.add(createEmployeeRuleDetail(f.Id, '7',null,e.Id,'Follow Fail','Follow Fail',null));
                }
                
            }
            
            e.Team__c = 'Sales';
            e.Promo_In__c = promoIn * e.Promo_In_Rate__c / 100; // 0.65
            e.Promo_Out__c = promoOut * e.Promo_Out_Rate__c / 100; // 0.45
            e.E_Commerce__c = eCommerce * e.E_Commerce_Rate__c / 100 ; // 0.25
            e.Used_Bike__c = usedBike * e.Used_Bike_Rate__c / 100; // 20
                        
            
            e.KPI_Rule_1_Value__c = saleVolume;
            e.KPI_Rule_2_Value__c = numberEnquiries;
            e.KPI_Rule_3_Value__c = quantityOpty;
            e.KPI_Rule_4_Value__c = totalTestRide;
            e.KPI_Rule_5_Value__c = totalContent;
            e.KPI_Rule_6_Value__c = avarageTSI;
            e.KPI_Rule_7_Value__c = totalFollowFail;
            
            calSalesConsultant(e);
        }
        
        for(Monthly_KPI_Employee__c e : listSalesSupevisor)
        {
            //Sales team volume
            //Training section
            //Event
            //Showroom monitoring
            //Team TSI
			//Team content creation
			List<Order> listCurrentOrder = new List<Order>();
            List<Opportunity> listCurrentOpty = new List<Opportunity>();            
            if(mapOrderSale.containsKey(e.Employee__c))
            {
                listCurrentOrder = mapOrderSale.get(e.Employee__c);
            }
            if(mapOpty.containsKey(e.Employee__c))
            {
                listCurrentOpty = mapOpty.get(e.Employee__c);
            }
                        
            Decimal totalOrderSurvey = 0;
			Decimal teamVolume = 0;
            Decimal totalTraining = 0;
            Decimal totalEvent = 0;
            Decimal totalShowRoom = 0;
            Decimal totalContent = 0;
            Decimal selfTSI = 0;
            Decimal selfAvarageTSI = 0;
            Decimal teamTSI = 0;
            Decimal avarageTSI = 0;
            Decimal countChild = 0;
            
            Decimal teamTotalOpty = 0;
            Decimal teamTotalOptyConvert = 0;
            Decimal teamConvertRate = 0;
            Decimal convertRate = 0;
            
            Decimal promoIn = 0;
            Decimal PromoOut = 0;
            Decimal eCommerce = 0;
            Decimal usedBike = 0;
            
            if(mapMTask.containsKey(e.Employee__c))
            {     
                List<Monthly_Task__c> currentListMTask = mapMTask.get(e.Employee__c);
                for(Monthly_Task__c mT : currentListMTask)
                {
                    if(mT.RecordTypeId == RecordTypeHelper.MONTHLY_TRAINING && mT.Is_Confirm__c == true)
                    {
                        totalTraining += 1;
                        listMKPIDetail.add(createEmployeeRuleDetail(mT.Id, '2',null ,e.Id,'Monthly Task','Tranning',null));
                    }
                    if(mT.RecordTypeId == RecordTypeHelper.MONTHLY_EVENT && mT.Is_Confirm__c == true)
                    {
                        totalEvent += 1;
                        listMKPIDetail.add(createEmployeeRuleDetail(mT.Id, '3',null ,e.Id,'Monthly Task','Event',null));
                    }
                    if(mT.RecordTypeId == RecordTypeHelper.MONTHLY_SHOWROOM && mT.Is_Confirm__c == true)
                    {
                        totalShowRoom += 1;
                        listMKPIDetail.add(createEmployeeRuleDetail(mT.Id, '4',null ,e.Id,'Monthly Task','Show Room',null));
                    }
                    if(mT.RecordTypeId == RecordTypeHelper.MONTHLY_CONTENT_CREATION && mT.Is_Confirm__c == true)
                    {
                        totalContent += 1;
                        listMKPIDetail.add(createEmployeeRuleDetail(mT.Id, '6',null ,e.Id,'Monthly Task','Content Creation',null));
                    }
                }
            }
            
            // 20/5/2022 // chạy cho opty có team
            if(mapOrderBikeKPIByContact.containsKey(e.Employee__c))
            {
                List<Order_Bike_KPI__c> listOBK = mapOrderBikeKPIByContact.get(e.Employee__c);
                for(Order_Bike_KPI__c obk : listOBK )
                {
                    if(obk.Opportunity__r.Is_Used_Bike__c)
                    {                        
                        usedBike += obk.Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(obk.Opportunity__c,obk.Opportunity__r.Order__c,null,'Used Bike',obk.Amount__c,e.Id,obk.Opportunity__r.Owner.Name));
                    }
                    else if(obk.Opportunity__r.Order_WebCommercal__c != null)
                    {         
                        eCommerce += obk.Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(obk.Opportunity__c,obk.Opportunity__r.Order__c,null,'E-Commerce',obk.Amount__c,e.Id,obk.Opportunity__r.Owner.Name));
                    }
                    else if(obk.Opportunity__r.Quote_Changed__c)
                    {        
                        promoOut += obk.Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(obk.Opportunity__c,obk.Opportunity__r.Order__c,null,'Promotion Out',obk.Amount__c,e.Id,obk.Opportunity__r.Owner.Name));                      
                    }
                    else
                    {          
                        promoIn += obk.Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(obk.Opportunity__c,obk.Opportunity__r.Order__c,null,'Promotion In',obk.Amount__c,e.Id,obk.Opportunity__r.Owner.Name));     

                    }
                }
            }
            
            
            for(Opportunity opty : listCurrentOpty)
            {
                if(opty.Order__r.Invoice_Date__c != null && opty.Order__r.Status == 'Completed')
                {
                    teamTotalOptyConvert+= 1;
                    listMKPIDetail.add(createEmployeeRuleDetail(opty.Id, '7',null ,e.Id,'Opportunity','Opportunity Converted',null));                   
                }
            }
            teamTotalOpty += listCurrentOpty.size();
            
            for(Order o : listCurrentOrder)
            {
                if(o.Status == 'Completed')
                {
                    teamVolume++;
                    listMKPIDetail.add(createEmployeeRuleDetail(o.Id, '1',null ,e.Id,'Order','Order',o.Opportunity.Owner.Name));
                    
                    /*if(o.Total_Survey_Sales__c != 0 || o.Total_Survey_Service__c != 0 || o.Total_Survey_PCA__c != 0)
                    {
                        selfTSI += o.TSI__c;              
                        totalOrderSurvey++;
                        listMKPIDetail.add(createEmployeeRuleDetail(o.Id, '5',o.TSI__c,e.Id,'Order','TSI',o.Opportunity.Owner.Name));
                    }*/
                    
                    // 20/5/2022 // chạy cho opty không có team
                    if(!mapOrderBikeKPIByOppty.containsKey(o.OpportunityId))
                    {
                        if(o.Opportunity.Is_Used_Bike__c)
                        {                        
                            usedBike += o.Amount__c;
                            listMKPIDetail.add(createEmployeeCommissionDetail(o.OpportunityId,o.Id,null,'Used Bike',o.Amount__c,e.Id,o.Opportunity.Owner.Name));
                        }
                        else if(o.Opportunity.Order_WebCommercal__c != null)
                        {         
                            eCommerce += o.Amount__c;
                            listMKPIDetail.add(createEmployeeCommissionDetail(o.OpportunityId,o.Id,null,'E-Commerce',o.Amount__c,e.Id,o.Opportunity.Owner.Name));
                        }
                        else if(o.Opportunity.Quote_Changed__c)
                        {        
                            promoOut += o.Amount__c;
                            listMKPIDetail.add(createEmployeeCommissionDetail(o.OpportunityId,o.Id,null,'Promotion Out',o.Amount__c,e.Id,o.Opportunity.Owner.Name));                      
                        }
                        else
                        {          
                            promoIn += o.Amount__c;
                            listMKPIDetail.add(createEmployeeCommissionDetail(o.OpportunityId,o.Id,null,'Promotion In',o.Amount__c,e.Id,o.Opportunity.Owner.Name));
                        }
                    } 
                }                          
            }           
            
            List<Order> listTeamOrder = new List<Order>();
            listTeamOrder.addAll(listCurrentOrder);
            
            //Decimal teamOrderTSI = 0;
            Decimal teamOrderCount = 0;
            List<Monthly_KPI_Employee__c> listChild = new List<Monthly_KPI_Employee__c>();
            if(mapSalesConsultant.containsKey(e.Id))
            {
                listChild = mapSalesConsultant.get(e.Id); 
                countChild = listChild.size();
                for(Monthly_KPI_Employee__c child : listChild)
                {
                    teamVolume += child.KPI_Rule_1_Value__c;
                    //teamTSI += child.KPI_Rule_6_Value__c;
                    totalContent += child.KPI_Rule_5_Value__c;
                    
                    if(mapOrderSale.containsKey(child.Employee__c))
                    {
                        List<Order> listChildOrder = mapOrderSale.get(child.Employee__c);
                        listTeamOrder.addAll(listChildOrder);
                        /*for(Order childO : listChildOrder)
                        {
                            if(childO.Status == 'Completed')
                            {
                                teamOrderTSI += childO.TSI__c;
                                teamOrderCount++;
                                listMKPIDetail.add(createEmployeeRuleDetail(childO.Id, '1',null ,e.Id,'Order','Order',childO.Opportunity.Owner.Name));
                                if(childO.Total_Survey_Sales__c != 0 || childO.Total_Survey_Service__c != 0 || childO.Total_Survey_PCA__c != 0)
                                {
                                    listMKPIDetail.add(createEmployeeRuleDetail(childO.Id, '5',childO.TSI__c ,e.Id,'Order','TSI',childO.Opportunity.Owner.Name));
                                }
                            }                          
                        }*/
                    }
                    
                    if(mapOpty.containsKey(child.Employee__c))
                    {
                        List<Opportunity> listChildOpty = mapOpty.get(child.Employee__c);
                        teamTotalOpty += listChildOpty.size();
                        for(Opportunity childO : listChildOpty)
                        {
                            if(childO.Order__r.Invoice_Date__c != null)
                            {
                                teamTotalOptyConvert+= 1;
                                listMKPIDetail.add(createEmployeeRuleDetail(childO.Id, '7',null ,e.Id,'Opportunity','Opportunity Converted',null));
                                
                            }
                        }
                    }           
                }
            }
            
            //system.debug('Sales Super');
            avarageTSI = SurveyCalculateHelper.calculatePoint(listTeamOrder,e.KPI_Rule_5_Target__c,e,listMKPIDetail,'5');    
            //system.debug('END Sales Super');
            
            //avarageTSI = (teamTSI + selfAvarageTSI) / (listChild.size() + 1);
            //avarageTSI = (selfTSI + teamOrderTSI) / (totalOrderSurvey + teamOrderCount); // 23/8/2022
            if(teamTotalOptyConvert > 0 && teamTotalOpty > 0)
            {
                listMKPIDetail.add(createEmployeeRuleDetail(null, '7',teamTotalOpty ,e.Id,'','Total Opportunity Team',null));
                listMKPIDetail.add(createEmployeeRuleDetail(null, '7',teamTotalOptyConvert ,e.Id,'','Total Converted Opportunity Team',null));
                
                convertRate = (teamTotalOptyConvert / teamTotalOpty) * 100;
            }
            
            e.Team__c = 'Sales';
            e.Promo_In__c = promoIn * e.Promo_In_Rate__c / 100; // 0.65
            e.Promo_Out__c = promoOut * e.Promo_Out_Rate__c / 100; // 0.45
            e.E_Commerce__c = eCommerce * e.E_Commerce_Rate__c / 100; // 0.25
            e.Used_Bike__c = usedBike * e.Used_Bike_Rate__c / 100; // 20
            
            
            e.KPI_Rule_1_Value__c = teamVolume;
            e.KPI_Rule_2_Value__c = totalTraining;
            e.KPI_Rule_3_Value__c = totalEvent;
            e.KPI_Rule_4_Value__c = totalShowRoom;
            e.KPI_Rule_5_Value__c = avarageTSI;
            e.KPI_Rule_6_Value__c = totalContent;
            e.KPI_Rule_7_Value__c = convertRate;
            
            calSalesSuper(e);
        }
        
        for(Monthly_KPI_Employee__c e : listSalesAM)
        {
            List<Order> listCurrentOrder = new List<Order>();
            List<Opportunity> listCurrentOpty = new List<Opportunity>();
            /*if(mapOrderSale.containsKey(e.Employee__c))
            {
                listCurrentOrder = mapOrderSale.get(e.Employee__c);
            }
            if(mapOpty.containsKey(e.Employee__c))
            {
                listCurrentOpty = mapOpty.get(e.Employee__c);
            }*/
            
            Decimal saleVolume = 0;
            Decimal saleRevenue = 0;
            Decimal totalTraining = 0;
            Decimal totalOpty = listCurrentOpty.size();
            //Decimal selfTSI = 0;
            //Decimal selfAvarageTSI = 0;
            //Decimal teamTSI = 0;
            Decimal countSuper = 0;
            Decimal avarageTSI = 0;
            Decimal teamContent = 0;
            
            Decimal promoIn = 0;
            Decimal PromoOut = 0;
            Decimal eCommerce = 0;
            Decimal usedBike = 0;
            
            if(mapMTask.containsKey(e.Employee__c))
            {
                List<Monthly_Task__c> currentListMTask = mapMTask.get(e.Employee__c);
                for(Monthly_Task__c mT : currentListMTask)
                {
                    if(mT.RecordTypeId == RecordTypeHelper.MONTHLY_TRAINING && mT.Is_Confirm__c == true)
                    {
                        totalTraining += 1;
                        listMKPIDetail.add(createEmployeeRuleDetail(mt.Id, '3',null,e.Id,'Monthly Task','Training',null));
                    }
                    if(mT.RecordTypeId == RecordTypeHelper.MONTHLY_CONTENT_CREATION && mT.Is_Confirm__c == true)
                    {
                        teamContent += 1;
                        listMKPIDetail.add(createEmployeeRuleDetail(mt.Id, '6',null,e.Id,'Monthly Task','Content Creation',null));
                    }
                }
            }
            
            // 20/5/2022 // chạy cho opty có team
            if(mapOrderBikeKPIByContact.containsKey(e.Employee__c))
            {
                List<Order_Bike_KPI__c> listOBK = mapOrderBikeKPIByContact.get(e.Employee__c);
                for(Order_Bike_KPI__c obk : listOBK )
                {
                    if(obk.Opportunity__r.Is_Used_Bike__c)
                    {                        
                        usedBike += obk.Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(obk.Opportunity__c,obk.Opportunity__r.Order__c,null,'Used Bike',obk.Amount__c,e.Id,obk.Opportunity__r.Owner.Name));
                    }
                    else if(obk.Opportunity__r.Order__r.Order_Source__c == 'E-Commerce')
                    {         
                        eCommerce += obk.Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(obk.Opportunity__c,obk.Opportunity__r.Order__c,null,'E-Commerce',obk.Amount__c,e.Id,obk.Opportunity__r.Owner.Name));
                    }
                    else if(obk.Opportunity__r.Quote_Changed__c)
                    {        
                        promoOut += obk.Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(obk.Opportunity__c,obk.Opportunity__r.Order__c,null,'Promotion Out',obk.Amount__c,e.Id,obk.Opportunity__r.Owner.Name));                      
                    }
                    else
                    {          
                        promoIn += obk.Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(obk.Opportunity__c,obk.Opportunity__r.Order__c,null,'Promotion In',obk.Amount__c,e.Id,obk.Opportunity__r.Owner.Name));     

                    }
                }
            }
            
            List<Order> listTeamOrder = new List<Order>();
            for(Monthly_KPI_Employee__c child : listSalesChildForAM)
            {
                // mapOrder
                // mapOpty
                // mapMTask
                /*if(child.KPI_Category_Management__r.Role__c == 'Sales Supevisor')
                {
                    teamTSI += child.KPI_Rule_5_Value__c;
                    countSuper++;
                    //teamContent += child.KPI_Rule_6_Value__c;
                }*/
                
                
                List<Order> listChildOrder = new List<Order>();
                if(mapOrderSale.containsKey(child.Employee__c))
                {
                    listChildOrder = mapOrderSale.get(child.Employee__c);
                    listTeamOrder.addAll(listChildOrder);
                    for(Order o : listChildOrder)
                    {
                        if(o.Status == 'Completed')
                        {
                            saleVolume++;
                            listMKPIDetail.add(createEmployeeRuleDetail(o.Id, '1',null,e.Id,'Order','Order',o.Opportunity.Owner.Name));
                            
                            saleRevenue += o.Amount__c;    
                            listMKPIDetail.add(createEmployeeRuleDetail(o.Id, '2',o.Amount__c,e.Id,'Order','Order Revenue',null));
                            /*if(o.Total_Survey_Sales__c != 0 || o.Total_Survey_Service__c != 0 || o.Total_Survey_PCA__c != 0)
                            {
                                listMKPIDetail.add(createEmployeeRuleDetail(o.Id, '5',o.TSI__c,e.Id,'Order','TSI',o.Opportunity.Owner.Name));
                            }*/
                            
                            // 20/5/2022 // chạy cho opty không có team
                            if(!mapOrderBikeKPIByOppty.containsKey(o.OpportunityId))
                            {
                                if(o.Opportunity.Is_Used_Bike__c)
                                {                        
                                    usedBike += o.Amount__c;
                                    listMKPIDetail.add(createEmployeeCommissionDetail(o.OpportunityId,o.Id,null,'Used Bike',o.Amount__c,e.Id,o.Opportunity.Owner.Name));
                                }
                                else if(o.Order_Source__c == 'E-Commerce')
                                {         
                                    eCommerce += o.Amount__c;
                                    listMKPIDetail.add(createEmployeeCommissionDetail(o.OpportunityId,o.Id,null,'E-Commerce',o.Amount__c,e.Id,o.Opportunity.Owner.Name));
                                }
                                else if(o.Opportunity.Quote_Changed__c)
                                {        
                                    promoOut += o.Amount__c;
                                    listMKPIDetail.add(createEmployeeCommissionDetail(o.OpportunityId,o.Id,null,'Promotion Out',o.Amount__c,e.Id,o.Opportunity.Owner.Name));                      
                                }
                                else
                                {          
                                    promoIn += o.Amount__c;
                                    listMKPIDetail.add(createEmployeeCommissionDetail(o.OpportunityId,o.Id,null,'Promotion In',o.Amount__c,e.Id,o.Opportunity.Owner.Name));
                                }
                            } 
                        }        
                    }
                }
                List<Opportunity> listChildOpty = new List<Opportunity>();
                if(mapOpty.containsKey(child.Employee__c))
                {
                    listChildOpty = mapOpty.get(child.Employee__c);
                    for(Opportunity o : listChildOpty)
                    {
                        totalOpty++;
                        listMKPIDetail.add(createEmployeeRuleDetail(o.Id, '4',null,e.Id,'Opportunity','Opportunity',null));
                        /*if(o.Order__r.Invoice_Date__c != null)
                        {
                            if(o.Is_Used_Bike__c)
                            {
                                usedBike += o.Order__r.Amount__c;
                                listMKPIDetail.add(createEmployeeCommissionDetail(o.Id,o.Order__c,null,'Used Bike',o.Order__r.Amount__c,e.Id));
                            }
                            else if(o.Order__r.Order_Source__c == 'E-Commerce')
                            {
                                eCommerce += o.Order__r.Amount__c;
                                listMKPIDetail.add(createEmployeeCommissionDetail(o.Id,o.Order__c,null,'E-Commerce',o.Order__r.Amount__c,e.Id));
                            }
                            else if(o.Quote_Changed__c)
                            {                               
                                promoOut += o.Order__r.Amount__c;
                                listMKPIDetail.add(createEmployeeCommissionDetail(o.Id,o.Order__c,null,'Promotion Out',o.Order__r.Amount__c,e.Id));
                            }
                            else
                            {
                                promoIn += o.Order__r.Amount__c;
                                listMKPIDetail.add(createEmployeeCommissionDetail(o.Id,o.Order__c,null,'Promotion In',o.Order__r.Amount__c,e.Id));
                            }  
                        }*/
                    }
                }
                List<Monthly_Task__c> listChildMTask = new List<Monthly_Task__c>();
                if(mapMTask.containsKey(child.Employee__c))
                {
                    listChildMTask = mapMTask.get(child.Employee__c);
                    for(Monthly_Task__c mTask : listChildMTask)
                    {
                        if( mTask.RecordTypeId == RecordTypeHelper.MONTHLY_CONTENT_CREATION && mTask.Is_Confirm__c == true)
                        {
                            teamContent += 1;
                            listMKPIDetail.add(createEmployeeRuleDetail(mTask.Id, '6',0,e.Id,'Monthly Task','Content Creation',null));
                        }                        
                    }
                }
            }
            
            avarageTSI = SurveyCalculateHelper.calculatePoint(listTeamOrder,e.KPI_Rule_5_Target__c,e,listMKPIDetail,'5');  
            
            /*if(countSuper > 0)
            {
                avarageTSI =  teamTSI / (countSuper) ;   
            }
            else
            {
                avarageTSI = e.KPI_Rule_5_Target__c;
            }*/
                       
            //system.debug('Promo Out '+promoOut);
            //system.debug(e.Promo_Out__c);
            
            e.Team__c = 'Sales';
            e.Promo_In__c = promoIn *  e.Promo_In_Rate__c / 100; // 0.125
            e.Promo_Out__c = promoOut * e.Promo_Out_Rate__c / 100; // 0.125
            e.E_Commerce__c = eCommerce * e.E_Commerce_Rate__c / 100; // 0.125
            e.Used_Bike__c = usedBike * e.Used_Bike_Rate__c / 100; // 5
            
            e.KPI_Rule_1_Value__c = saleVolume;
            e.KPI_Rule_2_Value__c = saleRevenue;
            e.KPI_Rule_3_Value__c = totalTraining;
            e.KPI_Rule_4_Value__c = totalOpty;
            e.KPI_Rule_5_Value__c = avarageTSI;
            e.KPI_Rule_6_Value__c = teamContent;
            
            calSaleAM(e);
        }
        
        Decimal serviceConsultantFollowFail = 0;
        Decimal serviceConsultantContentCreation = 0;
        List<Monthly_Task__c> listServiceContentCreation = new List<Monthly_Task__c>();
        List<Follow_Fail__c> listServiceFollowFail = new List<Follow_Fail__c>();
        for(Monthly_KPI_Employee__c e : listServiceConsultant)
        {
            if(mapMTask.containsKey(e.Employee__c))
            {
                List<Monthly_Task__c> currentListMTask = mapMTask.get(e.Employee__c); 
                for(Monthly_Task__c mT : currentListMTask)
                {
                    if(mT.RecordTypeId == RecordTypeHelper.MONTHLY_CONTENT_CREATION && mT.Is_Confirm__c == true)
                    {
                        serviceConsultantContentCreation++;         
                        listServiceContentCreation.add(mT);
                        //listMKPIDetail.add(createEmployeeRuleDetail(mT.Id,'7',null,e.Id,'Monthly Task'));
                    }
                }
            } 
            
            if(mapFail.containsKey(e.Employee__c))
            {
                List<Follow_Fail__c> listCurrentFollow = mapFail.get(e.Employee__c);
                serviceConsultantFollowFail += listCurrentFollow.size();
                for(Follow_Fail__c f : listCurrentFollow)
                {
                    listServiceFollowFail.add(f);
                    //listMKPIDetail.add(createEmployeeRuleDetail(f.Id,'3',null,e.Id,'Follow Fail'));
                }               
            }         
        }
        
        
        
        for(Monthly_KPI_Employee__c e : listServiceConsultant)
        {
            // Monthly revenue : PCA target ,  Service revenue
            // Service Dept. TSI : order tsi
            // Customer following up : ??? 
			// Service efficiency : Sold Hours/ Worked Hours 
			// Service productivity Worked Hours/ On-duty 
			// Customer retention rate ???
			// Content creation : monthly task

            //system.debug(e.Employee_Name__c);
            
            Decimal totalOrderSurvey = 0;
            //Decimal selfTSI = 0;
            //Decimal selfAvarageTSI = 0;
            Decimal pcaRevenue = 0;
            Decimal serviceRevenue = 0;
            Decimal soldHour = 0;
            Decimal workedHour = 0;
            Decimal onDutyHour = 0;
            Decimal currentRetentionRate = 0; // o	Customer retention rate (90days) = ((CE -CN)/CS) *100 // CE: number of customers in the end of period // number of new customer acquired during period  // number customer of start of period  
            Decimal contantCreation = 0;
            
            Decimal soldHourRevenue = 0;
            Decimal partRevenue = 0;
            Decimal AARevenue = 0;
            //Decimal voucher = 0;
            Decimal voucherPartPCA = 0;
            Decimal voucherAAPCA = 0;
            Decimal discount = 0;
            Decimal discountPartPCA = 0;
            Decimal discountAAPCA = 0;
            
            //List<Order> listCurrentOrder = new List<Order>();
            List<OrderItem> listCurrentOrderItem = new List<OrderItem>();
            List<Follow_Fail__c> listCurrentFollow = new List<Follow_Fail__c>();
                     
            for(Order o : listOrdersService)
            {
                if(o.Status == 'Completed')
                {
                    /*if(o.Total_Survey_Sales__c != 0 || o.Total_Survey_Service__c != 0 || o.Total_Survey_PCA__c != 0)
                    {
                        totalOrderSurvey++;
                        selfTSI += o.TSI__c;
                        listMKPIDetail.add(createEmployeeRuleDetail(o.Id, '2',o.TSI__c,e.Id,'Order','TSI',null));
                    }*/
                    
                    //system.debug('O Service Hour '+ o.Service_Hours__c);
                    
                    /*if(o.Service_Hours__c > 0 && o.Mechanic__c != null)
                    {
                        workedHour += o.Service_Hours__c ;
                        listMKPIDetail.add(createEmployeeRuleDetail(o.Id,'4',o.Service_Hours__c,e.Id,'Order','Worked Hour'));
                        listMKPIDetail.add(createEmployeeRuleDetail(o.Id,'5',o.Service_Hours__c,e.Id,'Order','Worked Hour'));
                    }
                   
                    if(o.Detailing_Hours__c > 0 && o.Detailing_Staff__c != null)
                    {
                        workedHour += o.Detailing_Hours__c ;
                        listMKPIDetail.add(createEmployeeRuleDetail(o.Id,'4',o.Detailing_Hours__c,e.Id,'Order','Worked Hour'));
                        listMKPIDetail.add(createEmployeeRuleDetail(o.Id,'5',o.Detailing_Hours__c,e.Id,'Order','Worked Hour')); 
                    }    */              
                } 
                
                // voucher for order PCA
                if(mapPaymentVoucher.containsKey(o.Id))
                {
                    List<Payment__c> listCurrentVoucher = mapPaymentVoucher.get(o.Id);
                    for(Payment__c p : listCurrentVoucher)
                    {
                        if(p.Payment_For__c == 'Phụ tùng-phụ kiện-quần áo/PCA')
                        {
                            voucherPartPCA -= p.Amount__c;
                            listMKPIDetail.add(createEmployeeCommissionDetail(null,o.Id,null,'Voucher',p.Amount__c * -1,e.Id,null));   
                        }                           
                    }
                } 
            }   

			List<String> listOrderAlreadyCount = new List<String>();     
            for(OrderItem item : listOrderItemService)
            {
                if(!listOrderAlreadyCount.contains(item.OrderId))
                {
                    if(item.Order.Service_Hours__c > 0 && item.Order.Mechanic__c != null)
                    {
                        workedHour += item.Order.Service_Hours__c;
                        listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'4',item.Order.Service_Hours__c,e.Id,'Order','Worked Hour',null));
                        listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'5',item.Order.Service_Hours__c,e.Id,'Order','Worked Hour',null));
                    }
                    
                    if(item.Order.Detailing_Hours__c > 0 && item.Order.Detailing_Hours__c != null)
                    {
                        workedHour += item.Order.Detailing_Hours__c;
                        listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'4',item.Order.Detailing_Hours__c,e.Id,'Order','Worked Hour',null));
                        listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'5',item.Order.Detailing_Hours__c,e.Id,'Order','Worked Hour',null)); 
                    }                 
                    
                    listOrderAlreadyCount.add(item.OrderId);
                }              
            }
            
            for(OrderItem item : listOrderItemPCA)
            {
                pcaRevenue += item.KPI_Amount__c;
                listMKPIDetail.add(createEmployeeRuleDetail(item.Id,'1',item.KPI_Amount__c,e.Id,'Order Product','PCA Revenue',null));
            }  
             
            listCurrentOrderItem = listOrderItemPCAFromServiceOrder;
            for(OrderItem item : listCurrentOrderItem)
            {
                if(item.Product2.RecordTypeId == RecordTypeHelper.PRODUCT_PCA)
                {
                    /*pcaRevenue += item.TotalPrice;
                    listMKPIDetail.add(createEmployeeRuleDetail(item.Id, '1',item.Amount__c,e.Id,'Order Product','PCA Revenue'));   */     
                    
                    if(item.Product2.Family == 'Part' )
                    {
                        partRevenue += item.KPI_Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Part Revenue',item.KPI_Amount__c,e.Id,null));
                        
                        discountPartPCA -= item.KPI_Amount__c - item.TotalPrice ;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                    }
                    else if(item.Product2.Family == 'ACC' )
                    {
                        AARevenue += item.KPI_Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'A&A Revenue',item.KPI_Amount__c,e.Id,null));
                        
                        discountAAPCA -= item.KPI_Amount__c - item.TotalPrice ;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                    }              
                }        
            }
            
            for(OrderItem item : listOrderItemService)
            {
                if(item.Labour_Hours__c != null)
                {
                    soldHour += item.Labour_Hours__c;
                    listMKPIDetail.add(createEmployeeRuleDetail(item.Id,'4',item.Labour_Hours__c,e.Id,'Order Product','Hour Sold',null));
                }
                
                serviceRevenue += item.KPI_Amount__c;
                listMKPIDetail.add(createEmployeeRuleDetail(item.Id, '1B',item.KPI_Amount__c,e.Id,'Order Product','Service Revenue',null));
                
                soldHourRevenue += item.KPI_Amount__c;
                listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Hour Sold Revenue',item.KPI_Amount__c,e.Id,null));
                
                discount -= item.KPI_Amount__c - item.TotalPrice ;
                listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                
            }
            

            for(Monthly_Task__c mT : listServiceContentCreation)
            {
                if(mT.RecordTypeId == RecordTypeHelper.MONTHLY_CONTENT_CREATION && mT.Is_Confirm__c == true)
                {        
                    //listServiceContentCreation.add(mT);
                    listMKPIDetail.add(createEmployeeRuleDetail(mT.Id,'7',null,e.Id,'Monthly Task','Content Creation',null));
                }
            }
            
            for(Follow_Fail__c f : listServiceFollowFail)
            {
                listMKPIDetail.add(createEmployeeRuleDetail(f.Id,'3',null,e.Id,'Follow Fail','Follow Fail',null));
            }               
            
            /*List<Roster_Management__c> listCurrentRoster = new List<Roster_Management__c>();
            if(mapRoster.containsKey(e.Employee__r.Staff_Code__c))
            {               
                listCurrentRoster = mapRoster.get(e.Employee__r.Staff_Code__c);
                for(Roster_Management__c r : listCurrentRoster)
                {
                    if(r.Work_Hour__c != null)
                    {
                        onDutyHour += r.Work_Hour__c;
                        listMKPIDetail.add(createEmployeeRuleDetail(r.Id,'5',r.Work_Hour__c,e.Id,'Roster Management','On Duty Hour'));
                    }
                }
            }   */
            
            for(Roster_Management__c r : listRosterWithoutChief)
            {
                if(r.Work_Hour__c != null)
                {
                    onDutyHour += r.Work_Hour__c;
                    listMKPIDetail.add(createEmployeeRuleDetail(r.Id,'5',r.Work_Hour__c,e.Id,'Roster Management','On Duty Hour',null));
                }
            }
            
            List<Order> listOrderPSI = new List<Order>();
            listOrderPSI.addAll(listOrdersService);
            //listOrderPSI.addAll(listOrdersWarratyFreeCoupon);
            
            Decimal avarageTSI = SurveyCalculateHelper.calculatePoint(listOrderPSI,e.KPI_Rule_2_Target__c,e,listMKPIDetail,'2');  
           
            
            /*if(totalOrderSurvey > 0)
            {
                selfAvarageTSI = selfTSI / totalOrderSurvey;
            }
            else
            {
                selfAvarageTSI = e.KPI_Rule_2_Target__c;
            }*/
            
            e.KPI_Rule_1_Value__c = pcaRevenue;
            e.KPI_Rule_1_Service_Value__c = serviceRevenue;
            e.KPI_Rule_2_Value__c = avarageTSI;
            e.KPI_Rule_3_Value__c = serviceConsultantFollowFail;
            
            //system.debug('Sold Hour : '+soldHour);
            //system.debug('Worked Hour : '+workedHour);
            //system.debug('Duty Hour : '+onDutyHour);
            if(workedHour > 0)
            {
                listMKPIDetail.add(createEmployeeRuleDetail(null,'4',soldHour,e.Id,'','Total Sold Hour',null));
                listMKPIDetail.add(createEmployeeRuleDetail(null,'4',workedHour,e.Id,'','Total Worked Hour',null));
               e.KPI_Rule_4_Value__c =  soldHour / workedHour * 100; 
            }
  
            if(onDutyHour > 0)
            {
                
                listMKPIDetail.add(createEmployeeRuleDetail(null,'5',workedHour,e.Id,'','Total Worked Hour',null));
                listMKPIDetail.add(createEmployeeRuleDetail(null,'5',onDutyHour,e.Id,'','Total On Duty Hour',null));
                e.KPI_Rule_5_Value__c = workedHour / onDutyHour * 100;
            }            
            
            if(countCustomerHaveActivity == 0)
            {
                currentRetentionRate = e.KPI_Rule_6_Target__c;
                listMKPIDetail.add(createEmployeeRuleDetail(null,'6',countCustomerHaveActivity,e.Id,'','Custom Have Activity',null));
                listMKPIDetail.add(createEmployeeRuleDetail(null,'6',countCustomer,e.Id,'','Customer',null));
            }
            else
            {
                currentRetentionRate = Decimal.valueOf(countCustomerHaveActivity)  / Decimal.valueOf(countCustomer) * 100;  
                listMKPIDetail.add(createEmployeeRuleDetail(null,'6',countCustomerHaveActivity,e.Id,'','Custom Have Activity',null));
                listMKPIDetail.add(createEmployeeRuleDetail(null,'6',countCustomer,e.Id,'','Customer',null));
            }
            
            e.KPI_Rule_6_Value__c = currentRetentionRate ; // 
            e.KPI_Rule_7_Value__c = serviceConsultantContentCreation;
            
            e.Team__c = 'Services';
            e.Count_Team_Member__c = listServiceConsultant.size();
            e.Hour_Sold_Revenue__c = soldHourRevenue * (e.Service_Hour_Rate__c / listServiceConsultant.size()) / 100; // thay đổi theo số lượng service consultan // 3
            e.Part_Revenue__c = partRevenue * (e.Part_Rate__c / listServiceConsultant.size()) / 100; // 2
            e.A_A_Revenue__c = AARevenue * (e.A_A_Rate__c / listServiceConsultant.size()) / 100; // 1.5 
            e.Voucher__c = voucherPartPCA * (e.Part_Rate__c / listServiceConsultant.size()) / 100 + voucherAAPCA * (e.A_A_Rate__c / listServiceConsultant.size()) / 100;
            e.Service_Hour_Discount__c = discount / listServiceConsultant.size(); // * (e.Service_Hour_Rate__c / listServiceConsultant.size()) / 100
            e.Part_Discount__c = discountPartPCA / listServiceConsultant.size(); // * (e.Part_Rate__c / listServiceConsultant.size()) / 100
            e.A_A_Discount__c = discountAAPCA / listServiceConsultant.size(); // * (e.A_A_Rate__c / listServiceConsultant.size()) / 100
            e.Discount__c = discount * (e.Service_Hour_Rate__c / listServiceConsultant.size()) / 100 + discountPartPCA * (e.Part_Rate__c / listServiceConsultant.size()) / 100 + discountAAPCA * (e.A_A_Rate__c / listServiceConsultant.size()) / 100;
			  
            calServiceConsultant(e);
        }
        
        for(Monthly_KPI_Employee__c e : listServiceTechnician)
        {
			// Hour sold target
			// Service Efficiency
			// Service productivity
			// TSI Score
			
            // Order service có 2 nhân sự : mechanic và detailing
			// Sold hour dựa trên field labour hour và tính cho mechanic khi product : service type = Repair và tính cho detailing khi product : service type = Detailing
			// Worked Hour dựa trên service date ( mechanic ) và Detail date ( detailing )
			// On duty : Roster Management : Staff : lấy time trên shift Total_Hour__c			 
            
            Decimal totalOrderSurvey = 0;
            //Decimal selfTSI = 0;
            //Decimal selfAvarageTSI = 0;
            
            Decimal hourSoldAmount = 0 ;
            Decimal hourSold = 0; // labour hour // Labour_Hours__c
            Decimal workedHour = 0; // Working_Hours__c
            Decimal onDutyHour = 0; // Roster Management object // 
            
            Decimal discount = 0;
            
            Decimal soldRevenue = 0;
            
            List<OrderItem> listOItemMechanic;
            List<OrderItem> listOItemDetailing;
            
            List<String> listOrderAlreadyCount = new List<String>();
            List<String> listOrderAlreadyCountTSI = new List<String>();
            
            Set<Order> setCurrentOrder = new Set<Order>();
            if( e.Employee__r.Contact_Type__c == 'Mechanic' && e.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert')
            {
                for(OrderItem item : listOrderItemService)
                {
                    if(item.Product2.Service_Type__c == 'Repair' )
                    {
                        if(mapOrder.containsKey(item.OrderId))
                        {
                            setCurrentOrder.add(mapOrder.get(item.OrderId));
                        }
                        
                        if(item.Labour_Hours__c != null )
                        {
                            hourSold += item.Labour_Hours__c;
                            listMKPIDetail.add(createEmployeeRuleDetail(item.Id,'4',item.Labour_Hours__c,e.Id,'Order Product','Hour Sold',null));
                        }    
                        
                       /*if((item.Order.Total_Survey_Sales__c != 0 || item.Order.Total_Survey_Service__c != 0 || item.Order.Total_Survey_PCA__c != 0) && !listOrderAlreadyCountTSI.contains(item.OrderId))
                        {
                            selfTSI += item.Order.TSI__c;
                            totalOrderSurvey++;
                            listMKPIDetail.add(createEmployeeRuleDetail(item.Order.Id,'4', item.Order.TSI__c,e.Id,'Order','TSI',null));      
                            
                            listOrderAlreadyCountTSI.add(item.OrderId);
                        }  */
                        
                        if(item.Order.Service_Hours__c > 0 && !listOrderAlreadyCount.contains(item.OrderId))
                        {
                            workedHour += item.Order.Service_Hours__c;
                            listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'2',item.Order.Service_Hours__c,e.Id,'Order','Worked Hour',null));
                            listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'3',item.Order.Service_Hours__c,e.Id,'Order','Worked Hour',null));  
                            
                            listOrderAlreadyCount.add(item.OrderId);
                        }
                        
                        discount -= item.KPI_Amount__c - item.TotalPrice ;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                    }                 
                }
            }
            else if( e.Employee__r.Contact_Type__c == 'Detailing Staff' && e.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert')
            {
                for(OrderItem item : listOrderItemService)
                {
                    if( item.Product2.Service_Type__c == 'Detailing')
                    {
                        if(mapOrder.containsKey(item.OrderId))
                        {
                            setCurrentOrder.add(mapOrder.get(item.OrderId));
                        }
                        
                        if(item.Labour_Hours__c != null && item.Product2.Service_Type__c == 'Detailing'  )
                        {
                            hourSold += item.Labour_Hours__c;
                            listMKPIDetail.add(createEmployeeRuleDetail(item.Id,'4',item.Labour_Hours__c,e.Id,'Order Product','Hour Sold',null));
                        } 
                        
                        /*if((item.Order.Total_Survey_Sales__c != 0 || item.Order.Total_Survey_Service__c != 0 || item.Order.Total_Survey_PCA__c != 0) && !listOrderAlreadyCountTSI.contains(item.OrderId))
                        {
                            selfTSI += item.Order.TSI__c;
                            totalOrderSurvey++;
                            listMKPIDetail.add(createEmployeeRuleDetail(item.Order.Id,'4', item.Order.TSI__c,e.Id,'Order',null,null));      
                            
                            listOrderAlreadyCountTSI.add(item.OrderId);
                        }  */
                        
                        if(item.Order.Service_Hours__c > 0 && !listOrderAlreadyCount.contains(item.OrderId))
                        {
                            workedHour += item.Order.Service_Hours__c;
                            listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'2',item.Order.Service_Hours__c,e.Id,'Order','Worked Hour',null));
                            listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'3',item.Order.Service_Hours__c,e.Id,'Order','Worked Hour',null));  
                            
                            listOrderAlreadyCount.add(item.OrderId);
                        }
                        
                        discount -= item.KPI_Amount__c - item.TotalPrice ;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                    }                
                }
            }
            
            
            if(e.Employee__r.Contact_Type__c == 'Mechanic' && mapOrderItemMechanic.containsKey(e.Employee__c) && e.Employee__r.Tech_Role__c != 'Chief technician / Detailing expert')
            {
                //system.debug('In Mechanic');
                listOItemMechanic = mapOrderItemMechanic.get(e.Employee__c);
                for(OrderItem item : listOItemMechanic)
                {
                    
                    if(mapOrder.containsKey(item.OrderId))
                    {
                        setCurrentOrder.add(mapOrder.get(item.OrderId));
                    }
                    
                    hourSoldAmount += item.KPI_Amount__c;
                    //listMKPIDetail.add(createEmployeeRuleDetail(item.Id,'1',item.KPI_Amount__c,e.Id,'Order Product','Sold Hour Amount'));
                    
                    if(item.Labour_Hours__c != null)
                    {             
                        hourSold += item.Labour_Hours__c;                     
                        listMKPIDetail.add(createEmployeeRuleDetail(item.Id,'1',item.Labour_Hours__c,e.Id,'Order Product','Sold Hour',null));
                        listMKPIDetail.add(createEmployeeRuleDetail(item.Id,'2',item.Labour_Hours__c,e.Id,'Order Product','Sold Hour',null));
                    }
                    
                    if(item.KPI_Amount__c > 0)
                    {
                        soldRevenue += item.KPI_Amount__c; 
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Hour Sold Revenue',item.KPI_Amount__c,e.Id,null));
                    }
                    
                    if(item.Order.Service_Hours__c > 0 && !listOrderAlreadyCount.contains(item.OrderId))
                    {
                        workedHour += item.Order.Service_Hours__c;
                        listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'2',item.Order.Service_Hours__c,e.Id,'Order','Worked Hour',null));
                        listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'3',item.Order.Service_Hours__c,e.Id,'Order','Worked Hour',null));  
                        
                        listOrderAlreadyCount.add(item.OrderId);
                    }
                    
                    
                    /*if((item.Order.Total_Survey_Sales__c != 0 || item.Order.Total_Survey_Service__c != 0 || item.Order.Total_Survey_PCA__c != 0) && !listOrderAlreadyCountTSI.contains(item.OrderId))
                    {
                        selfTSI += item.Order.TSI__c;
                        totalOrderSurvey++;
                        listMKPIDetail.add(createEmployeeRuleDetail(item.Order.Id,'4', item.Order.TSI__c,e.Id,'Order',null,null));      
                        
                        listOrderAlreadyCountTSI.add(item.OrderId);
                    }  */
                    
                    discount -= item.KPI_Amount__c - item.TotalPrice ;
                    listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                }
            }
            else if(e.Employee__r.Contact_Type__c == 'Detailing Staff' && mapOrderItemDetailing.containsKey(e.Employee__c) && e.Employee__r.Tech_Role__c != 'Chief technician / Detailing expert')
            {             
                //system.debug('In Detailing');
                listOItemDetailing = mapOrderItemDetailing.get(e.Employee__c);
                for(OrderItem item : listOItemDetailing)
                {
                    if(mapOrder.containsKey(item.OrderId))
                    {
                        setCurrentOrder.add(mapOrder.get(item.OrderId));
                    }
                    
                    hourSoldAmount += item.KPI_Amount__c;
                    //stMKPIDetail.add(createEmployeeRuleDetail(item.Id,'1',item.KPI_Amount__c,e.Id,'Order Product','Sold Hour Amount'));
                    
                    if(item.Labour_Hours__c != null)
                    {
                        hourSold += item.Labour_Hours__c;
                        listMKPIDetail.add(createEmployeeRuleDetail(item.Id,'1',item.Labour_Hours__c,e.Id,'Order Product','Sold Hour',null));
                        listMKPIDetail.add(createEmployeeRuleDetail(item.Id,'2',item.Labour_Hours__c,e.Id,'Order Product','Sold Hour',null));
                    }
                    
					if(item.KPI_Amount__c > 0)
                    {
                        soldRevenue += item.KPI_Amount__c; 
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Hour Sold Revenue',item.KPI_Amount__c,e.Id,null));
                    }
                          
                    if(item.Order.Detailing_Hours__c > 0 && !listOrderAlreadyCount.contains(item.OrderId))
                    {
                        workedHour += item.Order.Detailing_Hours__c;
                        listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'2',item.Order.Detailing_Hours__c,e.Id,'Order','Worked Hour',null));
                        listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'3',item.Order.Detailing_Hours__c,e.Id,'Order','Worked Hour',null));
                        
                        listOrderAlreadyCount.add(item.OrderId);
                    }
                                        
                    /*if((item.Order.Total_Survey_Sales__c != 0 || item.Order.Total_Survey_Service__c != 0 || item.Order.Total_Survey_PCA__c != 0) && !listOrderAlreadyCountTSI.contains(item.OrderId))
                    {
                        selfTSI += item.Order.TSI__c;
                        totalOrderSurvey++;
                        listMKPIDetail.add(createEmployeeRuleDetail(item.Order.Id,'4',item.Order.TSI__c,e.Id,'Order','TSI',null));          
                        
                        listOrderAlreadyCountTSI.add(item.OrderId);
                    }  */
                        
                    discount -= item.KPI_Amount__c - item.TotalPrice ;
                    listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                }
            }         
            
            // Add order form set to list to calc TSI
            List<Order> listCurrentOrder = new List<Order>();
            for(Order o : setCurrentOrder)
            {
                listCurrentOrder.add(o);
            }
            
            /*for(Order o : listOrdersWarratyFreeCoupon)
            {
                if(o.)
            }*/
            
            List<Order> listOrderPSI = new List<Order>();
            listOrderPSI.addAll(listCurrentOrder);
            
            
            Decimal avarageTSI = SurveyCalculateHelper.calculatePoint(listOrderPSI,e.KPI_Rule_4_Target__c,e,listMKPIDetail,'4');  
            
            /*f(totalOrderSurvey > 0)
            {
                selfAvarageTSI = selfTSI / totalOrderSurvey ;
            }
            else
            {
                selfAvarageTSI = e.KPI_Rule_4_Target__c;
            }*/
            
            List<Roster_Management__c> listCurrentRoster = new List<Roster_Management__c>();
            if(mapRoster.containsKey(e.Employee__r.Staff_Code__c) && e.Employee__r.Tech_Role__c != 'Chief technician / Detailing expert')
            {
                listCurrentRoster = mapRoster.get(e.Employee__r.Staff_Code__c);
                for(Roster_Management__c r : listCurrentRoster)
                {
                    if(r.Work_Hour__c != null)
                    {
                        onDutyHour += r.Work_Hour__c;
                        listMKPIDetail.add(createEmployeeRuleDetail(r.Id,'3',r.Work_Hour__c,e.Id,'Roster Management','On Duty Hour',null));
                    }
                }
            }
            else if(e.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert' && e.Employee__r.Contact_Type__c == 'Mechanic')
            {
                for(Roster_Management__c r : listRoster)
                {
                    if(r.Work_Hour__c != null && r.Staff__r.Contact_Type__c == 'Mechanic')
                    {
                        onDutyHour += r.Work_Hour__c;
                        listMKPIDetail.add(createEmployeeRuleDetail(r.Id,'3',r.Work_Hour__c,e.Id,'Roster Management','On Duty Hour',null));
                    }
                }                
            }
            else if(e.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert' && e.Employee__r.Contact_Type__c == 'Detailing')
            {
                for(Roster_Management__c r : listRoster)
                {
                    if(r.Work_Hour__c != null && r.Staff__r.Contact_Type__c == 'Detailing')
                    {
                        onDutyHour += r.Work_Hour__c;
                        listMKPIDetail.add(createEmployeeRuleDetail(r.Id,'3',r.Work_Hour__c,e.Id,'Roster Management','On Duty Hour',null));
                    }
                }
            }
            
            system.debug('=====================');
            system.debug(workedHour);
            system.debug(onDutyHour);
                  
            e.KPI_Rule_1_Value__c = hourSold;
            if(workedHour > 0)
            {
                listMKPIDetail.add(createEmployeeRuleDetail(null,'2',hourSold,e.Id,'','Total Sold Hour',null));
                listMKPIDetail.add(createEmployeeRuleDetail(null,'2',workedHour,e.Id,'','Total Worked Hour',null));
                e.KPI_Rule_2_Value__c = hourSold / workedHour * 100; 
            }
            if(onDutyHour > 0)
            {
                listMKPIDetail.add(createEmployeeRuleDetail(null,'3',workedHour,e.Id,'','Total Worked Hour',null));
                listMKPIDetail.add(createEmployeeRuleDetail(null,'3',onDutyHour,e.Id,'','Total On Duty Hour',null));
                e.KPI_Rule_3_Value__c = workedHour / onDutyHour * 100; 
            }
            
            e.KPI_Rule_4_Value__c = avarageTSI;
            
            e.Team__c = 'Services';
            if(e.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert')
            {
                e.Hour_Sold_Revenue__c = soldRevenue * 0;
                e.Discount__c = discount * 0;
                e.Service_Hour_Discount__c = discount;
            }
            else if(e.Employee__r.Tech_Role__c == 'Advance technician')
            {           
                e.Hour_Sold_Revenue__c = soldRevenue * e.Service_Hour_Rate__c / 100; // 17
                e.Discount__c = discount * e.Service_Hour_Rate__c / 100;
                e.Service_Hour_Discount__c = discount;
            }
            else
            {
                e.Hour_Sold_Revenue__c = soldRevenue * e.Service_Hour_Rate__c / 100; // 12
                e.Discount__c = discount * e.Service_Hour_Rate__c / 100;        
                e.Service_Hour_Discount__c = discount;
            }
            
            
            
            calAllTech(e);        
        }
        
        for(Monthly_KPI_Employee__c e : listServiceAM)
        {
    		// Monthly revenue : PCA target , Service revenue
			// Service Dept. TSI 
			// Customer complain handling
			// Customer following up
			// Service efficiency
			// Service productivity
			// Customer retention rate
		
			//Decimal totalOrderSurvey = 0;
            Decimal totalPcaRevenue = 0;
            Decimal totalServiceRevenue = 0;
            Decimal followFail = 0;
            Decimal efficiency = 0;
            Decimal productivity = 0;
            //Decimal totalTSI = 0;
            Decimal currentRetentionRate = 0; // o	Customer retention rate (90days) = ((CE -CN)/CS) *100 // CE: number of customers in the end of period // number of new customer acquired during period  // number customer of start of period  
            Decimal contantCreation = 0;
            
            
            
            Decimal soldHour = 0;
            Decimal workedHour = 0;
            Decimal onDutyHour = 0;
            
            Decimal soldHourRevenue = 0;
            Decimal partRevenue = 0;
            Decimal AARevenue = 0;
            
            Decimal partServiceRevenue = 0;
            Decimal AAServiceRevenue = 0;
            
            Decimal discount = 0;
            Decimal voucherPartPCA = 0;
            Decimal voucherAAPCA = 0;
            Decimal discountPartPCA = 0;
            Decimal discountAAPCA = 0;
            
            //Decimal childCount = listServiceChildForAM.size();
			 
            List<Order> listCurrentOrder = listOrdersService;
            for(Order o : listCurrentOrder)
            {
                if(o.Status == 'Completed')
                {
                    /*if(o.Total_Survey_Sales__c != 0 || o.Total_Survey_Service__c != 0 || o.Total_Survey_PCA__c != 0)
                    {
                        totalOrderSurvey++;
                        totalTSI += o.TSI__c;
                        listMKPIDetail.add(createEmployeeRuleDetail(o.Id, '2',o.TSI__c,e.Id,'Order','TSI',null));
                    }*/
                    
                   /*system.debug('O Service Hour '+ o.Service_Hours__c);
                    
                    if(o.Service_Hours__c > 0 && o.Mechanic__c != null)
                    {
                        workedHour += o.Service_Hours__c ;
                        listMKPIDetail.add(createEmployeeRuleDetail(o.Id,'4',o.Service_Hours__c,e.Id,'Order','Worked Hour'));
                        listMKPIDetail.add(createEmployeeRuleDetail(o.Id,'5',o.Service_Hours__c,e.Id,'Order','Worked Hour'));
                    }
                   
                    if(o.Detailing_Hours__c > 0 && o.Detailing_Staff__c != null)
                    {
                        workedHour += o.Detailing_Hours__c ;
                        listMKPIDetail.add(createEmployeeRuleDetail(o.Id,'4',o.Detailing_Hours__c,e.Id,'Order','Worked Hour'));
                        listMKPIDetail.add(createEmployeeRuleDetail(o.Id,'5',o.Detailing_Hours__c,e.Id,'Order','Worked Hour')); 
                    }    */
                    
                    // voucher for order PCA
                    if(mapPaymentVoucher.containsKey(o.Id))
                    {
                        List<Payment__c> listCurrentVoucher = mapPaymentVoucher.get(o.Id);
                        for(Payment__c p : listCurrentVoucher)
                        {
                            if(p.Payment_For__c == 'Phụ tùng-phụ kiện-quần áo/PCA')
                            {
                                voucherPartPCA -= p.Amount__c;
                                listMKPIDetail.add(createEmployeeCommissionDetail(null,o.Id,null,'Voucher',p.Amount__c * -1,e.Id,null));   
                            }                           
                        }
                    } 
                }           
            }   
            
            List<String> listOrderAlreadyCount = new List<String>();
            for(OrderItem item : listOrderItemService)
            {
                if(!listOrderAlreadyCount.contains(item.OrderId))
                {
                    if(item.Order.Service_Hours__c > 0 && item.Order.Mechanic__c != null)
                    {
                        workedHour += item.Order.Service_Hours__c;
                        listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'4',item.Order.Service_Hours__c,e.Id,'Order','Worked Hour',null));
                        listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'5',item.Order.Service_Hours__c,e.Id,'Order','Worked Hour',null));
                    }
                    
                    if(item.Order.Detailing_Hours__c > 0 && item.Order.Detailing_Staff__c != null) 
                    {
                        workedHour += item.Order.Detailing_Hours__c;
                        listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'4',item.Order.Detailing_Hours__c,e.Id,'Order','Worked Hour',null));
                        listMKPIDetail.add(createEmployeeRuleDetail(item.OrderId,'5',item.Order.Detailing_Hours__c,e.Id,'Order','Worked Hour',null)); 
                    }                 
                    
                    listOrderAlreadyCount.add(item.OrderId);
                }              
            }
            
            for(OrderItem item : listOrderItemPCA)
            {
                totalPcaRevenue += item.KPI_Amount__c;
                listMKPIDetail.add(createEmployeeRuleDetail(item.Id,'1',item.KPI_Amount__c,e.Id,'Order Product','PCA Revenue',null));
            }  
             
            List<OrderItem> listCurrentOrderItem = listOrderItemPCAFromServiceOrder;
            for(OrderItem item : listCurrentOrderItem)
            {
                if(item.Product2.RecordTypeId == RecordTypeHelper.PRODUCT_PCA)
                {
                    /*totalPcaRevenue += item.TotalPrice;
                    listMKPIDetail.add(createEmployeeRuleDetail(item.Id, '1',item.Amount__c,e.Id,'Order Product','PCA Revenue'));   */    
                    
                    //system.debug('Item Id :' + item.Id);
                    //system.debug('PCA Type '+ item.Product2.PCA_Type__c);
                    if(item.Product2.Family == 'Part')
                    {
                        partRevenue += item.KPI_Amount__c; // ??? TotalPrice or KPI Price
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Part Revenue',item.KPI_Amount__c,e.Id,null));
                        
                        discountPartPCA -= item.KPI_Amount__c - item.TotalPrice ;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                    }
                    else if(item.Product2.Family == 'ACC')
                    {
                        AARevenue += item.KPI_Amount__c; // ??? TotalPrice or KPI Price
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'A&A Revenue',item.KPI_Amount__c,e.Id,null));
                                            
                        discountAAPCA -= item.KPI_Amount__c - item.TotalPrice ;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                    }                            
                }
                /*else if(item.Product2.RecordTypeId == RecordTypeHelper.PRODUCT_SERVICE_PACKAGE || 
                        item.Product2.RecordTypeId == RecordTypeHelper.SV_JOB)
                {                        
                    totalServiceRevenue += item.TotalPrice;
                    listMKPIDetail.add(createEmployeeRuleDetail(item.Id, '1B',item.TotalPrice,e.Id,'Order Product','Service Revenue'));
                    
                    soldHourRevenue += item.TotalPrice;
                    listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Hour Sold Revenue',item.TotalPrice,e.Id));
                }            */
                
            }
            
            for(OrderItem item : listOrderItemService)
            {
                if(item.Labour_Hours__c != null)
                {
                    soldHour += item.Labour_Hours__c;
                    listMKPIDetail.add(createEmployeeRuleDetail(item.Id,'4',item.Labour_Hours__c,e.Id,'Order Product','Hour Sold',null));
                }
                
                totalServiceRevenue += item.KPI_Amount__c;
                listMKPIDetail.add(createEmployeeRuleDetail(item.Id, '1B',item.KPI_Amount__c,e.Id,'Order Product','Service Revenue',null));
                
                soldHourRevenue += item.KPI_Amount__c;               
                listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Hour Sold Revenue',item.KPI_Amount__c,e.Id,null));
            
                discount -= item.KPI_Amount__c - item.TotalPrice ;
                listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                
            }
            
            for(Roster_Management__c r : listRosterWithoutChief)
            {
                if(r.Work_Hour__c != null)
                {
                    onDutyHour += r.Work_Hour__c;
                    listMKPIDetail.add(createEmployeeRuleDetail(r.Id,'5',r.Work_Hour__c,e.Id,'Roster Management','On Duty Hour',null));
                }
            }
            
            List<Case> listCurrentCase = new List<Case>();
            listCurrentCase = listServiceCase;
            for(Case ca : listCurrentCase)
            {
                //listMKPIDetail.add(createEmployeeRuleDetail(ca.Id,'3',ca.Handling_Time__c,e.Id,'Case','Case',null));
            }
            /*if(mapCase.containsKey(e.Employee__c))
            {
                listCurrentCase = mapCase.get(e.Employee__c);
                for(Case ca : listCurrentCase)
                {
                    listMKPIDetail.add(createEmployeeRuleDetail(ca.Id,'3',ca.Handling_Time__c,e.Id,'Case','Case',null));
                }
            }   */     
            
            e.KPI_Rule_1_Value__c = totalPcaRevenue;
            e.KPI_Rule_1_Service_Value__c = totalServiceRevenue;
            
            List<Order> listOrderPSI = new List<Order>();
            listOrderPSI.addAll(listOrdersService);
            //listOrderPSI.addAll(listOrdersWarratyFreeCoupon);
            
            Decimal avarageTSI = SurveyCalculateHelper.calculatePoint(listOrderPSI,e.KPI_Rule_2_Target__c,e,listMKPIDetail,'2'); 
            e.KPI_Rule_2_Value__c = avarageTSI;
            /*if(totalOrderSurvey > 0)
            {
                e.KPI_Rule_2_Value__c = totalTSI / totalOrderSurvey;
            }           
            else
            {
                e.KPI_Rule_2_Value__c = e.KPI_Rule_2_Target__c;
            }*/
            e.KPI_Rule_3_Value__c = listCurrentCase.size();
            e.KPI_Rule_4_Value__c = followFail ;
            if(workedHour > 0)
            {
                listMKPIDetail.add(createEmployeeRuleDetail(null,'5',soldHour,e.Id,'','Total Sold Hour',null));
                listMKPIDetail.add(createEmployeeRuleDetail(null,'5',workedHour,e.Id,'','Total Worked Hour',null));
               e.KPI_Rule_5_Value__c =  soldHour / workedHour * 100; 
            }
            if(onDutyHour > 0)
            {
                listMKPIDetail.add(createEmployeeRuleDetail(null,'6',workedHour,e.Id,'','Total Worked Hour',null));
                listMKPIDetail.add(createEmployeeRuleDetail(null,'6',onDutyHour,e.Id,'','Total On Duty Hour',null));
                e.KPI_Rule_6_Value__c = workedHour / onDutyHour * 100;
            }  
            
            if(countCustomerHaveActivity == 0)
            {
                currentRetentionRate = e.KPI_Rule_7_Target__c;
                listMKPIDetail.add(createEmployeeRuleDetail(null,'7',countCustomerHaveActivity,e.Id,'','Custom Have Activity',null));
                listMKPIDetail.add(createEmployeeRuleDetail(null,'7',countCustomer,e.Id,'','Customer',null));
            }
            else
            {
                currentRetentionRate = Decimal.valueOf(countCustomerHaveActivity)  / Decimal.valueOf(countCustomer) * 100;    
                listMKPIDetail.add(createEmployeeRuleDetail(null,'7',countCustomerHaveActivity,e.Id,'','Custom Have Activity',null));
                listMKPIDetail.add(createEmployeeRuleDetail(null,'7',countCustomer,e.Id,'','Customer',null));
            } 
            
            e.KPI_Rule_7_Value__c = currentRetentionRate ; // currentRetentionRate
            
            e.Team__c = 'Services';
            e.Hour_Sold_Revenue__c = soldHourRevenue *  e.Service_Hour_Rate__c / 100; // 1.5
            e.Part_Revenue__c = partRevenue * e.Part_Rate__c / 100; // 0.75
            e.A_A_Revenue__c = AARevenue * e.A_A_Rate__c / 100 ; // 0.5
            e.Voucher__c = voucherPartPCA * e.Part_Rate__c / 100 + voucherAAPCA *e.A_A_Rate__c  / 100;
            e.Service_Hour_Discount__c = discount  ; //* e.Service_Hour_Rate__c /100
            e.Part_Discount__c = discountPartPCA ; // * e.Part_Rate__c / 100
            e.A_A_Discount__c = discountAAPCA ; // * e.A_A_Rate__c / 100
            e.Discount__c  = discount * e.Service_Hour_Rate__c /100 + discountPartPCA * e.Part_Rate__c / 100 + discountAAPCA * e.A_A_Rate__c / 100;
            
            calServiceAM(e);
            
        }
        
        for(Monthly_KPI_Employee__c e : listPCAConsultant)
        {
            // Monthly sales volume
			// 1st PO of new bike delivery
			// TSI Score
			// Content creation
			// Customer follow-up
			 
			List<Order> listCurrentOrder = new List<Order>();
            
            Decimal saleVolume = listOrdersPCA.size();
            Decimal saleRevenue = 0;
            //Decimal tsiScore = 0;
            //Decimal totalOrderSurvey = 0;
            Decimal avarageTsi = 0;
            Decimal contentCreation = 0;
            Decimal followFail = 0;
            
            Decimal partRevenue = 0;
            Decimal AARevenue = 0;
            Decimal voucher = 0;
            Decimal discount = 0;
            
            // total commission = total line - all voucher - (bike gift - promotion / customer program) (discount) // khong co tren PCA - free service / coupon / warranty ( Free Coupon Order + Warranty Order )          
            
            for(OrderItem o : listOrdersLinePCAFromBike)
            {                
                listMKPIDetail.add(createEmployeeRuleDetail(o.Id,'2',o.KPI_Amount__c,e.Id,'Order Product','Order Product PCA',null));
            }
            listMKPIDetail.add(createEmployeeRuleDetail(null,'2',listOrdersLinePCAFromBike.size(),e.Id,'','Order PCA From Bike',null));
            
            for(Order o : listOrdersSale)
            {
                listMKPIDetail.add(createEmployeeRuleDetail(o.Id,'2',o.Amount__c,e.Id,'Order','Order Sale',null));
            }
            listMKPIDetail.add(createEmployeeRuleDetail(null,'2',listOrdersSale.size(),e.Id,'','Order Sale',null));

           
            if(mapOrderPCA.containsKey(e.Employee__c))
            {
                listCurrentOrder = mapOrderPCA.get(e.Employee__c);
                for(Order o : listCurrentOrder)
                {
                    if(o.Status == 'Completed')
                    {
                        /*if(o.Total_Survey_Sales__c != 0 || o.Total_Survey_Service__c != 0 || o.Total_Survey_PCA__c != 0)
                        {
                            totalOrderSurvey++;
                            tsiScore += o.TSI__c;
                            listMKPIDetail.add(createEmployeeRuleDetail(o.Id, '3',null,e.Id,'Order','TSI',null));
                        }*/
                        
                        if(mapPaymentVoucher.containsKey(o.Id))
                        {
                            List<Payment__c> listCurrentVoucher = mapPaymentVoucher.get(o.Id);
                            for(Payment__c p : listCurrentVoucher)
                            {
                                if(p.Payment_For__c == 'Phụ tùng-phụ kiện-quần áo/PCA')
                                {
                                    voucher -= p.Amount__c;
                                    listMKPIDetail.add(createEmployeeCommissionDetail(null,o.Id,null,'Voucher',p.Amount__c * -1,e.Id,null));  
                                }                            
                            }
                        }
                    }                   
                }
            }
            
            for(OrderItem item : listOrderItemPCA)
            {
                saleRevenue += item.KPI_Amount__c;
                listMKPIDetail.add(createEmployeeRuleDetail(item.Id,'1',item.KPI_Amount__c,e.Id,'Order Product','Sale Revenue',null));
            }            
            
            
            if(mapOrderItemPCA.containsKey(e.Employee__c))
            {
                List<OrderItem> listCurrentOrderItem = mapOrderItemPCA.get(e.Employee__c);
                for(OrderItem item : listCurrentOrderItem)
                {
                    //saleRevenue += item.TotalPrice;
                    //listMKPIDetail.add(createEmployeeRuleDetail(item.Id,'1',item.TotalPrice,e.Id,'Order Product','Sale Revenue'));
                    
                    
                    if(item.Product2.Family == 'Part')
                    {
                        partRevenue += item.KPI_Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Part Revenue',item.KPI_Amount__c,e.Id,null));
                        
                        discount -= item.KPI_Amount__c - item.TotalPrice ;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                        
                    }
                    else if(item.Product2.Family == 'ACC')
                    {
                        AARevenue += item.KPI_Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'A&A Revenue',item.KPI_Amount__c,e.Id,null));
                        
                        discount -= item.KPI_Amount__c - item.TotalPrice ;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                    }     
                    

                }
            }
            
            //system.debug('PCA Consultant : '+ e.Employee__c);
            avarageTSI = SurveyCalculateHelper.calculatePoint(listCurrentOrder,e.KPI_Rule_3_Target__c,e,listMKPIDetail,'3');  
            //system.debug('End PCA Consultant : '+ e.Employee__c);
            
            /*if(totalOrderSurvey > 0)
            {
                avarageTsi = tsiScore / totalOrderSurvey;
            }
            else
            {
                avarageTsi = e.KPI_Rule_3_Target__c;
            }*/
            
            if(mapMTask.containsKey(e.Employee__c))
            {
                List<Monthly_Task__c> currentListMTask = mapMTask.get(e.Employee__c); 
                for(Monthly_Task__c mT : currentListMTask)
                {
                    if(mT.RecordTypeId == RecordTypeHelper.MONTHLY_CONTENT_CREATION && mT.Is_Confirm__c == true)
                    {
                        contentCreation++;                       
                        listMKPIDetail.add(createEmployeeRuleDetail(mT.Id,'4',null,e.Id,'Monthly Task','Content Creation',null));
                    }
                }
            }    
            
            List<Follow_Fail__c> listCurrentFollow = new List<Follow_Fail__c>();
            if(mapFail.containsKey(e.Employee__c))
            {
                listCurrentFollow = mapFail.get(e.Employee__c);
                for(Follow_Fail__c f : listCurrentFollow)
                {
                    listMKPIDetail.add(createEmployeeRuleDetail(f.Id,'5',null,e.Id,'Follow Fail','Follow Fail',null));
                }               
            }
            
            e.KPI_Rule_1_Value__c = saleRevenue;
            e.KPI_Rule_2_Value__c = newBikeDelivery;
            e.KPI_Rule_3_Value__c = avarageTsi;
            e.KPI_Rule_4_Value__c = contentCreation;
            e.KPI_Rule_5_Value__c = listCurrentFollow.size();

            e.Team__c = 'PCA';
		    e.Part_Revenue__c = partRevenue * e.Part_Rate__c / 100; // 3.5
            e.A_A_Revenue__c = AARevenue * e.A_A_Rate__c / 100; // 3.5
            e.Voucher__c = voucher * e.Part_Rate__c / 100; // 3.5
            e.Discount__c = discount * e.Part_Rate__c / 100; // 3.5 
            
            calPCAConsultant(e);
            
        }
        
        for(Monthly_KPI_Employee__c e : listPCASupervisor)
        {
			// Monthly sales revenue
			// Spare Parts Supply Ratio
			// Stock movement
            // Stock age control
            // Team TSI
             
            //Decimal totalTSI;
            //Decimal totalOrderSurvey = 0;
            Decimal avarageTSI = 0;
            
            Decimal partRevenue = 0;
            Decimal AARevenue = 0;
            Decimal partServiceRevenue = 0;
            Decimal AAServiceRevenue = 0;
            Decimal voucher = 0;
            Decimal serviceVoucher = 0;
            Decimal discount = 0;
            Decimal discountService = 0;

            // total commission = total line - all voucher - bike gift - promotion / customer program             
            
            Decimal saleRevenue = 0;
            Decimal supllyRatio = 0;
            if(listOrderItemPCA.size() > 0)
            {
                // (tổng các line pca - tổng line có tick profoma = true)/ tổng line pca
                supllyRatio = (listOrderItemPCA.size() - listOrderItemPCAPerfomar.size()) / listOrderItemPCA.size() * 100 ;
                
                listMKPIDetail.add(createEmployeeRuleDetail(null, '2',listOrderItemPCA.size() - listOrderItemPCAPerfomar.size(),e.Id,'','Total Allocated Sale Order Lines',null));
                listMKPIDetail.add(createEmployeeRuleDetail(null, '2',listOrderItemPCA.size(),e.Id,'','Total Filled Sale Order Lines',null));
            }
            
            // up 5/5/2022
            for(OrderItem item : listOrderItemPCA)
            {
                saleRevenue += item.KPI_Amount__c;
                listMKPIDetail.add(createEmployeeRuleDetail(item.Id,'1',item.KPI_Amount__c,e.Id,'Order Product','Sale Revenue',null));
            }           
            
            for(Order o : listOrdersPCA)
            {
                if(o.Status == 'Completed')
                {
                    /*saleRevenue += o.Amount__c;
                    listMKPIDetail.add(createEmployeeRuleDetail(o.Id,'1',o.Amount__c,e.Id,'Order','Sale Revenue'));*/
                    
                    /*if(o.Total_Survey_Sales__c != 0 || o.Total_Survey_Service__c != 0 || o.Total_Survey_PCA__c != 0)
                    {
                        totalOrderSurvey++;
                        totalTSI += o.TSI__c;
                        listMKPIDetail.add(createEmployeeRuleDetail(o.Id, '5',null,e.Id,'Order','TSI',null));
                    }*/
                    
                    // voucher for order PCA
                    if(mapPaymentVoucher.containsKey(o.Id))
                    {
                        List<Payment__c> listCurrentVoucher = mapPaymentVoucher.get(o.Id);
                        for(Payment__c p : listCurrentVoucher)
                        {
                            if(p.Payment_For__c == 'Phụ tùng-phụ kiện-quần áo/PCA')
                            {
                                voucher -= p.Amount__c;
                                listMKPIDetail.add(createEmployeeCommissionDetail(null,o.Id,null,'Voucher',p.Amount__c * -1,e.Id,null));   
                            }                           
                        }
                    } 
                }               
            }
            
            avarageTSI = SurveyCalculateHelper.calculatePoint(listOrdersPCA,e.KPI_Rule_5_Target__c,e,listMKPIDetail,'5');  
            
            /*if(totalOrderSurvey > 0)
            {
                avarageTSI = totalTSI / totalOrderSurvey;
            }
            else
            {
                avarageTSI = e.KPI_Rule_5_Target__c;
            }  */      
            
            for(Inventory_Transaction_Item__c inv : listThreeMonthInventory)
            {
                listMKPIDetail.add(createEmployeeRuleDetail(inv.Id,'4',inv.Quantity_Amount_Remaing_KPI__c,e.Id,'Inventory Transaction Item','180 Days Stock',null));
            }
            
            Decimal stockMovement = 0;
            Decimal stockAgeControl = 0;
            
            for(Stock_History__c stock : listStartMonthStockHistory)
            {
                listMKPIDetail.add(createEmployeeRuleDetail(stock.Id,'3',stock.Stock_At_The_Start__c * stock.Product__r.KPI_Price__c,e.Id,'Stock History','Start Month Stock',null));
            }
            
            for(Stock_History__c stock : listEndMonthStockHistory)
            {
                listMKPIDetail.add(createEmployeeRuleDetail(stock.Id,'4',stock.Stock_At_The_Start__c * stock.Product__r.KPI_Price__c,e.Id,'Stock History','End Monthy Stock',null));
            }
            
            
            if(startMonthStock > 0)
            {
                stockMovement = saleRevenue / startMonthStock * 100;
            }
            
            if(threeMonthDayStock == 0)
            {
                stockAgeControl = e.KPI_Rule_4_Target__c;
            }
            else if(endMonthStock > 0 )
            {
                stockAgeControl = threeMonthDayStock / endMonthStock * 100;
            }
            
            
            Set<Id> setOrderServiceId = new Set<Id>();
            for(Monthly_KPI_Employee__c child : listPCAChildForAM)
            {
                if(mapOrderItemPCA.containsKey(child.Employee__c))
                {
                    List<OrderItem> listCurrentOrderItem = mapOrderItemPCA.get(child.Employee__c);
                    
                    for(OrderItem item : listCurrentOrderItem)
                    {
                        if(item.Product2.Family == 'Part')
                        {
                            partRevenue += item.KPI_Amount__c;
                            listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Part Revenue',item.KPI_Amount__c,e.Id,null));               
                            setOrderServiceId.add(item.OrderId);
                            
                            discount -= item.KPI_Amount__c - item.TotalPrice ;
                            listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                        }
                        else if(item.Product2.Family == 'ACC')
                        {
                            AARevenue += item.KPI_Amount__c;
                            listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'A&A Revenue',item.KPI_Amount__c,e.Id,null));        
                            setOrderServiceId.add(item.OrderId);
                            
                            discount -= item.KPI_Amount__c - item.TotalPrice ;
                            listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                        }                    	
                    }
                }  
            }
            
            // voucher cho order service
            for(Order o : listOrdersService)
            {
                if(mapPaymentVoucher.containsKey(o.Id))
                {
                    List<Payment__c> listCurrentVoucher = mapPaymentVoucher.get(o.Id);
                    for(Payment__c p : listCurrentVoucher)
                    {
                        if(p.Payment_For__c == 'Phụ tùng-phụ kiện-quần áo/PCA')
                        {
                            serviceVoucher -= p.Amount__c;
                            listMKPIDetail.add(createEmployeeCommissionDetail(null,o.Id,null,'Voucher',p.Amount__c * -1,e.Id,null));   
                        }                           
                    }
                } 
            }
            
            List<OrderItem> listCurrentOrderItem = new List<OrderItem>();
            listCurrentOrderItem = listOrderItemPCAFromServiceOrder;
            for(OrderItem item : listCurrentOrderItem)
            {
                if(item.Product2.RecordTypeId == RecordTypeHelper.PRODUCT_PCA)
                {                          
                    if(item.Product2.Family == 'Part')
                    {
                        partServiceRevenue += item.KPI_Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Part Revenue',item.KPI_Amount__c,e.Id,null));
                        
                        discount -= item.KPI_Amount__c - item.TotalPrice ;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                    }
                    else if(item.Product2.Family == 'ACC')
                    {
                        AAServiceRevenue += item.KPI_Amount__c;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'A&A Revenue',item.KPI_Amount__c,e.Id,null));
                        
                        discount -= item.KPI_Amount__c - item.TotalPrice ;
                        listMKPIDetail.add(createEmployeeCommissionDetail(null,item.OrderId,item.Id,'Discount',(item.KPI_Amount__c - item.TotalPrice) * -1,e.Id,null));
                    }                            
                }
            }
            
            e.KPI_Rule_1_Value__c = saleRevenue;
            e.KPI_Rule_2_Value__c = supllyRatio;
            e.KPI_Rule_3_Value__c = stockMovement;
            e.KPI_Rule_4_Value__c = stockAgeControl;
            e.KPI_Rule_5_Value__c = avarageTSI;
            
            e.Team__c = 'PCA';
            e.Part_Revenue__c = partRevenue * e.Part_Rate__c / 100 + partServiceRevenue * e.Part_Service_Rate__c / 100; // 1.25 // 0.5
            e.A_A_Revenue__c = AARevenue * e.A_A_Rate__c / 100 + AAServiceRevenue * e.A_A_Service_Rate__c / 100; // 1.25 // 0.5
            e.Voucher__c = voucher * e.Part_Rate__c / 100 + serviceVoucher * e.Part_Service_Rate__c / 100;  // 1.25 // 0.5
            e.Discount__c = discount * e.Part_Rate__c / 100 + discountService * e.Part_Service_Rate__c / 100; // 1.25 // 0.5
            

           	calPCASuper(e);
        }

		if(!listEmployee.isEmpty())
        {
            system.debug('listEmployee size : '+listEmployee.size());
            update listEmployee;
        }
        
        /*if(!listEmployeeDetail.isEmpty())
        {
            system.debug('listEmployeeDetail size : '+listEmployeeDetail.size());
            //delete listEmployeeDetail;           
            //System.enqueueJob(new DeleteOldEmployeeDetail(listEmployeeDetail,0));
        }*/
        
        if(!listMKPIDetail.isEmpty())
        {
            system.debug('listMKPIDetail size : '+listMKPIDetail.size());
            //insert listMKPIDetail;
            System.enqueueJob(new InsertEmployeeDetail(listMKPIDetail,0,monthlyId));
        }
    }
    
    /*public class DeleteOldEmployeeDetail implements Queueable, Database.AllowsCallouts { 
        // Decrease this if we run into heap size limit (maximum of 6MB)
        List<Monthly_KPI_Employee_Detail__c> listEmployeeDetailOld;
        Integer offset = 0;
        Integer maxOffset = 0;
        
        
        public DeleteOldEmployeeDetail(List<Monthly_KPI_Employee_Detail__c> listEmployeeDetailOld,Integer offset,monthlyRecordId){
			this.listEmployeeDetailOld = listEmployeeDetailOld;      
            this.offset = offset;
        }
        
        public void execute(QueueableContext context) {
            
            List<Monthly_KPI_Employee_Detail__c> listCurrentDelete = new List<Monthly_KPI_Employee_Detail__c>();
            if(offset + 1000 < listEmployeeDetailOld.size())
            {
                maxOffset = offset + 1000;
            }
            else
            {
                maxOffset = listEmployeeDetailOld.size();
            }
            
            for(Integer i = offset; i < maxOffset ; i++)
            {
                listCurrentDelete.add(listEmployeeDetailOld[i]);
            }
            
            if(!listCurrentDelete.isEmpty())
            {
                delete listCurrentDelete;
            }
            
            if(maxOffset != listEmployeeDetailOld.size())
            {
				System.enqueueJob(new DeleteOldEmployeeDetail(listEmployeeDetailOld,maxOffset));
            }
        }  
    }*/
    
    public class InsertEmployeeDetail implements Queueable, Database.AllowsCallouts { 
        List<Monthly_KPI_Employee_Detail__c> listEmployeeDetail;
        Integer offset = 0;
        Integer maxOffset = 0;
        string monthlyRecordId = '';
        
        public InsertEmployeeDetail(List<Monthly_KPI_Employee_Detail__c> listEmployeeDetail,Integer offset,string monthlyRecordId ){
			this.listEmployeeDetail = listEmployeeDetail;      
            this.offset = offset;           
            this.monthlyRecordId = monthlyRecordId;
        }
        
        public void execute(QueueableContext context) {
            
            List<Monthly_KPI_Employee_Detail__c> listCurrentInsert = new List<Monthly_KPI_Employee_Detail__c>();
            if(offset + 1000 < listEmployeeDetail.size())
            {
                maxOffset = offset + 1000;
            }
            else
            {
                maxOffset = listEmployeeDetail.size();
            }
            
            for(Integer i = offset; i < maxOffset ; i++)
            {
                listCurrentInsert.add(listEmployeeDetail[i]);
            }
            
            if(!listCurrentInsert.isEmpty())
            {
                try
                {
                    insert listCurrentInsert;
                }
                catch(Exception e)
                {
                    String error = e.getMessage() + ' , ' +e.getLineNumber();
                    system.debug(error);
                }              
            }
            
            if(maxOffset != listEmployeeDetail.size())
            {
				System.enqueueJob(new InsertEmployeeDetail(listEmployeeDetail,maxOffset,monthlyRecordId));
            }
            else
            {
                Monthly_KPI__c m = new Monthly_KPI__c();
                m.Id = monthlyRecordId;
                m.Is_Calculating__c = false;
                ///update m;
            }
        }         
    }
    
    public static Monthly_KPI_Employee_Detail__c  createEmployeeRuleDetail(String recordId, String rule,Decimal amount ,String employeeId,String recordObjectType,String label,String extra)
    {
        Monthly_KPI_Employee_Detail__c eDetail = new Monthly_KPI_Employee_Detail__c();
        if(recordObjectType == 'Opportunity')
        {
            eDetail.Opportunity__c = recordId;
        }
        else if(recordObjectType == 'Order')
        {
            eDetail.Order__c = recordId;
            if(extra != null)
            {
               eDetail.Sales_Owner__c = extra; 
            }           
        }
        else if(recordObjectType == 'Monthly Task')
        {
            eDetail.Monthly_Task__c = recordId;
        }
        else if(recordObjectType == 'Follow Fail')
        {
            eDetail.Follow_Fail__c = recordId;
        }
        else if(recordObjectType == 'Test Ride')
        {
            eDetail.Test_Ride__c = recordId;
        }
        else if(recordObjectType == 'Order Product')
        {
            eDetail.Order_Product__c = recordId;
        }
        else if(recordObjectType == 'Roster Management')
        {
            eDetail.Roster_Management__c = recordId;
        }
        else if(recordObjectType == 'Case')
        {
            eDetail.Case__c = recordId;
        }
        else if(recordObjectType == 'Warehouse Inventory')
        {
            eDetail.Warehouse_Inventory__c = recordId;
        }
        else if(recordObjectType == 'Stock History')
        {
            eDetail.Stock_History__c = recordId;
        }
        else if(recordObjectType == 'Inventory Transaction Item')
        {
            eDetail.Inventory_Transaction_Item__c = recordId;
        }
        
        eDetail.Label__c = label;
        eDetail.Rule__c = rule;
        eDetail.Amount__c = amount != null ? amount : 0;
        eDetail.Monthly_KPI_Employee__c = employeeId;   
        return eDetail;
    }
    
    public static Monthly_KPI_Employee_Detail__c  createEmployeeCommissionDetail(String optyId,String orderId,String orderItemId ,String commissionType,Decimal amount,String employeeId,String extra)
    {
        Monthly_KPI_Employee_Detail__c eDetail = new Monthly_KPI_Employee_Detail__c();
        if(optyId != null)
        {
            eDetail.Opportunity__c = optyId;
        }
        if(orderId != null)
        {
            eDetail.Order__c = orderId;
            if(extra != null)
            {
                eDetail.Sales_Owner__c = extra;
            }
        }
        if(orderItemId != null)
        {
            eDetail.Order_Product__c = orderItemId;
        }
        
        eDetail.Rule__c = 'Commission';
        eDetail.Commission_Type__c = commissionType;
        eDetail.Label__c = commissionType;
        eDetail.Amount__c = amount;
        eDetail.Monthly_KPI_Employee__c = employeeId;
        
        return eDetail;
    }
    
    //Monthly achieved = sum order amount
    //customer wrong info 
    //TSI score
    //times not follow correctly the score
    public static void calSalesConsultant(Monthly_KPI_Employee__c employee)
    {
        /*Sales Volume : đếm số order có einvoice trong tháng / List Order có einvoice date 
        Number of Enquiries : đếm số opty new trong tháng / List opty created trong tháng
        Quality of Enquiries : Đếm số opty có ngày record trong tháng / List opty có ngày comment trong tháng
        Number of Test Ride : Đếm lượt test ride của opty trong tháng / Tổng total test drive trên opty
        Content creation : đếm record Monthly Task trong tháng / Tổng số Monthly Task được tạo trong tháng có Is_Confirm__c = true
        TSI score : trung bình TSI của opty trong tháng / Trung bình cộng của TSI tất cả opty trong tháng
        Customer follow up : đếm số record Follow Fail trong tháng / Tổng số record follow fail trong tháng theo lead,opty */ 
        
     	employee.KPI_Rule_1_Value_Percent__c = employee.KPI_Rule_1_Value__c / employee.KPI_Rule_1_Target__c * employee.KPI_Rule_1_Percent__c ;
        
        Decimal value2 =  employee.KPI_Rule_2_Value__c / employee.KPI_Rule_2_Target__c * employee.KPI_Rule_2_Percent__c;
        employee.KPI_Rule_2_Value_Percent__c = value2 <= employee.KPI_Rule_2_Max_Percent__c ? value2 : employee.KPI_Rule_2_Max_Percent__c;
        
        if(employee.KPI_Rule_3_Value__c <= 1)
        {
            employee.KPI_Rule_3_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_3_Value__c <= 3)
        {
            employee.KPI_Rule_3_Value_Percent__c = 8;
        }
        else if(employee.KPI_Rule_3_Value__c <= 5)
        {
            employee.KPI_Rule_3_Value_Percent__c = 5;
        }
        else //if(employee.KPI_Rule_3_Value__c > 5)
        {
            employee.KPI_Rule_3_Value_Percent__c = 0;
        }
        
        Decimal value4 = employee.KPI_Rule_4_Value__c / employee.KPI_Rule_4_Target__c * employee.KPI_Rule_4_Percent__c ;
		employee.KPI_Rule_4_Value_Percent__c = value4 <= employee.KPI_Rule_4_Max_Percent__c ? value4 : employee.KPI_Rule_4_Max_Percent__c;
        
        Decimal value5 = employee.KPI_Rule_5_Value__c / employee.KPI_Rule_5_Target__c * employee.KPI_Rule_5_Percent__c ;
        employee.KPI_Rule_5_Value_Percent__c = value5 <= employee.KPI_Rule_5_Max_Percent__c ? value5 : employee.KPI_Rule_5_Max_Percent__c;
        
        if(employee.KPI_Rule_6_Value__c >= employee.KPI_Rule_6_Target__c)
        {
            employee.KPI_Rule_6_Value_Percent__c = 15;
        }
        else if(employee.KPI_Rule_6_Value__c >= employee.KPI_Rule_6_Target__c - 5)
        {
            employee.KPI_Rule_6_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_6_Value__c >= employee.KPI_Rule_6_Target__c - 10)
        {
            employee.KPI_Rule_6_Value_Percent__c = 5;
        }
        else //if(employee.KPI_Rule_6_Value__c < employee.KPI_Rule_6_Target__c - 15)
        {
            employee.KPI_Rule_6_Value_Percent__c = 0;
        }
        
        if(employee.KPI_Rule_7_Value__c <= 3)
        {
            employee.KPI_Rule_7_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_7_Value__c <= 6)
        {
            employee.KPI_Rule_7_Value_Percent__c = 5;
        }
        else //if(employee.KPI_Rule_7_Value__c > 6)
        {
            employee.KPI_Rule_7_Value_Percent__c = 0;
        }
        
        employee.KPI__c = employee.KPI_Rule_1_Value_Percent__c != null ? employee.KPI_Rule_1_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_2_Value_Percent__c != null ? employee.KPI_Rule_2_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_3_Value_Percent__c != null ? employee.KPI_Rule_3_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_4_Value_Percent__c != null ? employee.KPI_Rule_4_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_5_Value_Percent__c != null ? employee.KPI_Rule_5_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_6_Value_Percent__c != null ? employee.KPI_Rule_6_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_7_Value_Percent__c != null ? employee.KPI_Rule_7_Value_Percent__c : 0;
        employee.KPI__c = employee.KPI__c.setScale(2, RoundingMode.HALF_UP);
        
        if(employee.KPI__c >= 100)
        {
            employee.KPI_Rate__c = 1.2;
        }
        else if(employee.KPI__c >= 90)
        {
            employee.KPI_Rate__c = 1.1;
        }
        else if(employee.KPI__c >= 80)
        {
            employee.KPI_Rate__c = 1;
        }
        else if(employee.KPI__c >= 70)
        {
            employee.KPI_Rate__c = 0.9;
        }
        else
        {
            employee.KPI_Rate__c = 0.8;
        }
        
        employee.Commission__c = employee.Promo_In__c + employee.Promo_Out__c + employee.E_Commerce__c + employee.Used_Bike__c;
        employee.Total_Commission__c = employee.Commission__c * employee.KPI_Rate__c;

    }
    
    //Monthly achieved = sum order amount
    //1 time every month the conditions doesn’t meet requirement 
    //Avg TSI score 
    //Total team enquiries
    //Convert rate
    public static void calSalesSuper(Monthly_KPI_Employee__c employee)
    {
        Decimal monthlyAchieved = 0;
        Decimal conditionNotMeet = 0;
        Decimal tsiScore = 0;
        Decimal totalTeamEnquiries = 0;
        Decimal convertRate = 0;
        
        employee.KPI_Rule_1_Value_Percent__c = employee.KPI_Rule_1_Value__c / employee.KPI_Rule_1_Target__c * employee.KPI_Rule_1_Percent__c ;
        
        Decimal value2 = employee.KPI_Rule_2_Value__c / employee.KPI_Rule_2_Target__c * employee.KPI_Rule_2_Percent__c ;
        employee.KPI_Rule_2_Value_Percent__c = value2 <= employee.KPI_Rule_2_Max_Percent__c ? value2 : employee.KPI_Rule_2_Max_Percent__c;
        
        Decimal value3 = employee.KPI_Rule_3_Value__c / employee.KPI_Rule_3_Target__c * employee.KPI_Rule_3_Percent__c ;
        employee.KPI_Rule_3_Value_Percent__c = value3 <= employee.KPI_Rule_3_Max_Percent__c ? value3 : employee.KPI_Rule_3_Max_Percent__c;
        
        if(employee.KPI_Rule_4_Value__c <= 1)
        {
            employee.KPI_Rule_4_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_4_Value__c == 2)
        {
            employee.KPI_Rule_4_Value_Percent__c = 5;
        }
        else //if(employee.KPI_Rule_4_Value__c >= 3)
        {
            employee.KPI_Rule_4_Value_Percent__c = 0;
        }
        
        if(employee.KPI_Rule_5_Value__c >= employee.KPI_Rule_5_Target__c)
        {
            employee.KPI_Rule_5_Value_Percent__c = 15;
        }
        else if(employee.KPI_Rule_5_Value__c >= employee.KPI_Rule_5_Target__c - 10)
        {
            employee.KPI_Rule_5_Value_Percent__c = 10;
        }
        else //if(employee.KPI_Rule_5_Value__c < employee.KPI_Rule_5_Target__c - 10)
        {
            employee.KPI_Rule_5_Value_Percent__c = 5;
        }
        
        Decimal value6 = employee.KPI_Rule_6_Value__c / employee.KPI_Rule_6_Target__c * employee.KPI_Rule_6_Percent__c ;
        employee.KPI_Rule_6_Value_Percent__c = value6 <= employee.KPI_Rule_6_Max_Percent__c ? value6 : employee.KPI_Rule_6_Max_Percent__c;
        
        if(employee.KPI_Rule_7_Value__c >= employee.KPI_Rule_7_Target__c)
        {
            employee.KPI_Rule_7_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_7_Value__c >= employee.KPI_Rule_7_Target__c - 2)
        {
            employee.KPI_Rule_7_Value_Percent__c = 8;
        }
        else if(employee.KPI_Rule_7_Value__c >= employee.KPI_Rule_7_Target__c - 3)
        {
            employee.KPI_Rule_7_Value_Percent__c = 6;
        }
        else //if(employee.KPI_Rule_7_Value__c < employee.KPI_Rule_7_Target__c - 20)
        {
            employee.KPI_Rule_7_Value_Percent__c = 5;
        }
        
        employee.KPI__c = employee.KPI_Rule_1_Value_Percent__c != null ? employee.KPI_Rule_1_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_2_Value_Percent__c != null ? employee.KPI_Rule_2_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_3_Value_Percent__c != null ? employee.KPI_Rule_3_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_4_Value_Percent__c != null ? employee.KPI_Rule_4_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_5_Value_Percent__c != null ? employee.KPI_Rule_5_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_6_Value_Percent__c != null ? employee.KPI_Rule_6_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_7_Value_Percent__c != null ? employee.KPI_Rule_7_Value_Percent__c : 0;
        
        if(employee.KPI__c >= 100)
        {
            employee.KPI_Rate__c = 1.2;
        }
        else if(employee.KPI__c >= 90)
        {
            employee.KPI_Rate__c = 1.1;
        }
        else if(employee.KPI__c >= 80)
        {
            employee.KPI_Rate__c = 1;
        }
        else if(employee.KPI__c >= 70)
        {
            employee.KPI_Rate__c = 0.9;
        }
        else
        {
            employee.KPI_Rate__c = 0.8;
        }
        
        employee.Commission__c = employee.Promo_In__c + employee.Promo_Out__c + employee.E_Commerce__c + employee.Used_Bike__c;
        employee.Total_Commission__c = employee.Commission__c * employee.KPI_Rate__c;
    }
    
    //Monthly achieved
    //TSI score
    public static void calSaleAM(Monthly_KPI_Employee__c employee)
    {
        //Sales dept. volume 
        //Sales dept. revenue // Giá trị xuất VAT
        //Training // 
        //Number of Oppty // 
        //Sales dept. TSI // Tính hết chia trung bình.
        //Sales dept. content creation // Count tổng của của các member.

        
        Decimal monthlyAchieved = 0;
        Decimal tsiScore = 0;
        
        employee.KPI_Rule_1_Value_Percent__c = employee.KPI_Rule_1_Value__c / employee.KPI_Rule_1_Target__c * employee.KPI_Rule_1_Percent__c ;
        
        employee.KPI_Rule_2_Value_Percent__c = employee.KPI_Rule_2_Value__c / employee.KPI_Rule_2_Target__c * employee.KPI_Rule_2_Percent__c ;
        
        Decimal value3 = employee.KPI_Rule_3_Value__c / employee.KPI_Rule_3_Target__c * employee.KPI_Rule_3_Percent__c ;
        employee.KPI_Rule_3_Value_Percent__c = value3 <= employee.KPI_Rule_3_Max_Percent__c ? value3 : employee.KPI_Rule_3_Max_Percent__c;
        
        Decimal value4 = employee.KPI_Rule_4_Value__c / employee.KPI_Rule_4_Target__c * employee.KPI_Rule_4_Percent__c ;
        employee.KPI_Rule_4_Value_Percent__c = value4 <= employee.KPI_Rule_4_Max_Percent__c ? value4 : employee.KPI_Rule_4_Max_Percent__c;
        
        if(employee.KPI_Rule_5_Value__c >= employee.KPI_Rule_5_Target__c  )
        {
            employee.KPI_Rule_5_Value_Percent__c =15;
        }
        else if(employee.KPI_Rule_5_Value__c >= employee.KPI_Rule_5_Target__c - 5)
        {
            employee.KPI_Rule_5_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_5_Value__c >= employee.KPI_Rule_5_Target__c - 10)
        {
            employee.KPI_Rule_5_Value_Percent__c = 5;
        }
        else //if(employee.KPI_Rule_5_Value__c < employee.KPI_Rule_5_Target__c - 10)
        {
            employee.KPI_Rule_5_Value_Percent__c = 0;
        }               
        
        Decimal value6 = employee.KPI_Rule_6_Value__c / employee.KPI_Rule_6_Target__c * employee.KPI_Rule_6_Percent__c ;
        employee.KPI_Rule_6_Value_Percent__c = value6 <= employee.KPI_Rule_6_Max_Percent__c ? value6 : employee.KPI_Rule_6_Max_Percent__c;       
        
        employee.KPI__c = employee.KPI_Rule_1_Value_Percent__c != null ? employee.KPI_Rule_1_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_2_Value_Percent__c != null ? employee.KPI_Rule_2_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_3_Value_Percent__c != null ? employee.KPI_Rule_3_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_4_Value_Percent__c != null ? employee.KPI_Rule_4_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_5_Value_Percent__c != null ? employee.KPI_Rule_5_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_6_Value_Percent__c != null ? employee.KPI_Rule_6_Value_Percent__c : 0;
        
        if(employee.KPI__c >= 120)
        {
            employee.KPI_Rate__c = 1.3;
        }
        else if(employee.KPI__c >= 100)
        {
            employee.KPI_Rate__c = 1.2;
        }
        else if(employee.KPI__c >= 90)
        {
            employee.KPI_Rate__c = 1;
        }
        else if(employee.KPI__c >= 80)
        {
            employee.KPI_Rate__c = 0.9;
        }
        else
        {
            employee.KPI_Rate__c = 0.8;
        }
        
        employee.Commission__c = employee.Promo_In__c + employee.Promo_Out__c + employee.E_Commerce__c + employee.Used_Bike__c;
        employee.Total_Commission__c = employee.Commission__c * employee.KPI_Rate__c;
    }
    
    //Monthly PCA achieved
    //TSI score
    //not follow correctly the score
    public static void calServiceConsultant(Monthly_KPI_Employee__c employee)
    {
        if(employee.KPI_Rule_1_Target__c != null )
        {
            employee.KPI_Rule_1_Value_Percent__c = employee.KPI_Rule_1_Value__c / employee.KPI_Rule_1_Target__c * employee.KPI_Rule_1_Percent__c ;
        }
        if(employee.KPI_Rule_1_Service_Target__c != null)
        {
            employee.KPI_Rule_1_Service_Value_Percent__c = employee.KPI_Rule_1_Service_Value__c / employee.KPI_Rule_1_Service_Target__c * employee.KPI_Rule_1_Service_Percent__c ;
        }
        
        if(employee.KPI_Rule_2_Value__c >= employee.KPI_Rule_2_Target__c )
        {
            employee.KPI_Rule_2_Value_Percent__c =15;
        }
        else if(employee.KPI_Rule_2_Value__c >= employee.KPI_Rule_2_Target__c - 5)
        {
            employee.KPI_Rule_2_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_2_Value__c >= employee.KPI_Rule_2_Target__c - 10)
        {
            employee.KPI_Rule_2_Value_Percent__c = 5;
        }
        else //if(tsiScore < 80)
        {
            employee.KPI_Rule_2_Value_Percent__c = 0;
        }
        
        
        if(employee.KPI_Rule_3_Value__c  <= 3 )
        {
            employee.KPI_Rule_3_Value_Percent__c = 15;
        }
        else if(employee.KPI_Rule_3_Value__c <= 6)
        {
            employee.KPI_Rule_3_Value_Percent__c = 7.5;
        }
        else //if(customerWrongFollow > 6)
        {
            employee.KPI_Rule_3_Value_Percent__c = 0;
        }
        
        if(employee.KPI_Rule_4_Value__c >= employee.KPI_Rule_4_Target__c )
        {
            employee.KPI_Rule_4_Value_Percent__c =5;
        }
        else if(employee.KPI_Rule_4_Value__c >= employee.KPI_Rule_4_Target__c - 5)
        {
            employee.KPI_Rule_4_Value_Percent__c = 2.5;
        }
        else //if(employee.KPI_Rule_4_Target__c > 6)
        {
            employee.KPI_Rule_4_Value_Percent__c = 0;
        }
        
        // not sure
        if(employee.KPI_Rule_5_Value__c >= employee.KPI_Rule_5_Target__c )
        {
            employee.KPI_Rule_5_Value_Percent__c = 5;
        }
        else if(employee.KPI_Rule_5_Value__c >= employee.KPI_Rule_5_Target__c -10 )
        {
            employee.KPI_Rule_5_Value_Percent__c = 2.5;
        }
        else //if(employee.KPI_Rule_5_Target__c > 6)
        {
            employee.KPI_Rule_5_Value_Percent__c = 0;
        }
        
        // not sure
        if(employee.KPI_Rule_6_Value__c >= employee.KPI_Rule_6_Target__c )
        {
            employee.KPI_Rule_6_Value_Percent__c =10;
        }
        else if(employee.KPI_Rule_6_Value__c >= employee.KPI_Rule_6_Target__c - 10)
        {
            employee.KPI_Rule_6_Value_Percent__c = 5;
        }
        else //if(employee.KPI_Rule_6_Target__c > 6)
        {
            employee.KPI_Rule_6_Value_Percent__c = 0;
        }
        
        Decimal value7 = employee.KPI_Rule_7_Value__c / employee.KPI_Rule_7_Target__c * employee.KPI_Rule_7_Percent__c ;
        employee.KPI_Rule_7_Value_Percent__c = value7 <= employee.KPI_Rule_7_Max_Percent__c ? value7 : employee.KPI_Rule_7_Max_Percent__c;
        
        employee.KPI__c = employee.KPI_Rule_1_Value_Percent__c != null ? employee.KPI_Rule_1_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_1_Service_Value_Percent__c != null ? employee.KPI_Rule_1_Service_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_2_Value_Percent__c != null ? employee.KPI_Rule_2_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_3_Value_Percent__c != null ? employee.KPI_Rule_3_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_4_Value_Percent__c != null ? employee.KPI_Rule_4_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_5_Value_Percent__c != null ? employee.KPI_Rule_5_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_6_Value_Percent__c != null ? employee.KPI_Rule_6_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_7_Value_Percent__c != null ? employee.KPI_Rule_7_Value_Percent__c : 0;
        employee.KPI__c = employee.KPI__c.setScale(2, RoundingMode.HALF_UP);
        
        if(employee.KPI__c >= 100)
        {
            employee.KPI_Rate__c = 1.2;
        }
        else if(employee.KPI__c >= 90)
        {
            employee.KPI_Rate__c = 1.1;
        }
        else if(employee.KPI__c >= 80)
        {
            employee.KPI_Rate__c = 1;
        }
        else if(employee.KPI__c >= 70)
        {
            employee.KPI_Rate__c = 0.9;
        }
        else
        {
            employee.KPI_Rate__c = 0.8;
        }
        
        if(employee.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert')
        {
            employee.Commission__c = employee.Hour_Sold_Revenue__c + employee.Part_Revenue__c + employee.A_A_Revenue__c + employee.Voucher__c + employee.Discount__c ;
            employee.Total_Commission__c = employee.Commission__c * employee.KPI_Rate__c; 
        }
        else
        {
            employee.Commission__c = employee.Hour_Sold_Revenue__c + employee.Part_Revenue__c + employee.A_A_Revenue__c + employee.Voucher__c + employee.Discount__c ;
            employee.Total_Commission__c = employee.Commission__c * employee.KPI_Rate__c; 
        }      
    }
    
    //Monthly achieved
    //TSI score
    public static void calAllTech(Monthly_KPI_Employee__c employee)
    {
        
        employee.KPI_Rule_1_Value_Percent__c = employee.KPI_Rule_1_Value__c / employee.KPI_Rule_1_Target__c * employee.KPI_Rule_1_Percent__c ;
        
        if(employee.KPI_Rule_2_Value__c >= employee.KPI_Rule_2_Target__c)
        {
            employee.KPI_Rule_2_Value_Percent__c = 20;
        }
        else if(employee.KPI_Rule_2_Value__c >= employee.KPI_Rule_2_Target__c - 5)
        {
            employee.KPI_Rule_2_Value_Percent__c = 17.5;
        }
        else //if(employee.KPI_Rule_2_Target__c < 90)
        {
            employee.KPI_Rule_2_Value_Percent__c = 15;
        }
        
        // not sure
        if(employee.KPI_Rule_3_Value__c >= employee.KPI_Rule_3_Target__c)
        {
            employee.KPI_Rule_3_Value_Percent__c = 20;
        }
        else if(employee.KPI_Rule_3_Value__c >= employee.KPI_Rule_3_Target__c - 10)
        {
            employee.KPI_Rule_3_Value_Percent__c = 17.5;
        }
        else //if(employee.KPI_Rule_3_Target__c < 70)
        {
            employee.KPI_Rule_3_Value_Percent__c = 15;
        }
        
        // not sure
        if(employee.KPI_Rule_4_Value__c >= employee.KPI_Rule_4_Target__c)
        {
            employee.KPI_Rule_4_Value_Percent__c = 30;
        }
        else if(employee.KPI_Rule_4_Value__c >= employee.KPI_Rule_4_Target__c -5)
        {
            employee.KPI_Rule_4_Value_Percent__c = 25;
        }
        else //if(tsiScore > 80 && tsiscore < 85)
        {
            employee.KPI_Rule_4_Value_Percent__c = 20;
        }
        
        employee.KPI__c = employee.KPI_Rule_1_Value_Percent__c != null ? employee.KPI_Rule_1_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_2_Value_Percent__c != null ? employee.KPI_Rule_2_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_3_Value_Percent__c != null ? employee.KPI_Rule_3_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_4_Value_Percent__c != null ? employee.KPI_Rule_4_Value_Percent__c : 0;
        
        Decimal incentiveScheme = 0;
        if(employee.KPI__c >= 100)
        {
            employee.KPI_Rate__c = 1.2;
            if(employee.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert')
            {
                incentiveScheme = 3000000;
            }
        }
        else if(employee.KPI__c >= 90)
        {
            employee.KPI_Rate__c = 1.1;
            if(employee.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert')
            {
                incentiveScheme = 2000000;
            }
        }
        else if(employee.KPI__c >= 80)
        {
            employee.KPI_Rate__c = 1;
            if(employee.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert')
            {
                incentiveScheme = 1000000;
            }
        }
        else if(employee.KPI__c >= 70)
        {
            employee.KPI_Rate__c = 0.9;
        }
        else
        {
            employee.KPI_Rate__c = 0.8;
        }
        
        employee.Commission__c = employee.Hour_Sold_Revenue__c + employee.Discount__c;
        //employee.Total_Commission__c = employee.Commission__c * employee.KPI_Rate__c;
        employee.Total_Commission__c = employee.Commission__c * employee.KPI_Rate__c + incentiveScheme; // bật lên khi muốn tính thêm incentive scheme cho chief
             
    }
    
    //Monthly PCA achieved
    //Monthly Service Achieved
    //TSI score
    //complain record
    //followWrong
    public static void calServiceAM(Monthly_KPI_Employee__c employee)
    {        
        
        if(employee.KPI_Rule_1_Target__c != null )
        {
            employee.KPI_Rule_1_Value_Percent__c = employee.KPI_Rule_1_Value__c / employee.KPI_Rule_1_Target__c * employee.KPI_Rule_1_Percent__c ;
        }
        if(employee.KPI_Rule_1_Service_Target__c != null)
        {
            employee.KPI_Rule_1_Service_Value_Percent__c = employee.KPI_Rule_1_Service_Value__c / employee.KPI_Rule_1_Service_Target__c * employee.KPI_Rule_1_Service_Percent__c ;
        }
        
        if(employee.KPI_Rule_2_Value__c >= employee.KPI_Rule_2_Target__c)
        {
            employee.KPI_Rule_2_Value_Percent__c = 15;
        }
        else if(employee.KPI_Rule_2_Value__c >= employee.KPI_Rule_2_Target__c - 5)
        {
            employee.KPI_Rule_2_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_2_Value__c >= employee.KPI_Rule_2_Target__c - 10)
        {
            employee.KPI_Rule_2_Value_Percent__c = 5;
        }
        else //if(tsiScore < 80)
        {
            employee.KPI_Rule_2_Value_Percent__c = 0;
        }
        
        if(employee.KPI_Rule_3_Value__c == 0)
        {
            employee.KPI_Rule_3_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_3_Value__c <= 2)
        {
            employee.KPI_Rule_3_Value_Percent__c = 7.5;
        }
        else if(employee.KPI_Rule_3_Value__c <= 4)
        {
            employee.KPI_Rule_3_Value_Percent__c = 5;
        }
        else //if(complainRecord > 4 || handlingTime > 24)
        {
            employee.KPI_Rule_3_Value_Percent__c = 0;
        }           
        
        if(employee.KPI_Rule_4_Value__c <= 3)
        {
            employee.KPI_Rule_4_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_4_Value__c <= 6)
        {	
            employee.KPI_Rule_4_Value_Percent__c = 5;
        }
        else //if(employee.KPI_Rule_5_Target__c > 6)
        {
            employee.KPI_Rule_4_Value_Percent__c = 0;
        }
        
        // not sure
        if(employee.KPI_Rule_5_Value__c >= 95)
        {
            employee.KPI_Rule_5_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_5_Value__c >= 90)
        {
            employee.KPI_Rule_5_Value_Percent__c = 5;
        }
        else //if(employee.KPI_Rule_5_Target__c < 90)
        {
            employee.KPI_Rule_5_Value_Percent__c = 0;
        }
        
        if(employee.KPI_Rule_6_Value__c >= 80)
        {
            employee.KPI_Rule_6_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_6_Value__c >= 70)
        {
            employee.KPI_Rule_6_Value_Percent__c = 5;
        }
        else //if(employee.KPI_Rule_6_Target__c < 70)
        {
            employee.KPI_Rule_6_Value_Percent__c = 0;
        }
        
        if(employee.KPI_Rule_7_Value__c >= 40)
        {
            employee.KPI_Rule_7_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_7_Value__c >= 30)
        {
            employee.KPI_Rule_7_Value_Percent__c = 5;
        }
        else //if(employee.KPI_Rule_7_Target__c < 30)
        {
            employee.KPI_Rule_7_Value_Percent__c = 0;
        }
        
        employee.KPI__c = employee.KPI_Rule_1_Value_Percent__c != null ? employee.KPI_Rule_1_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_1_Service_Value_Percent__c != null ? employee.KPI_Rule_1_Service_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_2_Value_Percent__c != null ? employee.KPI_Rule_2_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_3_Value_Percent__c != null ? employee.KPI_Rule_3_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_4_Value_Percent__c != null ? employee.KPI_Rule_4_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_5_Value_Percent__c != null ? employee.KPI_Rule_5_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_6_Value_Percent__c != null ? employee.KPI_Rule_6_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_7_Value_Percent__c != null ? employee.KPI_Rule_7_Value_Percent__c : 0;
                
        if(employee.KPI__c >= 100)
        {
            employee.KPI_Rate__c = 1.2;
            if(employee.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert')
            {
                employee.Incentive_Scheme__c = 3000000;
            }   
        }
        else if(employee.KPI__c >= 90)
        {
            employee.KPI_Rate__c = 1.1;
            if(employee.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert')
            {
                employee.Incentive_Scheme__c = 2000000;
            }              
        }
        else if(employee.KPI__c >= 80)
        {
            employee.KPI_Rate__c = 1;
            if(employee.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert')
            {
                employee.Incentive_Scheme__c = 1000000;
            }               
        }
        else if(employee.KPI__c >= 70)
        {
            employee.KPI_Rate__c = 0.9;
        }
        else
        {
            employee.KPI_Rate__c = 0.8;
            if(employee.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert')
            {
                employee.Incentive_Scheme__c = 0;
            } 
        }
        
        employee.Commission__c = employee.Hour_Sold_Revenue__c + employee.Part_Revenue__c + employee.A_A_Revenue__c + employee.Voucher__c + employee.Discount__c ;
        employee.Total_Commission__c = employee.Commission__c * employee.KPI_Rate__c ;
        if(employee.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert')
        {
            employee.Total_Commission__c = employee.Incentive_Scheme__c;
        }
        
    }
    
    //Monthly achieved
    //TSI score
    //follow wrong
    public static void calPCAConsultant(Monthly_KPI_Employee__c employee)
    {
        Decimal monthlyAchieved = 0;
        Decimal tsiScore = 0;
        Decimal followWrong = 0;
        
        employee.KPI_Rule_1_Value_Percent__c = employee.KPI_Rule_1_Value__c / employee.KPI_Rule_1_Target__c * employee.KPI_Rule_1_Percent__c ;
        
        // not sure
        if(employee.KPI_Rule_2_Value__c >= 3)
        {
            employee.KPI_Rule_2_Value_Percent__c = 15;
        }
        else if(employee.KPI_Rule_2_Value__c >= 2)
        {
            employee.KPI_Rule_2_Value_Percent__c = 10;
        }
        else //if(employee.KPI_Rule_2_Target__c < 2)
        {
            employee.KPI_Rule_2_Value_Percent__c = 5;
        }

        if(employee.KPI_Rule_3_Value__c >= 90)
        {
            employee.KPI_Rule_3_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_3_Value__c >= 80)
        {
            employee.KPI_Rule_3_Value_Percent__c = 7.5;
        }
        else //if(tsiScore < 80)
        {
            employee.KPI_Rule_3_Value_Percent__c = 5;
        }

        Decimal value4 = employee.KPI_Rule_4_Value__c / employee.KPI_Rule_4_Target__c * employee.KPI_Rule_4_Percent__c ;
        employee.KPI_Rule_4_Value_Percent__c = value4 <= employee.KPI_Rule_4_Max_Percent__c ? value4 : employee.KPI_Rule_4_Max_Percent__c;
        
        if(employee.KPI_Rule_5_Value__c <= 3)
        {
            employee.KPI_Rule_5_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_5_Value__c <= 6)
        {
            employee.KPI_Rule_5_Value_Percent__c = 5;
        }
        else //if(followWrong > 6)
        {
            employee.KPI_Rule_5_Value_Percent__c = 0;
        }
        
        employee.KPI__c = employee.KPI_Rule_1_Value_Percent__c != null ? employee.KPI_Rule_1_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_2_Value_Percent__c != null ? employee.KPI_Rule_2_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_3_Value_Percent__c != null ? employee.KPI_Rule_3_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_4_Value_Percent__c != null ? employee.KPI_Rule_4_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_5_Value_Percent__c != null ? employee.KPI_Rule_5_Value_Percent__c : 0;
        
        if(employee.KPI__c >= 100)
        {
            employee.KPI_Rate__c = 1.2;
        }
        else if(employee.KPI__c >= 90)
        {
            employee.KPI_Rate__c = 1.1;
        }
        else if(employee.KPI__c >= 80)
        {
            employee.KPI_Rate__c = 1;
        }
        else if(employee.KPI__c >= 70)
        {
            employee.KPI_Rate__c = 0.9;
        }
        else
        {
            employee.KPI_Rate__c = 0.8;
        }
        
        employee.Commission__c = employee.Part_Revenue__c + employee.A_A_Revenue__c + employee.Voucher__c + employee.Discount__c;
        employee.Total_Commission__c = employee.Commission__c * employee.KPI_Rate__c;
    }
    
    //Monthly achieved
    //TSI score
    public static void calPCASuper(Monthly_KPI_Employee__c employee)
    {
        
        employee.KPI_Rule_1_Value_Percent__c = employee.KPI_Rule_1_Value__c / employee.KPI_Rule_1_Target__c * employee.KPI_Rule_1_Percent__c ;
        
        
        if(employee.KPI_Rule_2_Value__c >= employee.KPI_Rule_2_Percent__c )
        {
            employee.KPI_Rule_2_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_2_Value__c >= employee.KPI_Rule_2_Percent__c -25 )
        {
            employee.KPI_Rule_2_Value_Percent__c = 7.5;
        }
        else 
        {
            employee.KPI_Rule_2_Value_Percent__c = 5;
        }
        
        if(employee.KPI_Rule_3_Value__c >= 5)
        {
            employee.KPI_Rule_3_Value_Percent__c = 15;
        }
        else if(employee.KPI_Rule_3_Value__c >= 3)
        {
            employee.KPI_Rule_3_Value_Percent__c = 10;
        }
        else 
        {
            employee.KPI_Rule_3_Value_Percent__c = 5;
        }
        
        // not sure
        if(employee.KPI_Rule_4_Value__c <= employee.KPI_Rule_4_Target__c)
        {
            employee.KPI_Rule_4_Value_Percent__c = 15;
        }
        else if(employee.KPI_Rule_4_Value__c <= employee.KPI_Rule_4_Target__c + 10)
        {
            employee.KPI_Rule_4_Value_Percent__c = 10;
        }
        else 
        {
            employee.KPI_Rule_4_Value_Percent__c = 5;
        }
        
        if(employee.KPI_Rule_5_Value__c >= employee.KPI_Rule_5_Target__c)
        {
            employee.KPI_Rule_5_Value_Percent__c = 15;
        }
        else if(employee.KPI_Rule_5_Value__c >= employee.KPI_Rule_5_Target__c -5)
        {
            employee.KPI_Rule_5_Value_Percent__c = 10;
        }
        else if(employee.KPI_Rule_5_Value__c >= employee.KPI_Rule_5_Target__c - 10)
        {
            employee.KPI_Rule_5_Value_Percent__c = 5;
        }
        else 
        {
            employee.KPI_Rule_5_Value_Percent__c = 0;
        }
        
        employee.KPI__c = employee.KPI_Rule_1_Value_Percent__c != null ? employee.KPI_Rule_1_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_2_Value_Percent__c != null ? employee.KPI_Rule_2_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_3_Value_Percent__c != null ? employee.KPI_Rule_3_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_4_Value_Percent__c != null ? employee.KPI_Rule_4_Value_Percent__c : 0;
        employee.KPI__c += employee.KPI_Rule_5_Value_Percent__c != null ? employee.KPI_Rule_5_Value_Percent__c : 0;
        
        if(employee.KPI__c >= 100)
        {
            employee.KPI_Rate__c = 1.2;
        }
        else if(employee.KPI__c >= 90)
        {
            employee.KPI_Rate__c = 1.1;
        }
        else if(employee.KPI__c >= 80)
        {
            employee.KPI_Rate__c = 1;
        }
        else if(employee.KPI__c >= 70)
        {
            employee.KPI_Rate__c = 0.9;
        }
        else
        {
            employee.KPI_Rate__c = 0.8;
        }
        
        employee.Commission__c = employee.Part_Revenue__c + employee.A_A_Revenue__c + employee.Voucher__c + employee.Discount__c;
        employee.Total_Commission__c = employee.Commission__c * employee.KPI_Rate__c;
    }
    
    public static void addPoint()
    {
        Integer point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
                point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
         point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
                point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
         point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
                point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
         point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
         point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
         point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
                point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
         point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
         point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
         point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
         point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        
        point = 1;
        point = 1;
        point = 1;
         point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        point = 1;
        
    }
}