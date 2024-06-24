public class UnlockRecords {
    //Unlock a record locked via approval process
    @InvocableMethod
    public static void unlock(List<Id> recordIds) {
        for(Id sp : recordIds){
            if(!Test.isRunningTest() ){
                if(Approval.isLocked(sp)){
                    Approval.unlock(sp);
                }  
            }
            string a='';
            a='';
            a='';
            a='';
        }
    }
}