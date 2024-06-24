global without sharing class ScheduleBatchReportStockHistoryBike implements Schedulable{
        global static String schedule() {
            ScheduleBatchReportStockHistoryBike SC = new ScheduleBatchReportStockHistoryBike(); 
            return System.schedule('ScheduleBatchReportStockHistoryBike every 8PM', '0 00 20 * * ?', SC);
        }
    
        global void execute(SchedulableContext sc) {
            BatchReportStockHistoryBike b1 = new BatchReportStockHistoryBike();
            ID batchprocessid = Database.executeBatch(b1,100);           
        }
      
         public static void stopScheduler(){
            List<CronTrigger> lstJobs =   [SELECT Id, CronJobDetailId, CronJobDetail.Name 
                                          FROM CronTrigger
                                          WHERE CronJobDetail.Name LIKE 'ScheduleBatchReportStockHistoryBike%'];
            if (lstJobs !=null && !lstJobs.isEmpty()){
               for (CronTrigger ct : lstJobs){
                  System.abortJob(ct.Id);
               }
            }
         }
        
}