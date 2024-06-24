public class MonthlyKPIEmployeeDetailController {
	@AuraEnabled
    public static ApiResponse getData(String recordId)
    {
        ApiResponse api = new ApiResponse();
        if(recordId == null)
        {
            api.error = 'Record id missing';
        }
        
        Map<String,Object> mapData = new Map<String,Object>();
        
        Map<String, Schema.SObjectField> employeeFieldMap = Monthly_KPI_Employee__c.sObjectType.getDescribe().fields.getMap();
        List<string> employeeSelectFields = new List<String>(employeeFieldMap.keySet());
        employeeSelectFields.add('Employee__r.Name');
        employeeSelectFields.add('Employee__r.Staff_Code__c');
        employeeSelectFields.add('Employee__r.Manager__c');
        employeeSelectFields.add('Employee__r.Tech_Role__c');
        employeeSelectFields.add('KPI_Category_Management__r.Name');       
         employeeSelectFields.add('KPI_Category_Management__r.Role__c');
        String employeeSoql = 'SELECT ' + String.join(employeeSelectFields, ',');
        employeeSoql += ' FROM Monthly_KPI_Employee__c';
        employeeSoql += ' WHERE Id =: recordId'; 
        Monthly_KPI_Employee__c employee = Database.query(employeeSoql);
        mapData.put('Employee',employee);
                     
        List<EmployeeDetail> listEmployeeDetail = new List<EmployeeDetail>();
        if(employee.KPI_Category_Management__r.Role__c == 'Service Consultant' ||
          employee.KPI_Category_Management__r.Role__c == 'Service AM/Sup')
        {
            EmployeeDetail eD1 = new EmployeeDetail();
            eD1.Id = '1';
            eD1.RuleName = employee.KPI_Rule_1_Name__c + ' PCA target';
            eD1.Percent = employee.KPI_Rule_1_Percent__c;
            eD1.Target = employee.KPI_Rule_1_Target__c;
            eD1.Value = employee.KPI_Rule_1_Value__c ;
            eD1.ValuePercent = employee.KPI_Rule_1_Value_Percent__c;
            listEmployeeDetail.add(eD1);  
            
            EmployeeDetail eD1B = new EmployeeDetail();
            eD1B.Id = '1B';
            eD1B.RuleName = employee.KPI_Rule_1_Name__c + ' Service revenue';
            eD1B.Percent = employee.KPI_Rule_1_Service_Percent__c;
            eD1B.Target = employee.KPI_Rule_1_Service_Target__c;
            eD1B.Value = employee.KPI_Rule_1_Service_Value__c ;
            eD1B.ValuePercent = employee.KPI_Rule_1_Service_Value_Percent__c;
            listEmployeeDetail.add(eD1B);
        }      
        else
        {            
            EmployeeDetail eD1 = new EmployeeDetail();
            eD1.Id = '1';
            eD1.RuleName = employee.KPI_Rule_1_Name__c;
            eD1.Percent = employee.KPI_Rule_1_Percent__c;
            eD1.Target = employee.KPI_Rule_1_Target__c;
            eD1.Value = employee.KPI_Rule_1_Value__c ;
            eD1.ValuePercent = employee.KPI_Rule_1_Value_Percent__c;          
            listEmployeeDetail.add(eD1);  
        }
        
        EmployeeDetail eD2 = new EmployeeDetail();
        eD2.Id = '2';
        eD2.RuleName = employee.KPI_Rule_2_Name__c;
        eD2.Percent = employee.KPI_Rule_2_Percent__c;
        eD2.Target = employee.KPI_Rule_2_Target__c;
        eD2.Value = employee.KPI_Rule_2_Value__c;
        eD2.ValuePercent = employee.KPI_Rule_2_Value_Percent__c;
        eD2.MaxPercent = employee.KPI_Rule_2_Max_Percent__c;
        listEmployeeDetail.add(eD2);
        
        EmployeeDetail eD3 = new EmployeeDetail();
        eD3.Id = '3';
        eD3.RuleName = employee.KPI_Rule_3_Name__c;
        eD3.Percent = employee.KPI_Rule_3_Percent__c;
        eD3.Target = employee.KPI_Rule_3_Target__c;
        eD3.Value = employee.KPI_Rule_3_Value__c;
        eD3.ValuePercent = employee.KPI_Rule_3_Value_Percent__c;
        eD3.MaxPercent = employee.KPI_Rule_3_Max_Percent__c;
        listEmployeeDetail.add(eD3);
        
        EmployeeDetail eD4 = new EmployeeDetail();
        eD4.Id = '4';
        eD4.RuleName = employee.KPI_Rule_4_Name__c;
        eD4.Percent = employee.KPI_Rule_4_Percent__c;
        eD4.Target = employee.KPI_Rule_4_Target__c;
        eD4.Value = employee.KPI_Rule_4_Value__c;
        eD4.ValuePercent = employee.KPI_Rule_4_Value_Percent__c;
        eD4.MaxPercent = employee.KPI_Rule_4_Max_Percent__c;
        listEmployeeDetail.add(eD4);
        
        EmployeeDetail eD5 = new EmployeeDetail();
        eD5.Id = '5';
        eD5.RuleName = employee.KPI_Rule_5_Name__c;
        eD5.Percent = employee.KPI_Rule_5_Percent__c;
        eD5.Target = employee.KPI_Rule_5_Target__c;
        eD5.Value = employee.KPI_Rule_5_Value__c;
        eD5.ValuePercent = employee.KPI_Rule_5_Value_Percent__c;
        eD5.MaxPercent = employee.KPI_Rule_5_Max_Percent__c;
        if(eD5.RuleName != null)
        {
            listEmployeeDetail.add(eD5);
        }
                
        EmployeeDetail eD6 = new EmployeeDetail();
        eD6.Id = '6';
        eD6.RuleName = employee.KPI_Rule_6_Name__c;
        eD6.Percent = employee.KPI_Rule_6_Percent__c;
        eD6.Target = employee.KPI_Rule_6_Target__c;
        eD6.Value = employee.KPI_Rule_6_Value__c;
        eD6.ValuePercent = employee.KPI_Rule_6_Value_Percent__c;
        eD6.MaxPercent = employee.KPI_Rule_6_Max_Percent__c;  
        if(eD6.RuleName != null)
        {
            listEmployeeDetail.add(eD6);
        }
        
        EmployeeDetail eD7 = new EmployeeDetail();
        eD7.Id = '7';
        eD7.RuleName = employee.KPI_Rule_7_Name__c;
        eD7.Percent = employee.KPI_Rule_7_Percent__c;
        eD7.Target = employee.KPI_Rule_7_Target__c;
        eD7.Value = employee.KPI_Rule_7_Value__c;
        eD7.ValuePercent = employee.KPI_Rule_7_Value_Percent__c;
        eD7.MaxPercent = employee.KPI_Rule_7_Max_Percent__c;
        if(eD7.RuleName != null)
        {
            listEmployeeDetail.add(eD7);
        }
        
        
        mapData.put('EmployeeDetail',listEmployeeDetail);
        
        List<EmployeeCommission> listCommission = new List<EmployeeCommission>();
        if(employee.KPI_Category_Management__r.Role__c == 'Sales Consultant' 
          || employee.KPI_Category_Management__r.Role__c == 'Sales Supevisor' )
        {
            EmployeeCommission commission1 = new EmployeeCommission();
            commission1.Name = 'Promotion In';
            commission1.Value = employee.Promo_In__c;
            listCommission.add(commission1);
            
            EmployeeCommission commission2 = new EmployeeCommission();
            commission2.Name = 'Promotion Out';
            commission2.Value = employee.Promo_Out__c;
            listCommission.add(commission2);
            
            EmployeeCommission commission3 = new EmployeeCommission();
            commission3.Name = 'E-Commerce';
            commission3.Value = employee.E_Commerce__c;
            listCommission.add(commission3);
            
            EmployeeCommission commission4 = new EmployeeCommission();
            commission4.Name = 'Used Bike';
            commission4.Value = employee.Used_Bike__c;
            listCommission.add(commission4);
        }
        else if(employee.KPI_Category_Management__r.Role__c == 'Sales AM/Manager' )
        {
            EmployeeCommission commission1 = new EmployeeCommission();
            commission1.Name = 'Promotion In';
            commission1.Value = employee.Promo_In__c;
            listCommission.add(commission1);
            
            EmployeeCommission commission2 = new EmployeeCommission();
            commission2.Name = 'Promotion Out';
            commission2.Value = employee.Promo_Out__c;
            listCommission.add(commission2);
            
            EmployeeCommission commission3 = new EmployeeCommission();
            commission3.Name = 'E-Commerce';
            commission3.Value = employee.E_Commerce__c;
            listCommission.add(commission3);
            
            EmployeeCommission commission4 = new EmployeeCommission();
            commission4.Name = 'Used Bike';
            commission4.Value = employee.Used_Bike__c;
            listCommission.add(commission4);
        }
        else if(employee.KPI_Category_Management__r.Role__c == 'Service Consultant' ||
                employee.KPI_Category_Management__r.Role__c == 'Service AM/Sup')
        {
            EmployeeCommission commission1 = new EmployeeCommission();
            commission1.Name = 'Hour Sold Revenue';
            commission1.Value = employee.Hour_Sold_Revenue__c;
            listCommission.add(commission1);
            
            EmployeeCommission commission2 = new EmployeeCommission();
            commission2.Name = 'Team Part revenue';
            commission2.Value = employee.Part_Revenue__c;
            listCommission.add(commission2);
            
            EmployeeCommission commission3 = new EmployeeCommission();
            commission3.Name = 'Team A&A revenue';
            commission3.Value = employee.A_A_Revenue__c;
            listCommission.add(commission3);
            
            EmployeeCommission commission4 = new EmployeeCommission();
            commission4.Name = 'Voucher';
            commission4.Value = employee.Voucher__c;
            listCommission.add(commission4);
            
            EmployeeCommission commission5 = new EmployeeCommission();
            commission5.Name = 'Discount';
            commission5.Value = employee.Discount__c;
            listCommission.add(commission5);
        }
        else if(employee.KPI_Category_Management__r.Role__c == 'Service Technician')
        {
            EmployeeCommission commission1 = new EmployeeCommission();
            commission1.Name = 'Hour Sold Revenue';
            commission1.Value = employee.Hour_Sold_Revenue__c;
            listCommission.add(commission1);
            
            EmployeeCommission commission5 = new EmployeeCommission();
            commission5.Name = 'Discount';
            commission5.Value = employee.Discount__c;
            listCommission.add(commission5);
            
            if(employee.Employee__r.Tech_Role__c == 'Chief technician / Detailing expert')
            {
                EmployeeCommission commission2 = new EmployeeCommission();
                commission2.Name = 'Incentive Scheme';
                commission2.Value = employee.Incentive_Scheme__c;
                listCommission.add(commission2);
            }
        }
        else if(employee.KPI_Category_Management__r.Role__c == 'PCA Sales Consultant' ||
                employee.KPI_Category_Management__r.Role__c == 'PCA Supervisor')
        {
            EmployeeCommission commission2 = new EmployeeCommission();
            commission2.Name = 'Part revenue';
            commission2.Value = employee.Part_Revenue__c;
            listCommission.add(commission2);
            
            EmployeeCommission commission3 = new EmployeeCommission();
            commission3.Name = 'A&A revenue';
            commission3.Value = employee.A_A_Revenue__c;
            listCommission.add(commission3);
            
            EmployeeCommission commission4 = new EmployeeCommission();
            commission4.Name = 'Voucher';
            commission4.Value = employee.Voucher__c;
            listCommission.add(commission4);
            
            EmployeeCommission commission5 = new EmployeeCommission();
            commission5.Name = 'Discount';
            commission5.Value = employee.Discount__c;
            listCommission.add(commission5);
        }


        
        mapData.put('Commission',listCommission);
        
        system.debug(mapData);
        
        api.success = true;
        api.result = mapData;
        
        system.debug(api.success);
        
        return api;
    }
    
    @AuraEnabled
    public static ApiResponse getDataDetail(String recordId,String rule)
    {
        ApiResponse api = new ApiResponse();
        if(recordId == null)
        {
            api.error = 'Record id missing';
        }

		system.debug('Get Detail');
        system.debug(recordId);
        system.debug(rule);
        
        Map<String, Schema.SObjectField> eDetailFieldMap = Monthly_KPI_Employee_Detail__c.sObjectType.getDescribe().fields.getMap();
        List<string> eDetailSelectFields = new List<String>(eDetailFieldMap.keySet());      
        String eDetailSoql = 'SELECT ' + String.join(eDetailSelectFields, ',');
        eDetailSoql += ' FROM Monthly_KPI_Employee_Detail__c';
        eDetailSoql += ' WHERE Monthly_KPI_Employee__c =: recordId and Rule__c =: rule';
        List<Monthly_KPI_Employee_Detail__c> listEDetail = Database.query(eDetailSoql);

        system.debug(listEDetail);

        api.success = true;
        api.result = listEDetail;
        
        return api;
    }
    
    @AuraEnabled
    public static ApiResponse getCommissionDataDetail(String recordId,String commissionType)
    {
        ApiResponse api = new ApiResponse();
        if(recordId == null)
        {
            api.error = 'Record id missing';
        }

		system.debug('Get Detail');
        system.debug(recordId);
        system.debug(commissionType);
        
        Map<String, Schema.SObjectField> eDetailFieldMap = Monthly_KPI_Employee_Detail__c.sObjectType.getDescribe().fields.getMap();
        List<string> eDetailSelectFields = new List<String>(eDetailFieldMap.keySet());      
        String eDetailSoql = 'SELECT ' + String.join(eDetailSelectFields, ',');
        eDetailSoql += ' FROM Monthly_KPI_Employee_Detail__c';
        eDetailSoql += ' WHERE Monthly_KPI_Employee__c =: recordId and Commission_Type__c =: commissionType';
        List<Monthly_KPI_Employee_Detail__c> listEDetail = Database.query(eDetailSoql);

        system.debug('List Detail : '+ listEDetail);

        api.success = true;
        api.result = listEDetail;
        
        return api;
    }
    
    public class EmployeeCommission
    {
        @AuraEnabled
        public string Name;
        @AuraEnabled
        public decimal Value;
    }
       
    public Class EmployeeDetail
    {
        @AuraEnabled
        public string Id;
        @AuraEnabled
        public string RuleName;
        @AuraEnabled
        public decimal Percent;
        @AuraEnabled
        public decimal Target;
        @AuraEnabled
        public decimal Value;
        @AuraEnabled
        public decimal ValuePercent;
        @AuraEnabled
        public decimal MaxPercent;
    }
}