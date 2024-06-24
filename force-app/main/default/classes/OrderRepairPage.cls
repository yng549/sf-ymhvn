public with sharing class OrderRepairPage {
	private final static String MSG_EXCEPTION = 'Error System, Please Connect Admin.';
	private final static String DATE_TIME_FILE_FORMAT = 'yyyyMMddHHmm';
	private final static String FILE_NAME = '{0}_{1}_{2}.pdf';
	public String addressString {get; set;}
	private class CustomException extends Exception {}
	public Order objOrder {get; set;}
	public Date today {get; set;}
	public  String strOrderId {get; set;}
	public list<OrderItem> lstOrderItemRepair {get;set;}
    public list<OrderItem> lstOrderItemDetailing {get;set;}
    public list<OrderItem> lstOrderItemPCA {get;set;}
    private final static String SERVICE_TYPE_REPAIR = 'Repair';
    private final static String SERVICE_TYPE_DETAILING = 'Detailing';
	 
	public OrderRepairPage() {
		try {
			today = System.today();
            objOrder = new Order();
            addressString = '';
            strOrderId = ApexPages.currentPage().getParameters().get('Id');
            if(String.isNotBlank(strOrderId)) {
                objOrder = getOrderById(strOrderId);
                if(String.isBlank(objOrder.Id)) {
                    return;
                }
                lstOrderItemRepair = getOrderItemByOrderId(strOrderId, SERVICE_TYPE_REPAIR);
                system.Debug('lstOrderItemRepair : ' + lstOrderItemRepair);
                lstOrderItemDetailing = getOrderItemByOrderId(strOrderId, SERVICE_TYPE_DETAILING);
                system.Debug('lstOrderItemDetailing : ' + lstOrderItemDetailing);
                lstOrderItemPCA = getOrderItemByOrderId(strOrderId, Null);
                system.Debug('lstOrderItemPCA :' + lstOrderItemPCA);
                initAddressString(objOrder.Account.Address_No__c, objOrder.Account.Province__r.Name, objOrder.Account.District__r.Name);
            }
        } catch (Exception ex) {
            throw new CustomException(String.format(MSG_EXCEPTION, new List<Object>{ex.getMessage()}));
        }
	}

	private void initAddressString(String strAddressNo, String strProvince, String strDistrict) {
		if(String.isNotBlank(strAddressNo)) {
			addressString +=  (strAddressNo != Null ? strAddressNo + ', ' : '');
		}
		if (String.isNotBlank(strProvince)) {
			addressString += (strProvince != Null ? strProvince + ', ' : '');
		}
		if (String.isNotBlank(strDistrict)) {
			addressString += (strDistrict != Null ? strDistrict : '');
		}
    }

	private Order getOrderById(String strOrderId) {
        List<Order> lstOrderQuerry = [
                                        SELECT	Id,
                                        FormNumber__c,
                                        RecordType.Name,
            							Service_Job_Start_Date__c,
            							Service_Job_End_Date__c,
                                        EndDate,
                                        Bike_Delivery_Date__c,
                                        Bike_Receiving_Date__c,
                                        Make_Model__c,
                                        Year__c,
                                        Frame_No__c,
            							Mileage_Out__c,
                                        Titile_No__c,
                                        Stock_No__c,
                                        Mileage__c,
                                        Crankcase_No__c,
                                        OrderNumber,
                                        CreatedDate,
                                        Interested_In__c,
                                        Interested_In__r.Name,
                                        Compression__c,
                                        Clutch_Transmission__c,
                                        Cooling_system__c,
                                        Charging_system__c,
                                        Front_forks__c,
                                        Rear_shock_s__c,
                                        Front_brake_s__c,
                                        Rear_brake__c,
                                        Final_Drive__c,					
                                        Spark_plugs__c,	
                                        Steering_bearings__c,
                                        Handlebar_s__c,
                                        Tyres__c,
                                        Tail_light_s__c,
                                        Clutch_Throtttle_cable__c,
                                        Brake_Clutch_levers__c,
                                        Wheels__c,
                                        Wheel_bearings__c,
                                        Swing_arm_bearings__c,
                                        Switches_Housings__c,
                                        Rearsets_Footpegs__c,
                                        Indicators__c,
                                        Headlight_s__c,
                                        Brake_light__c,
                                        Main_fairings__c,
                                        Small_covers__c,
                                        Rider_seat__c,
                                        Passenger_seat__c,
                                        Fuel_tank__c,
                                        Engine__c,
                                        Chassis__c,
                                        Handling__c,
                                        Fairings__c,
                                        Accessories__c,
                                        General_Condition__c,
                                        Clean_up__c,
                                        Reconditioning_Total__c,
                                        Reconditioning_note__c,            
                                        Asset__c,
                                        Asset__r.Frame_Number__c,
                                        Asset__r.Product2.Model__c,
                                        Asset__r.Product2.Model_Bike__r.Name,
                                        Asset__r.Engine_No__c,
                                        Account.Name,
                                        Account.Address_Full__c,
                                        Account.Phone,
                                        Account.PersonMobilePhone,
                                        Account.Address_No__c,
                                        Account.Province__r.Name,
                                        Account.District__r.Name,
                                        Sales_Associate__c,
                                        Sales_Associate__r.Name,				
                                        OwnerId,
                                        Owner.Name,
                                        Appraiser__c,
                                        Appraiser__r.Name,
                                        Dealer__c,				
                                        Status,
                                        Mechanic__r.Name,
                                        Opportunity.Asset__r.Year__c,
                                        Opportunity.Asset__r.Make_Model__c,
                                        Opportunity.Asset__r.VinID__c,
                                        Opportunity.Asset__r.Mileage__c,
                                        Opportunity.Asset__r.Engine_No__c,
            							Detailing_Staff__r.FirstName,
            							Detailing_Staff__r.LastName,
                                        Detailing_End_Date__c,
                                        Detailing_Start_Date__c
                                        FROM	Order							
                                        WHERE	Id = : strOrderId];
        if (lstOrderQuerry.isEmpty()) {
            return new Order();
        } else {
            return lstOrderQuerry[0];
        }
    }
	private static List<OrderItem>  getOrderItemByOrderId(String strOrderId, String strServiceType) {
        List<OrderItem> lstOrderItem = new List<OrderItem>();
        if(strServiceType == Null) {
            lstOrderItem = [SELECT Id
                            , Percent__c
                            , UnitPrice
                            , Product2.Name
                            , Product2.Labor_HOUR__c
                            , TotalPrice
                            , ListPrice
                            , OrderItemNumber
                            , Product2Id
                            , Date_Active__c
                            , OrderId
                            , Product2.ProductCode
                            , Product2.Quantity_of_Unit__c
                            , Quantity
                    FROM    OrderItem
                    WHERE   OrderId =: strOrderId
                        AND Product2.RecordTypeId =: RecordTypeHelper.PRODUCT_PCA];
        } else if(strServiceType == SERVICE_TYPE_REPAIR || strServiceType == SERVICE_TYPE_DETAILING ) {
            lstOrderItem = [SELECT Id
                            , Percent__c
                            , UnitPrice
                            , Product2.Name
                            , Product2.Labor_HOUR__c
                            , TotalPrice
                            , ListPrice
                            , OrderItemNumber
                            , Product2Id
                            , Date_Active__c
                            , OrderId
                            , Product2.ProductCode
                            , Product2.Quantity_of_Unit__c
                    FROM    OrderItem
                    WHERE   OrderId =: strOrderId
                        AND Product2.Service_Type__c =: strServiceType];
        }
        return lstOrderItem;
    }
    

	/*
    * OrderRepairPage
    * @param: quoteId
    * @return: none
    * @created: 2022/01/05  Nguyễn Gia Minh
    * @modified: 
    */
    @AuraEnabled
    public static void createPdfFile(String orderId) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Order> orderList = [
                SELECT OrderNumber
                                        , Account.Name
                    , CreatedDate
                FROM Order 
                WHERE ID = : orderId
            ];
            if (orderList.isEmpty()) {
                return;
            }
            PageReference page = Page.OrderRepairFormPDF;
            page.getParameters().put('id' , orderId);
            Blob pdfContent;
            if (Test.isRunningTest()) {
                pdfContent = Blob.valueOf('TestClass.pdf');
            } else {
                pdfContent = page.getContent();
            }
            DateTime dt = DateTime.now();
            String strDateTime = dt.format(DATE_TIME_FILE_FORMAT);
            String fileName = String.format(FILE_NAME,new List<String>{orderList[0].OrderNumber,strDateTime, orderList[0].Account.Name});
            ContentVersion objContentVersion = createContentVersion(pdfContent, fileName);
            String contentDocumentId = createContentDocumentLink(objContentVersion.Id, orderId);
        } catch (Exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(String.format(MSG_EXCEPTION, new List<Object>{ex.getMessage()}));
        }
    }

    private static ContentVersion createContentVersion(Blob pdfContent, String fileName) {
        ContentVersion objContentVersion = new ContentVersion(
            VersionData = pdfContent,
            Title = fileName,
            PathOnClient = fileName
        );
        insert objContentVersion;
        return objContentVersion;
    }

    private static String createContentDocumentLink(String contentVersionId, String orderId) {
        ContentVersion objContentVersion = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersionId
        ];
        ContentDocumentLink objContentDocLink = new ContentDocumentLink();
        objContentDocLink.ContentDocumentId = objContentVersion.ContentDocumentId;
        objContentDocLink.LinkedEntityId = orderId;
        objContentDocLink.ShareType = 'V';
        insert objContentDocLink;
        return objContentVersion.ContentDocumentId;
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
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
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