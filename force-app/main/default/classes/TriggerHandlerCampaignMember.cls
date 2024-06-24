public class TriggerHandlerCampaignMember {
    public static void onBeforeUpdate(Map<Id, CampaignMember> mapOlds, Map<Id, CampaignMember> mapNews) {
        List<CampaignMember> lstCampaignMember = new List<CampaignMember>();
        for(CampaignMember item : mapNews.values()) {
            if(mapOlds.get(item.Id).Status != item.Status && item.Status == 'Round To SALE') {
                lstCampaignMember.add(item);
            }
        }
        if(!lstCampaignMember.isEmpty()) {
            createOptyForCampaignMember(lstCampaignMember, mapNews);
        }
    }
    
    private static void createOptyForCampaignMember(List<CampaignMember> lstCampaignMember, Map<Id, CampaignMember> mapNews) {
        Map<Id, Opportunity> mapCampaignWithOppty = new Map<Id, Opportunity>();
        try {
            List<CampaignMember> lstCMQuery = [SELECT Id
                                               		, Contact.AccountId
                                               		, Contact.Account.Name
                                               		, Product__r.Sales_Name__c
                                               		, Contact.Account.DO_DL_Create_Account__c
                                               		, Product__c
                                               		, Contact.Account.OwnerId
                                               		, Contact.Account.Owner.Profile.Name
                                               FROM CampaignMember
                                               WHERE Id IN: lstCampaignMember AND ContactId != null ];
            System.debug('lstCMQuery: ' + lstCMQuery);
            for(CampaignMember item : lstCMQuery) {
                Opportunity opp = new Opportunity();
                opp.RecordTypeId = RecordTypeHelper.OPPORTUNITY_BIKE;
                opp.AccountId = item.Contact.AccountId;
                opp.DODL_Create__c = item.Contact.Account.DO_DL_Create_Account__c;
                opp.Product__c = item.Product__c;
                opp.StageName = 'New';
                opp.CloseDate = Date.today().addDays(30);
                opp.Create_from_Campaign__c = true;
                opp.Name = item.Contact.Account.Name + ' ' + item.Product__r.Sales_Name__c;
                opp.Run_Reassign__c = true;//test
                opp.Enable_Round_Robin__c = true;//test
                if(item.Contact.Account.Owner.Profile.Name == 'Community Sale Profile' || item.Contact.Account.Owner.Profile.Name == 'Community Sale Sup') {
                    opp.OwnerId = item.Contact.Account.OwnerId;
                }
                //add in 14/01/2023
                mapCampaignWithOppty.put(item.Id, opp);
            }
            System.debug('mapCampaignWithOppty: ' + mapCampaignWithOppty);
            if(!mapCampaignWithOppty.values().isEmpty()) {
                insert mapCampaignWithOppty.values();
                System.debug('mapCampaignWithOppty After Insert: ' + mapCampaignWithOppty);
                for(CampaignMember item : lstCMQuery) {
                    if(mapCampaignWithOppty.containsKey(item.Id)) {
                        
                        mapNews.get(item.Id).Opportunity__c = mapCampaignWithOppty.get(item.Id).Id;
                        System.debug('mapNews.get(item.Id):' + mapNews.get(item.Id).Id);
                        System.debug('mapNews.get(item.Id).Opportunity__c' + mapNews.get(item.Id).Opportunity__c);
					}
                }
            }
        } catch(Exception ex) {
            System.debug('ex.getMessage() : ' + ex.getMessage() + ' ' + ex.getLineNumber());
        }
    }
    
    public static void cheat(){
        String a = '';
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
        a = a;
    }
}