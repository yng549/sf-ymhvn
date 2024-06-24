//Database.executeBatch(new BatchSetOriginAmountInventory(),2000);
public class BatchSetOriginAmountInventory extends BaseBatchHandler{
	public BatchSetOriginAmountInventory() {
        this.objectName = 'Inventory_Transaction_Item__c';
    }
    public override Database.querylocator start(Database.BatchableContext BC){
        Date dateToday = Date.today();
        String ProductPCARecordType = RecordTypeHelper.PRODUCT_PCA;
        
        List<string> query = new List<string>();
        query.add('SELECT Id,Quantity_Amount_Remaing_KPI__c	,Quantity__c ');
        query.add(' FROM ' + this.objectName);
        query.add(' WHERE Inventory_Transaction_Header__r.Status__c = \'Completed\'');
        query.add(' AND Inventory_Transaction_Header__r.Header_Type__c = \'Input\'');
        query.add(' AND Product__r.RecordTypeId =: ProductPCARecordType');
        //query.add(' WHERE Quantity_Amount_Remaing_KPI__c = null ');
        
        return Database.getQueryLocator(string.join(query, ' '));
    }
    public override List<SObject> processData(List<SObject> records){
        List<Inventory_Transaction_Item__c> listItem = (List<Inventory_Transaction_Item__c>)records;
        
        for(Inventory_Transaction_Item__c item : listItem)
        {
            item.Quantity_Amount_Remaing_KPI__c = item.Quantity__c;
        }
        
        if(!listItem.isEmpty())
        {
            update listItem;
        }
        
        return listItem;
    }
    public override void handleFinish(){

    }
}