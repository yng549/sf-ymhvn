public class MonthlyKPIEmployeeController {
    @AuraEnabled 
    public static ApiResponse getDODL()
    {
        system.debug('getDODL');
        ApiResponse api = new ApiResponse();
        List<Account> listAcc = [Select Id,Name 
                                 from Account
                                 where RecordTypeId =: RecordTypeHelper.ACCOUNT_DODL];
        
        /*List<Map<String,String>> listDodl = new List<Map<string,String>>();
        for(Account acc : listAcc)
        {
            Map<String,String> mapDodl = new Map<String,String>();
            mapDodl.put('label',acc.Name);
            mapDodl.put('value',acc.Id);
            listDodl.add(mapDodl);
        }
        system.debug(listDodl);*/
        
        api.success = true;
        api.result = listAcc;
        return api;
    }
      
    @AuraEnabled
	public static ApiResponse getData(Integer selectedMonth,Integer selectedYear,String selectedTeam,String selectedDODL)
    {
        
        ApiResponse api = new ApiResponse();     
        
        Map<String, Schema.SObjectField> monthlyFieldMap = Monthly_KPI__c.sObjectType.getDescribe().fields.getMap();
        List<string> monthlySelectFields = new List<String>(monthlyFieldMap.keySet());      
        String monthlySoql = 'SELECT ' + String.join(monthlySelectFields, ',');
        monthlySoql += ' FROM Monthly_KPI__c';
        monthlySoql += ' WHERE Month__c =: selectedMonth AND Year__c =: selectedYear AND DO_DL__c =: selectedDODL LIMIT 1'; 
        List<Monthly_KPI__c> listMonthly = Database.query(monthlySoql);       
        if(listMonthly.isEmpty())
        {
            api.error = 'KPI do not exist.Please choose right date';
            return api;
        }
        String monthlyId = listMonthly[0].Id;
        
        Map<String, Schema.SObjectField> employeeFieldMap = Monthly_KPI_Employee__c.sObjectType.getDescribe().fields.getMap();
        List<string> employeeSelectFields = new List<String>(employeeFieldMap.keySet());
        employeeSelectFields.add('Employee__r.Name');
        employeeSelectFields.add('Employee__r.Staff_Code__c');
        employeeSelectFields.add('Employee__r.Manager__c');
        employeeSelectFields.add('KPI_Category_Management__r.Name');       
        String employeeSoql = 'SELECT ' + String.join(employeeSelectFields, ',');
        employeeSoql += ' FROM Monthly_KPI_Employee__c';
        employeeSoql += ' WHERE Monthly_KPI__c =: monthlyId'; 
        if(selectedTeam != 'All')
        {
            employeeSoql += ' AND Team__c =: selectedTeam';
        }
        List<Monthly_KPI_Employee__c> listEmployee = Database.query(employeeSoql);
        
		if(!listEmployee.isEmpty())
        {
            api.result = listEmployee; 
            api.success = true;  
        }
        else
        {
            api.error = 'No Employee Record Exist';
        }
        
        return api;
    }
}