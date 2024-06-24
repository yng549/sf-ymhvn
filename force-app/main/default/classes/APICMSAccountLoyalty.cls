/*******************************************************************************
 ** Class Name: APICMSAccountLoyalty
 ** Description: This class call API CMS to update Account
 ** Version: 1.0
 ** Created By: THL
 ** Modified By:
 *******************************************************************************/
public class APICMSAccountLoyalty implements Queueable, Database.AllowsCallouts{
   
     	List<Id> accountIds;
        public APICMSAccountLoyalty(List<Id> accountIds){
            this.accountIds = accountIds;
        }
        public void execute(QueueableContext context) {
            if(accountIds.isEmpty()){
                return;
            }
            try{
                List<Id> queryaccountIds = accountIds;
                String accountSoql = 'SELECT Id, Name, Applied_Promotion__c ,Website_ID__c	';
                accountSoql += ' FROM Account';
                accountSoql += ' WHERE Id IN :queryaccountIds';
                List<Account> accounts = Database.query(accountSoql);
                if(accounts.isEmpty()){
                    return;
                }
               
                List<Account> updatedAccounts = new List<Account>();
                List<DevLog__c> logs = new List<DevLog__c>();
                for (Account a : accounts) {
                    string strMessage = '';
                    Account updateAccount = new Account(Id = a.Id);
                    HttpResponse response = new HttpResponse(); 
                    try {
                        List<Data> accountRequestData = convertAccountCMS(a);
                        response = requestApiCMS(JSON.serialize(accountRequestData));
                        ResponseBody result = (ResponseBody)JSON.deserialize(response.getBody(), ResponseBody.class);
                        string strOutput = JSON.serialize(result);
                        system.debug('body' + response.getBody());
                        logError('APICMSAccountLoyalty.execute', '', JSON.serialize(accountRequestData), trimErrorMessage(strOutput), a.Name);
                        if(response.getStatusCode() == 200) { 
                            if(result.status == '200') {
                                updateAccount.Log_CMS__c = 'Success';
                            } else {
                                updateAccount.Log_CMS__c = result.status + '_' + result.message;
                            } 
                        }
                    }catch(Exception e) {
                        updateAccount.Log_CMS__c = e.getMessage();
                        strMessage = e.getMessage() + ' - ' + e.getLineNumber();
                        system.debug('error' + strMessage);
                        logError('APICMSAccountLoyalty.UpdateLoyaltyAccount', strMessage, trimErrorMessage(response.getBody()), a.Id, a.Name);
                    }
                    updatedAccounts.add(updateAccount);
                }
                update updatedAccounts;
            } catch(Exception e){
                system.debug('error' + e.getMessage() + e.getLineNumber());
                logError('APICMSAccountLoyalty.UpdateLoyaltyAccount', e.getMessage() + ' - ' + e.getLineNumber(), JSON.serialize(accountIds), '', '');
            }
        }
    public static List<Data> convertAccountCMS(Account account) {
        Data data = new Data();
        data.web_user_id = account.Website_ID__c;
        data.first_bike = account.Applied_Promotion__c;
        data.applied = account.Applied_Promotion__c ;
        return new List<Data> {data};
    }
    @TestVisible 
    private static String trimErrorMessage(String errorMessage){        
        if(errorMessage.length() > 30000){
            errorMessage = errorMessage.substring(0, 30000);
        }
        return errorMessage;
    }
    @TestVisible 
    private static void logError(String function, String message, String input, String output, String url){
        DevLog__c log = new DevLog__c(
            Function__c = function,
            Url__c = url,
            Input__c = input,
            Output__c = output,
            Message__c = message             
        );
        insert log;
        
    }
    public class ResponseBody {
        public string status {
            get;
            set;
        }
        public string message {
            get;
            set;
        }
    }
    public static HttpResponse requestApiCMS(String reqBody) {
		Http http = new Http();
		HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:API_CMS/updateLoyalty');
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
        request.setBody(reqBody);
        request.setTimeout(120000);
        return http.send(request);
	}
	public class Data {
        public string web_user_id;
        public boolean first_bike;
        public boolean applied;
    }
}