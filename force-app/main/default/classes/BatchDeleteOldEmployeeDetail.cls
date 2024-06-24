global  class BatchDeleteOldEmployeeDetail implements Database.Batchable<sObject> {
    String recordId = '';
    
    
	global BatchDeleteOldEmployeeDetail(String recordId) {
        //this.objectName = 'Monthly_KPI_Employee_Detail__c';
        this.recordId = recordId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) { 
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
        
        // Monthly KPI Employee
        Map<String, Schema.SObjectField> employeeSelectFieldMap = Monthly_KPI_Employee__c.sObjectType.getDescribe().fields.getMap();
        List<string> employeeSelectFields = new List<String>(employeeSelectFieldMap.keySet());                
        employeeSelectFields.add('KPI_Category_Management__r.Role__c');
        employeeSelectFields.add('Employee__r.Staff_Code__c');
            employeeSelectFields.add('Employee__r.Contact_Type__c');
        String employeeSoql = 'SELECT ' + String.join(employeeSelectFields, ',');
        employeeSoql += ' FROM Monthly_KPI_Employee__c';
        employeeSoql += ' WHERE Monthly_KPI__c =: monthlyId'; 
        List<Monthly_KPI_Employee__c> listEmployee = Database.query(employeeSoql); 
        
        Map<String, Schema.SObjectField> employeeDetailSelectFieldMap = Monthly_KPI_Employee_Detail__c.sObjectType.getDescribe().fields.getMap();
        List<string> employeeDetailSelectFields = new List<String>(employeeDetailSelectFieldMap.keySet());                
        String employeeDetailSoql = 'SELECT ' + String.join(employeeDetailSelectFields, ',');
        employeeDetailSoql += ' FROM Monthly_KPI_Employee_Detail__c';
        employeeDetailSoql += ' WHERE Monthly_KPI_Employee__c in: listEmployee'; 
        //List<Monthly_KPI_Employee_Detail__c> listEmployeeDetail = Database.query(employeeDetailSoql); 
        
		return Database.getQueryLocator(employeeDetailSoql);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> records)
    {
        List<Monthly_KPI_Employee_Detail__c> listRecord = (List<Monthly_KPI_Employee_Detail__c>)records;
        
        delete listRecord;
        
        //return listRecord;
    }
    
    global void finish(Database.BatchableContext BC)   
    {
        if(Test.isRunningTest() == false)
        {
           Database.executeBatch(new BatchKPIHelper(recordId,1), 100); 
        }
        
        //KPIHelper.startCalculate(this.recordId);
    }
}