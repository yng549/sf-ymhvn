public  without sharing class RecordTypeHelper {
    /*
     * Sales Report DO 
     */  
    public static final String TARGETRDO = Schema.SObjectType.Sales_Report__c.getRecordTypeInfosByDeveloperName()
        .get('Target')
        .getRecordTypeId();
    public static final String ACCTARGETRDO = Schema.SObjectType.Sales_Report__c.getRecordTypeInfosByDeveloperName()
        .get('Acc_Target')
        .getRecordTypeId();
    public static final String RESULTRDO = Schema.SObjectType.Sales_Report__c.getRecordTypeInfosByDeveloperName()
        .get('Result')
        .getRecordTypeId();
    public static final String ACCRESULTRDO = Schema.SObjectType.Sales_Report__c.getRecordTypeInfosByDeveloperName()
        .get('Acc_Result')
        .getRecordTypeId();
    public static final String STOCKRDO = Schema.SObjectType.Sales_Report__c.getRecordTypeInfosByDeveloperName()
        .get('Stock')
        .getRecordTypeId();
    public static final String TURNRDO = Schema.SObjectType.Sales_Report__c.getRecordTypeInfosByDeveloperName()
        .get('Turn')
        .getRecordTypeId();
	public static final String DEPOSITRDO = Schema.SObjectType.Sales_Report__c.getRecordTypeInfosByDeveloperName()
        .get('Deposit')
        .getRecordTypeId();
    
    public static final String PROMOTIONVOUCHER = Schema.SObjectType.Promotion_Item__c.getRecordTypeInfosByDeveloperName()
        .get('Promotion_Voucher')
        .getRecordTypeId();
    public static final String PROMOTIONITEMDISCOUNT = Schema.SObjectType.Promotion_Item__c.getRecordTypeInfosByDeveloperName()
        .get('Discount')
        .getRecordTypeId();
    public static final String PROMOTIONITEMDISCOUNTAM = Schema.SObjectType.Promotion_Item__c.getRecordTypeInfosByDeveloperName()
        .get('Discount_Amount')
        .getRecordTypeId();
    public static final String PROMOTIONDEFAULT = Schema.SObjectType.Promotion__c.getRecordTypeInfosByDeveloperName()
        .get('Default')
        .getRecordTypeId();
    public static final String PROMOTIONSTANDARD = Schema.SObjectType.Promotion__c.getRecordTypeInfosByDeveloperName()
        .get('Standard')
        .getRecordTypeId();
    // #region ownerShipping
    public static final String CRMOWNERSHIP = Schema.SObjectType.OwnerShip__c.getRecordTypeInfosByDeveloperName()
        .get('CRM')
        .getRecordTypeId();
    public static final String DMSOWNERSHIP = Schema.SObjectType.OwnerShip__c.getRecordTypeInfosByDeveloperName()
        .get('DMS')
        .getRecordTypeId();
    // #region Junction Service request and product
    public static final String JOB = Schema.SObjectType.Job_Part_Detail__c.getRecordTypeInfosByDeveloperName()
        .get('Job')
        .getRecordTypeId();
    public static final String TASK_LEAD = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
        .get('Lead')
        .getRecordTypeId();
    public static final String TASK_ORDER = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
        .get('Order')
        .getRecordTypeId();
    
    public static final String TASK_OPPORTUNITY = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
        .get('Opportunity')
        .getRecordTypeId();
    public static final String TASK_AFTERSALE = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
        .get('After_Sale')
        .getRecordTypeId();
    
    public static final String PART = Schema.SObjectType.Job_Part_Detail__c.getRecordTypeInfosByDeveloperName()
        .get('Part')
        .getRecordTypeId();
    // #region Service request
    public static final String COUPON = Schema.SObjectType.Service_Request__c.getRecordTypeInfosByDeveloperName()
        .get('Service_Request_Free_Coupon')
        .getRecordTypeId();
    public static final String WARRANTY = Schema.SObjectType.Service_Request__c.getRecordTypeInfosByDeveloperName()
        .get('Service_Request_Warranty')
        .getRecordTypeId();
    // #region Campaign
    public static final String CAMPAIGNRECALL = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName()
        .get('Recall')
        .getRecordTypeId();
    // #region Product
    public static final String SV_JOB = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName()
        .get('Service_Jobs')
        .getRecordTypeId();
    public static final String PRODUCT_PCA = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName()
        .get('PCA')
        .getRecordTypeId();
   public static final String PRODUCT_MODEL = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName()
        .get('Bike')
        .getRecordTypeId();
    public static final String PRODUCT_SERVICE_PACKAGE = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName()
        .get('Service_package')
        .getRecordTypeId();
    // #region Product Campaign
    
    public static final String RECALL_PM = Schema.SObjectType.Product_Campaign__c.getRecordTypeInfosByDeveloperName()
        .get('Recall')
        .getRecordTypeId();
    public static final String VOUCHERDISCOUNT_PM = Schema.SObjectType.Product_Campaign__c.getRecordTypeInfosByDeveloperName()
        .get('Voucher_Up_to_Discount')
        .getRecordTypeId();
    public static final String VOUCHERGIFT_PM = Schema.SObjectType.Product_Campaign__c.getRecordTypeInfosByDeveloperName()
        .get('Voucher_Gift')
        .getRecordTypeId();
    // #region Sympton condition
    public static final String SYMPTON = Schema.SObjectType.Symptom_Condition__c.getRecordTypeInfosByDeveloperName()
        .get('Symptom')
        .getRecordTypeId();
    public static final String CONDITION = Schema.SObjectType.Symptom_Condition__c.getRecordTypeInfosByDeveloperName()
        .get('Condition')
        .getRecordTypeId();
    
    // START Opportunity
    public static final String OPPORTUNITY_BIKE = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Bike')
        .getRecordTypeId();
    public static final String OPPORTUNITY_PCA = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('PCA')
        .getRecordTypeId();
    public static final String CAMPAIGN_RECALL = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName()
        .get('Recall')
        .getRecordTypeId();
    //END OPPORTUNITY
    
    
    // START ORDER
    public static final String ORDER_RECALL = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('Recall_Service')
        .getRecordTypeId();
    public static final String ORDER_PCA = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('PCA')
        .getRecordTypeId();
    public static final String ORDER_SERVICE_ORDER = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('External_Service')
        .getRecordTypeId();
    public static final String ORDER_BIKE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('Bike')
        .getRecordTypeId();
    public static final String ORDER_FREE_COUPON = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('Free_Coupon')
        .getRecordTypeId();
    public static final String ORDER_FREE_SERVICE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('Free_Service_Order')
        .getRecordTypeId();
    public static final String ORDER_SERVICE_PACKAGE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('Service_Package')
        .getRecordTypeId();
    public static final String ORDER_WARRANTY = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('Warranty')
        .getRecordTypeId();
    public static final String ORDER_INTERNAL_SERVICE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('Internal_Service')
        .getRecordTypeId();
    public static final String ORDER_PROFOMAR_ORDER = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('Profomar_Order')
        .getRecordTypeId();
    public static final String ORDER_QUICK_SERVICE = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('Quick_Service_Order')
        .getRecordTypeId();
    public static final String ORDER_APPRAISAL = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('Appraisal')
        .getRecordTypeId();
    public static final String ORDER_INSTALLATION = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
        .get('Installation')
        .getRecordTypeId();
     
    // END ORDER
    
    public static final String VOUCHER_CASH = Schema.SObjectType.Voucher__c.getRecordTypeInfosByDeveloperName()
        .get('Voucher_Cash')
        .getRecordTypeId();
    public static final String VOUCHER_GIFT = Schema.SObjectType.Voucher__c.getRecordTypeInfosByDeveloperName()
        .get('Voucher_Gift')
        .getRecordTypeId();
    public static final String VOUCHER_UPTODISCOUNT = Schema.SObjectType.Voucher__c.getRecordTypeInfosByDeveloperName()
        .get('Voucher_Up_To_Discount')
        .getRecordTypeId();
    public static final String VOUCHER_NEW_BIKE = Schema.SObjectType.Voucher__c.getRecordTypeInfosByDeveloperName()
        .get('Voucher_New_Bike')
        .getRecordTypeId();
    public static final String ACCOUNT_CUSTOMER = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Customer')
        .getRecordTypeId();
    public static final String ACCOUNT_BRANCH = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Branch') 
        .getRecordTypeId();
    public static final String ACCOUNT_DODL = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('DODLR')
        .getRecordTypeId();
    public static final String ACCOUNT_SUPPLIER = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Supplier')
        .getRecordTypeId();
    public static final String FOLLOW_FAIL_LEAD = Schema.SObjectType.Follow_Fail__c.getRecordTypeInfosByDeveloperName()
        .get('Follow_Fail_Lead')
        .getRecordTypeId();
    
    public static final String FOLLOW_FAIL_ACCOUNT = Schema.SObjectType.Follow_Fail__c.getRecordTypeInfosByDeveloperName()
        .get('Follow_Fail_Account')
        .getRecordTypeId();

	public static final String FOLLOW_LEAD = Schema.SObjectType.Follow_Fail__c.getRecordTypeInfosByDeveloperName()
        .get('Follow_Fail_Lead')
        .getRecordTypeId();
    
    public static final String FOLLOWFAIL_AFTERSALE = Schema.SObjectType.Follow_Fail__c.getRecordTypeInfosByDeveloperName()
        .get('After_Sale')
        .getRecordTypeId();
    
    public static final String FOLLOWFAIL_ORDER = Schema.SObjectType.Follow_Fail__c.getRecordTypeInfosByDeveloperName()
        .get('Follow_Fail_Order')
        .getRecordTypeId();
    
    public static final String ORDER_ACCOUNT_BIKE = Schema.SObjectType.Order_Account__c.getRecordTypeInfosByDeveloperName()
        .get('After_Sale_Bike')
        .getRecordTypeId();
    public static final String ORDER_ACCOUNT_PCA = Schema.SObjectType.Order_Account__c.getRecordTypeInfosByDeveloperName()
        .get('After_Sales_PCA')
        .getRecordTypeId();
    public static final String ORDER_ACCOUNT_SERVICE = Schema.SObjectType.Order_Account__c.getRecordTypeInfosByDeveloperName()
        .get('Service')
        .getRecordTypeId();
    public static final String SERVICE_PACKAGE_PRODUCT =  Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName()
        .get('Service_package')
        .getRecordTypeId();
    // #endregion
    
    // Contact
    public static final String CONTACT = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
        .get('Contact')
        .getRecordTypeId();
    public static final String CONTACT_EMPLOYEE =  Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
        .get('Employee')
        .getRecordTypeId();
    // #endregion   
    
    // Quote
    public static final String QUOTE_SALES = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName()
        .get('Sales')
        .getRecordTypeId();
    public static final String QUOTE_SALES_BIKE = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName()
        .get('Sales_Bike')
        .getRecordTypeId();
    public static final String QUOTE_TRADE_IN = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName()
        .get('Trade_in')
        .getRecordTypeId();
    // #endregion
    
    // Contract Information
    public static final String CONTRACT_INFORMATION_PERSON = Schema.SObjectType.Contract_Information__c.getRecordTypeInfosByDeveloperName()
        .get('Person')
        .getRecordTypeId();
    
    public static final String CONTRACT_INFORMATION_CORPORATE = Schema.SObjectType.Contract_Information__c.getRecordTypeInfosByDeveloperName()
        .get('Corporate')
        .getRecordTypeId();
    // 
    
    // Monthly Task
    public static final String MONTHLY_CONTENT_CREATION = Schema.SObjectType.Monthly_Task__c.getRecordTypeInfosByDeveloperName()
        .get('Content_Creation')
        .getRecordTypeId();
    public static final String MONTHLY_EVENT = Schema.SObjectType.Monthly_Task__c.getRecordTypeInfosByDeveloperName()
        .get('Event')
        .getRecordTypeId();
    public static final String MONTHLY_SHOWROOM = Schema.SObjectType.Monthly_Task__c.getRecordTypeInfosByDeveloperName()
        .get('Showroom_Monitoring')
        .getRecordTypeId();
    public static final String MONTHLY_TRAINING = Schema.SObjectType.Monthly_Task__c.getRecordTypeInfosByDeveloperName()
        .get('Training_Section')
        .getRecordTypeId();
    //  
   
}