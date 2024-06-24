public class BtnCalculateKPIController {
    
    @AuraEnabled
    public static ApiResponse callCalculate(String recordId)
    {
        ApiResponse api = new ApiResponse();
        
        try
        {
            Map<String, Schema.SObjectField> monthlyFieldMap = Monthly_KPI__c.sObjectType.getDescribe().fields.getMap();
            List<string> monthlySelectFields = new List<String>(monthlyFieldMap.keySet());                
            String monthlySoql = 'SELECT ' + String.join(monthlySelectFields, ',');
            monthlySoql += ' FROM Monthly_KPI__c';
            monthlySoql += ' WHERE Id =: recordId'; 
            Monthly_KPI__c monthly = Database.query(monthlySoql);
            
            if(monthly.Is_Lock__c == false)
            {
                if(monthly.Is_Calculating__c == false)
                {
                    monthly.Is_Calculating__c = true;
                    update monthly;
                    
                    Database.executeBatch(new BatchDeleteOldEmployeeDetail(recordId), 1000);
                    
                    //KPIHelper.startCalculate(recordId);
                    api.success = true;
                    api.result = 'Calculate Start ';
                }
                else
                {
                    api.error = 'This KPI is calculating . Please wait .';
                }
            }
            else
            {
                api.error = 'This KPI is locked . Contact admin if you have any problem .';
            }
            
        }
        catch(Exception ex)
        {            
            api.error = 'Error : '+ ex.getMessage() + ' , line : '+ex.getLineNumber();
            system.debug(api.error);
        }
        
        return api;
    }
}