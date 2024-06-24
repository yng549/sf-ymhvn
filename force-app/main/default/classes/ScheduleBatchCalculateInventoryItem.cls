//System.schedule('Batch Caclculate Invenetory Item For KPI', '0 0 23 * * ?', new ScheduleBatchCalculateInventoryItem());
global class ScheduleBatchCalculateInventoryItem implements Schedulable{
	global void execute(SchedulableContext ctx) {
        Database.executeBatch(new BatchCalculateInventoryItem(),200);
    }
}