public class BtnCreateMonthlyTaskController {
	@AuraEnabled
    public static ApiResponse createMonthlyTask(String recordId)
    {
        ApiResponse api = new ApiResponse();        
        system.debug(recordId);
        
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
        
        Integer thisMonth =  Integer.valueOf(monthly.Month__c);
        Integer thisYear = Integer.valueOf(monthly.Year__c); 
        
        if(monthly.Created_Monthly_Task__c == false)
        {
            monthly.Created_Monthly_Task__c = true;
            
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
            List<String> listContactId = new List<String>();
            for(Monthly_KPI_Employee__c e : listEmployee)
            {
                listContactId.add(e.Employee__c);
            }
            
            Map<String,List<Monthly_KPI_Employee__c>> mapSalesConsultant = new Map<String,List<Monthly_KPI_Employee__c>>();
            List<Monthly_KPI_Employee__c> listSalesChildForAM = new List<Monthly_KPI_Employee__c>();
            for(Monthly_KPI_Employee__c c : listEmployee)
            {
                if(c.KPI_Category_Management__r.Role__c == 'Sales Consultant')
                {
                    if(!mapSalesConsultant.containsKey(c.Manager__c))
                    {
                        mapSalesConsultant.put(c.Manager__c,new List<Monthly_KPI_Employee__c>());
                    }
                    mapSalesConsultant.get(c.Manager__c).add(c);
                    
                    listSalesChildForAM.add(c);
                }
            }
            
            
            List<Monthly_Task__c> listNewTask = new List<Monthly_Task__c>();
            for(Monthly_KPI_Employee__c c : listEmployee)
            {
                if(c.KPI_Category_Management__r.Role__c == 'Sales Consultant')
                {
                    // Rule 5               
                    if(c.KPI_Rule_5_Target__c > 0)
                    {
                        for(Integer i = 0; i < c.KPI_Rule_5_Target__c ; i ++)
                        {
                            Monthly_Task__c t = new Monthly_Task__c();
                            t.Name = 'Content Creation tháng '+thisMonth;
                            t.RecordTypeId = RecordTypeHelper.MONTHLY_CONTENT_CREATION;
                            t.Contact__c = c.Employee__c;
                            listNewTask.add(t);
                        }
                    }
                }
                else if(c.KPI_Category_Management__r.Role__c == 'Sales Supevisor')
                {
                    // Rule 2,3,4,6    
                    if(c.KPI_Rule_2_Target__c > 0)
                    {        
                        for(Integer i = 0; i < c.KPI_Rule_2_Target__c ; i ++)
                        {
                            Monthly_Task__c t = new Monthly_Task__c();
                            t.Name = 'Training tháng '+thisMonth;
                            t.RecordTypeId = RecordTypeHelper.MONTHLY_TRAINING;
                            t.Contact__c = c.Employee__c;
                            listNewTask.add(t);
                        }                
                    }
                    if(c.KPI_Rule_3_Target__c > 0)
                    {
                        for(Integer i = 0; i < c.KPI_Rule_3_Target__c ; i ++)
                        {
                            Monthly_Task__c t = new Monthly_Task__c();
                            t.Name = 'Event tháng '+thisMonth;
                            t.RecordTypeId = RecordTypeHelper.MONTHLY_EVENT;
                            t.Contact__c = c.Employee__c;
                            listNewTask.add(t);
                        }
                    }
                    if(c.KPI_Rule_4_Target__c > 0)
                    {
                        for(Integer i = 0; i < c.KPI_Rule_4_Target__c ; i ++)
                        {
                            Monthly_Task__c t = new Monthly_Task__c();
                            t.Name = 'Showroom tháng '+thisMonth;
                            t.RecordTypeId = RecordTypeHelper.MONTHLY_SHOWROOM;
                            t.Contact__c = c.Employee__c;
                            listNewTask.add(t);
                        }
                    }
                    if(c.KPI_Rule_6_Target__c > 0)
                    {
                        if(mapSalesConsultant.containsKey(c.Id))
                        {
                            List<Monthly_KPI_Employee__c> listChild = mapSalesConsultant.get(c.Id);
                            Decimal contentTarget = c.KPI_Rule_6_Target__c;
                            for(Monthly_KPI_Employee__c child : listChild)
                            {
                                contentTarget -= child.KPI_Rule_5_Target__c;
                            }

                            if(contentTarget > 0)
                            {
                                for(Decimal i = 0; i < contentTarget ; i ++)
                                {
                                    Monthly_Task__c t = new Monthly_Task__c();
                                    t.Name = 'Content Creation tháng '+thisMonth;
                                    t.RecordTypeId = RecordTypeHelper.MONTHLY_CONTENT_CREATION;
                                    t.Contact__c = c.Employee__c;
                                    listNewTask.add(t);
                                }
                            }                           
                        } 
                    }
                }
                else if(c.KPI_Category_Management__r.Role__c == 'Sales AM/Manager')
                {
                    // Rule 3,6
                    if(c.KPI_Rule_3_Target__c > 0)
                    {
                        for(Integer i = 0; i < c.KPI_Rule_3_Target__c ; i ++)
                        {
                            Monthly_Task__c t = new Monthly_Task__c();
                            t.Name = 'Training tháng '+thisMonth;
                            t.RecordTypeId = RecordTypeHelper.MONTHLY_TRAINING;
                            t.Contact__c = c.Employee__c;
                            listNewTask.add(t);
                        }
                    }
                    /*if(c.KPI_Rule_6_Target__c > 0)
                    {
                    for(Integer i = 0; i < c.KPI_Rule_6_Target__c ; i ++)
                    {
                    Monthly_Task__c t = new Monthly_Task__c();
                    t.RecordTypeId = RecordTypeHelper.MONTHLY_CONTENT_CREATION;
                    t.Contact__c = c.Employee__c;
                    listNewTask.add(t);
                    }
                    }*/
                }
                else if(c.KPI_Category_Management__r.Role__c == 'Service Consultant')
                {
                    // Rule 7
                    if(c.KPI_Rule_7_Target__c > 0)
                    {
                        for(Integer i = 0; i < c.KPI_Rule_7_Target__c ; i ++)
                        {
                            Monthly_Task__c t = new Monthly_Task__c();
                            t.Name = 'Content Creation tháng '+thisMonth;
                            t.RecordTypeId = RecordTypeHelper.MONTHLY_CONTENT_CREATION;
                            t.Contact__c = c.Employee__c;
                            listNewTask.add(t);
                        }
                    }
                }
                else if(c.KPI_Category_Management__r.Role__c == 'PCA Sales Consultant')
                {
                    // Rule 4   
                    if(c.KPI_Rule_4_Target__c > 0)
                    {
                        for(Integer i = 0; i < c.KPI_Rule_4_Target__c ; i ++)
                        {
                            Monthly_Task__c t = new Monthly_Task__c();
                            t.Name = 'Content Creation tháng '+thisMonth;
                            t.RecordTypeId = RecordTypeHelper.MONTHLY_CONTENT_CREATION;
                            t.Contact__c = c.Employee__c;
                            listNewTask.add(t);
                        }
                    }
                }
            }
            
            api.success = true;
            api.result = 'Created monthly task';
            
            update monthly;
            if(!listNewTask.isEmpty())
            {
				insert listNewTask;
            } 
        }
        else
        {
            api.error = 'This monthly kpi already created task';
        }
        
        
        
        return api;
    }
}