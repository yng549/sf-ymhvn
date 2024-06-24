@isTest
public class BtnMappingEmployeeControllerTest {
	@isTest
    public static void test()
    {
        Contact contact1 = new Contact();
        contact1.RecordTypeId = RecordTypeHelper.CONTACT_EMPLOYEE;
        contact1.LastName = 'test';
        insert contact1;
        
        Contact contact2 = new Contact();
        contact2.RecordTypeId = RecordTypeHelper.CONTACT_EMPLOYEE;
        contact2.LastName = 'test';
        contact2.Manager__c = contact1.Id;
        insert contact2;
        
        KPI_Category_Management__c category2 = new KPI_Category_Management__c();
        category2.Name = '	Sales Supevisor';
        category2.Role__c = '	Sales Supevisor';
        insert category2;
        
        KPI_Category_Management__c category = new KPI_Category_Management__c();
        category.Name = 'Sales Consultant';
        category.Role__c = 'Sales Consultant';
        insert category;
        
        Monthly_KPI__c month = new Monthly_KPI__c();
        month.Month__c = Date.today().month();
        month.Year__c = Date.today().year();
        insert month;
        
        Monthly_KPI_Employee__c employee = new Monthly_KPI_Employee__c();
        employee.Monthly_KPI__c = month.Id;
        employee.KPI_Category_Management__c = category.Id;
        employee.Employee__c = contact2.Id;
        insert employee;
        
        Monthly_KPI_Employee__c employee2 = new Monthly_KPI_Employee__c();
        employee2.Monthly_KPI__c = month.Id;
        employee2.KPI_Category_Management__c = category2.Id;
        employee2.Employee__c = contact1.Id;
        insert employee2;
        
        BtnMappingEmployeeController.startMapping(month.Id);
    }
}