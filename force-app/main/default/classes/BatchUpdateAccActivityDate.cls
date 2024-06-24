public class BatchUpdateAccActivityDate  extends BaseBatchHandler {
    
	public BatchUpdateAccActivityDate() {
        this.objectName = 'Account';
    }
    
    public override Database.querylocator start(Database.BatchableContext BC){        
        String recordTypeCustomer = RecordTypeHelper.ACCOUNT_CUSTOMER;
        
        Map<String, Schema.SObjectField> accSelectFieldMap = Account.sObjectType.getDescribe().fields.getMap();
        List<string> accSelectFields = new List<String>(accSelectFieldMap.keySet());                
        String accSoql = 'SELECT ' + String.join(accSelectFields, ',');
        accSoql += ' FROM Account';
        accSoql += ' WHERE RecordTypeId =: recordTypeCustomer  and Last_Activity_Date_Custom__c = null'; 
        
        return Database.getQueryLocator(accSoql);
    }

    public override List<SObject> processData(List<SObject> records){
        List<Account> listRecord = (List<Account>)records;
		
        List<Account> listUpdateAcc = new List<Account>();
        List<Order> listOrder = [Select id,AccountId,CreatedDate from Order where AccountId in: listRecord];
        Map<String,List<Order>> mapOrder = new Map<string,List<Order>>();
        for(Order o : listOrder)
        {
            if(!mapOrder.containsKey(o.AccountId))
            {
                mapOrder.put(o.AccountId,new List<Order>());
            }
            mapOrder.get(o.AccountId).add(o);
        }
        for(Account acc : listRecord)
        {
            if(mapOrder.containsKey(acc.Id))
            {
                List<Order> listCOrder = mapOrder.get(acc.Id);
                for(Order o : listCOrder)
                {
                    if(o.CreatedDate.date() > acc.Last_Activity_Date_Custom__c || acc.Last_Activity_Date_Custom__c == null)
                    {
                        acc.Last_Activity_Date_Custom__c = o.CreatedDate.date();
                        if(!listUpdateAcc.contains(acc))
                        {
                            listUpdateAcc.add(acc);
                        }
                    }
                }
            }
        }
        
        List<Opportunity> listOppty = [Select id,CreatedDate,AccountId from Opportunity where AccountId in: listRecord];
        Map<String,List<Opportunity>> mapOppty = new Map<string,List<Opportunity>>();
        for(Opportunity o : listOppty)
        {
            if(!mapOppty.containsKey(o.AccountId))
            {
                mapOppty.put(o.AccountId,new List<Opportunity>());
            }
            mapOppty.get(o.AccountId).add(o);
        }
        for(Account acc : listRecord)
        {
            if(mapOppty.containsKey(acc.Id))
            {
                List<Opportunity> listCOppty = mapOppty.get(acc.Id);
                for(Opportunity o : listCOppty)
                {
                    if(o.CreatedDate.date() > acc.Last_Activity_Date_Custom__c || acc.Last_Activity_Date_Custom__c == null)
                    {
                        acc.Last_Activity_Date_Custom__c = o.CreatedDate.date();
                        if(!listUpdateAcc.contains(acc))
                        {
                            listUpdateAcc.add(acc);
                        }
                    }
                }
            }
        }
        
        update listUpdateAcc;

        return listRecord;
    }
    
    public override void handleFinish(){         
    }
    
    public static void addpoint()
    {
        integer point = 0;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
        point = 100;
    }
}