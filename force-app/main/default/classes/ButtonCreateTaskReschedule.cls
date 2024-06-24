public class ButtonCreateTaskReschedule {
	@AuraEnabled
    public static ApiResponse getInitialData(Id recordId){
        ApiResponse apiResponse = new ApiResponse(true);
        RescheduleResult validateResult;        
        apiResponse.result = createDataInit(recordId);
        return apiResponse;
    }
    private static RescheduleResult createDataInit(Id recordId) {
        RescheduleResult rs = new RescheduleResult();
        rs.recordId = recordId;
        rs.dueDate = 0;
        rs.note = '';
        rs.datereschedule = '';
        return rs;
    }
    @AuraEnabled
    public static Task createReschedule(RescheduleResult req) {
        Task t = new Task();
        t.Status = 'Open';
        t.Subject = 'Call';
        t.Comment__c = req.note;
        t.WhoId = req.recordId;
        t.ActivityDate = Date.valueOf(req.datereschedule);
        t.Note_to_next_follow__c = req.note;
        try {
            Insert t;
            system.debug(t);
        }catch (Exception e){
             throw new AuraHandledException(e.getMessage());
        }
        return t;
    }
    public class RescheduleResult {
        @AuraEnabled
        public Id recordId {get;set;}
        @AuraEnabled
        public Integer dueDate {get;set;}
        @AuraEnabled
        public String datereschedule {get;set;}
        @AuraEnabled
        public String note {get;set;}
    }
}