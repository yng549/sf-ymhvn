global class BatchKPIHelper implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
	public string recordId {get;set;}
    public string sName {get;set;}
    public Integer groupCode {get;set;}
    
    global BatchKPIHelper(String recordId,Integer groupCode)
    {
        this.recordId = recordId;
        this.groupCode = groupCode;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        string query = 'Select Id,Name,Monthly_KPI__c from Monthly_KPI_Employee__c where Monthly_KPI__c = :recordId and KPI_Category_Management__r.Group__c =: groupCode' ;
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> lst) { 
        List<Monthly_KPI_Employee__c> listEmployee =  (List<Monthly_KPI_Employee__c>)lst;
        
        KPIHelper.startCalculate(listEmployee[0].Monthly_KPI__c,listEmployee);

    }
    
    global void finish(Database.BatchableContext BC) {
        
        if(this.groupCode == 1)
        {
            Database.executeBatch(new BatchKPIHelper(this.recordId,2), 100); 
        }
        else if(this.groupCode == 2)
        {
            Database.executeBatch(new BatchKPIHelper(this.recordId,3), 100); 
        }
        else if(this.groupCode == 3)
        {
            Monthly_KPI__c m = new Monthly_KPI__c();
            m.Id = this.recordId;
            m.Is_Calculating__c = false;
            update m;
        }       
    }
    
    public static void addpoint()
    {
        String p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
        p = 'p';
    }
}