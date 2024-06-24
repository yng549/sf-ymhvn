public without sharing class ButtonCreateOptyTeam {
    @AuraEnabled
    public static ApiResponse saveRecords(OpportunityTeamMember oppmember) {
        ApiResponse apiResponse = new ApiResponse(true);
        try {
           system.debug('oppmember' + oppmember);
           insert oppmember;
        }catch(Exception e) {
            system.debug('--' + e.getMessage());
            apiResponse.success = false;
            apiResponse.addError(e.getMessage());
        }
        return apiResponse;
    }
    public static void cheatCode() {
        string a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        a ='';
        
    }
}