public class TriggerHandlerMonthly {
	public static void isBeforeUpdate( List<Monthly_KPI__c> listNew)
    {
        //Monthly KPI
        Map<String, Schema.SObjectField> monthlyFieldMap = Monthly_KPI__c.sObjectType.getDescribe().fields.getMap();
        List<string> monthlySelectFields = new List<String>(monthlyFieldMap.keySet());                
        String monthlySoql = 'SELECT ' + String.join(monthlySelectFields, ',');
        monthlySoql += ' FROM Monthly_KPI__c';
        monthlySoql += ' WHERE Id in: listNew'; 
        Monthly_KPI__c monthly = Database.query(monthlySoql);
        String monthlyId = monthly.Id;
        Date fromDate = Date.newInstance( Integer.valueOf(monthly.Year__c), Integer.valueOf(monthly.Month__c), 1);
        Date toDate = Date.newInstance( Integer.valueOf(monthly.Year__c), Integer.valueOf(monthly.Month__c) + 1, 1);
        Date fromDate3Month = Date.newInstance( Integer.valueOf(monthly.Year__c), Integer.valueOf(monthly.Month__c) - 2, 1);
        system.debug('From Date : '+ fromDate);
        system.debug('To Date : '+ toDate);
        
        
        // Monthly KPI Employee
        Map<String, Schema.SObjectField> employeeSelectFieldMap = Monthly_KPI_Employee__c.sObjectType.getDescribe().fields.getMap();
        List<string> employeeSelectFields = new List<String>(employeeSelectFieldMap.keySet());                
        employeeSelectFields.add('KPI_Category_Management__r.Role__c');
        employeeSelectFields.add('Employee__r.Staff_Code__c');
        employeeSelectFields.add('Employee__r.Contact_Type__c');
        employeeSelectFields.add('Employee__r.Tech_Role__c');
        String employeeSoql = 'SELECT ' + String.join(employeeSelectFields, ',');
        employeeSoql += ' FROM Monthly_KPI_Employee__c';
        employeeSoql += ' WHERE Monthly_KPI__c =: monthlyId'; 
        List<Monthly_KPI_Employee__c> listEmployee = Database.query(employeeSoql); 
        List<String> listContactId = new List<String>();
        for(Monthly_KPI_Employee__c e : listEmployee)
        {
            e.Is_Lock__c = e.Is_Lock_Formula__c;
        }
        
        if(!listEmployee.isEmpty())
        {
            update listEmployee;
        }
    }
}