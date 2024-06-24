//Database.executeBatch(new BatchReCalculateAllInventoryItem(),200);
public class BatchReCalculateAllInventoryItem extends BaseBatchHandler{
    public BatchReCalculateAllInventoryItem() {
        this.objectName = 'OrderItem';
    }
    public override Database.querylocator start(Database.BatchableContext BC){
        Date dateToday = Date.today();
		String ProductPCARecordType = RecordTypeHelper.PRODUCT_PCA;
        
        List<string> query = new List<string>();
        query.add('SELECT Id,Product2Id,Quantity,Product_Code__c ');
        query.add(' FROM ' + this.objectName);
        query.add(' WHERE Order.Invoice_Date__c != null');
        if(!Test.isRunningTest())
        {
           query.add(' AND Order.Status = \'Completed\''); 
        }        
        query.add(' AND Product2.RecordTypeId = \''+ProductPCARecordType+'\'');
        
        return Database.getQueryLocator(string.join(query, ' '));
    }
	public override List<SObject> processData(List<SObject> records){
        List<OrderItem> listOrderItem = (List<OrderItem>)records;
        system.debug(listOrderItem);
        
        Set<String> setProductId = new Set<String>();
        for(OrderItem item : listOrderItem)
        {
            setProductId.add(item.Product2Id);
        }
        
        List<Inventory_Transaction_Item__c> listInventoryItem = [Select Id,Quantity_Remaining__c,Stock_Age__c,Product__c,Quantity_Out__c,Quantity__c,Quantity_Amount_Remaing_KPI__c
                                                                from Inventory_Transaction_Item__c where Product__c in: setProductId
                                                                 And Quantity_Amount_Remaing_KPI__c > 0 AND Inventory_Transaction_Header__r.Header_Type__c = 'Input'
                                                                 AND Inventory_Transaction_Header__r.Status__c = 'Completed' AND Product__r.RecordTypeId =: RecordTypeHelper.PRODUCT_PCA
                                                                Order By Stock_Age__c DESC];
        Map<String,List<Inventory_Transaction_Item__c>> mapInventoryItem = new Map<String,List<Inventory_Transaction_Item__c>>();
        for(Inventory_Transaction_Item__c item : listInventoryItem)
        {
            if(!mapInventoryItem.containsKey(item.Product__c))
            {
                mapInventoryItem.put(item.Product__c,new List<Inventory_Transaction_Item__c>());
            }
            mapInventoryItem.get(item.Product__c).add(item);
        }
        system.debug(mapInventoryItem);
        
        for(OrderItem item : listOrderItem)
        {
           Decimal amountReduce = item.Quantity;
           if(mapInventoryItem.containsKey(item.Product2Id))
           {
               //List<Inventory_Transaction_Item__c> listCurrentInventoryItem = mapInventoryItem.get(item.Product2Id);
               
               //system.debug(amountReduce);
               
               for(Inventory_Transaction_Item__c iItem : mapInventoryItem.get(item.Product2Id))
               {
                   if(amountReduce > 0)
                   {
                       if(iItem.Quantity_Amount_Remaing_KPI__c <= amountReduce)
                       {       
                           /*
                               system.debug('======Before========');
                               system.debug('Quantity Remaining :'+ iItem.Quantity_Amount_Remaing_KPI__c);
                               system.debug('Amount Reduct :'+ amountReduce);
                           */
                           
                           amountReduce = amountReduce - iItem.Quantity_Amount_Remaing_KPI__c;
                           iItem.Quantity_Amount_Remaing_KPI__c = 0;
                           
                           /*
                               system.debug('======After=========');
                               system.debug('Order Item Id :'+ item.Id);
                               system.debug('Inventort Item Id :'+ iItem.Id);
                               system.debug('Quantity Remaining :'+ iItem.Quantity_Amount_Remaing_KPI__c);
                               system.debug('Amount Reduct :'+amountReduce);                               
                           */
                       }
                       else
                       {
                           /*
                               system.debug('======Before========');
                               system.debug('Quantity Remaining :'+ iItem.Quantity_Amount_Remaing_KPI__c);
                               system.debug('Amount Reduct :'+ amountReduce);
                           */
                           
                           iItem.Quantity_Amount_Remaing_KPI__c = iItem.Quantity_Amount_Remaing_KPI__c - amountReduce; // => iItem.Quantity_Remaining__c reduce
                           amountReduce = 0;
                           
                           /*
                           system.debug('======After=========');
                           system.debug('Order Item Id :'+ item.Id);
                           system.debug('Inventort Item Id :'+ iItem.Id);
                           system.debug('Quantity Remaining :'+ iItem.Quantity_Amount_Remaing_KPI__c);
                           system.debug('Amount Reduct :'+amountReduce);     
							*/                          

                  }
                   }
                   else
                   {
                       break;
                   }
               }
           }
        }
        
        List<Inventory_Transaction_Item__c> listUpdateInventory = new List<Inventory_Transaction_Item__c>();
        for (Id key : mapInventoryItem.keySet()) {
            
            for(Inventory_Transaction_Item__c iItem : (List<Inventory_Transaction_Item__c>) mapInventoryItem.get(key))
            {
                listUpdateInventory.add(iItem);
            }          
        }
        
        try
        {
            if(!listUpdateInventory.isEmpty())
            {
                //List<Inventory_Transaction_Item__c> listItem = new List<Inventory_Transaction_Item__c>();
                update listUpdateInventory;
            }
        }
        catch(Exception e)
        {
            String errorMsg = e.getMessage() + ' , '+e.getLineNumber();
            system.debug(errorMsg);
            DevLog__c log = new DevLog__c();
            log.Function__c = 'BatchReCalculateInventoryItem';
            log.Output__c = errorMsg;
            insert log;
        }
        
        return listOrderItem;
    }
    public override void handleFinish(){

    }
}