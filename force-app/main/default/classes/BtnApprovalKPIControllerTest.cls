@isTest
public class BtnApprovalKPIControllerTest {
	@isTest
    public static void test()
    {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Name = 'Sales Consultant';
        category.Role__c = 'Sales Consultant';
        insert category;
        
        KPI_Category_Management__c category2 = new KPI_Category_Management__c();
        category2.Name = 'Sales Supevisor';
        category2.Role__c = 'Sales Supevisor';
        insert category2;
        
        KPI_Category_Management__c category3 = new KPI_Category_Management__c();
        category3.Name = 'Sales AM/Manager';
        category3.Role__c = 'Sales AM/Manager';
        insert category3;
        
        KPI_Category_Management__c category4 = new KPI_Category_Management__c();
        category4.Name = 'Service Consultant';
        category4.Role__c = 'Service Consultant';
        insert category4;
        
        KPI_Category_Management__c category5 = new KPI_Category_Management__c();
        category5.Name = 'Service Technician';
        category5.Role__c = 'Service Technician';
        insert category5;
        
        KPI_Category_Management__c category6 = new KPI_Category_Management__c();
        category6.Name = 'Service AM/Sup';
        category6.Role__c = 'Service AM/Sup';
        insert category6;
        
        KPI_Category_Management__c category7 = new KPI_Category_Management__c();
        category7.Name = 'PCA Sales Consultant';
        category7.Role__c = 'PCA Sales Consultant';
        insert category7;
        
        KPI_Category_Management__c category8 = new KPI_Category_Management__c();
        category8.Name = 'PCA Supervisor';
        category8.Role__c = 'PCA Supervisor';
        insert category8;
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        insert employee;
        
        Monthly_KPI_Employee__c employee2 = new Monthly_KPI_Employee__c();
        employee2.Monthly_KPI__c = month.Id;
        employee2.KPI_Category_Management__c = category2.Id;
        insert employee2;
        
        Monthly_KPI_Employee__c employee3 = new Monthly_KPI_Employee__c();
        employee3.Monthly_KPI__c = month.Id;
        employee3.KPI_Category_Management__c = category3.Id;
        insert employee3;
        
        Monthly_KPI_Employee__c employee4 = new Monthly_KPI_Employee__c();
        employee4.Monthly_KPI__c = month.Id;
        employee4.KPI_Category_Management__c = category4.Id;
        insert employee4;
        
        Monthly_KPI_Employee__c employee5 = new Monthly_KPI_Employee__c();
        employee5.Monthly_KPI__c = month.Id;
        employee5.KPI_Category_Management__c = category5.Id;
        insert employee5;
        
        Monthly_KPI_Employee__c employee6 = new Monthly_KPI_Employee__c();
        employee6.Monthly_KPI__c = month.Id;
        employee6.KPI_Category_Management__c = category6.Id;
        insert employee6;
        
        Monthly_KPI_Employee__c employee7 = new Monthly_KPI_Employee__c();
        employee7.Monthly_KPI__c = month.Id;
        employee7.KPI_Category_Management__c = category7.Id;
        insert employee7;
        
        Monthly_KPI_Employee__c employee8 = new Monthly_KPI_Employee__c();
        employee8.Monthly_KPI__c = month.Id;
        employee8.KPI_Category_Management__c = category8.Id;
        insert employee8;
        
        List<Monthly_KPI_Employee__c> listCon = new List<Monthly_KPI_Employee__c>();
        
        List<Monthly_KPI_Employee__c> listService = new List<Monthly_KPI_Employee__c>();
        
        BtnApprovalKPIController.SuperData superData1 = new BtnApprovalKPIController.SuperData();
        
        
        BtnApprovalKPIController.getData(Date.today().month(),Date.today().year());
        BtnApprovalKPIController.saveDataKPI(employee3, null, employee6, listCon, listService, null);
        
    }
}