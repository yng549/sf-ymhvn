public class BtnApprovalKPIController {
	@AuraEnabled
    public static ApiResponse getData(Integer selectedMonth,Integer selectedYear)
    {
        ApiResponse api = new ApiResponse();
        
        Map<String, Schema.SObjectField> monthlyFieldMap = Monthly_KPI__c.sObjectType.getDescribe().fields.getMap();
        List<string> monthlySelectFields = new List<String>(monthlyFieldMap.keySet());      
        String monthlySoql = 'SELECT ' + String.join(monthlySelectFields, ',');
        monthlySoql += ' FROM Monthly_KPI__c';
        monthlySoql += ' WHERE Month__c =: selectedMonth AND Year__c =: selectedYear LIMIT 1'; 
        Monthly_KPI__c monthly = Database.query(monthlySoql);       
        if(monthly == null)
        {
            api.error = 'KPI do not exist.Please choose right date';
        }
        String monthlyId = monthly.Id;
        
        Map<String, Schema.SObjectField> employeeFieldMap = Monthly_KPI_Employee__c.sObjectType.getDescribe().fields.getMap();
        List<string> employeeSelectFields = new List<String>(employeeFieldMap.keySet());
        employeeSelectFields.add('Employee__r.Name');
        employeeSelectFields.add('Employee__r.Manager__c');
        employeeSelectFields.add('KPI_Category_Management__r.Name');       
        employeeSelectFields.add('KPI_Category_Management__r.Role__c');  
        String employeeSoql = 'SELECT ' + String.join(employeeSelectFields, ',');
        employeeSoql += ' FROM Monthly_KPI_Employee__c';
        employeeSoql += ' WHERE Monthly_KPI__c =: monthlyId'; 
        List<Monthly_KPI_Employee__c> listEmployee = Database.query(employeeSoql);              
        
        Map<String,Object> mapData = new Map<String,Object>();
        //mapData.put('testEmployee',listEmployee);
        //system.debug(mapData);
        
        Map<String,List<Monthly_KPI_Employee__c>> mapSaleChildEmployee = new Map<string,List<Monthly_KPI_Employee__c>>();
        Map<String,List<Monthly_KPI_Employee__c>> mapServiceChildEmployee = new Map<string,List<Monthly_KPI_Employee__c>>();
        Map<String,List<Monthly_KPI_Employee__c>> mapPCAChildEmployee = new Map<string,List<Monthly_KPI_Employee__c>>();
        
        for(Monthly_KPI_Employee__c e : listEmployee)
        {
            if(e.KPI_Category_Management__r.Role__c == 'Sales AM/Manager')
            {
                mapData.put('Sales AM/Manager',e);
            }
            else if(e.KPI_Category_Management__r.Role__c == 'Sales Supevisor')
            {
                if(!mapData.containsKey('Sales Supevisor'))
                {
                    mapData.put('Sales Supevisor',new List<SuperData>());
                }
                List<SuperData> listSuper = (List<SuperData>) mapData.get('Sales Supevisor');
                SuperData s = new SuperData();
                s.superEmployee = e;
                listSuper.add(s);
            }
            else if(e.KPI_Category_Management__r.Role__c == 'Sales Consultant')
            {
                if(!mapSaleChildEmployee.containsKey(e.Manager__c))
                {
                    mapSaleChildEmployee.put(e.Manager__c,new List<Monthly_KPI_Employee__c>());
                }
                mapSaleChildEmployee.get(e.Manager__c).add(e);
            }
            else if(e.KPI_Category_Management__r.Role__c == 'Service AM/Sup')
            {
                mapData.put('Service AM/Sup',e);
            }
            else if(e.KPI_Category_Management__r.Role__c == 'Service Consultant')
            {                
                if(!mapData.containsKey('Service Consultant'))
                {
                    mapData.put('Service Consultant',new List<Monthly_KPI_Employee__c>());
                }
				List<Monthly_KPI_Employee__c> listSC = (List<Monthly_KPI_Employee__c>) mapData.get('Service Consultant');
                listSC.add(e);
            }
            else if(e.KPI_Category_Management__r.Role__c == 'Service Technician')
            {
                if(!mapData.containsKey('Service Technician'))
                {
                    mapData.put('Service Technician',new List<Monthly_KPI_Employee__c>());
                }
                List<Monthly_KPI_Employee__c> listTech = (List<Monthly_KPI_Employee__c>) mapData.get('Service Technician');
                listTech.add(e);
            }
            else if(e.KPI_Category_Management__r.Role__c == 'PCA Supervisor')
            {
                if(!mapData.containsKey('PCA Supervisor'))
                {
                    mapData.put('PCA Supervisor',new List<SuperData>());
                }
                List<SuperData> listSuper = (List<SuperData>) mapData.get('PCA Supervisor');
                SuperData s = new SuperData();
                s.superEmployee = e;
                listSuper.add(s);
            }
            else if(e.KPI_Category_Management__r.Role__c == 'PCA Sales Consultant')
            {
                if(!mapPCAChildEmployee.containsKey(e.Manager__c))
                {
                    mapPCAChildEmployee.put(e.Manager__c,new List<Monthly_KPI_Employee__c>());
                }
                mapPCAChildEmployee.get(e.Manager__c).add(e);
            }
        }
        
        List<SuperData> listSaleSuper = (List<SuperData>) mapData.get('Sales Supevisor');     
        for(SuperData currentSuper : listSaleSuper)
        {
            if(mapSaleChildEmployee.containsKey(currentSuper.superEmployee.Id))
            {
                currentSuper.listChild = mapSaleChildEmployee.get(currentSuper.superEmployee.Id);
            }
        }
        
        List<SuperData> listPCASuper = (List<SuperData>) mapData.get('PCA Supervisor');     
        for(SuperData currentSuper : listPCASuper)
        {
            if(mapPCAChildEmployee.containsKey(currentSuper.superEmployee.Id))
            {
                currentSuper.listChild = mapPCAChildEmployee.get(currentSuper.superEmployee.Id);
            }
        }
        
        DevLog__c log = new DevLog__c();
        log.Function__c = 'KPI';
        log.Input__c = Json.serialize(mapData);
        //insert log;
        
        api.result = mapData; // Sales AM/Manager , Sales Supevisor , Service AM/Sup , Service Consultant , ALL Technician , PCA Supervisor , PCA Sales Consultant
		api.success = true;
        
        return api;
    }
    
    /*@AuraEnabled
    public static ApiResponse saveDataTest(Monthly_KPI_Employee__c SaleAM)
    {
		ApiResponse api = new ApiResponse();
		
        
        
        return api;
    }*/
    
    @AuraEnabled
    public static ApiResponse saveDataKPI(Monthly_KPI_Employee__c SaleAM,String SaleSuper,Monthly_KPI_Employee__c ServiceAM,List<Monthly_KPI_Employee__c> ServiceCon,
                                       List<Monthly_KPI_Employee__c> ServiceTech,String PCASuper)
    {
        system.debug('Save Data');
        ApiResponse api = new ApiResponse();

        List<Monthly_KPI_Employee__c> listKPIUpdate = new List<Monthly_KPI_Employee__c>();
        listKPIUpdate.add(SaleAM);
        listKPIUpdate.add(ServiceAM);
        
        if(ServiceCon != null)
        {
            for(Monthly_KPI_Employee__c e : ServiceCon)
            {
                listKPIUpdate.add(e);
            }
        }        
        
        if(ServiceTech !=null )
        {
            for(Monthly_KPI_Employee__c e : ServiceTech)
            {
                listKPIUpdate.add(e);
            }
        }
        
        
        if(SaleSuper != null)
        {
            List<SuperData> listObjectSaleSuper = (List<SuperData>) JSON.deserialize(SaleSuper, List<SuperData>.class);
            for(SuperData superData : listObjectSaleSuper)
            {
                listKPIUpdate.add(superData.superEmployee);
                if(superData.listChild != null)
                {
                    for(Monthly_KPI_Employee__c e : superData.listChild)
                    {
                        listKPIUpdate.add(e);
                    }
                }
                
            }
        }
        
        
        if(PCASuper != null)
        {
            List<SuperData> listObjectPCASuper = (List<SuperData>) JSON.deserialize(PCASuper, List<SuperData>.class);
            for(SuperData superData : listObjectPCASuper)
            {
                listKPIUpdate.add(superData.superEmployee);
                if(superData.listChild != null)
                {
                    for(Monthly_KPI_Employee__c e : superData.listChild)
                    {
                        
                        listKPIUpdate.add(e);
                        
                    } 
                }                
            } 
        }
        
        
        if(!listKPIUpdate.isEmpty())
        {
            update listKPIUpdate;
            api.success = true;
        }
  
        return api;
    }
    
    public class SuperData
    {
        @AuraEnabled
        public Monthly_KPI_Employee__c superEmployee;
        @AuraEnabled
        public List<Monthly_KPI_Employee__c> listChild;
    }
}