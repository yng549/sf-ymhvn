public class BtnMappingEmployeeController {
	@AuraEnabled
    public static ApiResponse startMapping(string recordId)
    {
        ApiResponse api = new ApiResponse();
        
        String recordTypeContactEmployee = RecordTypeHelper.CONTACT_EMPLOYEE;
        
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
        system.debug('From Date : '+ fromDate);
        system.debug('To Date : '+ toDate);
        
        // Monthly KPI Employee
        Map<String, Schema.SObjectField> employeeSelectFieldMap = Monthly_KPI_Employee__c.sObjectType.getDescribe().fields.getMap();
        List<string> employeeSelectFields = new List<String>(employeeSelectFieldMap.keySet());                
        employeeSelectFields.add('KPI_Category_Management__r.Role__c');
        String employeeSoql = 'SELECT ' + String.join(employeeSelectFields, ',');
        employeeSoql += ' FROM Monthly_KPI_Employee__c';
        employeeSoql += ' WHERE Monthly_KPI__c =: monthlyId'; 
        List<Monthly_KPI_Employee__c> listEmployee = Database.query(employeeSoql); 
        List<String> listContactId = new List<String>();
        Map<String,Monthly_KPI_Employee__c> mapEmployee = new Map<String,Monthly_KPI_Employee__c>();
        for(Monthly_KPI_Employee__c e : listEmployee)
        {
            listContactId.add(e.Employee__c);
            mapEmployee.put(e.Employee__c,e);
        } 
        
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
        system.debug(listContact);
        
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
        
        List<Monthly_KPI_Employee__c> listUpdateEmployee = new List<Monthly_KPI_Employee__c>();
        for(Monthly_KPI_Employee__c e : listEmployee)
        {
			if(e.Employee__c != null)
            {
                if(mapManagerId.containsKey(e.Employee__c))
                {
                    String managerId = mapManagerId.get(e.Employee__c);
                    if(mapEmployee.containsKey(managerId))
                    {
                        Monthly_KPI_Employee__c manager = mapEmployee.get(managerId);
                        e.Manager__c = manager.Id;
                        listUpdateEmployee.add(e);
                    }
                }
            }
        }
        
        if(!listUpdateEmployee.isEmpty())
        {
            update listUpdateEmployee;
            api.success = true;
            api.result = 'Mapping success';
        }
        else
        {
            api.result = 'No record update';
        }
        
        return api;
    }
}