@isTest
public class MonthlyKPIEmployeeDetailControllerTest {
	@isTest
    public static void testSale()
    {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Sales Consultant';
        insert category;
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        employee.KPI_Rule_1_Target__c = 1;
        employee.KPI_Rule_1_Value__c = 1;
        employee.KPI_Rule_1_Percent__c = 1;
        employee.KPI_Rule_2_Target__c = 1;
        employee.KPI_Rule_2_Value__c = 1;
        employee.KPI_Rule_2_Percent__c = 1;
        employee.KPI_Rule_2_Max_Percent__c = 1;
        employee.KPI_Rule_3_Target__c = 1;
        employee.KPI_Rule_3_Value__c = 1;
        employee.KPI_Rule_3_Percent__c = 1;
        employee.KPI_Rule_3_Max_Percent__c = 1;
        employee.KPI_Rule_4_Target__c = 1;
        employee.KPI_Rule_4_Value__c = 1;
        employee.KPI_Rule_4_Percent__c = 1;
        employee.KPI_Rule_4_Max_Percent__c = 1;
        employee.KPI_Rule_5_Target__c = 1;
        employee.KPI_Rule_5_Value__c = 1;
        employee.KPI_Rule_5_Percent__c = 1;
        employee.KPI_Rule_5_Max_Percent__c = 1;
        employee.KPI_Rule_6_Target__c = 1;
        employee.KPI_Rule_6_Value__c = 1;
        employee.KPI_Rule_6_Percent__c = 1;
        employee.KPI_Rule_6_Max_Percent__c = 1;
        employee.KPI_Rule_7_Target__c = 1;
        employee.KPI_Rule_7_Value__c = 1;
        employee.KPI_Rule_7_Percent__c = 1;
        employee.KPI_Rule_7_Max_Percent__c = 1;
        insert employee;
        
        Monthly_KPI_Employee_Detail__c detail = new Monthly_KPI_Employee_Detail__c();
        detail.Monthly_KPI_Employee__c = employee.Id;
        detail.Commission_Type__c = 'Promotion Out';
        insert detail;
        
        MonthlyKPIEmployeeDetailController.getData(employee.Id);
        MonthlyKPIEmployeeDetailController.getDataDetail(employee.Id, '1');
        MonthlyKPIEmployeeDetailController.getCommissionDataDetail(detail.Id, 'Promotion Out');
    }
    @isTest
    public static void testSaleAM()
    {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Sales AM/Manager';
        insert category;
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        employee.KPI_Rule_1_Target__c = 1;
        employee.KPI_Rule_1_Value__c = 1;
        employee.KPI_Rule_1_Percent__c = 1;
        employee.KPI_Rule_2_Target__c = 1;
        employee.KPI_Rule_2_Value__c = 1;
        employee.KPI_Rule_2_Percent__c = 1;
        employee.KPI_Rule_2_Max_Percent__c = 1;
        employee.KPI_Rule_3_Target__c = 1;
        employee.KPI_Rule_3_Value__c = 1;
        employee.KPI_Rule_3_Percent__c = 1;
        employee.KPI_Rule_3_Max_Percent__c = 1;
        employee.KPI_Rule_4_Target__c = 1;
        employee.KPI_Rule_4_Value__c = 1;
        employee.KPI_Rule_4_Percent__c = 1;
        employee.KPI_Rule_4_Max_Percent__c = 1;
        employee.KPI_Rule_5_Target__c = 1;
        employee.KPI_Rule_5_Value__c = 1;
        employee.KPI_Rule_5_Percent__c = 1;
        employee.KPI_Rule_5_Max_Percent__c = 1;
        employee.KPI_Rule_6_Target__c = 1;
        employee.KPI_Rule_6_Value__c = 1;
        employee.KPI_Rule_6_Percent__c = 1;
        employee.KPI_Rule_6_Max_Percent__c = 1;
        employee.KPI_Rule_7_Target__c = 1;
        employee.KPI_Rule_7_Value__c = 1;
        employee.KPI_Rule_7_Percent__c = 1;
        employee.KPI_Rule_7_Max_Percent__c = 1;
        insert employee;
        
        Monthly_KPI_Employee_Detail__c detail = new Monthly_KPI_Employee_Detail__c();
        detail.Monthly_KPI_Employee__c = employee.Id;
        detail.Commission_Type__c = 'Promotion Out';
        insert detail;
        
        MonthlyKPIEmployeeDetailController.getData(employee.Id);
        MonthlyKPIEmployeeDetailController.getDataDetail(employee.Id, '1');
        MonthlyKPIEmployeeDetailController.getCommissionDataDetail(detail.Id, 'Promotion Out');
    }
    @isTest
    public static void testTech()
    {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Service Technician';
        insert category;
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        employee.KPI_Rule_1_Target__c = 1;
        employee.KPI_Rule_1_Value__c = 1;
        employee.KPI_Rule_1_Percent__c = 1;
        employee.KPI_Rule_2_Target__c = 1;
        employee.KPI_Rule_2_Value__c = 1;
        employee.KPI_Rule_2_Percent__c = 1;
        employee.KPI_Rule_2_Max_Percent__c = 1;
        employee.KPI_Rule_3_Target__c = 1;
        employee.KPI_Rule_3_Value__c = 1;
        employee.KPI_Rule_3_Percent__c = 1;
        employee.KPI_Rule_3_Max_Percent__c = 1;
        employee.KPI_Rule_4_Target__c = 1;
        employee.KPI_Rule_4_Value__c = 1;
        employee.KPI_Rule_4_Percent__c = 1;
        employee.KPI_Rule_4_Max_Percent__c = 1;
        employee.KPI_Rule_5_Target__c = 1;
        employee.KPI_Rule_5_Value__c = 1;
        employee.KPI_Rule_5_Percent__c = 1;
        employee.KPI_Rule_5_Max_Percent__c = 1;
        employee.KPI_Rule_6_Target__c = 1;
        employee.KPI_Rule_6_Value__c = 1;
        employee.KPI_Rule_6_Percent__c = 1;
        employee.KPI_Rule_6_Max_Percent__c = 1;
        employee.KPI_Rule_7_Target__c = 1;
        employee.KPI_Rule_7_Value__c = 1;
        employee.KPI_Rule_7_Percent__c = 1;
        employee.KPI_Rule_7_Max_Percent__c = 1;
        insert employee;
        
        Monthly_KPI_Employee_Detail__c detail = new Monthly_KPI_Employee_Detail__c();
        detail.Monthly_KPI_Employee__c = employee.Id;
        detail.Commission_Type__c = 'Promotion Out';
        insert detail;
        
        MonthlyKPIEmployeeDetailController.getData(employee.Id);
        MonthlyKPIEmployeeDetailController.getDataDetail(employee.Id, '1');
        MonthlyKPIEmployeeDetailController.getCommissionDataDetail(detail.Id, 'Promotion Out');
    }
    @isTest
    public static void testService()
    {
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Role__c = 'Service AM/Sup';
        insert category;
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        employee.KPI_Rule_1_Target__c = 1;
        employee.KPI_Rule_1_Value__c = 1;
        employee.KPI_Rule_1_Percent__c = 1;
        employee.KPI_Rule_2_Target__c = 1;
        employee.KPI_Rule_2_Value__c = 1;
        employee.KPI_Rule_2_Percent__c = 1;
        employee.KPI_Rule_2_Max_Percent__c = 1;
        employee.KPI_Rule_3_Target__c = 1;
        employee.KPI_Rule_3_Value__c = 1;
        employee.KPI_Rule_3_Percent__c = 1;
        employee.KPI_Rule_3_Max_Percent__c = 1;
        employee.KPI_Rule_4_Target__c = 1;
        employee.KPI_Rule_4_Value__c = 1;
        employee.KPI_Rule_4_Percent__c = 1;
        employee.KPI_Rule_4_Max_Percent__c = 1;
        employee.KPI_Rule_5_Target__c = 1;
        employee.KPI_Rule_5_Value__c = 1;
        employee.KPI_Rule_5_Percent__c = 1;
        employee.KPI_Rule_5_Max_Percent__c = 1;
        employee.KPI_Rule_6_Target__c = 1;
        employee.KPI_Rule_6_Value__c = 1;
        employee.KPI_Rule_6_Percent__c = 1;
        employee.KPI_Rule_6_Max_Percent__c = 1;
        employee.KPI_Rule_7_Target__c = 1;
        employee.KPI_Rule_7_Value__c = 1;
        employee.KPI_Rule_7_Percent__c = 1;
        employee.KPI_Rule_7_Max_Percent__c = 1;
        insert employee;
        
        Monthly_KPI_Employee_Detail__c detail = new Monthly_KPI_Employee_Detail__c();
        detail.Monthly_KPI_Employee__c = employee.Id;
        detail.Commission_Type__c = 'Promotion Out';
        insert detail;
        
        MonthlyKPIEmployeeDetailController.getData(employee.Id);
        MonthlyKPIEmployeeDetailController.getDataDetail(employee.Id, '1');
        MonthlyKPIEmployeeDetailController.getCommissionDataDetail(detail.Id, 'Promotion Out');
    }
}