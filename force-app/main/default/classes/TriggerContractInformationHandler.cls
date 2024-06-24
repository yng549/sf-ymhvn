public without sharing class TriggerContractInformationHandler {
    public static void onAfterInsert(List<Contract_Information__c> lstOrderNew){
        updateContractAfterInsert(lstOrderNew);
    }
    private static void updateContractAfterInsert(List<Contract_Information__c> lstOrderNew){
        Map<Id,Id> mapUpdateId = new Map<Id,Id>();
        for (Contract_Information__c CI : lstOrderNew){
            if (CI.Contract__c !=null){
                mapUpdateId.put(CI.Contract__c,CI.Id);
            }
        }
        List<Contract> lstContractUpdate = [SELECT Id, Contract_Information__c FROM Contract WHERE Id IN: mapUpdateId.keySet()];
        for (Contract contractUpdate : lstContractUpdate){
            contractUpdate.Contract_Information__c = mapUpdateId.get(contractUpdate.Id);
        }
        update lstContractUpdate;
    }
}